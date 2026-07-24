import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import 'auth_page.dart';
import 'auth_providers.dart';

/// 인증 상태에 따라 화면을 분기하는 wrapper.
///
/// ── 동작 ─────────────────────────────────────────────────────────
/// authStateChangesProvider(StreamProvider)를 watch:
///   - loading        : 스플래시(로딩 인디케이터)
///   - error          : 캐시 세션 있으면 그대로 진입, 없으면 재시도 화면
///   - data, user==null : AuthPage (로그인/가입)
///   - data, user!=null : 인증된 사용자 → child(보통 HomePage)
///
/// app_router의 / 라우트가 직접 HomePage 대신 AuthGate(child: HomePage())로 감싸면
/// 모든 진입점이 이 게이트를 통과 → 비로그인 상태에서 화면 누수 없음.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  /// 로그인된 사용자에게 보여줄 화면 (보통 HomePage).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAuth = ref.watch(authStateChangesProvider);
    final user = ref.watch(currentUserProvider);

    return asyncAuth.when(
      // 첫 stream 이벤트 도착 전 (보통 SDK가 cached session 복구 중)
      loading: () => const Scaffold(
        body: Center(child: BabyLoading()),
      ),
      // 스트림 에러 — 콜드 스타트 시 토큰 갱신(refresh_token)이 일시적 네트워크/
      // DNS 실패(AuthRetryableFetchException)로 자주 발생. 이때:
      //  - 캐시된 세션이 있으면(재방문 사용자) 앱으로 그대로 진입. supabase 가
      //    백그라운드에서 토큰 갱신을 재시도하므로 사용자는 오류를 볼 필요 없음.
      //  - 세션이 없으면(오프라인 신규) 날것 예외 대신 친절한 재시도 화면.
      error: (err, _) => user != null
          ? child
          : _ConnectionErrorView(
              onRetry: () => ref.invalidate(authStateChangesProvider),
            ),
      // stream에서 첫 이벤트 받음. 이후 user 값으로 분기.
      data: (_) => user == null ? const AuthPage() : child,
    );
  }
}

/// 세션 없이 앱을 켰는데 네트워크가 안 될 때 보여주는 재시도 화면.
/// 날것 예외 텍스트 대신 친절한 안내 + 다시 시도 버튼.
class _ConnectionErrorView extends StatelessWidget {
  const _ConnectionErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.authConnErrorTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.authConnErrorBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.syncRetryNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
