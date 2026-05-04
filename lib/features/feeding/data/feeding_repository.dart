import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/feeding.dart';

/// feedings 테이블 CRUD.
///
/// RLS 정책(06_rls_policies.sql):
///   - INSERT: is_caregiver_of(child_id) AND recorded_by = auth.uid()
///   - SELECT: is_caregiver_of(child_id) → 케어기버 모두 같은 자녀의 기록 공유
class FeedingRepository {
  FeedingRepository(this._client);

  final SupabaseClient _client;

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
    final draft = Feeding(
      id: 'pending',
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
    );

    final inserted = await _client
        .from('feedings')
        .insert(draft.toInsertMap(recordedBy: currentUserId))
        .select()
        .single();

    return Feeding.fromMap(inserted);
  }

  /// 이미지 파일을 feeding-photos bucket에 업로드 → Storage path 반환.
  ///
  /// ── 경로 규칙 ────────────────────────────────────────────────────
  /// `<user_id>/<YYYYMMDD_HHmmss>_<random>.jpg`
  /// user_id 폴더로 분리하면 RLS 정책으로 본인 폴더만 쓰기 가능 (11 마이그레이션 참조).
  ///
  /// ── 반환값 ──────────────────────────────────────────────────────
  /// Storage 안의 path만 반환. UI에서 표시할 때는
  /// `supabase.storage.from('feeding-photos').getPublicUrl(path)`로 URL 생성.
  /// → DB에는 path만 저장(짧음 + bucket 변경 유연).
  Future<String> uploadFeedingPhoto({
    required String userId,
    required File file,
  }) async {
    // 파일 확장자 추출 — 못 알아내면 jpg fallback
    final originalPath = file.path.toLowerCase();
    String ext = 'jpg';
    if (originalPath.endsWith('.png')) {
      ext = 'png';
    } else if (originalPath.endsWith('.webp')) {
      ext = 'webp';
    } else if (originalPath.endsWith('.heic')) {
      ext = 'heic';
    }

    // 파일명 생성 (충돌 방지: 타임스탬프 + 랜덤)
    final now = DateTime.now();
    final ts =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final rand = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final path = '$userId/${ts}_$rand.$ext';

    await _client.storage.from('feeding-photos').upload(
          path,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600', // 1시간 캐시
            upsert: false, // 동명 파일 덮어쓰기 금지
          ),
        );
    return path;
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  /// 특정 자녀의 최근 수유 기록 N건 (최신순).
  Future<List<Feeding>> listRecent(String childId, {int limit = 20}) async {
    final rows = await _client
        .from('feedings')
        .select()
        .eq('child_id', childId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map((r) => Feeding.fromMap(r)).toList();
  }
}

final feedingRepositoryProvider = Provider<FeedingRepository>((ref) {
  return FeedingRepository(ref.watch(supabaseClientProvider));
});
