import 'package:flutter/material.dart';
import '../../../core/widgets/stroked_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/widgets/child_picker_action.dart';
import 'diaper_inventory_list_page.dart';
import 'formula_inventory_list_page.dart';

/// 재고 관리 Hub — 분유/기저귀 두 탭 통합 페이지.
///
/// 각 탭은 기존 list page를 embed=true로 호출 (Scaffold/AppBar 없이 body만).
/// AppBar는 Hub의 단일 AppBar — 현재 탭에 맞는 "+ 추가" 버튼 보여줌.
class InventoryHubPage extends ConsumerStatefulWidget {
  const InventoryHubPage({super.key});

  @override
  ConsumerState<InventoryHubPage> createState() => _InventoryHubPageState();
}

class _InventoryHubPageState extends ConsumerState<InventoryHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // 탭 바뀔 때 + 버튼 동작 분기를 위해 setState
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFormula = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: StrokedTitle(l10n.inventoryHubTitle, fontSize: 26),
        actions: [
          const ChildPickerAction(),
          IconButton(
            tooltip: l10n.commonAdd,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(
              isFormula ? '/inventory/formula/new' : '/inventory/diaper/new',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.formulaInventoryTitle),
            Tab(text: l10n.diaperInventoryTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FormulaInventoryListPage(embed: true),
          DiaperInventoryListPage(embed: true),
        ],
      ),
    );
  }
}
