/// Environment configuration. Values are injected at compile time via
/// `--dart-define=KEY=value` so secrets never live in source control.
///
/// Run example:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sentry DSN이 dart-define으로 주입됐는지. 비었으면 init 자체를 건너뜀
  /// (개발자가 sentry 프로젝트 만들기 전이거나 로컬 디버깅 단계).
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;
}
