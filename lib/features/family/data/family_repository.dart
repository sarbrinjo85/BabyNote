import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/caregiver.dart';
import '../domain/caregiver_invite.dart';

/// 가족 공유 (caregivers + caregiver_invites) 데이터 접근.
///
/// ── 코드 생성 정책 ───────────────────────────────────────────────────
/// 6자리 영숫자 대문자 (예: A3B7K9). 혼동 글자(0/O/1/I/L) 제외.
/// 24시간 만료가 default. 코드 충돌은 `unique partial index` + 재시도로 방지.
class FamilyRepository {
  FamilyRepository(this._client);
  final SupabaseClient _client;

  /// 자녀의 caregivers 목록 (user_profiles JOIN). accepted_at IS NOT NULL만.
  Future<List<Caregiver>> listCaregivers(String childId) async {
    final rows = await _client
        .from('caregivers')
        .select('id, child_id, user_id, role, accepted_at, '
            'user_profile:user_profiles!caregivers_user_id_fkey(display_name)')
        .eq('child_id', childId)
        .not('accepted_at', 'is', null)
        .order('accepted_at', ascending: true);
    return (rows as List)
        .map((m) => Caregiver.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// 자녀의 활성 초대 코드들 (만료 안 됨 + 미사용).
  Future<List<CaregiverInvite>> listActiveInvites(String childId) async {
    final rows = await _client
        .from('caregiver_invites')
        .select()
        .eq('child_id', childId)
        .filter('used_at', 'is', null)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    return (rows as List)
        .map((m) => CaregiverInvite.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// 새 초대 코드 발급. 충돌 시 자동 재시도.
  Future<CaregiverInvite> createInvite({
    required String childId,
    required String createdBy,
    String role = 'parent',
    Duration validFor = const Duration(hours: 24),
  }) async {
    // 최대 5번 재시도 (실제로는 1회에 거의 항상 성공)
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      try {
        final inserted = await _client
            .from('caregiver_invites')
            .insert({
              'child_id': childId,
              'created_by': createdBy,
              'code': code,
              'role': role,
              'expires_at':
                  DateTime.now().add(validFor).toIso8601String(),
            })
            .select()
            .single();
        return CaregiverInvite.fromMap(inserted);
      } on PostgrestException catch (e) {
        // 23505 = unique violation (코드 충돌). 재시도.
        if (e.code == '23505') continue;
        rethrow;
      }
    }
    throw StateError('코드 발급 실패 — 잠시 후 다시 시도해주세요.');
  }

  /// 초대 코드 사용 — RPC 호출. 성공 시 child_id 반환.
  Future<String> redeemInvite(String code) async {
    final result = await _client.rpc('redeem_invite', params: {
      'p_code': code.toUpperCase().trim(),
    });
    return result as String;
  }

  /// caregiver row 삭제 (본인이 가족에서 나가기 또는 다른 caregiver를 내보내기).
  Future<void> removeCaregiver(String caregiverId) async {
    await _client.from('caregivers').delete().eq('id', caregiverId);
  }

  /// 초대 코드 회수.
  Future<void> revokeInvite(String inviteId) async {
    await _client.from('caregiver_invites').delete().eq('id', inviteId);
  }

  /// 6자리 코드 생성. 혼동 글자 제외 + 모두 대문자.
  static String _generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buf.write(chars[rng.nextInt(chars.length)]);
    }
    return buf.toString();
  }
}

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FamilyRepository(client);
});
