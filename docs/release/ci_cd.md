# CI/CD — GitHub Actions

마지막 업데이트: 2026-05-16

## 📋 워크플로 개요

| 파일 | 트리거 | 실행 내용 | 시크릿 필요 |
|---|---|---|---|
| `.github/workflows/analyze.yml` | PR / push to main | `flutter pub get` → `flutter gen-l10n` → `flutter analyze` → `flutter test` | 없음 |
| `.github/workflows/build-android.yml` | push to main / v* 태그 / 수동 | release AAB + APK 빌드 → artifact 업로드 | **필수** (아래) |

`analyze` 는 시크릿 없이 즉시 동작. `build-android` 는 GitHub Secrets 셋업 후 동작.

---

## 🔑 GitHub Secrets 셋업

저장소 → **Settings → Secrets and variables → Actions → New repository secret**

### 1. ANDROID_KEYSTORE_BASE64

로컬 keystore (`C:\Users\sarbr\babynote-release.jks`) 를 base64 인코딩한 문자열.

PowerShell:
```powershell
$bytes = [System.IO.File]::ReadAllBytes("$env:USERPROFILE\babynote-release.jks")
$b64 = [Convert]::ToBase64String($bytes)
# 클립보드로 복사
Set-Clipboard -Value $b64
Write-Output "Length: $($b64.Length) chars — 이미 클립보드에 복사됨"
```

→ GitHub Secret `ANDROID_KEYSTORE_BASE64` 에 Ctrl+V 로 붙여넣기.

### 2. KEYSTORE_PASSWORD

keystore 생성 시 입력한 비밀번호 (`key.properties` 의 `storePassword`).

### 3. KEY_PASSWORD

key alias 비밀번호 (`key.properties` 의 `keyPassword`). keystore 와 같으면 동일.

### 4. KEY_ALIAS

`babynote` (또는 keystore 생성 시 지정한 alias).

### 5. SUPABASE_URL

`run/dev.json` 의 `SUPABASE_URL` 값. (production 은 별도 운영 시 prod 값).

### 6. SUPABASE_ANON_KEY

`sb_publishable_...` 형태.

### 7. SENTRY_DSN

(선택) Sentry 프로젝트 DSN. 비워두면 Sentry 비활성으로 빌드됨.

### 8. REVENUECAT_ANDROID_KEY

`goog_...` 형태.

---

## ✅ 시크릿 등록 확인

저장소 **Settings → Secrets and variables → Actions** 에서 다음 8개가 보여야 정상 (값은 안 보이고 이름만):
- `ANDROID_KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SENTRY_DSN` (선택)
- `REVENUECAT_ANDROID_KEY`

---

## 🚀 첫 빌드 트리거

### 방법 A: 수동 트리거

저장소 → **Actions → build-android → Run workflow** 버튼 → branch `main` 선택 → Run.

### 방법 B: push to main

main 에 commit + push 하면 자동 트리거됨. (지금 워크플로 추가 commit 자체가 첫 빌드 트리거)

### 방법 C: 태그 푸시 (정식 출시 패턴)

```powershell
git tag v1.0.0
git push origin v1.0.0
```

→ 태그가 `v*` 패턴이면 자동 빌드.

---

## 📥 빌드 결과물 다운로드

1. **Actions → build-android → 최신 실행** 클릭
2. 페이지 맨 아래 **Artifacts** 영역:
   - `app-release-aab` (Play Console 업로드용)
   - `app-release-apk` (직접 sideload 베타용)
3. 클릭하면 zip 다운로드 → 내부에 .aab / .apk

---

## ⏱ 빌드 시간

| 단계 | 시간 |
|---|---|
| analyze (cold cache) | ~3분 |
| analyze (warm cache) | ~1분 |
| build-android (cold) | ~15분 |
| build-android (warm) | ~7분 |

GitHub Actions 무료 한도: public 저장소 무제한, private 월 2,000분. BabyNote 는 public 이므로 부담 없음.

---

## 🔮 향후 확장

- **fastlane + Google Play API** 로 AAB 자동 업로드 (Play Console 의 Internal Testing 트랙까지 자동 배포)
- **macOS runner** 추가해 iOS 빌드까지 (macOS 시간 제한 주의 — 분당 비용 10배)
- **체크리스트 PR comment** — analyze 실패 시 PR 에 자동 댓글
- **Slack/Discord 알림** — 빌드 성공/실패 메시지

---

## 🐛 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| `Could not find key.properties` | KEYSTORE_PASSWORD 등 시크릿 누락 | 위 8개 시크릿 모두 등록 확인 |
| `Cannot find keystore file` | ANDROID_KEYSTORE_BASE64 디코딩 실패 | base64 인코딩 시 공백/줄바꿈 섞임 — `Set-Clipboard` 재실행 |
| `Apk Signature Scheme v2 verification failed` | KEY_PASSWORD 틀림 | 로컬에서 `keytool -list -v -keystore ...jks` 로 확인 |
| analyze 실패 (4xx 에러) | Flutter 버전 미스매치 | `flutter-version: '3.41.9'` 를 본인 로컬 버전과 일치시키기 |
| Sentry release 매칭 안 됨 | `--release` 인자 누락 | build-android.yml 의 dart-define 에 추가 (현재는 Env.release 고정값) |

---

## 📌 첫 실행 전 체크리스트

- [ ] 8개 GitHub Secret 등록 완료
- [ ] keystore 백업 USB / 클라우드 보관 확인
- [ ] `key.properties` 비밀번호 메모/비밀번호 매니저 보관
- [ ] **Actions** 탭에서 `analyze` 가 자동 실행되어 ✓ 표시되는지 (분석 OK)
- [ ] **Run workflow** 로 `build-android` 수동 트리거 → artifact 다운로드 가능
