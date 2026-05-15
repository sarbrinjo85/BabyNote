import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/symptom_repository.dart';
import '../domain/symptom.dart';

final recentSymptomsProvider =
    FutureProvider.family<List<Symptom>, String>((ref, childId) async {
  final repo = ref.watch(symptomRepositoryProvider);
  return repo.listRecent(childId);
});

final recentSymptomsByKindProvider = FutureProvider.family<
    List<Symptom>, (String childId, SymptomKind kind)>((ref, key) async {
  final repo = ref.watch(symptomRepositoryProvider);
  return repo.listRecentByKind(key.$1, key.$2);
});

class SymptomController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// 새 증상 기록 + 선택적 사진 업로드.
  ///
  /// photoFile 이 주어지면 먼저 Storage 업로드 → 받은 path 를 photo_path 컬럼에 저장.
  /// 업로드 실패하면 전체 실패 처리 (메모만이라도 남기려면 photoFile null 로 호출).
  Future<void> create({
    required String childId,
    required SymptomKind kind,
    required DateTime occurredAt,
    Severity? severity,
    File? photoFile,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(symptomRepositoryProvider);
      String? photoPath;
      if (photoFile != null) {
        photoPath = await repo.uploadSymptomPhoto(
          userId: user.id,
          file: photoFile,
        );
      }
      await repo.create(
        currentUserId: user.id,
        childId: childId,
        kind: kind,
        occurredAt: occurredAt,
        severity: severity,
        photoPath: photoPath,
        note: note,
      );
      ref.invalidate(recentSymptomsProvider(childId));
      ref.invalidate(recentSymptomsByKindProvider((childId, kind)));
    });
  }

  Future<void> saveEdit({
    required Symptom symptom,
    File? newPhotoFile,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(symptomRepositoryProvider);
      String? finalPhotoPath = symptom.photoPath;
      if (newPhotoFile != null) {
        finalPhotoPath = await repo.uploadSymptomPhoto(
          userId: user.id,
          file: newPhotoFile,
        );
      }
      final updated = Symptom(
        id: symptom.id,
        childId: symptom.childId,
        kind: symptom.kind,
        occurredAt: symptom.occurredAt,
        severity: symptom.severity,
        photoPath: finalPhotoPath,
        note: symptom.note,
        recordedBy: symptom.recordedBy,
        createdAt: symptom.createdAt,
      );
      await repo.update(updated);
      ref.invalidate(recentSymptomsProvider(symptom.childId));
      ref.invalidate(
          recentSymptomsByKindProvider((symptom.childId, symptom.kind)));
    });
  }

  Future<void> deleteSymptom({
    required String childId,
    required String id,
    required SymptomKind kind,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(symptomRepositoryProvider);
      await repo.delete(id);
      ref.invalidate(recentSymptomsProvider(childId));
      ref.invalidate(recentSymptomsByKindProvider((childId, kind)));
    });
  }
}

final symptomControllerProvider =
    AsyncNotifierProvider<SymptomController, void>(SymptomController.new);
