# 출시 준비 (Release Prep)

이 폴더는 BabyNote 의 KR → JP → 영어권 순차 출시에 필요한 모든 비코드 산출물을 모은 곳입니다.

## 문서 목록

| 파일 | 용도 |
|---|---|
| [release_android.md](release_android.md) | Android 서명 키 생성 + Play Store 빌드 명령 |
| [release_ios.md](release_ios.md) | iOS App Store Connect + provisioning profile |
| [app_store_metadata.md](app_store_metadata.md) | 권역별(한/일/영) 스토어 등록 텍스트 — 이름, 짧은/긴 설명, 키워드, 카테고리 |
| [screenshot_spec.md](screenshot_spec.md) | 권역별 필수 스크린샷 사이즈 + 화면 리스트 |
| [github_pages_setup.md](github_pages_setup.md) | privacy_policy / terms_of_service 를 공개 URL 로 호스팅 |

## 권역별 출시 사전 체크리스트

### 🇰🇷 KR (한국 — 1순위)

- [ ] **Android signing key** 생성 ([release_android.md](release_android.md))
- [ ] **Google Play Console 가입** + 본인 인증 + 결제 수단 등록 ($25 일회 등록비)
- [ ] **앱스토어 메타** 한국어 작성 ([app_store_metadata.md](app_store_metadata.md))
- [ ] **스크린샷** Android 폰 (1080×1920 또는 1440×2560) 최소 2장, 권장 8장
- [ ] **privacy_policy.md / terms_of_service.md 공개 URL** ([github_pages_setup.md](github_pages_setup.md))
- [ ] **카카오/네이버 OAuth** 등록 (F 작업, 후속)
- [ ] **데이터 안전성 신고** (Play Console "Data safety") — 수집 데이터 + 공유 여부 명시
- [ ] **내부 테스트 트랙** 업로드 → 베타 → 프로덕션 단계적 출시
- [ ] **연령 등급**: 만 3세+ (Pegi 3 / ESRB Everyone)

### 🇯🇵 JP (일본 — 2순위)

- [ ] 위 KR 모든 항목의 **일본어 버전**
- [ ] **LINE Login** OAuth 등록 (F 작업)
- [ ] **資金決済法** 결제 명시 (Apple/Google 결제 사용 시 자동 충족)
- [ ] **백신 시드 JP** 적용 확인 (`08_seed_vaccine_jp.sql`)

### 🇺🇸 / 🇬🇧 / 🇨🇦 / 🇦🇺 (영어권 — 3순위)

- [ ] 위 항목의 **영어 버전**
- [ ] **COPPA 준수** — 만 13세 미만 아동 직접 회원가입 X (이미 충족)
- [ ] **CCPA/CPRA** 옵트아웃 페이지 (캘리포니아) — 데이터 판매 안 함 명시
- [ ] **백신 시드 US** 적용 확인 (`09_seed_vaccine_us.sql`)
- [ ] **Apple Sign-In** 활성화 (iOS는 Apple 로그인 필수, F 작업)

## 버전/빌드 넘버 정책

`pubspec.yaml` 의 `version: X.Y.Z+N`:
- **X.Y.Z** — Semantic Version (사용자에게 보이는 버전)
  - X: 호환성 깨지는 변경 (DB 스키마 대규모 변경 등)
  - Y: 기능 추가 (새 기록 종류, 새 화면)
  - Z: 버그 픽스
- **N** — Build number (각 스토어 업로드마다 +1, 절대 감소 불가)

예시:
- 출시 시점: `1.0.0+1`
- KR 베타 1차: `1.0.1+2` (작은 픽스)
- JP 출시: `1.1.0+10` (l10n 보강)

## 출시 일정 권장

스펙 §9.1 의 24주 로드맵 마지막 단계 (Phase 5: 21–24주 i18n + 출시 준비) 가 이 문서들의 작성 + 베타 + 정식 출시 구간입니다.
