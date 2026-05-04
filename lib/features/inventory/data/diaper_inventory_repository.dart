import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/diaper_inventory.dart';

class DiaperInventoryRepository {
  DiaperInventoryRepository(this._client);

  final SupabaseClient _client;

  Future<DiaperInventory> create({
    required String currentUserId,
    required DiaperInventory draft,
  }) async {
    final inserted = await _client
        .from('diaper_inventories')
        .insert(draft.toInsertMap(createdBy: currentUserId))
        .select()
        .single();
    return DiaperInventory.fromMap(inserted);
  }

  Future<List<DiaperInventory>> listAll(String childId) async {
    final rows = await _client
        .from('diaper_inventories')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return rows.map((r) => DiaperInventory.fromMap(r)).toList();
  }

  Future<List<DiaperInventory>> listActive(String childId) async {
    final rows = await _client
        .from('diaper_inventories')
        .select()
        .eq('child_id', childId)
        .not('opened_at', 'is', null)
        .filter('depleted_at', 'is', null)
        .order('opened_at', ascending: true);
    return rows.map((r) => DiaperInventory.fromMap(r)).toList();
  }

  Future<DiaperInventory> markOpened(String inventoryId) async {
    final updated = await _client
        .from('diaper_inventories')
        .update({'opened_at': _today()})
        .eq('id', inventoryId)
        .select()
        .single();
    return DiaperInventory.fromMap(updated);
  }

  Future<DiaperInventory> markDepleted(String inventoryId) async {
    final updated = await _client
        .from('diaper_inventories')
        .update({'depleted_at': _today()})
        .eq('id', inventoryId)
        .select()
        .single();
    return DiaperInventory.fromMap(updated);
  }

  /// 한 기저귀 팩에 연결된 사용 기록(diapers) 매수 카운트.
  /// "둘다"도 1매로 계산 (현실에서도 한 번에 한 매).
  Future<int> countUsed(String inventoryId) async {
    final rows = await _client
        .from('diapers')
        .select('id')
        .eq('diaper_inventory_id', inventoryId);
    return rows.length;
  }

  String _today() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

final diaperInventoryRepositoryProvider =
    Provider<DiaperInventoryRepository>((ref) {
  return DiaperInventoryRepository(ref.watch(supabaseClientProvider));
});
