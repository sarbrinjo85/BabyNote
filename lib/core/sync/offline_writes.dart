import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'write_queue.dart';

/// 오프라인 쓰기 헬퍼 — 리포지토리에서 try/catch 보일러플레이트를 줄여줌.
///
/// ── 사용 패턴 ────────────────────────────────────────────────────────
/// 리포지토리는 보통 Ref(또는 컨테이너) 를 들고 있어야 writeQueueProvider 를
/// 접근 가능. 새 리포지토리 만들 때:
///
/// ```dart
/// class XxxRepository {
///   XxxRepository(this._client, this._ref);
///   final SupabaseClient _client;
///   final Ref _ref;
///
///   Future<Routine> create({...}) async {
///     final id = const Uuid().v4(); // 클라이언트 측 id
///     final payload = {'id': id, ... };
///
///     return OfflineWrites.execute<Routine>(
///       ref: _ref,
///       table: 'routines',
///       op: 'insert',
///       rowId: id,
///       payload: payload,
///       onlineCall: () async {
///         final r = await _client.from('routines').insert(payload).select().single();
///         return Routine.fromMap(r);
///       },
///       optimisticResult: () => Routine(id: id, ...), // 큐잉 시 즉시 반환
///     );
///   }
/// }
/// ```
class OfflineWrites {
  OfflineWrites._();

  /// 핵심 wrapper.
  ///
  /// 1. `onlineCall()` 시도 → 성공이면 그 결과 반환
  /// 2. 네트워크 에러면 큐에 enqueue + `optimisticResult()` 반환
  /// 3. 그 외 에러는 그대로 rethrow (서버 4xx 등 — 사용자에게 알려야 함)
  static Future<T> execute<T>({
    required Ref ref,
    required String table,
    required String op,
    String? rowId,
    required Map<String, dynamic> payload,
    required Future<T> Function() onlineCall,
    required T Function() optimisticResult,
  }) async {
    try {
      return await onlineCall();
    } catch (e) {
      if (WriteQueue.isOfflineError(e)) {
        await ref.read(writeQueueProvider).enqueue(
              op: op,
              table: table,
              rowId: rowId,
              payload: payload,
            );
        // 큐 길이 invalidate — sync indicator 갱신
        ref.invalidate(writeQueueCountProvider);
        return optimisticResult();
      }
      rethrow;
    }
  }

  /// DELETE/UPDATE 처럼 반환값이 void 인 경우.
  static Future<void> executeVoid({
    required Ref ref,
    required String table,
    required String op,
    String? rowId,
    required Map<String, dynamic> payload,
    required Future<void> Function() onlineCall,
  }) async {
    try {
      await onlineCall();
    } catch (e) {
      if (WriteQueue.isOfflineError(e)) {
        await ref.read(writeQueueProvider).enqueue(
              op: op,
              table: table,
              rowId: rowId,
              payload: payload,
            );
        ref.invalidate(writeQueueCountProvider);
        return;
      }
      rethrow;
    }
  }
}

/// 클라이언트에서 UUID v4 생성 — INSERT 시 id 컬럼에 직접 넣어야
/// 오프라인 큐잉 후 동일 id 로 UPDATE/DELETE 가능.
///
/// Supabase 의 `default gen_random_uuid()` 는 클라이언트가 id 를 명시하면
/// 그 값을 그대로 사용하므로 호환 OK.
String genUuid() => const Uuid().v4();
