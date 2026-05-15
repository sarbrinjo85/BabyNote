import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/offline_writes.dart';
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
///
/// ── 오프라인 ─────────────────────────────────────────────────────────
/// 오프라인 큐잉 가능. 클라이언트 UUID 발급 → flush 시 동일 id 로 INSERT.
/// 트리거(created_by 자동 + caregiver 자동)는 flush 시점에 정상 동작 (auth.uid()
/// 가 큐잉 당시 사용자와 같으면).
class ChildRepository {
  ChildRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<Child> createChild({
    required String name,
    required DateTime birthDate,
    String? gender,
    int? birthWeightG,
    int? birthHeightMm,
  }) async {
    final id = genUuid();
    final draft = Child(
      id: id,
      name: name,
      birthDate: birthDate,
      gender: gender,
      birthWeightG: birthWeightG,
      birthHeightMm: birthHeightMm,
    );
    final payload = draft.toInsertMap();

    return OfflineWrites.execute<Child>(
      ref: _ref,
      table: 'children',
      op: 'insert',
      rowId: id,
      payload: payload,
      onlineCall: () async {
        final r = await _client
            .from('children')
            .insert(payload)
            .select()
            .single();
        return Child.fromMap(r);
      },
      optimisticResult: () => draft,
    );
  }

  /// 내가 케어기버로 묶여있는 모든 자녀를 가져옴.
  /// RLS 정책이 자동 필터링 → WHERE 안 써도 됨.
  Future<List<Child>> listMyChildren() async {
    final rows = await _client
        .from('children')
        .select()
        .order('birth_date', ascending: true);
    return rows.map((r) => Child.fromMap(r)).toList();
  }

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
    return OfflineWrites.execute<Child>(
      ref: _ref,
      table: 'children',
      op: 'update',
      rowId: id,
      payload: patch,
      onlineCall: () async {
        final r = await _client
            .from('children')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
        return Child.fromMap(r);
      },
      optimisticResult: () => Child(
        id: id,
        name: name,
        birthDate: birthDate,
        gender: gender,
        birthWeightG: birthWeightG,
        birthHeightMm: birthHeightMm,
      ),
    );
  }

  /// 자녀 삭제. children에 cascade FK가 걸린 records/inventories/caregivers 등도
  /// 함께 삭제됨. 호출 측에서 confirm dialog로 신중히 처리할 것.
  Future<void> deleteChild(String id) async {
    return OfflineWrites.executeVoid(
      ref: _ref,
      table: 'children',
      op: 'delete',
      rowId: id,
      payload: const {},
      onlineCall: () async {
        await _client.from('children').delete().eq('id', id);
      },
    );
  }
}

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository(ref.watch(supabaseClientProvider), ref);
});
