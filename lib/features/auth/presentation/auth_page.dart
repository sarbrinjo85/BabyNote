import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// 로그인 / 회원가입 화면.
///
/// 위쪽 탭: 로그인 / 회원가입 전환
/// 아래쪽: Google 버튼 (구분선 위)
///
/// ── 학습 포인트 ───────────────────────────────────────────────────
/// 1. DefaultTabController + TabBar — 화면 안에서 탭 전환
/// 2. async 작업 + try/catch + SnackBar로 에러 표시
/// 3. Google OAuth는 외부 브라우저로 빠지므로 호출 후 자동 화면 전환은
///    AuthGate(StreamProvider 구독)가 처리. 이 화면은 그냥 트리거만 함.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  // 두 탭이 컨트롤러를 공유하지 않게 별도 키 — DefaultTabController로 단순화.
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  // 회원가입 탭에서만 사용 — 가족 공유 시 다른 부모에게 보이는 표시 이름.
  final _displayNameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    // TextEditingController는 명시적 dispose 안 하면 메모리 leak.
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      // 성공 시 화면 전환은 AuthGate가 자동 처리 (auth state stream).
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    final repo = ref.read(authRepositoryProvider);
    await _runAuth(() => repo.signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ));
  }

  Future<void> _signUp() async {
    final repo = ref.read(authRepositoryProvider);
    await _runAuth(() => repo.signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _displayNameCtrl.text.trim().isEmpty
              ? null
              : _displayNameCtrl.text.trim(),
        ));
  }

  Future<void> _signInGoogle() async {
    final repo = ref.read(authRepositoryProvider);
    await _runAuth(() => repo.signInWithGoogle());
    // Google은 외부 브라우저 → 돌아오면 onAuthStateChange가 트리거 → AuthGate가 화면 전환.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.authStartTitle),
          bottom: TabBar(
            tabs: [Tab(text: l10n.authLogin), Tab(text: l10n.authSignup)],
          ),
        ),
        // SafeArea(bottom: true)로 감싸서 시스템 네비게이션 바 영역만큼 자동으로
        // 패딩이 들어가게 함 → Google 버튼이 안 잘림.
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      // ── 로그인 탭 ───────────────────────────────
                      _EmailForm(
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        displayNameCtrl: null,
                        busy: _busy,
                        submitLabel: l10n.authLogin,
                        onSubmit: _signIn,
                      ),
                      // ── 회원가입 탭 ─────────────────────────────
                      _EmailForm(
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        displayNameCtrl: _displayNameCtrl,
                        busy: _busy,
                        submitLabel: l10n.authSignup,
                        onSubmit: _signUp,
                      ),
                    ],
                  ),
                ),
                // ── 공통: 구분선 + Google 버튼 ─────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l10n.commonOr),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signInGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 이메일 + 비밀번호 입력 폼 (로그인/가입 둘이 공유).
/// 회원가입 모드는 displayNameCtrl이 not-null이면 displayName 필드 추가.
class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.displayNameCtrl,
    required this.busy,
    required this.submitLabel,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  /// null이면 폼에 displayName 필드 표시 안 함 (로그인 모드).
  final TextEditingController? displayNameCtrl;
  final bool busy;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        TextField(
          controller: emailCtrl,
          decoration: InputDecoration(
            labelText: l10n.authEmail,
            hintText: 'name@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordCtrl,
          decoration: InputDecoration(
            labelText: l10n.authPassword,
          ),
          obscureText: true,
        ),
        if (displayNameCtrl != null) ...[
          const SizedBox(height: 16),
          TextField(
            controller: displayNameCtrl!,
            decoration: InputDecoration(
              labelText: l10n.authDisplayNameLabel,
              hintText: l10n.authDisplayNameHint,
              helperText: l10n.authDisplayNameHelp,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: busy
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}
