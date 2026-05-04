import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import 'formula_inventory_providers.dart';

/// 분유 한 통 등록 화면.
///
/// 필수: 제품명, 용량(g)
/// 선택: 브랜드, 구매일, 가격, 구매처, 개봉일(미입력=보관 중)
class FormulaInventoryRegisterPage extends ConsumerStatefulWidget {
  const FormulaInventoryRegisterPage({super.key});

  @override
  ConsumerState<FormulaInventoryRegisterPage> createState() =>
      _FormulaInventoryRegisterPageState();
}

class _FormulaInventoryRegisterPageState
    extends ConsumerState<FormulaInventoryRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String _productName = '';
  String _brand = '';
  String _containerG = '';
  String _priceWon = '';
  String _store = '';
  DateTime? _purchasedAt;
  DateTime? _openedAt;

  Future<void> _pickDate({
    required String label,
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1), // 유통기한 미래도 허용 (구매일은 보통 과거지만)
      helpText: label,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit(String childId) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final grams = int.tryParse(_containerG)!;
    final price = int.tryParse(_priceWon);

    await ref.read(formulaInventoryControllerProvider.notifier).create(
          childId: childId,
          productName: _productName.trim(),
          brand: _brand.trim().isEmpty ? null : _brand.trim(),
          containerGrams: grams,
          purchasedAt: _purchasedAt,
          priceMinor: price,
          store: _store.trim().isEmpty ? null : _store.trim(),
          openedAt: _openedAt,
        );

    if (!mounted) return;
    final state = ref.read(formulaInventoryControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분유를 등록했어요 🍼')),
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
    final asyncCtrl = ref.watch(formulaInventoryControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('분유 등록')),
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

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '제품명',
                      hintText: '예: 압타밀 1단계',
                    ),
                    autofocus: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제품명은 필수예요.' : null,
                    onSaved: (v) => _productName = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '브랜드 (선택)',
                      hintText: '예: 압타밀, 매일유업',
                    ),
                    onSaved: (v) => _brand = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '용량',
                      hintText: '예: 800',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '용량은 필수예요.';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return '양수만 입력해주세요.';
                      if (n > 10000) return '용량이 너무 커요. 단위(g) 다시 확인해줘.';
                      return null;
                    },
                    onSaved: (v) => _containerG = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  // ── 날짜 입력 ──────────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('구매일 (선택)'),
                    subtitle: Text(_purchasedAt == null
                        ? '탭해서 선택'
                        : _formatDate(_purchasedAt!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(
                      label: '구매일',
                      current: _purchasedAt,
                      onPicked: (d) => setState(() => _purchasedAt = d),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('개봉일 (선택, 비워두면 보관 중)'),
                    subtitle: Text(_openedAt == null
                        ? '아직 안 열었음'
                        : _formatDate(_openedAt!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(
                      label: '개봉일',
                      current: _openedAt,
                      onPicked: (d) => setState(() => _openedAt = d),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: Spacing.md),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '가격 (선택, 원)',
                      hintText: '예: 35000',
                      suffixText: '원',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return '0 이상의 숫자만.';
                      return null;
                    },
                    onSaved: (v) => _priceWon = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '구매처 (선택)',
                      hintText: '예: 쿠팡, 약국',
                    ),
                    onSaved: (v) => _store = v ?? '',
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
                    label: Text(isLoading ? '저장 중…' : '등록'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(TouchTarget.huge),
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
