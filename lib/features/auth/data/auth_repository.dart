import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';

/// Supabase Auth API를 우리 앱이 쓸 만한 모양으로 감싼 얇은 계층.
///
/// ── 왜 Repository로 한 겹 더 감싸나 ─────────────────────────────────
/// `SupabaseClient.auth.signInAnonymously()`를 위젯에서 직접 호출하면 위젯이
/// Supabase API 형태에 강하게 묶여버림. 나중에 다른 인증 백엔드로 바꾸거나
/// 테스트에서 mock 하려면 위젯을 다 고쳐야 함.
///
/// Repository를 한 겹 두면 위젯 입장에선 "auth_repo.signInAnonymously()" 한 줄.
/// 내부 구현이 바뀌어도 호출 측은 모름 — 이게 의존성 역전(DIP)의 가벼운 적용.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// 현재 살아있는 세션을 반환 (없으면 null).
  Session? get currentSession => _client.auth.currentSession;

  /// 현재 로그인된 사용자(없으면 null).
  User? get currentUser => _client.auth.currentUser;

  /// auth 상태 변화를 스트림으로 노출.
  ///
  /// ── 어떤 이벤트가 들어오나 ──────────────────────────────────────
  /// signedIn / signedOut / tokenRefreshed / userUpdated / passwordRecovery 등.
  /// 각 이벤트마다 `AuthState { event, session }` 형태로 도착.
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  /// 익명 사용자로 로그인 (현재는 사용 안 함 — onboarding이 SNS/Email 강제).
  /// 추후 "둘러보기" 모드를 지원할 일 있으면 이 메서드로 즉시 부활 가능.
  Future<User> ensureAnonymousSession() async {
    final existing = currentUser;
    if (existing != null) return existing;
    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    if (user == null) throw StateError('익명 로그인 응답에 user가 없습니다.');
    return user;
  }

  /// 이메일 + 비밀번호로 신규 가입.
  ///
  /// Supabase는 가입 직후 자동 로그인 처리 (=세션 발급). "Confirm email" 옵션이
  /// ON이면 사용자가 메일 확인 전엔 세션은 있어도 일부 기능이 제한됨. 개발 단계
  /// 에선 OFF로 두는 게 편함 (Supabase Dashboard → Auth → Providers → Email).
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // raw_user_meta_data에 display_name 포함 → handle_new_user 트리거가
    // user_profiles.display_name으로 자동 옮김 (01_users_caregivers.sql).
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
      },
    );
    final user = response.user;
    if (user == null) throw StateError('가입 응답에 user가 없습니다.');
    return user;
  }

  /// 이메일 + 비밀번호로 로그인.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth
        .signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) throw StateError('로그인 응답에 user가 없습니다.');
    return user;
  }

  /// Google OAuth 로그인.
  ///
  /// ── 동작 ─────────────────────────────────────────────────────────
  /// 외부 브라우저(또는 in-app browser)를 띄워서 Google 로그인 페이지로 보냄.
  /// 사용자가 인증 끝내면 Google → Supabase callback URL로 redirect → Supabase가
  /// 토큰 발급 후 우리 앱의 deep link(`com.kjfamily.babynote://auth-callback`)로
  /// 다시 redirect → 앱이 받아서 supabase_flutter SDK가 세션을 로컬에 저장.
  ///
  /// 이 메서드 자체는 "외부 페이지 띄우기"만 트리거하고 즉시 반환 (return true).
  /// 실제 로그인 완료 신호는 onAuthStateChange 스트림에서 signedIn 이벤트로 도착.
  /// 그래서 호출 측은 이 메서드 결과보다는 currentUserProvider가 갱신되는 걸 봐야 함.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Android/iOS deep link. AndroidManifest의 intent filter와 일치해야 함.
      redirectTo: 'com.kjfamily.babynote://auth-callback',
    );
  }

  /// 로그아웃. 토큰을 폐기하고 onAuthStateChange가 signedOut 이벤트 발행.
  Future<void> signOut() => _client.auth.signOut();
}

/// AuthRepository를 만들고 SupabaseClient 의존성을 주입하는 provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
