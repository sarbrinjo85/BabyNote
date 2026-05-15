import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/hospital.dart';

class HospitalRepository {
  HospitalRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Hospital> create({
    required String currentUserId,
    required Hospital draft,
  }) async {
    final id = genUuid();
    final payload = draft.toInsertMap(userId: currentUserId);
    payload['id'] = id;

    final optimistic = Hospital(
      id: id,
      userId: currentUserId,
      name: draft.name,
      specialty: draft.specialty,
      phone: draft.phone,
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      note: draft.note,
      isDefault: draft.isDefault,
    );

    return OfflineWrites.execute<Hospital>(
      ref: _ref,
      table: 'hospitals',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('hospitals')
            .insert(payload)
            .select()
            .single();
        return Hospital.fromMap(r);
      },
      optimisticResult: () => optimistic,
    );
  }

  Future<List<Hospital>> listMine() async {
    final rows = await _client
        .from('hospitals')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);
    return rows.map((r) => Hospital.fromMap(r)).toList();
  }

  /// is_default 토글 — 큐잉 어려움 (두 개 row 영향 + .neq filter).
  /// 단순화 위해 큐잉 X — 오프라인 시 그대로 실패. 사용자가 재시도.
  Future<void> setDefault(String hospitalId) async {
    await _client.from('hospitals').update({'is_default': false}).neq('id', hospitalId);
    await _client.from('hospitals').update({'is_default': true}).eq('id', hospitalId);
  }

  Future<void> delete(String hospitalId) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'hospitals',
      op: 'delete',
      rowId: hospitalId,
      payload: const {},
      onlineCall: () async {
        await _client.from('hospitals').delete().eq('id', hospitalId);
      },
    );
  }

  Future<Hospital> update({
    required String id,
    required String name,
    String? specialty,
    String? phone,
    String? address,
    String? note,
    required bool isDefault,
  }) async {
    final patch = <String, dynamic>{
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'address': address,
      'note': note,
      'is_default': isDefault,
    };
    return OfflineWrites.execute<Hospital>(
      ref: _ref,
      table: 'hospitals',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('hospitals')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
        return Hospital.fromMap(r);
      },
      optimisticResult: () => Hospital(
        id: id,
        userId: '',
        name: name,
        specialty: specialty,
        phone: phone,
        address: address,
        note: note,
        isDefault: isDefault,
      ),
    );
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository(ref.watch(supabaseClientProvider), ref);
});
