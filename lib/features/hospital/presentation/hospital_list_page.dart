import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../domain/hospital.dart';
import 'hospital_actions.dart';
import 'hospital_providers.dart';

class HospitalListPage extends ConsumerWidget {
  const HospitalListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myHospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('단골 병원'),
        actions: [
          IconButton(
            tooltip: '추가',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/hospital/new'),
          ),
        ],
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('병원 목록 로딩 실패: $err')),
        data: (list) {
          if (list.isEmpty) return _EmptyPlaceholder();
          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: list.map((h) => _HospitalCard(hospital: h)).toList(),
          );
        },
      ),
    );
  }
}

class _HospitalCard extends ConsumerWidget {
  const _HospitalCard({required this.hospital});
  final Hospital hospital;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = hospital;
    final theme = Theme.of(context);

    String specialtyLabel(String? s) => switch (s) {
          'pediatrics' => '소아과',
          'dental' => '치과',
          'er' => '응급실',
          'other' => '기타',
          _ => '',
        };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (h.isDefault) ...[
                            Icon(Icons.star, color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(h.name,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (h.specialty != null)
                        Text(specialtyLabel(h.specialty),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      if (h.address != null && h.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Text(h.address!,
                              style: theme.textTheme.bodySmall),
                        ),
                      if (h.phone != null && h.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(h.phone!, style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'default') {
                      await ref
                          .read(hospitalControllerProvider.notifier)
                          .setDefault(h.id);
                    } else if (v == 'delete') {
                      final ok = await _confirmDelete(context);
                      if (ok && context.mounted) {
                        await ref
                            .read(hospitalControllerProvider.notifier)
                            .delete(h.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    if (!h.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('기본으로 설정'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: (h.phone == null || h.phone!.isEmpty)
                        ? null
                        : () => _onCallPhone(context, h),
                    icon: const Icon(Icons.phone),
                    label: const Text('전화'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed:
                        (h.hasCoordinates || (h.address?.isNotEmpty ?? false))
                            ? () => _onOpenMaps(context, h)
                            : null,
                    icon: const Icon(Icons.map),
                    label: const Text('길찾기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCallPhone(BuildContext context, Hospital h) async {
    final ok = await HospitalActions.callPhone(h);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화 앱을 열 수 없어요.')),
      );
    }
  }

  Future<void> _onOpenMaps(BuildContext context, Hospital h) async {
    final ok = await HospitalActions.openMaps(h);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도 앱을 열 수 없어요.')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('병원을 삭제할까요?'),
        content: const Text('이 작업은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    return r ?? false;
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.sm),
            const Text('등록된 병원이 없어요'),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/hospital/new'),
              icon: const Icon(Icons.add),
              label: const Text('병원 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
