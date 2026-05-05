import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../domain/hospital.dart';
import 'hospital_actions.dart';
import 'hospital_providers.dart';

class HospitalListPage extends ConsumerWidget {
  const HospitalListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(myHospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hospitalListTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonAdd,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/hospital/new'),
          ),
        ],
      ),
      body: SafeArea(top: false, child: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.hospitalLoadFailure(err))),
        data: (list) {
          if (list.isEmpty) return _EmptyPlaceholder();
          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: list.map((h) => _HospitalCard(hospital: h)).toList(),
          );
        },
      )),
    );
  }
}

class _HospitalCard extends ConsumerWidget {
  const _HospitalCard({required this.hospital});
  final Hospital hospital;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final h = hospital;
    final theme = Theme.of(context);

    String specialtyLabel(String? s) => switch (s) {
          'pediatrics' => l10n.hospitalSpecialtyPediatrics,
          'dental' => l10n.hospitalSpecialtyDental,
          'er' => l10n.hospitalSpecialtyER,
          'other' => l10n.hospitalSpecialtyOther,
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
                      PopupMenuItem(
                        value: 'default',
                        child: Text(l10n.hospitalSetDefault),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.hospitalDelete),
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
                    label: Text(l10n.hospitalCall),
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
                    label: Text(l10n.hospitalDirections),
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
    final l10n = AppLocalizations.of(context);
    final ok = await HospitalActions.callPhone(h);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hospitalCallFailed)),
      );
    }
  }

  Future<void> _onOpenMaps(BuildContext context, Hospital h) async {
    final l10n = AppLocalizations.of(context);
    final ok = await HospitalActions.openMaps(h);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hospitalMapsFailed)),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hospitalDeleteConfirmTitle),
        content: Text(l10n.hospitalDeleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    return r ?? false;
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.sm),
            Text(l10n.hospitalNone),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/hospital/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.hospitalAdd),
            ),
          ],
        ),
      ),
    );
  }
}
