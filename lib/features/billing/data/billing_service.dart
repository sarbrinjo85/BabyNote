import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/env.dart';

/// RevenueCat 기반 인앱 결제/구독 서비스.
///
/// ── 구조 ─────────────────────────────────────────────────────────────
/// - initialize(): 앱 시작 시 1회 호출. 환경 키 없으면 no-op.
/// - getOfferings(): 현재 활성 패키지 목록 (월/연/평생 등)
/// - purchasePackage(): 결제 진행 + 결과 반환
/// - hasMultiChildEntitlement(): 멀티 자녀 entitlement 활성 여부 (Riverpod 사용)
/// - restorePurchases(): "구독 복원"
/// - logIn(userId): Supabase userId와 RevenueCat appUserId 연결
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool get isEnabled => Env.isBillingEnabled;

  /// 앱 시작 시 1회 호출.
  Future<void> initialize() async {
    if (_initialized || !isEnabled) return;
    try {
      await Purchases.setLogLevel(
          kReleaseMode ? LogLevel.warn : LogLevel.info);
      final apiKey = Platform.isIOS
          ? Env.revenueCatIosKey
          : Env.revenueCatAndroidKey;
      if (apiKey.isEmpty) return;
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;
    } catch (e, st) {
      debugPrint('Billing init error: $e\n$st');
    }
  }

  /// Supabase 로그인 후 호출 — RevenueCat 사용자도 동일 userId로 alias.
  Future<void> logIn(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Billing logIn error: $e');
    }
  }

  /// 로그아웃 시 RevenueCat anonymous로 전환.
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Billing logOut error: $e');
    }
  }

  /// 활성 패키지 (현재 entitlement에 매핑된 상품 목록).
  /// RevenueCat 콘솔의 "current" offering 기준.
  Future<Offering?> currentOffering() async {
    if (!_initialized) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint('getOfferings error: $e');
      return null;
    }
  }

  /// 패키지 구매 — 성공 시 CustomerInfo 반환, 취소/실패 시 null.
  Future<CustomerInfo?> purchasePackage(Package pkg) async {
    if (!_initialized) return null;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      debugPrint('purchasePackage error: $e');
      return null;
    } catch (e) {
      debugPrint('purchasePackage error: $e');
      return null;
    }
  }

  /// 구독 복원 — 다른 디바이스에서 산 구독 동기화.
  Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases error: $e');
      return null;
    }
  }

  /// 현재 customerInfo (entitlement 포함).
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('getCustomerInfo error: $e');
      return null;
    }
  }

  /// 멀티 자녀 entitlement 활성 여부.
  bool hasMultiChildEntitlement(CustomerInfo? info) {
    if (info == null) return false;
    final ent = info.entitlements.active[Env.billingEntitlement];
    return ent != null && ent.isActive;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService.instance;
});

/// 현재 구매 정보 (entitlement 포함). billing 비활성이면 null.
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  final svc = ref.watch(billingServiceProvider);
  if (!svc.isInitialized) return null;
  return svc.getCustomerInfo();
});

/// 멀티 자녀 entitlement 활성 여부.
/// 빌링이 비활성(키 없음)이면 항상 true 반환 → 개발 환경에서 막힘 없음.
/// 실제 출시 시 키 주입 + entitlement 등록되어야 paywall 동작.
final hasMultiChildEntitlementProvider = Provider<bool>((ref) {
  final svc = ref.watch(billingServiceProvider);
  if (!svc.isEnabled) return true; // 키 없으면 freely allow (dev mode)
  return ref.watch(customerInfoProvider).maybeWhen(
        data: (info) => svc.hasMultiChildEntitlement(info),
        orElse: () => false,
      );
});
