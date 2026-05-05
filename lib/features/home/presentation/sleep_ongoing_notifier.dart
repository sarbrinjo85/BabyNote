import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/notifications/notification_service.dart';
import '../../child/domain/child.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// 수면 진행 중 ongoing notification을 자동 표시/제거하는 무음 위젯.
///
/// ── 왜 위젯인가 ─────────────────────────────────────────────────
/// SleepController.start/end 시점에 직접 부르는 것보다 reactive 패턴이 더 안전:
/// - 앱 재시작 후 진행 중 수면이 있어도 자동으로 알림 다시 표시
/// - 다른 디바이스(가족 공유)에서 시작한 수면도 polling/watch로 반영
/// - SleepController는 라벨 의존성 없음 (l10n 접근 위치 분리)
class SleepOngoingNotifier extends ConsumerWidget {
  const SleepOngoingNotifier({super.key, required this.child});
  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncOngoing = ref.watch(ongoingSleepProvider(child.id));

    asyncOngoing.whenData((sleep) {
      if (sleep == null) {
        // 진행 중 수면 없음 → ongoing notification 제거
        NotificationService.instance.cancelOngoingSleep(child.id);
      } else {
        // 진행 중 → ongoing notification 표시 (이미 표시되어 있으면 OS가 자동 갱신)
        final title = sleep.napOrNight == 'night'
            ? l10n.sleepNightInProgress
            : l10n.sleepNapInProgress;
        NotificationService.instance.showOngoingSleep(
          childId: child.id,
          startedAt: sleep.startedAt,
          title: title,
          body: l10n.notifSleepOngoingBody,
        );
      }
    });

    return const SizedBox.shrink();
  }
}
