# iOS Release 빌드 가이드

⚠️ iOS 빌드는 **macOS 머신** 이 필수입니다. 본 프로젝트는 현재 Windows 머신에서 개발 중이라, iOS 빌드 시점에 다음 중 하나가 필요합니다:

1. **Mac mini 또는 MacBook** 직접 운영
2. **Codemagic / Bitrise 등 Mac CI 서비스** 임차
3. **Mac in the Cloud** 같은 원격 Mac

KR 출시 (Android 우선) 가 1차 목표라면 iOS 는 후순위로 미뤄도 됩니다.

## 1. 사전 준비

- Apple Developer Program 등록 ($99/년)
- Mac 머신 + Xcode (최신 stable, 현재 16+)
- App Store Connect 접근 권한

## 2. Bundle ID 등록

1. https://developer.apple.com/account/resources/identifiers/list
2. **+** → App IDs → App
3. Bundle ID: `com.kjfamily.babynote` (Android 와 동일하게)
4. Capabilities: Push Notifications, Sign in with Apple, Associated Domains (선택)

## 3. App Store Connect 앱 생성

1. https://appstoreconnect.apple.com
2. **My Apps → +** → New App
3. Bundle ID 선택
4. **Primary Language**: Korean (또는 English)
5. **SKU**: `babynote_ios_001`

## 4. 인증서 + Provisioning Profile (자동 권장)

Xcode 의 **Automatic Signing** 사용:
1. Xcode → Open `ios/Runner.xcworkspace`
2. Runner target → Signing & Capabilities
3. ✅ Automatically manage signing
4. Team 선택 (Apple Developer 계정의 팀)

## 5. 환경 변수 — `--dart-define-from-file`

iOS 도 Android 와 동일하게 `run/prod.json` 사용:

```bash
flutter build ios --release \
  --dart-define-from-file=run/prod.json
```

## 6. Archive + Upload

### Xcode 직접
1. Xcode 좌측 상단 디바이스 → **Any iOS Device (arm64)**
2. **Product → Archive**
3. Archive 창에서 **Distribute App** → App Store Connect → Upload
4. 대기 후 App Store Connect 에서 빌드 보임

### Flutter CLI (대안)
```bash
flutter build ipa --release \
  --dart-define-from-file=run/prod.json

# 생성된 .ipa 를 Transporter.app 으로 업로드
# build/ios/ipa/Runner.ipa
```

## 7. TestFlight (베타)

1. App Store Connect → TestFlight 탭
2. 업로드된 빌드 클릭 → "Provide Export Compliance Info" → 일반적으로 "No" (HTTPS만 사용)
3. **Internal Testing** 그룹에 테스터 이메일 추가 (즉시 사용 가능)
4. **External Testing** 은 Apple 심사 1-2일 (최대 90일 베타)

## 8. 정식 출시

1. **App Information** 작성:
   - Name, Subtitle, Privacy Policy URL ([github_pages_setup.md](github_pages_setup.md))
   - Category: Lifestyle (Primary), Medical (Secondary)
   - Content Rights 체크
2. **Pricing and Availability**:
   - Price Tier 0 (Free) — 인앱결제는 별도
   - Available in all territories 또는 KR/JP/US/UK/CA/AU 선택
3. **App Privacy** (data safety 와 동일):
   - "Data Collected" → Contact Info / Health & Fitness / User Content / Identifiers
   - "Linked to You" → 모두 Yes (RLS 로 격리되지만 식별자 연결됨)
   - "Used for Tracking" → No (광고 추적 없음)
4. **In-App Purchases**:
   - 자녀 1명 추가: $14.99/year — Auto-Renewable Subscription
   - 패밀리 플랜: $39.99/year — Auto-Renewable Subscription
5. **Screenshots**: [screenshot_spec.md](screenshot_spec.md) 의 iOS 사이즈
6. **App Review Info** + **Version Release**:
   - Manually release / Automatic / Phased Release 중 선택
   - 첫 출시는 Phased Release (7일에 걸쳐 점진 노출) 권장

## 9. Apple 정책 주의

| 정책 | 대응 |
|---|---|
| Sign in with Apple 의무 | 다른 소셜 로그인 사용 시 필수 추가. F 작업에서 포함 |
| In-App Purchase | RevenueCat 사용 (이미 `purchases_flutter` 의존성 있음) |
| 결제 외부 링크 금지 | 어필리에이트 링크는 OK (디지털 콘텐츠 아닌 실물 구매) |
| 아동 카테고리 | 만 13세 미만 직접 가입 X — 자녀 입력은 부모/보호자가. 정책 충족 |
| 데이터 삭제 1탭 | App Review Guidelines 5.1.1(v). 설정 → 계정 → 회원 탈퇴 필수 |

## 10. macOS 환경 갖춰지면 추가 작업

- `ios/Runner/Info.plist` 에 다음 키 확인/추가:
  - `NSCameraUsageDescription` (이유식 / 증상 사진)
  - `NSPhotoLibraryUsageDescription` (갤러리 첨부)
- `ios/Runner/Runner.entitlements` 에 Push, Sign in with Apple 권한
- App Icon 1024×1024 — `assets/launcher_icon.png` 가 자동 생성 (`flutter_launcher_icons`)

지금은 Windows 환경에서 iOS 작업 보류 가능. Android 출시 (1순위) 안정화 후 iOS 진행 권장.
