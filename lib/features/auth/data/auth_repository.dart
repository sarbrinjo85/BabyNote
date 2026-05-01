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

  /// 익명 사용자로 로그인.
  ///
  /// ── 익명 로그인이란 ─────────────────────────────────────────────
  /// 회원가입 없이 즉시 사용 가능한 임시 사용자를 만들어줌. `auth.uid()`가
  /// 정상적으로 채워지므로 RLS 정책이 그대로 동작 (= "본인 데이터"라는 개념 유지).
  /// 나중에 사용자가 이메일/소셜로 정식 가입하면 `linkIdentity`로 익명 계정을
  /// 정식 계정에 흡수시킬 수 있음 → 데이터 손실 없이 회원전환.
  ///
  /// ── 멱등성 ──────────────────────────────────────────────────────
  /// 이미 세션이 있으면 그대로 반환 (다시 익명 사용자 만들지 않음).
  /// 부트스트랩 단계에서 안전하게 여러 번 호출 가능.
  Future<User> ensureAnonymousSession() async {
    final existing = currentUser;
    if (existing != null) return existing;

    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    if (user == null) {
      // signInAnonymously 성공 시 user는 거의 항상 채워지지만, 방어적으로 처리.
      throw StateError('익명 로그인 응답에 user가 없습니다.');
    }
    return user;
  }

  /// 로그아웃. 익명 사용자도 로그아웃 가능 (그러면 데이터 접근 불가).
  Future<void> signOut() => _client.auth.signOut();
}

/// AuthRepository를 만들고 SupabaseClient 의존성을 주입하는 provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
