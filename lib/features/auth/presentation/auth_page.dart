import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _busy = false;

  @override
  void dispose() {
    // TextEditingController는 명시적 dispose 안 하면 메모리 leak.
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      // 성공 시 화면 전환은 AuthGate가 자동 처리 (auth state stream).
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('실패: $e')));
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
        ));
  }

  Future<void> _signInGoogle() async {
    final repo = ref.read(authRepositoryProvider);
    await _runAuth(() => repo.signInWithGoogle());
    // Google은 외부 브라우저 → 돌아오면 onAuthStateChange가 트리거 → AuthGate가 화면 전환.
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('베이비노트 시작'),
          bottom: const TabBar(
            tabs: [Tab(text: '로그인'), Tab(text: '회원가입')],
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
                        busy: _busy,
                        submitLabel: '로그인',
                        onSubmit: _signIn,
                      ),
                      // ── 회원가입 탭 ─────────────────────────────
                      _EmailForm(
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        busy: _busy,
                        submitLabel: '회원가입',
                        onSubmit: _signUp,
                      ),
                    ],
                  ),
                ),
                // ── 공통: 구분선 + Google 버튼 ─────────────────────
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('또는'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _signInGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Google 계정으로 계속'),
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
class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.busy,
    required this.submitLabel,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool busy;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'name@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordCtrl,
          decoration: const InputDecoration(
            labelText: '비밀번호',
            hintText: '6자 이상',
          ),
          obscureText: true,
        ),
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
