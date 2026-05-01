import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트(SupabaseClient)를 앱 전역에서 꺼내 쓰는 진입점.
///
/// ── 왜 Provider로 감싸나 ─────────────────────────────────────────────
/// `Supabase.instance.client`로 어디서든 직접 호출할 수도 있어. 그런데:
///   1. **테스트** 때 가짜(SupabaseClient mock)로 갈아끼우려면 직접 호출은 곤란.
///      Provider로 감싸면 테스트에서 `ProviderScope(overrides: [...])`로 교체 가능.
///   2. **의존성을 명시적으로** 드러내는 게 Riverpod 철학. 어느 위젯이 Supabase를
///      쓰는지가 `ref.watch(supabaseClientProvider)` 한 줄로 보여서 추적이 쉬움.
///   3. 나중에 클라이언트 초기화 로직이 복잡해지면(예: Brick offline-first) 한 곳만
///      바꾸면 됨.
///
/// ── Provider vs FutureProvider ───────────────────────────────────────
/// 여긴 그냥 `Provider`. 이유: `Supabase.initialize`가 main()에서 이미 끝나서
/// `Supabase.instance.client`는 동기적으로 즉시 사용 가능. 비동기 초기화가 필요한
/// 객체였다면 `FutureProvider`를 썼을 거.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
