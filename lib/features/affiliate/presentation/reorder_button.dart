import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../data/affiliate_service.dart';

/// "다시 주문" 버튼 — 재고 소진 임박 시 브랜드로 쿠팡 재구매 이동 + 클릭 추적.
///
/// Phase 1은 쿠팡(한국)만 지원 → **한국어 로케일에서만 노출**. 그 외 로케일은
/// 파트너 미지원이라 숨김 (Phase 2에서 Amazon JP/US 등 추가).
///
/// 브랜드별 딥링크 생성(Edge Function)에 네트워크 왕복이 있어 탭 후 잠깐 로딩
/// 표시. 함수 미배포 시엔 정적 링크로 즉시 폴백.
class ReorderButton extends ConsumerStatefulWidget {
  const ReorderButton({
    super.key,
    required this.kind,
    this.brand,
    this.childId,
  });

  final ProductKind kind;
  final String? brand;
  final String? childId;

  @override
  ConsumerState<ReorderButton> createState() => _ReorderButtonState();
}

class _ReorderButtonState extends ConsumerState<ReorderButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // 쿠팡 = 한국 파트너. 한국어 사용자에게만 노출.
    if (Localizations.localeOf(context).languageCode != 'ko') {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _busy ? null : _onReorder,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.shopping_cart_outlined, size: 18),
      label: Text(l10n.reorderButton),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: const Color(0xFFA43F45),
      ),
    );
  }

  Future<void> _onReorder() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final svc = ref.read(affiliateServiceProvider);
    final ok = await svc.openReorder(
      kind: widget.kind,
      brand: widget.brand,
      childId: widget.childId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(l10n.reorderFailed),
      ));
    }
  }
}

/// 쿠팡 파트너스 수수료 고지 — 파트너스 정산이 실제 활성(subId 주입)일 때만,
/// 그리고 한국어 로케일에서만 노출. 법적 고지 의무 충족용.
class AffiliateDisclosure extends ConsumerWidget {
  const AffiliateDisclosure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(affiliateDisclosureVisibleProvider)) {
      return const SizedBox.shrink();
    }
    if (Localizations.localeOf(context).languageCode != 'ko') {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Text(
        AppLocalizations.of(context).affiliateDisclosure,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }
}
