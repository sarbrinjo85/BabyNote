-- =============================================================================
-- 06_rls_policies.sql — Row Level Security (모든 테이블에 대해)
-- =============================================================================
--
-- RLS = "이 row를 누가 볼 수 있고 누가 수정할 수 있는가"를 DB 레벨에서 강제.
-- 클라이언트가 anon/publishable 키로 접속하면 항상 이 정책의 검사를 거침.
-- service_role 키는 RLS를 우회 (마이그레이션/관리자 작업용).
--
-- 정책 구조:
--   - SELECT: USING 절로 "어떤 row를 읽을 수 있는가"
--   - INSERT: WITH CHECK 절로 "어떤 row를 만들 수 있는가"
--   - UPDATE/DELETE: USING(필터) + WITH CHECK(변경 후 검증)
--
-- 참고: auth.uid()는 현재 인증된 사용자의 id (uuid). 비로그인이면 NULL.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- user_profiles
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.user_profiles enable row level security;

-- 본인 프로필만 read/update. INSERT는 트리거(handle_new_user)가 처리하므로 정책 없음.
-- DELETE도 정책 없음 → auth.users 삭제 시 cascade로만 삭제 가능 (안전).
create policy "user_profiles: select own"
  on public.user_profiles for select
  using (id = auth.uid());

create policy "user_profiles: update own"
  on public.user_profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- children
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.children enable row level security;

-- SELECT: 케어기버 관계가 있는 자녀만 볼 수 있음.
-- 첫 등록 직후엔 created_by가 자기 자신이므로 caregivers 트리거가 돌면서 자동 등록 → 즉시 보임.
create policy "children: select if caregiver"
  on public.children for select
  using (public.is_caregiver_of(id));

-- INSERT: created_by를 자기 자신으로만 설정 가능. 트리거가 caregiver 자동 추가.
create policy "children: insert as self"
  on public.children for insert
  with check (created_by = auth.uid());

-- UPDATE: 케어기버이면 누구나 수정 가능 (자녀 정보는 공유 데이터).
create policy "children: update if caregiver"
  on public.children for update
  using (public.is_caregiver_of(id))
  with check (public.is_caregiver_of(id));

-- DELETE: 케어기버이면 가능. (UI 단에서 확인 다이얼로그 필수.)
create policy "children: delete if caregiver"
  on public.children for delete
  using (public.is_caregiver_of(id));


-- ─────────────────────────────────────────────────────────────────────────────
-- caregivers
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.caregivers enable row level security;

-- SELECT: 같은 자녀의 케어기버끼리 서로 볼 수 있음.
create policy "caregivers: select fellow"
  on public.caregivers for select
  using (public.is_caregiver_of(child_id));

-- INSERT는 트리거(add_creator_as_caregiver) 또는 invitation 흐름에서 처리.
-- MVP에선 직접 INSERT 막음 (보안상 안전).
-- 추후 초대 토큰 기반 INSERT 정책 추가 예정.

-- DELETE: 본인 caregiver row만 삭제 (스스로 그만두기).
create policy "caregivers: delete self"
  on public.caregivers for delete
  using (user_id = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- 일상 기록 (feedings, sleeps, diapers, growths) — 동일 패턴
-- ─────────────────────────────────────────────────────────────────────────────
-- 모두 child_id 기준으로 케어기버이면 CRUD 가능.

alter table public.feedings enable row level security;
create policy "feedings: select if caregiver" on public.feedings for select
  using (public.is_caregiver_of(child_id));
create policy "feedings: insert if caregiver" on public.feedings for insert
  with check (public.is_caregiver_of(child_id) and recorded_by = auth.uid());
create policy "feedings: update if caregiver" on public.feedings for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "feedings: delete if caregiver" on public.feedings for delete
  using (public.is_caregiver_of(child_id));

alter table public.sleeps enable row level security;
create policy "sleeps: select if caregiver" on public.sleeps for select
  using (public.is_caregiver_of(child_id));
create policy "sleeps: insert if caregiver" on public.sleeps for insert
  with check (public.is_caregiver_of(child_id) and recorded_by = auth.uid());
create policy "sleeps: update if caregiver" on public.sleeps for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "sleeps: delete if caregiver" on public.sleeps for delete
  using (public.is_caregiver_of(child_id));

alter table public.diapers enable row level security;
create policy "diapers: select if caregiver" on public.diapers for select
  using (public.is_caregiver_of(child_id));
create policy "diapers: insert if caregiver" on public.diapers for insert
  with check (public.is_caregiver_of(child_id) and recorded_by = auth.uid());
create policy "diapers: update if caregiver" on public.diapers for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "diapers: delete if caregiver" on public.diapers for delete
  using (public.is_caregiver_of(child_id));

alter table public.growths enable row level security;
create policy "growths: select if caregiver" on public.growths for select
  using (public.is_caregiver_of(child_id));
create policy "growths: insert if caregiver" on public.growths for insert
  with check (public.is_caregiver_of(child_id) and recorded_by = auth.uid());
create policy "growths: update if caregiver" on public.growths for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "growths: delete if caregiver" on public.growths for delete
  using (public.is_caregiver_of(child_id));


-- ─────────────────────────────────────────────────────────────────────────────
-- 재고 (formula_inventories, diaper_inventories) — child_id 기준
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.formula_inventories enable row level security;
create policy "formula_inv: select if caregiver" on public.formula_inventories for select
  using (public.is_caregiver_of(child_id));
create policy "formula_inv: insert if caregiver" on public.formula_inventories for insert
  with check (public.is_caregiver_of(child_id) and created_by = auth.uid());
create policy "formula_inv: update if caregiver" on public.formula_inventories for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "formula_inv: delete if caregiver" on public.formula_inventories for delete
  using (public.is_caregiver_of(child_id));

alter table public.diaper_inventories enable row level security;
create policy "diaper_inv: select if caregiver" on public.diaper_inventories for select
  using (public.is_caregiver_of(child_id));
create policy "diaper_inv: insert if caregiver" on public.diaper_inventories for insert
  with check (public.is_caregiver_of(child_id) and created_by = auth.uid());
create policy "diaper_inv: update if caregiver" on public.diaper_inventories for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "diaper_inv: delete if caregiver" on public.diaper_inventories for delete
  using (public.is_caregiver_of(child_id));


-- ─────────────────────────────────────────────────────────────────────────────
-- hospitals — user_id 기준 (자녀가 아닌 사용자 개인 소유)
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.hospitals enable row level security;

create policy "hospitals: select own" on public.hospitals for select
  using (user_id = auth.uid());
create policy "hospitals: insert own" on public.hospitals for insert
  with check (user_id = auth.uid());
create policy "hospitals: update own" on public.hospitals for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy "hospitals: delete own" on public.hospitals for delete
  using (user_id = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- vaccine_schedules — 모두 read, write는 service_role만
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.vaccine_schedules enable row level security;

-- anon/authenticated 사용자에게 read 허용. WHERE 절 없이 전체 SELECT 가능.
create policy "vaccine_sched: read all" on public.vaccine_schedules for select
  using (true);

-- INSERT/UPDATE/DELETE 정책 없음 → 클라이언트는 못 함. service_role만 가능.


-- ─────────────────────────────────────────────────────────────────────────────
-- vaccinations — child_id 기준 (다른 기록과 동일 패턴)
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.vaccinations enable row level security;
create policy "vaccinations: select if caregiver" on public.vaccinations for select
  using (public.is_caregiver_of(child_id));
create policy "vaccinations: insert if caregiver" on public.vaccinations for insert
  with check (public.is_caregiver_of(child_id));
create policy "vaccinations: update if caregiver" on public.vaccinations for update
  using (public.is_caregiver_of(child_id))
  with check (public.is_caregiver_of(child_id));
create policy "vaccinations: delete if caregiver" on public.vaccinations for delete
  using (public.is_caregiver_of(child_id));


-- ─────────────────────────────────────────────────────────────────────────────
-- affiliate_clicks — 본인 클릭만 insert/select
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.affiliate_clicks enable row level security;

-- INSERT: 본인 행위만. user_id가 NULL이면 익명 추적 (Edge Function이 service_role로 처리).
create policy "affiliate: insert own" on public.affiliate_clicks for insert
  with check (user_id is null or user_id = auth.uid());

create policy "affiliate: select own" on public.affiliate_clicks for select
  using (user_id = auth.uid());

-- UPDATE/DELETE는 안 만듦 (감사 로그라서 immutable).


-- ─────────────────────────────────────────────────────────────────────────────
-- subscriptions — 본인 구독만 read. INSERT/UPDATE는 webhook(service_role)이 처리.
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.subscriptions enable row level security;

create policy "subscriptions: select own" on public.subscriptions for select
  using (user_id = auth.uid());

-- 클라이언트가 직접 INSERT/UPDATE 못 함 → 결제 위조 방지.
-- RevenueCat webhook → Edge Function (service_role 키 사용) → upsert.
