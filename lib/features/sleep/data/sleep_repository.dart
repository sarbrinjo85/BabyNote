import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/sleep.dart';

/// sleeps 테이블 CRUD.
///
/// ── F1과 다른 점 ─────────────────────────────────────────────────────
/// 수유는 한 번 INSERT로 끝이지만 수면은 두 단계:
///   1) startSleep — INSERT (ended_at = NULL = 진행 중)
///   2) endSleep   — UPDATE (ended_at = now)
///
/// ── 오프라인 ─────────────────────────────────────────────────────────
/// 두 단계 다 큐잉 가능. startSleep 시 클라이언트 UUID 발급 → 같은 id 로
/// endSleep update 큐잉. flush 시 INSERT 가 먼저, 그 다음 UPDATE 가 순서대로
/// 적용됨 (enqueued_at ASC 순).
class SleepRepository {
  SleepRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Sleep> startSleep({
    required String currentUserId,
    required String childId,
    required String napOrNight,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Sleep(
      id: id,
      childId: childId,
      startedAt: DateTime.now(),
      napOrNight: napOrNight,
      note: note,
      recordedBy: currentUserId,
    );
    final payload = draft.toStartInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Sleep>(
      ref: _ref,
      table: 'sleeps',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r =
            await _client.from('sleeps').insert(payload).select().single();
        return Sleep.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  /// 진행 중 수면 종료.
  Future<Sleep> endSleep({
    required String sleepId,
    required DateTime endedAt,
  }) async {
    final patch = {'ended_at': endedAt.toUtc().toIso8601String()};
    return OfflineWrites.execute<Sleep>(
      ref: _ref,
      table: 'sleeps',
      op: 'update',
      rowId: sleepId,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('sleeps')
            .update(patch)
            .eq('id', sleepId)
            .select()
            .single();
        return Sleep.fromMap(r);
      },
      // 옵티미스틱 — child/napOrNight 등은 알 수 없어 invalidate 후 갱신
      optimisticResult: () => Sleep(
        id: sleepId,
        childId: '',
        startedAt: endedAt.subtract(const Duration(minutes: 30)),
        endedAt: endedAt,
        napOrNight: Sleep.classifyNapOrNight(endedAt),
      ),
    );
  }

  /// 진행 중인 수면 1건 (한 자녀당 1건이라고 가정). 없으면 null.
  Future<Sleep?> findOngoing(String childId) async {
    final row = await _client
        .from('sleeps')
        .select()
        .eq('child_id', childId)
        .filter('ended_at', 'is', null)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Sleep.fromMap(row);
  }

  Future<void> deleteSleep(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'sleeps',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('sleeps').delete().eq('id', id);
      },
    );
  }

  Future<void> updateSleep({
    required String id,
    required String napOrNight,
    String? note,
  }) async {
    final patch = <String, dynamic>{
      'nap_or_night': napOrNight,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    };
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'sleeps',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        await _client.from('sleeps').update(patch).eq('id', id);
      },
    );
  }

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
  return SleepRepository(ref.watch(supabaseClientProvider), ref);
});
