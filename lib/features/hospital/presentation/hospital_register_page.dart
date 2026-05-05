import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../domain/hospital.dart';
import 'hospital_name_autocomplete.dart';
import 'hospital_providers.dart';

class HospitalRegisterPage extends ConsumerStatefulWidget {
  const HospitalRegisterPage({super.key, this.editing});

  final Hospital? editing;

  @override
  ConsumerState<HospitalRegisterPage> createState() =>
      _HospitalRegisterPageState();
}

class _HospitalRegisterPageState extends ConsumerState<HospitalRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // 자동완성 후 phone/address controller에도 즉시 반영하려면 controller 패턴 필요.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late String _specialty;
  late String _note;
  late bool _isDefault;
  // Places 선택 시 받은 좌표 (저장은 추후 — 현재 Hospital domain 사용)
  double? _latitude;
  double? _longitude;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _specialty = e?.specialty ?? 'pediatrics';
    _note = e?.note ?? '';
    _isDefault = e?.isDefault ?? true;
    _latitude = e?.latitude;
    _longitude = e?.longitude;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (_isEdit) {
      await ref.read(hospitalControllerProvider.notifier).saveEdit(
            id: widget.editing!.id,
            name: name,
            specialty: _specialty,
            phone: phone.isEmpty ? null : phone,
            address: address.isEmpty ? null : address,
            note: _note.trim().isEmpty ? null : _note.trim(),
            isDefault: _isDefault,
          );
    } else {
      await ref.read(hospitalControllerProvider.notifier).create(
            name: name,
            specialty: _specialty,
            phone: phone.isEmpty ? null : phone,
            address: address.isEmpty ? null : address,
            latitude: _latitude,
            longitude: _longitude,
            note: _note.trim().isEmpty ? null : _note.trim(),
            isDefault: _isDefault,
          );
    }
    if (!mounted) return;
    final state = ref.read(hospitalControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l10n.recordEditSaved : l10n.hospitalSavedToast)),
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
      appBar: AppBar(
        title: Text(_isEdit ? l10n.hospitalEditTitle : l10n.hospitalRegisterTitle),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              HospitalNameAutocomplete(
                controller: _nameCtrl,
                autofocus: !_isEdit,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.hospitalNameRequired : null,
                onPlaceSelected: (details) {
                  // 자동완성 결과 → phone/address/lat/lng 자동 채움
                  setState(() {
                    if (details.phoneNumber != null &&
                        details.phoneNumber!.isNotEmpty) {
                      _phoneCtrl.text = details.phoneNumber!;
                    }
                    if (details.formattedAddress != null &&
                        details.formattedAddress!.isNotEmpty) {
                      _addressCtrl.text = details.formattedAddress!;
                    }
                    _latitude = details.latitude;
                    _longitude = details.longitude;
                  });
                },
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
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: l10n.hospitalPhone,
                  hintText: l10n.hospitalPhoneHint,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: l10n.hospitalAddress,
                  hintText: l10n.hospitalAddressHint,
                ),
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                initialValue: _note,
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
                label: Text(isLoading
                    ? l10n.commonSaving
                    : (_isEdit ? l10n.commonSave : l10n.commonRegister)),
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
