import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 5), // 5년 전까지만 (너무 큰 아이는 앱 타겟 외)
      lastDate: now, // 미래 날짜 차단
      helpText: '자녀 생년월일 선택',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  /// 폼 제출.
  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요.')));
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
          SnackBar(content: Text('등록 실패: $err')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 진행 상태 구독 — submit 중이면 버튼을 disable + 스피너 표시.
    final asyncCreate = ref.watch(childCreationControllerProvider);
    final isLoading = asyncCreate.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('자녀 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 이름 (필수) ─────────────────────────────────────
            TextFormField(
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '예: 김아기',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름은 필수예요.' : null,
              onSaved: (v) => _name = v ?? '',
            ),
            const SizedBox(height: 16),

            // ── 성별 (Dropdown, 기본 female) ────────────────────
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '성별'),
              initialValue: _gender,
              items: const [
                DropdownMenuItem(value: 'female', child: Text('여아')),
                DropdownMenuItem(value: 'male', child: Text('남아')),
                DropdownMenuItem(value: 'other', child: Text('기타')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'female'),
            ),
            const SizedBox(height: 16),

            // ── 생년월일 (날짜 선택기) ───────────────────────────
            // TextFormField 대신 ListTile + onTap으로 날짜 선택 UX 구현.
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('생년월일'),
              subtitle: Text(
                _birthDate == null
                    ? '탭해서 선택'
                    : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickBirthDate,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // ── 출생 시 무게 (선택) ──────────────────────────────
            TextFormField(
              decoration: const InputDecoration(
                labelText: '출생 시 무게 (kg, 선택)',
                hintText: '예: 3.45',
                suffixText: 'kg',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // 선택 항목
                final n = double.tryParse(v);
                if (n == null) return '숫자만 입력해주세요.';
                if (n < 0.5 || n > 8.0) return '0.5~8.0 kg 사이여야 해요.';
                return null;
              },
              onSaved: (v) => _weightKg = v ?? '',
            ),
            const SizedBox(height: 16),

            // ── 출생 시 키 (선택) ────────────────────────────────
            TextFormField(
              decoration: const InputDecoration(
                labelText: '출생 시 키 (cm, 선택)',
                hintText: '예: 51.5',
                suffixText: 'cm',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null) return '숫자만 입력해주세요.';
                if (n < 30 || n > 80) return '30~80 cm 사이여야 해요.';
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
              label: Text(isLoading ? '등록 중…' : '등록'),
            ),
          ],
        ),
      ),
    );
  }
}
