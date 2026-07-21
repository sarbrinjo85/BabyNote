import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../data/billing_service.dart';

/// 멀티 자녀 / 가족 plan / 평생 결제 페이월.
///
/// ── 표시 조건 ────────────────────────────────────────────────────────
/// - 자녀 등록 화면 진입 시 이미 1명 이상이고 entitlement 미보유면 자동 push
/// - 설정 → 구독 / 결제 → 수동 진입
/// - 이미 구독 중이면 구매 카드 대신 "이용 중" 상태 + 구독 관리 진입
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  Offering? _offering;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(billingServiceProvider);
    final off = await svc.currentOffering();
    if (!mounted) return;
    setState(() {
      _offering = off;
      _loading = false;
    });
  }

  Future<void> _purchase(Package pkg) async {
    setState(() => _purchasing = true);
    final svc = ref.read(billingServiceProvider);
    final info = await svc.purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (info != null && svc.hasMultiChildEntitlement(info)) {
      ref.invalidate(customerInfoProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('구매가 완료되었어요. 가족 플랜이 활성화됐습니다.'),
        ),
      );
      if (mounted) context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('결제가 완료되지 않았어요.'),
        ),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final svc = ref.read(billingServiceProvider);
    final info = await svc.restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    final ok = svc.hasMultiChildEntitlement(info);
    ref.invalidate(customerInfoProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(ok ? '구매가 복원됐어요.' : '복원할 구매가 없어요.'),
      ),
    );
    if (ok && mounted) context.pop(true);
  }

  /// Google Play 구독 관리 화면 열기.
  /// RevenueCat CustomerInfo.managementURL 이 있으면 그걸 사용 (스토어별 정확),
  /// 없으면 Play 구독 목록 딥링크로 fallback.
  Future<void> _openManagement() async {
    final svc = ref.read(billingServiceProvider);
    final info = await svc.getCustomerInfo();
    final url = info?.managementURL ??
        'https://play.google.com/store/account/subscriptions'
            '?package=com.kjfamily.babynote';
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('구독 관리 화면을 열 수 없어요. Play 스토어에서 확인해주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 이미 entitlement 보유 → 구매 카드 대신 "이용 중" 상태 표시.
    // dev(빌링 키 없음)에서는 provider 가 항상 true 라 Env 가드 필수 (뱃지와 동일).
    final subscribed = Env.isBillingEnabled &&
        ref.watch(hasMultiChildEntitlementProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('가족 플랜'),
        actions: [
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: const Text('구매 복원'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: BabyLoading())
            : subscribed
                ? _SubscribedView(onManage: _openManagement)
                : ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  const SizedBox(height: Spacing.md),
                  // 헤더
                  Center(
                    child: Column(
                      children: [
                        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          '둘째부터는 가족 플랜으로',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA43F45),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 1줄: "첫째는 무료" 강조
                        Text(
                          '첫째는 평생 무료',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD06A5C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 2줄: 보조 안내
                        Text(
                          '둘째부터 자녀를 추가하려면 가족 플랜이 필요해요',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // 혜택
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _Benefit('💌', '자녀 무제한 추가'),
                          SizedBox(height: 8),
                          _Benefit('🤝', '가족과 실시간 공유'),
                          SizedBox(height: 8),
                          _Benefit('📊', '자녀별 통계 / 백분위 비교'),
                          SizedBox(height: 8),
                          _Benefit('☁️', '클라우드 자동 백업'),
                          SizedBox(height: 8),
                          _Benefit('🚫', '광고 없음'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // 패키지 목록
                  if (_offering == null || _offering!.availablePackages.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Text(
                          '결제 상품을 불러올 수 없어요. 잠시 후 다시 시도해주세요.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_offering!.availablePackages.length, (i) {
                      final pkg = _offering!.availablePackages[i];
                      final product = pkg.storeProduct;
                      // 가족팩(babynote_family_yearly) 카드 위에 추천 라벨.
                      // Android base plan 접미사(:p1y) 포함될 수 있어 contains 매칭.
                      final isFamily = product.identifier.contains('family');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isFamily)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 4,
                                ),
                                child: Text(
                                  '👍 자녀가 2명 이상이면 가족팩이 더 좋아요',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD06A5C),
                                  ),
                                ),
                              ),
                            _PackageCard(
                              title: product.title,
                              description: product.description,
                              price: product.priceString,
                              onPressed: _purchasing
                                  ? null
                                  : () => _purchase(pkg),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: Spacing.md),
                  // 구매 복원이 환불로 오해되지 않게 명확히 안내.
                  Text(
                    '이미 구매하셨다면 우측 상단 "구매 복원"을 눌러주세요. '
                    '복원은 환불이 아니라, 기기 변경·재설치 시 구독을 다시 '
                    '불러오는 기능이에요.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '결제는 Google Play / App Store를 통해 처리됩니다. '
                    '구독 해지·환불은 각 스토어에서 진행할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 구독 중 상태 — 구매 카드 대신 이용 중 안내 + 구독 관리 진입.
class _SubscribedView extends StatelessWidget {
  const _SubscribedView({required this.onManage});
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        const SizedBox(height: Spacing.md),
        Center(
          child: Column(
            children: [
              const Text('👑', style: TextStyle(fontSize: 56)),
              const SizedBox(height: Spacing.sm),
              Text(
                '가족 플랜 이용 중',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFA43F45),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '자녀 무제한 추가와 가족 공유가 활성화되어 있어요',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Benefit('💌', '자녀 무제한 추가'),
                SizedBox(height: 8),
                _Benefit('🤝', '가족과 실시간 공유'),
                SizedBox(height: 8),
                _Benefit('📊', '자녀별 통계 / 백분위 비교'),
                SizedBox(height: 8),
                _Benefit('☁️', '클라우드 자동 백업'),
                SizedBox(height: 8),
                _Benefit('🚫', '광고 없음'),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        FilledButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('구독 관리 (Google Play)'),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '결제 수단 변경·해지는 Google Play 구독 관리에서 진행돼요. '
          '해지해도 결제 기간이 끝날 때까지 이용할 수 있어요.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.emoji, this.text);
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.description,
    required this.price,
    required this.onPressed,
  });
  final String title;
  final String description;
  final String price;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                price,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFA43F45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
