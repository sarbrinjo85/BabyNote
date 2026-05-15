import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/feeding.dart';

/// feedings 테이블 CRUD + 사진 업로드.
///
/// RLS 정책(06_rls_policies.sql):
///   - INSERT: is_caregiver_of(child_id) AND recorded_by = auth.uid()
///   - SELECT: is_caregiver_of(child_id) → 케어기버 모두 같은 자녀의 기록 공유
///
/// ── 오프라인 지원 ──────────────────────────────────────────────────────
/// INSERT/UPDATE/DELETE 는 OfflineWrites 로 감싸져 네트워크 실패 시 큐잉.
/// 사진 업로드(Supabase Storage)는 큐잉 대상 X — 파일 자체가 binary 라
/// 큐 payload 에 담기 어려움. 오프라인에서 사진 첨부 시도는 그 자리에서 실패
/// (사용자에게 노출), 다시 시도 권유.
class FeedingRepository {
  FeedingRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Feeding> createFeeding({
    required String currentUserId,
    required String childId,
    required String type, // 'breast' | 'formula' | 'solid'
    required DateTime startedAt,
    DateTime? endedAt,
    int? amountMl,
    String? breastSide,
    String? foodName,
    String? formulaBrand,
    String? formulaInventoryId,
    String? note,
    String? photoPath,
  }) async {
    final id = genUuid();
    final draft = Feeding(
      id: id,
      childId: childId,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt,
      amountMl: amountMl,
      breastSide: breastSide,
      foodName: foodName,
      formulaBrand: formulaBrand,
      formulaInventoryId: formulaInventoryId,
      note: note,
      photoPath: photoPath,
      recordedBy: currentUserId,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Feeding>(
      ref: _ref,
      table: 'feedings',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('feedings')
            .insert(payload)
            .select()
            .single();
        return Feeding.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  /// 이미지 파일을 feeding-photos bucket에 업로드 → Storage path 반환.
  /// 큐잉 대상 아님 — Storage 업로드는 온라인 전용.
  Future<String> uploadFeedingPhoto({
    required String userId,
    required File file,
  }) async {
    final originalPath = file.path.toLowerCase();
    String ext = 'jpg';
    if (originalPath.endsWith('.png')) {
      ext = 'png';
    } else if (originalPath.endsWith('.webp')) {
      ext = 'webp';
    } else if (originalPath.endsWith('.heic')) {
      ext = 'heic';
    }

    final now = DateTime.now();
    final ts =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final rand = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final path = '$userId/${ts}_$rand.$ext';

    await _client.storage.from('feeding-photos').upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
    return path;
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Future<List<Feeding>> listRecent(String childId, {int limit = 20}) async {
    final rows = await _client
        .from('feedings')
        .select()
        .eq('child_id', childId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Feeding.fromMap(r)).toList();
  }

  Future<void> deleteFeeding(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'feedings',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('feedings').delete().eq('id', id);
      },
    );
  }

  Future<Feeding> updateFeeding({
    required String id,
    required String type,
    int? amountMl,
    String? breastSide,
    String? foodName,
    String? formulaBrand,
    String? note,
  }) async {
    // null로 명시적 clear 가능하게 patch는 모든 키 포함.
    final patch = <String, dynamic>{
      'type': type,
      'amount_ml': amountMl,
      'breast_side': breastSide,
      'food_name': foodName,
      'formula_brand': formulaBrand,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    };
    return OfflineWrites.execute<Feeding>(
      ref: _ref,
      table: 'feedings',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('feedings')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
        return Feeding.fromMap(r);
      },
      // 오프라인 옵티미스틱 — 호출자가 전달한 필드만으로 임시 Feeding 구성.
      // startedAt 등 일부 필드는 알 수 없어 minimum 정보로. 실제 sync 후 invalidate.
      optimisticResult: () => Feeding(
        id: id,
        childId: '', // 옵티미스틱 placeholder — invalidate 후 정확히 갱신
        type: type,
        startedAt: DateTime.now(),
        amountMl: amountMl,
        breastSide: breastSide,
        foodName: foodName,
        formulaBrand: formulaBrand,
        note: note,
      ),
    );
  }
}

final feedingRepositoryProvider = Provider<FeedingRepository>((ref) {
  return FeedingRepository(ref.watch(supabaseClientProvider), ref);
});
