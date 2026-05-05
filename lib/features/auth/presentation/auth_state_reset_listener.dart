import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child/presentation/selected_child_provider.dart';
import 'auth_providers.dart';

/// 로그아웃 시 사용자별 ephemeral state를 자동 초기화하는 무음 listener.
///
/// ── 왜 필요한가 ──────────────────────────────────────────────────────
/// `selectedChildIdProvider` (StateProvider)는 사용자가 자녀 picker로 선택한 id를
/// 보관함. 로그아웃 → 다른 계정으로 로그인하면 그 id는 새 사용자에게 무의미.
/// 이전 id가 남아있으면 selectedChildProvider가 첫 자녀로 fallback돼서 동작은 하지만,
/// 매번 stale id로 lookup 시도 → 불필요한 비교 + 잠재 race.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// currentUser가 not-null → null로 바뀐 시점(=로그아웃)에 selectedChildId를 null로 reset.
/// FutureProvider/StreamProvider(myChildren, recent records 등)는 `currentUser`
/// 의존성이 있어서 자동 재계산되므로 별도 invalidate 불필요.
///
/// ── 사용 ──────────────────────────────────────────────────────────────
/// app.dart에서 MaterialApp.router의 builder로 감쌈.
class AuthStateResetListener extends ConsumerWidget {
  const AuthStateResetListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.listen은 build 도중 setState 발생 안 시킴 — listener로 안전.
    ref.listen<dynamic>(currentUserProvider, (previous, next) {
      // user 있다가 없어졌을 때만 reset (signedOut).
      // signedIn은 reset 불필요 — 새 user면 selectedChildId가 null인 게 default.
      if (previous != null && next == null) {
        ref.read(selectedChildIdProvider.notifier).state = null;
      }
    });
    return child;
  }
}
