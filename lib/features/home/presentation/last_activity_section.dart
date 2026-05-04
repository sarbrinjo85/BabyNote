import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_ago.dart';
import '../../diaper/domain/diaper.dart';
import '../../diaper/presentation/diaper_providers.dart';
import '../../feeding/domain/feeding.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../growth/domain/growth.dart';
import '../../growth/presentation/growth_providers.dart';
import '../../sleep/domain/sleep.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// 홈에 표시되는 "마지막 활동" 섹션.
///
/// ── 구성 ────────────────────────────────────────────────────────────
/// 4개 기록(수유/수면/기저귀/성장)의 가장 최근 1건씩을 작은 카드로 노출.
/// 각 카드는:
///   - 이모지 + 활동 라벨
///   - 핵심 정보 1줄 (예: "분유 120ml", "낮잠 45분", "대변 노랑")
///   - 상대 시간 (예: "2시간 전")
/// 기록 0건이면 카드 자체를 숨김(섹션은 그대로).
///
/// ── 4개 provider 동시 watch ──────────────────────────────────────────
/// recent*Provider(family) 4개를 동시에 watch → AsyncValue 4개. 화면은 각 카드를
/// 독립적으로 자기 상태 표시. 한 카드가 로딩 중이어도 다른 카드는 표시됨.
class LastActivitySection extends ConsumerWidget {
  const LastActivitySection({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));
    final asyncGrowths = ref.watch(growthsProvider(childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityCard(
          icon: '🍼',
          label: '수유',
          value: asyncFeedings.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeFeeding(list.first),
            orElse: () => null,
          ),
          time: asyncFeedings.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(list.first.startedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '💤',
          label: '수면',
          value: asyncSleeps.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeSleep(list.first),
            orElse: () => null,
          ),
          time: asyncSleeps.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(list.first.startedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '💩',
          label: '기저귀',
          value: asyncDiapers.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeDiaper(list.first),
            orElse: () => null,
          ),
          time: asyncDiapers.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(list.first.recordedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '📏',
          label: '성장',
          value: asyncGrowths.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeGrowth(list.last),
            orElse: () => null,
          ),
          time: asyncGrowths.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(list.last.measuredAt),
            orElse: () => null,
          ),
        ),
      ],
    );
  }

  /// 수유 한 줄 요약. 예: "분유 120ml", "모유 (양쪽)", "이유식: 호박죽".
  String _summarizeFeeding(Feeding f) {
    switch (f.type) {
      case 'breast':
        final side = switch (f.breastSide) {
          'left' => '왼쪽',
          'right' => '오른쪽',
          'both' => '양쪽',
          _ => '',
        };
        return '모유${side.isEmpty ? '' : ' ($side)'}'
            '${f.amountMl != null ? ' · ${f.amountMl}ml' : ''}';
      case 'formula':
        final amount = f.amountMl != null ? '${f.amountMl}ml' : '';
        final brand = f.formulaBrand != null && f.formulaBrand!.isNotEmpty
            ? ' · ${f.formulaBrand}'
            : '';
        return '분유 $amount$brand';
      case 'solid':
        return '이유식: ${f.foodName ?? ''}';
      default:
        return f.type;
    }
  }

  /// 수면 한 줄. 진행 중이면 "낮잠 진행 중", 아니면 "낮잠 45분".
  String _summarizeSleep(Sleep s) {
    final kind = s.napOrNight == 'night' ? '밤잠' : '낮잠';
    if (s.isOngoing) return '$kind 진행 중';
    final minutes = s.elapsedMinutes(s.endedAt!);
    if (minutes < 60) return '$kind $minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$kind $h시간' : '$kind $h시간 $m분';
  }

  /// 기저귀 한 줄. 예: "대변 노랑 · 보통 · 보통".
  String _summarizeDiaper(Diaper d) {
    final type = switch (d.type) {
      'pee' => '소변',
      'poop' => '대변',
      'both' => '둘다',
      _ => d.type,
    };
    final parts = <String>[type];
    if (d.color != null) parts.add(_colorLabel(d.color!));
    if (d.consistency != null) parts.add(_consistencyLabel(d.consistency!));
    if (d.amount != null) parts.add(_amountLabel(d.amount!));
    return parts.join(' · ');
  }

  String _colorLabel(String c) => switch (c) {
        'yellow' => '노랑',
        'brown' => '갈색',
        'green' => '녹색',
        'black' => '검정',
        'red' => '빨강',
        'white' => '흰색',
        _ => '모름',
      };

  String _consistencyLabel(String c) => switch (c) {
        'loose' => '묽음',
        'normal' => '보통',
        'firm' => '단단함',
        _ => c,
      };

  String _amountLabel(String a) => switch (a) {
        'small' => '조금',
        'normal' => '보통',
        'large' => '많음',
        _ => a,
      };

  /// 성장 한 줄. 예: "8.45kg / 75.5cm".
  String _summarizeGrowth(Growth g) {
    final parts = <String>[];
    if (g.weightG != null) parts.add('${(g.weightG! / 1000).toStringAsFixed(2)}kg');
    if (g.heightMm != null) parts.add('${(g.heightMm! / 10).toStringAsFixed(1)}cm');
    if (g.headCircumferenceMm != null) {
      parts.add('머리 ${(g.headCircumferenceMm! / 10).toStringAsFixed(1)}cm');
    }
    return parts.join(' / ');
  }
}

/// 한 줄 활동 카드.
/// value/time이 모두 null이면 "아직 기록 없음" 회색 카드.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.time,
  });

  final String icon;
  final String label;
  final String? value;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  Text(
                    empty ? '아직 기록 없음' : value!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: empty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (time != null)
              Text(time!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
          ],
        ),
      ),
    );
  }
}
