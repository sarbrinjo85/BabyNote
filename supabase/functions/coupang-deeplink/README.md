# coupang-deeplink (Edge Function)

쿠팡 파트너스 Open API 로 **브랜드별 딥링크**(추적 링크)를 서버에서 생성한다.
Secret Key 를 앱에 넣지 않기 위한 서명 프록시 — 앱은 이 함수만 호출한다.

## 왜 필요한가

- 정적 카테고리 링크(Phase 1)는 "기저귀/분유" 검색으로만 이동 (브랜드 특정 X).
- Open API 딥링크(Phase 2)는 "하기스 기저귀" 처럼 **브랜드별 추적 링크** 생성 →
  전환율↑ + 상품 단위 정산.
- 쿠팡 서명에 **Secret Key** 필요 → 앱에 넣으면 APK 에서 유출 → **서버 필수**.

## 배포 (사용자 작업)

```bash
# 1) 쿠팡 파트너스 → 마이페이지 → Open API 에서 Access Key / Secret Key 발급

# 2) Supabase 시크릿 등록 (프로젝트 루트에서)
supabase secrets set COUPANG_ACCESS_KEY=발급받은_ACCESS_KEY
supabase secrets set COUPANG_SECRET_KEY=발급받은_SECRET_KEY

# 3) 함수 배포
supabase functions deploy coupang-deeplink
```

배포 전에도 앱은 **정적 카테고리 링크로 폴백**하므로 정상 동작한다 (수수료는
카테고리 단위로 계속 발생). 배포 후 자동으로 브랜드별 딥링크로 업그레이드된다.

## 앱 호출

```dart
supabase.functions.invoke('coupang-deeplink',
    body: { 'url': 'https://www.coupang.com/np/search?q=하기스 기저귀',
            'subId': 'diaper' });
// → { "shortenUrl": "https://link.coupang.com/a/xxxx" }
```

`AffiliateService.resolveReorderUrl()` 가 이 함수를 호출하고, 실패/미배포 시
`buildReorderUrl()`(정적 링크)로 폴백한다.

## 검증

```bash
supabase functions invoke coupang-deeplink \
  --body '{"url":"https://www.coupang.com/np/search?q=하기스 기저귀","subId":"diaper"}'
# → {"shortenUrl":"https://link.coupang.com/a/..."} 나오면 성공
```
