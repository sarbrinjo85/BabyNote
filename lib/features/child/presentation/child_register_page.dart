import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import 'child_providers.dart';

/// 자녀 등록 화면.
///
/// ── 학습 포인트 ───────────────────────────────────────────────────
/// 1. Form + `GlobalKey<FormState>` + validator: 폼 검증의 표준 Flutter 패턴
/// 2. TextFormField: validator + onSaved 콜백 + InputDecoration
/// 3. showDatePicker: Material 표준 날짜 선택기
/// 4. AsyncNotifier(ChildCreationController) 호출 + state 구독으로 진행/에러 표시
/// 5. SnackBar: 일시적 알림(Material 표준)
class ChildRegisterPage extends ConsumerStatefulWidget {
  const ChildRegisterPage({super.key});

  @override
  ConsumerState<ChildRegisterPage> createState() => _ChildRegisterPageState();
}

/// ── ConsumerStatefulWidget을 쓴 이유 ────────────────────────────────
/// 폼은 사용자 입력(텍스트 컨트롤러, 선택한 생일 등)을 위젯 state에 유지해야 해서
/// StatefulWidget이 자연스러움. ConsumerStatefulWidget = StatefulWidget + Riverpod ref.
class _ChildRegisterPageState extends ConsumerState<ChildRegisterPage> {
  // GlobalKey: 위젯 트리 어디서든 같은 widget/state 인스턴스를 참조하게 해주는 키.
  // FormState 메서드(validate, save 등)를 호출하려면 필요.
  final _formKey = GlobalKey<FormState>();

  // 폼 입력값을 보관하는 일반 변수들. TextEditingController도 가능하지만
  // 학습 단순화를 위해 onSaved 콜백 + 멤버 변수 패턴 사용.
  String _name = '';
  String _gender = 'female'; // 기본값
  DateTime? _birthDate;
  String _weightKg = '';
  String _heightCm = '';

  /// 날짜 선택기 띄우기 → 결과 받아서 _birthDate에 저장.
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    // 직접 입력 시 Korean locale 포맷 "yyyy. M. d." 만 허용되어 사용자가
    // 다른 형식으로 치면 파싱 실패 → fieldHintText/errorFormatText로 명시.
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 5), // 5년 전까지만 (너무 큰 아이는 앱 타겟 외)
      lastDate: now, // 미래 날짜 차단
      helpText: l10n.childBirthDateHelp,
      fieldHintText: '2026. 5. 5.',
      fieldLabelText: l10n.childBirthDateHelp,
      errorFormatText: '형식: yyyy. m. d.',
      errorInvalidText: '범위 밖 날짜입니다',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  /// 폼 제출.
  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.childBirthDateRequired)));
      return;
    }
    form.save();

    // kg → g, cm → mm 변환 (DB는 항상 metric 정수로 저장).
    final weightG = double.tryParse(_weightKg);
    final heightCm = double.tryParse(_heightCm);

    await ref.read(childCreationControllerProvider.notifier).create(
          name: _name.trim(),
          birthDate: _birthDate!,
          gender: _gender,
          birthWeightG: weightG != null ? (weightG * 1000).round() : null,
          birthHeightMm: heightCm != null ? (heightCm * 10).round() : null,
        );

    if (!mounted) return;
    final state = ref.read(childCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_name.trim()} 자녀가 등록되었어요 🎉')),
        );
        context.pop(); // 홈으로 돌아감
      },
      loading: () {}, // submit 직후엔 loading일 수 있음, 그냥 두기
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.childRegisterFailed(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 진행 상태 구독 — submit 중이면 버튼을 disable + 스피너 표시.
    final asyncCreate = ref.watch(childCreationControllerProvider);
    final isLoading = asyncCreate.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.childRegisterTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 이름 (필수) ─────────────────────────────────────
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.childName,
                hintText: l10n.childNameHint,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.childNameRequired : null,
              onSaved: (v) => _name = v ?? '',
            ),
            const SizedBox(height: 16),

            // ── 성별 (Dropdown, 기본 female) ────────────────────
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.childGender),
              initialValue: _gender,
              items: [
                DropdownMenuItem(value: 'female', child: Text(l10n.childGenderFemale)),
                DropdownMenuItem(value: 'male', child: Text(l10n.childGenderMale)),
                DropdownMenuItem(value: 'other', child: Text(l10n.childGenderOther)),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'female'),
            ),
            const SizedBox(height: 16),

            // ── 생년월일 (날짜 선택기) ───────────────────────────
            // TextFormField 대신 ListTile + onTap으로 날짜 선택 UX 구현.
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.childBirthDate),
              subtitle: Text(
                _birthDate == null
                    ? l10n.commonTapToSelect
                    : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickBirthDate,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // ── 출생 시 무게 (선택) ──────────────────────────────
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.childBirthWeightLabel,
                hintText: l10n.childBirthWeightHint,
                suffixText: 'kg',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // 선택 항목
                final n = double.tryParse(v);
                if (n == null) return l10n.commonNumberOnly;
                if (n < 0.5 || n > 8.0) return '0.5~8.0 kg';
                return null;
              },
              onSaved: (v) => _weightKg = v ?? '',
            ),
            const SizedBox(height: 16),

            // ── 출생 시 키 (선택) ────────────────────────────────
            TextFormField(
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
            const SizedBox(height: 32),

            // ── 제출 버튼 ────────────────────────────────────────
            FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(isLoading ? l10n.commonRegistering : l10n.commonRegister),
            ),
          ],
        ),
      ),
    );
  }
}
