-- =============================================================================
-- 05_affiliate_subscriptions.sql — 어필리에이트 클릭 추적 + 결제/구독
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- affiliate_clicks — 어필리에이트 링크 클릭 추적
-- ─────────────────────────────────────────────────────────────────────────────
-- 매출 분석/A-B 테스트/파트너 정산 검증 등에 사용.
-- 익명 사용자도 클릭 가능하므로 user_id는 nullable.
create table if not exists public.affiliate_clicks (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.user_profiles(id) on delete set null,
  child_id     uuid references public.children(id) on delete set null,
  -- 어느 파트너 링크인지. 'coupang' | 'amazon_jp' | 'rakuten' | 'amazon_us' | ...
  partner      text not null,
  -- 카테고리: 'formula' | 'diaper' | 'other'
  product_kind text check (product_kind in ('formula','diaper','other')),
  -- 파트너별 product 식별자 (쿠팡 productId, Amazon ASIN 등)
  product_id   text,
  -- 실제 redirect 된 URL (디버깅 + 정산 검증용)
  click_url    text,
  clicked_at   timestamptz not null default now(),
  -- 전환(=실제 구매) 여부. 파트너 webhook 또는 batch reconciliation으로 업데이트.
  converted    boolean not null default false
);

create index if not exists idx_affiliate_user_time
  on public.affiliate_clicks(user_id, clicked_at desc);
create index if not exists idx_affiliate_partner_time
  on public.affiliate_clicks(partner, clicked_at desc);


-- ─────────────────────────────────────────────────────────────────────────────
-- subscriptions — 결제/구독 상태 (RevenueCat ↔ DB 동기화 대상)
-- ─────────────────────────────────────────────────────────────────────────────
-- RevenueCat이 진실의 원천(source of truth)이지만, RLS와 빠른 권한 체크를 위해
-- DB에도 미러링. RevenueCat webhook → Supabase Edge Function → 이 테이블 upsert.
create table if not exists public.subscriptions (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.user_profiles(id) on delete cascade,
  -- 'family_yearly' | 'add_child_yearly' | 'lifetime' | ...
  -- RevenueCat의 entitlement identifier와 매핑.
  product_id            text not null,
  platform              text not null check (platform in ('ios','android','web')),
  status                text not null
                          check (status in ('active','expired','in_grace','cancelled')),
  original_purchase_at  timestamptz,
  expires_at            timestamptz, -- NULL = 평생(lifetime)
  -- RevenueCat의 사용자 식별자 (보통 우리 user_id와 동일하게 설정).
  revenuecat_user_id    text,
  -- 디버깅용: webhook payload 그대로 저장.
  raw_payload           jsonb,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  -- 같은 (user, product, platform) 조합은 하나만. 갱신은 UPSERT.
  unique (user_id, product_id, platform)
);

create index if not exists idx_subscriptions_user_status
  on public.subscriptions(user_id, status);

create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();
