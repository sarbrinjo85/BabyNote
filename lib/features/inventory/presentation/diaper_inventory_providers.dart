import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../growth/presentation/growth_providers.dart';
import '../data/diaper_inventory_repository.dart';
import '../domain/diaper_inventory.dart';
import '../domain/diaper_size.dart';

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

/// 기저귀 사이즈업 예측 — 차별화 ③.
///
/// ── 예측 로직 ────────────────────────────────────────────────────────
/// 1. 활성 기저귀 팩의 size = 현재 사용 중인 사이즈
/// 2. 자녀의 최근 weight + 성장 속도(g/일) 계산
/// 3. (현재 사이즈의 maxKg - currentKg) / velocity = 사이즈업까지 남은 일수
///
/// ── 표시 조건 ────────────────────────────────────────────────────────
/// 활성 기저귀 팩 없거나, 체중 기록 없거나, 다음 사이즈가 없으면(XXL) null.
/// 호출 측이 daysToSizeUp 보고 카드 표시 여부 결정.
final diaperSizeUpForecastProvider =
    FutureProvider.family<DiaperSizeForecast?, String>((ref, childId) async {
  // 1. 현재 사이즈 (활성 팩에서)
  final actives =
      await ref.watch(activeDiaperInventoriesProvider(childId).future);
  if (actives.isEmpty) return null;
  final currentSize = actives.first.size;
  final sizeInfo = DiaperSizeInfo.byCode(currentSize);
  if (sizeInfo == null) return null;

  // 2. 최근 체중
  final growths = await ref.watch(growthsProvider(childId).future);
  final withWeight = growths.where((g) => g.weightG != null).toList()
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  if (withWeight.isEmpty) return null;

  final latest = withWeight.last;
  final latestKg = latest.weightG! / 1000.0;

  // 3. 성장 속도 (g/day)
  // 기록 2개 이상 → 실측 속도. 1개뿐이면 신생아 평균 25g/day default.
  double velocityGPerDay = 25.0;
  if (withWeight.length >= 2) {
    final first = withWeight.first;
    final dayDiff = latest.measuredAt.difference(first.measuredAt).inDays;
    if (dayDiff > 0) {
      final v = (latest.weightG! - first.weightG!) / dayDiff;
      // 음수(다이어트?)나 비현실적 값은 default로 fallback
      if (v > 0 && v < 100) velocityGPerDay = v;
    }
  }

  // 4. 사이즈업까지 남은 일수
  final remainKg = sizeInfo.maxKg - latestKg;
  final remainG = remainKg * 1000;
  final daysToSizeUp = velocityGPerDay > 0
      ? (remainG / velocityGPerDay).round()
      : 999;

  final urgent = daysToSizeUp <= 7;

  return DiaperSizeForecast(
    currentSize: currentSize,
    currentKg: latestKg,
    maxKg: sizeInfo.maxKg,
    nextSize: sizeInfo.nextSize,
    daysToSizeUp: daysToSizeUp,
    urgent: urgent,
  );
});
