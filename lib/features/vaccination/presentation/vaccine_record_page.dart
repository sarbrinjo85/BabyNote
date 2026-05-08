import 'package:flutter/material.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../hospital/presentation/hospital_providers.dart';
import '../domain/vaccine_schedule.dart';
import 'vaccination_providers.dart';

/// 접종 완료 기록 화면.
///
/// 진입 시 schedule + childId를 GoRouter extra로 받음.
/// 사용자가 접종일(default 오늘) + 병원 선택 + 메모 입력 후 등록.
class VaccineRecordPage extends ConsumerStatefulWidget {
  const VaccineRecordPage({
    super.key,
    required this.schedule,
    required this.childId,
  });

  final VaccineSchedule schedule;
  final String childId;

  @override
  ConsumerState<VaccineRecordPage> createState() => _VaccineRecordPageState();
}

class _VaccineRecordPageState extends ConsumerState<VaccineRecordPage> {
  DateTime _administeredAt = DateTime.now();
  String? _hospitalId;
  String _note = '';

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _administeredAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: l10n.vaccineDateHelp,
    );
    if (picked != null) {
      // 시간은 그대로 (지금) — 추후 time picker 추가 가능
      setState(() => _administeredAt =
          DateTime(picked.year, picked.month, picked.day, now.hour, now.minute));
    }
  }

  Future<void> _submit() async {
    final s = widget.schedule;
    await ref.read(vaccinationControllerProvider.notifier).recordAdministered(
          childId: widget.childId,
          vaccineCode: s.code,
          doseNumber: s.doseNumber,
          vaccineScheduleId: s.id,
          administeredAt: _administeredAt,
          hospitalId: _hospitalId,
          note: _note.trim().isEmpty ? null : _note.trim(),
        );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(vaccinationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.schedule.name} ✅')),
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
    final s = widget.schedule;
    final asyncCtrl = ref.watch(vaccinationControllerProvider);
    final isLoading = asyncCtrl.isLoading;
    final asyncHospitals = ref.watch(myHospitalsProvider);

    String two(int v) => v.toString().padLeft(2, '0');
    final dateStr =
        '${_administeredAt.year}-${two(_administeredAt.month)}-${two(_administeredAt.day)}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaccineRecordTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // ── 백신 정보 ───────────────────────────────────────────
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${s.code} · ${s.doseNumber}'),
                    Text(l10n.vaccineRecommendedAge(s.recommendedAgeDays)),
                    if (s.description != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(s.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.vaccineDoseDate),
              subtitle: Text(dateStr),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: Spacing.md),

            // ── 병원 선택 ──────────────────────────────────────────
            asyncHospitals.when(
              loading: () =>
                  const Center(child: BabyLoading()),
              error: (err, _) => Text(l10n.vaccineHospitalLoadFailure(err)),
              data: (hospitals) {
                if (hospitals.isEmpty) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.homeHospital),
                    subtitle: Text(l10n.vaccineHospitalNone),
                    trailing: TextButton(
                      onPressed: () => context.push('/hospital/new'),
                      child: Text(l10n.hospitalAdd),
                    ),
                  );
                }
                return DropdownButtonFormField<String?>(
                  decoration:
                      InputDecoration(labelText: l10n.vaccineHospitalLabel),
                  initialValue: _hospitalId,
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text(l10n.commonNoSelection)),
                    ...hospitals.map((h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(h.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _hospitalId = v),
                );
              },
            ),
            const SizedBox(height: Spacing.lg),

            TextField(
              decoration: InputDecoration(
                labelText: l10n.commonMemoOptional,
                hintText: l10n.vaccineMemoHint,
              ),
              onChanged: (v) => _note = v,
              maxLines: 2,
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
              label: Text(isLoading ? l10n.commonSaving : l10n.vaccineRecordButton),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(TouchTarget.huge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
