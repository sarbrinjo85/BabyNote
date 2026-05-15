import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/symptom.dart';

/// symptoms 테이블 CRUD + 'symptom-photos' Storage 업로드.
///
/// ── 사진 패턴 ────────────────────────────────────────────────────────
/// feeding_repository.uploadFeedingPhoto 와 동일:
///   path = `<userId>/<YYYYMMDD_HHmmss>_<rand>.<ext>`
///   user_id 폴더 분리 → 11/17 마이그레이션의 Storage RLS 가 본인 폴더만 허용.
class SymptomRepository {
  SymptomRepository(this._client);

  final SupabaseClient _client;

  Future<Symptom> create({
    required String currentUserId,
    required String childId,
    required SymptomKind kind,
    required DateTime occurredAt,
    Severity? severity,
    String? photoPath,
    String? note,
  }) async {
    final draft = Symptom(
      id: 'pending',
      childId: childId,
      kind: kind,
      occurredAt: occurredAt,
      severity: severity,
      photoPath: photoPath,
      note: note,
    );
    final inserted = await _client
        .from('symptoms')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();
    return Symptom.fromMap(inserted);
  }

  Future<Symptom> update(Symptom symptom) async {
    final updated = await _client
        .from('symptoms')
        .update(symptom.toUpdateMap())
        .eq('id', symptom.id)
        .select()
        .single();
    return Symptom.fromMap(updated);
  }

  Future<void> delete(String id) async {
    await _client.from('symptoms').delete().eq('id', id);
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
  /// 미리 사용자가 Dashboard에서 'symptom-photos' bucket을 Public 으로 생성해둬야 함.
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
  return SymptomRepository(ref.watch(supabaseClientProvider));
});
