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
  /// Google Places API 키 — 병원/가게 등 장소 자동완성에 사용.
  /// dart-define으로 주입. 비었으면 자동완성 비활성 (앱은 정상 동작).
  static const googlePlacesApiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sentry DSN이 dart-define으로 주입됐는지. 비었으면 init 자체를 건너뜀
  /// (개발자가 sentry 프로젝트 만들기 전이거나 로컬 디버깅 단계).
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;

  /// Google Places API 키가 주입됐는지.
  static bool get isPlacesEnabled => googlePlacesApiKey.isNotEmpty;

  /// RevenueCat 공개 API 키.
  /// app.revenuecat.com → Project → API keys 발급. 비어 있으면 결제 비활성.
  static const revenueCatAndroidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const revenueCatIosKey =
      String.fromEnvironment('REVENUECAT_IOS_KEY');

  static bool get isBillingEnabled =>
      revenueCatAndroidKey.isNotEmpty || revenueCatIosKey.isNotEmpty;

  /// 멀티 자녀 entitlement 식별자 (RevenueCat 콘솔에서 동일하게 등록).
  static const billingEntitlement = 'multi_child';
}
