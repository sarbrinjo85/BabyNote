import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/routine.dart';

/// routines 테이블 CRUD — 산책/목욕/영양제/간식 4종 통합.
///
/// ── 오프라인 지원 ──────────────────────────────────────────────────────
/// 모든 mutation 은 `OfflineWrites.execute` 로 감싸짐.
/// - 네트워크 OK → Supabase 직접 호출 후 서버 row 반환
/// - 네트워크 실패 → 큐에 enqueue + 옵티미스틱 결과(client UUID 포함) 반환
/// 큐는 connectivity 복구 시 SyncWorker 가 자동 flush.
///
/// ── INSERT 시 client UUID ─────────────────────────────────────────────
/// 큐에 들어간 INSERT 가 flush 되기 전이라도 id 가 결정돼 있어야 같은 row 의
/// 후속 UPDATE/DELETE 를 큐잉 가능. 그래서 클라이언트에서 미리 uuid v4 발급.
/// Supabase 의 `default gen_random_uuid()` 는 client id 가 있으면 그걸 사용.
class RoutineRepository {
  RoutineRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Routine> create({
    required String currentUserId,
    required String childId,
    required RoutineKind kind,
    required DateTime startedAt,
    int? durationMin,
    String? itemName,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Routine(
      id: id,
      childId: childId,
      kind: kind,
      startedAt: startedAt,
      durationMin: durationMin,
      itemName: itemName,
      note: note,
      recordedBy: currentUserId,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Routine>(
      ref: _ref,
      table: 'routines',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('routines')
            .insert(payload)
            .select()
            .single();
        return Routine.fromMap(r);
      },
      // 오프라인 옵티미스틱 — id 는 클라가 정한 것 그대로
      optimisticResult: () => draft,
    );
  }

  Future<Routine> update(Routine routine) async {
    final payload = routine.toUpdateMap();
    return OfflineWrites.execute<Routine>(
      ref: _ref,
      table: 'routines',
      op: 'update',
      rowId: routine.id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('routines')
            .update(payload)
            .eq('id', routine.id)
            .select()
            .single();
        return Routine.fromMap(r);
      },
      optimisticResult: () => routine,
    );
  }

  Future<void> delete(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'routines',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('routines').delete().eq('id', id);
      },
    );
  }

  Future<List<Routine>> listRecent(String childId, {int limit = 30}) async {
    final rows = await _client
        .from('routines')
        .select()
        .eq('child_id', childId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Routine.fromMap(r)).toList();
  }

  Future<List<Routine>> listRecentByKind(
    String childId,
    RoutineKind kind, {
    int limit = 20,
  }) async {
    final rows = await _client
        .from('routines')
        .select()
        .eq('child_id', childId)
        .eq('kind', kind.dbValue)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Routine.fromMap(r)).toList();
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(ref.watch(supabaseClientProvider), ref);
});
