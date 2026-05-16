# 남은 업무 (Remaining Tasks)

마지막 업데이트: 2026-05-16

[PROGRESS.md](PROGRESS.md) 와 짝. 작업 시작 시 여기서 ▢ → 🟡 → ✅ 로 갱신 후
완료 항목은 PROGRESS.md 로 옮겨 보관.

각 항목은 ID(예: `Y1`), 상태, 예상 시간, 의존성 표기.

---

## 🔴 1순위 — 출시 직전 필수

### Y1. 결제 시스템 콘솔 셋업 + 검증
▢ | ~6h | 사용자 + 코드 작업 양쪽 | 상세: [release/billing.md](release/billing.md)

코드는 이미 있음 (`lib/features/billing/`, `purchases_flutter`,
`subscriptions` 테이블). 콘솔 셋업 + 환경 키 + 검증만 남음.

- ▢ RevenueCat 계정 생성 + 프로젝트 만들기
- ▢ Android app 추가 + Google Play 연동
- ▢ Entitlement `multi_child` 정의
- ▢ Products `babynote_extra_child_yearly` / `babynote_family_yearly` 생성
- ▢ Google Play Console — 인앱상품 등록 (각각 ₩19,900/년 / ₩49,900/년)
- ▢ `run/dev.json` + `run/prod.json` 에 `REVENUECAT_ANDROID_KEY` 추가
- ▢ Webhook 셋업 (RevenueCat → Supabase Edge Function 또는 직접 callback)
- ▢ 테스트 결제 (Play Console 테스터 추가 → 라이센스 테스트)
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
▢ | ~1h

- ▢ records_page 의 각 row 에 "동기화 대기 중" 배지 (큐에 있는 id 인지 체크)
- ▢ `writeQueue.listAll()` 의 rowId 들과 화면의 id 매칭
- ▢ 디자인: 옅은 회색 + ⏳ 아이콘

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
▢ | ~2h

- ▢ `google_sign_in: ^6.2.2` pubspec 활성화
- ▢ Firebase Console 또는 Google Cloud Console 에서 OAuth 2.0 클라이언트 ID
- ▢ Supabase Dashboard → Auth → Providers → Google enable
- ▢ AuthPage 에 "Google 로 계속" 버튼
- ▢ Android `android/app/google-services.json` 추가 (gitignore)
- ▢ Android `applicationId` SHA-1 fingerprint 등록

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
▢ | ~2h

- ▢ 홈에서 "최근 산책 30분", "최근 발진 어제" 같은 last-record 표시
- ▢ 기존 RecordButtonsGrid 의 표시 로직을 일반화한 위젯
- ▢ tiles 6개 (산책/목욕/영양제/간식/기침/구토/발진/상처) — 8개라 4col×2row

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
