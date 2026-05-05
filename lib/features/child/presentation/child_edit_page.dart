import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../domain/child.dart';
import 'child_providers.dart';

/// 자녀 편집 화면.
///
/// 라우터로 진입할 때 `extra`에 Child 객체를 담아 전달.
/// 폼은 기존 등록 화면과 동일하지만 모든 필드가 prefilled.
/// 하단에 [저장] + [삭제] 두 버튼.
class ChildEditPage extends ConsumerStatefulWidget {
  const ChildEditPage({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<ChildEditPage> createState() => _ChildEditPageState();
}

class _ChildEditPageState extends ConsumerState<ChildEditPage> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _gender;
  late DateTime _birthDate;
  late String _weightKg;
  late String _heightCm;

  @override
  void initState() {
    super.initState();
    final c = widget.child;
    _name = c.name;
    _gender = c.gender ?? 'female';
    _birthDate = c.birthDate;
    _weightKg = c.birthWeightG != null
        ? (c.birthWeightG! / 1000).toStringAsFixed(2)
        : '';
    _heightCm = c.birthHeightMm != null
        ? (c.birthHeightMm! / 10).toStringAsFixed(1)
        : '';
  }

  Future<void> _pickBirthDate() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: l10n.childBirthDateHelp,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final w = double.tryParse(_weightKg);
    final h = double.tryParse(_heightCm);

    await ref.read(childEditControllerProvider.notifier).save(
          id: widget.child.id,
          name: _name.trim(),
          birthDate: _birthDate,
          gender: _gender,
          birthWeightG: w != null ? (w * 1000).round() : null,
          birthHeightMm: h != null ? (h * 10).round() : null,
        );

    if (!mounted) return;
    final state = ref.read(childEditControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.childEditSaved)),
        );
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorFailed(err))),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.childDeleteTitle),
        content: Text(l10n.childDeleteWarning(widget.child.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;

    await ref
        .read(childEditControllerProvider.notifier)
        .delete(widget.child.id);

    if (!mounted) return;
    final state = ref.read(childEditControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.childDeleted)),
        );
        context.go('/'); // 홈으로 (편집 → 자녀 등록 → 등 stack 다 정리)
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorFailed(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(childEditControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.childEditTitle)),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: l10n.childName,
                  hintText: l10n.childNameHint,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.childNameRequired
                    : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.childGender),
                initialValue: _gender,
                items: [
                  DropdownMenuItem(
                      value: 'female', child: Text(l10n.childGenderFemale)),
                  DropdownMenuItem(
                      value: 'male', child: Text(l10n.childGenderMale)),
                  DropdownMenuItem(
                      value: 'other', child: Text(l10n.childGenderOther)),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'female'),
              ),
              const SizedBox(height: Spacing.md),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.childBirthDate),
                subtitle: Text(
                  '${_birthDate.year}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
              ),
              const Divider(),
              const SizedBox(height: Spacing.md),

              TextFormField(
                initialValue: _weightKg,
                decoration: InputDecoration(
                  labelText: l10n.childBirthWeightLabel,
                  hintText: l10n.childBirthWeightHint,
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null) return l10n.commonNumberOnly;
                  if (n < 0.5 || n > 8.0) return '0.5~8.0 kg';
                  return null;
                },
                onSaved: (v) => _weightKg = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                initialValue: _heightCm,
                decoration: InputDecoration(
                  labelText: l10n.childBirthHeightLabel,
                  hintText: l10n.childBirthHeightHint,
                  suffixText: 'cm',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null) return l10n.commonNumberOnly;
                  if (n < 30 || n > 80) return '30~80 cm';
                  return null;
                },
                onSaved: (v) => _heightCm = v ?? '',
              ),
              const SizedBox(height: Spacing.xl),

              FilledButton.icon(
                onPressed: isLoading ? null : _save,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isLoading ? l10n.commonSaving : l10n.commonSave),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(TouchTarget.huge),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _confirmDelete,
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                label: Text(
                  l10n.childDeleteAction,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(TouchTarget.standard),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
