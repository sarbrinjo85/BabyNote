import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import 'hospital_providers.dart';

class HospitalRegisterPage extends ConsumerStatefulWidget {
  const HospitalRegisterPage({super.key});

  @override
  ConsumerState<HospitalRegisterPage> createState() =>
      _HospitalRegisterPageState();
}

class _HospitalRegisterPageState extends ConsumerState<HospitalRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _specialty = 'pediatrics';
  String _phone = '';
  String _address = '';
  String _note = '';
  bool _isDefault = true;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    await ref.read(hospitalControllerProvider.notifier).create(
          name: _name.trim(),
          specialty: _specialty,
          phone: _phone.trim().isEmpty ? null : _phone.trim(),
          address: _address.trim().isEmpty ? null : _address.trim(),
          note: _note.trim().isEmpty ? null : _note.trim(),
          isDefault: _isDefault,
        );
    if (!mounted) return;
    final state = ref.read(hospitalControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.hospitalSavedToast)),
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
    final asyncCtrl = ref.watch(hospitalControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hospitalRegisterTitle)),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.hospitalNameLabel,
                  hintText: l10n.hospitalNameHint,
                ),
                autofocus: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.hospitalNameRequired : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: Spacing.lg),

              Text(l10n.hospitalSpecialty, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: Spacing.xs),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'pediatrics', label: Text(l10n.hospitalSpecialtyPediatrics)),
                  ButtonSegment(value: 'dental', label: Text(l10n.hospitalSpecialtyDental)),
                  ButtonSegment(value: 'er', label: Text(l10n.hospitalSpecialtyER)),
                  ButtonSegment(value: 'other', label: Text(l10n.hospitalSpecialtyOther)),
                ],
                selected: {_specialty},
                onSelectionChanged: (s) =>
                    setState(() => _specialty = s.first),
              ),
              const SizedBox(height: Spacing.lg),

              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.hospitalPhone,
                  hintText: l10n.hospitalPhoneHint,
                ),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.hospitalAddress,
                  hintText: l10n.hospitalAddressHint,
                ),
                onSaved: (v) => _address = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.commonMemoOptional,
                  hintText: l10n.hospitalMemoHint,
                ),
                onSaved: (v) => _note = v ?? '',
                maxLines: 2,
              ),
              const SizedBox(height: Spacing.lg),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hospitalDefaultTitle),
                subtitle: Text(l10n.hospitalDefaultSubtitle),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),

              const SizedBox(height: Spacing.xl),
              FilledButton.icon(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(isLoading ? l10n.commonSaving : l10n.commonRegister),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(TouchTarget.huge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
