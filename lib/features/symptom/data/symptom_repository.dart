import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
import '../../../data/supabase_client_provider.dart';
import '../domain/symptom.dart';

/// symptoms 테이블 CRUD + 'symptom-photos' Storage 업로드.
///
/// ── 오프라인 ─────────────────────────────────────────────────────────
/// row INSERT/UPDATE/DELETE 는 OfflineWrites 로 큐잉.
/// 사진 업로드(`uploadSymptomPhoto`)는 큐잉 대상 X — Storage 의 binary 는
/// 큐 payload 에 담기 어려움. 컨트롤러가 사진 업로드 실패하면 토스트로 알리고
/// row 만 큐잉 (photoPath null) 하거나 전체 실패시키는 등 결정.
///
/// ── 사진 path 규칙 ───────────────────────────────────────────────────
/// `<userId>/<YYYYMMDD_HHmmss>_<rand>.<ext>` — user_id 폴더 분리로 17 마이그레이션의
/// Storage RLS 가 본인 폴더만 허용.
class SymptomRepository {
  SymptomRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Symptom> create({
    required String currentUserId,
    required String childId,
    required SymptomKind kind,
    required DateTime occurredAt,
    Severity? severity,
    String? photoPath,
    String? note,
  }) async {
    final id = genUuid();
    final draft = Symptom(
      id: id,
      childId: childId,
      kind: kind,
      occurredAt: occurredAt,
      severity: severity,
      photoPath: photoPath,
      note: note,
      recordedBy: currentUserId,
    );
    final payload = draft.toInsertMap(recordedBy: currentUserId);

    return OfflineWrites.execute<Symptom>(
      ref: _ref,
      table: 'symptoms',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r =
            await _client.from('symptoms').insert(payload).select().single();
        return Symptom.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  Future<Symptom> update(Symptom symptom) async {
    final payload = symptom.toUpdateMap();
    return OfflineWrites.execute<Symptom>(
      ref: _ref,
      table: 'symptoms',
      op: 'update',
      rowId: symptom.id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('symptoms')
            .update(payload)
            .eq('id', symptom.id)
            .select()
            .single();
        return Symptom.fromMap(r);
      },
      optimisticResult: () => symptom,
    );
  }

  Future<void> delete(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'symptoms',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('symptoms').delete().eq('id', id);
      },
    );
  }

  Future<List<Symptom>> listRecent(String childId, {int limit = 30}) async {
    final rows = await _client
        .from('symptoms')
        .select()
        .eq('child_id', childId)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Symptom.fromMap(r)).toList();
  }

  Future<List<Symptom>> listRecentByKind(
    String childId,
    SymptomKind kind, {
    int limit = 20,
  }) async {
    final rows = await _client
        .from('symptoms')
        .select()
        .eq('child_id', childId)
        .eq('kind', kind.dbValue)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Symptom.fromMap(r)).toList();
  }

  /// 사진을 'symptom-photos' bucket 에 업로드 → Storage path 반환.
  /// 큐잉 대상 아님 — Storage 업로드는 온라인 전용.
  Future<String> uploadSymptomPhoto({
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

    await _client.storage.from('symptom-photos').upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
    return path;
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository(ref.watch(supabaseClientProvider), ref);
});
