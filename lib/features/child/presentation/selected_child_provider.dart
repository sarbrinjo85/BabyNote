import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/child.dart';
import 'child_providers.dart';

/// 현재 선택된 자녀 ID — 사용자가 자녀 picker로 선택. null이면 자녀 1명 자동 또는 미선택.
///
/// ── 왜 `StateProvider<String?>`인가 ────────────────────────────────────
/// Child 객체를 직접 저장하면 myChildrenProvider 갱신 시 stale 객체가 됨.
/// id만 저장하고 selectedChildProvider에서 매번 lookup → 항상 최신 데이터.
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

/// 현재 선택된 자녀 객체. selectedChildIdProvider + myChildrenProvider 조합.
///
/// ── 자동 fallback ────────────────────────────────────────────────────
/// - 자녀 0명: null
/// - 자녀 1명: 자동으로 첫 자녀 (사용자 선택 불필요)
/// - 자녀 2+명: selectedChildId가 있으면 그것, 없거나 무효면 첫 자녀
final selectedChildProvider = Provider<Child?>((ref) {
  final asyncChildren = ref.watch(myChildrenProvider);
  return asyncChildren.maybeWhen(
    data: (children) {
      if (children.isEmpty) return null;
      final id = ref.watch(selectedChildIdProvider);
      if (id == null) return children.first;
      // id가 있는데 그 자녀가 더 이상 없으면(삭제 등) 첫 자녀로 fallback.
      for (final c in children) {
        if (c.id == id) return c;
      }
      return children.first;
    },
    orElse: () => null,
  );
});
