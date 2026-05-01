import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// Supabase의 auth 이벤트 스트림을 그대로 노출하는 StreamProvider.
///
/// ── StreamProvider란 ────────────────────────────────────────────────
/// FutureProvider가 "한 번 비동기 결과"를 다룬다면, StreamProvider는
/// "시간에 따라 계속 흘러들어오는 값들"을 다룸. 위젯이 `ref.watch`하면
/// 새 값이 도착할 때마다 자동 rebuild.
///
/// auth 상태는 본질적으로 시간 흐름에 따라 변하므로(로그인 → 토큰 갱신 → 로그아웃)
/// Stream이 자연스러움.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// 현재 로그인된 사용자를 노출.
///
/// 위 StreamProvider를 watch해서 새 이벤트가 올 때마다 자동 갱신됨.
/// 값은 `User?` — 비로그인이면 null.
///
/// ── 왜 별도 provider로 빼나 ──────────────────────────────────────
/// 위젯 대부분은 "지금 사용자 누구야?" 만 궁금하지 어떤 이벤트(signedIn /
/// tokenRefreshed 등)가 발생했는지는 관심 없음. 그래서 한 겹 정제해서 노출.
final currentUserProvider = Provider<User?>((ref) {
  // ref.watch(authStateChangesProvider)는 AsyncValue<AuthState>를 반환.
  // 거기서 session이 있으면 user 추출, 없으면 currentUser fallback.
  final asyncAuth = ref.watch(authStateChangesProvider);

  // AsyncValue.when 으로 읽어도 되지만, 현재 user는 repo에 캐시되어 있음.
  // 스트림에서 새 이벤트 올 때마다 다시 평가해서 갱신.
  final repo = ref.watch(authRepositoryProvider);
  return asyncAuth.maybeWhen(
    data: (state) => state.session?.user ?? repo.currentUser,
    orElse: () => repo.currentUser,
  );
});

/// 앱 부팅 시 한 번 호출되어 세션이 없으면 익명 로그인을 수행하는 FutureProvider.
///
/// 위젯에서 `ref.watch`하면 "익명 세션 보장 작업"의 진행 상태를 AsyncValue로
/// 받게 됨. 부트스트랩 화면이 이 값을 보고 로딩/에러/성공을 분기.
final ensureAnonymousSessionProvider = FutureProvider<User>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.ensureAnonymousSession();
});
