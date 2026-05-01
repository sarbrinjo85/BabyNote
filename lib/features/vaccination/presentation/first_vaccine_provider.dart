import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vaccine_schedule_repository.dart';
import '../domain/vaccine_schedule.dart';

/// "한국 첫 번째(생후 가장 이른) 예방접종"을 비동기로 가져오는 provider.
///
/// ── FutureProvider란 ───────────────────────────────────────────────
/// 비동기 결과를 위젯에 노출하는 provider. UI 쪽에서 `ref.watch(...)`로
/// 구독하면 자동으로 `AsyncValue<T>`(loading / error / data) 형태로 받게 됨.
/// 즉 위젯은 setState 없이도 "로딩 중 → 결과 도착" 흐름을 표현할 수 있음.
///
/// ── 왜 ref.read가 아니라 ref.watch ─────────────────────────────────
/// 한 번만 읽으면 충분한 의존성(=초기화 시점에만 필요)은 read.
/// 값이 바뀌면 함께 갱신되어야 하는 의존성은 watch.
/// 여기서 repository는 supabase 클라이언트가 바뀌면 같이 바뀌어야 하므로 watch.
final firstKoreanVaccineProvider = FutureProvider<VaccineSchedule?>((ref) async {
  final repo = ref.watch(vaccineScheduleRepositoryProvider);
  return repo.fetchEarliestKoreanVaccine();
});
