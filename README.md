# BabyNote

Global baby-care recording app for parents of 0–24 month infants.
**Markets:** Korea → Japan → English-speaking (US/UK/CA/AU).
**Stack:** Flutter + Supabase. **Offline-first**, **ad-free**, couples-shared.

The full product spec lives in [docs/spec_extracted.txt](docs/spec_extracted.txt).

## Three differentiators

1. **Auto formula/diaper depletion alerts** — daily-consumption math from feed/diaper logs → push "running out in 3 days" → one-click affiliate reorder.
2. **Family hospital + auto vaccination scheduling** — country-specific vaccine schedules (KR 질병관리청 / JP 후생노동성 / US CDC / UK NHS / CA / AU NIP) with one-tap call & directions.
3. **Couples real-time sharing, no ads** — Supabase Realtime, all core features free, only second child onward is paid.

---

## Prerequisites

- **Flutter SDK** stable (3.41+). Installed at `E:\flutter`.
- **Android Studio** with Flutter & Dart plugins (install from Android Studio → Settings → Plugins).
- **Android SDK** with cmdline-tools — see [docs/android_setup.md](docs/android_setup.md).
- **Xcode** (macOS only, for iOS builds).

Verify with:
```bash
flutter doctor
```

## Project layout

```
lib/
├── main.dart                  # Entry point — env load, Supabase init, runApp
├── app.dart                   # Root MaterialApp.router
├── core/
│   ├── config/                # Env (--dart-define-fed)
│   ├── theme/                 # Material 3 light/dark
│   ├── router/                # go_router config
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── features/                  # Each feature: data/ + domain/ + presentation/
│   ├── auth/
│   ├── child/
│   ├── feeding/
│   ├── sleep/
│   ├── diaper/
│   ├── growth/
│   ├── inventory/             # ★ depletion alerts (differentiator)
│   ├── hospital/              # ★ family hospital + call/maps
│   ├── vaccination/           # ★ country-specific schedules
│   ├── stats/
│   ├── caregiver/             # couples sharing
│   ├── subscription/          # RevenueCat paywall
│   ├── affiliate/             # link tracking
│   └── home/                  # dashboard composing the above
├── data/                      # global Supabase client / repos
├── models/                    # shared models
└── l10n/                      # ARB files (ko/en/ja) + generated bindings
```

## Configuration (env)

Secrets are passed at build time via `--dart-define`, never committed.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi... \
  --dart-define=SENTRY_DSN=https://...@sentry.io/...
```

For convenience, save your common defines in `run/dev.json` (gitignored) and pass with `--dart-define-from-file=run/dev.json`.

## Common commands

| Goal | Command |
|---|---|
| Install / update packages | `flutter pub get` |
| Regenerate localization | `flutter gen-l10n` |
| Static analysis | `flutter analyze` |
| Tests | `flutter test` |
| Run on a device | `flutter run --dart-define-from-file=run/dev.json` |
| Build release APK | `flutter build apk --release --dart-define-from-file=run/prod.json` |
| Build iOS (macOS) | `flutter build ipa --release --dart-define-from-file=run/prod.json` |

## Roadmap (24 weeks)

| Phase | Weeks | Scope |
|---|---|---|
| 1. Foundation | 1–4 | Project, design system, auth, data model |
| 2. Core records | 5–10 | Home, feed/sleep/diaper/growth, stats |
| 3. Differentiators | 11–16 | Inventory, hospital, vaccination |
| 4. Couples + payments | 17–20 | Caregiver share, RevenueCat |
| 5. i18n + launch | 21–24 | KO/JA/EN, affiliate, beta, store |

Detailed plan in [docs/spec_extracted.txt](docs/spec_extracted.txt) §11.
