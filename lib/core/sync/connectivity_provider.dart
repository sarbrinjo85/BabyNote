import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 디바이스 네트워크 연결 상태를 스트림으로 노출.
///
/// connectivity_plus 7+ 부터 결과가 `List<ConnectivityResult>` (다중 인터페이스 동시).
/// 모든 항목이 `none` 이면 오프라인.
///
/// ── 주의 ───────────────────────────────────────────────────────────
/// "Wi-Fi 신호 잡힘" 이 "인터넷 도달 가능" 을 보장하지 않음 (캡티브 포털, ISP 장애 등).
/// 정확한 도달성은 실제 HTTP 요청 실패로만 확정 가능 → WriteQueue.isOfflineError 가
/// catch 측에서 백업 판단. connectivity 는 "최소한 시도 가치 있는가" 판단용.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final c = Connectivity();
  return c.onConnectivityChanged.map(_anyOnline).distinct();
});

/// 현재 시점 (스트림 첫 이벤트 전) 연결 여부 — 부팅 직후 sync worker 가 한 번 체크.
final connectivityCheckProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return _anyOnline(results);
});

bool _anyOnline(List<ConnectivityResult> results) {
  return results.any((r) =>
      r != ConnectivityResult.none && r != ConnectivityResult.bluetooth);
}
