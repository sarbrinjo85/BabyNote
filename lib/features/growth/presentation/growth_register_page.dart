import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import 'growth_providers.dart';

/// 성장 측정 화면 (체중/키/머리둘레).
///
/// ── 단위 변환 ────────────────────────────────────────────────────────
/// 사용자 입력은 kg / cm (소수점 한 자리). DB 저장은 g / mm.
/// kg → g : *1000, cm → mm : *10. 간단한 곱셈.
///
/// ── WHO 백분위 ───────────────────────────────────────────────────────
/// Phase 2 후반에 추가 예정. 지금은 입력 + 저장만.
class GrowthRegisterPage extends ConsumerStatefulWidget {
  const GrowthRegisterPage({super.key});

  @override
  ConsumerState<GrowthRegisterPage> createState() =>
      _GrowthRegisterPageState();
}

class _GrowthRegisterPageState extends ConsumerState<GrowthRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _measuredAt = DateTime.now();
  String _weightKg = '';
  String _heightCm = '';
  String _headCm = '';
  String _note = '';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: '측정 일자 선택',
    );
    if (picked != null) {
      setState(() => _measuredAt = picked);
    }
  }

  Future<void> _submit(String childId) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final w = double.tryParse(_weightKg);
    final h = double.tryParse(_heightCm);
    final hd = double.tryParse(_headCm);

    if (w == null && h == null && hd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체중·키·머리둘레 중 하나는 입력해주세요.')),
      );
      return;
    }

    await ref.read(growthCreationControllerProvider.notifier).create(
          childId: childId,
          measuredAt: _measuredAt,
          weightG: w == null ? null : (w * 1000).round(),
          heightMm: h == null ? null : (h * 10).round(),
          headCircumferenceMm: hd == null ? null : (hd * 10).round(),
          note: _note.trim().isEmpty ? null : _note.trim(),
        );

    if (!mounted) return;
    final state = ref.read(growthCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성장 기록을 저장했어요 📏')),
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
    final asyncCtrl = ref.watch(growthCreationControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('성장 기록')),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('자녀 목록 로딩 실패: $err')),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = children.first;

          return SafeArea(
            top: false,
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: Spacing.lg),

                  // ── 측정일 ─────────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('측정 일자'),
                    subtitle: Text(_formatDate(_measuredAt)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  const Divider(),
                  const SizedBox(height: Spacing.md),

                  // ── 체중 ───────────────────────────────────────
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '체중',
                      hintText: '예: 8.45',
                      suffixText: 'kg',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(v, 0.5, 30, 'kg'),
                    onSaved: (v) => _weightKg = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 키 ─────────────────────────────────────────
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '키',
                      hintText: '예: 75.5',
                      suffixText: 'cm',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(v, 30, 150, 'cm'),
                    onSaved: (v) => _heightCm = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 머리둘레 ──────────────────────────────────
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '머리둘레',
                      hintText: '예: 45.0',
                      suffixText: 'cm',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(v, 25, 60, 'cm'),
                    onSaved: (v) => _headCm = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  // ── 메모 ───────────────────────────────────────
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '메모 (선택)',
                      hintText: '예: 신생아실, 정기검진 등',
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
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isLoading ? '저장 중…' : '등록'),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(TouchTarget.huge),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _validateRange(String? v, double min, double max, String unit) {
    if (v == null || v.isEmpty) return null; // 모두 선택 (적어도 하나는 별도 검증)
    final n = double.tryParse(v);
    if (n == null) return '숫자만 입력해주세요.';
    if (n < min || n > max) return '$min~$max $unit 사이여야 해요.';
    return null;
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
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
