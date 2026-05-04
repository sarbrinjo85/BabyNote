import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/big_action_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../child/presentation/child_providers.dart';
import 'formula_status_card.dart';
import 'last_activity_section.dart';
import 'todays_summary_section.dart';

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
    final currentUser = ref.watch(currentUserProvider);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              // signOut → onAuthStateChange가 signedOut 이벤트 발행
              // → AuthGate가 자동으로 AuthPage로 전환됨. 수동 navigate 불필요.
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Center(
            child: Text(
              l10n.homeWelcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Center(child: _UserChip(user: currentUser)),
          const SizedBox(height: Spacing.lg),

          // ── 자녀 섹션 ──────────────────────────────────────────
          const _SectionTitle('내 자녀'),
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
                child: Text('자녀 목록 로딩 실패: $err'),
              ),
            ),
            data: (children) {
              if (children.isEmpty) {
                return _EmptyChildrenCard();
              }
              return Column(
                children: [
                  ...children.map((c) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.child_care),
                          title: Text(c.name),
                          subtitle: Text(
                            '${_genderLabel(c.gender)} · 생후 ${c.ageInDays(DateTime.now())}일',
                          ),
                        ),
                      )),
                  const SizedBox(height: Spacing.xs),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/child/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('자녀 추가'),
                  ),
                ],
              );
            },
          ),

          // ── 분유 잔량 + 오늘의 요약 + 마지막 활동 (자녀 1명 이상일 때만) ──
          ...asyncChildren.maybeWhen(
            data: (cs) => cs.isEmpty
                ? const <Widget>[]
                : [
                    const SizedBox(height: Spacing.lg),
                    FormulaStatusCard(childId: cs.first.id),
                    const SizedBox(height: Spacing.md),
                    TodaysSummarySection(childId: cs.first.id),
                    const SizedBox(height: Spacing.lg),
                    const _SectionTitle('마지막 활동'),
                    const SizedBox(height: Spacing.xs),
                    LastActivitySection(childId: cs.first.id),
                  ],
            orElse: () => const <Widget>[],
          ),

          const SizedBox(height: Spacing.xl),

          // ── 4개 큰 기록 버튼 ────────────────────────────────────
          const _SectionTitle('오늘의 기록'),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: '수유',
            icon: const Text('🍼', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/feeding/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: '수면',
            icon: const Text('💤', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/sleep/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: '기저귀',
            icon: const Text('💩', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/diaper/new'),
          ),
          const SizedBox(height: Spacing.xs),
          BigActionButton(
            label: '성장',
            icon: const Text('📏', style: TextStyle(fontSize: 28)),
            onPressed: () => context.push('/growth/new'),
          ),

          const SizedBox(height: Spacing.xl),

          // ── 재고 관리 (Phase 3 차별화) ────────────────────────────
          const _SectionTitle('재고 관리'),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/formula'),
            icon: const Text('🍼', style: TextStyle(fontSize: 24)),
            label: const Text('분유 재고 관리'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/diaper'),
            icon: const Text('🧷', style: TextStyle(fontSize: 24)),
            label: const Text('기저귀 재고 관리'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  // 4개 기록 모두 화면 연결 완료. _comingSoon은 더 이상 사용 안 함 → 제거.

  String _genderLabel(String? g) {
    switch (g) {
      case 'female':
        return '여아';
      case 'male':
        return '남아';
      case 'other':
        return '기타';
      default:
        return '미지정';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            const Icon(Icons.child_friendly, size: 40),
            const SizedBox(height: Spacing.xs),
            const Text('아직 등록된 자녀가 없어요'),
            const SizedBox(height: Spacing.sm),
            FilledButton.icon(
              onPressed: () => context.push('/child/new'),
              icon: const Icon(Icons.add),
              label: const Text('첫 자녀 등록'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Chip(label: Text('비로그인'));
    }
    final id = user.id as String;
    final isAnon = (user.isAnonymous as bool?) ?? false;
    final email = (user.email as String?) ?? '';
    final label = email.isNotEmpty
        ? email
        : '${isAnon ? "익명" : "사용자"}: ${id.substring(0, 8)}…';
    return Chip(
      avatar: Icon(isAnon ? Icons.person_outline : Icons.person),
      label: Text(label),
    );
  }
}
