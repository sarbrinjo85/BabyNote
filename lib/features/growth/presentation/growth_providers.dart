import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/growth_repository.dart';
import '../domain/growth.dart';

/// 자녀의 모든 성장 기록 (시간 순). 차트/통계에 그대로 사용 가능.
final growthsProvider =
    FutureProvider.family<List<Growth>, String>((ref, childId) async {
  final repo = ref.watch(growthRepositoryProvider);
  return repo.listAll(childId);
});

class GrowthCreationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required DateTime measuredAt,
    int? weightG,
    int? heightMm,
    int? headCircumferenceMm,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(growthRepositoryProvider);
      await repo.createGrowth(
        currentUserId: user.id,
        childId: childId,
        measuredAt: measuredAt,
        weightG: weightG,
        heightMm: heightMm,
        headCircumferenceMm: headCircumferenceMm,
        note: note,
      );
      ref.invalidate(growthsProvider(childId));
    });
  }
}

final growthCreationControllerProvider =
    AsyncNotifierProvider<GrowthCreationController, void>(
        GrowthCreationController.new);
