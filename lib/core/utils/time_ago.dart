import 'package:babynote/l10n/app_localizations.dart';

/// 상대 시간 포맷팅 — 다국어 지원.
///
/// l10n 인스턴스를 받아서 현재 로케일에 맞는 문자열 반환.
class TimeAgo {
  const TimeAgo._();

  static String format(AppLocalizations l10n, DateTime past, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(past);

    if (diff.isNegative) return l10n.timeJustNow;

    if (diff.inSeconds < 60) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);

    final today = DateTime(reference.year, reference.month, reference.day);
    final pastDate = DateTime(past.year, past.month, past.day);
    final daysAgo = today.difference(pastDate).inDays;

    if (daysAgo == 1) {
      return l10n.timeYesterdayAt('${_two(past.hour)}:${_two(past.minute)}');
    }
    if (daysAgo <= 7) return l10n.timeDaysAgo(daysAgo);

    return '${past.year}-${_two(past.month)}-${_two(past.day)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
