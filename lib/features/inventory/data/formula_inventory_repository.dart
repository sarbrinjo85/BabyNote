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
}

final formulaInventoryRepositoryProvider =
    Provider<FormulaInventoryRepository>((ref) {
  return FormulaInventoryRepository(ref.watch(supabaseClientProvider));
});
