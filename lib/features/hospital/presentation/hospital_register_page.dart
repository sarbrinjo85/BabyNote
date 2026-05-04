import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isDefault = true; // 첫 등록은 보통 default

  Future<void> _submit() async {
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
          const SnackBar(content: Text('병원을 등록했어요 🏥')),
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
    final asyncCtrl = ref.watch(hospitalControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('병원 등록')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '병원 이름',
                  hintText: '예: 우리동네 소아과',
                ),
                autofocus: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '병원 이름은 필수예요.' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: Spacing.lg),

              Text('진료과', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: Spacing.xs),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pediatrics', label: Text('소아과')),
                  ButtonSegment(value: 'dental', label: Text('치과')),
                  ButtonSegment(value: 'er', label: Text('응급실')),
                  ButtonSegment(value: 'other', label: Text('기타')),
                ],
                selected: {_specialty},
                onSelectionChanged: (s) =>
                    setState(() => _specialty = s.first),
              ),
              const SizedBox(height: Spacing.lg),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  hintText: '예: 02-123-4567',
                ),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '예: 서울 강남구 테헤란로 123',
                ),
                onSaved: (v) => _address = v ?? '',
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '예: 야간 진료 가능, 친절한 의사',
                ),
                onSaved: (v) => _note = v ?? '',
                maxLines: 2,
              ),
              const SizedBox(height: Spacing.lg),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('기본 병원으로 설정'),
                subtitle: const Text('알림/원클릭 전화 등에서 우선 표시'),
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
                label: Text(isLoading ? '저장 중…' : '등록'),
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
