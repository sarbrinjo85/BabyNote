-- =============================================================================
-- 04_vaccines.sql — 예방접종 마스터 + 자녀별 접종 기록
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- vaccine_schedules — 국가별 표준 예방접종 일정 (마스터 테이블)
-- ─────────────────────────────────────────────────────────────────────────────
-- 모든 사용자가 read만 가능. write는 service_role만 (=관리자 전용).
-- 차별화 기능 ②의 자동 알림 데이터 소스.
--
-- 출처:
--   KR — 질병관리청 표준 예방접종 일정
--   JP — 후생노동성 정기예방접종
--   US — CDC Immunization Schedule
--   UK — NHS Immunisation Schedule
--   CA — Public Health Agency of Canada
--   AU — National Immunisation Program (NIP)
create table if not exists public.vaccine_schedules (
  id                   uuid primary key default gen_random_uuid(),
  country              text not null
                         check (country in ('KR','JP','US','UK','CA','AU')),
  -- 백신 코드: 'BCG', 'PCV13', 'MMR', 'HEPB' 등. 국가 간 공통 코드 우선.
  code                 text not null,
  -- 표시 이름 (현지어)
  name                 text not null,
  description          text,
  -- 권장 접종 시기 (생후 일수). 예: 생후 4주 = 28, 12개월 = 365, 6세 = 2190
  recommended_age_days int not null,
  -- 몇 차 접종인가. 1차/2차/3차 등.
  dose_number          int not null default 1 check (dose_number >= 1),
  -- 같은 국가 + 같은 백신 + 같은 차수는 하나만 있어야 함.
  unique (country, code, dose_number),
  created_at           timestamptz not null default now()
);

create index if not exists idx_vaccine_sched_country
  on public.vaccine_schedules(country, recommended_age_days);


-- ─────────────────────────────────────────────────────────────────────────────
-- vaccinations — 자녀별 예방접종 기록
-- ─────────────────────────────────────────────────────────────────────────────
-- 마스터 일정과 매칭되지만, 자녀 생일 기준으로 알림이 트리거되는 건
-- 클라이언트(또는 Edge Function 스케줄러)가 처리. DB는 사실(fact)만 저장.
create table if not exists public.vaccinations (
  id                  uuid primary key default gen_random_uuid(),
  child_id            uuid not null references public.children(id) on delete cascade,
  recorded_by         uuid references public.user_profiles(id) on delete set null,
  -- 어떤 마스터 일정과 매칭되는지. NULL = 일정 없는 임의 접종 (출장백신 등).
  vaccine_schedule_id uuid references public.vaccine_schedules(id) on delete set null,
  -- denormalized: 마스터가 사라져도 어떤 백신이었는지 알 수 있게 코드 복사.
  vaccine_code        text not null,
  dose_number         int not null default 1,
  -- 예약일 (D-1 알림 트리거)
  scheduled_for       date,
  -- 실제 접종 완료 시각. NULL이면 미접종 상태.
  administered_at     timestamptz,
  -- 어디서 접종했나
  hospital_id         uuid references public.hospitals(id) on delete set null,
  note                text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists idx_vaccinations_child
  on public.vaccinations(child_id, administered_at desc nulls first);
-- 미접종(administered_at IS NULL) row를 빠르게 찾는 partial index — 알림 발송용.
create index if not exists idx_vaccinations_pending
  on public.vaccinations(child_id, scheduled_for) where administered_at is null;

create trigger trg_vaccinations_updated_at
  before update on public.vaccinations
  for each row execute function public.set_updated_at();
