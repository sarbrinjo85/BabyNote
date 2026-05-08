import 'package:flutter/material.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/stroked_title.dart';
import '../../../core/widgets/grid_action_tile.dart';
import '../../auth/data/auth_repository.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../onboarding/presentation/onboarding_coach.dart';
import 'child_info_card.dart';
import 'notification_bell.dart';
import 'notification_scheduler.dart';
import 'quick_feeding_fab.dart';
import 'record_buttons_grid.dart';
import 'sleep_ongoing_notifier.dart';
import 'todays_summary_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    // 첫 build 직후 — 자녀가 1명 이상 있을 때만 코치마크 표시 (UX상 자연스러움).
    // 자녀 0명이면 _OnboardingHero가 떠서 코치마크와 겹침 X.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_onboardingTriggered) return;
      _onboardingTriggered = true;
      OnboardingCoach.maybeShow(context);
    });
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);

    return Scaffold(
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
          IconButton(
            key: OnboardingCoach.addChildKey,
            tooltip: l10n.homeAddChild,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => context.push('/child/new'),
          ),
          NotificationBellAction(key: OnboardingCoach.bellKey),
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
        child: asyncChildren.maybeWhen(
              data: (cs) => cs.isEmpty,
              orElse: () => false,
            )
            ? const _OnboardingHero()
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 자녀 picker (2명 이상일 때만)
                            if (children.length >= 2) ...[
                              Wrap(
                                spacing: Spacing.xs,
                                runSpacing: Spacing.xs,
                                children: children.map((c) {
                                  final isSel = (selectedChildId ??
                                          children.first.id) ==
                                      c.id;
                                  return ChoiceChip(
                                    label: Text(c.name),
                                    avatar: const Icon(Icons.child_care,
                                        size: 18),
                                    selected: isSel,
                                    onSelected: (sel) {
                                      if (sel) {
                                        ref
                                            .read(selectedChildIdProvider
                                                .notifier)
                                            .state = c.id;
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: Spacing.xs),
                            ],

                            // 무음 위젯들
                            NotificationScheduler(child: child),
                            SleepOngoingNotifier(child: child),

                            // 자녀 정보 + 성장
                            ChildInfoCard(child: child),
                            const SizedBox(height: Spacing.xs),

                            // 오늘의 요약 차트
                            TodaysSummaryChart(childId: child.id),
                            const SizedBox(height: Spacing.sm),

                            // 메인 기록 4 col — 마지막 활동 시간 + 알림 dot 통합
                            _SectionLabel(text: l10n.homeTodayRecord),
                            const SizedBox(height: Spacing.xxs),
                            Container(
                              key: OnboardingCoach.recordButtonsKey,
                              child: RecordButtonsGrid(childId: child.id),
                            ),
                            const SizedBox(height: Spacing.sm),

                            // ── 카테고리 1: 데이터/관리 ──────────────
                            _SectionLabel(text: l10n.homeSectionData),
                            const SizedBox(height: Spacing.xxs),
                            Container(
                              key: OnboardingCoach.dataMenuKey,
                              child: GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
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
                            const SizedBox(height: Spacing.sm),

                            // ── 카테고리 2: 의료 ────────────────────
                            _SectionLabel(text: l10n.homeSectionMedical),
                            const SizedBox(height: Spacing.xxs),
                            Container(
                              key: OnboardingCoach.medicalMenuKey,
                              child: GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
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
                            const SizedBox(height: Spacing.lg),
                          ],
                        );
                      },
                    ),
                  ),
                ],
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

