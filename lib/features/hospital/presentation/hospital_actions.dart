import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/hospital.dart';

/// 단골 병원의 핵심 차별화: 원클릭 [전화] [길찾기].
///
/// ── tel: 딥링크 ─────────────────────────────────────────────────────
/// 형식: `tel:01012345678`. 하이픈/공백 제거 후 인코딩.
/// 안드로이드: 전화 앱 자동 호출. iOS: 같음. 단, 시뮬레이터/이뮬레이터에선 작동 안 할 수도.
///
/// ── 길찾기 딥링크 ───────────────────────────────────────────────────
/// 좌표 있으면 `https://www.google.com/maps?q=lat,lng` (모든 OS에서 Google Maps 또는
/// 기본 지도 앱으로 안내). 좌표 없고 주소만 있으면 query에 주소 인코딩.
/// 한국 사용자에겐 카카오/네이버맵이 더 친숙하지만 글로벌 호환성 위해 Google Maps URL 사용.
class HospitalActions {
  const HospitalActions._();

  /// tel: 딥링크로 전화 앱 호출. 실패 시 false 반환.
  static Future<bool> callPhone(Hospital h) async {
    final raw = h.phone;
    if (raw == null || raw.trim().isEmpty) return false;

    // 하이픈/공백/괄호 제거 — 표준 tel: URI엔 숫자/+ 만 권장
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;

    final uri = Uri.parse('tel:$cleaned');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  /// 지도 앱으로 길찾기. 좌표 우선, 없으면 주소.
  static Future<bool> openMaps(Hospital h) async {
    final Uri uri;
    if (h.hasCoordinates) {
      // Google Maps의 "search by coordinate" URL
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${h.latitude},${h.longitude}',
      );
    } else if (h.address != null && h.address!.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(h.address!)}',
      );
    } else {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
