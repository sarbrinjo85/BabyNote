import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/config/env.dart';
import '../../../core/sync/sync_indicator.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/stroked_title.dart';
import '../../../core/widgets/grid_action_tile.dart';
import '../../auth/data/auth_repository.dart';
import '../../billing/data/billing_service.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../family/data/realtime_sync.dart';
import '../../onboarding/presentation/onboarding_coach.dart';
import '../../routine/domain/routine.dart';
import '../../routine/presentation/routine_providers.dart';
import '../../symptom/domain/symptom.dart';
import '../../symptom/presentation/symptom_providers.dart';
import 'child_info_card.dart';
import 'notification_bell.dart';
import 'notification_scheduler.dart';
import 'quick_feeding_fab.dart';
import 'record_buttons_grid.dart';
import 'sleep_ongoing_notifier.dart';

/// 홈 화면 — 한 화면에 핵심 정보 모두 노출 (스크롤 최소화).
///
/// ── 레이아웃 (위 → 아래) ────────────────────────────────────────────
/// 1. AppBar (title + 종 + 설정 + 로그아웃)
/// 2. AlertBanner — 컴팩트 한 줄 알림 (분유/사이즈업/접종 중 가장 시급한 1개)
/// 3. (자녀 2+명일 때) 자녀 picker chips
/// 4. ChildInfoCard — 자녀 + 성장 정보(체중/키/머리둘레)
/// 5. TodaysSummaryChart — 가로 bar 3개 (수유/수면/기저귀)
/// 6. 메인 기록 grid 4 col (수유/수면/기저귀/성장) — 가장 자주 쓰임
/// 7. LastActivityGrid 2x2 — 4종 마지막 1건씩
/// 8. 진입점 grid 4 col × 2 row (재고/기록/통계/병원/접종/가족 등)
/// 9. FAB — 마지막 수유 1탭 빠른 기록
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _onboardingTriggered = false;
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);

    // 첫 build 직후 — 자녀가 1명 이상 있을 때만 코치마크 표시.
    // 자녀 0명이면 _OnboardingHero 가 떠서 코치마크와 겹치는 문제가 있어 보류.
    // 자녀 추가 후 다음 build 의 postFrameCallback 에서 트리거됨.
    final hasChildren = asyncChildren.maybeWhen(
      data: (cs) => cs.isNotEmpty,
      orElse: () => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_onboardingTriggered) return;
      if (!hasChildren) return; // 0명이면 latch 안 함
      _onboardingTriggered = true;
      OnboardingCoach.maybeShow(context);
    });

    // 가족 실시간 동기화 — 자녀별 4 테이블 INSERT/UPDATE/DELETE 구독.
    // 자녀 바뀌면 이전 구독 자동 dispose, 새 구독 시작.
    if (selectedChild != null) {
      ref.watch(childRealtimeSyncProvider(selectedChild.id));
    }

    // 가족 다른 사용자가 추가한 활동 — 토스트 알림
    ref.listen(familyActivityFeedProvider, (prev, next) {
      if (next == null || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${next.icon} 가족이 ${next.kind} 기록을 남겼어요'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      // 일회성 — 알림 후 reset
      ref.read(familyActivityFeedProvider.notifier).state = null;
    });

    return PopScope(
      canPop: false, // 시스템이 자동으로 pop하지 않게 막고 직접 처리
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          // 2초 이내 두 번째 백 → 앱 종료
          SystemNavigator.pop();
          return;
        }
        _lastBackPressed = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다'),
              duration: Duration(seconds: 1),
            ),
          );
      },
      child: Scaffold(
        floatingActionButton: selectedChild != null
            ? Container(
                key: OnboardingCoach.fabKey,
                child: QuickFeedingFab(child: selectedChild),
              )
            : null,
        appBar: AppBar(
          // 글자 fill + stroke 두 겹 — Stack으로 구현.
          // Flutter의 TextStyle.foreground는 fill XOR stroke 둘 중 하나만 지원.
          title: const StrokedTitle('Baby Note'),
          actions: [
            // 오프라인 큐 indicator — 큐가 비어있으면 0 폭으로 사라짐.
            const SyncIndicator(),
            // GlobalKey는 Container로 감싸서 위치 계산이 IconButton 외곽 박스에
            // 정확히 매칭되도록 함.
            Container(
              key: OnboardingCoach.addChildKey,
              child: IconButton(
                tooltip: l10n.homeAddChild,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () => context.push('/child/new'),
              ),
            ),
            Container(
              key: OnboardingCoach.bellKey,
              child: const NotificationBellAction(),
            ),
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              tooltip: l10n.homeLogout,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child:
              asyncChildren.maybeWhen(
                data: (cs) => cs.isEmpty,
                orElse: () => false,
              )
              ? const _OnboardingHero()
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.md,
                        Spacing.xs,
                        Spacing.md,
                        Spacing.sm,
                      ),
                      child: asyncChildren.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(Spacing.md),
                          child: Center(child: BabyLoading()),
                        ),
                        error: (err, _) => Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(Spacing.sm),
                            child: Text(l10n.errorChildrenLoadFailed(err)),
                          ),
                        ),
                        data: (children) {
                          if (children.isEmpty) return const SizedBox.shrink();
                          final child = selectedChild ?? children.first;

                          // 루틴/건강 종류별 "오늘" 횟수 — 큰 버튼 안에 표시.
                          // recentXProvider 는 30건 limit, kind 8종이라 보통 모두 커버.
                          final routinesAsync = ref.watch(
                            recentRoutinesProvider(child.id),
                          );
                          final symptomsAsync = ref.watch(
                            recentSymptomsProvider(child.id),
                          );
                          final now = DateTime.now();
                          final todayStart = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );
                          final routineTodayCount = <RoutineKind, int>{};
                          final symptomTodayCount = <SymptomKind, int>{};
                          routinesAsync.whenData((list) {
                            for (final r in list) {
                              if (r.startedAt.isAfter(todayStart)) {
                                routineTodayCount[r.kind] =
                                    (routineTodayCount[r.kind] ?? 0) + 1;
                              }
                            }
                          });
                          symptomsAsync.whenData((list) {
                            for (final s in list) {
                              if (s.occurredAt.isAfter(todayStart)) {
                                symptomTodayCount[s.kind] =
                                    (symptomTodayCount[s.kind] ?? 0) + 1;
                              }
                            }
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 자녀 picker (2명 이상일 때만)
                              if (children.length >= 2) ...[
                                Wrap(
                                  spacing: Spacing.xs,
                                  runSpacing: Spacing.xs,
                                  children: children.map((c) {
                                    final isSel =
                                        (selectedChildId ??
                                            children.first.id) ==
                                        c.id;
                                    return ChoiceChip(
                                      label: Text(c.name),
                                      avatar: Icon(
                                        Icons.child_care,
                                        size: 18,
                                        color: isSel
                                            ? const Color(0xFFA43F45)
                                            : null,
                                      ),
                                      selected: isSel,
                                      // 선택 시 코랄핑크 파스텔 배경 + 다크 코랄 글자
                                      selectedColor: const Color(0xFFFFB5A7),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      labelStyle: TextStyle(
                                        color: isSel
                                            ? const Color(0xFFA43F45)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      side: BorderSide(
                                        color: isSel
                                            ? const Color(0xFFA43F45)
                                            : const Color(0x99FFB5A7),
                                        width: 1.2,
                                      ),
                                      showCheckmark: false,
                                      onSelected: (sel) {
                                        if (sel) {
                                          ref
                                                  .read(
                                                    selectedChildIdProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              c.id;
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: Spacing.xxs),
                              ],

                              // 무음 위젯들
                              NotificationScheduler(child: child),
                              SleepOngoingNotifier(child: child),

                              // 자녀 정보 + 성장
                              ChildInfoCard(child: child),
                              // 가족 플랜 활성 시에만 뜨는 뱃지 (구매 가치 가시화)
                              const _FamilyPlanBadge(),
                              const SizedBox(height: Spacing.xxs),

                              // 메인 기록 4 col — 오늘 합계 + 마지막 활동 통합
                              // (기존 "오늘의 요약" 차트를 각 버튼에 흡수)
                              _SectionLabel(text: l10n.homeTodayRecord),
                              const SizedBox(height: Spacing.xxs),
                              Container(
                                key: OnboardingCoach.recordButtonsKey,
                                child: RecordButtonsGrid(childId: child.id),
                              ),
                              const SizedBox(height: Spacing.xs),

                              // ── 루틴 · 건강 — 큰 버튼 2개로 통합 ────────
                              // 산책/목욕/… 8개 타일을 "루틴" / "건강" 큰 버튼
                              // 2개로 묶어 홈을 단순화. 종류 선택은 등록 화면의
                              // kind 토글에서 진행. 코치 마크 키는 그대로 유지.
                              SizedBox(
                                height: 128,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _KindBreakdownButton(
                                        key: OnboardingCoach.routineSectionKey,
                                        emoji: '🧸',
                                        label: l10n.routineSectionHome,
                                        items: [
                                          (
                                            l10n.homeRoutineWalk,
                                            routineTodayCount[RoutineKind
                                                    .walk] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeRoutineBath,
                                            routineTodayCount[RoutineKind
                                                    .bath] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeRoutineSupplement,
                                            routineTodayCount[RoutineKind
                                                    .supplement] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeRoutineSnack,
                                            routineTodayCount[RoutineKind
                                                    .snack] ??
                                                0,
                                          ),
                                        ],
                                        onTap: () =>
                                            context.push('/routine/new'),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.xs),
                                    Expanded(
                                      child: _KindBreakdownButton(
                                        key: OnboardingCoach.symptomSectionKey,
                                        emoji: '🌡️',
                                        label: l10n.symptomSectionHome,
                                        items: [
                                          (
                                            l10n.homeSymptomCough,
                                            symptomTodayCount[SymptomKind
                                                    .cough] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeSymptomVomit,
                                            symptomTodayCount[SymptomKind
                                                    .vomit] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeSymptomRash,
                                            symptomTodayCount[SymptomKind
                                                    .rash] ??
                                                0,
                                          ),
                                          (
                                            l10n.homeSymptomInjury,
                                            symptomTodayCount[SymptomKind
                                                    .injury] ??
                                                0,
                                          ),
                                        ],
                                        onTap: () =>
                                            context.push('/symptom/new'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),

                              // ── 카테고리 1: 데이터/관리 ──────────────
                              _SectionLabel(text: l10n.homeSectionData),
                              const SizedBox(height: Spacing.xxs),
                              Container(
                                key: OnboardingCoach.dataMenuKey,
                                child: GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: Spacing.xs,
                                  crossAxisSpacing: Spacing.xs,
                                  childAspectRatio: 0.9,
                                  children: [
                                    GridActionTile(
                                      emoji: '📦',
                                      label: l10n.homeInventory,
                                      onTap: () => context.push('/inventory'),
                                    ),
                                    GridActionTile(
                                      emoji: '📋',
                                      label: l10n.recordsEntryHome,
                                      onTap: () => context.push('/records'),
                                    ),
                                    GridActionTile(
                                      emoji: '📊',
                                      label: l10n.statsEntryHome,
                                      onTap: () => context.push('/stats'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),

                              // ── 카테고리 2: 의료 ────────────────────
                              _SectionLabel(text: l10n.homeSectionMedical),
                              const SizedBox(height: Spacing.xxs),
                              Container(
                                key: OnboardingCoach.medicalMenuKey,
                                child: GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: Spacing.xs,
                                  crossAxisSpacing: Spacing.xs,
                                  childAspectRatio: 0.9,
                                  children: [
                                    GridActionTile(
                                      emoji: '🏥',
                                      label: l10n.homeHospitalEntry,
                                      onTap: () => context.push('/hospital'),
                                    ),
                                    GridActionTile(
                                      emoji: '💉',
                                      label: l10n.homeVaccineEntry,
                                      onTap: () => context.push('/vaccine'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 가족 플랜(멀티 자녀 entitlement) 활성 시에만 표시되는 작은 뱃지.
///
/// 빌링 비활성(dev: 키 없음) 환경에서는 hasMultiChildEntitlementProvider 가
/// 항상 true 를 반환하므로, Env.isBillingEnabled 로 한 번 더 가드해서 개발 중
/// 오표시를 방지한다. 활성이 아니면 SizedBox.shrink() (공간 차지 X).
class _FamilyPlanBadge extends ConsumerWidget {
  const _FamilyPlanBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isBillingEnabled) return const SizedBox.shrink();
    final active = ref.watch(hasMultiChildEntitlementProvider);
    if (!active) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0B25C)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                l10n.homeFamilyPlanBadge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A6D1B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 루틴/건강용 큰 버튼 — 헤더(이모지+라벨) + 종류별 오늘 횟수 2×2.
/// 부모 SizedBox(height) 가 높이를 결정하고, Card 가 그 높이를 채운다.
/// items 는 (종류 라벨, 오늘 횟수) 4개. 코치 마크 타겟 key 를 그대로 전달받는다.
class _KindBreakdownButton extends StatelessWidget {
  const _KindBreakdownButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.items,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final List<(String, int)> items;
  final VoidCallback onTap;

  Widget _cell(ThemeData theme, (String, int) it) {
    final has = it.$2 > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            it.$1,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${it.$2}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: has
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.brMd,
        side: BorderSide(
          color: BrandColors.seed.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              // 종류별 오늘 횟수 (2×2)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _cell(theme, items[0])),
                        const SizedBox(width: 10),
                        Expanded(child: _cell(theme, items[1])),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _cell(theme, items[2])),
                        const SizedBox(width: 10),
                        Expanded(child: _cell(theme, items[3])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 섹션 라벨 (작고 회색).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 자녀 0명 onboarding hero — 이전과 동일.
class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👶', style: TextStyle(fontSize: 96)),
            const SizedBox(height: Spacing.lg),
            Text(
              l10n.onboardingTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.onboardingBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton.icon(
              onPressed: () => context.push('/child/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.onboardingCta),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(TouchTarget.huge),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextButton.icon(
              onPressed: () => context.push('/family/join'),
              icon: const Icon(Icons.group_add),
              label: Text(l10n.familyEntryJoin),
            ),
          ],
        ),
      ),
    );
  }
}
