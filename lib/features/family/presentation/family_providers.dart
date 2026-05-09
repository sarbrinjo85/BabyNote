import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../child/presentation/child_providers.dart';
import '../data/family_repository.dart';
import '../domain/caregiver.dart';
import '../domain/caregiver_invite.dart';

/// 자녀의 caregivers 목록 (user_profile JOIN).
final caregiversProvider =
    FutureProvider.family<List<Caregiver>, String>((ref, childId) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.listCaregivers(childId);
});

/// 자녀의 활성 초대 코드들.
final activeInvitesProvider =
    FutureProvider.family<List<CaregiverInvite>, String>((ref, childId) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.listActiveInvites(childId);
});

/// 가족 액션 컨트롤러 — 초대 발급/회수/제거.
class FamilyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CaregiverInvite> createInvite({
    required String childId,
    String role = 'parent',
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    final repo = ref.read(familyRepositoryProvider);
    final invite = await repo.createInvite(
      childId: childId,
      createdBy: user.id,
      role: role,
    );
    ref.invalidate(activeInvitesProvider(childId));
    return invite;
  }

  Future<void> revokeInvite(String childId, String inviteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(familyRepositoryProvider);
      await repo.revokeInvite(inviteId);
      ref.invalidate(activeInvitesProvider(childId));
    });
  }

  Future<void> removeCaregiver(String childId, String caregiverId) async {
    // 마지막 보호자 나가기 방지 — 자녀가 orphan 되는 사고 차단.
    final caregivers = await ref.read(caregiversProvider(childId).future);
    if (caregivers.length <= 1) {
      throw StateError(
        '마지막 보호자는 나갈 수 없어요. 다른 가족을 먼저 초대해주세요.',
      );
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(familyRepositoryProvider);
      await repo.removeCaregiver(caregiverId);
      ref.invalidate(caregiversProvider(childId));
    });
  }

  /// 초대 코드 사용. 성공 시 자녀 목록도 invalidate해서 새 자녀 보이게.
  Future<String> redeemInvite(String code) async {
    final repo = ref.read(familyRepositoryProvider);
    final childId = await repo.redeemInvite(code);
    ref.invalidate(myChildrenProvider);
    ref.invalidate(caregiversProvider(childId));
    return childId;
  }
}

final familyControllerProvider =
    AsyncNotifierProvider<FamilyController, void>(FamilyController.new);
