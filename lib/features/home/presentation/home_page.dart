import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../vaccination/presentation/first_vaccine_provider.dart';

/// 홈 화면 (placeholder).
///
/// ── StatelessWidget → ConsumerWidget으로 바꾼 이유 ───────────────────
/// Riverpod의 provider를 위젯에서 구독하려면 `ref` 객체가 필요.
/// `ConsumerWidget`(flutter_riverpod 제공)은 build 메서드에 `ref`를 추가로 넘겨주는
/// StatelessWidget의 변종. setState 같은 명령형 코드를 안 써도 provider 값이
/// 바뀔 때마다 자동으로 rebuild 됨 (선언형).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // ── ref.watch(provider): 그 provider의 현재 값을 읽고 + 변할 때 자동 rebuild
    // FutureProvider라서 결과는 AsyncValue<VaccineSchedule?> 형태.
    final asyncVaccine = ref.watch(firstKoreanVaccineProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.homeWelcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // ── AsyncValue.when 패턴 ─────────────────────────────────
            // 비동기 결과의 3가지 상태(로딩 / 에러 / 데이터)를 한 번에 표현.
            // setState나 FutureBuilder 없이도 깔끔하게 분기 처리됨.
            asyncVaccine.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text(
                'Supabase 연결 실패: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (vaccine) {
                if (vaccine == null) {
                  return const Text('등록된 한국 백신 일정이 없습니다.');
                }
                // 결과가 정상적으로 왔다는 건 곧:
                //   1) Supabase init OK
                //   2) RLS가 anon 키에게 vaccine_schedules read 허용 OK
                //   3) 시드 데이터 들어가 있음 OK
                // → e2e 검증 완료라는 뜻
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🇰🇷 첫 번째 예방접종 (Supabase에서)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vaccine.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('코드: ${vaccine.code} (${vaccine.doseNumber}차)'),
                        Text('권장 시기: 생후 ${vaccine.recommendedAgeDays}일'),
                        if (vaccine.description != null) ...[
                          const SizedBox(height: 8),
                          Text(vaccine.description!),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
