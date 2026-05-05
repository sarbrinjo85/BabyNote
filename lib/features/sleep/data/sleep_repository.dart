import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/sleep.dart';

/// sleeps 테이블 CRUD.
///
/// ── F1과 다른 점 ─────────────────────────────────────────────────────
/// 수유는 한 번 INSERT로 끝이지만 수면은 두 단계:
///   1) startSleep — INSERT (ended_at = NULL = 진행 중)
///   2) endSleep   — UPDATE (ended_at = now)
class SleepRepository {
  SleepRepository(this._client);

  final SupabaseClient _client;

  /// 수면 시작.
  Future<Sleep> startSleep({
    required String currentUserId,
    required String childId,
    required String napOrNight,
    String? note,
  }) async {
    final draft = Sleep(
      id: 'pending',
      childId: childId,
      startedAt: DateTime.now(),
      napOrNight: napOrNight,
      note: note,
    );
    final inserted = await _client
        .from('sleeps')
        .insert(draft.toStartInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Sleep.fromMap(inserted);
  }

  /// 진행 중 수면 종료.
  ///
  /// ── update + eq + select 패턴 ────────────────────────────────────
  /// .update({})는 set 절. .eq()로 WHERE id = $1. .select().single()로
  /// 변경된 row 받음.
  Future<Sleep> endSleep({
    required String sleepId,
    required DateTime endedAt,
  }) async {
    final updated = await _client
        .from('sleeps')
        .update({'ended_at': endedAt.toUtc().toIso8601String()})
        .eq('id', sleepId)
        .select()
        .single();
    return Sleep.fromMap(updated);
  }

  /// 진행 중인 수면 1건 (한 자녀당 1건이라고 가정). 없으면 null.
  Future<Sleep?> findOngoing(String childId) async {
    final row = await _client
        .from('sleeps')
        .select()
        .eq('child_id', childId)
        .filter('ended_at', 'is', null) // ended_at IS NULL
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Sleep.fromMap(row);
  }

  /// 수면 기록 1건 삭제.
  Future<void> deleteSleep(String id) async {
    await _client.from('sleeps').delete().eq('id', id);
  }

  /// 최근 수면 기록 N건.
  Future<List<Sleep>> listRecent(String childId, {int limit = 20}) async {
    final rows = await _client
        .from('sleeps')
        .select()
        .eq('child_id', childId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Sleep.fromMap(r)).toList();
  }
}

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepository(ref.watch(supabaseClientProvider));
});
