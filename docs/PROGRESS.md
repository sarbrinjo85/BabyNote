# 진척 현황 (Progress)

마지막 업데이트: 2026-05-16

이 문서는 BabyNote 의 누적 진척을 카테고리별로 정리한다.
신규 작업 시작 전 [TODO.md](TODO.md) 를 확인 → 작업 완료 후 여기 옮겨 적기.

---

## 📊 Phase 별 요약 (spec_extracted.txt §9.1 의 24주 로드맵 기준)

| Phase | 주차 | 상태 | 비고 |
|---|---|---|---|
| 1. 기반 구축 | 1–4 | ✅ 완료 | Auth, 온보딩, 테마, 라우터, l10n |
| 2. 핵심 기록 | 5–10 | ✅ 완료 | 수유/수면/기저귀/성장 + 통계 |
| 3. 차별화 기능 | 11–16 | ✅ 완료 | 분유·기저귀 재고, 단골 병원, 예방접종 |
| 4. 협업 + 결제 | 17–20 | 🟡 코드만 | 가족 공유 ✅, RevenueCat 인프라 ✅, 콘솔 셋업 ⏳ |
| 5. 다국어 + 출시 | 21–24 | 🟡 진행 중 | 한·일·영 ARB ✅, EN/JA 법무문서 ⏳, 베타 ⏳ |

---

## 🚀 2026-05-16 작업 (오늘)

신규 기록 8종 + 통합 + 출시 준비 인프라 대거 완료. 9 커밋 푸시.

### 신규 기록 종류 추가
- **A. 루틴 4종** — 산책 🚶 / 목욕 🛁 / 영양제 💊 / 간식 🍪
  - `supabase/migrations/16_routines.sql` (테이블 + RLS + 인덱스)
  - `lib/features/routine/` (model + repo + providers + register page)
  - 홈 "루틴" 섹션 + 라우트 + l10n 19개 키
- **B. 증상 4종** — 기침 😷 / 구토 🤢 / 발진 🌶️ / 상처 🩹
  - `supabase/migrations/17_symptoms.sql` (테이블 + RLS + Storage 정책)
  - `lib/features/symptom/` (사진 업로드 포함)
  - 홈 "건강" 섹션 + l10n 23개 키

### 신규 기록을 앱 전체에 통합 (C)
- 가족 실시간 동기화 (`realtime_sync.dart`) — routines/symptoms 테이블 구독
- 전체 기록 페이지 (`records_page.dart`) — 6종 시간순 타임라인
- CSV 내보내기 (`export_service.dart`) — 6종 모두 포함
- 통계 stats providers — kind 별 카운트
- 가족 토스트 kind 별 메시지 (L) — "🚶 가족이 산책 기록을 남겼어요"

### 통계 화면 확장 (H)
- 통계 페이지에 "루틴 (지난 7일)" + "건강 (지난 7일)" 카드 추가
- severe 증상 1건 이상 시 빨간 강조 + "의사 상담 권장"

### 다국가 출시 데이터 (I)
- `08_seed_vaccine_jp.sql` — 일본 후생노동성 정기접종 31건
- `09_seed_vaccine_us.sql` — US CDC schedule 36건
- DB 적용 완료 (KR 36, JP 35, US 36)

### 출시 준비 문서 (J)
`docs/release/` 폴더:
- `README.md` — 권역별 출시 사전 체크리스트
- `release_android.md` — keystore 생성 + AAB 빌드
- `release_ios.md` — App Store Connect (macOS 필요)
- `app_store_metadata.md` — 한·일·영 메타 1차 초안
- `github_pages_setup.md` — 법무문서 호스팅 가이드
- `screenshot_spec.md` — Android/iOS 사이즈 + 화면 리스트

### 오프라인 쓰기 큐 (E-pragmatic + M + P)
**스펙 §8.3 의 Brick 전면 도입은 별도 작업으로 보류**, 실용판으로 구현.
- `lib/core/sync/` — WriteQueue (sqflite) + SyncWorker + connectivity + sync_indicator + helper
- 11개 리포지토리에 큐잉 통합 (routine/feeding/sleep/diaper/growth/symptom + child/inventory×2/hospital/vaccination)
- 모든 모델의 `toInsertMap` 이 `id != 'pending'` 시 id 포함 → 클라이언트 측 UUID 발급
- `OfflineWrites.execute()` 가 connectivity 우선 체크 → 오프라인이면 즉시 큐잉 (HTTP 타임아웃 회피)
- 홈 AppBar 에 ☁️🚫 sync indicator (큐 비면 0폭, 탭하면 "지금 다시 시도" 시트)

### UX 픽스 다수
- **D**. 코치마크 — 자녀 0명일 때 표시 보류
- **L**. 가족 토스트 kind 별 라벨
- 토스트 유지 시간 전체 **1초로 단축**
- **FAB 토스트 회귀 3건**:
  - connectivity 우선 체크 (M 도입으로 인한 30~60s 지연 회피)
  - `clearSnackBars` 사용 (큐 누적 방지)
  - `Future.delayed` backup dismiss (Material 3 + Action 조합의 일부 디바이스 timer 미발동 회피)

### GitHub Pages 활성화
- 저장소 public 전환 → Pages enable
- `docs/index.md` + `docs/_config.yml` (jekyll-theme-cayman)
- URL 운용 중:
  - https://sarbrinjo85.github.io/BabyNote/
  - https://sarbrinjo85.github.io/BabyNote/privacy_policy.html
  - https://sarbrinjo85.github.io/BabyNote/terms_of_service.html

### Android Release 빌드 가능
- `android/key.properties.example` 템플릿 + `.gitignore` 패턴
- `android/app/build.gradle.kts` 서명 wire-up (Kotlin 2.x DSL `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }`)
- 사용자가 `babynote-release.jks` keystore 생성 완료
- `flutter build apk --release` 성공 ✅

---

## 📜 이전 작업 (커밋 히스토리 요약)

`git log --oneline` 발췌:

| 커밋 | 작업 |
|---|---|
| `ac2ef7e` | build.gradle.kts Kotlin 2.x DSL + Properties API 픽스 |
| `7fc373b` | Android release 서명 설정 wire-up |
| `6ff5c50` | docs/ Pages 인덱스 + Jekyll 설정 |
| `c163cb8` | 큐 통합 5개 repo 추가 (M-extend) |
| `cb97691` | FAB 토스트 강제 dismiss (Future.delayed backup) |
| `23fe58c` | FAB 토스트 누적 픽스 (clearSnackBars) |
| `b34b7d0` | FAB 토스트 회귀 픽스 (connectivity 우선) |
| `69083c9` | 홈 AppBar sync indicator |
| `fb19245` | 오프라인 쓰기 큐 — 6개 리포지토리 통합 |
| `940040d` | 오프라인 쓰기 큐 + 자동 sync worker |
| `4bcacef` | 새 기록 8종 + 통합 + 통계 카드 + 토스트 1초 + 코치마크 |
| `6c4372e` | 출시 준비 문서 (docs/release/) |
| `eef9ff4` | 일본·미국 표준 예방접종 시드 |
| `344e57b` | 인트로 — 5초 → 3초 |
| `1affbd5` | 온보딩 코치마크 — addChild Key Container 위치 |
| `83993fe` | 설정 Sentry 테스트 에러 전송 버튼 + 안내 제거 |
| `59c9efe` | 문의 이메일 통일 + 설정 → 문의하기 메뉴 |
| `bd19d14` | 개인정보처리방침 + 이용약관 페이지 |
| `425277d` | 가족 공유 마무리 — role/safety/share/avatar/activity toast |
| `d3b1589` | RevenueCat 인앱 결제 + 멀티 자녀 페이월 게이트 |

(이전 작업은 24주 로드맵 Phase 1~3 의 핵심 기록 / 차별화 기능 / 디자인 톤 다듬기)
