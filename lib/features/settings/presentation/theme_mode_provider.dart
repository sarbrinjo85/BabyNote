import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자가 명시적으로 선택한 테마 모드 — system / light / dark.
///
/// ── 영구 저장 ────────────────────────────────────────────────────────
/// shared_preferences로 디바이스 로컬에 저장 → 앱 재시작 시 복원.
/// 서버 동기화는 추후 (사용자 환경설정 동기화 트랙).
///
/// ── AsyncNotifier 패턴 ───────────────────────────────────────────────
/// build()에서 SharedPreferences를 비동기 로드 → ThemeMode.system을 default로.
/// setMode()로 사용자가 변경 → state 갱신 + prefs 저장.
class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return _parse(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _stringify(mode));
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _stringify(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
        ThemeModeController.new);
