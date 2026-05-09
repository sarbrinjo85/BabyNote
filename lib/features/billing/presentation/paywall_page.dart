import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../data/billing_service.dart';

/// 멀티 자녀 / 가족 plan / 평생 결제 페이월.
///
/// ── 표시 조건 ────────────────────────────────────────────────────────
/// - 자녀 등록 화면 진입 시 이미 1명 이상이고 entitlement 미보유면 자동 push
/// - 설정 → 구독 / 결제 → 수동 진입
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
        const SnackBar(content: Text('구매가 완료되었어요. 가족 플랜이 활성화됐습니다.')),
      );
      if (mounted) context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제가 완료되지 않았어요.')),
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
      SnackBar(content: Text(ok ? '구매가 복원됐어요.' : '복원할 구매가 없어요.')),
    );
    if (ok && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            : ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  const SizedBox(height: Spacing.md),
                  // 헤더
                  Center(
                    child: Column(
                      children: [
                        const Text('👨‍👩‍👧',
                            style: TextStyle(fontSize: 56)),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          '둘째부터는 가족 플랜으로',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA43F45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '첫째는 평생 무료. 둘째부터 자녀를 추가하려면 가족 플랜이 필요해요.',
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
                    ...List.generate(
                      _offering!.availablePackages.length,
                      (i) {
                        final pkg = _offering!.availablePackages[i];
                        final product = pkg.storeProduct;
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: Spacing.sm),
                          child: _PackageCard(
                            title: product.title,
                            description: product.description,
                            price: product.priceString,
                            onPressed: _purchasing
                                ? null
                                : () => _purchase(pkg),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: Spacing.md),
                  Text(
                    '결제는 Google Play / App Store를 통해 처리됩니다. '
                    '구독은 언제든 스토어에서 해지할 수 있어요.',
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
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
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
