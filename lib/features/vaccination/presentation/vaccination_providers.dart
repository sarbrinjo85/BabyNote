import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/vaccination_repository.dart';
import '../data/vaccine_schedule_repository.dart';
import '../domain/vaccination.dart';
import '../domain/vaccine_schedule.dart';

/// 사용자의 country로 표준 예방접종 일정 조회.
///
/// 일단 'KR' 하드코드. 추후 user_profiles.country watch로 확장 예정.
final vaccineSchedulesProvider =
    FutureProvider.family<List<VaccineSchedule>, String>((ref, country) async {
  final repo = ref.watch(vaccineScheduleRepositoryProvider);
  return repo.listByCountry(country);
});

/// 자녀의 접종 기록 목록.
final vaccinationsProvider =
    FutureProvider.family<List<Vaccination>, String>((ref, childId) async {
  final repo = ref.watch(vaccinationRepositoryProvider);
  return repo.listForChild(childId);
});

/// 접종 기록 컨트롤러.
class VaccinationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> recordAdministered({
    required String childId,
    required String vaccineCode,
    required int doseNumber,
    String? vaccineScheduleId,
    required DateTime administeredAt,
    String? hospitalId,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('로그인되지 않았어요.');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(vaccinationRepositoryProvider);
      await repo.recordAdministered(
        currentUserId: user.id,
        childId: childId,
        vaccineCode: vaccineCode,
        doseNumber: doseNumber,
        vaccineScheduleId: vaccineScheduleId,
        administeredAt: administeredAt,
        hospitalId: hospitalId,
        note: note,
      );
      ref.invalidate(vaccinationsProvider(childId));
    });
  }
}

final vaccinationControllerProvider =
    AsyncNotifierProvider<VaccinationController, void>(
        VaccinationController.new);
