import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_client_provider.dart';
import 'connectivity_provider.dart';
import 'write_queue.dart';

/// 네트워크 재연결 시 WriteQueue 를 Supabase 로 flush 하는 백그라운드 워커.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// 1. connectivityStreamProvider 가 false→true 가 되면 `flush()` 호출
/// 2. 큐의 모든 PendingWrite 를 enqueued_at 오래된 순으로 Supabase 에 전송
/// 3. 성공 → queue 에서 제거 / 실패 → attempts 증가 + 다음 트리거까지 대기
///
/// ── 사용 ─────────────────────────────────────────────────────────────
/// main.dart 의 ProviderScope override 에서 자동 시작:
///   ref.watch(syncWorkerProvider);
///
/// 또는 HomePage 에서 한 번 watch 해도 됨 (싱글톤이므로 동일).
class SyncWorker {
  SyncWorker(this._ref);

  final Ref _ref;
  bool _flushing = false;

  Future<void> flush() async {
    if (_flushing) {
      debugPrint('[SyncWorker] flush already in progress, skip');
      return;
    }
    _flushing = true;
    try {
      final queue = _ref.read(writeQueueProvider);
      final client = _ref.read(supabaseClientProvider);
      final items = await queue.listAll();
      if (items.isEmpty) return;
      debugPrint('[SyncWorker] flushing ${items.length} pending writes');

      for (final w in items) {
        try {
          await _send(client, w);
          await queue.remove(w.id);
        } catch (e) {
          // 네트워크 끊김이면 다음 트리거까지 대기, 그 외 (서버 4xx 등) 면 카운트만 증가
          await queue.markFailure(w.id, e);
          debugPrint('[SyncWorker] failed #${w.id} ${w.op} ${w.table}: $e');
          if (WriteQueue.isOfflineError(e)) {
            // 다시 오프라인 — 나머지는 다음 기회에
            break;
          }
        }
      }
      // 큐 길이 + pending key 셋 변경 알림 (sync indicator + records 배지 업데이트)
      _ref.invalidate(writeQueueCountProvider);
      _ref.invalidate(writeQueuePendingKeysProvider);
    } finally {
      _flushing = false;
    }
  }

  Future<void> _send(SupabaseClient client, PendingWrite w) async {
    final tbl = client.from(w.table);
    switch (w.op) {
      case 'insert':
        await tbl.insert(w.payload);
        break;
      case 'update':
        if (w.rowId == null) {
          throw StateError('update without row_id: queue #${w.id}');
        }
        await tbl.update(w.payload).eq('id', w.rowId!);
        break;
      case 'delete':
        if (w.rowId == null) {
          throw StateError('delete without row_id: queue #${w.id}');
        }
        await tbl.delete().eq('id', w.rowId!);
        break;
      default:
        throw StateError('unknown op: ${w.op}');
    }
  }
}

/// SyncWorker — 앱 라이프사이클 단일 인스턴스.
/// connectivityStreamProvider 가 true 로 바뀔 때마다 flush 자동 호출.
final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(ref);

  // 부팅 직후 한 번 시도 — 앱 시작 전에 enqueue 된 게 있다면 즉시 처리.
  ref.listen<AsyncValue<bool>>(connectivityCheckProvider, (prev, next) {
    next.whenData((online) {
      if (online) worker.flush();
    });
  }, fireImmediately: true);

  // 연결 상태 변화 구독.
  ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (prev, next) {
    next.whenData((online) {
      if (online) worker.flush();
    });
  });

  return worker;
});
