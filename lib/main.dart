import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: kDebugMode,
    );
  } else if (kDebugMode) {
    debugPrint(
      'Env not configured — pass --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... to enable backend features.',
    );
  }

  // 로컬 알림 서비스 초기화 (timezone 로드 + plugin init + 권한 요청).
  // await로 기다려야 setLocalLocation이 안전하게 끝남.
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: BabyNoteApp()));
}
