import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/diaper.dart';

/// diapers 테이블 CRUD. 패턴은 F1(feedings)과 동일.
class DiaperRepository {
  DiaperRepository(this._client);

  final SupabaseClient _client;

  Future<Diaper> createDiaper({
    required String currentUserId,
    required String childId,
    required String type,
    required DateTime recordedAt,
    String? color,
    String? consistency,
    String? amount,
    String? diaperInventoryId,
    String? note,
  }) async {
    final draft = Diaper(
      id: 'pending',
      childId: childId,
      recordedAt: recordedAt,
      type: type,
      color: color,
      consistency: consistency,
      amount: amount,
      diaperInventoryId: diaperInventoryId,
      note: note,
    );

    final inserted = await _client
        .from('diapers')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Diaper.fromMap(inserted);
  }

  /// 기저귀 기록 1건 삭제.
  Future<void> deleteDiaper(String id) async {
    await _client.from('diapers').delete().eq('id', id);
  }

  /// 기저귀 기록 수정 — type/color/consistency/amount/note 변경 가능.
  /// diaper_inventory_id는 자동 연결 보존.
  Future<void> updateDiaper({
    required String id,
    required String type,
    String? color,
    String? consistency,
    String? amount,
    String? note,
  }) async {
    final patch = <String, dynamic>{
      'type': type,
      'color': color,
      'consistency': consistency,
      'amount': amount,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    };
    await _client.from('diapers').update(patch).eq('id', id);
  }

  Future<List<Diaper>> listRecent(String childId, {int limit = 20}) async {
    final rows = await _client
        .from('diapers')
        .select()
        .eq('child_id', childId)
        .order('recorded_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Diaper.fromMap(r)).toList();
  }
}

final diaperRepositoryProvider = Provider<DiaperRepository>((ref) {
  return DiaperRepository(ref.watch(supabaseClientProvider));
});
