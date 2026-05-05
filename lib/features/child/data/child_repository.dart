import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../domain/child.dart';

/// children 테이블 CRUD 담당.
///
/// ── RLS와의 협조 ──────────────────────────────────────────────────
/// children 테이블의 RLS 정책(06_rls_policies.sql)은 다음을 강제:
///   - INSERT: created_by = auth.uid()  → 즉, 자기 자신을 생성자로만 등록 가능
///   - SELECT: is_caregiver_of(id)        → 케어기버 관계 있는 자녀만 보임
///
/// children INSERT 직후 add_creator_as_caregiver 트리거가 caregivers row를
/// 자동으로 만들어주므로, 방금 등록한 자녀가 즉시 SELECT 결과에 포함됨.
/// (트리거가 없으면 INSERT는 되지만 RLS의 SELECT가 막혀 본인이 본인 자녀를
///  못 보는 황당한 상황이 됨. 트리거가 이걸 자연스럽게 해결.)
class ChildRepository {
  ChildRepository(this._client);

  final SupabaseClient _client;

  /// 새 자녀 등록.
  ///
  /// created_by는 클라이언트에서 보내지 않음 — 서버 트리거(children_set_created_by)가
  /// auth.uid()로 자동 채움. JWT mismatch로 인한 RLS reject를 방지.
  Future<Child> createChild({
    required String name,
    required DateTime birthDate,
    String? gender,
    int? birthWeightG,
    int? birthHeightMm,
  }) async {
    final draft = Child(
      id: 'pending', // 서버가 채울 거라 placeholder
      name: name,
      birthDate: birthDate,
      gender: gender,
      birthWeightG: birthWeightG,
      birthHeightMm: birthHeightMm,
    );

    // ── insert(...).select() 패턴 ──────────────────────────────────
    // INSERT 후 그 row를 다시 SELECT해서 받음 (서버가 채운 id, created_at, created_by 포함).
    // .single() = 정확히 1행 기대. 0행이거나 2행 이상이면 throw.
    final inserted = await _client
        .from('children')
        .insert(draft.toInsertMap())
        .select()
        .single();

    return Child.fromMap(inserted);
  }

  /// 내가 케어기버로 묶여있는 모든 자녀를 가져옴.
  /// RLS 정책이 자동 필터링 → WHERE 안 써도 됨.
  Future<List<Child>> listMyChildren() async {
    final rows = await _client
        .from('children')
        .select()
        .order('birth_date', ascending: true);
    // rows는 List<dynamic>. 각 항목을 Map으로 캐스팅 후 Child로 변환.
    return rows.map((r) => Child.fromMap(r)).toList();
  }

  /// 자녀 정보 부분 수정 — 모든 필드 nullable, 명시 안 한 필드는 그대로.
  ///
  /// gender는 null 의도 표현 못 함(DB에서 null 허용이라 충돌). 일단 string으로 강제.
  Future<Child> updateChild({
    required String id,
    required String name,
    required DateTime birthDate,
    String? gender,
    int? birthWeightG,
    int? birthHeightMm,
  }) async {
    final patch = <String, dynamic>{
      'name': name,
      'birth_date':
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      'gender': gender,
      'birth_weight_g': birthWeightG,
      'birth_height_mm': birthHeightMm,
    };
    final updated = await _client
        .from('children')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Child.fromMap(updated);
  }

  /// 자녀 삭제. children에 cascade FK가 걸린 records/inventories/caregivers 등도
  /// 함께 삭제됨. 호출 측에서 confirm dialog로 신중히 처리할 것.
  Future<void> deleteChild(String id) async {
    await _client.from('children').delete().eq('id', id);
  }
}

/// ChildRepository의 인스턴스를 만들고 SupabaseClient를 주입.
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository(ref.watch(supabaseClientProvider));
});
