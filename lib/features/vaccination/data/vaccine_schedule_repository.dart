import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/vaccine_schedule.dart';

/// vaccine_schedules 테이블에 대한 데이터 접근 담당.
///
/// ── Repository 패턴이란 ───────────────────────────────────────────────
/// "데이터를 어디서 가져오느냐"(Supabase / 로컬 SQLite / mock)를 한 곳에 캡슐화.
/// presentation 레이어(provider/widget)는 "한국 첫 백신 가져와줘"라고만 부탁하고,
/// 어떻게 가져오는지는 신경 안 씀. 이게 흔들리지 않는 코드의 출발점.
///
/// 지금은 메서드 1개뿐이지만, 곧 fetchByCountry(), fetchByCode() 등이 추가될 거.
class VaccineScheduleRepository {
  VaccineScheduleRepository(this._client);

  // _ 시작 = private (이 파일 밖에서 접근 불가).
  final SupabaseClient _client;

  /// 한국 표준 일정 중 가장 이른(생후 일수 최소) 백신 1개를 반환.
  /// 없으면 null.
  ///
  /// ── async / await ────────────────────────────────────────────────
  /// `async`는 "이 함수는 비동기"라는 표시. 안에서 `await`로 비동기 호출의 결과를
  /// 동기처럼 기다림. 반환 타입은 `Future<T>`로 자동 감쌈.
  ///
  /// ── Supabase 쿼리 빌더 체인 ──────────────────────────────────────
  ///   .from('테이블명')          : 어느 테이블
  ///   .select('컬럼1, 컬럼2')   : 어느 컬럼만 (생략 가능, 생략 시 *)
  ///   .eq('컬럼','값')           : WHERE col = value
  ///   .order(...)                : ORDER BY
  ///   .limit(N)                  : LIMIT N
  ///   .maybeSingle()             : 0~1행 기대, 0행이면 null, 2행 이상이면 에러
  ///
  /// `await`가 끝나면 `Map<String, dynamic>?` 가 반환됨 (single row 또는 null).
  Future<VaccineSchedule?> fetchEarliestKoreanVaccine() async {
    final row = await _client
        .from('vaccine_schedules')
        .select('id, country, code, name, dose_number, recommended_age_days, description')
        .eq('country', 'KR')
        .order('recommended_age_days', ascending: true) // 생후 일수 오름차순
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return VaccineSchedule.fromMap(row);
  }

  /// 한 국가의 모든 표준 예방접종 일정 (생후 일수 순).
  Future<List<VaccineSchedule>> listByCountry(String country) async {
    final rows = await _client
        .from('vaccine_schedules')
        .select(
            'id, country, code, name, dose_number, recommended_age_days, description')
        .eq('country', country)
        .order('recommended_age_days', ascending: true)
        .order('dose_number', ascending: true);
    return rows.map((r) => VaccineSchedule.fromMap(r)).toList();
  }
}

/// Repository 인스턴스를 만들고 의존성(SupabaseClient)을 주입하는 provider.
///
/// `ref.watch(supabaseClientProvider)`로 다른 provider의 값을 꺼내옴.
/// supabase 클라이언트가 바뀌면(테스트 시 override 등) repository도 자동으로 다시 만들어짐.
final vaccineScheduleRepositoryProvider = Provider<VaccineScheduleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VaccineScheduleRepository(client);
});
