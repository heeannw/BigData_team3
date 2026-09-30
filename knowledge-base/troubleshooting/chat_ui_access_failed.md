---
title: 챗봇 화면에 접속할 수 없을 때(localhost:5500 연결 거부, localhost:8080 403)
doc_id: TS-008
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [연결을 거부했습니다, 5500, 8080, 403, forbidden, index.html, mock ui, nginx, frontend]
---
# TS-008 챗봇 화면에 접속할 수 없을 때

## 증상
- `http://localhost:5500` 접속 시 "연결을 거부했습니다"가 표시된다.
- `http://localhost:8080` 접속 시 403 Forbidden이 표시된다.
- 다른 서비스(n8n 등)는 정상인데 챗봇 화면만 열리지 않는다.

## 영향 범위
- 브라우저에서 챗봇 화면을 사용하는 모든 사용자. n8n API 자체는 영향이 없다.

## 가능한 원인
1. 5500 포트의 Mock UI는 Docker가 아니라 별도의 임시 Python 서버로 실행하는데, 서버가 켜져 있지 않거나 터미널 창을 닫아 종료되었다.
2. 8080 포트의 403은 `frontend/public/` 폴더에 `index.html`이 없을 때 나타난다. 최종 UI 파일이 배치되기 전에는 정상적인 현상이다.
3. frontend(Nginx) 컨테이너가 실행 중이 아니다.

## 우선 점검 순서
1. 5500 접속 문제라면 임시 서버가 실행 중인 터미널이 열려 있는지 확인한다.
2. `http://localhost:8080/healthz`에 접속해 `ok`가 표시되는지 확인한다. `ok`이면 Nginx는 정상이다.
3. 컨테이너 상태를 확인한다.
   ```bash
   docker compose ps
   ```
4. `frontend/public/`에 `index.html`이 있는지 확인한다.

## 조치 방법
1. 저장소 폴더(BigData_team3)에서 터미널을 열고 임시 서버를 실행한다.
   ```bash
   # Windows
   python -m http.server 5500 --directory n8n-webhook-browser-test/frontend/public --bind 127.0.0.1
   # Mac / Linux
   python3 -m http.server 5500 --directory n8n-webhook-browser-test/frontend/public --bind 127.0.0.1
   ```
   그 후 `http://localhost:5500`에 접속한다. 터미널 창을 닫으면 서버도 종료되므로 켜둔 채로 사용한다.
2. 8080의 403은 `frontend/public/`에 `index.html`을 추가하면 해결된다.
3. frontend 컨테이너가 중지되어 있으면 기동한다.
   ```bash
   docker compose up -d
   ```

## 성공 확인 방법
- 브라우저에 챗봇(또는 Mock UI) 화면이 표시된다.
- `http://localhost:8080/healthz`가 `ok`를 반환한다.

## 예방 방법
- 5500은 초기 확인용 임시 서버이고, 최종 시연은 8080(Nginx)으로 통일한다.
- 화면은 열리는데 질문 전송이 실패하면 TS-007을 참고한다.

## 관련 문서
- TS-007 챗봇 화면에서 요청 실패 또는 CORS 오류
- TS-002 컨테이너 재시작 반복
