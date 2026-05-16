import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 오프라인 시 INSERT/UPDATE/DELETE 를 로컬 SQLite 에 임시 저장하고
/// 재연결 시 Supabase 로 flush 하는 쓰기 큐.
///
/// ── 사용 패턴 ────────────────────────────────────────────────────────
/// 리포지토리 작성 시 try/catch 로 네트워크 실패를 잡고 enqueue.
///
/// ```dart
/// try {
///   await _client.from('routines').insert(payload);
/// } catch (e) {
///   if (WriteQueue.isOfflineError(e)) {
///     await ref.read(writeQueueProvider).enqueue(
///       op: 'insert',
///       table: 'routines',
///       payload: payload,
///     );
///   } else {
///     rethrow;
///   }
/// }
/// ```
///
/// 또는 `OfflineAwareRepository` mixin 사용 (후속 작업).
///
/// ── 스키마 ───────────────────────────────────────────────────────────
/// pending_writes:
///   id INTEGER PRIMARY KEY AUTOINCREMENT
///   op TEXT NOT NULL      ('insert' | 'update' | 'delete')
///   table_name TEXT NOT NULL  (예: 'routines', 'feedings')
///   row_id TEXT           (UPDATE/DELETE 의 대상 row id; INSERT 면 NULL)
///   payload TEXT NOT NULL (JSON 인코딩된 column→value 맵)
///   enqueued_at INTEGER NOT NULL (ms since epoch)
///   last_error TEXT       (flush 실패 시 마지막 에러 메시지)
///   attempts INTEGER NOT NULL DEFAULT 0
class WriteQueue {
  WriteQueue._(this._db);

  final Database _db;

  static const _dbFile = 'babynote_sync.db';
  static const _table = 'pending_writes';

  /// 앱 문서 디렉터리에 SQLite DB 열고 인스턴스 반환.
  /// 같은 프로세스에서 여러 번 호출돼도 안전 (sqflite 가 같은 path 캐시 처리).
  static Future<WriteQueue> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbFile);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            op TEXT NOT NULL,
            table_name TEXT NOT NULL,
            row_id TEXT,
            payload TEXT NOT NULL,
            enqueued_at INTEGER NOT NULL,
            last_error TEXT,
            attempts INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_pending_writes_enqueued_at
            ON $_table(enqueued_at)
        ''');
      },
    );
    return WriteQueue._(db);
  }

  /// 쓰기를 큐에 추가.
  Future<int> enqueue({
    required String op,
    required String table,
    String? rowId,
    required Map<String, dynamic> payload,
  }) async {
    if (op != 'insert' && op != 'update' && op != 'delete') {
      throw ArgumentError('op must be insert|update|delete, got: $op');
    }
    final id = await _db.insert(_table, {
      'op': op,
      'table_name': table,
      'row_id': rowId,
      'payload': jsonEncode(payload),
      'enqueued_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('[WriteQueue] enqueued #$id $op $table');
    return id;
  }

  /// 큐에 있는 항목 모두 (enqueued_at 오래된 순).
  Future<List<PendingWrite>> listAll() async {
    final rows = await _db.query(_table, orderBy: 'enqueued_at ASC');
    return rows.map(PendingWrite.fromMap).toList();
  }

  /// 큐 길이 — UI 의 sync indicator 용.
  Future<int> count() async {
    final r = await _db.rawQuery('SELECT COUNT(*) as c FROM $_table');
    return (r.first['c'] as int?) ?? 0;
  }

  /// flush 성공 시 항목 제거.
  Future<void> remove(int id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// flush 실패 시 attempts 증가 + 에러 기록.
  Future<void> markFailure(int id, Object error) async {
    await _db.rawUpdate(
      'UPDATE $_table SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error.toString(), id],
    );
  }

  /// 어떤 에러가 "오프라인" 인지 판단 — 휴리스틱. 네트워크 끊김/타임아웃 등.
  ///
  /// Supabase 클라이언트는 네트워크 실패 시 `SocketException`, `TimeoutException`,
  /// 또는 `ClientException` 같은 dart:io / http 예외를 던짐. 5xx HTTP 응답은
  /// 큐에 넣지 않음 (서버 문제는 재시도해도 의미 없음, 사용자에게 알림 필요).
  static bool isOfflineError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('timeoutexception') ||
        s.contains('clientexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection closed') ||
        s.contains('handshakeexception');
  }

  Future<void> close() async => _db.close();
}

/// 큐에 들어있는 한 row.
class PendingWrite {
  const PendingWrite({
    required this.id,
    required this.op,
    required this.table,
    required this.payload,
    required this.enqueuedAt,
    required this.attempts,
    this.rowId,
    this.lastError,
  });

  final int id;
  final String op;
  final String table;
  final String? rowId;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  final int attempts;
  final String? lastError;

  static PendingWrite fromMap(Map<String, Object?> m) {
    return PendingWrite(
      id: m['id'] as int,
      op: m['op'] as String,
      table: m['table_name'] as String,
      rowId: m['row_id'] as String?,
      payload: jsonDecode(m['payload'] as String) as Map<String, dynamic>,
      enqueuedAt:
          DateTime.fromMillisecondsSinceEpoch(m['enqueued_at'] as int),
      attempts: m['attempts'] as int,
      lastError: m['last_error'] as String?,
    );
  }
}

/// 앱 라이프사이클 동안 단일 인스턴스 유지 — main.dart 에서 초기화.
final writeQueueProvider = Provider<WriteQueue>((ref) {
  throw UnimplementedError(
      'writeQueueProvider must be overridden in main.dart after WriteQueue.open()');
});

/// 큐 길이 — UI 의 sync indicator 용. 폴링 또는 flush 후 invalidate.
final writeQueueCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(writeQueueProvider).count();
});

/// 큐에 있는 모든 row 의 (table, rowId) 쌍 모음 — records 화면이 각 row 가
/// "동기화 대기 중" 인지 빠르게 lookup 하기 위함.
///
/// 키 형식: `"{table}::{rowId}"` (rowId 가 null 이면 제외 — INSERT 인 경우 payload
/// 에서 'id' 를 꺼냄)
final writeQueuePendingKeysProvider =
    FutureProvider<Set<String>>((ref) async {
  final queue = ref.watch(writeQueueProvider);
  final items = await queue.listAll();
  final out = <String>{};
  for (final w in items) {
    final id = w.rowId ?? w.payload['id'] as String?;
    if (id != null) out.add('${w.table}::$id');
  }
  return out;
});
