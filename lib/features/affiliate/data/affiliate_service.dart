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

  /// 재구매 이동 URL.
  ///
  /// 카테고리별 **쿠팡 파트너스 추적 링크**(link.coupang.com) 를 우선 사용 —
  /// 이 링크를 통한 클릭만 수수료가 정산됨. 카테고리 단위라 브랜드 특정은 안 되고
  /// "기저귀/분유" 검색 결과로 이동(Phase 1). 브랜드별 딥링크는 Phase 2(Open API).
  ///
  /// 추적 링크 미설정 시엔 일반 검색 URL 로 폴백(동작만, 수수료 X).
  Uri buildReorderUrl({required ProductKind kind, String? brand}) {
    final tracking = switch (kind) {
      ProductKind.diaper => Env.affiliateCoupangDiaperUrl,
      ProductKind.formula => Env.affiliateCoupangFormulaUrl,
      ProductKind.other => '',
    };
    if (tracking.isNotEmpty) return Uri.parse(tracking);
    // 폴백: 추적 안 되는 일반 검색 (수수료 X).
    return _coupangSearchUrl(kind: kind, brand: brand);
  }

  /// 재구매 URL 해석 (Phase 2).
  ///
  /// 브랜드가 있으면 **브랜드별 딥링크**를 `coupang-deeplink` Edge Function 으로
  /// 생성 시도 → "하기스 기저귀" 처럼 브랜드 특정 추적 링크. 함수 미배포/실패 시엔
  /// 정적 카테고리 추적 링크([buildReorderUrl], Phase 1)로 폴백.
  Future<Uri> resolveReorderUrl({
    required ProductKind kind,
    String? brand,
  }) async {
    if (brand != null && brand.trim().isNotEmpty && kind != ProductKind.other) {
      final target = _coupangSearchUrl(kind: kind, brand: brand);
      try {
        final res = await _client.functions.invoke(
          'coupang-deeplink',
          body: {'url': target.toString(), 'subId': _kindDbValue(kind)},
        );
        final data = res.data;
        final shorten = (data is Map) ? data['shortenUrl'] as String? : null;
        if (shorten != null && shorten.isNotEmpty) return Uri.parse(shorten);
      } catch (e) {
        if (kDebugMode) debugPrint('coupang deeplink 실패, 정적 링크 폴백: $e');
      }
    }
    return buildReorderUrl(kind: kind, brand: brand);
  }

  /// 클릭 기록(best-effort) 후 외부 브라우저로 이동. 성공 시 true.
  Future<bool> openReorder({
    required ProductKind kind,
    String? brand,
    String? childId,
  }) async {
    final url = await resolveReorderUrl(kind: kind, brand: brand);
    // 로깅 실패가 이동을 막지 않도록 fire-and-forget.
    unawaited(_logClick(kind: kind, url: url.toString(), childId: childId));
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('reorder launch 실패: $e');
      return false;
    }
  }

  /// 브랜드+카테고리 쿠팡 검색 URL (딥링크 변환 대상).
  Uri _coupangSearchUrl({required ProductKind kind, String? brand}) {
    final query = [
      if (brand != null && brand.trim().isNotEmpty) brand.trim(),
      _categoryKeyword(kind),
    ].where((s) => s.isNotEmpty).join(' ');
    return Uri.https('www.coupang.com', '/np/search', {'q': query});
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
