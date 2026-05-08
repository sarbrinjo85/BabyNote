import 'package:flutter/material.dart';
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
///   - error          : 에러 메시지
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
      // 스트림 자체가 에러 — 거의 발생 안 함
      error: (err, _) => Scaffold(
        body: Center(child: Text(AppLocalizations.of(context).errorAuthStream(err))),
      ),
      // stream에서 첫 이벤트 받음. 이후 user 값으로 분기.
      data: (_) => user == null ? const AuthPage() : child,
    );
  }
}
