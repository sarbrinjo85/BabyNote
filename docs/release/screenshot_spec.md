# 스크린샷 사양 (Screenshot Spec)

Play Console + App Store Connect 양쪽에 업로드할 권역별 스크린샷 설계.

## 1. 권역별 필수 사이즈

### Android (Play Console)

| 항목 | 사이즈 | 필수 | 비고 |
|---|---|---|---|
| Phone screenshot | 9:16 비율 (예: 1080×1920) | 최소 2장, 최대 8장 | 가로 1080~3840px |
| 7-inch tablet | 권장 1200×1920 | 선택 | 태블릿 사용자 적음 |
| 10-inch tablet | 권장 1920×1200 | 선택 | 동일 |
| Featured graphic | 1024×500 | 필수 (등록 시점) | Play 상단 배너 |

### iOS (App Store Connect)

| 항목 | 사이즈 | 필수 |
|---|---|---|
| iPhone 6.7" (iPhone 14/15/16 Pro Max) | 1290×2796 | 필수 (가장 큰 폰) |
| iPhone 6.5" (iPhone 11 Pro Max 등) | 1242×2688 | 선택, 호환성 |
| iPad Pro 12.9" 3세대+ | 2048×2732 | 필수 (앱이 iPad 호환이면) |

> iOS 는 큰 사이즈만 올리면 작은 사이즈 자동 매핑. **6.7" 1세트** 만 있어도 충분.

## 2. 화면 리스트 (5~6장 권장)

기획서 §7.3 의 13개 화면 중 마케팅 가치 높은 것:

| 순서 | 화면 | 강조 메시지 (자막) |
|---|---|---|
| 1 | 홈 (자녀 카드 + 4종 기록 버튼 + 오늘 요약) | "한 손으로 1탭 기록" |
| 2 | 분유 재고 + 소진 예측 카드 | "3일 후 떨어져요" |
| 3 | 부부 공유 — 가족 토스트 ("🚶 가족이 산책 기록을 남겼어요") | "부부 실시간 공유" |
| 4 | 예방접종 일정 (다가오는 백신 카드) | "예방접종 자동 알림" |
| 5 | 통계 (수유·수면·기저귀 7일 차트 + 루틴/건강 카드) | "일주일을 한눈에" |
| 6 (선택) | 건강 기록 — 발진 사진 + severity | "사진까지 함께 기록" |

## 3. 자막 (Caption) — 권역별

[app_store_metadata.md](app_store_metadata.md) §스크린샷 자막 섹션 참고. 위 화면에 매칭되는 한/일/영 카피.

## 4. 디자인 가이드

- **상단 자막 띠**: 24~32pt 한국어 굵게, 배경 코랄핑크 (#FFB5A7) + 흰 글자
- **하단**: 실제 디바이스 프레임 안에 앱 스크린샷
- **배경**: 옅은 코랄핑크 그라데이션 또는 솔리드 #FFF5F0 (스펙의 scaffoldLight 색)
- **로고/앱 아이콘**: 좌상단 작은 표시 권장

## 5. 자동 캡처 방법

### Android — `flutter screenshot`

```powershell
# 디바이스 연결 + 앱 실행 상태에서
C:\Users\sarbr\flutter\bin\flutter.bat screenshot `
  --type=device `
  --out=docs\release\screenshots\android\home.png
```

또는 ADB 직접:
```powershell
adb exec-out screencap -p > home.png
```

### iOS — Xcode Simulator

```bash
xcrun simctl io booted screenshot home.png
```

### 자동화 (선택, 큰 작업)

Flutter integration_test + golden screenshots 로 CI 에서 자동 캡처도 가능. 출시 후반에 검토.

## 6. 캡처 시 체크리스트

캡처 전 디바이스 상태:
- [ ] **상태바 깨끗**: 통신사 / 알림 / 배터리 100% / 09:41 (Apple 관례) — Android 데모 모드 사용
- [ ] **데모 데이터 채워둠**: 자녀 1~2명 + 일주일치 기록 (수유 30회+, 수면 14회+, 기저귀 50회+)
- [ ] **분유 재고 카드** 가 "3일 후 떨어짐" 상태로 시연되게 설정
- [ ] **다가오는 백신** 1건 이상
- [ ] **다크모드 별도**: Play 는 라이트만 OK, App Store 는 다크 한 세트 추가 권장
- [ ] **권역별 l10n**: 시스템 언어 KR/JA/EN 으로 각각 캡처

## 7. Featured graphic (Play 상단 배너)

1024×500 — 마케팅 톤:

```
[로고]   베이비노트
        새벽에도 한 손으로,
        분유 떨어지기 3일 전에 알려드려요
                                  [폰 미리보기 일러스트]
```
