import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../router/app_router.dart';

/// Android 홈 위젯에서 탭한 deep link를 받아 GoRouter로 navigation.
///
/// ── 동작 ─────────────────────────────────────────────────────────
/// 1) 앱이 종료된 상태에서 위젯 탭 → `initiallyLaunchedFromHomeWidget()` 가 Uri 반환
/// 2) 앱이 백그라운드에 있다가 위젯 탭 → `widgetClicked` stream 으로 도달
///
/// 둘 다 babynote://widget/{type} 형식.
/// type: feeding | sleep | diaper | growth → /{type}/new 라우트로 push.
///
/// ── 사용 ──────────────────────────────────────────────────────────
/// app.dart에서 root에 한 번만 설치. 자식 위젯은 그냥 child로 넘김.
class HomeWidgetListener extends ConsumerStatefulWidget {
  const HomeWidgetListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeWidgetListener> createState() => _HomeWidgetListenerState();
}

class _HomeWidgetListenerState extends ConsumerState<HomeWidgetListener> {
  @override
  void initState() {
    super.initState();
    // 앱이 종료된 상태에서 위젯으로 시작된 경우 — 한 번만 처리.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleUri);
    // 백그라운드 → 포어그라운드 진입 시
    HomeWidget.widgetClicked.listen(_handleUri);
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    // 'babynote://widget/feeding' → path '/feeding' (segment 'feeding')
    final segments = uri.pathSegments;
    if (segments.isEmpty) return;
    final type = segments.first; // feeding | sleep | diaper | growth

    // GoRouter로 push. router는 ProviderScope에서 watch 가능.
    final router = ref.read(appRouterProvider);
    // 마이크로태스크로 미루기 — 위젯 빌드 사이클과 충돌 방지
    Future.microtask(() {
      switch (type) {
        case 'feeding':
          router.push('/feeding/new');
          break;
        case 'sleep':
          router.push('/sleep/new');
          break;
        case 'diaper':
          router.push('/diaper/new');
          break;
        case 'growth':
          router.push('/growth/new');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
