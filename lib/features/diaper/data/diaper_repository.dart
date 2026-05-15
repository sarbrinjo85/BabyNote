import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/diaper.dart';

/// diapers 테이블 CRUD. 패턴은 F1(feedings)과 동일.
/// 오프라인 시 OfflineWrites 가 큐잉, SyncWorker 가 자동 flush.
class DiaperRepository {
  DiaperRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Diaper> createDiaper({
    required String currentUserId,
    required String childId,
    required String type,
    required DateTime recordedAt,
    String? color,
    String? consistency,
    String? amount,
    String? diaperInventoryId,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Diaper(
      id: id,
      childId: childId,
      recordedAt: recordedAt,
      type: type,
      color: color,
      consistency: consistency,
      amount: amount,
      diaperInventoryId: diaperInventoryId,
      note: note,
      recordedBy: currentUserId,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Diaper>(
      ref: _ref,
      table: 'diapers',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r =
            await _client.from('diapers').insert(payload).select().single();
        return Diaper.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  Future<void> deleteDiaper(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'diapers',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('diapers').delete().eq('id', id);
      },
    );
  }

  Future<void> updateDiaper({
    required String id,
    required String type,
    String? color,
    String? consistency,
    String? amount,
    String? note,
  }) async {
    final patch = <String, dynamic>{
      'type': type,
      'color': color,
      'consistency': consistency,
      'amount': amount,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    };
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'diapers',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        await _client.from('diapers').update(patch).eq('id', id);
      },
    );
  }

  Future<List<Diaper>> listRecent(String childId, {int limit = 20}) async {
    final rows = await _client
        .from('diapers')
        .select()
        .eq('child_id', childId)
        .order('recorded_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Diaper.fromMap(r)).toList();
  }
}

final diaperRepositoryProvider = Provider<DiaperRepository>((ref) {
  return DiaperRepository(ref.watch(supabaseClientProvider), ref);
});
