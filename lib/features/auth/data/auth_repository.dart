import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
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

  /// Google Sign-In — native SDK 방식 (선호).
  ///
  /// ── 동작 ─────────────────────────────────────────────────────────
  /// google_sign_in 패키지가 Google Play Services 의 native 다이얼로그 호출.
  /// 브라우저 안 거치고 곧바로 계정 선택 → idToken/accessToken 발급.
  /// 받은 idToken 으로 Supabase.auth.signInWithIdToken 호출 → 세션 발급.
  ///
  /// 브라우저 OAuth flow (signInWithGoogleViaBrowser) 대비 장점:
  /// - UX: 브라우저 깜빡임 없음
  /// - 속도: 자동 계정 매칭으로 1-2단계 단축
  /// - 안정성: deep link callback 의존 없음
  ///
  /// ── 사전 셋업 (docs/release/google_signin.md) ───────────────────
  /// 1. Google Cloud Console — Android OAuth 2.0 Client ID (앱 SHA-1 등록)
  /// 2. Google Cloud Console — Web OAuth 2.0 Client ID (Supabase 가 사용)
  /// 3. Supabase Dashboard → Auth → Providers → Google enable + Web Client ID 입력
  /// 4. Env.googleServerClientId 에 Web Client ID 주입 (run/dev.json)
  ///
  /// ── 에러 케이스 ──────────────────────────────────────────────────
  /// - 사용자가 다이얼로그 취소: GoogleSignIn 이 null 반환 → 조용히 skip
  /// - serverClientId 없음: Env 미설정 → 예외 발생, 호출 측에서 토스트
  /// - Play Services 미설치: PlatformException → 호출 측에서 토스트
  Future<User?> signInWithGoogle() async {
    if (Env.googleServerClientId.isEmpty) {
      throw StateError(
          'Google Sign-In 이 설정되지 않았어요 — GOOGLE_SERVER_CLIENT_ID 누락.');
    }
    final googleSignIn = GoogleSignIn(
      serverClientId: Env.googleServerClientId,
      scopes: ['email', 'profile'],
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // 사용자가 다이얼로그 취소
    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Google 로그인 결과에 idToken 이 없어요.');
    }
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    return response.user;
  }

  /// 구 OAuth (브라우저 redirect) flow — fallback.
  /// 신규 구현은 signInWithGoogle 사용 권장. 이 메서드는 native SDK 가 실패할 때
  /// (예: Play Services 없는 환경) 대안으로 호출 가능.
  Future<bool> signInWithGoogleViaBrowser() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
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
