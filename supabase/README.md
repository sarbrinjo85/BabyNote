# Supabase 백엔드

## 적용 순서

Supabase Dashboard → **SQL Editor** → "New query" → 아래 파일을 **순서대로 복사+붙여넣기+Run**.
순서 중요 (FK 의존성 + RLS는 테이블 생성 후 적용).

| 순서 | 파일 | 내용 |
|---|---|---|
| 1 | `migrations/00_init.sql` | extensions (pgcrypto), 공통 트리거 함수, 헬퍼 |
| 2 | `migrations/01_users_caregivers.sql` | `user_profiles`, `children`, `caregivers` + auth 신규 가입 트리거 |
| 3 | `migrations/02_records.sql` | `feedings`, `sleeps`, `diapers`, `growths` (4개 일상 기록) |
| 4 | `migrations/03_inventories_hospitals.sql` | `formula_inventories`, `diaper_inventories`, `hospitals` |
| 5 | `migrations/04_vaccines.sql` | `vaccine_schedules` (마스터), `vaccinations` (자녀별 기록) |
| 6 | `migrations/05_affiliate_subscriptions.sql` | `affiliate_clicks`, `subscriptions` (RevenueCat 동기화 대상) |
| 7 | `migrations/06_rls_policies.sql` | 모든 테이블에 RLS 활성화 + 정책 |
| 8 | `migrations/07_seed_vaccine_kr.sql` | 한국 표준 예방접종 일정 시드 데이터 |

> 처음엔 `00 → 07` 순서대로 한 번씩 실행. 일본/영어권 시드는 추후 `08_seed_vaccine_jp.sql`, `09_seed_vaccine_us.sql`로 추가.

## 핵심 설계 결정

**1. Primary Key는 모두 `uuid` (`gen_random_uuid()`)**
- 분산 ID — 클라이언트가 ID 미리 만들 수 있음 → 오프라인 작성 후 동기화 시 충돌 없음
- 자동 증가 정수 대비: 추측 불가 (security), URL에 노출돼도 다른 row 추론 불가

**2. 시각은 모두 `timestamptz`**
- 저장은 UTC, 표시는 사용자 타임존 (한일미 같이 쓰기에 필수)
- `now()` default → 트리거에서 자동 채움

**3. 단위는 미터법 통일**
- 무게 = `int` (g), 길이 = `int` (mm), 부피 = `int` (ml)
- 클라이언트가 oz/lb로 변환해서 표시 (사용자 setting에 따라)
- DB에 절대 imperial 저장 안 함 → 통계 계산 일관성 유지

**4. enum 대신 `text + check constraint`**
- Postgres enum 타입은 마이그레이션 시 ALTER가 까다로움 (기존 값 추가는 OK, 제거/재정렬 어려움)
- `text + check (col in (...))` 패턴이 변경에 유연함

**5. RLS (Row Level Security) 강제**
- 모든 사용자 데이터 테이블에 RLS 활성화
- 마스터 테이블(`vaccine_schedules`)만 read-all, write는 service_role(=관리자)만
- 헬퍼 `is_caregiver_of(child_id)` 함수가 정책 표현 단순화

**6. 케어기버 권한 모델**
- 자녀(children) 생성 시 트리거가 생성자를 자동으로 `caregivers`에 추가 (role=parent, 즉시 accepted)
- 다른 사람을 케어기버로 초대하는 흐름은 추후 (QR 코드 + invitation token 패턴)

## Service role vs anon key

- `anon` (= publishable) 키: 클라이언트 앱에서 사용. RLS의 보호를 받음. `auth.uid()`가 그 사용자
- `service_role` 키: 서버/CLI/마이그레이션에서만 사용. RLS 무시. **클라이언트에 절대 노출 금지**

마이그레이션 SQL을 SQL Editor에서 직접 실행하면 service_role 권한으로 동작 → RLS 신경 안 써도 됨. 그래서 시드 데이터 삽입도 가능.
