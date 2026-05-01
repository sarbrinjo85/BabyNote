import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../child/presentation/child_providers.dart';
import '../../vaccination/presentation/first_vaccine_provider.dart';

/// 홈 화면 (인증 후).
///
/// AuthGate로 감싸져 있어 여기 도달했다는 건 user != null. 그래도 방어적으로
/// currentUser를 한 번 더 watch.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final asyncVaccine = ref.watch(firstKoreanVaccineProvider);
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
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(l10n.homeWelcome,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 12),
          Center(child: _UserChip(user: currentUser)),
          const SizedBox(height: 24),

          // ── 자녀 섹션 ──────────────────────────────────────────
          _SectionTitle('내 자녀'),
          const SizedBox(height: 8),
          asyncChildren.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/child/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('자녀 추가'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // ── (학습 데모) 백신 카드 ──────────────────────────────
          _SectionTitle('학습 데모: 한국 첫 예방접종'),
          const SizedBox(height: 8),
          asyncVaccine.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Supabase 연결 실패: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            data: (vaccine) {
              if (vaccine == null) return const Text('등록된 한국 백신 일정이 없습니다.');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🇰🇷 첫 번째 예방접종 (Supabase에서)',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(vaccine.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('코드: ${vaccine.code} (${vaccine.doseNumber}차)'),
                      Text('권장 시기: 생후 ${vaccine.recommendedAgeDays}일'),
                      if (vaccine.description != null) ...[
                        const SizedBox(height: 8),
                        Text(vaccine.description!),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.child_friendly, size: 40),
            const SizedBox(height: 8),
            const Text('아직 등록된 자녀가 없어요'),
            const SizedBox(height: 12),
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
