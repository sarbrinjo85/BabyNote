import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../billing/data/billing_service.dart';
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
    ref.listen<User?>(currentUserProvider, (previous, next) {
      final prevId = previous?.id;
      final nextId = next?.id;
      if (prevId != null && nextId == null) {
        // signedOut — 사용자별 ephemeral state reset.
        // signedIn은 reset 불필요 — 새 user면 selectedChildId가 null인 게 default.
        ref.read(selectedChildIdProvider.notifier).state = null;
        // RevenueCat 도 익명 사용자로 전환 (다음 회원의 구독과 섞이지 않게).
        unawaited(BillingService.instance.logOut());
      } else if (nextId != null && prevId != nextId) {
        // signedIn 또는 계정 변경 — RevenueCat appUserId 를 Supabase userId 로 연결.
        // 이 호출이 없으면 구독이 익명 ID 에 묶여 "구매 복원"이 회원 계정과
        // 어긋남. (콜드 스타트 초기 연결은 main.dart 에서 처리.)
        unawaited(BillingService.instance.logIn(nextId));
      }
    });
    return child;
  }
}
