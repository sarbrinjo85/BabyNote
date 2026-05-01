import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../vaccination/presentation/first_vaccine_provider.dart';

/// 홈 화면 (placeholder).
///
/// ── 화면이 watch하는 provider 세 개 ──────────────────────────────────
/// 1) ensureAnonymousSessionProvider — 부팅 시 익명 로그인 1회 실행, 결과 AsyncValue
/// 2) currentUserProvider           — auth 상태 스트림에서 현재 user 추출 (실시간 갱신)
/// 3) firstKoreanVaccineProvider    — Supabase에서 KR 첫 백신 1건 fetch
///
/// auth와 vaccine은 독립적이지만, 학습 가독성을 위해 auth 부트스트랩이 끝난 뒤
/// 화면을 그리도록 위쪽 AsyncValue로 한 번 감쌈.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // ── 1) 익명 세션 보장 (부팅 1회 트리거)
    // FutureProvider라서 AsyncValue<User> 반환. 첫 build 때 호출 시작.
    final asyncAuth = ref.watch(ensureAnonymousSessionProvider);

    // ── 2) 현재 user (스트림 기반, 로그아웃/재로그인 시 자동 갱신)
    final currentUser = ref.watch(currentUserProvider);

    // ── 3) KR 첫 백신
    final asyncVaccine = ref.watch(firstKoreanVaccineProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: asyncAuth.when(
        // 익명 로그인 진행 중
        loading: () => const Center(child: CircularProgressIndicator()),
        // 익명 로그인 실패 (가장 흔한 원인: Supabase Dashboard에서 anon sign-in 미활성)
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  '익명 로그인 실패',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('$err', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  '확인: Supabase Dashboard → Authentication → "Allow anonymous sign-ins" ON',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // 익명 로그인 성공
        data: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.homeWelcome,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                _UserChip(user: currentUser),
                const SizedBox(height: 32),
                asyncVaccine.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text(
                    'Supabase 연결 실패: $err',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (vaccine) {
                    if (vaccine == null) {
                      return const Text('등록된 한국 백신 일정이 없습니다.');
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🇰🇷 첫 번째 예방접종 (Supabase에서)',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vaccine.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
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
          ),
        ),
      ),
    );
  }
}

/// 현재 user.id를 사용자에게 보여주는 작은 칩 위젯.
///
/// 학습 데모 용도: "익명 로그인이 진짜 됐다"를 시각적으로 확인. 운영 단계에선
/// user.id를 화면에 노출할 일은 거의 없으니 제거할 위젯.
class _UserChip extends StatelessWidget {
  const _UserChip({required this.user});
  final dynamic user; // Supabase의 User. 학습 단순화 위해 dynamic.

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Chip(label: Text('비로그인'));
    }
    final id = user.id as String;
    final isAnon = (user.isAnonymous as bool?) ?? true;
    return Chip(
      avatar: Icon(isAnon ? Icons.person_outline : Icons.person),
      label: Text(
        '${isAnon ? '익명' : '정식'} 사용자: ${id.substring(0, 8)}…',
      ),
    );
  }
}
