---
title: 챗봇 화면에서 "요청 실패"가 나오거나 CORS 오류가 발생할 때
doc_id: TS-007
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [요청 실패, CORS, Allowed Origins, fetch, 브라우저 콘솔, api url, nginx, 프록시]
---
# TS-007 챗봇 화면에서 "요청 실패"가 나오거나 CORS 오류가 발생할 때

## 증상
- 챗봇 또는 Mock UI 화면은 뜨는데 질문을 보내면 "요청 실패"가 표시된다.
- 브라우저 개발자 도구(F12) 콘솔에 CORS 정책에 의해 차단되었다는 오류가 나온다.
- 응답 없이 로딩만 계속된다.

## 영향 범위
- 브라우저 UI에서 n8n Webhook을 호출하는 모든 질문·진단 요청.

## 가능한 원인
1. UI를 다른 주소(예: 별도 포트의 임시 서버)에서 열었는데, Webhook의 Allowed Origins에 그 주소가 허용되어 있지 않다.
2. n8n이 실행 중이 아니거나, 워크플로우가 등록되지 않았거나, 게시(Publish/Active)되지 않았다.
3. UI 코드의 `API_URL`에 오타나 문법 오류가 있다.
4. Test URL(`/webhook-test/...`)을 호출하고 있다.
5. Nginx 프록시 경로(`/api/*` → `/webhook/*`)가 잘못되었다.

## 우선 점검 순서
1. 브라우저 개발자 도구의 Console과 Network 탭에서 오류 종류와 요청 주소를 확인한다.
2. 터미널에서 Webhook을 직접 POST로 호출해 서버 쪽 문제인지 구분한다.
   ```bash
   curl -X POST http://localhost:5678/webhook/mock-chat -H "Content-Type: application/json" -d '{"question":"test","requestType":"operation"}'
   ```
   Windows PowerShell에서는 `curl.exe`를 사용한다.
3. `docker compose ps`로 n8n이 실행 중인지 확인한다.
4. UI 코드의 `API_URL`이 Production URL(`/webhook/...`) 또는 Nginx 경유 주소(`/api/...`)인지 확인한다.

## 조치 방법
1. curl은 성공하는데 브라우저만 실패하면 CORS 문제이다. Webhook 노드의 Options → Allowed Origins에 UI가 열린 주소(예: `http://localhost:5500`)를 추가한다. 기본값은 `*`이다.
2. 최종 환경에서는 Nginx 경유 주소(`http://localhost:8080/api/...`)로 호출한다. UI와 API가 같은 주소를 사용하므로 CORS 설정이 필요 없다.
3. n8n이 중지되어 있으면 `docker compose up -d`로 기동한다. 설치 직후라면 `install` 스크립트를 실행한다. 워크플로우가 등록되지 않았다면 `import-workflows` 스크립트를 실행하고, 게시 상태를 확인한다(TS-001 참조).
4. `API_URL`의 오타·문법 오류를 수정한다.

## 성공 확인 방법
- Network 탭에서 요청이 HTTP 200으로 표시된다.
- 화면에 답변(JSON 결과)이 출력된다.

## 예방 방법
- 개발 중 다른 주소에서 UI를 열 때는 Allowed Origins를 함께 설정한다.
- 최종 시연은 Nginx 경유 주소로 통일한다.
- UI 코드의 API 주소는 한 곳(`api.js`)에서 관리한다.

## 관련 문서
- TS-001 Webhook 404 또는 미실행
- TS-002 컨테이너 재시작 반복
