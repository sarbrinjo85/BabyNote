-- =============================================================================
-- 13_caregiver_invites.sql — 부부/가족 공유 초대 코드 시스템 (D4)
-- =============================================================================
--
-- 흐름:
-- 1) 자녀의 caregiver(이미 있는 사람)가 코드를 생성 → caregiver_invites row insert
-- 2) 다른 사용자가 앱에서 코드 입력 → redeem_invite(code) RPC 호출
-- 3) RPC가 caregivers 테이블에 row 추가 (accepted_at = now()) + invite를 used 처리
--
-- 보안:
-- - 코드는 6자리 영숫자(대소문자 구분 없음 — 전부 대문자로 정규화)
-- - 24시간 만료 (앱 측 default. 만료된 코드는 redeem 불가)
-- - 한 번 사용된 코드는 used_at 마킹되어 재사용 불가
-- =============================================================================

create table if not exists public.caregiver_invites (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  -- 6자리 코드 (예: 'A3B7K9'). uppercase alnum 권장 — 클라가 정규화해서 insert.
  code        text not null check (length(code) between 4 and 12),
  role        text not null default 'parent'
                check (role in ('parent','grandparent','nanny','other')),
  -- 만료 시각. 기본 24시간 — 클라이언트가 결정.
  expires_at  timestamptz not null,
  -- 누가 만들었나 (caregiver 본인). on delete set null로 두면 caregiver 떠나도
  -- 이미 사용한 invite의 history는 유지.
  created_by  uuid references public.user_profiles(id) on delete set null,
  -- 누가 사용했나 + 언제. used_at IS NULL이면 미사용 상태.
  used_by     uuid references public.user_profiles(id) on delete set null,
  used_at     timestamptz,
  created_at  timestamptz not null default now()
);

-- 빠른 코드 조회 — 미사용 코드만 (partial index).
create unique index if not exists uq_invites_code_active
  on public.caregiver_invites(code)
  where used_at is null;

create index if not exists idx_invites_child on public.caregiver_invites(child_id);

alter table public.caregiver_invites enable row level security;

-- ─────────────────────────────────────────────────────────────────────────────
-- RLS 정책
-- ─────────────────────────────────────────────────────────────────────────────
-- SELECT: caregiver(생성자 측) 또는 사용한 사람(used_by)이 자기 invite 조회 가능
drop policy if exists invites_select on public.caregiver_invites;
create policy invites_select on public.caregiver_invites for select
  using (
    public.is_caregiver_of(child_id)
    or used_by = auth.uid()
    or created_by = auth.uid()
  );

-- INSERT: 이미 caregiver인 사람만 새 코드 생성 가능. created_by = self 강제.
drop policy if exists invites_insert on public.caregiver_invites;
create policy invites_insert on public.caregiver_invites for insert
  with check (
    public.is_caregiver_of(child_id)
    and created_by = auth.uid()
  );

-- DELETE: 생성자 본인만 자기 invite 삭제 가능 (코드 회수).
drop policy if exists invites_delete on public.caregiver_invites;
create policy invites_delete on public.caregiver_invites for delete
  using (created_by = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- redeem_invite(code) — 초대 코드 사용
-- ─────────────────────────────────────────────────────────────────────────────
-- 클라이언트가 supabase.rpc('redeem_invite', { p_code: 'A3B7K9' }) 형태로 호출.
-- 성공 시 child_id(uuid) 반환. 실패 시 raise exception.
--
-- security definer: caregivers 테이블의 RLS를 우회해서 row 추가.
-- 일반 사용자가 다른 가족의 caregivers에 row를 직접 INSERT하면 RLS가 막아야 하지만,
-- 이 함수 안에서는 코드 검증을 거친 뒤이므로 안전.
create or replace function public.redeem_invite(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite caregiver_invites%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  -- 미사용 + 가장 최근 생성된 invite 1건 조회 + lock
  select * into v_invite
  from public.caregiver_invites
  where code = upper(p_code) and used_at is null
  for update;

  if not found then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  if v_invite.expires_at < now() then
    raise exception 'INVITE_EXPIRED';
  end if;

  -- caregiver row insert (이미 있으면 accepted_at만 갱신)
  insert into public.caregivers (child_id, user_id, role, accepted_at)
  values (v_invite.child_id, v_user, v_invite.role, now())
  on conflict (child_id, user_id) do update
    set accepted_at = now(),
        role = excluded.role;

  -- 사용 처리
  update public.caregiver_invites
     set used_by = v_user, used_at = now()
   where id = v_invite.id;

  return v_invite.child_id;
end;
$$;

grant execute on function public.redeem_invite(text) to authenticated;
