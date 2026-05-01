-- =============================================================================
-- 02_records.sql — 일상 기록 4종 (수유 / 수면 / 기저귀 / 성장)
-- =============================================================================
--
-- 모든 기록 테이블은 child_id 기준으로 RLS가 적용됨 (06 파일 참조).
-- recorded_by는 어느 케어기버가 기록했는지 추적 (부부 누가 입력했나 표시용).
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- feedings — 수유 (모유/분유/이유식)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.feedings (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  recorded_by  uuid references public.user_profiles(id) on delete set null,
  type         text not null check (type in ('breast','formula','solid')),
  started_at   timestamptz not null,
  ended_at     timestamptz, -- 이유식/분유는 NULL일 수 있음. 모유는 보통 양쪽 시간 기록.
  -- 분유/모유: 양 (ml). 이유식: NULL (양 표현 어려움).
  amount_ml    int,
  -- 모유 전용: 어느 쪽 가슴
  breast_side  text check (breast_side in ('left','right','both')),
  -- 이유식 전용: 음식 이름
  food_name    text,
  -- 분유 전용: 브랜드/제품명 (재고 미연결 시 자유 입력)
  formula_brand text,
  -- 분유 재고와 연결되면 그쪽에서 자동 차감 트리거 가능 (Phase 3에서 추가).
  -- inventory가 삭제되면 기록은 유지하되 link만 끊음.
  formula_inventory_id uuid, -- FK는 03 파일에서 추가 (forward reference 회피)
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_feedings_child_started on public.feedings(child_id, started_at desc);

create trigger trg_feedings_updated_at
  before update on public.feedings
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- sleeps — 수면 (낮잠/밤잠)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.sleeps (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  recorded_by  uuid references public.user_profiles(id) on delete set null,
  started_at   timestamptz not null,
  ended_at     timestamptz, -- NULL이면 진행 중인 수면.
  -- 19~07시는 'night', 그 외는 'nap'. 클라이언트가 시작 시각 보고 자동 판정.
  -- 사용자가 수동으로 변경 가능.
  nap_or_night text not null default 'nap'
                check (nap_or_night in ('nap','night')),
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_sleeps_child_started on public.sleeps(child_id, started_at desc);
-- 진행 중인 수면(ended_at IS NULL)을 빠르게 찾기 위한 부분 인덱스 (partial index).
-- 거의 모든 row는 ended_at이 채워져 있으므로 인덱스가 매우 작음.
create index if not exists idx_sleeps_in_progress
  on public.sleeps(child_id) where ended_at is null;

create trigger trg_sleeps_updated_at
  before update on public.sleeps
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- diapers — 기저귀 교체 기록
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.diapers (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  recorded_by  uuid references public.user_profiles(id) on delete set null,
  recorded_at  timestamptz not null,
  type         text not null check (type in ('pee','poop','both')),
  -- 색상은 의학적 의미가 있음. 빨강/검정/흰색은 의사 상담 권유 트리거 (앱 단에서).
  color        text check (color in ('yellow','brown','green','black','red','white','unknown')),
  consistency  text check (consistency in ('loose','normal','firm')),
  diaper_inventory_id uuid, -- FK는 03 파일에서 추가
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_diapers_child_recorded on public.diapers(child_id, recorded_at desc);

create trigger trg_diapers_updated_at
  before update on public.diapers
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- growths — 성장 측정 (체중 / 키 / 머리둘레)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.growths (
  id                    uuid primary key default gen_random_uuid(),
  child_id              uuid not null references public.children(id) on delete cascade,
  recorded_by           uuid references public.user_profiles(id) on delete set null,
  measured_at           timestamptz not null,
  weight_g              int,    -- 무게 (g)
  height_mm             int,    -- 키 (mm)
  head_circumference_mm int,    -- 머리둘레 (mm)
  note                  text,
  created_at            timestamptz not null default now()
  -- 성장 기록은 사후 수정이 적으므로 updated_at 생략. 필요 시 추가.
);

create index if not exists idx_growths_child_measured on public.growths(child_id, measured_at desc);
