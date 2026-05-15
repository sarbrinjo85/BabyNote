import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/routine_repository.dart';
import '../domain/routine.dart';

/// 자녀별 최근 루틴 기록 (모든 kind 혼합) — 홈/통계용.
final recentRoutinesProvider =
    FutureProvider.family<List<Routine>, String>((ref, childId) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.listRecent(childId);
});

/// kind 필터링용 family — (childId, kind) 튜플.
///
/// Riverpod family 는 단일 인자만 받기에 record 타입 ((String, RoutineKind))
/// 으로 묶어서 전달.
final recentRoutinesByKindProvider = FutureProvider.family<
    List<Routine>, (String childId, RoutineKind kind)>((ref, key) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.listRecentByKind(key.$1, key.$2);
});

/// 등록/수정/삭제 컨트롤러.
class RoutineController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required RoutineKind kind,
    required DateTime startedAt,
    int? durationMin,
    String? itemName,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(routineRepositoryProvider);
      await repo.create(
        currentUserId: user.id,
        childId: childId,
        kind: kind,
        startedAt: startedAt,
        durationMin: durationMin,
        itemName: itemName,
        note: note,
      );
      ref.invalidate(recentRoutinesProvider(childId));
      ref.invalidate(recentRoutinesByKindProvider((childId, kind)));
    });
  }

  Future<void> saveEdit({
    required Routine routine,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(routineRepositoryProvider);
      await repo.update(routine);
      ref.invalidate(recentRoutinesProvider(routine.childId));
      ref.invalidate(recentRoutinesByKindProvider((routine.childId, routine.kind)));
    });
  }

  Future<void> deleteRoutine({
    required String childId,
    required String id,
    required RoutineKind kind,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(routineRepositoryProvider);
      await repo.delete(id);
      ref.invalidate(recentRoutinesProvider(childId));
      ref.invalidate(recentRoutinesByKindProvider((childId, kind)));
    });
  }
}

final routineControllerProvider =
    AsyncNotifierProvider<RoutineController, void>(RoutineController.new);
