import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diaper/data/diaper_repository.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../growth/presentation/growth_providers.dart';
import '../../routine/data/routine_repository.dart';
import '../../routine/domain/routine.dart';
import '../../sleep/data/sleep_repository.dart';
import '../../sleep/domain/sleep.dart';
import '../../symptom/data/symptom_repository.dart';
import '../../symptom/domain/symptom.dart';

/// 통계 화면용 — 최근 200건 데이터.
///
/// recentXProvider(20건)는 홈 마지막 활동 + 오늘 요약용. 통계는 최소 7일치
/// 충분히 커버하려면 limit를 충분히 늘려야 함. 200건이면 활발한 신생아도 7일+ 커버.
final statsFeedingsProvider =
    FutureProvider.family<List<Feeding>, String>((ref, childId) async {
  final repo = ref.watch(feedingRepositoryProvider);
  return repo.listRecent(childId, limit: 1000);
});

final statsSleepsProvider =
    FutureProvider.family<List<Sleep>, String>((ref, childId) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return repo.listRecent(childId, limit: 1000);
});

final statsDiapersProvider =
    FutureProvider.family<List<Diaper>, String>((ref, childId) async {
  final repo = ref.watch(diaperRepositoryProvider);
  return repo.listRecent(childId, limit: 1000);
});

/// 성장 기록 — 모든 기록 (월 단위로 보면 작아서 limit 불필요).
final statsGrowthsProvider = growthsProvider;

/// 루틴 7일치 — 산책/목욕/영양제/간식 통합. UI 에서 kind 별로 그룹화.
final statsRoutinesProvider =
    FutureProvider.family<List<Routine>, String>((ref, childId) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.listRecent(childId, limit: 1000);
});

/// 증상 7일치 — 기침/구토/발진/상처 통합.
final statsSymptomsProvider =
    FutureProvider.family<List<Symptom>, String>((ref, childId) async {
  final repo = ref.watch(symptomRepositoryProvider);
  return repo.listRecent(childId, limit: 1000);
});
