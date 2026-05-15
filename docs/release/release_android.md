# Android Release 빌드 가이드

이 문서는 **release 서명된 AAB(Android App Bundle)** 를 만들어 Play Console 에 업로드하는 절차입니다.

## 1. 서명 키(keystore) 생성 — 한 번만

키 분실 시 같은 앱을 새로 등록해야 하니 **반드시 백업**.

```powershell
# 위치는 원하는 곳, 단 git 추적은 NO
cd "$env:USERPROFILE"
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -genkey -v `
  -keystore babynote-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias babynote
```

질문에 답:
- 비밀번호 (잊지 말 것)
- 이름, 조직, 시/도, 국가 코드(KR)

생성된 `babynote-release.jks` 를 **안전한 곳에 백업** (USB + 클라우드 + 비밀번호 매니저).

## 2. `android/key.properties` 작성

이 파일은 **절대 git 에 안 들어감** (`.gitignore:48` 가 `key.properties` 막음).

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=babynote
storeFile=C:/Users/sarbr/babynote-release.jks
```

## 3. `android/app/build.gradle.kts` 에 서명 설정 연결

> **현재 프로젝트는 release 서명 미설정 상태입니다.** Play 업로드 전 한 번 추가 필요.

`android/app/build.gradle.kts` 의 `android { ... }` 블록 안에 추가:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keyProps = Properties()
val keyPropsFile = rootProject.file("key.properties")
if (keyPropsFile.exists()) {
    keyProps.load(FileInputStream(keyPropsFile))
}

android {
    // ... 기존 설정 ...

    signingConfigs {
        create("release") {
            keyAlias = keyProps["keyAlias"] as String?
            keyPassword = keyProps["keyPassword"] as String?
            storeFile = keyProps["storeFile"]?.let { file(it as String) }
            storePassword = keyProps["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // 코드 축소 + 난독화 — 첫 출시는 false로 시작, 안정화 후 켜도 됨
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
```

## 4. release AAB 빌드

```powershell
# 프로젝트 루트에서
C:\Users\sarbr\flutter\bin\flutter.bat build appbundle `
  --release `
  --dart-define-from-file=run\prod.json
```

> `run/prod.json` 은 production Supabase URL/Anon Key/Sentry DSN 을 담은 별도 파일. `run/dev.example.json` 형태 그대로 production 값으로 만들고, `run/` 는 `.gitignore` 로 제외돼있음.

생성물: `build/app/outputs/bundle/release/app-release.aab`

## 5. Play Console 업로드

1. https://play.google.com/console → 앱 생성 → 패키지명 `com.kjfamily.babynote`
2. **내부 테스트** 트랙 선택 → AAB 업로드
3. 메타데이터 작성 ([app_store_metadata.md](app_store_metadata.md) 참고)
4. **Data safety** 신고 — 수집 데이터: 이메일/이름/자녀 정보/기록/이미지(이유식·증상)
5. **연령 등급** 설문 → 만 3세+ 예상
6. 테스터 이메일 등록 → 베타 링크 공유
7. 안정화 확인 후 **프로덕션** 트랙으로 단계적 출시 (1% → 5% → 20% → 100%)

## 6. APK 로 직접 배포(베타)

AAB 가 아니라 단일 APK 가 필요한 경우 (사이드로딩 베타 테스터):

```powershell
C:\Users\sarbr\flutter\bin\flutter.bat build apk `
  --release `
  --dart-define-from-file=run\prod.json
```

생성물: `build/app/outputs/flutter-apk/app-release.apk`

## 7. 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| `Could not find key.properties` | 파일 미생성 | 2단계 참고 |
| `Cannot find keystore file` | storeFile 경로 오타 | 절대경로 + 슬래시 사용 |
| `Apk Signature Scheme v2 verification failed` | keyPassword 틀림 | `keytool -list -v -keystore xxx.jks` 로 확인 |
| Play Console "AAB 거부" | minSdkVersion 너무 낮음 | `android/app/build.gradle.kts` 의 minSdkVersion 확인 (현재 29 — Play 정책 24+ OK) |
