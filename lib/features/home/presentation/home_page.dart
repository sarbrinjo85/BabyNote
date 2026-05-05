import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/big_action_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import 'diaper_size_up_card.dart';
import 'formula_status_card.dart';
import 'last_activity_section.dart';
import 'notification_scheduler.dart';
import 'todays_summary_section.dart';
import 'upcoming_vaccine_card.dart';

/// 홈 화면 (인증 후).
///
/// AuthGate로 감싸져 있어 여기 도달했다는 건 user != null. 그래도 방어적으로
/// currentUser를 한 번 더 watch.
///
/// ── Phase 1 시점 구성 ────────────────────────────────────────────────
/// 1. AppBar: 타이틀 + 로그아웃 버튼
/// 2. _UserChip: 현재 user 칩 (학습 데모용, 추후 제거)
/// 3. 내 자녀 섹션: 목록 + "자녀 추가" CTA
/// 4. 4개 큰 기록 버튼 (수유/수면/기저귀/성장) — placeholder, Phase 2에서 화면 연결
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeLogout,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              // signOut → onAuthStateChange가 signedOut 이벤트 발행
              // → AuthGate가 자동으로 AuthPage로 전환됨. 수동 navigate 불필요.
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // ── 자녀 섹션 ──────────────────────────────────────────
          _SectionTitle(l10n.homeMyChildren),
          const SizedBox(height: Spacing.xs),
          asyncChildren.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Text(l10n.errorChildrenLoadFailed(err)),
              ),
            ),
            data: (children) {
              if (children.isEmpty) {
                return _EmptyChildrenCard();
              }
              return Column(
                children: [
                  // ── 자녀 picker (2명 이상일 때만 ChoiceChip 그룹) ────────
                  if (children.length >= 2) ...[
                    Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: children.map((c) {
                        final isSel = (selectedChildId ?? children.first.id) == c.id;
                        return ChoiceChip(
                          label: Text(c.name),
                          avatar: const Icon(Icons.child_care, size: 18),
                          selected: isSel,
                          onSelected: (sel) {
                            if (sel) {
                              ref
                                  .read(selectedChildIdProvider.notifier)
                                  .state = c.id;
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  // 선택된 자녀 1명 정보 카드 (선택된 거 또는 1명뿐이면 그것)
                  // 탭하면 편집 화면으로 (이름/생년월일 오타 등 수정 + 삭제 가능)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.child_care),
                      title: Text((selectedChild ?? children.first).name),
                      subtitle: Text(
                        l10n.homeChildSubtitle(
                          _genderLabel(
                              context, (selectedChild ?? children.first).gender),
                          (selectedChild ?? children.first)
                              .ageInDays(DateTime.now()),
                        ),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => context.push(
                        '/child/edit',
                        extra: selectedChild ?? children.first,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/child/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.homeAddChild),
                  ),
                ],
              );
            },
          ),

          // ── 분유 잔량 + 오늘의 요약 + 마지막 활동 (선택된 자녀 기준) ──
          if (selectedChild != null) ...[
            // 무음 위젯 — 자녀 데이터 watch + 조건 만족 시 로컬 알림 자동 스케줄
            NotificationScheduler(child: selectedChild),
            const SizedBox(height: Spacing.lg),
            FormulaStatusCard(childId: selectedChild.id),
            const SizedBox(height: Spacing.xs),
            DiaperSizeUpCard(childId: selectedChild.id),
            const SizedBox(height: Spacing.xs),
            UpcomingVaccineCard(child: selectedChild),
            const SizedBox(height: Spacing.md),
            TodaysSummarySection(childId: selectedChild.id),
            const SizedBox(height: Spacing.lg),
            _SectionTitle(l10n.homeLastActivity),
            const SizedBox(height: Spacing.xs),
            LastActivitySection(childId: selectedChild.id),
          ],

          const SizedBox(height: Spacing.xl),

          // ── 4개 큰 기록 버튼 ────────────────────────────────────
          _SectionTitle(l10n.homeTodayRecord),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: l10n.summaryFeeding,
            icon: const Text('🍼', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/feeding/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: l10n.summarySleep,
            icon: const Text('💤', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/sleep/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: l10n.summaryDiaper,
            icon: const Text('💩', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/diaper/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: l10n.summaryGrowth,
            icon: const Text('📏', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/growth/new'),
          ),

          const SizedBox(height: Spacing.xl),

          // ── 재고 관리 (Phase 3 차별화) ────────────────────────────
          _SectionTitle(l10n.homeInventory),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/formula'),
            icon: const Text('🍼', style: TextStyle(fontSize: 24)),
            label: Text(l10n.homeFormulaInventoryEntry),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/diaper'),
            icon: const Text('🧷', style: TextStyle(fontSize: 24)),
            label: Text(l10n.homeDiaperInventoryEntry),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // ── 의료/케어 ───────────────────────────────────────────
          // ── 통계 ───────────────────────────────────────────────
          _SectionTitle(l10n.statsTitle),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/stats'),
            icon: const Text('📊', style: TextStyle(fontSize: 24)),
            label: Text(l10n.statsEntryHome),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── 가족 공유 ───────────────────────────────────────────
          _SectionTitle(l10n.familyTitle),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/family'),
            icon: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
            label: Text(l10n.familyEntryHome),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/family/join'),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.familyEntryJoin),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          _SectionTitle(l10n.homeHospital),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/hospital'),
            icon: const Text('🏥', style: TextStyle(fontSize: 24)),
            label: Text(l10n.homeHospitalEntry),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/vaccine'),
            icon: const Text('💉', style: TextStyle(fontSize: 24)),
            label: Text(l10n.homeVaccineEntry),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      ),
    );
  }

  // 4개 기록 모두 화면 연결 완료. _comingSoon은 더 이상 사용 안 함 → 제거.

  String _genderLabel(BuildContext context, String? g) {
    final l10n = AppLocalizations.of(context);
    switch (g) {
      case 'female':
        return l10n.childGenderFemale;
      case 'male':
        return l10n.childGenderMale;
      case 'other':
        return l10n.childGenderOther;
      default:
        return l10n.childGenderUnset;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            const Icon(Icons.child_friendly, size: 40),
            const SizedBox(height: Spacing.xs),
            Text(l10n.homeNoChildYet),
            const SizedBox(height: Spacing.sm),
            FilledButton.icon(
              onPressed: () => context.push('/child/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeFirstChild),
            ),
          ],
        ),
      ),
    );
  }
}

