-- =============================================================================
-- 16_routines.sql — 일상 루틴 기록 (산책 / 목욕 / 영양제 / 간식) 통합 테이블
-- =============================================================================
--
-- ── 왜 4개 테이블이 아니라 1개 통합 테이블인가? ────────────────────────
-- 데이터 형태가 거의 동일함:
--   - 산책 / 목욕: 시간 + 시간(분) + 메모
--   - 영양제 / 간식: 시간 + 이름(텍스트) + 메모
-- 4개 따로 만들면 통계/실시간 동기화/리포지토리 4배 boilerplate.
-- kind 컬럼 + check constraint 로 분기하면 한 테이블에서 깔끔.
--
-- ── 컬럼 ─────────────────────────────────────────────────────────────
-- kind          'walk' | 'bath' | 'supplement' | 'snack'
-- started_at    발생 시각 (모든 종류 공통, default now())
-- duration_min  지속 시간(분) — 산책/목욕에만 의미 있음. 영양제/간식은 NULL.
-- item_name     음식/영양제 이름 — 영양제/간식에 사용. 산책/목욕은 NULL.
-- note          자유 메모
--
-- ── recorded_by 패턴 ────────────────────────────────────────────────
-- 02_records.sql (feedings/sleeps/diapers/growths) 와 동일하게 recorded_by 사용.
-- = 어느 케어기버가 기록했는지. RLS INSERT 정책에서 auth.uid() 일치 검증.
-- =============================================================================

create table if not exists public.routines (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  recorded_by  uuid references public.user_profiles(id) on delete set null,
  kind         text not null check (kind in ('walk', 'bath', 'supplement', 'snack')),
  started_at   timestamptz not null default now(),
  -- 산책/목욕: 지속 시간(분). 영양제/간식: NULL.
  duration_min int check (duration_min is null or duration_min >= 0),
  -- 영양제/간식: 이름 (예: "비타민D 1방울", "사과 1/4쪽"). 산책/목욕: NULL.
  item_name    text,
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_routines_child_started
  on public.routines(child_id, started_at desc);

-- kind별 빠른 필터링용 — 통계 화면에서 "최근 산책 7일" 등 조회 시.
create index if not exists idx_routines_child_kind_started
  on public.routines(child_id, kind, started_at desc);

-- updated_at 자동 갱신 (00_init.sql의 set_updated_at 함수 사용).
create trigger trg_routines_updated_at
  before update on public.routines
  for each row execute function public.set_updated_at();

-- ── RLS ────────────────────────────────────────────────────────────
-- 06_rls_policies.sql 패턴 동일 + 15_caregiver_roles.sql 의 can_edit_records 사용.
-- (15 migration이 적용된 상태라고 가정)
alter table public.routines enable row level security;

create policy "routines: select if caregiver" on public.routines for select
  using (public.is_caregiver_of(child_id));

create policy "routines: insert if can_edit" on public.routines for insert
  with check (public.can_edit_records(child_id) and recorded_by = auth.uid());

create policy "routines: update if can_edit" on public.routines for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));

create policy "routines: delete if can_edit" on public.routines for delete
  using (public.can_edit_records(child_id));
