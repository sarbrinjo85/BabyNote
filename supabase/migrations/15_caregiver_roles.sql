-- =============================================================================
-- 15_caregiver_roles.sql — 가족 보호자 역할 세분화 + 권한 분리
-- =============================================================================
--
-- ── 역할 정의 ──────────────────────────────────────────────────────
-- parent / guardian — 모든 기록 조회 + 추가/수정/삭제 가능
-- view_only        — 조회만 가능 (예: 친척이 잠시 들여다보는 경우)
-- grandparent / nanny / other — 기존 호환 (기본 편집 가능)
--
-- ── 정책 ─────────────────────────────────────────────────────────────
-- SELECT은 is_caregiver_of로 동일 (모두 조회 가능)
-- INSERT/UPDATE/DELETE는 can_edit_records로 변경 (view_only 차단)

-- 기존 role CHECK 제거 + 새 값 허용
alter table public.caregivers
  drop constraint if exists caregivers_role_check;

alter table public.caregivers
  add constraint caregivers_role_check
  check (role in (
    'parent', 'guardian', 'view_only',
    'grandparent', 'nanny', 'other'
  ));

-- 편집 권한 함수 — view_only는 false 반환.
create or replace function public.can_edit_records(p_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.caregivers
    where child_id = p_child_id
      and user_id = auth.uid()
      and accepted_at is not null
      and role <> 'view_only'
  );
$$;

-- ── feedings 정책 갱신 ─────────────────────────────────────────────
drop policy if exists "feedings: insert if caregiver" on public.feedings;
drop policy if exists "feedings: update if caregiver" on public.feedings;
drop policy if exists "feedings: delete if caregiver" on public.feedings;

create policy "feedings: insert if can_edit" on public.feedings for insert
  with check (public.can_edit_records(child_id) and created_by = auth.uid());
create policy "feedings: update if can_edit" on public.feedings for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));
create policy "feedings: delete if can_edit" on public.feedings for delete
  using (public.can_edit_records(child_id));

-- ── sleeps 정책 ────────────────────────────────────────────────────
drop policy if exists "sleeps: insert if caregiver" on public.sleeps;
drop policy if exists "sleeps: update if caregiver" on public.sleeps;
drop policy if exists "sleeps: delete if caregiver" on public.sleeps;

create policy "sleeps: insert if can_edit" on public.sleeps for insert
  with check (public.can_edit_records(child_id) and created_by = auth.uid());
create policy "sleeps: update if can_edit" on public.sleeps for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));
create policy "sleeps: delete if can_edit" on public.sleeps for delete
  using (public.can_edit_records(child_id));

-- ── diapers 정책 ───────────────────────────────────────────────────
drop policy if exists "diapers: insert if caregiver" on public.diapers;
drop policy if exists "diapers: update if caregiver" on public.diapers;
drop policy if exists "diapers: delete if caregiver" on public.diapers;

create policy "diapers: insert if can_edit" on public.diapers for insert
  with check (public.can_edit_records(child_id) and created_by = auth.uid());
create policy "diapers: update if can_edit" on public.diapers for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));
create policy "diapers: delete if can_edit" on public.diapers for delete
  using (public.can_edit_records(child_id));

-- ── growths 정책 ───────────────────────────────────────────────────
drop policy if exists "growths: insert if caregiver" on public.growths;
drop policy if exists "growths: update if caregiver" on public.growths;
drop policy if exists "growths: delete if caregiver" on public.growths;

create policy "growths: insert if can_edit" on public.growths for insert
  with check (public.can_edit_records(child_id) and recorded_by = auth.uid());
create policy "growths: update if can_edit" on public.growths for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));
create policy "growths: delete if can_edit" on public.growths for delete
  using (public.can_edit_records(child_id));
