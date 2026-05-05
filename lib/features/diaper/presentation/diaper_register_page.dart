import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../domain/diaper.dart';
import 'diaper_providers.dart';

/// 기저귀 기록 화면.
///
/// ── 화면 구성 ────────────────────────────────────────────────────────
/// 종류(소변/대변/둘다) → 색상(7개) → 형태(묽음/보통/단단함, 대변 포함 시만) → 메모 → 등록
///
/// 이상 색상(빨강/검정/흰색) 선택 시 경고 카드 표시 (의사 상담 권장).
class DiaperRegisterPage extends ConsumerStatefulWidget {
  const DiaperRegisterPage({super.key, this.editing});

  final Diaper? editing;

  @override
  ConsumerState<DiaperRegisterPage> createState() =>
      _DiaperRegisterPageState();
}

class _DiaperRegisterPageState extends ConsumerState<DiaperRegisterPage> {
  late String _type;
  String? _color;
  String? _consistency;
  String? _amount;
  late final TextEditingController _noteCtrl;

  bool get _isEdit => widget.editing != null;
  bool get _showColorAndConsistency => _type == 'poop' || _type == 'both';

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _type = e.type;
      _color = e.color;
      _consistency = e.consistency;
      _amount = e.amount;
      _noteCtrl = TextEditingController(text: e.note ?? '');
    } else {
      _type = 'pee';
      _noteCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String childId) async {
    final l10n = AppLocalizations.of(context);
    final noteText = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    if (_isEdit) {
      await ref.read(diaperCreationControllerProvider.notifier).saveEdit(
            childId: childId,
            id: widget.editing!.id,
            type: _type,
            color: _color,
            consistency: _consistency,
            amount: _amount,
            note: noteText,
          );
    } else {
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
            note: noteText,
          );
    }
    if (!mounted) return;
    final state = ref.read(diaperCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l10n.recordEditSaved : l10n.diaperSavedToast)),
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
    final asyncCtrl = ref.watch(diaperCreationControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.diaperEditTitle : l10n.diaperTitle),
        actions: _isEdit ? null : const [ChildPickerAction()],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = _isEdit
              ? children.firstWhere(
                  (c) => c.id == widget.editing!.childId,
                  orElse: () => children.first,
                )
              : (ref.watch(selectedChildProvider) ?? children.first);
          final isAbnormal =
              _color == 'red' || _color == 'black' || _color == 'white';

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
                    Text(child.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // ── 활성 기저귀 팩 카드 ────────────────────────
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
                                    Text(l10n.feedingInUse,
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
                              Text(l10n.feedingAutoSubtract,
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
                              Expanded(
                                child: Text(l10n.diaperNoActivePack),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── 종류 ────────────────────────────────────────────
                Text(l10n.diaperType, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: Spacing.xs),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'pee',
                      icon: const Text('💧'),
                      label: Text(l10n.diaperPee),
                    ),
                    ButtonSegment(
                      value: 'poop',
                      icon: const Text('💩'),
                      label: Text(l10n.diaperPoop),
                    ),
                    ButtonSegment(
                      value: 'both',
                      icon: const Text('💧💩'),
                      label: Text(l10n.diaperBoth),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) =>
                      setState(() => _type = s.first),
                ),

                if (_showColorAndConsistency) ...[
                  const SizedBox(height: Spacing.lg),
                  Text(l10n.diaperColor, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: _colorOptions(l10n).map((opt) {
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
                                l10n.diaperColorAbnormalWarn,
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
                  Text(l10n.diaperConsistency, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: [
                      ButtonSegment(value: 'loose', label: Text(l10n.diaperLoose)),
                      ButtonSegment(value: 'normal', label: Text(l10n.diaperNormal)),
                      ButtonSegment(value: 'firm', label: Text(l10n.diaperFirm)),
                    ],
                    selected: _consistency == null ? {} : {_consistency!},
                    onSelectionChanged: (s) => setState(
                        () => _consistency = s.isEmpty ? null : s.first),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(l10n.diaperAmount, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: [
                      ButtonSegment(value: 'small', label: Text(l10n.diaperSmall)),
                      ButtonSegment(value: 'normal', label: Text(l10n.diaperNormal)),
                      ButtonSegment(value: 'large', label: Text(l10n.diaperLarge)),
                    ],
                    selected: _amount == null ? {} : {_amount!},
                    onSelectionChanged: (s) =>
                        setState(() => _amount = s.isEmpty ? null : s.first),
                  ),
                ],

                const SizedBox(height: Spacing.lg),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.commonMemoOptional,
                    hintText: l10n.diaperMemoHint,
                  ),
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
                  label: Text(isLoading
                      ? l10n.commonSaving
                      : (_isEdit ? l10n.commonSave : l10n.commonRegister)),
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

class _ColorOption {
  const _ColorOption(this.value, this.label, this.emoji);
  final String value;
  final String label;
  final String emoji;
}

List<_ColorOption> _colorOptions(AppLocalizations l10n) => [
      _ColorOption('yellow', l10n.diaperColorYellow, '🟡'),
      _ColorOption('brown', l10n.diaperColorBrown, '🟤'),
      _ColorOption('green', l10n.diaperColorGreen, '🟢'),
      _ColorOption('black', l10n.diaperColorBlack, '⚫'),
      _ColorOption('red', l10n.diaperColorRed, '🔴'),
      _ColorOption('white', l10n.diaperColorWhite, '⚪'),
      _ColorOption('unknown', l10n.diaperColorUnknown, '❓'),
    ];

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
