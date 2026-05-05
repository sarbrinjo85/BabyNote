import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/sleep.dart';
import 'sleep_providers.dart';

/// 수면 기록 화면.
///
/// ── 화면 분기 ────────────────────────────────────────────────────────
/// 진행 중 수면이 있으면 → "자고 있어요" 카드 + "지금 깼어요" 버튼
/// 없으면 → "잠들었어요" 큰 버튼 + 낮/밤 선택 + 메모
///
/// 자녀 여러 명 처리는 Phase 2 후반(자녀 선택 UI). 지금은 첫 자녀 자동 사용.
class SleepRegisterPage extends ConsumerStatefulWidget {
  const SleepRegisterPage({super.key});

  @override
  ConsumerState<SleepRegisterPage> createState() => _SleepRegisterPageState();
}

class _SleepRegisterPageState extends ConsumerState<SleepRegisterPage> {
  // 시작용 폼 상태
  late String _napOrNight;
  String _note = '';

  @override
  void initState() {
    super.initState();
    // 현재 시각 기준 자동 판정 (19~07시 = night)
    _napOrNight = Sleep.classifyNapOrNight(DateTime.now());
  }

  Future<void> _start(String childId) async {
    await ref.read(sleepControllerProvider.notifier).startSleep(
          childId: childId,
          napOrNight: _napOrNight,
          note: _note.trim().isEmpty ? null : _note.trim(),
        );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(sleepControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sleepStartedToast)),
        );
        // 시작 후엔 그대로 같은 화면 유지 (진행 중 카드로 자동 전환)
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorFailed(err))));
      },
    );
  }

  Future<void> _end(String childId, String sleepId) async {
    await ref.read(sleepControllerProvider.notifier).endSleep(
          childId: childId,
          sleepId: sleepId,
        );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(sleepControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sleepFinishedToast)),
        );
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorFailed(err))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCtrl = ref.watch(sleepControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sleepTitle),
        actions: const [ChildPickerAction()],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = ref.watch(selectedChildProvider) ?? children.first;

          // 진행 중 수면 watch — 시작/종료 시점에 invalidate되어 자동 갱신
          final asyncOngoing = ref.watch(ongoingSleepProvider(child.id));

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: asyncOngoing.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text(l10n.sleepInProgressLoadFailure(err))),
                data: (ongoing) {
                  if (ongoing == null) {
                    return _StartForm(
                      childName: child.name,
                      napOrNight: _napOrNight,
                      isLoading: isLoading,
                      onNapOrNightChanged: (v) =>
                          setState(() => _napOrNight = v),
                      onNoteChanged: (v) => _note = v,
                      onStart: () => _start(child.id),
                    );
                  }
                  return _OngoingCard(
                    childName: child.name,
                    sleep: ongoing,
                    isLoading: isLoading,
                    onEnd: () => _end(child.id, ongoing.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 시작 폼 (수면 진행 중 아닐 때).
class _StartForm extends StatelessWidget {
  const _StartForm({
    required this.childName,
    required this.napOrNight,
    required this.isLoading,
    required this.onNapOrNightChanged,
    required this.onNoteChanged,
    required this.onStart,
  });

  final String childName;
  final String napOrNight;
  final bool isLoading;
  final ValueChanged<String> onNapOrNightChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Row(
          children: [
            const Icon(Icons.child_care),
            const SizedBox(width: Spacing.xs),
            Text(childName,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Text(l10n.sleepNapNight, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'nap', label: Text(l10n.sleepNap)),
            ButtonSegment(value: 'night', label: Text(l10n.sleepNight)),
          ],
          selected: {napOrNight},
          onSelectionChanged: (s) => onNapOrNightChanged(s.first),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.commonMemoOptional,
            hintText: l10n.sleepMemoHint,
          ),
          onChanged: onNoteChanged,
          maxLines: 2,
        ),
        const SizedBox(height: Spacing.xl),
        FilledButton.icon(
          onPressed: isLoading ? null : onStart,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bedtime),
          label: Text(isLoading ? l10n.sleepStarting : l10n.sleepGoToSleep),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(TouchTarget.huge),
          ),
        ),
      ],
    );
  }
}

/// 진행 중 카드 (수면 진행 중일 때).
class _OngoingCard extends StatelessWidget {
  const _OngoingCard({
    required this.childName,
    required this.sleep,
    required this.isLoading,
    required this.onEnd,
  });

  final String childName;
  final Sleep sleep;
  final bool isLoading;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final elapsed = sleep.elapsedMinutes(DateTime.now());
    final hours = elapsed ~/ 60;
    final mins = elapsed % 60;
    final elapsedText = hours > 0
        ? '${hours}h ${mins}m'
        : l10n.sleepDurationMinutes(mins);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💤', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        sleep.napOrNight == 'night'
                            ? l10n.sleepNightInProgress
                            : l10n.sleepNapInProgress,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                _Row(
                  label: l10n.sleepStartLabel,
                  value: _formatTime(sleep.startedAt),
                ),
                const SizedBox(height: Spacing.xs),
                _Row(
                  label: l10n.sleepElapsed,
                  value: elapsedText,
                ),
                const SizedBox(height: Spacing.xs),
                _Row(
                  label: l10n.sleepKindLabel,
                  value: sleep.napOrNight == 'night' ? l10n.sleepNight : l10n.sleepNap,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        FilledButton.icon(
          onPressed: isLoading ? null : onEnd,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.alarm),
          label: Text(isLoading ? l10n.sleepFinishing : l10n.sleepWakeUp),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(TouchTarget.huge),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _NoChildPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            Text(l10n.commonRegisterChildFirst),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push('/child/new');
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.commonGoRegisterChild),
            ),
          ],
        ),
      ),
    );
  }
}
