# Google Sign-In 셋업

마지막 업데이트: 2026-05-16

## 📋 현재 코드 상태

| 항목 | 상태 |
|---|---|
| `google_sign_in: ^6.2.2` pubspec | ✅ 설치됨 |
| `AuthRepository.signInWithGoogle()` — native SDK | ✅ 구현됨 |
| `AuthRepository.signInWithGoogleViaBrowser()` — fallback | ✅ 유지 (대안) |
| `Env.googleServerClientId` 정의 | ✅ (`GOOGLE_SERVER_CLIENT_ID`) |
| `auth_page` 의 Google 버튼 | ✅ native 호출로 갱신 |
| **Google Cloud Console OAuth 2.0 Client ID 2개** | ⏳ 셋업 필요 |
| **Supabase Dashboard → Auth → Providers → Google** | ⏳ 활성화 필요 |
| **run/dev.json 에 `GOOGLE_SERVER_CLIENT_ID` 주입** | ⏳ 필요 |
| **Android `applicationId` SHA-1 등록** | ⏳ 필요 |

코드는 다 있고 **외부 콘솔 4가지 셋업** 만 남음.

---

## 1️⃣ Android SHA-1 fingerprint 추출

OAuth Client ID 생성 시 SHA-1 입력이 필요. **debug + release 두 개** 추출.

### Debug SHA-1
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android -keypass android | Select-String "SHA1"
```

### Release SHA-1 (출시용 keystore)
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v `
  -keystore "$env:USERPROFILE\babynote-release.jks" `
  -alias babynote | Select-String "SHA1"
```
(keystore 비밀번호 입력 프롬프트)

두 SHA-1 값 둘 다 메모해두기 (Google Cloud Console 에 두 OAuth Client 등록할 때 각각 사용).

---

## 2️⃣ Google Cloud Console — OAuth Client 2개 생성

### a. GCP 프로젝트 선택 / 생성
1. https://console.cloud.google.com
2. 상단 프로젝트 선택기 → 기존 프로젝트 선택
   - Play Console 인증 때 만들었던 `BabyNote-billing` 재사용 가능
   - 또는 별도 `BabyNote-auth` 새로 만들기
3. 좌측 메뉴 → **APIs & Services → Credentials**

### b. **Android OAuth Client ID** (1번째)
1. **+ Create Credentials → OAuth client ID**
2. Application type: **Android**
3. Name: `BabyNote Android (debug)`
4. Package name: `com.kjfamily.babynote`
5. SHA-1: 위 §1 의 **debug SHA-1** 입력
6. Create — Client ID 발급 (이건 따로 메모 불필요, Android 가 자동 사용)

같은 방식으로 **두 번째 Android Client** (release SHA-1) 도 만들기:
- Name: `BabyNote Android (release)`
- 같은 패키지명, release SHA-1

### c. **Web Application OAuth Client ID** (가장 중요)
1. **+ Create Credentials → OAuth client ID**
2. Application type: **Web application**
3. Name: `BabyNote Web (Supabase)`
4. Authorized JavaScript origins: (비워두기)
5. Authorized redirect URIs: **Supabase Auth callback URL** 입력 — Supabase Dashboard 에서 확인 후 입력 (아래 §3 참고)
6. Create — **Client ID + Client Secret** 발급. **이게 가장 중요한 값**.

> **Web Client ID** 가 `signInWithIdToken` 의 `audience` 값. 클라이언트와 Supabase 양쪽이 똑같이 알아야 토큰 검증 통과.

---

## 3️⃣ Supabase Dashboard — Google Provider 활성화

1. https://supabase.com/dashboard/project/kbaxmeiwnvedzohdqwkg/auth/providers
2. **Google** 항목 클릭 → 펼침
3. **Enabled** 토글 ON
4. 입력:
   - **Client ID** (Web): 위 §2.c 에서 받은 Web Client ID
   - **Client Secret** (Web): 같이 받은 Secret
5. **Authorized Client IDs (Mobile)** 필드에 다음 모두 추가:
   - Web Client ID (위와 동일)
   - Android debug Client ID (§2.b)
   - Android release Client ID (§2.b)
6. **Save**

페이지 상단의 **Callback URL** 복사 → §2.c 의 Authorized redirect URIs 에 붙여넣기 + Save (이미 했으면 OK).

---

## 4️⃣ `run/dev.json` 에 Web Client ID 주입

```json
{
  "SUPABASE_URL": "https://kbaxmeiwnvedzohdqwkg.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_...",
  "SENTRY_DSN": "https://...",
  "FLAVOR": "dev",
  "REVENUECAT_ANDROID_KEY": "goog_...",
  "REVENUECAT_IOS_KEY": "",
  "GOOGLE_SERVER_CLIENT_ID": "여기에_Web_Client_ID_붙여넣기.apps.googleusercontent.com"
}
```

(production 도 `run/prod.json` 만들 때 같은 값 입력)

GitHub Actions 시크릿에도 추가:
- `GOOGLE_SERVER_CLIENT_ID` Secret 등록 → `.github/workflows/build-android.yml` 에 `--dart-define=GOOGLE_SERVER_CLIENT_ID=$GOOGLE_SERVER_CLIENT_ID` 추가 (다음 빌드 워크플로 업데이트 시점에).

---

## 5️⃣ Android 추가 설정 — 일반적으로 자동

`google_sign_in` 패키지가 대부분 자동 셋업하지만, 일부 환경에선 추가 작업 필요:

### a. Google Services 플러그인 — **불필요** (Firebase 안 씀)
Firebase 사용하지 않으므로 `google-services.json` 도 불필요. `signInWithIdToken` 만 쓸 거면 OAuth Client ID 만으로 충분.

### b. ProGuard rules — 출시 직전 minify 켤 때
`android/app/proguard-rules.pro` (현재는 minify OFF 라 무시 OK):
```
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
```

---

## 6️⃣ 검증

```powershell
cd "C:\Users\sarbr\StudioProjects\BabyNote"
C:\Users\sarbr\flutter\bin\flutter.bat run -d <device-id> --dart-define-from-file=run\dev.json
```

폰에서:
1. 로그아웃 (이미 로그인된 상태면)
2. 로그인 화면 → **Google** 버튼 탭
3. **Google 계정 선택 다이얼로그** (브라우저 X, native 위젯) 등장
4. 계정 선택 → 자동으로 홈 화면

성공 시 Supabase Dashboard → Auth → Users 에 새 행 (provider=google).

---

## 7️⃣ 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| `Google Sign-In 이 설정되지 않았어요` 에러 | `GOOGLE_SERVER_CLIENT_ID` 미설정 | §4 의 run/dev.json |
| `PlatformException(sign_in_failed, ... 10:)` | SHA-1 미등록 또는 패키지명 불일치 | §1 + §2.b 다시 확인 |
| `signInWithIdToken` 가 400 응답 | Web Client ID 가 Supabase Authorized Client IDs 에 없음 | §3 의 5번 |
| 다이얼로그 떴는데 계정 선택 후 무한 로딩 | Supabase 가 Web Client ID 검증 실패 | §3 Client Secret 도 등록했는지 확인 |
| 항상 같은 계정으로만 로그인 | google_sign_in 의 cache | `googleSignIn.signOut()` 호출 후 재시도 |

---

## 8️⃣ 출시 직전 체크리스트

- [ ] SHA-1 fingerprint **debug + release** 두 개 추출
- [ ] Google Cloud Console — Android OAuth Client 2개 생성 (debug + release)
- [ ] Google Cloud Console — Web OAuth Client 1개 생성
- [ ] Supabase Dashboard — Google provider enable + 3개 Client ID 등록
- [ ] `run/dev.json` + `run/prod.json` 에 `GOOGLE_SERVER_CLIENT_ID` 주입
- [ ] GitHub Secret `GOOGLE_SERVER_CLIENT_ID` 등록 + build-android.yml 갱신
- [ ] 폰 실기에서 Google 로그인 동작 확인
- [ ] Supabase Auth → Users 테이블에 google provider 가입자 정상 표시

---

## 📌 다음 액션 (사용자 손)

1. **SHA-1 추출** — debug + release
2. Google Cloud Console — OAuth Client 3개 생성
3. Supabase Dashboard — Google provider 활성화
4. Web Client ID 알려주시면 `run/dev.json` 에 추가 + 빌드 검증
