import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/hospital_repository.dart';
import '../domain/hospital.dart';

final myHospitalsProvider = FutureProvider<List<Hospital>>((ref) async {
  // currentUser 의존성 — 사용자 변경 시 자동 재계산
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final repo = ref.watch(hospitalRepositoryProvider);
  return repo.listMine();
});

class HospitalController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String name,
    String? specialty,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? note,
    bool isDefault = false,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('로그인되지 않았어요.');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(hospitalRepositoryProvider);
      final draft = Hospital(
        id: 'pending',
        userId: user.id,
        name: name,
        specialty: specialty,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        note: note,
        isDefault: isDefault,
      );
      await repo.create(currentUserId: user.id, draft: draft);
      ref.invalidate(myHospitalsProvider);
    });
  }

  Future<void> setDefault(String hospitalId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(hospitalRepositoryProvider);
      await repo.setDefault(hospitalId);
      ref.invalidate(myHospitalsProvider);
    });
  }

  Future<void> delete(String hospitalId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(hospitalRepositoryProvider);
      await repo.delete(hospitalId);
      ref.invalidate(myHospitalsProvider);
    });
  }

  /// 병원 정보 수정. isDefault가 true면 setDefault 후속 호출 (다른 병원 default 해제).
  Future<void> saveEdit({
    required String id,
    required String name,
    String? specialty,
    String? phone,
    String? address,
    String? note,
    required bool isDefault,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(hospitalRepositoryProvider);
      await repo.update(
        id: id,
        name: name,
        specialty: specialty,
        phone: phone,
        address: address,
        note: note,
        isDefault: isDefault,
      );
      // isDefault가 true면 다른 병원도 false로 만들기 (단일 default 보장)
      if (isDefault) {
        await repo.setDefault(id);
      }
      ref.invalidate(myHospitalsProvider);
    });
  }
}

final hospitalControllerProvider =
    AsyncNotifierProvider<HospitalController, void>(HospitalController.new);
