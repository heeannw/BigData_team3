---
title: Webhook 호출 시 404 또는 워크플로우가 실행되지 않을 때
doc_id: TS-001
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [webhook, 404, 실행 안 됨, production url, test url, publish, active]
---
# TS-001 Webhook 호출 시 404 또는 워크플로우가 실행되지 않을 때

## 증상
- Webhook URL로 요청했는데 404가 반환된다.
- Webhook은 수신되는 것 같은데 다음 노드가 실행되지 않는다.
- Test URL에서는 되는데 Production URL에서는 되지 않는다.
- 브라우저 주소창에 Webhook 주소를 직접 열면 404가 나온다.

## 영향 범위
- 해당 Webhook을 호출하는 화면·스크립트 전체(예: Mock UI, 문서 적재 호출).

## 가능한 원인
1. 워크플로우가 게시(Publish/Active)되지 않았다.
2. Test URL과 Production URL을 혼동했다. Test URL은 편집기에서 테스트 실행을 대기시킨 동안에만 동작한다.
3. HTTP Method가 맞지 않는다. Webhook 노드가 POST인데 브라우저(GET)로 열었다.
4. Path 오타 또는 이전 버전 워크플로우가 남아 있다.

## 우선 점검 순서
1. n8n 편집기(http://localhost:5678)에서 해당 워크플로우가 게시(Active) 상태인지 확인한다.
2. Webhook 노드의 HTTP Method와 Path를 확인한다.
3. 터미널에서 POST로 직접 호출한다.
   ```bash
   curl -X POST http://localhost:5678/webhook/mock-chat -H "Content-Type: application/json" -d '{"question":"test"}'
   ```
   Windows PowerShell에서는 `curl` 대신 `curl.exe`를 사용한다.
4. n8n의 Executions(실행 이력)에 해당 실행이 기록됐는지 확인한다.

## 조치 방법
1. 게시되지 않았다면 워크플로우를 게시(Publish/Active)한다.
2. Test URL이 아닌 Production URL(`/webhook/...`)을 사용한다.
3. 브라우저 직접 접속이 아니라 POST 요청으로 호출한다. 브라우저에서 GET으로 열었을 때의 404는 POST 전용 Webhook에서는 정상적인 응답이다.
4. Workflow JSON을 수정했다면 `import-workflows` 스크립트로 다시 등록한다.

## 성공 확인 방법
- POST 호출 시 HTTP 200과 JSON 응답이 반환된다.
- Executions에 성공 실행이 기록된다.

## 예방 방법
- 워크플로우 수정 후에는 게시 상태를 다시 확인한다.
- 호출 주소는 Production URL을 문서와 스크립트에 통일해 적는다.

## 관련 문서
- TS-004 Qdrant·Ollama 연결 실패
