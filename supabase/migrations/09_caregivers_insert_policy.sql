-- =============================================================================
-- 09_caregivers_insert_policy.sql — caregivers INSERT 정책 + children 정책 복원
-- =============================================================================
--
-- 문제: children INSERT 시 add_creator_as_caregiver 트리거가 caregivers에
-- INSERT를 시도하는데 caregivers의 INSERT 정책이 없어서 RLS reject.
-- 트리거 함수가 SECURITY DEFINER + postgres owner(BYPASSRLS) 인데도 우회 안 됨.
--
-- 해결: caregivers에 명시적 INSERT 정책 추가 — 자기 자신을 등록하는 행위만 허용.
-- =============================================================================

-- ── caregivers INSERT 정책 추가 ───────────────────────────────────────
-- user_id = auth.uid() : 자기 자신을 caregiver로 등록 (트리거 동작 + 셀프 가입)
-- 추후 초대 흐름이 도입되면 별도 정책(invitation token 기반) 추가 예정.
drop policy if exists "caregivers: insert self or via trigger" on public.caregivers;
create policy "caregivers: insert self or via trigger"
  on public.caregivers for insert
  with check (user_id = auth.uid());


-- ── children 임시 정책 복원 (디버깅용 'allow all' 제거) ──────────────
drop policy if exists "children: insert temp allow all" on public.children;
drop policy if exists "children: insert as self" on public.children;

create policy "children: insert as self"
  on public.children for insert
  with check (created_by is null or created_by = auth.uid());
