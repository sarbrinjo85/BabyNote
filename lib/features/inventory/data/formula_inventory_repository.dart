import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/formula_inventory.dart';

class FormulaInventoryRepository {
  FormulaInventoryRepository(this._client);

  final SupabaseClient _client;

  Future<FormulaInventory> create({
    required String currentUserId,
    required FormulaInventory draft,
  }) async {
    final inserted = await _client
        .from('formula_inventories')
        .insert(draft.toInsertMap(createdBy: currentUserId))
        .select()
        .single();
    return FormulaInventory.fromMap(inserted);
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

  /// 사용 중인 통(=opened_at NOT NULL AND depleted_at IS NULL).
  /// `or()` 대신 두 번 filter — Supabase Dart SDK는 `not()` chain.
  Future<List<FormulaInventory>> listActive(String childId) async {
    final rows = await _client
        .from('formula_inventories')
        .select()
        .eq('child_id', childId)
        .not('opened_at', 'is', null)
        .filter('depleted_at', 'is', null)
        .order('opened_at', ascending: true); // FIFO — 먼저 개봉한 것 먼저
    return rows.map((r) => FormulaInventory.fromMap(r)).toList();
  }

  /// 개봉(opened_at = today). FIFO 차감 로직에서 다음 통을 활성화할 때 사용.
  Future<FormulaInventory> markOpened(String inventoryId) async {
    final updated = await _client
        .from('formula_inventories')
        .update({'opened_at': _today()})
        .eq('id', inventoryId)
        .select()
        .single();
    return FormulaInventory.fromMap(updated);
  }

  /// 소진 처리.
  Future<FormulaInventory> markDepleted(String inventoryId) async {
    final updated = await _client
        .from('formula_inventories')
        .update({'depleted_at': _today()})
        .eq('id', inventoryId)
        .select()
        .single();
    return FormulaInventory.fromMap(updated);
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

  /// 분유 통 정보 부분 수정 — 메타데이터(제품명/브랜드/용량/구매일/가격/구매처/개봉일).
  /// opened_at/depleted_at은 별도 액션(markOpened/markDepleted) 사용 권장.
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
    final updated = await _client
        .from('formula_inventories')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return FormulaInventory.fromMap(updated);
  }

  /// 분유 통 삭제. 연결된 feeding 기록은 formula_inventory_id가 SET NULL되거나
  /// CASCADE에 따라 처리됨 (DB 정의에 의존).
  Future<void> deleteInventory(String id) async {
    await _client.from('formula_inventories').delete().eq('id', id);
  }

  /// 한 분유 통에 연결된 수유 기록의 amount_ml 합계.
  /// formula_inventory_id로 join해서 sum.
  ///
  /// PostgREST에는 .sum() 같은 group by 한 줄 매개변수가 없어서
  /// row를 가져와서 클라이언트에서 합산. 한 통당 보통 30~50건이라 부담 없음.
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
  return FormulaInventoryRepository(ref.watch(supabaseClientProvider));
});
