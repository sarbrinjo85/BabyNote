import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/routine.dart';

/// routines 테이블 CRUD — 산책/목욕/영양제/간식 4종 통합.
///
/// ── 비교: sleep_repository ────────────────────────────────────────────
/// 수면은 진행 중 상태(ended_at = NULL)가 의미 있어서 start/end 2단계.
/// 루틴은 다 한 번에 INSERT — 산책도 끝난 후 "산책 30분" 식으로 기록.
class RoutineRepository {
  RoutineRepository(this._client);

  final SupabaseClient _client;

  /// 새 기록 1건 추가.
  Future<Routine> create({
    required String currentUserId,
    required String childId,
    required RoutineKind kind,
    required DateTime startedAt,
    int? durationMin,
    String? itemName,
    String? note,
  }) async {
    final draft = Routine(
      id: 'pending',
      childId: childId,
      kind: kind,
      startedAt: startedAt,
      durationMin: durationMin,
      itemName: itemName,
      note: note,
    );
    final inserted = await _client
        .from('routines')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Routine.fromMap(inserted);
  }

  /// 기존 기록 수정 — kind 는 변경 불가 (kind가 바뀌면 사실상 다른 기록).
  Future<Routine> update(Routine routine) async {
    final updated = await _client
        .from('routines')
        .update(routine.toUpdateMap())
        .eq('id', routine.id)
        .select()
        .single();
    return Routine.fromMap(updated);
  }

  Future<void> delete(String id) async {
    await _client.from('routines').delete().eq('id', id);
  }

  /// 자녀별 최근 기록 (모든 kind 혼합) — 홈 그리드/통계용.
  Future<List<Routine>> listRecent(String childId, {int limit = 30}) async {
    final rows = await _client
        .from('routines')
        .select()
        .eq('child_id', childId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Routine.fromMap(r)).toList();
  }

  /// 자녀 + kind 별 최근 기록 — "최근 산책 1건", "최근 목욕 1건" 등.
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
  return RoutineRepository(ref.watch(supabaseClientProvider));
});
