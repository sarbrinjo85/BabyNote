import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../child/domain/child.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';

/// 홈 화면 FAB — 마지막 수유와 같은 type/양으로 1탭 빠른 기록.
///
/// ── 동작 ─────────────────────────────────────────────────────────
/// 짧은 탭:
///   - 마지막 수유 있으면 → 같은 type/양으로 즉시 INSERT (분유는 활성 통 자동 연결)
///   - SnackBar에 결과 + "취소" 액션 (5초 안에 누르면 방금 만든 record 삭제)
///   - 마지막 수유 없으면 → /feeding/new 페이지로 이동 (첫 기록)
/// 길게 탭:
///   - /feeding/new 페이지 (탭 위치/조건 변경하고 싶을 때)
///
/// ── 왜 수유만 ──────────────────────────────────────────────────
/// 신생아는 하루 6~10번 수유. 수면/기저귀는 변동 폭이 큼(상태/양/색상).
/// 수유는 마지막 패턴 그대로 반복되는 경우가 가장 많음 → 1탭 가치 최대.
class QuickFeedingFab extends ConsumerWidget {
  const QuickFeedingFab({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // FAB는 1탭 빠른 기록 전용. 직접 입력하려면 홈 화면의 BigActionButton(수유)
    // 또는 길게 누르지 않고 마지막 기록 없을 때 자동으로 /feeding/new 이동.
    // GestureDetector로 감싸서 길게 누름 제스처를 가로챔.
    // FAB의 onPressed는 짧은 탭 전용 — 제스처 아레나에서 longPress가 우선됨.
    return GestureDetector(
      onLongPress: () => _onLongPress(context, ref),
      child: FloatingActionButton.extended(
        onPressed: () => _onTap(context, ref),
        icon: const Text('🍼', style: TextStyle(fontSize: 22)),
        label: Text(l10n.fabQuickFeed),
        tooltip: l10n.fabQuickFeedTooltip,
      ),
    );
  }

  /// 길게 누름 → 수유 양 직접 입력 다이얼로그 → 마지막 type 그대로 저장.
  /// 마지막 기록 없으면 /feeding/new 페이지로 이동.
  Future<void> _onLongPress(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final asyncRecent = ref.read(recentFeedingsProvider(child.id));
    final last = asyncRecent.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );
    if (last == null) {
      context.push('/feeding/new');
      return;
    }

    final controller = TextEditingController(
      text: last.amountMl?.toString() ?? '',
    );
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fabAmountEditTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l10n.fabAmountEditHint,
            suffixText: 'ml',
          ),
          onSubmitted: (v) {
            final n = int.tryParse(v.trim());
            Navigator.of(ctx).pop(n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(n);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    if (!context.mounted) return;
    await _quickInsert(context, ref, last, overrideAmountMl: amount);
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final asyncRecent = ref.read(recentFeedingsProvider(child.id));
    final last = asyncRecent.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );

    // 마지막 기록 없으면 새 기록 페이지로
    if (last == null) {
      context.push('/feeding/new');
      return;
    }
    await _quickInsert(context, ref, last);
  }

  /// 마지막 수유 패턴을 그대로 복사해 INSERT.
  /// [overrideAmountMl] — 길게 누름 다이얼로그에서 직접 입력한 양.
  Future<void> _quickInsert(
    BuildContext context,
    WidgetRef ref,
    Feeding last, {
    int? overrideAmountMl,
  }) async {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // 분유라면 활성 통 자동 연결
    String? formulaInventoryId;
    if (last.type == 'formula') {
      final asyncActives =
          ref.read(activeFormulaInventoriesProvider(child.id));
      asyncActives.whenData((list) {
        if (list.isNotEmpty) formulaInventoryId = list.first.id;
      });
    }

    final now = DateTime.now();
    final repo = ref.read(feedingRepositoryProvider);
    Feeding? created;
    try {
      created = await repo.createFeeding(
        currentUserId: currentUser.id,
        childId: child.id,
        type: last.type,
        startedAt: now,
        endedAt: now,
        amountMl: overrideAmountMl ?? last.amountMl,
        breastSide: last.breastSide,
        foodName: last.foodName,
        formulaBrand: last.formulaBrand,
        formulaInventoryId: formulaInventoryId,
      );
      ref.invalidate(recentFeedingsProvider(child.id));
      ref.invalidate(formulaInventoryStatsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorFailed(e))),
      );
      return;
    }

    if (!context.mounted) return;
    final summary = _summary(l10n, created);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.fabSaved(summary)),
        action: SnackBarAction(
          label: l10n.fabUndo,
          onPressed: () async {
            try {
              await repo.deleteFeeding(created!.id);
              ref.invalidate(recentFeedingsProvider(child.id));
              ref.invalidate(formulaInventoryStatsProvider);
            } catch (_) {/* 무시 */}
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _summary(AppLocalizations l10n, Feeding f) {
    switch (f.type) {
      case 'breast':
        return '${l10n.feedingTabBreast}${f.amountMl != null ? ' ${f.amountMl}ml' : ''}';
      case 'formula':
        return '${l10n.feedingTabFormula}${f.amountMl != null ? ' ${f.amountMl}ml' : ''}';
      case 'solid':
        return '${l10n.feedingTabSolid}: ${f.foodName ?? ''}';
      default:
        return f.type;
    }
  }
}
