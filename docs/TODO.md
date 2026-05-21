# 남은 업무 (Remaining Tasks)

마지막 업데이트: 2026-05-16

[PROGRESS.md](PROGRESS.md) 와 짝. 작업 시작 시 여기서 ▢ → 🟡 → ✅ 로 갱신 후
완료 항목은 PROGRESS.md 로 옮겨 보관.

각 항목은 ID(예: `Y1`), 상태, 예상 시간, 의존성 표기.

---

## 🔴 1순위 — 출시 직전 필수

### Y1. 결제 시스템 콘솔 셋업 + 검증
🟡 | ~6h | 사용자 + 코드 작업 양쪽 | 상세: [release/billing.md](release/billing.md)

코드는 이미 있음 (`lib/features/billing/`, `purchases_flutter`,
`subscriptions` 테이블). 콘솔 셋업 완료 — 라이센스 테스트만 남음.

- ✅ RevenueCat 계정 생성 + 프로젝트 만들기
- ✅ Android app 추가 + Google Play 연동 (Service Account JSON → Valid)
- ✅ Entitlement `multi_child` 정의
- ✅ Products `babynote_extra_child_yearly` / `babynote_family_yearly` 생성
- ✅ Google Play Console — 인앱상품 등록 (각각 ₩19,900/년 / ₩49,900/년)
- ✅ `run/dev.json` 에 `REVENUECAT_ANDROID_KEY` 추가 (`goog_...`)
- ✅ Offering `default` + Current + 2 packages 매핑
- ✅ 결제 프로필 + 은행 계좌 인증 완료 (2026-05-20)
- ⏭️ Webhook (Google dev notifications / Pub/Sub) — 출시 후 추가 (선택)
- 🟡 테스트 결제 (Play Console 라이센스 테스트) ← **지금 진행**
- ▢ 자녀 추가 시 paywall 게이트 동작 검증
- ▢ "구매 복원" 버튼 검증

### Y2. AAB 빌드 + Play Console 업로드
▢ | ~1h | Y1 후 또는 병행 가능

- ▢ `flutter build appbundle --release --dart-define-from-file=run/prod.json`
- ▢ Play Console 가입 ($25 일회)
- ▢ 앱 생성 (패키지명 `com.kjfamily.babynote`)
- ▢ **내부 테스트 트랙** 에 AAB 업로드
- ▢ 앱 메타데이터 입력 (`docs/release/app_store_metadata.md` 의 KR 섹션)
- ▢ **Data Safety** 신고 (수집 데이터 + 공유 여부)
- ▢ 연령 등급 설문 (만 3세+)
- ▢ 스크린샷 업로드 (Y3 와 종속)

### Y3. 스크린샷 캡처
▢ | ~1d (디자이너 협업 가능)

- ▢ 데모 자녀 1~2명 + 일주일치 기록 생성 (수유 30회+, 수면 14회+, 기저귀 50회+, 산책/목욕/영양제 각 5건+)
- ▢ 분유 재고 "3일 후 떨어짐" 상태 시연
- ▢ 다가오는 백신 카드 1건 시연
- ▢ Android phone 1080×1920+ 최소 5장 (홈/분유알림/부부공유/접종/통계 화면)
- ▢ Featured graphic 1024×500 디자인
- ▢ 자막 띠 합성 (`docs/release/app_store_metadata.md` 의 자막 카피)
- ▢ 권역별 시스템 언어 변경 후 KR/JA/EN 3 세트

### Y4. 베타 테스트
▢ | ~3일 | Y1 + Y2 후

- ▢ 베타 테스터 모집 (가족/지인 3~5명 시작)
- ▢ 내부 테스트 → 닫힌 베타 단계적 확대
- ▢ 피드백 수집 채널 (Google Form 또는 카톡)
- ▢ 크래시 모니터링 (Sentry) 확인
- ▢ 결제 흐름 베타에서 검증

---

## 🟠 2순위 — 출시 직전이지만 미루기 가능

### Y5. EN/JA 법무문서 번역
✅ 완료 (2026-05-16)

- ✅ `docs/privacy_policy_en.md` — GDPR/CCPA 친화적 자연스러운 영문
- ✅ `docs/privacy_policy_ja.md` — 일본 개인정보보호법 + GDPR 언급
- ✅ `docs/terms_of_service_en.md`
- ✅ `docs/terms_of_service_ja.md`
- ✅ `docs/index.md` 활성화 (한·영·일 3개 언어 인덱스)
- ✅ `docs/release/app_store_metadata.md` URL 6개로 확장 (KR/EN/JA × privacy/terms)

### Y6. App Store Connect (iOS) 셋업
▢ | ~1d | macOS 머신 필요

- ▢ Apple Developer Program 가입 ($99/년)
- ▢ Bundle ID `com.kjfamily.babynote` 등록
- ▢ Apple Sign-In 활성화 (필수 — 다른 소셜 사용 시)
- ▢ App Store Connect 앱 생성 + 메타데이터
- ▢ Xcode Archive → TestFlight 업로드
- ▢ iOS 출시는 Android 안정화 후 진행

### Y7. CI/CD (GitHub Actions)
✅ 완료 (2026-05-16) — 시크릿 셋업만 사용자 손에 남음

- ✅ `.github/workflows/analyze.yml` — PR / push 마다 analyze + gen-l10n + test (시크릿 불필요)
- ✅ `.github/workflows/build-android.yml` — push to main / v* 태그 / 수동 시 AAB+APK release 빌드 → artifact 업로드
- ✅ `docs/release/ci_cd.md` — 시크릿 셋업 + base64 keystore 변환 + 자주 막히는 곳 가이드
- ⏳ **사용자 작업**: GitHub Secrets 8개 등록 (위 문서 §🔑 참고)
- ▢ (후속) fastlane + Google Play API 로 Internal Testing 트랙 자동 배포
- ▢ (후속) macOS runner 추가 → iOS 빌드

### Y8. 옵티미스틱 큐잉 행 UI 표시
✅ 완료 (2026-05-16)

- ✅ `writeQueuePendingKeysProvider` (Set\<String\>) — `{table}::{rowId}` 포맷
- ✅ records_page 의 각 _DailyEvent 가 `isPending` 플래그 보유
- ✅ _RecordCard 가 isPending 시 옅은 amber 배경 + ☁️⬆️ "동기화 대기 중" 라벨
- ✅ OfflineWrites/SyncWorker 가 enqueue/flush 후 provider invalidate

### Y22. 온보딩 코치 마크에 루틴/건강 섹션 반영
✅ 완료 (2026-05-20)

- ✅ `onboarding_coach.dart`: `routineSectionKey` + `symptomSectionKey` GlobalKey 추가
- ✅ `TargetFocus` 2개 신규 — "하루 루틴" / "건강 기록" (records 단계 뒤에 삽입)
- ✅ `home_page.dart`: 루틴/건강 GridView 를 keyed Container 로 감싸 코치 타겟 부착
- ✅ flutter analyze 통과 / 검증: `OnboardingCoach.resetForTest()` 후 재표시 확인 권장

### Y23. 가족 플랜 구매/복원 — RevenueCat 회원 연결 누락 (해결)
✅ 코드 수정 완료 (2026-05-20) — 재빌드 후 검증 필요

근본 원인: `BillingService.logIn()`/`logOut()` 이 정의만 있고 호출되지 않아
RevenueCat 이 익명 ID 사용 → 구독이 Supabase 회원이 아니라 익명 사용자에 묶임
→ 복원/계정 간 동기화 어긋남.

- ✅ `main.dart`: 콜드스타트(세션 복원) 시 `BillingService.logIn(restoredUser.id)`
- ✅ `auth_state_reset_listener.dart`: 로그인 시 `logIn(userId)`, 로그아웃 시 `logOut()`
- ✅ flutter analyze 통과
- ⏳ 재빌드 후 검증: RevenueCat Customers 에서 Supabase UID 로 검색되는지 +
      복원 동작. (구매 페이지 안 뜸 증상은 Play 인앱상품 전파 지연이 유력 — 재현 시 재조사)

### Y24. 법무문서 "기록 데이터" 에 루틴/건강 항목 추가
✅ 완료 (2026-05-20)

- ✅ `docs/privacy_policy.md` / `_en.md` / `_ja.md` — 기록 데이터에 루틴·건강 추가
- ✅ `lib/features/legal/presentation/legal_doc_page.dart` — 인앱 개인정보(76) +
      약관 정의(156) + 서비스 설명(168) 모두 반영
- ✅ `docs/terms_of_service.md` / `_en.md` / `_ja.md` — 정의 + 서비스 설명 반영
- ✅ 사진 예시(이유식·발진·상처) KR 문서도 보강
- ▢ (남음) Play Console **Data Safety** 신고 항목과 일치 확인 — Y2 진행 시

### Y25. 홈 화면에 "가족 플랜 이용 중" 뱃지 표시
✅ 완료 (2026-05-20)

- ✅ `_FamilyPlanBadge` 위젯 — `Env.isBillingEnabled && hasMultiChildEntitlementProvider`
      가드 (dev 오표시 방지), 비활성 시 `SizedBox.shrink()`
- ✅ `home_page.dart`: ChildInfoCard 아래 👑 chip 노출
- ✅ l10n `homeFamilyPlanBadge` ko/ja/en 추가 + gen-l10n
- ✅ flutter analyze 통과
- ▢ (후속) 탭 시 구독 관리 안내 + 설정 "가족 플랜" 진입 시 구독 중 상태 표시

---

## 🧪 테스트 중 발견한 UI/UX 개선 (누적)

내부 테스트하면서 발견하는 UI/UX 개선 항목을 여기 모음.
**1차 배치 U1~U5 + 데이터 내보내기 안내문구 → ✅ 완료 (2026-05-21, v1.0.0+3)**
이후 발견 항목은 U6~ 로 계속 누적.

### U1. "구매 복원" 버튼이 환불로 오해됨
▢ | ~20m | UX 명확성

paywall AppBar 의 "구매 복원" 버튼(`paywall_page.dart:83-87`)이 "구매 복원"
텍스트만 있어 사용자가 **환불 기능으로 오해**함. 복원=이미 산 구독 되살리기,
환불과 무관함을 명확히.

- ▢ 버튼 아래/옆에 보조 설명 한 줄: "이전에 구매한 구독을 이 기기에 다시 불러와요"
- ▢ 또는 paywall 본문 하단 안내 문구("기기 변경·재설치 시 구매 복원을 눌러주세요")
- ▢ l10n ko/ja/en
- ▢ (검토) 환불/해지는 스토어에서 처리됨을 안내하는 도움말 링크

### U2. paywall 헤더 문구 — "첫째 무료" 강조 + 줄바꿈
▢ | ~20m | UX 가독성

paywall 부제(`paywall_page.dart:112-118`)
"첫째는 평생 무료. 둘째부터 자녀를 추가하려면 가족 플랜이 필요해요." 가
한 줄에 다 들어가 애매하게 길고 강조점이 약함.

- ▢ **"첫째는 무료"** 를 시각적으로 강조 (굵게/큰 글씨 또는 별도 라인)
- ▢ **"둘째부터…"** 는 다음 줄로 분리해서 표시
- ▢ 예시 구성:
      1줄(강조): "첫째는 평생 무료"
      2줄(보조): "둘째부터 자녀를 추가하려면 가족 플랜이 필요해요"
- ▢ l10n ko/ja/en (현재 하드코딩이면 문자열만 교체 또는 RichText/2-Text 구성)

### U3. 가족팩 위에 추천 안내 문구
▢ | ~30m | UX 전환 유도

paywall 상품 목록(`paywall_page.dart:160-178`, `availablePackages` 루프)에서
**가족팩(`babynote_family_yearly`) 카드 위에** "자녀 2명 이상은 가족팩이
좋습니다" 같은 추천 안내를 띄워 전환 유도.

- ▢ 루프 안에서 product identifier 가 `babynote_family_yearly` 인 패키지를 식별
      (`pkg.storeProduct.identifier` 에 `:p1y` 접미사 포함될 수 있어 `contains`/
      `startsWith` 로 매칭)
- ▢ 해당 카드 위에 작은 추천 라벨/배지 ("👍 자녀 2명 이상은 가족팩 추천" 등)
- ▢ 또는 _PackageCard 에 `recommended` 플래그 추가 → 카드 상단에 리본/칩
- ▢ l10n ko/ja/en
- ▢ (검토) 자녀 수에 따라 동적으로 문구 변경 (2명↑일 때만 강조 등)

### U4. 루틴/건강 등록 — 종류 칩을 한 줄로 표시
▢ | ~30m | UX 레이아웃

루틴 등록(`routine_register_page.dart:221-244`)과 건강 등록
(`symptom_register_page.dart` 동일 패턴)의 종류 선택이 `Wrap` 이라 화면 폭에
따라 2줄로 접힘. 4종(산책/목욕/영양제/간식, 기침/구토/발진/상처)을 **항상 한 줄**로
표시하고 싶음.

- ▢ `Wrap` → `Row` (각 칩 `Expanded`/`Flexible`) 로 변경, 또는
      `SingleChildScrollView(scrollDirection: Axis.horizontal)` 로 가로 스크롤
- ▢ 좁은 화면 overflow 주의 — 라벨 축약/폰트 축소 또는 이모지+짧은 라벨
- ▢ 선택 상태 색(코랄) / 편집 모드 잠금 동작 유지
- ▢ 루틴·건강 양쪽 동일 적용

### U5. 홈 화면 단순화 — 루틴/건강을 큰 버튼 1개로 통합
▢ | ~1.5h | UX 단순화 (구조 변경) | 발견: 2026-05-21

홈 화면이 복잡함. 현재 루틴 4타일(산책/목욕/영양제/간식) + 건강 4타일
(기침/구토/발진/상처) = 8개 타일이 나열돼 시각적 부담. 각각 **"루틴" / "건강"
큰 버튼 1개씩**으로 묶어 단순화.

현재 구조 (`home_page.dart`):
- 루틴 섹션: `_SectionLabel(routineSectionHome)` + `GridView.count(4)` 4타일
      → 각 타일 `/routine/new` (extra: 특정 RoutineKind)
      → `Container(key: routineSectionKey)` 로 감쌈 (코치 마크 타겟)
- 건강 섹션: 동일 패턴, `/symptom/new`, `symptomSectionKey`

변경안:
- ▢ 루틴 4타일 → **"루틴" 큰 버튼 1개** (탭 → `/routine/new`, kind 미지정)
      등록 페이지에 이미 kind 토글 있으니 거기서 선택 (U4 와 함께 자연스러움)
- ▢ 건강 4타일 → **"건강" 큰 버튼 1개** (탭 → `/symptom/new`)
- ▢ 큰 버튼 형태: `big_action_button.dart` 또는 RecordButtonsGrid 톤과 통일
- ▢ 코치 마크 키(`routineSectionKey`/`symptomSectionKey`)를 새 버튼에 재부착
      → Y22 코치 단계 그대로 동작 유지
- ▢ (트레이드오프) 타일별 "마지막 시간"(`lastFor`/`lastSymptomFor`) 표시가 사라짐
      → 큰 버튼 subtitle 에 "가장 최근 루틴 N시간 전" 식으로 대표 1개만 표시 검토
- ▢ 메인 기록(수유/수면/기저귀/성장) 4타일은 그대로 둘지, 전체 레이아웃 톤 함께 점검

<!-- 추가 항목은 U6, U7 … 으로 아래에 누적 -->

---

## 🟡 3순위 — 수익화 / 확장

### Y9. 어필리에이트 백엔드 (K)
▢ | ~1d

- ▢ Cloudflare Workers 프로젝트 생성
- ▢ `/r/{partner}/{product_id}` → 파트너 URL 로 리다이렉트
- ▢ Edge KV 또는 D1 으로 클릭 카운트 저장
- ▢ Supabase `affiliate_clicks` 테이블에 동기화 (이미 마이그레이션 05 에 있음)
- ▢ 클라이언트 측 `affiliate_repository` 와 연동

### Y10. Google Sign-In (F-1)
✅ 코드 완료 (2026-05-16) — 콘솔 셋업 사용자 손

- ✅ `google_sign_in: ^6.2.2` pubspec 활성화
- ✅ `AuthRepository.signInWithGoogle()` — native SDK + signInWithIdToken
- ✅ `signInWithGoogleViaBrowser()` — fallback 유지
- ✅ `Env.googleServerClientId` (`GOOGLE_SERVER_CLIENT_ID`)
- ✅ `auth_page` Google 버튼 — native flow 호출
- ✅ `build-android.yml` 워크플로 — GOOGLE_SERVER_CLIENT_ID dart-define 추가
- ✅ `docs/release/google_signin.md` — 상세 셋업 가이드 (SHA-1 / OAuth Client / Supabase)
- ⏳ **사용자 작업**: 가이드 §1~§4 따라 콘솔 셋업 + run/dev.json 키 주입
- ⏳ (firebase-messaging 없으면 google-services.json 도 불필요)

### Y11. Apple Sign-In (F-2)
▢ | ~2h | iOS 출시 시 필수

- ▢ `sign_in_with_apple: ^6.1.4` pubspec 활성화
- ▢ Apple Developer 에서 Sign in with Apple 활성화
- ▢ Supabase Auth → Apple provider
- ▢ AuthPage 에 "Apple 로 계속" 버튼

---

## 🟢 4순위 — 큰 인프라

### Y12. Brick offline-first 전면 도입 (E-full)
▢ | 2~3일

- ▢ Brick 의존성 추가 (이전에 시도, 현재 주석)
- ▢ `lib/brick/` 디렉터리 구조 + `build.yaml`
- ▢ 모든 모델을 `OfflineFirstWithSupabaseModel` 로 변환
- ▢ build_runner 코드젠
- ▢ AppRepository 싱글톤
- ▢ 기존 11개 repo 의 OfflineWrites + WriteQueue 제거 (Brick 이 흡수)
- ▢ 충돌 해결 정책 (last-write-wins, 시간 차 5분 이상 별도 기록)
- ▢ 오프라인 *읽기* 가 사용자에게 보여지는 UX

### Y13. 자녀 picker UI 정리 (R)
▢ | ~1h

- ▢ 2명+일 때 body 안 Wrap chips → AppBar bottom 또는 다른 위치?
- ▢ 이전에 시도 후 revert — 새 UX 결정 필요
- ▢ 디자인 의견 모은 다음 진행

### Y14. RecordButtonsGrid 패턴을 routines/symptoms 에도
✅ 완료 (2026-05-16)

- ✅ GridActionTile 에 subtitle 파라미터 (선택, 9pt 보조 텍스트)
- ✅ 홈에서 recentRoutines/recentSymptoms 를 kind 별로 집계 → 마지막 시간
- ✅ TimeAgo 로 "3시간 전" / "어제 18:30" / "3일 전" 등 자연어 표시
- ✅ 8개 타일 모두 적용 (기록 없으면 subtitle 안 표시)

---

## ⚪ 5순위 — 부가 가치 / 후순위

| ID | 작업 | 비고 |
|---|---|---|
| Y15 | LINE Sign-In | 일본 출시 시 검토 |
| Y16 | Cloud Push (Firebase Messaging) | 알림은 현재 local notification 만 — 가족 사이 push 안 됨 |
| Y17 | 데이터 마이그레이션 / 백업 도구 | 사용자 데이터 export-import |
| Y18 | 어드민 대시보드 | 사용자 통계, 결제 현황 |
| Y19 | A/B 테스트 인프라 | GrowthBook 또는 Supabase Feature Flags |
| Y20 | 음성 입력 (spec §9.3 의 advanced) | "분유 120ml 줬어" 음성 → 기록 |

---

## 🔧 즉시 가능한 미세 작업

이 항목들은 작은 polish — 시간 나면 빠르게 처리.

- ▢ `pubspec.yaml` 의 `version: 1.0.0+1` → 출시 직전 `1.0.0+2` 등 빌드 번호 증가
- ▢ `flutter_launcher_icons` 아이콘 — 현재 디자인 만족 시 패스, 다른 디자인 원하면 `assets/launcher_icon.png` 교체 후 `dart run flutter_launcher_icons`
- ▢ `record_buttons_grid.dart:206` 의 `unused_element_parameter` 경고 정리
- ▢ `statistics_page.dart:487-489` 의 `unnecessary_brace_in_string_interps` 4개
- ▢ `growth_chart_page.dart:243` 의 `unnecessary_underscores` 2개
- ▢ `places_service.dart:73` 의 `use_null_aware_elements` info
- ▢ `who_lms_data.dart:1` 의 `dangling_library_doc_comments`

---

## 🎯 권장 출시 시퀀스

KR 1순위 출시까지 가장 짧은 path:

1. **Y1 (결제)** ← 지금 사용자가 선택한 영역. 상세 [billing.md](release/billing.md)
2. **Y2 (AAB + Play Console)** — Y1 과 병행 가능
3. **Y3 (스크린샷)** — Y2 의 메타데이터 채우기 위해
4. **Y4 (베타)** — 내부 → 가족 → 외부
5. (Y5, Y7) 가능하면 병행
6. **KR 정식 출시**
7. **Y5 + Y6** 완료 후 JP/영어권 단계적 확대
