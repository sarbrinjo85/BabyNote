import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import 'sync_worker.dart';
import 'write_queue.dart';

/// 오프라인 큐 길이를 AppBar 우측에 표시.
/// count == 0 이면 화면에 0 폭으로 사라짐.
///
/// 탭하면 큐 상세 + "지금 다시 시도" 액션.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(writeQueueCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return IconButton(
      tooltip: l10n.syncPendingTooltip(count),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      onPressed: () => _showDetails(context, ref, count),
    );
  }

  Future<void> _showDetails(BuildContext context, WidgetRef ref, int count) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        color: Theme.of(sheetCtx).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(l10n.syncPendingTitle,
                        style: Theme.of(sheetCtx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.syncPendingDetail(count),
                    style: Theme.of(sheetCtx).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(l10n.syncPendingHint,
                    style: Theme.of(sheetCtx)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: Theme.of(sheetCtx)
                                .colorScheme
                                .onSurfaceVariant)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                        label: Text(l10n.commonClose),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          // 큐 즉시 flush 시도
                          await ref.read(syncWorkerProvider).flush();
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 1),
                                content: Text(l10n.syncRetryDoneToast),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync),
                        label: Text(l10n.syncRetryNow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
