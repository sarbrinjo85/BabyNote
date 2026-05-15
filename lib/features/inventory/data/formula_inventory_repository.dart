import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/formula_inventory.dart';

class FormulaInventoryRepository {
  FormulaInventoryRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<FormulaInventory> create({
    required String currentUserId,
    required FormulaInventory draft,
  }) async {
    final id = genUuid();
    // 큐잉 후 같은 id 로 후속 작업 가능하도록 id 를 미리 확정.
    final payload = draft.toInsertMap(createdBy: currentUserId);
    payload['id'] = id;

    // 옵티미스틱 결과 — id 만 새로 받아 같은 데이터로 복원.
    final optimistic = FormulaInventory(
      id: id,
      childId: draft.childId,
      productName: draft.productName,
      brand: draft.brand,
      form: draft.form,
      containerGrams: draft.containerGrams,
      mlPerGram: draft.mlPerGram,
      gPerScoop: draft.gPerScoop,
      mlPerScoop: draft.mlPerScoop,
      purchasedAt: draft.purchasedAt,
      priceMinor: draft.priceMinor,
      currency: draft.currency,
      store: draft.store,
      openedAt: draft.openedAt,
      depletedAt: draft.depletedAt,
      createdBy: currentUserId,
    );

    return OfflineWrites.execute<FormulaInventory>(
      ref: _ref,
      table: 'formula_inventories',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('formula_inventories')
            .insert(payload)
            .select()
            .single();
        return FormulaInventory.fromMap(r);
      },
      optimisticResult: () => optimistic,
    );
  }

  /// 자녀의 분유 재고 전체 (활성 + 보관 + 소진) — 최근 추가 순.
  Future<List<FormulaInventory>> listAll(String childId) async {
    final rows = await _client
        .from('formula_inventories')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return rows.map((r) => FormulaInventory.fromMap(r)).toList();
  }

  Future<List<FormulaInventory>> listActive(String childId) async {
    final rows = await _client
        .from('formula_inventories')
        .select()
        .eq('child_id', childId)
        .not('opened_at', 'is', null)
        .filter('depleted_at', 'is', null)
        .order('opened_at', ascending: true);
    return rows.map((r) => FormulaInventory.fromMap(r)).toList();
  }

  Future<FormulaInventory> markOpened(String inventoryId) async {
    final patch = {'opened_at': _today()};
    return OfflineWrites.execute<FormulaInventory>(
      ref: _ref,
      table: 'formula_inventories',
      op: 'update',
      rowId: inventoryId,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('formula_inventories')
            .update(patch)
            .eq('id', inventoryId)
            .select()
            .single();
        return FormulaInventory.fromMap(r);
      },
      // 옵티미스틱 — id 만 알고 최소 정보로 placeholder
      optimisticResult: () => FormulaInventory(
        id: inventoryId,
        childId: '',
        productName: '',
        form: FormulaForm.liquid,
        containerGrams: 0,
        mlPerGram: 1.0,
        gPerScoop: 0,
        mlPerScoop: 0,
        currency: 'KRW',
        openedAt: DateTime.now(),
      ),
    );
  }

  Future<FormulaInventory> markDepleted(String inventoryId) async {
    final patch = {'depleted_at': _today()};
    return OfflineWrites.execute<FormulaInventory>(
      ref: _ref,
      table: 'formula_inventories',
      op: 'update',
      rowId: inventoryId,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('formula_inventories')
            .update(patch)
            .eq('id', inventoryId)
            .select()
            .single();
        return FormulaInventory.fromMap(r);
      },
      optimisticResult: () => FormulaInventory(
        id: inventoryId,
        childId: '',
        productName: '',
        form: FormulaForm.liquid,
        containerGrams: 0,
        mlPerGram: 1.0,
        gPerScoop: 0,
        mlPerScoop: 0,
        currency: 'KRW',
        depletedAt: DateTime.now(),
      ),
    );
  }

  String _today() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _dateOrNull(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<FormulaInventory> updateInventory({
    required String id,
    required String productName,
    String? brand,
    required FormulaForm form,
    required int containerGrams,
    required double mlPerGram,
    required double gPerScoop,
    required double mlPerScoop,
    DateTime? purchasedAt,
    int? priceMinor,
    String? store,
    DateTime? openedAt,
  }) async {
    final patch = <String, dynamic>{
      'product_name': productName,
      'brand': brand,
      'form': form.value,
      'container_grams': containerGrams,
      'ml_per_gram': mlPerGram,
      'g_per_scoop': gPerScoop,
      'ml_per_scoop': mlPerScoop,
      'purchased_at': purchasedAt == null ? null : _dateOrNull(purchasedAt),
      'price_minor': priceMinor,
      'store': store,
      'opened_at': openedAt == null ? null : _dateOrNull(openedAt),
    };
    return OfflineWrites.execute<FormulaInventory>(
      ref: _ref,
      table: 'formula_inventories',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('formula_inventories')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
        return FormulaInventory.fromMap(r);
      },
      optimisticResult: () => FormulaInventory(
        id: id,
        childId: '',
        productName: productName,
        brand: brand,
        form: form,
        containerGrams: containerGrams,
        mlPerGram: mlPerGram,
        gPerScoop: gPerScoop,
        mlPerScoop: mlPerScoop,
        purchasedAt: purchasedAt,
        priceMinor: priceMinor,
        currency: 'KRW',
        store: store,
        openedAt: openedAt,
      ),
    );
  }

  Future<void> deleteInventory(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'formula_inventories',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('formula_inventories').delete().eq('id', id);
      },
    );
  }

  Future<int> sumConsumedMl(String inventoryId) async {
    final rows = await _client
        .from('feedings')
        .select('amount_ml')
        .eq('formula_inventory_id', inventoryId);
    int total = 0;
    for (final r in rows) {
      final v = r['amount_ml'];
      if (v is int) total += v;
    }
    return total;
  }
}

final formulaInventoryRepositoryProvider =
    Provider<FormulaInventoryRepository>((ref) {
  return FormulaInventoryRepository(ref.watch(supabaseClientProvider), ref);
});
