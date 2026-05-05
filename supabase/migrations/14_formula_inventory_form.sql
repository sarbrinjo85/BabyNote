-- =============================================================================
-- 14_formula_inventory_form.sql — 분유 재고에 형태(가루/액상) 구분 추가
-- =============================================================================
--
-- ── 배경 ────────────────────────────────────────────────────────────
-- 기존 formula_inventories는 가루분유 기준(container_grams + ml_per_gram)
-- 으로만 설계됐음. 액상분유(RTF) 사용자 케어 위해 form 컬럼 추가.
--
-- ── 컬럼 의미 ──────────────────────────────────────────────────────
-- form           'powder' | 'liquid'
-- container_grams (재해석): powder=무게(g), liquid=용량(ml) — 단일 컬럼 재사용
-- ml_per_gram   (재해석): powder=1g당 만들어지는 ml(≈ ml_per_scoop / g_per_scoop)
--                          liquid=1.0 고정 (ml 그대로)
-- g_per_scoop    가루분유 1스쿱 무게(g). 브랜드별 4.3~4.5 범위. default 4.4
-- ml_per_scoop   가루분유 1스쿱이 만드는 ml. 표준 30
--
-- ── 기존 행 마이그레이션 ───────────────────────────────────────────
-- 사용자 요청: 현재는 테스트 단계라 모두 액상으로 처리.
-- ml_per_gram=1.0 으로 강제해 container_grams 를 ml 로 직접 해석되게 함.
-- =============================================================================

alter table public.formula_inventories
  add column if not exists form text not null default 'liquid'
    check (form in ('powder', 'liquid'));

alter table public.formula_inventories
  add column if not exists g_per_scoop  numeric(5,2) not null default 4.4;

alter table public.formula_inventories
  add column if not exists ml_per_scoop numeric(5,2) not null default 30.0;

-- 기존 row를 액상으로 마이그레이션
update public.formula_inventories
  set form = 'liquid',
      ml_per_gram = 1.0
  where form = 'liquid';
