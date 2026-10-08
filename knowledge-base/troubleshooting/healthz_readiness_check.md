---
title: n8n 기동 직후 헬스체크는 통과하는데 예전 워크플로우가 실행될 때(healthz와 readiness)
doc_id: TS-010
category: troubleshooting
version: 1.0
created: 2026-10-02
keywords: [healthz, readiness, 헬스체크, 예전 워크플로우, 기동 직후, import-workflows, 준비 완료]
---
# TS-010 n8n 기동 직후 헬스체크는 통과하는데 예전 워크플로우가 실행될 때

## 증상
- 설치나 재기동 직후 n8n의 `/healthz`는 `ok`인데, Webhook을 호출하면 실패하거나 수정 전 버전의 응답이 온다.
- 헬스체크는 통과했는데 워크플로우가 최신 내용이 아니다.

## 영향 범위
- 설치·재기동 직후 Webhook을 호출하는 모든 사용자와 스크립트.

## 가능한 원인
1. n8n의 `/healthz`는 n8n이 완전히 준비되기 전에도 `ok`를 반환할 수 있다.
2. `import-workflows`는 워크플로우를 import하고 게시한 뒤 n8n을 재시작하므로, 재시작이 끝나기 전에 호출하면 예전 버전이 실행될 수 있다.
3. 수정한 워크플로우 JSON을 다시 import하지 않았다.

## 우선 점검 순서
1. 준비 완료 여부는 `/healthz/readiness`로 확인한다.
2. `docker compose ps`에서 n8n이 Healthy 상태인지 확인한다.
3. n8n 편집기에서 해당 워크플로우가 최신 내용이고 게시(Publish/Active) 상태인지 확인한다.
4. Executions(실행 이력)에서 어떤 버전이 실행됐는지 확인한다.

## 조치 방법
1. `/healthz/readiness`가 정상 응답할 때까지 기다린 뒤 호출한다.
2. 최신 JSON이 반영되지 않았다면 `import-workflows` 스크립트를 다시 실행한다. JSON 최상위 `id`가 같으면 기존 워크플로우를 덮어쓴다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
   ```
3. 반영 후 게시 상태를 다시 확인한다.

## 성공 확인 방법
- `/healthz/readiness`가 정상 응답한다.
- Webhook 호출 결과가 최신 워크플로우의 응답과 같다.

## 예방 방법
- 스크립트와 점검 절차에서 준비 확인에는 `/healthz/readiness`를 사용한다.
- 재기동 직후에는 잠시 기다렸다가 호출한다.

## 관련 문서
- OP-006 서비스 상태 확인 방법
- OP-004 워크플로우 내보내기·백업·복원
- TS-001 Webhook 404 또는 미실행
