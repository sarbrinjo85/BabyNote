import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/feeding_repository.dart';
import '../domain/feeding.dart';

/// 특정 자녀의 최근 수유 기록 (가족 함께 보임).
///
/// `family` 변형 — child_id를 매번 인자로 받아 별도 인스턴스가 생성됨.
/// (홈에 자녀가 여러 명 있어도 자녀별로 캐시 분리.)
final recentFeedingsProvider =
    FutureProvider.family<List<Feeding>, String>((ref, childId) async {
  final repo = ref.watch(feedingRepositoryProvider);
  return repo.listRecent(childId);
});

/// 수유 등록 컨트롤러 (AsyncNotifier).
///
/// 기록 타입(모유/분유/이유식)마다 채워지는 필드가 다르므로 메서드 인자는 모두 nullable.
/// 호출 측이 type에 맞춰 필요한 필드만 채우면 됨.
class FeedingCreationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required String type,
    required DateTime startedAt,
    DateTime? endedAt,
    int? amountMl,
    String? breastSide,
    String? foodName,
    String? formulaBrand,
    String? formulaInventoryId,
    String? note,
    /// 첨부 사진(있으면). 업로드 후 path를 photo_path 컬럼에 저장.
    File? photoFile,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(feedingRepositoryProvider);

      // 사진 있으면 먼저 Storage 업로드 → path 받기
      String? photoPath;
      if (photoFile != null) {
        photoPath = await repo.uploadFeedingPhoto(
          userId: user.id,
          file: photoFile,
        );
      }

      await repo.createFeeding(
        currentUserId: user.id,
        childId: childId,
        type: type,
        startedAt: startedAt,
        endedAt: endedAt,
        amountMl: amountMl,
        breastSide: breastSide,
        foodName: foodName,
        formulaBrand: formulaBrand,
        formulaInventoryId: formulaInventoryId,
        note: note,
        photoPath: photoPath,
      );
      // 같은 자녀의 최근 기록 캐시 무효화 → 홈/목록 새로고침
      ref.invalidate(recentFeedingsProvider(childId));
      // 분유 등록 시 잔량 stats 갱신 트리거
      // (formulaInventoryStatsProvider는 family<..., FormulaInventory>라 인자 객체 단위 캐시. 전체 inventories도 같이 invalidate해서 stats provider 재구독 시 재계산)
    });
  }
}

final feedingCreationControllerProvider =
    AsyncNotifierProvider<FeedingCreationController, void>(
        FeedingCreationController.new);
