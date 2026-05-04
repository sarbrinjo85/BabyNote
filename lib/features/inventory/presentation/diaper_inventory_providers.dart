import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/diaper_inventory_repository.dart';
import '../domain/diaper_inventory.dart';

final diaperInventoriesProvider =
    FutureProvider.family<List<DiaperInventory>, String>((ref, childId) async {
  final repo = ref.watch(diaperInventoryRepositoryProvider);
  return repo.listAll(childId);
});

final activeDiaperInventoriesProvider =
    FutureProvider.family<List<DiaperInventory>, String>((ref, childId) async {
  final repo = ref.watch(diaperInventoryRepositoryProvider);
  return repo.listActive(childId);
});

class DiaperInventoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String childId,
    required String size,
    required int quantity,
    String? brand,
    String? usageKind,
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
      final repo = ref.read(diaperInventoryRepositoryProvider);
      final draft = DiaperInventory(
        id: 'pending',
        childId: childId,
        size: size,
        quantity: quantity,
        brand: brand,
        usageKind: usageKind,
        purchasedAt: purchasedAt,
        priceMinor: priceMinor,
        currency: currency,
        store: store,
        openedAt: openedAt,
      );
      await repo.create(currentUserId: user.id, draft: draft);
      ref.invalidate(diaperInventoriesProvider(childId));
      ref.invalidate(activeDiaperInventoriesProvider(childId));
    });
  }

  Future<void> open(String childId, String inventoryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(diaperInventoryRepositoryProvider);
      await repo.markOpened(inventoryId);
      ref.invalidate(diaperInventoriesProvider(childId));
      ref.invalidate(activeDiaperInventoriesProvider(childId));
    });
  }

  Future<void> deplete(String childId, String inventoryId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(diaperInventoryRepositoryProvider);
      await repo.markDepleted(inventoryId);
      ref.invalidate(diaperInventoriesProvider(childId));
      ref.invalidate(activeDiaperInventoriesProvider(childId));
    });
  }
}

final diaperInventoryControllerProvider =
    AsyncNotifierProvider<DiaperInventoryController, void>(
        DiaperInventoryController.new);


/// 기저귀 팩의 잔량 stats. 분유 패턴 동일.
final diaperInventoryStatsProvider =
    FutureProvider.family<DiaperInventoryStats, DiaperInventory>(
        (ref, inv) async {
  final repo = ref.watch(diaperInventoryRepositoryProvider);
  final consumedCount = await repo.countUsed(inv.id);

  int daysOpened = 1;
  if (inv.openedAt != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final opened =
        DateTime(inv.openedAt!.year, inv.openedAt!.month, inv.openedAt!.day);
    final diff = today.difference(opened).inDays;
    daysOpened = diff <= 0 ? 1 : diff;
  }
  final dailyAvgCount = consumedCount / daysOpened;

  final remaining = (inv.quantity - consumedCount).clamp(0, 1 << 31);
  final expectedDaysLeft =
      dailyAvgCount > 0.1 ? remaining / dailyAvgCount : 999.0;
  final confidence = daysOpened < 7 ? 'low' : 'normal';

  return DiaperInventoryStats(
    inventory: inv,
    consumedCount: consumedCount,
    dailyAvgCount: dailyAvgCount,
    expectedDaysLeft: expectedDaysLeft,
    confidence: confidence,
  );
});
