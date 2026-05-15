-- =============================================================================
-- 17_symptoms.sql — 건강 증상 기록 (기침 / 구토 / 발진 / 상처) 통합 테이블
-- =============================================================================
--
-- ── 왜 통합 테이블인가? ────────────────────────────────────────────────
-- 16_routines 와 동일한 이유 — 데이터 형태가 거의 같음:
--   - 모든 증상: 발생 시각 + severity + 메모
--   - 발진/상처는 사진 첨부 가능 (cough/vomit 은 보통 안 함)
-- 4개 따로 만들면 boilerplate 4배.
--
-- ── 컬럼 ─────────────────────────────────────────────────────────────
-- kind         'cough' | 'vomit' | 'rash' | 'injury'
-- occurred_at  발생 시각 (default now())
-- severity     'mild' | 'moderate' | 'severe' (NULL 허용 — 입력 안 했으면)
-- photo_path   Supabase Storage 'symptom-photos' 버킷 안 경로. 발진/상처용.
-- note         자유 메모
--
-- ── 사진 저장 패턴 ────────────────────────────────────────────────────
-- 11_feeding_photo_path 와 동일:
--   Storage path 형식: '<user_id>/<YYYYMMDD_HHmmss>_<random>.jpg'
--   DB 에는 path 만 저장 → 표시 시 supabase.storage.from('symptom-photos').getPublicUrl(path)
--   버킷은 Dashboard 에서 'symptom-photos' Public 으로 미리 생성 필요.
-- =============================================================================

create table if not exists public.symptoms (
  id           uuid primary key default gen_random_uuid(),
  child_id     uuid not null references public.children(id) on delete cascade,
  recorded_by  uuid references public.user_profiles(id) on delete set null,
  kind         text not null check (kind in ('cough', 'vomit', 'rash', 'injury')),
  occurred_at  timestamptz not null default now(),
  severity     text check (severity is null or severity in ('mild', 'moderate', 'severe')),
  photo_path   text,
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists idx_symptoms_child_occurred
  on public.symptoms(child_id, occurred_at desc);

create index if not exists idx_symptoms_child_kind_occurred
  on public.symptoms(child_id, kind, occurred_at desc);

create trigger trg_symptoms_updated_at
  before update on public.symptoms
  for each row execute function public.set_updated_at();

-- ── RLS ────────────────────────────────────────────────────────────
alter table public.symptoms enable row level security;

create policy "symptoms: select if caregiver" on public.symptoms for select
  using (public.is_caregiver_of(child_id));

create policy "symptoms: insert if can_edit" on public.symptoms for insert
  with check (public.can_edit_records(child_id) and recorded_by = auth.uid());

create policy "symptoms: update if can_edit" on public.symptoms for update
  using (public.can_edit_records(child_id))
  with check (public.can_edit_records(child_id));

create policy "symptoms: delete if can_edit" on public.symptoms for delete
  using (public.can_edit_records(child_id));


-- ── Storage 버킷 'symptom-photos' RLS 정책 ───────────────────────────
-- 본인 user_id 폴더에만 업로드/관리 (feeding-photos 패턴 동일).
-- ※ 사용자가 Dashboard → Storage → "New bucket" → 'symptom-photos' (Public 체크) 미리 생성 필요.

drop policy if exists "symptom photos: upload to own folder" on storage.objects;
create policy "symptom photos: upload to own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'symptom-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "symptom photos: manage own folder" on storage.objects;
create policy "symptom photos: manage own folder"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'symptom-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "symptom photos: delete own folder" on storage.objects;
create policy "symptom photos: delete own folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'symptom-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 스키마 캐시 reload
notify pgrst, 'reload schema';
