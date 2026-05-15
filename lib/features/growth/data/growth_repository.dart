import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/growth.dart';

class GrowthRepository {
  GrowthRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Growth> createGrowth({
    required String currentUserId,
    required String childId,
    required DateTime measuredAt,
    int? weightG,
    int? heightMm,
    int? headCircumferenceMm,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Growth(
      id: id,
      childId: childId,
      measuredAt: measuredAt,
      weightG: weightG,
      heightMm: heightMm,
      headCircumferenceMm: headCircumferenceMm,
      note: note,
      recordedBy: currentUserId,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Growth>(
      ref: _ref,
      table: 'growths',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r =
            await _client.from('growths').insert(payload).select().single();
        return Growth.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  Future<void> deleteGrowth(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'growths',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('growths').delete().eq('id', id);
      },
    );
  }

  Future<void> updateGrowth({
    required String id,
    required DateTime measuredAt,
    int? weightG,
    int? heightMm,
    int? headCircumferenceMm,
    String? note,
  }) async {
    final patch = <String, dynamic>{
      'measured_at': '${measuredAt.year}-${measuredAt.month.toString().padLeft(2, '0')}-${measuredAt.day.toString().padLeft(2, '0')}',
      'weight_g': weightG,
      'height_mm': heightMm,
      'head_circumference_mm': headCircumferenceMm,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    };
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'growths',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        await _client.from('growths').update(patch).eq('id', id);
      },
    );
  }

  /// 성장 기록은 차트로도 보여줘야 해서 시간 순서가 중요.
  /// asc로 가져오면 그래프에 그대로 사용 가능.
  Future<List<Growth>> listAll(String childId) async {
    final rows = await _client
        .from('growths')
        .select()
        .eq('child_id', childId)
        .order('measured_at', ascending: true);
    return rows.map((r) => Growth.fromMap(r)).toList();
  }
}

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  return GrowthRepository(ref.watch(supabaseClientProvider), ref);
});
