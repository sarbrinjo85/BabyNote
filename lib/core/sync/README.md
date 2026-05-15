# 오프라인 쓰기 큐 (Write Queue)

네트워크 없을 때 INSERT/UPDATE/DELETE 를 로컬 SQLite 에 임시 보관, 재연결 시 자동 flush.

## 디자인 의도

- **목표**: "지하철·새벽·비행기에서 기록 안 됨" 해결 — 80% 의 오프라인-first 가치
- **scope 외**: 오프라인 *읽기*. Brick 전면 도입 시 (스펙 §8.3) 추가될 영역
- **3-file 인프라**: 의도적으로 작게. 후속 Brick 마이그레이션 시 큰 영향 없이 제거 가능

## 컴포넌트

| 파일 | 역할 |
|---|---|
| `write_queue.dart` | `WriteQueue` — sqflite 큐 (`enqueue`/`listAll`/`remove`/`markFailure`). 단일 인스턴스 (`writeQueueProvider`) |
| `connectivity_provider.dart` | `connectivityStreamProvider` (Stream\<bool\>) + `connectivityCheckProvider` (one-shot) |
| `sync_worker.dart` | `SyncWorker` — connectivity true 이벤트마다 flush 호출 |

`main.dart` 에서 `WriteQueue.open()` 한 번 + `_BootSyncWorker` 가 SyncWorker watch.

## 리포지토리에 적용하는 법

기존 리포지토리의 `_client.from(...).insert/update/delete()` 를 try/catch 로 감싸기:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/write_queue.dart';

class RoutineRepository {
  RoutineRepository(this._client, this._ref);
  final SupabaseClient _client;
  final Ref _ref;

  Future<void> create({required Map<String, dynamic> payload}) async {
    try {
      await _client.from('routines').insert(payload);
    } catch (e) {
      if (WriteQueue.isOfflineError(e)) {
        await _ref.read(writeQueueProvider).enqueue(
              op: 'insert',
              table: 'routines',
              payload: payload,
            );
        // UI 에는 "오프라인 - 큐에 저장됨" 토스트로 안내 (또는 silent 처리)
        return;
      }
      rethrow;
    }
  }
}
```

UPDATE / DELETE 는 `rowId` 도 전달:
```dart
await _ref.read(writeQueueProvider).enqueue(
  op: 'update', table: 'routines', rowId: routine.id, payload: patch);
```

## 한계 + 후속 작업

| 한계 | 영향 | 대응 |
|---|---|---|
| 오프라인 *읽기* 안 됨 | 비행기 모드 진입 후 앱 재시작 시 화면 비어보임 | Brick 전면 도입 (E-full) 또는 Riverpod 캐시 hydration |
| INSERT 시 서버 생성 PK 못 받음 | 큐 항목이 후속 update 의 `rowId` 로 못 씀 | 클라이언트가 uuid 미리 만들어서 보내기 (`gen_random_uuid()` 대신) |
| 가족 실시간 동기화 X | 오프라인 동안 다른 가족원 입력 못 받음 | connectivity true 직후 Riverpod invalidate 트리거 |
| 충돌 해결 X (last-write-wins 의 last 도 결정 어려움) | 동시 편집 시 어느 쪽이 살아남나 미정 | 스펙 §10.2 패턴: 시간 5분 이상 차이는 별도 기록 |

## 큐 모니터링

`writeQueueCountProvider` 를 watch 해서 settings/home 에 sync indicator 노출 가능:

```dart
ref.watch(writeQueueCountProvider).whenData((n) {
  if (n > 0) showBadge('$n 개 동기화 대기 중');
});
```

## E-full (Brick) 으로 전환 시

- `WriteQueue` 와 `SyncWorker` 는 그대로 두고 사용 안 함 → Brick repo 가 모든 흐름 가로챔
- 또는 완전 제거 (`lib/core/sync/` 삭제)
- 이행 기간 동안 둘 다 살려두면 큐 dual-write 위험 → 한쪽만 활성화
