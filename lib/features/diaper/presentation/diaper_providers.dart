import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/diaper_repository.dart';
import '../domain/diaper.dart';

/// 자녀별 최근 기저귀 기록.
final recentDiapersProvider =
    FutureProvider.family<List<Diaper>, String>((ref, childId) async {
  final repo = ref.watch(diaperRepositoryProvider);
  return repo.listRecent(childId);
});

/// 기저귀 등록 컨트롤러.
class DiaperCreationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required String type,
    String? color,
    String? consistency,
    String? amount,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(diaperRepositoryProvider);
      await repo.createDiaper(
        currentUserId: user.id,
        childId: childId,
        type: type,
        recordedAt: DateTime.now(),
        color: color,
        consistency: consistency,
        amount: amount,
        note: note,
      );
      ref.invalidate(recentDiapersProvider(childId));
    });
  }
}

final diaperCreationControllerProvider =
    AsyncNotifierProvider<DiaperCreationController, void>(
        DiaperCreationController.new);
