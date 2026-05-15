import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/vaccination.dart';

/// vaccinations 테이블 CRUD.
class VaccinationRepository {
  VaccinationRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  /// 자녀의 모든 접종 기록.
  Future<List<Vaccination>> listForChild(String childId) async {
    final rows = await _client
        .from('vaccinations')
        .select()
        .eq('child_id', childId)
        .order('administered_at', ascending: false, nullsFirst: false);
    return rows.map((r) => Vaccination.fromMap(r)).toList();
  }

  /// 접종 완료 기록 INSERT.
  Future<Vaccination> recordAdministered({
    required String currentUserId,
    required String childId,
    required String vaccineCode,
    required int doseNumber,
    String? vaccineScheduleId,
    required DateTime administeredAt,
    String? hospitalId,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Vaccination(
      id: id,
      childId: childId,
      vaccineCode: vaccineCode,
      doseNumber: doseNumber,
      vaccineScheduleId: vaccineScheduleId,
      administeredAt: administeredAt,
      hospitalId: hospitalId,
      note: note,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Vaccination>(
      ref: _ref,
      table: 'vaccinations',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('vaccinations')
            .insert(payload)
            .select()
            .single();
        return Vaccination.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }
}

final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) {
  return VaccinationRepository(ref.watch(supabaseClientProvider), ref);
});
