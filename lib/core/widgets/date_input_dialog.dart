import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 8자리 숫자(yyyymmdd) 직접 입력 + 캘린더 토글이 가능한 날짜 선택 다이얼로그.
///
/// ── 왜 만들었나 ───────────────────────────────────────────────────
/// Flutter 표준 `showDatePicker` 의 텍스트 입력 모드는 로케일별 고정 포맷
/// (KO: "yyyy. M. d.", EN: "mm/dd/yyyy") 만 받음.
/// 안드로이드 숫자 키보드에는 마침표/슬래시가 없거나 불편 → 사용자가
/// 직접 입력하기 어려움.
/// → 8자리 숫자만 받아 우리가 직접 파싱하는 다이얼로그를 별도로 제공.
///
/// 반환:
///   - 사용자가 확인 → `DateTime`
///   - 취소 / 닫기 → `null`
Future<DateTime?> showDateInputDialog(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '날짜 입력',
  String hint = '예: 20260505',
  String helper = 'YYYYMMDD 8자리 숫자만',
  String calendarLabel = '달력으로 선택',
  String okLabel = '확인',
  String cancelLabel = '취소',
}) async {
  final clamped = initial.isBefore(firstDate)
      ? firstDate
      : (initial.isAfter(lastDate) ? lastDate : initial);
  final ctrl = TextEditingController(text: _format8(clamped));

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(builder: (ctx, setSt) {
        Future<void> openCalendar() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: _parse8(ctrl.text) ?? clamped,
            firstDate: firstDate,
            lastDate: lastDate,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
          );
          if (picked != null) {
            ctrl.text = _format8(picked);
            setSt(() => error = null);
          }
        }

        void trySubmit() {
          final s = ctrl.text.trim();
          if (s.length != 8) {
            setSt(() => error = '8자리로 입력하세요');
            return;
          }
          final dt = _parse8(s);
          if (dt == null) {
            setSt(() => error = '올바른 날짜가 아닙니다');
            return;
          }
          if (dt.isBefore(firstDate) || dt.isAfter(lastDate)) {
            setSt(() => error = '입력 가능한 범위를 벗어났습니다');
            return;
          }
          Navigator.of(ctx).pop(dt);
        }

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: hint,
                  helperText: helper,
                  errorText: error,
                  counterText: '',
                ),
                onSubmitted: (_) => trySubmit(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: openCalendar,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(calendarLabel),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: trySubmit,
              child: Text(okLabel),
            ),
          ],
        );
      });
    },
  );
}

String _format8(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parse8(String s) {
  if (s.length != 8) return null;
  final y = int.tryParse(s.substring(0, 4));
  final m = int.tryParse(s.substring(4, 6));
  final d = int.tryParse(s.substring(6, 8));
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12) return null;
  if (d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  // 윤년/짧은 달 보정 검증 — DateTime은 잘못된 날짜를 자동으로 다음 달로
  // 굴리기 때문에 실제 컴포넌트가 일치하는지 확인.
  if (dt.year != y || dt.month != m || dt.day != d) return null;
  return dt;
}
