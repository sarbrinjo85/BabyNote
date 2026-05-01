import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/child_repository.dart';
import '../domain/child.dart';

/// 내가 케어기버로 묶여있는 자녀 목록.
///
/// ── ref.watch 의존성 그래프 ───────────────────────────────────────
/// myChildrenProvider
///   ├─ childRepositoryProvider (Repository)
///   └─ currentUserProvider     (User?)
///
/// currentUser가 바뀌면(로그아웃→재로그인 등) 이 provider가 자동으로 다시 계산됨.
/// → 사용자 전환 시 데이터 누수 없음.
final myChildrenProvider = FutureProvider<List<Child>>((ref) async {
  // 비로그인이면 빈 목록 반환 (RLS가 어차피 0행 돌려줄 테지만 명시적으로 처리).
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final repo = ref.watch(childRepositoryProvider);
  return repo.listMyChildren();
});

/// 자녀 등록(create) 동작 + 진행 상태를 묶은 컨트롤러.
///
/// ── AsyncNotifier 패턴 ────────────────────────────────────────────
/// AsyncNotifier는 Riverpod 2.x에서 권장되는 "비동기 명령(command) + 상태" 묶음.
/// state는 `AsyncValue<T>` — loading / error / data 자동 전이.
/// 위젯은 ref.watch로 진행 상태 구독, ref.read(provider.notifier)로 메서드 호출.
///
/// 여기서 T = void (생성된 Child를 굳이 들고있을 필요 없음 — 목록 provider invalidate로 새로고침).
class ChildCreationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 초기 상태: data(null)와 동등. 사용자가 submit 누르기 전엔 idle.
    return;
  }

  Future<void> create({
    required String name,
    required DateTime birthDate,
    String? gender,
    int? birthWeightG,
    int? birthHeightMm,
  }) async {
    // 비로그인 사전 차단 (서버는 RLS로 막지만 빠른 UX 피드백을 위해 클라에서도 체크)
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않은 상태에서는 자녀를 등록할 수 없어요.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(childRepositoryProvider);
      await repo.createChild(
        name: name,
        birthDate: birthDate,
        gender: gender,
        birthWeightG: birthWeightG,
        birthHeightMm: birthHeightMm,
      );
      ref.invalidate(myChildrenProvider);
    });
  }
}

/// AsyncNotifierProvider 만들기. notifier()는 ChildCreationController 생성자.
final childCreationControllerProvider =
    AsyncNotifierProvider<ChildCreationController, void>(
        ChildCreationController.new);
