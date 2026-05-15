import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_provider.dart';
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
  /// 1. **connectivity 가 false** 면 onlineCall 시도조차 안 함 → 즉시 enqueue
  ///    (HTTP 타임아웃 30~60초 기다리지 않게 — UI 응답성 보장)
  /// 2. connectivity true 면 `onlineCall()` 시도
  /// 3. 네트워크 에러(휴리스틱)면 큐에 enqueue + 옵티미스틱 반환
  /// 4. 그 외 에러(서버 4xx 등)는 rethrow
  static Future<T> execute<T>({
    required Ref ref,
    required String table,
    required String op,
    String? rowId,
    required Map<String, dynamic> payload,
    required Future<T> Function() onlineCall,
    required T Function() optimisticResult,
  }) async {
    if (_isOfflineNow(ref)) {
      await _enqueue(ref, op: op, table: table, rowId: rowId, payload: payload);
      return optimisticResult();
    }
    try {
      return await onlineCall();
    } catch (e) {
      if (WriteQueue.isOfflineError(e)) {
        await _enqueue(ref,
            op: op, table: table, rowId: rowId, payload: payload);
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
    if (_isOfflineNow(ref)) {
      await _enqueue(ref, op: op, table: table, rowId: rowId, payload: payload);
      return;
    }
    try {
      await onlineCall();
    } catch (e) {
      if (WriteQueue.isOfflineError(e)) {
        await _enqueue(ref,
            op: op, table: table, rowId: rowId, payload: payload);
        return;
      }
      rethrow;
    }
  }

  /// connectivity stream 의 현재 값을 동기 조회.
  ///
  /// 첫 build 시점엔 스트림이 아직 첫 이벤트를 못 받았을 수 있음 → null 이면
  /// **온라인 가정**(false-positive 가 아니라 true-positive 가 안전 — 네트워크
  /// 시도해보고 실패하면 catch 가 잡음). 부팅 직후 connectivityCheckProvider
  /// 가 한 번 즉시 fetch 하므로 곧 정확한 값이 들어옴.
  static bool _isOfflineNow(Ref ref) {
    final stream = ref.read(connectivityStreamProvider);
    final online = stream.valueOrNull ?? true;
    return !online;
  }

  static Future<void> _enqueue(
    Ref ref, {
    required String op,
    required String table,
    String? rowId,
    required Map<String, dynamic> payload,
  }) async {
    await ref.read(writeQueueProvider).enqueue(
          op: op,
          table: table,
          rowId: rowId,
          payload: payload,
        );
    ref.invalidate(writeQueueCountProvider);
  }
}

/// 클라이언트에서 UUID v4 생성 — INSERT 시 id 컬럼에 직접 넣어야
/// 오프라인 큐잉 후 동일 id 로 UPDATE/DELETE 가능.
///
/// Supabase 의 `default gen_random_uuid()` 는 클라이언트가 id 를 명시하면
/// 그 값을 그대로 사용하므로 호환 OK.
String genUuid() => const Uuid().v4();
