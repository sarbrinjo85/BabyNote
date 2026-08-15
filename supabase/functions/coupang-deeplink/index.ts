// 쿠팡 파트너스 Open API 딥링크 변환 (브랜드별 추적 링크 생성) — Phase 2.
//
// ── 왜 서버(Edge Function)인가 ──────────────────────────────────────────────
// 쿠팡 Open API 는 HMAC-SHA256 서명에 Secret Key 가 필요한데, Secret Key 를 앱에
// 넣으면 APK 디컴파일로 유출된다. 그래서 서명은 반드시 서버에서. 앱은 이 함수만
// 호출하고, 함수가 서명 → 쿠팡 API 호출 → 딥링크(link.coupang.com/a/…) 반환.
//
// ── 배포 (사용자 작업) ──────────────────────────────────────────────────────
// 1. 쿠팡 파트너스 → 마이페이지 → Open API → Access Key / Secret Key 발급
// 2. supabase secrets set COUPANG_ACCESS_KEY=... COUPANG_SECRET_KEY=...
// 3. supabase functions deploy coupang-deeplink
//
// ── 앱 호출 ─────────────────────────────────────────────────────────────────
//   supabase.functions.invoke('coupang-deeplink',
//       body: { url: 'https://www.coupang.com/np/search?q=하기스 기저귀', subId: 'diaper' })
//   → { shortenUrl: 'https://link.coupang.com/a/xxxx' }
//
// 함수가 없거나 실패하면 앱이 정적 카테고리 추적 링크(Phase 1)로 폴백하므로,
// 배포 전에도 앱은 정상 동작한다 (수수료 링크만 카테고리 단위).

const DOMAIN = "https://api-gateway.coupang.com";
const PATH =
  "/v2/providers/affiliate_open_api/apis/openapi/v1/deeplink";
const METHOD = "POST";

const enc = new TextEncoder();

/// 쿠팡 서명용 시각 — yyMMdd'T'HHmmss'Z' (GMT).
function signedDateNow(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return (
    p(d.getUTCFullYear() % 100) +
    p(d.getUTCMonth() + 1) +
    p(d.getUTCDate()) +
    "T" +
    p(d.getUTCHours()) +
    p(d.getUTCMinutes()) +
    p(d.getUTCSeconds()) +
    "Z"
  );
}

async function hmacHex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(message));
  return [...new Uint8Array(sig)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/// CEA HMAC Authorization 헤더. 서명 메시지 = signedDate + method + path + query.
async function authHeader(
  accessKey: string,
  secretKey: string,
  query: string,
): Promise<string> {
  const datetime = signedDateNow();
  const signature = await hmacHex(secretKey, datetime + METHOD + PATH + query);
  return `CEA algorithm=HmacSHA256, access-key=${accessKey}, signed-date=${datetime}, signature=${signature}`;
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);

  const accessKey = Deno.env.get("COUPANG_ACCESS_KEY");
  const secretKey = Deno.env.get("COUPANG_SECRET_KEY");
  if (!accessKey || !secretKey) {
    return json({ error: "coupang keys not configured" }, 500);
  }

  let body: { url?: string; urls?: string[]; subId?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid json" }, 400);
  }

  const urls = body.urls ?? (body.url ? [body.url] : []);
  if (urls.length === 0) return json({ error: "no url" }, 400);

  // subId 는 영숫자/_/- 만 (서명·정산 안전). 쿼리 파라미터로 전달.
  const subId = (body.subId ?? "").replace(/[^A-Za-z0-9_-]/g, "").slice(0, 40);
  const query = subId ? `subId=${subId}` : "";
  const requestUrl = DOMAIN + PATH + (query ? `?${query}` : "");

  try {
    const auth = await authHeader(accessKey, secretKey, query);
    const res = await fetch(requestUrl, {
      method: METHOD,
      headers: {
        "Authorization": auth,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ coupangUrls: urls }),
    });
    const data = await res.json();
    const shortenUrl = data?.data?.[0]?.shortenUrl ?? null;
    if (!shortenUrl) return json({ error: "no deeplink", raw: data }, 502);
    return json({ shortenUrl });
  } catch (e) {
    return json({ error: String(e) }, 502);
  }
});
