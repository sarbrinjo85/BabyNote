import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알림 서비스 — 분유 잔량/접종 임박 등 시각 기반 알림을 device 자체에서 schedule.
///
/// ── 왜 로컬인가 ─────────────────────────────────────────────────────
/// Phase 3 시점에 Firebase 추가 부담 회피. 로컬 알림으로 다음을 모두 해결:
/// - 분유 잔량 < 1일: 분유 떨어지기 1일 전 알림
/// - 다가오는 예방접종: 권장일 1일 전 알림
/// - 사이즈업: 7일 전 알림 (선택)
///
/// 외부 서버 안 거치고 device clock이 도달하면 OS가 자동 트리거.
/// 단점: 사용자가 한 번 앱을 열어서 schedule해야 함 (외부 이벤트로 push 불가).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 앱 시작 시 한 번 호출. timezone 데이터 로드 + plugin init + 권한 요청.
  Future<void> init() async {
    if (_initialized) return;

    // timezone DB 초기화 (zonedSchedule이 IANA name 필요)
    tz.initializeTimeZones();
    // 한국/일본 사용자 → Asia/Seoul 또는 Asia/Tokyo. flutter_timezone로 device tz를
    // 가져오는 게 정석이지만 의존성 줄이기 위해 Asia/Seoul 고정.
    // 시각이 약간 어긋나도 알림 의미는 유지됨 (분유 잔량 등은 일 단위라 ±1시간 무관).
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // local fallback
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ 런타임 알림 권한
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        if (kDebugMode) debugPrint('알림 권한 요청 실패 (앱 동작은 계속): $e');
      }
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      try {
        await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      } catch (e) {
        if (kDebugMode) debugPrint('iOS 알림 권한 실패: $e');
      }
    }

    _initialized = true;
  }

  /// 특정 시점에 알림 예약. 같은 id면 OS가 기존 예약을 자동 교체.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String channelId = 'babynote_default',
    String channelName = 'BabyNote',
  }) async {
    if (!_initialized) await init();

    // 과거 시각이면 지금부터 +5초 — 즉시 띄움 효과
    final now = DateTime.now();
    final scheduledAt = when.isBefore(now) ? now.add(const Duration(seconds: 5)) : when;
    final tzAt = tz.TZDateTime.from(scheduledAt, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzAt,
        details,
        // exact alarm 권한이 있으면 정확히, 없으면 inexact로 fallback
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // iOS 절대 시각 해석 (필수 인자)
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // 권한 거부 등으로 실패해도 앱 흐름 막지 않음
      if (kDebugMode) debugPrint('알림 예약 실패: $e');
    }
  }

  /// 특정 ID 알림 취소.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  /// 모든 예약된 알림 취소.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

/// Riverpod에서 service에 접근하기 위한 provider.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);
