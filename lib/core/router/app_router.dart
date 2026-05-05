import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/child/domain/child.dart';
import '../../features/child/presentation/child_edit_page.dart';
import '../../features/child/presentation/child_register_page.dart';
import '../../features/diaper/domain/diaper.dart';
import '../../features/diaper/presentation/diaper_register_page.dart';
import '../../features/family/presentation/family_join_page.dart';
import '../../features/family/presentation/family_page.dart';
import '../../features/records/presentation/records_page.dart';
import '../../features/stats/presentation/statistics_page.dart';
import '../../features/feeding/domain/feeding.dart';
import '../../features/feeding/presentation/feeding_register_page.dart';
import '../../features/growth/domain/growth.dart';
import '../../features/growth/presentation/growth_register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/hospital/domain/hospital.dart';
import '../../features/hospital/presentation/hospital_list_page.dart';
import '../../features/hospital/presentation/hospital_register_page.dart';
import '../../features/inventory/domain/diaper_inventory.dart';
import '../../features/inventory/domain/formula_inventory.dart';
import '../../features/inventory/presentation/diaper_inventory_list_page.dart';
import '../../features/inventory/presentation/diaper_inventory_register_page.dart';
import '../../features/inventory/presentation/formula_inventory_list_page.dart';
import '../../features/inventory/presentation/formula_inventory_register_page.dart';
import '../../features/vaccination/domain/vaccine_schedule.dart';
import '../../features/vaccination/presentation/vaccine_list_page.dart';
import '../../features/vaccination/presentation/vaccine_record_page.dart';
import '../../features/sleep/domain/sleep.dart';
import '../../features/sleep/presentation/sleep_register_page.dart';

/// 앱 전체 라우팅 정의.
///
/// ── go_router 기본 패턴 ────────────────────────────────────────────
/// GoRouter는 URL-기반 선언형 라우팅. 화면 간 이동은 `context.go('/path')`
/// (히스토리 교체) 또는 `context.push('/path')` (새 화면 push). 뒤로가기는
/// `context.pop()`. 자식 화면에서 데이터 가지고 돌아오려면 `await context.push`로 받기.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        // AuthGate로 감쌌으니 비로그인이면 자동으로 AuthPage가 떠. 로그인 후 HomePage.
        builder: (context, state) => const AuthGate(child: HomePage()),
      ),
      GoRoute(
        // /child/new — 새 자녀 등록 폼. 인증된 사용자만 접근 가능 (RLS가 막아주지만
        // UX를 위해 게이트도 한 번 더). AuthGate로 감싸도 됨.
        path: '/child/new',
        name: 'childNew',
        builder: (context, state) =>
            const AuthGate(child: ChildRegisterPage()),
      ),
      GoRoute(
        // /child/edit — 기존 자녀 정보 편집/삭제. extra에 Child 객체 필수.
        path: '/child/edit',
        name: 'childEdit',
        builder: (context, state) {
          final child = state.extra as Child;
          return AuthGate(child: ChildEditPage(child: child));
        },
      ),
      GoRoute(
        // /feeding/new — 수유 기록 등록 (3 탭: 모유/분유/이유식)
        // extra=Feeding이면 편집 모드로 동작.
        path: '/feeding/new',
        name: 'feedingNew',
        builder: (context, state) {
          final editing = state.extra as Feeding?;
          return AuthGate(child: FeedingRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /sleep/new — 수면 시작/종료 (진행 중이면 종료 화면 자동). extra=Sleep이면 편집.
        path: '/sleep/new',
        name: 'sleepNew',
        builder: (context, state) {
          final editing = state.extra as Sleep?;
          return AuthGate(child: SleepRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /diaper/new — 기저귀 기록. extra=Diaper면 편집.
        path: '/diaper/new',
        name: 'diaperNew',
        builder: (context, state) {
          final editing = state.extra as Diaper?;
          return AuthGate(child: DiaperRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /growth/new — 성장 기록. extra=Growth면 편집.
        path: '/growth/new',
        name: 'growthNew',
        builder: (context, state) {
          final editing = state.extra as Growth?;
          return AuthGate(child: GrowthRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /inventory/formula — 분유 재고 목록
        path: '/inventory/formula',
        name: 'formulaInventoryList',
        builder: (context, state) =>
            const AuthGate(child: FormulaInventoryListPage()),
      ),
      GoRoute(
        // /inventory/formula/new — 분유 한 통 등록 또는 편집(extra=FormulaInventory)
        path: '/inventory/formula/new',
        name: 'formulaInventoryNew',
        builder: (context, state) {
          final editing = state.extra as FormulaInventory?;
          return AuthGate(child: FormulaInventoryRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /inventory/diaper — 기저귀 재고 목록
        path: '/inventory/diaper',
        name: 'diaperInventoryList',
        builder: (context, state) =>
            const AuthGate(child: DiaperInventoryListPage()),
      ),
      GoRoute(
        // /inventory/diaper/new — 기저귀 한 팩 등록 또는 편집(extra=DiaperInventory)
        path: '/inventory/diaper/new',
        name: 'diaperInventoryNew',
        builder: (context, state) {
          final editing = state.extra as DiaperInventory?;
          return AuthGate(child: DiaperInventoryRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /hospital — 단골 병원 목록 (전화/길찾기 딥링크 포함)
        path: '/hospital',
        name: 'hospitalList',
        builder: (context, state) =>
            const AuthGate(child: HospitalListPage()),
      ),
      GoRoute(
        // /hospital/new — 등록 또는 편집(extra=Hospital)
        path: '/hospital/new',
        name: 'hospitalNew',
        builder: (context, state) {
          final editing = state.extra as Hospital?;
          return AuthGate(child: HospitalRegisterPage(editing: editing));
        },
      ),
      GoRoute(
        // /records — 전체 기록 (수유/수면/기저귀/성장 4탭, long-press 삭제)
        path: '/records',
        name: 'records',
        builder: (context, state) =>
            const AuthGate(child: RecordsPage()),
      ),
      GoRoute(
        // /stats — 통계 화면 (수유/수면/기저귀 7일치 + 성장 곡선)
        path: '/stats',
        name: 'stats',
        builder: (context, state) =>
            const AuthGate(child: StatisticsPage()),
      ),
      GoRoute(
        // /family — 가족 공유 (자녀 caregivers + 초대 코드 발급/회수)
        path: '/family',
        name: 'family',
        builder: (context, state) =>
            const AuthGate(child: FamilyPage()),
      ),
      GoRoute(
        // /family/join — 다른 부모가 보낸 코드로 가족 참여
        path: '/family/join',
        name: 'familyJoin',
        builder: (context, state) =>
            const AuthGate(child: FamilyJoinPage()),
      ),
      GoRoute(
        // /vaccine — 자녀 예방접종 일정 (다가오는/미접종/완료 분류)
        path: '/vaccine',
        name: 'vaccineList',
        builder: (context, state) =>
            const AuthGate(child: VaccineListPage()),
      ),
      GoRoute(
        // /vaccine/record — 특정 백신 접종 완료 기록 (extra로 schedule + childId 전달)
        path: '/vaccine/record',
        name: 'vaccineRecord',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AuthGate(
            child: VaccineRecordPage(
              schedule: extra['schedule'] as VaccineSchedule,
              childId: extra['childId'] as String,
            ),
          );
        },
      ),
    ],
  );
});
