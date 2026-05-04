import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
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
    final state = ref.read(sleepControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수면 시작! 자장자장 💤')),
        );
        // 시작 후엔 그대로 같은 화면 유지 (진행 중 카드로 자동 전환)
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('실패: $err')));
      },
    );
  }

  Future<void> _end(String childId, String sleepId) async {
    await ref.read(sleepControllerProvider.notifier).endSleep(
          childId: childId,
          sleepId: sleepId,
        );
    if (!mounted) return;
    final state = ref.read(sleepControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수면 기록 완료 ✅')),
        );
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('실패: $err')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCtrl = ref.watch(sleepControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('수면 기록')),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('자녀 목록 로딩 실패: $err')),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = children.first;

          // 진행 중 수면 watch — 시작/종료 시점에 invalidate되어 자동 갱신
          final asyncOngoing = ref.watch(ongoingSleepProvider(child.id));

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: asyncOngoing.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('진행 중 수면 조회 실패: $err')),
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
    return ListView(
      children: [
        Row(
          children: [
            const Icon(Icons.child_care),
            const SizedBox(width: Spacing.xs),
            Text('$childName 자녀',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Text('낮잠/밤잠', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'nap', label: Text('낮잠')),
            ButtonSegment(value: 'night', label: Text('밤잠')),
          ],
          selected: {napOrNight},
          onSelectionChanged: (s) => onNapOrNightChanged(s.first),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '※ 19시~07시는 자동 밤잠 판정 (수정 가능)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          decoration: const InputDecoration(
            labelText: '메모 (선택)',
            hintText: '예: 안고 재움, 모빌 보다가 잠듦',
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
          label: Text(isLoading ? '시작 중…' : '잠들었어요'),
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
    final cs = Theme.of(context).colorScheme;
    final elapsed = sleep.elapsedMinutes(DateTime.now());
    final hours = elapsed ~/ 60;
    final mins = elapsed % 60;
    final elapsedText = hours > 0 ? '$hours시간 $mins분' : '$mins분';

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
                    Text('💤', style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        '$childName 자녀가 자고 있어요',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                _Row(
                  label: '시작',
                  value: _formatTime(sleep.startedAt),
                ),
                const SizedBox(height: Spacing.xs),
                _Row(
                  label: '경과',
                  value: elapsedText,
                ),
                const SizedBox(height: Spacing.xs),
                _Row(
                  label: '구분',
                  value: sleep.napOrNight == 'night' ? '밤잠' : '낮잠',
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
          label: Text(isLoading ? '종료 중…' : '지금 깼어요'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            const Text('먼저 자녀를 등록해주세요.'),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push('/child/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('자녀 등록하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
