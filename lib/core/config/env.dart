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

  /// Google Sign-In native SDK 용 Web OAuth 2.0 Client ID.
  /// Google Cloud Console → Credentials → Web application 의 Client ID 를
  /// run/dev.json (또는 prod.json) 에 GOOGLE_SERVER_CLIENT_ID 로 주입.
  ///
  /// Android 앱은 별도 Android OAuth Client ID 가 필요하지만 그건 SHA-1 등록만
  /// 하면 되고 코드엔 안 들어감. signInWithIdToken 가 받는 idToken 의 audience
  /// 는 Web Client ID 라서 그것을 GoogleSignIn 에 serverClientId 로 전달.
  static const googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isGoogleSignInEnabled => googleServerClientId.isNotEmpty;

  /// 쿠팡 파트너스 카테고리별 추적 링크 (Partners ID AF2420215 임베드).
  /// 이 link.coupang.com 딥링크를 통한 클릭만 수수료가 정산됨 — 일반 검색 URL은
  /// 수수료 안 붙음. **공개 링크라 소스에 포함해도 무방** (앱에 노출되는 값).
  /// 링크 교체 시 dart-define 으로 재정의 가능. 비면 검색 URL 폴백(수수료 X).
  static const affiliateCoupangDiaperUrl = String.fromEnvironment(
    'AFFILIATE_COUPANG_DIAPER_URL',
    defaultValue: 'https://link.coupang.com/a/gfu3hKD5GK',
  );
  static const affiliateCoupangFormulaUrl = String.fromEnvironment(
    'AFFILIATE_COUPANG_FORMULA_URL',
    defaultValue: 'https://link.coupang.com/a/gfu5qRJuyi',
  );

  /// 파트너스 추적 링크가 하나라도 설정됐는지 → 수수료 고지 문구 노출 판단.
  static bool get isAffiliateActive =>
      affiliateCoupangDiaperUrl.isNotEmpty ||
      affiliateCoupangFormulaUrl.isNotEmpty;
}
