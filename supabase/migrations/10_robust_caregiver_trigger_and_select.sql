-- =============================================================================
-- 10_robust_caregiver_trigger_and_select.sql — 트리거 fallback + SELECT 정책 보강
-- =============================================================================
--
-- 09까지 적용했는데도 RLS reject가 반복되는 케이스 디버그용 보강:
--
-- ① add_creator_as_caregiver 트리거 함수: NEW.created_by가 NULL일 때
--    auth.uid()로 fallback → 09 정책의 (user_id = auth.uid()) 무조건 만족.
--
-- ② children SELECT 정책: 본인이 만든(created_by=auth.uid()) 자녀는 caregiver
--    관계 없어도 SELECT 가능 → INSERT 직후 RETURNING 단계에서 caregiver row가
--    아직 visible 안 한 race도 회피.
-- =============================================================================

-- ── ① 트리거 함수 보강 ────────────────────────────────────────────────
create or replace function public.add_creator_as_caregiver()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
begin
  -- created_by가 NULL이면 auth.uid()로 fallback (BEFORE 트리거가 채우지 못한 경우 대비)
  v_uid := coalesce(new.created_by, auth.uid());
  if v_uid is not null then
    insert into public.caregivers (child_id, user_id, role, accepted_at)
    values (new.id, v_uid, 'parent', now())
    on conflict do nothing;
  end if;
  return new;
end;
$$;


-- ── ② children SELECT 정책 보강 ──────────────────────────────────────
drop policy if exists "children: select if caregiver" on public.children;
create policy "children: select if caregiver"
  on public.children for select
  using (created_by = auth.uid() or public.is_caregiver_of(id));
