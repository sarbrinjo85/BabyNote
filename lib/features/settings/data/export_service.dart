import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../child/domain/child.dart';
import '../../diaper/data/diaper_repository.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../growth/data/growth_repository.dart';
import '../../growth/domain/growth.dart';
import '../../sleep/data/sleep_repository.dart';
import '../../sleep/domain/sleep.dart';

/// 자녀의 모든 기록을 CSV로 묶어서 시스템 공유 시트로 내보내는 서비스.
///
/// ── CSV 포맷 ─────────────────────────────────────────────────────────
/// 의사 진료/엑셀 등 외부 도구에서 열기 쉽게 통합 컬럼:
/// type, date, time, detail, note
///
/// 예:
/// 수유,2026-05-05,14:30,분유 120ml,트림 잘 함
/// 수면,2026-05-05,13:00,낮잠 85분,
/// 기저귀,2026-05-05,14:50,대변 노랑 보통 보통,
/// 성장,2026-05-05,09:00,체중 8.45kg / 키 75.5cm,정기검진
///
/// ── 단순화 ──────────────────────────────────────────────────────────
/// 다국어 라벨(수유/Feeding 등)은 호출 측에서 주입 — 여러 라벨 매핑 표를 받아 사용.
/// CSV escape: 셀에 콤마/줄바꿈/큰따옴표 있으면 큰따옴표로 감싸기.
class ExportService {
  ExportService._({
    required this.feedingRepo,
    required this.sleepRepo,
    required this.diaperRepo,
    required this.growthRepo,
  });

  final FeedingRepository feedingRepo;
  final SleepRepository sleepRepo;
  final DiaperRepository diaperRepo;
  final GrowthRepository growthRepo;

  /// 자녀의 모든 기록을 CSV로 만들어 공유 시트 띄우기.
  /// labels는 type 라벨 + diaper 색상/형태/양 등 다국어 텍스트 매핑.
  Future<void> exportChildToCsv({
    required Child child,
    required ExportLabels labels,
  }) async {
    // 데이터 fetch — 충분히 큰 limit (1000건). 더 많으면 페이징 필요.
    final feedings = await feedingRepo.listRecent(child.id, limit: 1000);
    final sleeps = await sleepRepo.listRecent(child.id, limit: 1000);
    final diapers = await diaperRepo.listRecent(child.id, limit: 1000);
    final growths = await growthRepo.listAll(child.id);

    final rows = <List<String>>[];
    rows.add(['type', 'date', 'time', 'detail', 'note']);

    for (final f in feedings) {
      rows.add([
        labels.feeding,
        _date(f.startedAt),
        _time(f.startedAt),
        _feedingDetail(f, labels),
        f.note ?? '',
      ]);
    }
    for (final s in sleeps) {
      rows.add([
        labels.sleep,
        _date(s.startedAt),
        _time(s.startedAt),
        _sleepDetail(s, labels),
        s.note ?? '',
      ]);
    }
    for (final d in diapers) {
      rows.add([
        labels.diaper,
        _date(d.recordedAt),
        _time(d.recordedAt),
        _diaperDetail(d, labels),
        d.note ?? '',
      ]);
    }
    for (final g in growths) {
      rows.add([
        labels.growth,
        _date(g.measuredAt),
        _time(g.measuredAt),
        _growthDetail(g),
        g.note ?? '',
      ]);
    }

    // 시간 역순 정렬 (헤더 제외) — 최신 위.
    final header = rows.first;
    final body = rows.sublist(1);
    body.sort((a, b) => '${b[1]} ${b[2]}'.compareTo('${a[1]} ${a[2]}'));

    final csv = _toCsv([header, ...body]);

    // 임시 파일에 쓰고 share_plus로 공유 시트
    final dir = await getTemporaryDirectory();
    final safeName = child.name.replaceAll(RegExp(r'[^A-Za-z0-9가-힣]'), '_');
    final filename = '${safeName}_${_dateCompact(DateTime.now())}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: filename)],
      subject: '${child.name} - BabyNote',
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────

  String _feedingDetail(Feeding f, ExportLabels l) {
    switch (f.type) {
      case 'breast':
        final side = switch (f.breastSide) {
          'left' => l.breastLeft,
          'right' => l.breastRight,
          'both' => l.breastBoth,
          _ => '',
        };
        final amount = f.amountMl != null ? ' ${f.amountMl}ml' : '';
        return '${l.breast}${side.isEmpty ? '' : ' ($side)'}$amount';
      case 'formula':
        final amount = f.amountMl != null ? ' ${f.amountMl}ml' : '';
        final brand = f.formulaBrand != null && f.formulaBrand!.isNotEmpty
            ? ' / ${f.formulaBrand}'
            : '';
        return '${l.formula}$amount$brand';
      case 'solid':
        final amount = f.amountMl != null ? ' (${f.amountMl}ml)' : '';
        return '${l.solid}: ${f.foodName ?? ''}$amount';
      default:
        return f.type;
    }
  }

  String _sleepDetail(Sleep s, ExportLabels l) {
    final kind = s.napOrNight == 'night' ? l.night : l.nap;
    if (s.endedAt == null) return '$kind (${l.ongoing})';
    final mins = s.elapsedMinutes(s.endedAt!);
    return '$kind ${mins}m';
  }

  String _diaperDetail(Diaper d, ExportLabels l) {
    final type = switch (d.type) {
      'pee' => l.pee,
      'poop' => l.poop,
      'both' => l.peeAndPoop,
      _ => d.type,
    };
    final parts = <String>[type];
    if (d.color != null) {
      parts.add(switch (d.color!) {
        'yellow' => l.yellow,
        'brown' => l.brown,
        'green' => l.green,
        'black' => l.black,
        'red' => l.red,
        'white' => l.white,
        _ => l.unknown,
      });
    }
    if (d.consistency != null) {
      parts.add(switch (d.consistency!) {
        'loose' => l.loose,
        'normal' => l.normal,
        'firm' => l.firm,
        _ => d.consistency!,
      });
    }
    if (d.amount != null) {
      parts.add(switch (d.amount!) {
        'small' => l.small,
        'normal' => l.normal,
        'large' => l.large,
        _ => d.amount!,
      });
    }
    return parts.join(' ');
  }

  String _growthDetail(Growth g) {
    final parts = <String>[];
    if (g.weightG != null) {
      parts.add('${(g.weightG! / 1000).toStringAsFixed(2)}kg');
    }
    if (g.heightMm != null) {
      parts.add('${(g.heightMm! / 10).toStringAsFixed(1)}cm');
    }
    if (g.headCircumferenceMm != null) {
      parts.add('${(g.headCircumferenceMm! / 10).toStringAsFixed(1)}cm');
    }
    return parts.join(' / ');
  }

  String _date(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.hour)}:${two(l.minute)}';
  }

  String _dateCompact(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}';
  }

  String _toCsv(List<List<String>> rows) {
    String escape(String v) {
      if (v.contains(',') || v.contains('"') || v.contains('\n')) {
        return '"${v.replaceAll('"', '""')}"';
      }
      return v;
    }

    final buf = StringBuffer();
    // BOM 추가 — Excel/한글에서 UTF-8 인식 보장
    buf.write('﻿');
    for (final row in rows) {
      buf.writeln(row.map(escape).join(','));
    }
    return buf.toString();
  }
}

/// CSV 라벨 묶음 — UI 레이어에서 l10n으로 채워서 주입.
class ExportLabels {
  const ExportLabels({
    required this.feeding,
    required this.sleep,
    required this.diaper,
    required this.growth,
    required this.breast,
    required this.formula,
    required this.solid,
    required this.breastLeft,
    required this.breastRight,
    required this.breastBoth,
    required this.nap,
    required this.night,
    required this.ongoing,
    required this.pee,
    required this.poop,
    required this.peeAndPoop,
    required this.yellow,
    required this.brown,
    required this.green,
    required this.black,
    required this.red,
    required this.white,
    required this.unknown,
    required this.loose,
    required this.normal,
    required this.firm,
    required this.small,
    required this.large,
  });

  final String feeding, sleep, diaper, growth;
  final String breast, formula, solid;
  final String breastLeft, breastRight, breastBoth;
  final String nap, night, ongoing;
  final String pee, poop, peeAndPoop;
  final String yellow, brown, green, black, red, white, unknown;
  final String loose, normal, firm;
  final String small, large;
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService._(
    feedingRepo: ref.watch(feedingRepositoryProvider),
    sleepRepo: ref.watch(sleepRepositoryProvider),
    diaperRepo: ref.watch(diaperRepositoryProvider),
    growthRepo: ref.watch(growthRepositoryProvider),
  );
});
