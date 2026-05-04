import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import 'diaper_providers.dart';

/// 기저귀 기록 화면.
///
/// ── 화면 구성 ────────────────────────────────────────────────────────
/// 종류(소변/대변/둘다) → 색상(7개) → 형태(묽음/보통/단단함, 대변 포함 시만) → 메모 → 등록
///
/// 이상 색상(빨강/검정/흰색) 선택 시 경고 카드 표시 (의사 상담 권장).
class DiaperRegisterPage extends ConsumerStatefulWidget {
  const DiaperRegisterPage({super.key});

  @override
  ConsumerState<DiaperRegisterPage> createState() =>
      _DiaperRegisterPageState();
}

class _DiaperRegisterPageState extends ConsumerState<DiaperRegisterPage> {
  String _type = 'pee';        // 'pee' | 'poop' | 'both'
  String? _color;              // null = 미선택
  String? _consistency;        // null = 미선택 (묽음/보통/단단함 — 형태)
  String? _amount;             // null = 미선택 (조금/보통/많음 — 분량)
  String _note = '';

  // 대변이 포함된 경우(=poop or both) 색상/형태 입력 필요.
  bool get _showColorAndConsistency => _type == 'poop' || _type == 'both';

  Future<void> _submit(String childId) async {
    // FIFO: 활성 기저귀 팩 첫 번째에 자동 연결.
    String? diaperInventoryId;
    final actives = ref.read(activeDiaperInventoriesProvider(childId));
    actives.whenData((list) {
      if (list.isNotEmpty) diaperInventoryId = list.first.id;
    });

    await ref.read(diaperCreationControllerProvider.notifier).create(
          childId: childId,
          type: _type,
          color: _color,
          consistency: _consistency,
          amount: _amount,
          diaperInventoryId: diaperInventoryId,
          note: _note.trim().isEmpty ? null : _note.trim(),
        );
    if (!mounted) return;
    final state = ref.read(diaperCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기저귀 기록을 저장했어요 💩')),
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
    final asyncCtrl = ref.watch(diaperCreationControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('기저귀 기록')),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('자녀 목록 로딩 실패: $err')),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = children.first;
          final isAbnormal =
              _color == 'red' || _color == 'black' || _color == 'white';

          // 활성 기저귀 팩 watch — 표시 + 자동 차감 연결
          final asyncActiveDiaper =
              ref.watch(activeDiaperInventoriesProvider(child.id));
          final activeDiaper = asyncActiveDiaper.maybeWhen(
            data: (list) => list.isEmpty ? null : list.first,
            orElse: () => null,
          );

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                Row(
                  children: [
                    const Icon(Icons.child_care),
                    const SizedBox(width: Spacing.xs),
                    Text('${child.name} 자녀',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // ── 활성 기저귀 팩 카드 (P3-2b) ────────────────────────
                Card(
                  color: activeDiaper != null
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: activeDiaper != null
                        ? Row(
                            children: [
                              const Text('🧷', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: Spacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('사용 중',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium),
                                    Text(
                                      '${activeDiaper.size} · ${activeDiaper.brand ?? ""}'
                                          .trim()
                                          .replaceAll(RegExp(r'·\s*$'), ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text('등록 시 자동 차감',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined),
                              const SizedBox(width: Spacing.sm),
                              const Expanded(
                                child: Text(
                                    '사용 중인 기저귀 팩이 없어요.\n등록 후 자동으로 차감됩니다.'),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── 종류 ────────────────────────────────────────────
                Text('종류', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: Spacing.xs),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'pee',
                      icon: Text('💧'),
                      label: Text('소변'),
                    ),
                    ButtonSegment(
                      value: 'poop',
                      icon: Text('💩'),
                      label: Text('대변'),
                    ),
                    ButtonSegment(
                      value: 'both',
                      icon: Text('💧💩'),
                      label: Text('둘다'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) =>
                      setState(() => _type = s.first),
                ),

                if (_showColorAndConsistency) ...[
                  const SizedBox(height: Spacing.lg),
                  Text('색상', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: _ColorOption.all.map((opt) {
                      return ChoiceChip(
                        label: Text('${opt.emoji} ${opt.label}'),
                        selected: _color == opt.value,
                        onSelected: (sel) =>
                            setState(() => _color = sel ? opt.value : null),
                      );
                    }).toList(),
                  ),
                  if (isAbnormal) ...[
                    const SizedBox(height: Spacing.sm),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded),
                            const SizedBox(width: Spacing.xs),
                            Expanded(
                              child: Text(
                                '이상 색상이에요. 가능한 빨리 의사와 상담을 권해드려요.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.lg),
                  Text('형태', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(value: 'loose', label: Text('묽음')),
                      ButtonSegment(value: 'normal', label: Text('보통')),
                      ButtonSegment(value: 'firm', label: Text('단단함')),
                    ],
                    selected: _consistency == null ? {} : {_consistency!},
                    onSelectionChanged: (s) => setState(
                        () => _consistency = s.isEmpty ? null : s.first),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text('양', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(value: 'small', label: Text('조금')),
                      ButtonSegment(value: 'normal', label: Text('보통')),
                      ButtonSegment(value: 'large', label: Text('많음')),
                    ],
                    selected: _amount == null ? {} : {_amount!},
                    onSelectionChanged: (s) =>
                        setState(() => _amount = s.isEmpty ? null : s.first),
                  ),
                ],

                const SizedBox(height: Spacing.lg),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '메모 (선택)',
                    hintText: '예: 평소보다 양 많음',
                  ),
                  onChanged: (v) => _note = v,
                  maxLines: 2,
                ),

                const SizedBox(height: Spacing.xl),
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _submit(child.id),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isLoading ? '저장 중…' : '등록'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(TouchTarget.huge),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 색상 옵션 정의 (DB 값 + 한국어 라벨 + 이모지).
class _ColorOption {
  const _ColorOption(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;

  static const all = [
    _ColorOption('yellow', '노랑', '🟡'),
    _ColorOption('brown', '갈색', '🟤'),
    _ColorOption('green', '녹색', '🟢'),
    _ColorOption('black', '검정', '⚫'),
    _ColorOption('red', '빨강', '🔴'),
    _ColorOption('white', '흰색', '⚪'),
    _ColorOption('unknown', '모름', '❓'),
  ];
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
