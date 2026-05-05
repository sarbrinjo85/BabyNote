import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/formula_inventory_repository.dart';
import '../domain/formula_inventory.dart';

// FormulaInventoryStats 클래스는 domain/formula_inventory.dart에서 export됨.

/// 자녀의 모든 분유 재고 (활성 + 보관 + 소진).
final formulaInventoriesProvider =
    FutureProvider.family<List<FormulaInventory>, String>((ref, childId) async {
  final repo = ref.watch(formulaInventoryRepositoryProvider);
  return repo.listAll(childId);
});

/// 사용 중(active)만 — 홈 카드 등에 사용.
final activeFormulaInventoriesProvider =
    FutureProvider.family<List<FormulaInventory>, String>((ref, childId) async {
  final repo = ref.watch(formulaInventoryRepositoryProvider);
  return repo.listActive(childId);
});

class FormulaInventoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required String productName,
    String? brand,
    required int containerGrams,
    double mlPerGram = 7.0,
    DateTime? purchasedAt,
    int? priceMinor,
    String currency = 'KRW',
    String? store,
    DateTime? openedAt,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('로그인되지 않았어요.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(formulaInventoryRepositoryProvider);
      final draft = FormulaInventory(
        id: 'pending',
        childId: childId,
        productName: productName,
        brand: brand,
        containerGrams: containerGrams,
        mlPerGram: mlPerGram,
        purchasedAt: purchasedAt,
        priceMinor: priceMinor,
        currency: currency,
        store: store,
        openedAt: openedAt,
      );
      await repo.create(currentUserId: user.id, draft: draft);
      ref.invalidate(formulaInventoriesProvider(childId));
      ref.invalidate(activeFormulaInventoriesProvider(childId));
    });
  }

  Future<void> open(String childId, String inventoryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(formulaInventoryRepositoryProvider);
      await repo.markOpened(inventoryId);
      ref.invalidate(formulaInventoriesProvider(childId));
      ref.invalidate(activeFormulaInventoriesProvider(childId));
    });
  }

  Future<void> deplete(String childId, String inventoryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(formulaInventoryRepositoryProvider);
      await repo.markDepleted(inventoryId);
      ref.invalidate(formulaInventoriesProvider(childId));
      ref.invalidate(activeFormulaInventoriesProvider(childId));
    });
  }

  /// 분유 통 정보 수정 (제품명/용량/구매일/가격/구매처/개봉일 등).
  Future<void> saveEdit({
    required String childId,
    required String id,
    required String productName,
    String? brand,
    required int containerGrams,
    DateTime? purchasedAt,
    int? priceMinor,
    String? store,
    DateTime? openedAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(formulaInventoryRepositoryProvider);
      await repo.updateInventory(
        id: id,
        productName: productName,
        brand: brand,
        containerGrams: containerGrams,
        purchasedAt: purchasedAt,
        priceMinor: priceMinor,
        store: store,
        openedAt: openedAt,
      );
      ref.invalidate(formulaInventoriesProvider(childId));
      ref.invalidate(activeFormulaInventoriesProvider(childId));
      ref.invalidate(formulaInventoryStatsProvider);
    });
  }

  /// 분유 통 삭제. 연결된 수유 기록의 formula_inventory_id는 DB에서 처리.
  Future<void> deleteInventory({
    required String childId,
    required String id,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(formulaInventoryRepositoryProvider);
      await repo.deleteInventory(id);
      ref.invalidate(formulaInventoriesProvider(childId));
      ref.invalidate(activeFormulaInventoriesProvider(childId));
      ref.invalidate(formulaInventoryStatsProvider);
    });
  }
}

final formulaInventoryControllerProvider =
    AsyncNotifierProvider<FormulaInventoryController, void>(
        FormulaInventoryController.new);


/// 한 분유 통의 잔량/소비/소진 예상 통계.
///
/// ── 의존 ─────────────────────────────────────────────────────────────
/// - formula_inventories(repo): 통 정보 (containerGrams, mlPerGram, opened_at 등)
/// - feedings: 그 통에 연결된 수유 기록 합계
///
/// ── 갱신 ─────────────────────────────────────────────────────────────
/// 수유 등록/통 상태 변경 시 invalidate해야 신선한 stats 받음.
/// FeedingCreationController, FormulaInventoryController에서 invalidate 추가 권장.
final formulaInventoryStatsProvider =
    FutureProvider.family<FormulaInventoryStats, FormulaInventory>(
        (ref, inv) async {
  final repo = ref.watch(formulaInventoryRepositoryProvider);
  final consumedMl = await repo.sumConsumedMl(inv.id);
  final consumedG = consumedMl / inv.mlPerGram;

  // 일평균: opened_at 기준 며칠 동안 사용했나
  int daysOpened = 1;
  if (inv.openedAt != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final opened =
        DateTime(inv.openedAt!.year, inv.openedAt!.month, inv.openedAt!.day);
    final diff = today.difference(opened).inDays;
    daysOpened = diff <= 0 ? 1 : diff;
  }
  final dailyAvgG = consumedG / daysOpened;

  // 잔량 (음수 방지) / 소진 예상일 (dailyAvg 0이면 무한)
  final remainingG = (inv.containerGrams - consumedG).clamp(0.0, double.infinity);
  final expectedDaysLeft = dailyAvgG > 0.1 ? remainingG / dailyAvgG : 999.0;

  // 7일 미만 사용은 샘플 적어 신뢰도 낮음
  final confidence = daysOpened < 7 ? 'low' : 'normal';

  return FormulaInventoryStats(
    inventory: inv,
    consumedG: consumedG,
    dailyAvgG: dailyAvgG,
    expectedDaysLeft: expectedDaysLeft,
    confidence: confidence,
  );
});
