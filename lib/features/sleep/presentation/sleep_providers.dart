import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/sleep_repository.dart';
import '../domain/sleep.dart';

/// 특정 자녀의 진행 중 수면 1건 (없으면 null).
///
/// ── family + autoDispose ─────────────────────────────────────────────
/// 자녀별로 캐시 분리(`family`). 자동 dispose는 안 씀 — 같은 자녀를 여러 화면에서
/// 동시 watch해도 같은 인스턴스 공유.
final ongoingSleepProvider =
    FutureProvider.family<Sleep?, String>((ref, childId) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.findOngoing(childId);
});

/// 최근 수면 기록 N건.
final recentSleepsProvider =
    FutureProvider.family<List<Sleep>, String>((ref, childId) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.listRecent(childId);
});

/// 수면 시작/종료 컨트롤러.
///
/// AsyncNotifier 한 클래스에 두 메서드(start/end). state.AsyncValue가
/// 진행 상태를 표현하므로 화면이 그걸 watch해서 버튼 disable/스피너 처리.
class SleepController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> startSleep({
    required String childId,
    required String napOrNight,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sleepRepositoryProvider);
      await repo.startSleep(
        currentUserId: user.id,
        childId: childId,
        napOrNight: napOrNight,
        note: note,
      );
      ref.invalidate(ongoingSleepProvider(childId));
      ref.invalidate(recentSleepsProvider(childId));
    });
  }

  Future<void> endSleep({
    required String childId,
    required String sleepId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sleepRepositoryProvider);
      await repo.endSleep(sleepId: sleepId, endedAt: DateTime.now());
      ref.invalidate(ongoingSleepProvider(childId));
      ref.invalidate(recentSleepsProvider(childId));
    });
  }

  /// 기존 수면 기록 수정 — napOrNight + note만.
  Future<void> saveEdit({
    required String childId,
    required String id,
    required String napOrNight,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sleepRepositoryProvider);
      await repo.updateSleep(id: id, napOrNight: napOrNight, note: note);
      ref.invalidate(recentSleepsProvider(childId));
      ref.invalidate(ongoingSleepProvider(childId));
    });
  }
}

final sleepControllerProvider =
    AsyncNotifierProvider<SleepController, void>(SleepController.new);
