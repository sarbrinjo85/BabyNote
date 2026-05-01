# `run/` — 빌드 시 환경 변수 주입 디렉터리

Flutter는 빌드 타임에 `--dart-define=KEY=VALUE` 형태로 상수를 코드에 박아 넣어. 그걸 일일이 손으로 치는 대신 JSON으로 모아서 `--dart-define-from-file=run/dev.json` 한 줄로 주입할 수 있어.

## 파일

| 파일 | 용도 | git에 commit? |
|---|---|---|
| `dev.example.json` | 키 자리 비워둔 템플릿 | ✅ commit (참고용) |
| `dev.json` | 개발용 실제 키 | ❌ gitignored |
| `prod.json` | 배포용 실제 키 | ❌ gitignored |

`.gitignore`에 `/run/*.json`이 있어서 실제 값이 든 json 파일은 자동 제외돼. `.example.json`은 예외로 추적됨.

## 사용

```bash
# 개발 (디버그 빌드, hot reload)
flutter run --dart-define-from-file=run/dev.json

# 릴리스 빌드 (배포용 APK)
flutter build apk --release --dart-define-from-file=run/prod.json
```

## 새 환경 만들기

1. `cp run/dev.example.json run/dev.json`
2. Supabase Studio → Settings → API → Project URL & publishable key 복사 → 붙여넣기
3. (선택) Sentry DSN 발급받았으면 채우기, 아니면 빈 문자열로 두기

`lib/core/config/env.dart`에서 `String.fromEnvironment(...)`로 읽고, 빈 문자열이면 Supabase init 자체를 건너뜀.
