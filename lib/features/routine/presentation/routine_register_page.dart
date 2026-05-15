import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/routine.dart';
import 'routine_providers.dart';

/// 루틴 기록 등록 / 편집 화면 — 산책 / 목욕 / 영양제 / 간식 4종 통합.
///
/// ── 흐름 ─────────────────────────────────────────────────────────────
/// 1. 상단 4-chip toggle 로 kind 선택 (편집 모드에선 잠금)
/// 2. 기록 시각 (default = now, 탭하면 time picker 로 수정)
/// 3. kind 별 추가 필드:
///    - 산책/목욕: 지속 시간(분) — 숫자 키패드
///    - 영양제/간식: 이름 — 텍스트
/// 4. 메모 (선택)
/// 5. 저장 버튼
///
/// ── 초기 kind 결정 ────────────────────────────────────────────────────
/// - 편집 모드(`editing != null`): 기존 기록의 kind 그대로
/// - 신규 + initialKind 전달됨: 해당 kind 선택
/// - 신규 + initialKind 없음: walk(산책) 기본값
class RoutineRegisterPage extends ConsumerStatefulWidget {
  const RoutineRegisterPage({
    super.key,
    this.editing,
    this.initialKind,
  });

  final Routine? editing;
  final RoutineKind? initialKind;

  @override
  ConsumerState<RoutineRegisterPage> createState() =>
      _RoutineRegisterPageState();
}

class _RoutineRegisterPageState extends ConsumerState<RoutineRegisterPage> {
  late RoutineKind _kind;
  late DateTime _startedAt;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _noteCtrl;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _kind = e.kind;
      _startedAt = e.startedAt;
      _durationCtrl =
          TextEditingController(text: e.durationMin?.toString() ?? '');
      _itemNameCtrl = TextEditingController(text: e.itemName ?? '');
      _noteCtrl = TextEditingController(text: e.note ?? '');
    } else {
      _kind = widget.initialKind ?? RoutineKind.walk;
      _startedAt = DateTime.now();
      _durationCtrl = TextEditingController();
      _itemNameCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _itemNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _startedAt = DateTime(
        _startedAt.year,
        _startedAt.month,
        _startedAt.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _submit(String childId) async {
    final l10n = AppLocalizations.of(context);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final duration = _kind.usesDuration
        ? int.tryParse(_durationCtrl.text.trim())
        : null;
    final itemName = _kind.usesItemName && _itemNameCtrl.text.trim().isNotEmpty
        ? _itemNameCtrl.text.trim()
        : null;

    if (_isEdit) {
      final updated = Routine(
        id: widget.editing!.id,
        childId: widget.editing!.childId,
        kind: _kind, // kind는 잠겨있어서 그대로
        startedAt: _startedAt,
        durationMin: duration,
        itemName: itemName,
        note: note,
        recordedBy: widget.editing!.recordedBy,
        createdAt: widget.editing!.createdAt,
      );
      await ref
          .read(routineControllerProvider.notifier)
          .saveEdit(routine: updated);
    } else {
      await ref.read(routineControllerProvider.notifier).create(
            childId: childId,
            kind: _kind,
            startedAt: _startedAt,
            durationMin: duration,
            itemName: itemName,
            note: note,
          );
    }
    if (!mounted) return;
    final state = ref.read(routineControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(
                _isEdit ? l10n.recordEditSaved : l10n.routineSavedToast),
          ),
        );
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(l10n.errorFailed(err)),
          ),
        );
      },
    );
  }

  String _kindLabel(AppLocalizations l10n, RoutineKind k) {
    switch (k) {
      case RoutineKind.walk:
        return l10n.routineKindWalk;
      case RoutineKind.bath:
        return l10n.routineKindBath;
      case RoutineKind.supplement:
        return l10n.routineKindSupplement;
      case RoutineKind.snack:
        return l10n.routineKindSnack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCtrl = ref.watch(routineControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.routineEditTitle : l10n.routineTitle),
        actions: _isEdit ? null : const [ChildPickerAction()],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: BabyLoading()),
        error: (err, _) =>
            Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(l10n.homeAddChild),
              ),
            );
          }
          final child = _isEdit
              ? children.firstWhere(
                  (c) => c.id == widget.editing!.childId,
                  orElse: () => children.first,
                )
              : (ref.watch(selectedChildProvider) ?? children.first);

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                // 자녀 이름
                Row(
                  children: [
                    const Icon(Icons.child_care),
                    const SizedBox(width: Spacing.xs),
                    Text(child.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // ── kind 토글 (편집 모드면 잠금) ──────────────────
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: RoutineKind.values.map((k) {
                    final selected = k == _kind;
                    return ChoiceChip(
                      label: Text('${k.emoji} ${_kindLabel(l10n, k)}'),
                      selected: selected,
                      onSelected: _isEdit
                          ? null
                          : (sel) {
                              if (sel) setState(() => _kind = k);
                            },
                      selectedColor: const Color(0xFFFFB5A7),
                      labelStyle: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? const Color(0xFFA43F45)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: Spacing.md),

                // ── 기록 시각 ────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(l10n.routineStartedAtLabel),
                  subtitle: Text(
                    '${_startedAt.hour.toString().padLeft(2, '0')}:'
                    '${_startedAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickTime,
                ),
                const SizedBox(height: Spacing.sm),

                // ── kind 별 추가 필드 ────────────────────────────
                if (_kind.usesDuration)
                  TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.routineDurationLabel,
                      hintText: l10n.routineDurationHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (_kind.usesItemName)
                  TextField(
                    controller: _itemNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.routineItemNameLabel,
                      hintText: _kind == RoutineKind.supplement
                          ? l10n.routineItemNameHintSupplement
                          : l10n.routineItemNameHintSnack,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: Spacing.sm),

                // ── 메모 ────────────────────────────────────────
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.routineNoteLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── 저장 ────────────────────────────────────────
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _submit(child.id),
                  icon: const Icon(Icons.save),
                  label: Text(_isEdit
                      ? l10n.recordEditSaved
                      : l10n.routineTitle),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(TouchTarget.comfortable),
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
