import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../data/supabase_client_provider.dart';

/// 재구매 대상 상품 카테고리.
enum ProductKind { formula, diaper, other }

/// 어필리에이트 재구매 링크 생성 + 클릭 추적.
///
/// ── 수익 흐름 ────────────────────────────────────────────────────────
/// 재고 소진 임박 → "다시 주문" 버튼 → 브랜드+카테고리로 쿠팡 검색 URL 생성 →
/// affiliate_clicks 에 클릭 기록(정산 검증/분석) → 외부 브라우저로 이동.
///
/// 쿠팡 파트너스 승인 후 [Env.affiliateCoupangSubId] 를 주입하면 subId 파라미터가
/// 붙어 전환/정산이 추적됨. 미주입 시엔 일반 검색 URL(수수료 없음)로 폴백 —
/// 기능 자체는 동작하므로 파트너스 가입 전에도 UX 검증 가능.
///
/// Phase 1은 쿠팡(한국)만 지원. 다권역 파트너(Amazon JP/US)는 Phase 2.
class AffiliateService {
  AffiliateService(this._client);
  final SupabaseClient _client;

  static const _partner = 'coupang';

  /// 브랜드 + 카테고리로 쿠팡 검색 URL 생성.
  /// 예) brand="하기스", diaper → "하기스 기저귀" 검색.
  Uri buildReorderUrl({required ProductKind kind, String? brand}) {
    final query = [
      if (brand != null && brand.trim().isNotEmpty) brand.trim(),
      _categoryKeyword(kind),
    ].where((s) => s.isNotEmpty).join(' ');

    final params = <String, String>{'q': query, 'channel': 'user'};
    final subId = Env.affiliateCoupangSubId;
    if (subId.isNotEmpty) params['subId'] = subId; // 파트너스 정산 추적
    return Uri.https('www.coupang.com', '/np/search', params);
  }

  /// 클릭 기록(best-effort) 후 외부 브라우저로 이동. 성공 시 true.
  Future<bool> openReorder({
    required ProductKind kind,
    String? brand,
    String? childId,
  }) async {
    final url = buildReorderUrl(kind: kind, brand: brand);
    // 로깅 실패가 이동을 막지 않도록 fire-and-forget.
    unawaited(_logClick(kind: kind, url: url.toString(), childId: childId));
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('reorder launch 실패: $e');
      return false;
    }
  }

  /// affiliate_clicks 에 클릭 1건 기록. RLS: 본인(user_id=auth.uid) 또는 익명(null).
  Future<void> _logClick({
    required ProductKind kind,
    required String url,
    String? childId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('affiliate_clicks').insert({
        'user_id': ?userId,
        'child_id': ?childId,
        'partner': _partner,
        'product_kind': _kindDbValue(kind),
        'click_url': url,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('affiliate_clicks 기록 실패(무시): $e');
    }
  }

  String _categoryKeyword(ProductKind kind) => switch (kind) {
        ProductKind.formula => '분유',
        ProductKind.diaper => '기저귀',
        ProductKind.other => '',
      };

  // affiliate_clicks.product_kind CHECK 제약: formula|diaper|other.
  String _kindDbValue(ProductKind kind) => switch (kind) {
        ProductKind.formula => 'formula',
        ProductKind.diaper => 'diaper',
        ProductKind.other => 'other',
      };
}

final affiliateServiceProvider = Provider<AffiliateService>((ref) {
  return AffiliateService(ref.watch(supabaseClientProvider));
});

/// 파트너스 subId 가 주입돼 실제 정산 링크가 활성인지 → 수수료 고지 노출 판단.
final affiliateDisclosureVisibleProvider = Provider<bool>((ref) {
  return Env.isAffiliateActive;
});
