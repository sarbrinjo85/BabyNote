import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/child/presentation/child_providers.dart';
import '../../features/child/presentation/selected_child_provider.dart';

/// AppBar.actions에 넣어 쓰는 자녀 picker 위젯.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// 자녀 0명 / 1명: 위젯이 보이지 않음 (SizedBox.shrink) — picker 의미 없음
/// 자녀 2+명:
///   - 현재 선택된 자녀 이름 + 아래 화살표 chip
///   - 탭하면 PopupMenu로 다른 자녀 선택 가능
///
/// ── 변경 동기화 ──────────────────────────────────────────────────────
/// 여기서 selectedChildIdProvider를 갱신하면 home + 모든 record/stats/inventory/family
/// 페이지가 동시에 같은 자녀로 전환됨 (이미 selectedChildProvider watch 중).
class ChildPickerAction extends ConsumerWidget {
  const ChildPickerAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(myChildrenProvider);
    return asyncChildren.maybeWhen(
      data: (children) {
        // 0명: 표시 X, 1명: 표시 X (선택 의미 없음)
        if (children.length < 2) return const SizedBox.shrink();

        final selectedId = ref.watch(selectedChildIdProvider);
        final current = children.firstWhere(
          (c) => c.id == (selectedId ?? children.first.id),
          orElse: () => children.first,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: PopupMenuButton<String>(
            tooltip: current.name,
            position: PopupMenuPosition.under,
            onSelected: (id) =>
                ref.read(selectedChildIdProvider.notifier).state = id,
            itemBuilder: (_) => children
                .map((c) => PopupMenuItem<String>(
                      value: c.id,
                      child: Row(
                        children: [
                          if (c.id == current.id)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.child_care, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    current.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
