# 결제 시스템 셋업 (Billing — RevenueCat + Play Console)

마지막 업데이트: 2026-05-16

## 📋 한눈에 보기

| 영역 | 상태 |
|---|---|
| 클라이언트 코드 (`lib/features/billing/`) | ✅ 완료 (`BillingService` 152줄, `PaywallPage` 270줄) |
| pubspec 의존성 (`purchases_flutter: ^10.0.2`) | ✅ 설치됨 |
| Env 변수 (`REVENUECAT_ANDROID_KEY`, `_IOS_KEY`) | ✅ 정의됨 |
| Entitlement 식별자 (`multi_child`) | ✅ 정의됨 (Env.billingEntitlement) |
| Supabase `subscriptions` 테이블 | ✅ 마이그레이션 05 |
| **RevenueCat 콘솔** | ⏳ 미셋업 |
| **Google Play 인앱상품** | ⏳ 미등록 |
| **Webhook (RevenueCat → Supabase)** | ⏳ 미구현 |
| **App Store Connect 인앱상품** | ⏳ iOS 출시 시 |

코드는 거의 다 있고 외부 콘솔 셋업이 핵심.

---

## 1️⃣ RevenueCat 콘솔 셋업

### a. 계정 + 프로젝트 생성

1. https://app.revenuecat.com 가입 (무료 시작, $0~$10k MRR 까지)
2. **Projects → Create new project** → 이름 "BabyNote"

### b. Android app 추가

1. **Project Settings → Apps → + New** → **Google Play Store**
2. 필드 채우기:
   - **App name**: `BabyNote Android`
   - **Package name**: `com.kjfamily.babynote`
   - **Service account credentials**: Play Console 에서 발급 (아래 c 단계 후 돌아오기)

### c. Google Play Service Account 발급

RevenueCat 가 Play 의 구독 상태를 조회/검증하려면 Service Account 키 필요.

1. **Google Play Console → Setup → API access**
2. **Create new service account** → Google Cloud Console 로 이동
3. **Service Accounts → Create Service Account**
   - Name: `revenuecat-sub-verify`
   - Roles: 없이 그냥 생성
4. 생성된 계정 → **Keys → Add Key → JSON** → 다운로드
5. Play Console 로 돌아와 새 계정에 권한 부여:
   - **Account permissions → Add user → "View financial data" + "Manage orders and subscriptions"**
6. JSON 파일을 RevenueCat → App 설정의 **Service account credentials** 에 업로드

### d. Entitlement 정의

Entitlement = "유료 사용자가 얻는 무엇" 의 추상 식별자. 우리는 1개:

1. RevenueCat → **Project → Entitlements → New**
2. **Identifier**: `multi_child` ⚠ 정확히 이 문자열 (Env.billingEntitlement 와 일치)
3. **Display name**: `Multi-Child Plan`
4. Save

### e. Products 정의

실제 사용자가 구매하는 상품. 2종류:

| 상품 | RevenueCat ID | Play Store ID (g) | 가격 |
|---|---|---|---|
| 자녀 1명 추가 / 년 | `extra_child_yearly` | `babynote_extra_child_yearly` | ₩19,900/년 |
| 가족 플랜 (자녀 무제한) / 년 | `family_yearly` | `babynote_family_yearly` | ₩49,900/년 |

1. RevenueCat → **Project → Products → + New product**
2. 두 번 반복 — 각각 RevenueCat ID 입력 + Play Store ID 매핑 + Entitlement `multi_child` 부여
3. **Attach entitlements** 에서 `multi_child` 선택

### f. Offering 구성

Offering = 사용자에게 보여줄 상품 묶음. 페이월에 노출되는 단위.

1. **Offerings → + New offering**
2. **Identifier**: `default`
3. **Packages** 추가:
   - `$rc_annual` (Annual) → `extra_child_yearly`
   - `$rc_lifetime` (Lifetime — 가족 플랜) → `family_yearly`
4. **Make current** 클릭 (default offering 활성화)

### g. API Keys 발급

1. **Project Settings → API keys**
2. **Public app-specific API keys** 영역:
   - Android key 복사 → `appl_` 또는 `goog_` 로 시작
   - (iOS 도 나중에)
3. 이 값을 `run/dev.json` + `run/prod.json` 에 추가:

```json
{
  "SUPABASE_URL": "...",
  "SUPABASE_ANON_KEY": "...",
  "SENTRY_DSN": "...",
  "FLAVOR": "dev",
  "REVENUECAT_ANDROID_KEY": "goog_여기에_복사한_키",
  "REVENUECAT_IOS_KEY": ""
}
```

---

## 2️⃣ Google Play Console 인앱상품 등록

> ⚠️ Play Console 가입 + 본인 인증 + $25 등록비 완료된 상태가 전제. [release/README.md](README.md) §KR 체크리스트 참고.

### a. 앱 생성 (아직 안 했으면)

1. **Play Console → Create app**
2. App name: `BabyNote` / Default language: 한국어
3. App type: App, Free
4. Declaration 체크박스 모두 동의

### b. AAB 한 번 업로드 (인앱상품 등록 전 필수)

Play Console 은 **AAB가 한 번이라도 업로드돼있어야** 인앱상품 메뉴가 활성화됨.

```powershell
cd "C:\Users\sarbr\StudioProjects\BabyNote"
C:\Users\sarbr\flutter\bin\flutter.bat build appbundle --release --dart-define-from-file=run\prod.json
```

생성물 `build/app/outputs/bundle/release/app-release.aab` 를 **내부 테스트 트랙**에 업로드.

### c. 인앱상품 등록

1. **Monetize → Products → Subscriptions** (구독 상품)
2. **Create subscription** → 2번 반복:

#### 상품 1: 자녀 1명 추가

| 필드 | 값 |
|---|---|
| Product ID | `babynote_extra_child_yearly` ⚠ RevenueCat 의 Play Store ID 와 일치 |
| Name | `자녀 1명 추가 (연 구독)` |
| Description | `자녀를 1명 추가로 등록할 수 있어요. 매년 자동 갱신.` |
| Base plan | Annual / `extra-child-annual` |
| Price | ₩19,900 / KR |
| Free trial | (선택) 7일 |

#### 상품 2: 가족 플랜

| 필드 | 값 |
|---|---|
| Product ID | `babynote_family_yearly` |
| Name | `가족 플랜 (연 구독, 자녀 무제한)` |
| Description | `자녀를 무제한으로 등록할 수 있어요. 매년 자동 갱신.` |
| Base plan | Annual / `family-annual` |
| Price | ₩49,900 / KR |

3. 둘 다 **Activate**

### d. 라이센스 테스트 — 결제 테스트

실제 결제 없이 테스트하려면:

1. **Play Console → Settings → License testing**
2. **Add testers** — 본인 + 가족 Gmail 추가
3. **License response**: `RESPOND_NORMALLY` (정상 결제 흐름) 또는 `LICENSED` (즉시 성공)
4. 테스터 기기에서 같은 Gmail 로 Play Store 로그인 + 내부 테스트 트랙에 합류
5. 앱 내 결제 → 무료로 구매 처리, 영수증은 RevenueCat 까지 전달됨

---

## 3️⃣ Webhook — RevenueCat → Supabase 동기화

`subscriptions` 테이블이 진실의 원천이 아니더라도 (RevenueCat 이 source),
RLS 와 빠른 권한 체크를 위해 미러링. RevenueCat 의 이벤트가 발생할 때마다
Supabase 테이블을 upsert.

### 구현 옵션 A: Supabase Edge Function (Recommended)

`supabase/functions/revenuecat-webhook/index.ts` (Deno):

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RC_WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET")!;

const supa = createClient(SUPABASE_URL, SERVICE_ROLE);

Deno.serve(async (req) => {
  const auth = req.headers.get("authorization");
  if (auth !== `Bearer ${RC_WEBHOOK_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  const event = payload.event;
  const userId = event.app_user_id;

  const status = mapStatus(event.type, event);
  const productId = event.product_id;
  const platform = event.store === "APP_STORE" ? "ios" : "android";

  await supa.from("subscriptions").upsert({
    user_id: userId,
    product_id: productId,
    platform,
    status,
    original_purchase_at: event.original_purchase_date,
    expires_at: event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null,
    revenuecat_user_id: userId,
    raw_payload: event,
  }, { onConflict: "user_id,product_id,platform" });

  return new Response("OK");
});

function mapStatus(type: string, e: any): string {
  switch (type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "PRODUCT_CHANGE":
      return "active";
    case "CANCELLATION":
      return e.cancel_reason === "BILLING_ERROR" ? "in_grace" : "cancelled";
    case "EXPIRATION":
      return "expired";
    default:
      return "active";
  }
}
```

배포:

```powershell
supabase functions deploy revenuecat-webhook
supabase secrets set REVENUECAT_WEBHOOK_SECRET=<랜덤_32자>
```

RevenueCat 콘솔에서:
1. **Project Settings → Integrations → Webhooks**
2. **URL**: `https://<your-supabase>.functions.supabase.co/revenuecat-webhook`
3. **Authorization header**: `Bearer <RC_WEBHOOK_SECRET>` (방금 설정한 값)
4. **Events to send**: All (또는 INITIAL_PURCHASE/RENEWAL/CANCELLATION/EXPIRATION)

### 구현 옵션 B: 클라이언트 측 동기화 (간단, 출시 직전엔 충분)

Webhook 없이 클라이언트가 `Purchases.getCustomerInfo()` 응답을 받아 본인 행 직접 upsert.

`lib/features/billing/data/billing_service.dart` 에 메서드 추가:

```dart
Future<void> syncToSupabase(SupabaseClient client, String userId) async {
  if (!_initialized) return;
  final info = await Purchases.getCustomerInfo();
  for (final entry in info.entitlements.active.entries) {
    final ent = entry.value;
    await client.from('subscriptions').upsert({
      'user_id': userId,
      'product_id': ent.productIdentifier,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'status': 'active',
      'original_purchase_at': ent.originalPurchaseDate,
      'expires_at': ent.expirationDate,
      'revenuecat_user_id': info.originalAppUserId,
    }, onConflict: 'user_id,product_id,platform');
  }
}
```

호출 시점: 결제 직후 + 앱 시작 직후.

**단점**: 사용자가 앱을 안 열면 갱신 안 됨. 정확성 중요하면 webhook 권장.

---

## 4️⃣ 검증 시나리오

### a. 페이월 표시
- 자녀 2명 추가 시도 → `multi_child` entitlement 없으면 PaywallPage 등장
- `lib/features/billing/presentation/paywall_page.dart` 의 두 패키지 (연/평생) 표시 확인

### b. 라이센스 테스트 결제
- 라이센스 테스터 계정으로 패키지 구매
- 영수증 즉시 RevenueCat 에 도달
- 클라이언트의 `hasMultiChildEntitlement` 가 true 로 즉시 갱신
- 자녀 추가 페이지 통과

### c. Supabase 동기화 확인
- Dashboard → Table Editor → `subscriptions` → 해당 user_id row 가 status=active 로 들어있는지

### d. 구매 복원
- 앱 데이터 클리어 → 같은 계정 로그인 → 설정에서 "구매 복원" → entitlement 살아남

### e. 만료 / 취소
- Play Console 테스트 환경에서 짧은 만료 (예: 5분) 시뮬레이션
- entitlement 가 false 로 변경 + Supabase status 가 expired 로 동기화

---

## 5️⃣ 출시 체크리스트

- [ ] RevenueCat 콘솔: 프로젝트/앱/entitlement/products/offering/api keys 모두 셋업
- [ ] Play Console: 인앱상품 2개 등록 + Activate
- [ ] `run/prod.json` 에 `REVENUECAT_ANDROID_KEY` 입력
- [ ] AAB release 빌드 후 내부 테스트 트랙 업로드 (`flutter build appbundle --release`)
- [ ] 라이센스 테스트 계정으로 결제 시뮬레이션 (구매/복원/만료)
- [ ] Webhook 셋업 (옵션 A) — 출시 직전엔 옵션 B 로 시작해도 됨
- [ ] PaywallPage 의 가격 표시가 RevenueCat 의 현재 offering 과 일치
- [ ] "이용 약관" / "개인정보처리방침" 링크가 RevenueCat 의 Subscription Group 페이지에 노출 (Apple 정책)

---

## 🔗 참고

- RevenueCat 공식 가이드: https://www.revenuecat.com/docs/welcome/overview
- Flutter SDK API: https://pub.dev/documentation/purchases_flutter/latest/
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- 가격 정책 협의 — 시장조사 결과 (스펙 §6.3):
  - 첫째 무제한 무료
  - 자녀 추가 ₩19,900/년 (≈ $14.99/년)
  - 가족 플랜 ₩49,900/년 (≈ $39.99/년)
  - 평생 가족 플랜 ₩129,000 (≈ $99) — 한국 시장 별도 검토

## 📌 다음 액션 (사용자 손)

1. RevenueCat 가입 → Project "BabyNote" 만들기
2. Google Play Service Account 발급 (Play Console)
3. RevenueCat 에 Service Account 연결 + Android app 등록
4. Entitlement `multi_child` + Products 2개 + Offering `default` 셋업
5. Play Console 에 같은 product_id 로 인앱상품 2개 등록 + Activate
6. API Key 받아서 `run/dev.json` 에 입력
7. 알려주시면 빌드 + 라이센스 테스트 진행
