import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../onboarding/presentation/onboarding_coach.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        walk: l10n.routineKindWalk,
        bath: l10n.routineKindBath,
        supplement: l10n.routineKindSupplement,
        snack: l10n.routineKindSnack,
        cough: l10n.symptomKindCough,
        vomit: l10n.symptomKindVomit,
        rash: l10n.symptomKindRash,
        injury: l10n.symptomKindInjury,
        mild: l10n.symptomSeverityMild,
        moderate: l10n.symptomSeverityModerate,
        severe: l10n.symptomSeveritySevere,
      );

  Future<void> _onExport() async {
    final l10n = AppLocalizations.of(context);
    final children = ref.read(myChildrenProvider).valueOrNull ?? const [];
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.commonRegisterChildFirst)),
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
          .showSnackBar(SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.errorFailed(e))));
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
            // ── 가족 플랜 / 구독 ─────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('가족 플랜'),
              subtitle: const Text('자녀 무제한 추가 + 가족 공유'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/paywall'),
            ),
            const Divider(),
            // ── 도움말 다시 보기 ─────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: const Text('홈 화면 도움말 다시 보기'),
              subtitle: const Text('앱을 재실행하면 코치 마크가 다시 표시돼요'),
              onTap: () async {
                await OnboardingCoach.markUnseenForNextLaunch();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('다음 앱 재실행 시 도움말이 다시 표시됩니다'),
                  ),
                );
              },
            ),
            const Divider(),
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
              loading: () => const Center(child: BabyLoading()),
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

            // ── 문의 ──────────────────────────────────────────────
            const SizedBox(height: Spacing.xl),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: const Text('문의하기'),
              subtitle: const Text('support.babynote@gmail.com'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSupportMail(context),
            ),
            // ── 법적 문서 ────────────────────────────────────────
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('개인정보처리방침'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/legal/privacy'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('이용약관'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/legal/terms'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 버전'),
              trailing: const Text('1.0.0'),
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  /// 문의 메일 — mailto 스킴으로 시스템 이메일 앱 열기.
  /// 메일 앱이 없으면 주소를 클립보드에 복사하고 SnackBar로 안내.
  Future<void> _openSupportMail(BuildContext context) async {
    const address = 'support.babynote@gmail.com';
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: Uri(queryParameters: {
        'subject': 'BabyNote 문의',
        'body': '안녕하세요,\n\n[문의 내용을 적어주세요]\n\n--\n앱 버전: 1.0.0\n',
      }).query,
    );
    final launched = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!context.mounted) return;
    if (!launched) {
      // 메일 앱이 없거나 실패 → 주소 복사 fallback
      await Clipboard.setData(const ClipboardData(text: address));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메일 앱을 열 수 없어 주소를 복사했어요: $address'),
        ),
      );
    }
  }
}
