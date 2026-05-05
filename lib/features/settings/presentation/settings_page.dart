import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../data/export_service.dart';
import 'theme_mode_provider.dart';

/// 설정 페이지 — 테마 모드 + 데이터 내보내기.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;

  ExportLabels _labelsFor(AppLocalizations l10n) => ExportLabels(
        feeding: l10n.summaryFeeding,
        sleep: l10n.summarySleep,
        diaper: l10n.summaryDiaper,
        growth: l10n.summaryGrowth,
        breast: l10n.feedingTabBreast,
        formula: l10n.feedingTabFormula,
        solid: l10n.feedingTabSolid,
        breastLeft: l10n.feedingBreastLeft,
        breastRight: l10n.feedingBreastRight,
        breastBoth: l10n.feedingBreastBoth,
        nap: l10n.sleepNap,
        night: l10n.sleepNight,
        ongoing: l10n.sleepNapInProgress, // 일반 진행중 표시
        pee: l10n.diaperPee,
        poop: l10n.diaperPoop,
        peeAndPoop: l10n.diaperBoth,
        yellow: l10n.diaperColorYellow,
        brown: l10n.diaperColorBrown,
        green: l10n.diaperColorGreen,
        black: l10n.diaperColorBlack,
        red: l10n.diaperColorRed,
        white: l10n.diaperColorWhite,
        unknown: l10n.diaperColorUnknown,
        loose: l10n.diaperLoose,
        normal: l10n.diaperNormal,
        firm: l10n.diaperFirm,
        small: l10n.diaperSmall,
        large: l10n.diaperLarge,
      );

  Future<void> _onExport() async {
    final l10n = AppLocalizations.of(context);
    final children = ref.read(myChildrenProvider).valueOrNull ?? const [];
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonRegisterChildFirst)),
      );
      return;
    }
    final child = ref.read(selectedChildProvider) ?? children.first;

    setState(() => _exporting = true);
    try {
      await ref.read(exportServiceProvider).exportChildToCsv(
            child: child,
            labels: _labelsFor(l10n),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // ── 테마 모드 섹션 ──────────────────────────────────
            Text(
              l10n.settingsTheme,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.settingsThemeHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Spacing.sm),
            asyncMode.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(l10n.errorFailed(err)),
              data: (mode) => SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref
                    .read(themeModeControllerProvider.notifier)
                    .setMode(s.first),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // ── 데이터 내보내기 섹션 ────────────────────────────
            Text(
              l10n.settingsExport,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.settingsExportHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Spacing.sm),
            FilledButton.icon(
              onPressed: _exporting ? null : _onExport,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_exporting
                  ? l10n.settingsExportInProgress
                  : l10n.settingsExportCsv),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(TouchTarget.standard),
              ),
            ),

            // ── 가족 공유 섹션 ────────────────────────────────────
            const SizedBox(height: Spacing.xl),
            Text(
              l10n.familyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: Spacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 28)),
              title: Text(l10n.familyEntryHome),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/family'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('🤝', style: TextStyle(fontSize: 28)),
              title: Text(l10n.familyEntryJoin),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/family/join'),
            ),

            // ── Sentry 검증 (debug 빌드에서만 노출) ─────────────────
            // production 사용자에겐 안 보임 — kDebugMode 가드.
            if (kDebugMode) ...[
              const SizedBox(height: Spacing.xl),
              Text(
                'Sentry 테스트 (debug only)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '버튼을 누르면 의도적 에러를 Sentry로 전송. 약 30초 뒤 sentry.io → Issues에서 확인 가능.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    throw StateError(
                        'BabyNote Sentry 검증 — ${DateTime.now()}');
                  } catch (e, stack) {
                    await Sentry.captureException(e, stackTrace: stack);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Sentry로 테스트 에러 전송. 30초 뒤 dashboard 확인.')),
                    );
                  }
                },
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('테스트 에러 전송'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
