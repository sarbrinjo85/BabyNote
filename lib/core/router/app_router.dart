import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/child/presentation/child_register_page.dart';
import '../../features/home/presentation/home_page.dart';

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
    ],
  );
});
