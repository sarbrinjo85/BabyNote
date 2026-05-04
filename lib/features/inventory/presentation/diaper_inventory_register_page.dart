import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import 'diaper_inventory_providers.dart';

class DiaperInventoryRegisterPage extends ConsumerStatefulWidget {
  const DiaperInventoryRegisterPage({super.key});

  @override
  ConsumerState<DiaperInventoryRegisterPage> createState() =>
      _DiaperInventoryRegisterPageState();
}

class _DiaperInventoryRegisterPageState
    extends ConsumerState<DiaperInventoryRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String _size = 'M';
  String _brand = '';
  String _quantity = '';
  String? _usageKind; // null = 미선택 (= all로 저장 안 함, 미설정)
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
      lastDate: DateTime(now.year + 1),
      helpText: label,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit(String childId) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final qty = int.tryParse(_quantity)!;
    final price = int.tryParse(_priceWon);

    await ref.read(diaperInventoryControllerProvider.notifier).create(
          childId: childId,
          size: _size,
          quantity: qty,
          brand: _brand.trim().isEmpty ? null : _brand.trim(),
          usageKind: _usageKind,
          purchasedAt: _purchasedAt,
          priceMinor: price,
          store: _store.trim().isEmpty ? null : _store.trim(),
          openedAt: _openedAt,
        );

    if (!mounted) return;
    final state = ref.read(diaperInventoryControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기저귀를 등록했어요 🧷')),
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
    final asyncCtrl = ref.watch(diaperInventoryControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('기저귀 등록')),
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

                  Text('사이즈', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    children: ['NB', 'S', 'M', 'L', 'XL', 'XXL']
                        .map((s) => ChoiceChip(
                              label: Text(s),
                              selected: _size == s,
                              onSelected: (sel) {
                                if (sel) setState(() => _size = s);
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '매수',
                      hintText: '예: 60',
                      suffixText: '매',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '매수는 필수예요.';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return '양수만 입력해주세요.';
                      if (n > 1000) return '매수가 너무 많아요.';
                      return null;
                    },
                    onSaved: (v) => _quantity = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '브랜드 (선택)',
                      hintText: '예: 하기스, 마미포코',
                    ),
                    onSaved: (v) => _brand = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  Text('사용 종류 (선택)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('낮용')),
                      ButtonSegment(value: 'night', label: Text('밤용')),
                      ButtonSegment(value: 'all', label: Text('공용')),
                    ],
                    selected: _usageKind == null ? {} : {_usageKind!},
                    onSelectionChanged: (s) =>
                        setState(() => _usageKind = s.isEmpty ? null : s.first),
                  ),
                  const SizedBox(height: Spacing.lg),

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
