import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';

/// 자동완성 후보 1건.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

/// place 상세 — 선택 시 받아오는 정보.
class PlaceDetails {
  const PlaceDetails({
    required this.name,
    this.formattedAddress,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });
  final String name;
  final String? formattedAddress;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
}

/// Google Places API 클라이언트 — Autocomplete + Details.
///
/// ── 직접 HTTP 호출 ──────────────────────────────────────────────────
/// `google_places_flutter` 같은 패키지 대신 직접 호출 — 의존성 가벼움.
/// `http` 패키지는 이미 supabase_flutter dependency tree에 있음.
///
/// ── language / region ───────────────────────────────────────────────
/// 사용자 시스템 언어 따라 한/일/영 분기. 한국 사용자는 `ko` + `KR` region.
class PlacesService {
  PlacesService({String? apiKey})
      : _apiKey = apiKey ?? Env.googlePlacesApiKey;

  final String _apiKey;

  /// API 키 주입됐는지. 비어있으면 자동완성 호출 자체를 건너뜀.
  bool get enabled => _apiKey.isNotEmpty;

  /// Autocomplete — 검색어 입력에 따른 후보 목록.
  ///
  /// [language]: 'ko' | 'ja' | 'en' 등 ISO 639-1 코드
  /// [components]: 'country:kr' 같은 필터 (특정 국가만)
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String language = 'ko',
    String? components,
  }) async {
    if (!enabled || input.trim().isEmpty) return const [];

    final query = <String, String>{
      'input': input,
      'key': _apiKey,
      'language': language,
      // hospital/clinic만 필터해도 되지만 일반 장소 검색이 더 유연
      // 'types': 'hospital',
      if (components != null) 'components': components,
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      query,
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        if (kDebugMode) debugPrint('Places autocomplete status: $status');
        return const [];
      }
      final preds = (body['predictions'] as List? ?? const []);
      return preds.map((p) {
        final m = p as Map<String, dynamic>;
        final structured =
            m['structured_formatting'] as Map<String, dynamic>?;
        return PlacePrediction(
          placeId: m['place_id'] as String,
          description: m['description'] as String? ?? '',
          mainText: structured?['main_text'] as String?,
          secondaryText: structured?['secondary_text'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Places autocomplete error: $e');
      return const [];
    }
  }

  /// place_id로 상세 정보 조회 — 이름/주소/전화/좌표.
  Future<PlaceDetails?> details(String placeId, {String language = 'ko'}) async {
    if (!enabled) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'language': language,
        // 응답 크기 절약 — 필요한 필드만
        'fields': 'name,formatted_address,formatted_phone_number,'
            'international_phone_number,geometry/location',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;
      final result = body['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final loc = (result['geometry']
          as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?;

      return PlaceDetails(
        name: result['name'] as String? ?? '',
        formattedAddress: result['formatted_address'] as String?,
        phoneNumber: (result['formatted_phone_number'] as String?) ??
            (result['international_phone_number'] as String?),
        latitude: (loc?['lat'] as num?)?.toDouble(),
        longitude: (loc?['lng'] as num?)?.toDouble(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Places details error: $e');
      return null;
    }
  }
}

final placesServiceProvider =
    Provider<PlacesService>((ref) => PlacesService());
