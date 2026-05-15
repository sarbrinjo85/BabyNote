import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/notifications/notification_service.dart';
import 'core/sync/sync_worker.dart';
import 'core/sync/write_queue.dart';
import 'features/billing/data/billing_service.dart';

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

  // 인앱 결제 (RevenueCat) 초기화 — 환경 키 없으면 no-op.
  await BillingService.instance.initialize();

  // 오프라인 쓰기 큐 — sqflite 백킹. WriteQueue.open 한 번만 호출 후
  // writeQueueProvider 를 override 해서 모든 곳에서 동일 인스턴스 사용.
  final writeQueue = await WriteQueue.open();

  // Sentry는 DSN이 주입돼있을 때만 init.
  // 개발 단계 또는 DSN 미설정 시엔 SentryFlutter.init 건너뛰고 그냥 runApp.
  if (Env.isSentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        // 환경 구분 — Sentry UI에서 dev vs production 필터링
        options.environment = kDebugMode ? 'debug' : 'production';
        options.release = 'babynote@1.0.0+1'; // pubspec version과 일치
        // 에러 발생 시 스택 트레이스 + breadcrumbs 자동 capture
        // 트래픽 적을 땐 100%, production 사용자 많아지면 0.1로 낮춤
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        // PII (이메일/이름)는 보내지 않음 — auth/privacy 보호
        options.sendDefaultPii = false;
      },
      appRunner: () => runApp(ProviderScope(
        overrides: [writeQueueProvider.overrideWithValue(writeQueue)],
        child: const _BootSyncWorker(child: BabyNoteApp()),
      )),
    );
  } else {
    if (kDebugMode) {
      debugPrint(
        'Sentry not configured — pass --dart-define=SENTRY_DSN=https://... '
        'to enable error monitoring.',
      );
    }
    runApp(ProviderScope(
      overrides: [writeQueueProvider.overrideWithValue(writeQueue)],
      child: const _BootSyncWorker(child: BabyNoteApp()),
    ));
  }
}

/// SyncWorker 를 앱 부팅 직후 활성화하는 wrapper.
/// 별도 위젯으로 빼는 이유: ProviderScope 가 child 빌드 시점에 ConsumerWidget
/// 안에서 ref.watch(syncWorkerProvider) 호출하면 라이프사이클 보장.
class _BootSyncWorker extends ConsumerWidget {
  const _BootSyncWorker({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // syncWorkerProvider 를 watch 해서 ref 의존성을 등록 → connectivity 구독 시작.
    ref.watch(syncWorkerProvider);
    return child;
  }
}
