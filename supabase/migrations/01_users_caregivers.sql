-- =============================================================================
-- 01_users_caregivers.sql — 사용자, 자녀, 케어기버 관계
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- user_profiles
-- ─────────────────────────────────────────────────────────────────────────────
-- Supabase는 auth.users 테이블을 자동으로 관리(이메일/소셜로그인 등 인증 정보).
-- 우리 앱 고유의 프로필(국가, 언어, 단위 시스템 등)은 별도 테이블로 분리.
--
-- id가 auth.users(id)를 그대로 참조 → 1:1 관계. 사용자 삭제 시 cascade로 같이 삭제.
create table if not exists public.user_profiles (
  id           uuid primary key
                 references auth.users(id) on delete cascade,
  country      text not null default 'KR'
                 check (country in ('KR','JP','US','UK','CA','AU')),
  language     text not null default 'ko'
                 check (language in ('ko','ja','en')),
  -- 단위 시스템: 'metric'(ml/g/cm) 또는 'imperial'(oz/lb/inch)
  -- 미국만 imperial 기본, 나머지는 metric. 사용자가 변경 가능.
  unit_system  text not null default 'metric'
                 check (unit_system in ('metric','imperial')),
  timezone     text not null default 'Asia/Seoul', -- IANA tz 식별자
  display_name text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger trg_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- handle_new_user 트리거: auth.users에 새 row가 들어오면 user_profiles 자동 생성
-- ─────────────────────────────────────────────────────────────────────────────
-- Supabase의 auth.users는 시스템 테이블이라 직접 RLS 정책을 못 만들지만, 트리거는 가능.
-- 회원가입 직후 클라이언트가 별도 INSERT 호출 안 해도 프로필 row가 보장됨.
--
-- raw_user_meta_data에서 country/language를 꺼내려면 클라이언트가 회원가입 시
-- supabase.auth.signUp(..., data: { country: 'KR', language: 'ko' }) 처럼 넘기면 됨.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (id, country, language, timezone, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'country', 'KR'),
    coalesce(new.raw_user_meta_data->>'language', 'ko'),
    coalesce(new.raw_user_meta_data->>'timezone', 'Asia/Seoul'),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing; -- 이미 있으면 조용히 패스
  return new;
end;
$$;

drop trigger if exists trg_handle_new_user on auth.users;
create trigger trg_handle_new_user
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ─────────────────────────────────────────────────────────────────────────────
-- children
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.children (
  id              uuid primary key default gen_random_uuid(),
  -- created_by가 NULL일 수 있는 이유: 사용자가 계정을 삭제해도 자녀 데이터는
  -- 다른 케어기버(부부 등)에게 남아있을 수 있어야 하므로 set null 사용.
  created_by      uuid references public.user_profiles(id) on delete set null,
  name            text not null,
  gender          text check (gender in ('male','female','other')),
  birth_date      date not null,
  birth_weight_g  int,    -- 출생 시 체중 (g 단위)
  birth_height_mm int,    -- 출생 시 키 (mm 단위, 즉 50cm = 500mm)
  -- 둘째 자녀부터 유료. 결제 검증은 subscriptions 테이블 + RevenueCat에서.
  -- 이 컬럼은 빠른 UI 표시용 캐시로만 사용 (실제 권한은 결제 검증 거쳐야 함).
  is_paid         boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_children_created_by on public.children(created_by);

create trigger trg_children_updated_at
  before update on public.children
  for each row execute function public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- caregivers — 자녀 ↔ 사용자 다대다 관계 (부부, 조부모, 시터 등)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.caregivers (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  user_id     uuid not null references public.user_profiles(id) on delete cascade,
  role        text not null default 'parent'
                check (role in ('parent','grandparent','nanny','other')),
  -- accepted_at이 NULL이면 초대 받았지만 수락 전 상태(pending).
  -- 초대 수락 시점 = NOW()로 채움.
  accepted_at timestamptz default now(),
  created_at  timestamptz not null default now(),
  -- 같은 (child, user) 조합은 하나만. 중복 케어기버 방지.
  unique (child_id, user_id)
);

create index if not exists idx_caregivers_child on public.caregivers(child_id);
create index if not exists idx_caregivers_user  on public.caregivers(user_id);


-- ─────────────────────────────────────────────────────────────────────────────
-- 자녀 생성 시 생성자를 자동으로 부모 케어기버로 등록
-- ─────────────────────────────────────────────────────────────────────────────
-- 이 트리거가 없으면 클라이언트가 children INSERT 후 caregivers INSERT를 또 해야 함 → 까먹기 쉬움.
create or replace function public.add_creator_as_caregiver()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is not null then
    insert into public.caregivers (child_id, user_id, role, accepted_at)
    values (new.id, new.created_by, 'parent', now())
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_add_creator_as_caregiver on public.children;
create trigger trg_add_creator_as_caregiver
  after insert on public.children
  for each row execute function public.add_creator_as_caregiver();


-- ─────────────────────────────────────────────────────────────────────────────
-- 헬퍼 함수: is_caregiver_of(child_id)
-- ─────────────────────────────────────────────────────────────────────────────
-- "현재 로그인한 사용자(auth.uid())가 이 자녀의 케어기버인가?"를 판단.
-- RLS 정책(06 파일)에서 자주 쓰이므로 함수로 추출. caregivers 테이블이 위에서
-- 막 만들어졌으므로 여기서 정의 가능.
--
-- security definer = 함수가 정의자(=DB owner)의 권한으로 실행됨
--   → caregivers 테이블의 RLS를 우회. 그래야 무한 재귀(RLS가 RLS를 부르는)를 피함.
-- stable = 같은 트랜잭션 안에서 같은 입력에 같은 결과 → 쿼리 플래너가 캐싱 가능.
create or replace function public.is_caregiver_of(p_child_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.caregivers c
    where c.child_id = p_child_id
      and c.user_id = auth.uid()
      and c.accepted_at is not null
  );
$$;
