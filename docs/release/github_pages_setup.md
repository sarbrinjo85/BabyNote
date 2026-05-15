# GitHub Pages — 개인정보처리방침 / 이용약관 호스팅

앱스토어 제출 시 **공개 접근 가능한 URL** 이 필수입니다. GitHub Pages 가 무료 + 가장 간단.

## 1. 결과 미리보기

- 개인정보처리방침: `https://sarbrinjo85.github.io/BabyNote/privacy_policy.html`
- 이용약관: `https://sarbrinjo85.github.io/BabyNote/terms_of_service.html`

(이후 JP/EN 추가 시):
- `privacy_policy_ja.html` / `privacy_policy_en.html`
- `terms_of_service_ja.html` / `terms_of_service_en.html`

## 2. 설정 단계

### a. 저장소 GitHub Pages 활성화

1. https://github.com/sarbrinjo85/BabyNote → **Settings** → **Pages**
2. **Source**: `Deploy from a branch`
3. **Branch**: `main` / **Folder**: `/docs`
4. **Save**

→ ~30초 후 `https://sarbrinjo85.github.io/BabyNote/` 가 활성화됩니다.

### b. docs 폴더에 index 추가 (선택)

기본적으로 `/docs/README.md` (이미 없음) 가 인덱스. 간단한 index 추가 권장:

`docs/index.md` 새 파일:

```markdown
# BabyNote 법무 문서

- [개인정보처리방침 (한국어)](privacy_policy.html)
- [이용약관 (한국어)](terms_of_service.html)
- [Privacy Policy (English)](privacy_policy_en.html) *(준비 중)*
- [Terms of Service (English)](terms_of_service_en.html) *(준비 중)*
- [プライバシーポリシー (日本語)](privacy_policy_ja.html) *(준비 중)*
- [利用規約 (日本語)](terms_of_service_ja.html) *(준비 중)*

연락처: support.babynote@gmail.com
```

### c. Jekyll 변환 확인

GitHub Pages 의 기본 Jekyll 빌더가 `.md` 를 `.html` 로 자동 변환합니다.
즉 `docs/privacy_policy.md` → `https://.../privacy_policy.html` 로 자동 접근 가능.

## 3. 권장 추가 — `_config.yml`

`docs/_config.yml` 새 파일:

```yaml
title: BabyNote
description: 글로벌 육아기록 앱 - 법무 문서
theme: jekyll-theme-cayman
# 또는 minimal-mistakes 같은 더 정돈된 theme 가능
```

테마 적용 후 페이지 헤더 + 폰트가 깔끔해집니다.

## 4. 출시 직전 체크

- [ ] `Settings → Pages` 에서 `Your site is published at ...` 메시지 확인
- [ ] 공개 URL 에 incognito 모드로 접속 → 한국어 깨짐 없는지
- [ ] `privacy_policy.md` 의 "최종 수정일" 이 출시 날짜에 맞는지
- [ ] 이 URL 을 Play Console / App Store Connect 의 *Privacy Policy URL* 필드에 입력

## 5. JP/EN 번역본 추가는 별도 작업

영어/일본어 번역은 [release/README.md](README.md) 의 권역별 체크리스트 참고. 출시 권역 직전에 추가하면 됨.

## 대안 호스팅

| 옵션 | 장점 | 단점 |
|---|---|---|
| **GitHub Pages** (Recommended) | 무료, 저장소 자동 동기화, 별도 인프라 없음 | 자체 도메인은 추가 설정 |
| Cloudflare Pages | 빠른 CDN, 자체 도메인 무료 | 별도 저장소 연결 필요 |
| 자체 서버 | 완전 제어 | 인프라 비용 + 유지보수 |
| Notion 공개 페이지 | 셋업 매우 빠름 | 앱스토어 심사가 종종 reject |

법무 문서는 GitHub Pages 가 표준 선택.
