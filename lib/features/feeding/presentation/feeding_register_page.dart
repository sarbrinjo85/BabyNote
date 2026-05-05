import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
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
  const FeedingRegisterPage({super.key});

  @override
  ConsumerState<FeedingRegisterPage> createState() =>
      _FeedingRegisterPageState();
}

class _FeedingRegisterPageState extends ConsumerState<FeedingRegisterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 모유 탭 상태
  String _breastSide = 'left';
  String _breastAmount = ''; // 양은 선택 (직접 짠 모유량 등)

  // 분유 탭 상태
  String _formulaAmount = ''; // 필수
  String _formulaBrand = '';

  // 이유식 탭 상태
  String _foodName = '';
  String _solidAmount = ''; // 선택
  File? _solidPhoto;        // 첨부 사진 (선택)

  // 공통 메모
  String _note = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // 탭 바뀔 때 setState로 등록 버튼 활성/비활성 갱신.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        final n = int.tryParse(_formulaAmount);
        return n != null && n > 0;
      case 'solid':
        return _foodName.trim().isNotEmpty;
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
        amountMl = int.tryParse(_breastAmount);
        break;
      case 'formula':
        amountMl = int.tryParse(_formulaAmount);
        formulaBrand =
            _formulaBrand.trim().isEmpty ? null : _formulaBrand.trim();
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
        foodName = _foodName.trim();
        amountMl = int.tryParse(_solidAmount);
        break;
    }

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
          note: _note.trim().isEmpty ? null : _note.trim(),
          photoFile: type == 'solid' ? _solidPhoto : null,
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(feedingCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.feedingSavedToast)));
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
        title: Text(l10n.feedingTitle),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) {
            // 자녀 0명 — 등록 화면 전에 자녀 등록 안내
            return _NoChildPlaceholder();
          }
          // selectedChild는 myChildrenProvider 결과 안에서 매칭된 1명 (없으면 첫 자녀).
          final child = ref.watch(selectedChildProvider) ?? children.first;

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
                      amount: _breastAmount,
                      onSideChanged: (s) => setState(() => _breastSide = s),
                      onAmountChanged: (v) => _breastAmount = v,
                    ),
                    _FormulaForm(
                      childId: child.id,
                      amount: _formulaAmount,
                      brand: _formulaBrand,
                      onAmountChanged: (v) =>
                          setState(() => _formulaAmount = v),
                      onBrandChanged: (v) => _formulaBrand = v,
                    ),
                    _SolidForm(
                      foodName: _foodName,
                      amount: _solidAmount,
                      photo: _solidPhoto,
                      onFoodNameChanged: (v) => setState(() => _foodName = v),
                      onAmountChanged: (v) => _solidAmount = v,
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
                        decoration: InputDecoration(
                          labelText: l10n.commonMemoOptional,
                          hintText: l10n.feedingMemoHint,
                        ),
                        onChanged: (v) => _note = v,
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
                        label: Text(isLoading ? l10n.commonSaving : l10n.commonRegister),
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
    required this.amount,
    required this.onSideChanged,
    required this.onAmountChanged,
  });

  final String side;
  final String amount;
  final ValueChanged<String> onSideChanged;
  final ValueChanged<String> onAmountChanged;

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
          decoration: InputDecoration(
            labelText: l10n.feedingBreastAmountLabel,
            hintText: l10n.feedingBreastAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
          onChanged: onAmountChanged,
        ),
      ],
    );
  }
}

/// 분유 입력 폼.
///
/// 상단에 "현재 사용 중인 분유" 카드 — 활성 통이 있으면 자동 연결되어 차감됨을 안내.
/// 없으면 "분유 등록하러 가기" 버튼.
class _FormulaForm extends ConsumerStatefulWidget {
  const _FormulaForm({
    required this.childId,
    required this.amount,
    required this.brand,
    required this.onAmountChanged,
    required this.onBrandChanged,
  });

  final String childId;
  final String amount;
  final String brand;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onBrandChanged;

  @override
  ConsumerState<_FormulaForm> createState() => _FormulaFormState();
}

class _FormulaFormState extends ConsumerState<_FormulaForm> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.amount);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _setAmount(int v) {
    _amountCtrl.text = v.toString();
    widget.onAmountChanged(_amountCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncActive =
        ref.watch(activeFormulaInventoriesProvider(widget.childId));
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
          controller: _amountCtrl,
          decoration: InputDecoration(
            labelText: l10n.feedingFormulaAmountLabel,
            hintText: l10n.feedingFormulaAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
          onChanged: widget.onAmountChanged,
        ),
        const SizedBox(height: Spacing.sm),
        // 빠른 선택: 10~250 ml, 10ml 단위 (25개)
        // List.generate로 [10, 20, ..., 250] 생성. (i+1)*10 패턴.
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: List.generate(25, (i) {
            final v = (i + 1) * 10;
            return OutlinedButton(
              onPressed: () => _setAmount(v),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.sm),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text('${v}ml'),
            );
          }),
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.feedingFormulaBrandLabel,
            hintText: l10n.feedingFormulaBrandHint,
          ),
          onChanged: widget.onBrandChanged,
        ),
      ],
    );
  }
}

/// 이유식 입력 폼.
class _SolidForm extends StatelessWidget {
  const _SolidForm({
    required this.foodName,
    required this.amount,
    required this.photo,
    required this.onFoodNameChanged,
    required this.onAmountChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final String foodName;
  final String amount;
  final File? photo;
  final ValueChanged<String> onFoodNameChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: l10n.feedingSolidFoodLabel,
            hintText: l10n.feedingSolidFoodHint,
          ),
          onChanged: onFoodNameChanged,
          autofocus: true,
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.feedingSolidAmountLabel,
            hintText: l10n.feedingSolidAmountHint,
            suffixText: 'ml',
          ),
          keyboardType: TextInputType.number,
          onChanged: onAmountChanged,
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
