import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/diaper_inventory.dart';

class DiaperInventoryRepository {
  DiaperInventoryRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<DiaperInventory> create({
    required String currentUserId,
    required DiaperInventory draft,
  }) async {
    final id = genUuid();
    final payload = draft.toInsertMap(createdBy: currentUserId);
    payload['id'] = id;

    final optimistic = DiaperInventory(
      id: id,
      childId: draft.childId,
      size: draft.size,
      quantity: draft.quantity,
      currency: draft.currency,
      brand: draft.brand,
      usageKind: draft.usageKind,
      purchasedAt: draft.purchasedAt,
      priceMinor: draft.priceMinor,
      store: draft.store,
      openedAt: draft.openedAt,
      depletedAt: draft.depletedAt,
      createdBy: currentUserId,
    );

    return OfflineWrites.execute<DiaperInventory>(
      ref: _ref,
      table: 'diaper_inventories',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('diaper_inventories')
            .insert(payload)
            .select()
            .single();
        return DiaperInventory.fromMap(r);
      },
      optimisticResult: () => optimistic,
    );
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
    final patch = {'opened_at': _today()};
    return OfflineWrites.execute<DiaperInventory>(
      ref: _ref,
      table: 'diaper_inventories',
      op: 'update',
      rowId: inventoryId,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('diaper_inventories')
            .update(patch)
            .eq('id', inventoryId)
            .select()
            .single();
        return DiaperInventory.fromMap(r);
      },
      optimisticResult: () => DiaperInventory(
        id: inventoryId,
        childId: '',
        size: '',
        quantity: 0,
        currency: 'KRW',
        openedAt: DateTime.now(),
      ),
    );
  }

  Future<DiaperInventory> markDepleted(String inventoryId) async {
    final patch = {'depleted_at': _today()};
    return OfflineWrites.execute<DiaperInventory>(
      ref: _ref,
      table: 'diaper_inventories',
      op: 'update',
      rowId: inventoryId,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('diaper_inventories')
            .update(patch)
            .eq('id', inventoryId)
            .select()
            .single();
        return DiaperInventory.fromMap(r);
      },
      optimisticResult: () => DiaperInventory(
        id: inventoryId,
        childId: '',
        size: '',
        quantity: 0,
        currency: 'KRW',
        depletedAt: DateTime.now(),
      ),
    );
  }

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

  String _dateOrNull(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<DiaperInventory> updateInventory({
    required String id,
    required String size,
    required int quantity,
    String? brand,
    String? usageKind,
    DateTime? purchasedAt,
    int? priceMinor,
    String? store,
    DateTime? openedAt,
  }) async {
    final patch = <String, dynamic>{
      'size': size,
      'quantity': quantity,
      'brand': brand,
      'usage_kind': usageKind,
      'purchased_at': purchasedAt == null ? null : _dateOrNull(purchasedAt),
      'price_minor': priceMinor,
      'store': store,
      'opened_at': openedAt == null ? null : _dateOrNull(openedAt),
    };
    return OfflineWrites.execute<DiaperInventory>(
      ref: _ref,
      table: 'diaper_inventories',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('diaper_inventories')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
        return DiaperInventory.fromMap(r);
      },
      optimisticResult: () => DiaperInventory(
        id: id,
        childId: '',
        size: size,
        quantity: quantity,
        currency: 'KRW',
        brand: brand,
        usageKind: usageKind,
        purchasedAt: purchasedAt,
        priceMinor: priceMinor,
        store: store,
        openedAt: openedAt,
      ),
    );
  }

  Future<void> deleteInventory(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'diaper_inventories',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('diaper_inventories').delete().eq('id', id);
      },
    );
  }
}

final diaperInventoryRepositoryProvider =
    Provider<DiaperInventoryRepository>((ref) {
  return DiaperInventoryRepository(ref.watch(supabaseClientProvider), ref);
});
