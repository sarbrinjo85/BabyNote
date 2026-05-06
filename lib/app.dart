import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/home_widget_listener.dart';
import 'core/widgets/home_widget_publisher.dart';
import 'features/auth/presentation/auth_state_reset_listener.dart';
import 'features/settings/presentation/theme_mode_provider.dart';
import 'l10n/app_localizations.dart';

class BabyNoteApp extends ConsumerWidget {
  const BabyNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // 사용자 설정 테마 모드 — shared_preferences에 영구 저장. 로딩 중엔 system fallback.
    final themeMode = ref.watch(themeModeControllerProvider).maybeWhen(
          data: (m) => m,
          orElse: () => ThemeMode.system,
        );
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // 모든 라우트를 감싸는 builder — 로그아웃 시 ephemeral state 자동 초기화 +
      // Android 홈 위젯 탭 deep link 처리.
      builder: (context, child) => HomeWidgetListener(
        child: HomeWidgetPublisher(
          child: AuthStateResetListener(child: child ?? const SizedBox.shrink()),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
