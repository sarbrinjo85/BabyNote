import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../utils/time_ago.dart';
import '../../features/child/presentation/child_providers.dart';
import '../../features/child/presentation/selected_child_provider.dart';
import '../../features/diaper/presentation/diaper_providers.dart';
import '../../features/feeding/presentation/feeding_providers.dart';
import '../../features/growth/presentation/growth_providers.dart';
import '../../features/sleep/presentation/sleep_providers.dart';

/// 오늘의 기록 4종(수유/수면/기저귀/성장)을 Android 홈 위젯과 동기화.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// ConsumerStatefulWidget으로 root 부근에 설치 → 선택 자녀 + 4 provider
/// 변경 감지 → HomeWidget.saveWidgetData() 로 SharedPreferences에 기록
/// → HomeWidget.updateWidget() 로 Provider.onUpdate 트리거.
///
/// Kotlin 측 `BabyNoteWidgetProvider.onUpdate`가 같은 키를 읽어 setText.
class HomeWidgetPublisher extends ConsumerStatefulWidget {
  const HomeWidgetPublisher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeWidgetPublisher> createState() =>
      _HomeWidgetPublisherState();
}

class _HomeWidgetPublisherState extends ConsumerState<HomeWidgetPublisher> {
  String _last = ''; // 마지막 push payload — 동일하면 skip

  @override
  Widget build(BuildContext context) {
    // ⚠️ 핵심: provider를 watch해야 데이터가 비동기로 로드된 뒤
    //   rebuild가 일어나고, postFrame 콜백에서 다시 _sync 가 실행됨.
    final asyncChildren = ref.watch(myChildrenProvider);
    final selected = ref.watch(selectedChildProvider);
    final children =
        asyncChildren.maybeWhen(data: (c) => c, orElse: () => const []);
    final child = (selected != null)
        ? selected
        : (children.isEmpty ? null : children.first);
    if (child != null) {
      // value 자체는 build에서 안 쓰지만 watch로 의존성 등록 → 변경 시 rebuild
      ref.watch(recentFeedingsProvider(child.id));
      ref.watch(recentSleepsProvider(child.id));
      ref.watch(recentDiapersProvider(child.id));
      ref.watch(growthsProvider(child.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    return widget.child;
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final asyncChildren = ref.read(myChildrenProvider);
    final children = asyncChildren.maybeWhen(data: (c) => c, orElse: () => []);
    if (children.isEmpty) return;
    final child = ref.read(selectedChildProvider) ?? children.first;
    final l10n = AppLocalizations.of(context);

    final lastFeeding = ref
        .read(recentFeedingsProvider(child.id))
        .maybeWhen(data: (l) => l.isEmpty ? null : l.first, orElse: () => null);
    final lastSleep = ref
        .read(recentSleepsProvider(child.id))
        .maybeWhen(data: (l) => l.isEmpty ? null : l.first, orElse: () => null);
    final lastDiaper = ref
        .read(recentDiapersProvider(child.id))
        .maybeWhen(data: (l) => l.isEmpty ? null : l.first, orElse: () => null);
    final lastGrowth = ref
        .read(growthsProvider(child.id))
        .maybeWhen(data: (l) => l.isEmpty ? null : l.last, orElse: () => null);

    String feedingText = '—';
    if (lastFeeding != null) {
      final time = TimeAgo.format(l10n, lastFeeding.startedAt);
      final amount = lastFeeding.amountMl != null
          ? '${lastFeeding.amountMl}ml'
          : (lastFeeding.type == 'breast'
              ? l10n.feedingTabBreast
              : (lastFeeding.type == 'formula'
                  ? l10n.feedingTabFormula
                  : l10n.feedingTabSolid));
      feedingText = '$time\n$amount';
    }

    String sleepText = '—';
    String sleepLabel = l10n.summarySleep;
    if (lastSleep != null) {
      final time = TimeAgo.format(l10n, lastSleep.startedAt);
      String dur;
      if (lastSleep.isOngoing) {
        dur = lastSleep.napOrNight == 'night'
            ? l10n.sleepNightInProgress
            : l10n.sleepNapInProgress;
        sleepLabel = l10n.summarySleeping;
      } else {
        final mins = lastSleep.elapsedMinutes(lastSleep.endedAt!);
        if (mins < 60) {
          dur = '${mins}m';
        } else {
          final h = mins ~/ 60;
          final m = mins % 60;
          dur = m == 0 ? '${h}h' : '${h}h${m}m';
        }
      }
      sleepText = '$time\n$dur';
    }

    String diaperText = '—';
    if (lastDiaper != null) {
      final time = TimeAgo.format(l10n, lastDiaper.recordedAt);
      final kind = switch (lastDiaper.type) {
        'pee' => l10n.diaperPee,
        'poop' => l10n.diaperPoop,
        'both' => l10n.diaperBoth,
        _ => lastDiaper.type,
      };
      diaperText = '$time\n$kind';
    }

    String growthText = '—';
    if (lastGrowth != null) {
      final time = TimeAgo.format(l10n, lastGrowth.measuredAt);
      String v = '—';
      if (lastGrowth.weightG != null) {
        v = '${(lastGrowth.weightG! / 1000).toStringAsFixed(2)}kg';
      } else if (lastGrowth.heightMm != null) {
        v = '${(lastGrowth.heightMm! / 10).toStringAsFixed(1)}cm';
      }
      growthText = '$time\n$v';
    }

    final payload = '$feedingText|$sleepText|$diaperText|$growthText|$sleepLabel';
    if (payload == _last) return;
    _last = payload;

    await HomeWidget.saveWidgetData('widget_feeding_summary', feedingText);
    await HomeWidget.saveWidgetData('widget_sleep_summary', sleepText);
    await HomeWidget.saveWidgetData('widget_sleep_label', sleepLabel);
    await HomeWidget.saveWidgetData('widget_diaper_summary', diaperText);
    await HomeWidget.saveWidgetData('widget_growth_summary', growthText);
    await HomeWidget.updateWidget(
      androidName: 'BabyNoteWidgetProvider',
      qualifiedAndroidName: 'com.kjfamily.babynote.BabyNoteWidgetProvider',
    );
  }
}
