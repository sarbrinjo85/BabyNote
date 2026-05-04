import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/hospital.dart';

class HospitalRepository {
  HospitalRepository(this._client);

  final SupabaseClient _client;

  Future<Hospital> create({
    required String currentUserId,
    required Hospital draft,
  }) async {
    final inserted = await _client
        .from('hospitals')
        .insert(draft.toInsertMap(userId: currentUserId))
        .select()
        .single();
    return Hospital.fromMap(inserted);
  }

  /// 본인 소유 병원 목록 (default 먼저).
  Future<List<Hospital>> listMine() async {
    final rows = await _client
        .from('hospitals')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);
    return rows.map((r) => Hospital.fromMap(r)).toList();
  }

  Future<void> setDefault(String hospitalId) async {
    // 단순화: 호출 측이 "기존 default 해제 → 새 default" 두 번 호출.
    // 더 견고하게 하려면 RPC로 트랜잭션 처리.
    await _client.from('hospitals').update({'is_default': false}).neq('id', hospitalId);
    await _client.from('hospitals').update({'is_default': true}).eq('id', hospitalId);
  }

  Future<void> delete(String hospitalId) async {
    await _client.from('hospitals').delete().eq('id', hospitalId);
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository(ref.watch(supabaseClientProvider));
});
