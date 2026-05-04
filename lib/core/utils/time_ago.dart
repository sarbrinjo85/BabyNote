/// "X분 전 / X시간 전 / 어제 / X일 전" 같은 상대 시간 포맷팅.
///
/// ── 왜 직접 구현 ────────────────────────────────────────────────────
/// `timeago` 패키지가 있긴 하지만 Phase 2 시점에 의존성 추가는 부담.
/// 베이비노트 사용 시나리오는 "최근 활동" 위주라 정밀한 다국어보다
/// 가벼운 한국어 직접 구현이 더 적절.
///
/// ── 임계값 ──────────────────────────────────────────────────────────
/// - 60초 이내      → "방금 전"
/// - 60분 이내      → "N분 전"
/// - 24시간 이내    → "N시간 전"
/// - 어제           → "어제 HH:mm"
/// - 7일 이내       → "N일 전"
/// - 그 이상        → "YYYY-MM-DD"
class TimeAgo {
  const TimeAgo._();

  static String format(DateTime past, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(past);

    if (diff.isNegative) return '방금 전'; // 미래 시각은 보정

    if (diff.inSeconds < 60) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';

    // 날짜 기준 비교 (시간 무시)
    final today = DateTime(reference.year, reference.month, reference.day);
    final pastDate = DateTime(past.year, past.month, past.day);
    final daysAgo = today.difference(pastDate).inDays;

    if (daysAgo == 1) {
      return '어제 ${_two(past.hour)}:${_two(past.minute)}';
    }
    if (daysAgo <= 7) return '$daysAgo일 전';

    return '${past.year}-${_two(past.month)}-${_two(past.day)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
