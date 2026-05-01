-- =============================================================================
-- 03_inventories_hospitals.sql — 분유/기저귀 재고 + 단골 병원
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- formula_inventories — 분유 재고
-- ─────────────────────────────────────────────────────────────────────────────
-- 핵심 차별화 기능 ①의 데이터 기반.
-- 사용자가 분유 1통을 등록하면, 수유 기록의 amount_ml에서 자동 차감해서
-- "X일 후 떨어짐" 알림 발송.
create table if not exists public.formula_inventories (
  id              uuid primary key default gen_random_uuid(),
  child_id        uuid not null references public.children(id) on delete cascade,
  created_by      uuid references public.user_profiles(id) on delete set null,
  product_name    text not null,
  brand           text,
  -- 1통 용량 (g). 예: 800g 들이 한 통.
  container_grams int not null check (container_grams > 0),
  -- 분유 1g당 몇 ml로 환산되는지. 제품마다 미세하게 다름 (보통 7.0).
  -- 이 값이 정확해야 잔량 계산이 맞음.
  ml_per_gram     numeric(5,2) not null default 7.0,
  purchased_at    date,
  -- 가격은 "센트 단위 정수" 패턴으로 저장 (부동소수점 회피).
  -- 예: $14.99 = 1499, ₩19,000 = 1900000 (KRW는 소수점 없으니 *100을 안 해도 되긴 함)
  -- 통화 별 단위는 클라이언트가 표시 시 처리.
  price_minor     int,
  currency        text not null default 'KRW' check (length(currency) = 3),
  store           text,
  opened_at       date, -- 개봉일. 보통 1개월 내 사용 권장.
  depleted_at     date, -- 다 쓴 날. NULL이면 사용 중.
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_formula_inv_child on public.formula_inventories(child_id);
-- 현재 사용 중인 통(depleted_at IS NULL)만 빠르게 조회.
create index if not exists idx_formula_inv_active
  on public.formula_inventories(child_id) where depleted_at is null;

create trigger trg_formula_inv_updated_at
  before update on public.formula_inventories
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- diaper_inventories — 기저귀 재고
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.diaper_inventories (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  created_by   uuid references public.user_profiles(id) on delete set null,
  brand        text,
  -- 사이즈 표기는 글로벌 차이 있음. NB(신생아) → S → M → L → XL → XXL.
  -- 미국식 1/2/3/4/5/6 매핑은 클라이언트가 표시 시 처리.
  size         text not null check (size in ('NB','S','M','L','XL','XXL')),
  quantity     int not null check (quantity > 0), -- 매수
  -- 기저귀는 낮용/밤용을 구분해서 사기도 함 (밤용은 흡수량 많은 제품).
  usage_kind   text check (usage_kind in ('day','night','all')),
  purchased_at date,
  price_minor  int,
  currency     text not null default 'KRW' check (length(currency) = 3),
  store        text,
  opened_at    date,
  depleted_at  date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_diaper_inv_child on public.diaper_inventories(child_id);
create index if not exists idx_diaper_inv_active
  on public.diaper_inventories(child_id) where depleted_at is null;

create trigger trg_diaper_inv_updated_at
  before update on public.diaper_inventories
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- 02 파일에서 미뤄둔 FK 추가
-- ─────────────────────────────────────────────────────────────────────────────
-- feedings.formula_inventory_id → formula_inventories.id
-- diapers.diaper_inventory_id → diaper_inventories.id
-- on delete set null: 재고 row가 삭제돼도 과거 기록은 유지됨.
alter table public.feedings
  add constraint feedings_formula_inv_fk
  foreign key (formula_inventory_id)
  references public.formula_inventories(id)
  on delete set null;

alter table public.diapers
  add constraint diapers_diaper_inv_fk
  foreign key (diaper_inventory_id)
  references public.diaper_inventories(id)
  on delete set null;


-- ─────────────────────────────────────────────────────────────────────────────
-- hospitals — 단골 병원
-- ─────────────────────────────────────────────────────────────────────────────
-- 자녀가 아닌 user_id에 직접 묶임. 부부가 같은 자녀를 케어해도 단골 병원은
-- 각자 가지는 게 자연스러움 (한 명은 동네 소아과, 다른 한 명은 직장 근처 등).
-- 차별화 기능 ②의 핵심.
create table if not exists public.hospitals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.user_profiles(id) on delete cascade,
  name        text not null,
  specialty   text check (specialty in ('pediatrics','dental','er','other')),
  phone       text, -- "010-1234-5678" 같은 식. tel: 딥링크에 그대로 사용.
  address     text,
  latitude    numeric(9,6),  -- 위도 (소수점 6자리 = 약 11cm 정밀도)
  longitude   numeric(9,6),
  -- 진료 시간: { "mon": "09:00-18:00", "tue": ..., "sat": "09:00-13:00", "sun": "closed" }
  hours       jsonb,
  note        text,
  -- 무료 사용자는 1개만, 패밀리 플랜은 무제한. 앱 단에서 검증.
  -- DB는 데이터를 받기만 하고 권한 검증은 클라이언트가 수행.
  is_default  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists idx_hospitals_user on public.hospitals(user_id);

create trigger trg_hospitals_updated_at
  before update on public.hospitals
  for each row execute function public.set_updated_at();
