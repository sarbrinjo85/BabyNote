import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/growth.dart';

class GrowthRepository {
  GrowthRepository(this._client);

  final SupabaseClient _client;

  Future<Growth> createGrowth({
    required String currentUserId,
    required String childId,
    required DateTime measuredAt,
    int? weightG,
    int? heightMm,
    int? headCircumferenceMm,
    String? note,
  }) async {
    final draft = Growth(
      id: 'pending',
      childId: childId,
      measuredAt: measuredAt,
      weightG: weightG,
      heightMm: heightMm,
      headCircumferenceMm: headCircumferenceMm,
      note: note,
    );
    final inserted = await _client
        .from('growths')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Growth.fromMap(inserted);
  }

  /// 성장 기록 1건 삭제.
  Future<void> deleteGrowth(String id) async {
    await _client.from('growths').delete().eq('id', id);
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
  return GrowthRepository(ref.watch(supabaseClientProvider));
});
