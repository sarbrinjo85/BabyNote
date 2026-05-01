-- =============================================================================
-- 08_auto_created_by.sql — children INSERT 시 created_by를 서버가 자동 채움
-- =============================================================================
--
-- 문제 상황: 클라이언트가 created_by에 user.id를 보내야 RLS의 with check
-- (created_by = auth.uid())를 통과. 그런데 클라이언트의 user.id와 서버의
-- auth.uid()가 어떤 이유(stale token 등)로 어긋나면 INSERT가 거부됨.
--
-- 해결: 클라이언트는 created_by를 NULL로 보내고, 서버 트리거가 auth.uid()로
-- 자동 채워줌. RLS 정책도 NULL 케이스를 허용하도록 완화.
-- =============================================================================

-- ── BEFORE INSERT 트리거: created_by가 NULL이면 auth.uid()로 채움 ────
create or replace function public.children_set_created_by()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is null then
    new.created_by = auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_children_set_created_by on public.children;
create trigger trg_children_set_created_by
  before insert on public.children
  for each row execute function public.children_set_created_by();


-- ── RLS 정책 완화: NULL 또는 본인 ID 허용 ─────────────────────────────
-- (NULL이면 트리거가 auth.uid()로 덮어쓰므로 결국 본인 row가 됨)
drop policy if exists "children: insert as self" on public.children;
create policy "children: insert as self"
  on public.children for insert
  with check (created_by is null or created_by = auth.uid());
