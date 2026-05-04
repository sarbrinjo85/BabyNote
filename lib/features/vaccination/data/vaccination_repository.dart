import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/vaccination.dart';

/// vaccinations 테이블 CRUD.
class VaccinationRepository {
  VaccinationRepository(this._client);

  final SupabaseClient _client;

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
    final draft = Vaccination(
      id: 'pending',
      childId: childId,
      vaccineCode: vaccineCode,
      doseNumber: doseNumber,
      vaccineScheduleId: vaccineScheduleId,
      administeredAt: administeredAt,
      hospitalId: hospitalId,
      note: note,
    );
    final inserted = await _client
        .from('vaccinations')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Vaccination.fromMap(inserted);
  }
}

final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) {
  return VaccinationRepository(ref.watch(supabaseClientProvider));
});
