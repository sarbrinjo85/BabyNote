-- =============================================================================
-- 11_feeding_photo_path.sql — feedings에 photo_path 컬럼 + Storage 정책
-- =============================================================================
--
-- 이유식 기록에 사진 첨부 가능하게 하려면:
--   ① feedings 테이블에 photo_path(text, nullable) 컬럼 추가
--   ② feeding-photos Storage bucket(사용자가 Dashboard에서 미리 Public으로 생성)에
--      RLS 정책 추가 — 본인 user_id 폴더에만 upload/관리
--
-- photo_path 형식: '<user_id>/<timestamp>_<random>.jpg'
--   예: '2322f1a9-324b-4b6f-9259-a90f14d70c7a/20260502_193512_abcd.jpg'
--
-- public URL 조회: supabase.storage.from('feeding-photos').getPublicUrl(path)
-- =============================================================================

-- ① 컬럼 추가
alter table public.feedings
  add column if not exists photo_path text;


-- ② Storage RLS 정책 (storage.objects 테이블에 적용)
-- public bucket이라 SELECT는 anonymous도 허용됨 (Storage 자체 설정).
-- INSERT/UPDATE/DELETE는 RLS로 본인 폴더만 가능하게 강제.

-- 본인 user_id 폴더에 INSERT(업로드) 허용
drop policy if exists "feeding photos: upload to own folder" on storage.objects;
create policy "feeding photos: upload to own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'feeding-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 본인 폴더의 파일 UPDATE/DELETE 허용
drop policy if exists "feeding photos: manage own folder" on storage.objects;
create policy "feeding photos: manage own folder"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'feeding-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "feeding photos: delete own folder" on storage.objects;
create policy "feeding photos: delete own folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'feeding-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ※ SELECT 정책은 bucket을 Public으로 만들었다면 자동 허용됨.
--   민감 사진이라 비공개로 가려면 bucket을 Private으로 만들고
--   다음 SELECT 정책 추가 (지금은 사용 안 함):
--
-- create policy "feeding photos: read own folder"
--   on storage.objects for select
--   to authenticated
--   using (
--     bucket_id = 'feeding-photos'
--     and (storage.foldername(name))[1] = auth.uid()::text
--   );
