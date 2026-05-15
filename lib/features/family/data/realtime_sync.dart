import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../diaper/presentation/diaper_providers.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../growth/presentation/growth_providers.dart';
import '../../routine/domain/routine.dart';
import '../../routine/presentation/routine_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';
import '../../stats/presentation/stats_providers.dart';
import '../../symptom/domain/symptom.dart';
import '../../symptom/presentation/symptom_providers.dart';

/// 가족 다른 사용자가 추가한 활동에 대한 토스트 알림 큐.
/// HomePage에서 listen해서 SnackBar로 표시.
class FamilyActivityEvent {
  const FamilyActivityEvent({required this.kind, required this.icon});
  final String kind; // 수유 / 수면 / 기저귀 / 성장
  final String icon;
}

final familyActivityFeedProvider = StateProvider<FamilyActivityEvent?>((ref) => null);

/// 가족 공유 실시간 동기화 — 자녀별 6개 테이블
/// (feedings/sleeps/diapers/growths/routines/symptoms) INSERT/UPDATE/DELETE 구독.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// - 같은 자녀에 대한 caregivers가 한 명이라도 기록을 추가/수정/삭제하면
///   해당 자녀의 모든 클라이언트 화면이 즉시 갱신됨
/// - 채널 이름은 `child:{id}` — Supabase가 동일 채널 구독자에게 fan-out
/// - Riverpod ref.onDispose로 채널 정리 → autoDispose 또는 family unsubscribe 시 cleanup
///
/// ── 사용 ─────────────────────────────────────────────────────────────
/// HomePage 등 자녀 선택 화면에서:
///   ref.watch(childRealtimeSyncProvider(childId));
/// child 바뀌면 이전 구독은 자동 dispose, 새 구독 시작.
final childRealtimeSyncProvider =
    Provider.family.autoDispose<void, String>((ref, childId) {
  final supa = ref.watch(supabaseClientProvider);
  final myUserId = ref.watch(currentUserProvider)?.id;
  final channel = supa.channel('child:$childId');

  // child_id로 필터된 PostgresChange listener 4개 등록.
  // payload의 created_by(또는 recorded_by)와 내 userId 비교 → 다른 사람이 추가한
  // 경우 활동 알림 이벤트 발행.
  void listenTable({
    required String table,
    required void Function(PostgresChangePayload payload) onChange,
  }) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'child_id',
        value: childId,
      ),
      callback: onChange,
    );
  }

  void publishActivity(
      PostgresChangePayload payload, String kind, String icon) {
    if (payload.eventType != PostgresChangeEvent.insert) return;
    final newRow = payload.newRecord;
    final by = (newRow['created_by'] ?? newRow['recorded_by']) as String?;
    if (by == null || by == myUserId) return; // 내가 한 거면 토스트 X
    try {
      ref.read(familyActivityFeedProvider.notifier).state =
          FamilyActivityEvent(kind: kind, icon: icon);
    } catch (e) {
      debugPrint('familyActivityFeed publish error: $e');
    }
  }

  listenTable(
    table: 'feedings',
    onChange: (payload) {
      ref.invalidate(recentFeedingsProvider(childId));
      ref.invalidate(statsFeedingsProvider(childId));
      publishActivity(payload, '수유', '🍼');
    },
  );
  listenTable(
    table: 'sleeps',
    onChange: (payload) {
      ref.invalidate(recentSleepsProvider(childId));
      ref.invalidate(statsSleepsProvider(childId));
      publishActivity(payload, '수면', '💤');
    },
  );
  listenTable(
    table: 'diapers',
    onChange: (payload) {
      ref.invalidate(recentDiapersProvider(childId));
      ref.invalidate(statsDiapersProvider(childId));
      publishActivity(payload, '기저귀', '💩');
    },
  );
  listenTable(
    table: 'growths',
    onChange: (payload) {
      ref.invalidate(growthsProvider(childId));
      ref.invalidate(statsGrowthsProvider(childId));
      publishActivity(payload, '성장', '📏');
    },
  );
  // ── routines / symptoms — kind 컬럼 기반으로 구체적 라벨 ────────────
  // 예: "🚶 가족이 산책 기록을 남겼어요" / "🩹 가족이 발진 기록을 남겼어요"
  // INSERT가 아니거나 kind 매핑 실패 시 통합 라벨로 fallback.
  listenTable(
    table: 'routines',
    onChange: (payload) {
      ref.invalidate(recentRoutinesProvider(childId));
      ref.invalidate(statsRoutinesProvider(childId));
      final kindStr = payload.newRecord['kind'] as String?;
      String label = '루틴';
      String icon = '🚶';
      if (kindStr != null) {
        try {
          final k = RoutineKind.fromDbValue(kindStr);
          icon = k.emoji;
          label = switch (k) {
            RoutineKind.walk => '산책',
            RoutineKind.bath => '목욕',
            RoutineKind.supplement => '영양제',
            RoutineKind.snack => '간식',
          };
        } catch (_) {/* 알 수 없는 kind: fallback */}
      }
      publishActivity(payload, label, icon);
    },
  );
  listenTable(
    table: 'symptoms',
    onChange: (payload) {
      ref.invalidate(recentSymptomsProvider(childId));
      ref.invalidate(statsSymptomsProvider(childId));
      final kindStr = payload.newRecord['kind'] as String?;
      String label = '건강 기록';
      String icon = '🩹';
      if (kindStr != null) {
        try {
          final k = SymptomKind.fromDbValue(kindStr);
          icon = k.emoji;
          label = switch (k) {
            SymptomKind.cough => '기침',
            SymptomKind.vomit => '구토',
            SymptomKind.rash => '발진',
            SymptomKind.injury => '상처',
          };
        } catch (_) {/* fallback */}
      }
      publishActivity(payload, label, icon);
    },
  );

  channel.subscribe();

  // 채널 정리 — 자녀가 바뀌거나 화면이 사라지면 구독 해제 (트래픽 절약)
  ref.onDispose(() {
    supa.removeChannel(channel);
  });
});
