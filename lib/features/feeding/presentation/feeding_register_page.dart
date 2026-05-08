import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../domain/feeding.dart';
import 'feeding_providers.dart';

/// 수유 기록 등록 화면.
///
/// ── 화면 구성 ────────────────────────────────────────────────────────
/// 상단: 어느 자녀에 대한 기록인지 (현재는 첫 자녀 자동 사용 — 자녀 여러 명 처리는 Phase 2 후반)
/// 탭: 모유 / 분유 / 이유식 — 각 탭마다 다른 입력 필드
/// 공통: 시간(자동, 지금) / 메모(선택) / 등록 버튼
///
/// ── 학습 포인트 ──────────────────────────────────────────────────────
/// - DefaultTabController + TabBarView (탭 전환 + 컨트롤러)
/// - 탭마다 다른 폼 → 별도의 _BreastForm/_FormulaForm/_SolidForm StatefulWidget
/// - 부모(이 화면)가 탭 인덱스 보고 어떤 데이터 보낼지 결정
class FeedingRegisterPage extends ConsumerStatefulWidget {
  const FeedingRegisterPage({super.key, this.editing});

  final Feeding? editing;

  @override
  ConsumerState<FeedingRegisterPage> createState() =>
      _FeedingRegisterPageState();
}

class _FeedingRegisterPageState extends ConsumerState<FeedingRegisterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 모유 탭 상태 (side는 SegmentedButton selected로 표시되므로 String만)
  String _breastSide = 'left';
  late final TextEditingController _breastAmountCtrl;

  // 분유 탭 상태
  late final TextEditingController _formulaAmountCtrl;
  late final TextEditingController _formulaBrandCtrl;

  // 이유식 탭 상태
  late final TextEditingController _foodNameCtrl;
  late final TextEditingController _solidAmountCtrl;
  File? _solidPhoto;

  // 공통 메모
  late final TextEditingController _noteCtrl;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final initialIndex = _initialTabIndex();
    _tabController = TabController(
      length: 3, vsync: this, initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // 편집 모드면 type별 prefill, 아니면 빈 컨트롤러
    _breastSide = (e?.type == 'breast' ? e!.breastSide : null) ?? 'left';
    _breastAmountCtrl = TextEditingController(
      text: e?.type == 'breast' ? (e!.amountMl?.toString() ?? '') : '',
    );
    _formulaAmountCtrl = TextEditingController(
      text: e?.type == 'formula' ? (e!.amountMl?.toString() ?? '') : '',
    );
    _formulaBrandCtrl = TextEditingController(
      text: e?.type == 'formula' ? (e!.formulaBrand ?? '') : '',
    );
    _foodNameCtrl = TextEditingController(
      text: e?.type == 'solid' ? (e!.foodName ?? '') : '',
    );
    _solidAmountCtrl = TextEditingController(
      text: e?.type == 'solid' ? (e!.amountMl?.toString() ?? '') : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');

    // 분유 빠른 선택 버튼 강조용 — amount 변할 때마다 rebuild
    _formulaAmountCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  int _initialTabIndex() {
    final t = widget.editing?.type;
    if (t == 'formula') return 1;
    if (t == 'solid') return 2;
    return 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breastAmountCtrl.dispose();
    _formulaAmountCtrl.dispose();
    _formulaBrandCtrl.dispose();
    _foodNameCtrl.dispose();
    _solidAmountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// 현재 선택된 탭 이름을 type 코드로 변환.
  String get _type {
    switch (_tabController.index) {
      case 0:
        return 'breast';
      case 1:
        return 'formula';
      case 2:
        return 'solid';
      default:
        return 'breast';
    }
  }

  /// 등록 버튼 활성 조건 — 탭별로 다름.
  bool get _canSubmit {
    switch (_type) {
      case 'breast':
        return true; // breastSide만 있으면 OK (default 'left')
      case 'formula':
        final n = int.tryParse(_formulaAmountCtrl.text);
        return n != null && n > 0;
      case 'solid':
        return _foodNameCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submit(String childId) async {
    final type = _type;
    final now = DateTime.now();

    int? amountMl;
    String? breastSide;
    String? foodName;
    String? formulaBrand;
    String? formulaInventoryId;

    switch (type) {
      case 'breast':
        breastSide = _breastSide;
        amountMl = int.tryParse(_breastAmountCtrl.text);
        break;
      case 'formula':
        amountMl = int.tryParse(_formulaAmountCtrl.text);
        formulaBrand = _formulaBrandCtrl.text.trim().isEmpty
            ? null
            : _formulaBrandCtrl.text.trim();
        // FIFO: 활성 분유 통 첫 번째(가장 먼저 개봉한 것)에 자동 연결.
        // P3-1c에서 잔량 계산할 때 이 id로 join.
        final actives = ref.read(
          activeFormulaInventoriesProvider(childId),
        );
        actives.whenData((list) {
          if (list.isNotEmpty) formulaInventoryId = list.first.id;
        });
        break;
      case 'solid':
        foodName = _foodNameCtrl.text.trim();
        amountMl = int.tryParse(_solidAmountCtrl.text);
        break;
    }
    final noteText = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEdit) {
      // 편집 모드: photo는 변경 안 함 (단순화). type/수치/메모만 update.
      await ref.read(feedingCreationControllerProvider.notifier).saveEdit(
            childId: childId,
            id: widget.editing!.id,
            type: type,
            amountMl: amountMl,
            breastSide: breastSide,
            foodName: foodName,
            formulaBrand: formulaBrand,
            note: noteText,
          );
    } else {
      await ref.read(feedingCreationControllerProvider.notifier).create(
            childId: childId,
            type: type,
            startedAt: now,
            endedAt: now,
            amountMl: amountMl,
            breastSide: breastSide,
            foodName: foodName,
            formulaBrand: formulaBrand,
            formulaInventoryId: formulaInventoryId,
            note: noteText,
            photoFile: type == 'solid' ? _solidPhoto : null,
          );
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(feedingCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? l10n.recordEditSaved : l10n.feedingSavedToast),
        ));
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.feedingSaveFailed(err))));
      },
    );
  }

  /// 갤러리에서 이유식 사진 선택.
  /// image_picker가 maxWidth/imageQuality로 자동 압축 → 업로드 부담 감소.
  Future<void> _pickSolidPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _solidPhoto = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.feedingPhotoFailed(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCreate = ref.watch(feedingCreationControllerProvider);
    final isLoading = asyncCreate.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.feedingEditTitle : l10n.feedingTitle),
        actions: _isEdit ? null : const [ChildPickerAction()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.feedingTabBreast),
            Tab(text: l10n.feedingTabFormula),
            Tab(text: l10n.feedingTabSolid),
          ],
        ),
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: BabyLoading()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) {
            // 자녀 0명 — 등록 화면 전에 자녀 등록 안내
            return _NoChildPlaceholder();
          }
          // selectedChild는 myChildrenProvider 결과 안에서 매칭된 1명 (없으면 첫 자녀).
          final child = _isEdit
              ? children.firstWhere(
                  (c) => c.id == widget.editing!.childId,
                  orElse: () => children.first,
                )
              : (ref.watch(selectedChildProvider) ?? children.first);

          return Column(
            children: [
              // 누구의 기록인지 상단에 명시
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.child_care),
                    const SizedBox(width: Spacing.xs),
                    Text('${child.name} 자녀',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BreastForm(
                      side: _breastSide,
                      amountCtrl: _breastAmountCtrl,
                      onSideChanged: (s) => setState(() => _breastSide = s),
                    ),
                    _FormulaForm(
                      childId: child.id,
                      amountCtrl: _formulaAmountCtrl,
                      brandCtrl: _formulaBrandCtrl,
                    ),
                    _SolidForm(
                      foodNameCtrl: _foodNameCtrl,
                      amountCtrl: _solidAmountCtrl,
                      photo: _solidPhoto,
                      onFoodNameChanged: () => setState(() {}),
                      onPickPhoto: _pickSolidPhoto,
                      onRemovePhoto: () => setState(() => _solidPhoto = null),
                    ),
                  ],
                ),
              ),
              // 공통: 메모 + 등록 버튼
              // SafeArea(top: false)로 하단 시스템 네비게이션 바 영역 회피.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.commonMemoOptional,
                          hintText: l10n.feedingMemoHint,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: Spacing.md),
                      FilledButton.icon(
                        onPressed: isLoading || !_canSubmit
                            ? null
                            : () => _submit(child.id),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(isLoading
                            ? l10n.commonSaving
                            : (_isEdit ? l10n.commonSave : l10n.commonRegister)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 모유 입력 폼.
class _BreastForm extends StatelessWidget {
  const _BreastForm({
    required this.side,
    required this.amountCtrl,
    required this.onSideChanged,
  });

  final String side;
  final TextEditingController amountCtrl;
  final ValueChanged<String> onSideChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Text(l10n.feedingBreastSide, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'left', label: Text(l10n.feedingBreastLeft)),
            ButtonSegment(value: 'right', label: Text(l10n.feedingBreastRight)),
            ButtonSegment(value: 'both', label: Text(l10n.feedingBreastBoth)),
          ],
          selected: {side},
          onSelectionChanged: (s) => onSideChanged(s.first),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: amountCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingBreastAmountLabel,
            hintText: l10n.feedingBreastAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

/// 분유 입력 폼. 컨트롤러는 부모(_FeedingRegisterPageState)가 소유.
class _FormulaForm extends ConsumerWidget {
  const _FormulaForm({
    required this.childId,
    required this.amountCtrl,
    required this.brandCtrl,
  });

  final String childId;
  final TextEditingController amountCtrl;
  final TextEditingController brandCtrl;

  void _setAmount(int v) {
    amountCtrl.text = v.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 현재 amount 값 — 빠른 선택 버튼 강조에 사용
    final currentMl = int.tryParse(amountCtrl.text);
    final asyncActive =
        ref.watch(activeFormulaInventoriesProvider(childId));
    final activeFirst = asyncActive.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        // ── 활성 분유 통 카드 (P3-1b) ──────────────────────────────
        Card(
          color: activeFirst != null
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: activeFirst != null
                ? Row(
                    children: [
                      const Text('🍼', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.feedingInUse,
                                style: Theme.of(context).textTheme.labelMedium),
                            Text(activeFirst.productName,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                      ),
                      Text(l10n.feedingAutoSubtract,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  )),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(l10n.feedingNoActiveFormula),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: amountCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingFormulaAmountLabel,
            hintText: l10n.feedingFormulaAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: Spacing.sm),
        // 빠른 선택: 10~250 ml, 10ml 단위 (25개).
        // 현재 입력값과 일치하는 버튼은 FilledButton으로 강조 (편집 시 이전 값 시각화).
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: List.generate(25, (i) {
            final v = (i + 1) * 10;
            final isSelected = currentMl == v;
            final style = ButtonStyle(
              minimumSize:
                  const WidgetStatePropertyAll(Size(0, 36)),
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: Spacing.sm)),
              textStyle:
                  const WidgetStatePropertyAll(TextStyle(fontSize: 14)),
            );
            return isSelected
                ? FilledButton(
                    onPressed: () => _setAmount(v),
                    style: style,
                    child: Text('${v}ml'),
                  )
                : OutlinedButton(
                    onPressed: () => _setAmount(v),
                    style: style,
                    child: Text('${v}ml'),
                  );
          }),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: brandCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingFormulaBrandLabel,
            hintText: l10n.feedingFormulaBrandHint,
          ),
        ),
      ],
    );
  }
}

/// 이유식 입력 폼. 컨트롤러는 부모가 소유.
class _SolidForm extends StatelessWidget {
  const _SolidForm({
    required this.foodNameCtrl,
    required this.amountCtrl,
    required this.photo,
    required this.onFoodNameChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final TextEditingController foodNameCtrl;
  final TextEditingController amountCtrl;
  final File? photo;
  /// foodName 변경 시 부모에 setState 트리거 (등록 버튼 활성/비활성).
  final VoidCallback onFoodNameChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        TextField(
          controller: foodNameCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingSolidFoodLabel,
            hintText: l10n.feedingSolidFoodHint,
          ),
          // 폼 비어있다가 텍스트 들어오면 등록 버튼 활성 → 부모 setState 필요
          onChanged: (_) => onFoodNameChanged(),
          autofocus: true,
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: amountCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingSolidAmountLabel,
            hintText: l10n.feedingSolidAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: Spacing.lg),

        // ── 사진 첨부 영역 ───────────────────────────────────────
        Text(l10n.feedingPhotoOptional, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        if (photo == null)
          // 사진 미선택 — 추가 버튼만
          OutlinedButton.icon(
            onPressed: onPickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.feedingPickFromGallery),
          )
        else
          // 사진 선택됨 — 미리보기 + 삭제 버튼
          Stack(
            children: [
              ClipRRect(
                borderRadius: Radii.brMd,
                child: Image.file(
                  photo!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: Spacing.xs,
                right: Spacing.xs,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemovePhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(Spacing.xs),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _NoChildPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            Text(l10n.commonRegisterChildFirst),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push('/child/new');
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.commonGoRegisterChild),
            ),
          ],
        ),
      ),
    );
  }
}
