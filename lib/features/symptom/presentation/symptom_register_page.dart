import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/symptom.dart';
import 'symptom_providers.dart';

/// 건강 기록 등록 / 편집 — 기침 / 구토 / 발진 / 상처.
///
/// ── kind 별 UX 차이 ──────────────────────────────────────────────────
/// - cough / vomit: severity + 메모만
/// - rash / injury: severity + 메모 + 사진 (카메라/갤러리)
///
/// ── 사진 업로드 ──────────────────────────────────────────────────────
/// 저장 버튼 → SymptomController.create 가 internally 업로드 후 path 저장.
/// 저장 실패 시 토스트.
class SymptomRegisterPage extends ConsumerStatefulWidget {
  const SymptomRegisterPage({
    super.key,
    this.editing,
    this.initialKind,
  });

  final Symptom? editing;
  final SymptomKind? initialKind;

  @override
  ConsumerState<SymptomRegisterPage> createState() =>
      _SymptomRegisterPageState();
}

class _SymptomRegisterPageState extends ConsumerState<SymptomRegisterPage> {
  late SymptomKind _kind;
  late DateTime _occurredAt;
  Severity? _severity;
  File? _newPhoto; // 새로 선택한 사진(아직 미업로드)
  late final TextEditingController _noteCtrl;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _kind = e.kind;
      _occurredAt = e.occurredAt;
      _severity = e.severity;
      _noteCtrl = TextEditingController(text: e.note ?? '');
    } else {
      _kind = widget.initialKind ?? SymptomKind.cough;
      _occurredAt = DateTime.now();
      _noteCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _occurredAt = DateTime(
        _occurredAt.year,
        _occurredAt.month,
        _occurredAt.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _newPhoto = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(l10n.errorFailed(e)),
        ),
      );
    }
  }

  Future<void> _submit(String childId) async {
    final l10n = AppLocalizations.of(context);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEdit) {
      // 편집 — kind는 잠겨있어서 그대로
      final updatedBase = Symptom(
        id: widget.editing!.id,
        childId: widget.editing!.childId,
        kind: _kind,
        occurredAt: _occurredAt,
        severity: _severity,
        photoPath: widget.editing!.photoPath, // 새 사진 없으면 유지
        note: note,
        recordedBy: widget.editing!.recordedBy,
        createdAt: widget.editing!.createdAt,
      );
      await ref.read(symptomControllerProvider.notifier).saveEdit(
            symptom: updatedBase,
            newPhotoFile: _newPhoto,
          );
    } else {
      await ref.read(symptomControllerProvider.notifier).create(
            childId: childId,
            kind: _kind,
            occurredAt: _occurredAt,
            severity: _severity,
            photoFile: _kind.supportsPhoto ? _newPhoto : null,
            note: note,
          );
    }
    if (!mounted) return;
    final state = ref.read(symptomControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(
                _isEdit ? l10n.recordEditSaved : l10n.symptomSavedToast),
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

  String _kindLabel(AppLocalizations l10n, SymptomKind k) {
    switch (k) {
      case SymptomKind.cough:
        return l10n.symptomKindCough;
      case SymptomKind.vomit:
        return l10n.symptomKindVomit;
      case SymptomKind.rash:
        return l10n.symptomKindRash;
      case SymptomKind.injury:
        return l10n.symptomKindInjury;
    }
  }

  String _severityLabel(AppLocalizations l10n, Severity s) {
    switch (s) {
      case Severity.mild:
        return l10n.symptomSeverityMild;
      case Severity.moderate:
        return l10n.symptomSeverityModerate;
      case Severity.severe:
        return l10n.symptomSeveritySevere;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCtrl = ref.watch(symptomControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.symptomEditTitle : l10n.symptomTitle),
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
                Row(
                  children: [
                    const Icon(Icons.child_care),
                    const SizedBox(width: Spacing.xs),
                    Text(child.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // ── kind 토글 ────────────────────────────────────
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: SymptomKind.values.map((k) {
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

                // ── 발생 시각 ────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(l10n.symptomOccurredAtLabel),
                  subtitle: Text(
                    '${_occurredAt.hour.toString().padLeft(2, '0')}:'
                    '${_occurredAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickTime,
                ),
                const SizedBox(height: Spacing.sm),

                // ── severity 선택 ────────────────────────────────
                Text(l10n.symptomSeverityLabel,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: Spacing.xxs),
                Wrap(
                  spacing: Spacing.xs,
                  children: Severity.values.map((s) {
                    final sel = _severity == s;
                    return ChoiceChip(
                      label: Text(_severityLabel(l10n, s)),
                      selected: sel,
                      onSelected: (selected) {
                        setState(() => _severity = selected ? s : null);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: Spacing.md),

                // ── 사진 (발진/상처만) ────────────────────────────
                if (_kind.supportsPhoto) ...[
                  Text(l10n.symptomPhotoLabel,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xxs),
                  _PhotoPickerCard(
                    newPhoto: _newPhoto,
                    existingPath: widget.editing?.photoPath,
                    onPickCamera: () => _pickPhoto(ImageSource.camera),
                    onPickGallery: () => _pickPhoto(ImageSource.gallery),
                    onRemove: () => setState(() => _newPhoto = null),
                  ),
                  const SizedBox(height: Spacing.md),
                ],

                // ── 메모 ────────────────────────────────────────
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.symptomNoteLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                FilledButton.icon(
                  onPressed: isLoading ? null : () => _submit(child.id),
                  icon: const Icon(Icons.save),
                  label: Text(_isEdit
                      ? l10n.recordEditSaved
                      : l10n.symptomTitle),
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

/// 사진 선택 카드 — 미선택 시 두 버튼(카메라/갤러리), 선택 후 미리보기 + 제거.
class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.newPhoto,
    required this.existingPath,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  final File? newPhoto;
  final String? existingPath;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasNew = newPhoto != null;
    final hasExisting = existingPath != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasNew)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  newPhoto!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              )
            else if (hasExisting)
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text(existingPath!.split('/').last),
                dense: true,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Center(
                  child: Text(
                    l10n.symptomPhotoPick,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickCamera,
                    icon: const Icon(Icons.photo_camera),
                    label: Text(l10n.symptomPhotoFromCamera),
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.symptomPhotoFromGallery),
                  ),
                ),
              ],
            ),
            if (hasNew) ...[
              const SizedBox(height: Spacing.xs),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
                label: Text(l10n.symptomPhotoRemove),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
