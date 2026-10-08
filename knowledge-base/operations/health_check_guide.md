---
title: 서비스 상태 확인 방법(healthz, Qdrant 대시보드, health-check 스크립트)
doc_id: OP-006
category: operations
version: 1.0
created: 2026-10-01
keywords: [상태 확인, 헬스체크, health-check, healthz, readiness, qdrant 대시보드, 정상 동작]
---
# OP-006 서비스 상태 확인 방법

## 목적
설치·기동 후 또는 문제가 생겼을 때 각 서비스가 정상인지 순서대로 점검한다.

## 적용 범위
frontend(Nginx), n8n, postgres, qdrant, ollama 5개 서비스와 지식베이스 컬렉션.

## 사전 조건
1. Docker Desktop이 실행 중이고 `docker compose up -d`로 서비스를 기동했다.
2. 컬렉션 확인은 문서 적재(`ingest-documents`)를 한 번 실행한 뒤에 가능하다.

## 점검 순서
1. 컨테이너 상태
   ```bash
   docker compose ps
   ```
   5개 서비스가 모두 Up(또는 Healthy)이어야 한다.
2. 프론트엔드(Nginx): `http://localhost:8080/healthz`에서 `ok`가 표시되면 정상이다.
3. n8n: `http://localhost:5678`에서 편집기가 열린다. 준비 완료 여부는 `/healthz/readiness`로 확인한다. `/healthz`는 n8n이 준비되기 전에도 `ok`를 반환할 수 있으므로 준비 확인에는 `/healthz/readiness`를 사용한다.
4. Qdrant: `http://localhost:6333/dashboard`에서 대시보드가 열리고, 문서 적재 후에는 컬렉션 `knowledge_base`가 보인다.
5. 통합 점검 스크립트
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\health-check.ps1
   ```
   컨테이너, 서비스, 프록시, 모델, 컬렉션을 한 번에 점검하며 하나라도 실패하면 종료 코드 1을 반환한다. Mac·Linux는 `bash scripts/health-check.sh`를 사용한다.

## 결과에 따른 조치
| 상황 | 참고 문서 |
|---|---|
| 컨테이너가 Restarting을 반복한다 | TS-002 |
| 포트가 이미 사용 중이라는 오류가 난다 | TS-003 |
| n8n에서 Qdrant·Ollama에 연결되지 않는다 | TS-004 |
| 모델을 찾을 수 없다고 나온다 | TS-005 |
| 적재 결과가 `NO_DOCUMENTS`이거나 컬렉션이 없다 | TS-006 |
| `http://localhost:8080`이 403이다 | TS-008 (최종 화면 파일이 아직 없으면 정상) |

## 확인 방법
- `health-check` 스크립트가 전 항목 OK이다.
- 문서 적재 후 Qdrant 대시보드에 `knowledge_base` 컬렉션이 있다.

## 주의사항
- 모델을 처음 호출할 때는 모델을 메모리에 올리느라 시간이 더 걸린다(검증 환경에서 첫 호출 약 21초, 이후 약 6초). 모델은 마지막 사용 후 기본 30분(`OLLAMA_KEEP_ALIVE`)이 지나면 메모리에서 내려가므로, 응답 시간을 측정하거나 시연하기 직전에 한 번 미리 호출해 둔다.
- Qdrant와 Ollama 포트는 이 PC(127.0.0.1)에서만 접속할 수 있다.

## 관련 문서
- OP-001 폐쇄망 설치 절차
- OP-002 Docker Compose 기동·중지·초기화
- TS-002, TS-004, TS-005, TS-006
