import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/elephant_loader.dart';

/// 앱 진입 시 3초간 핑크 코끼리 로딩 화면.
///
/// 스플래시 — 3초 후 자동으로 '/' 로 이동. 탭 스킵 없음.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _go);
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ElephantLoader(size: 220),
              const SizedBox(height: Spacing.xl),
              Text(
                'Baby Note',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFFFE7D81),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '잠시만 기다려주세요…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
