import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/formula_inventory_repository.dart';
import '../domain/formula_inventory.dart';

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
}

final formulaInventoryControllerProvider =
    AsyncNotifierProvider<FormulaInventoryController, void>(
        FormulaInventoryController.new);
