---
title: Docker 기동 시 포트 충돌(5678 등 port is already allocated)
doc_id: TS-003
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [포트 충돌, 5678, 8080, port is already allocated, bind failed, netstat, lsof]
---
# TS-003 Docker 기동 시 포트 충돌

## 증상
- `docker compose up -d` 실행 시 포트가 이미 사용 중이라는 오류가 발생한다.
  (예: `Bind for 0.0.0.0:5678 failed: port is already allocated`)
- 컨테이너가 시작되지 않는다.
- 접속은 되는데 예상과 다른 n8n 화면이 나온다.

## 영향 범위
- 충돌한 포트를 사용하는 서비스(n8n 5678, 프론트엔드 8080, Qdrant 6333, Ollama 11434).

## 가능한 원인
1. Docker 없이 로컬에 설치한 n8n 등 다른 프로그램이 같은 포트를 사용 중이다.
2. 이전에 실행한 컨테이너가 남아 있다.
3. 다른 프로젝트의 컨테이너가 같은 포트를 사용한다.

## 우선 점검 순서
1. 포트를 사용 중인 프로세스를 확인한다.
   ```bash
   # Windows (PowerShell / CMD)
   netstat -ano | findstr :5678
   # Mac / Linux
   lsof -i :5678
   ```
2. 실행 중인 컨테이너를 확인한다.
   ```bash
   docker ps
   ```

## 조치 방법
1. 로컬에 설치된 n8n 등 충돌 프로그램을 종료한다.
2. 남은 컨테이너가 원인이면 중지한다.
   ```bash
   docker compose stop
   ```
3. 종료가 어려우면 `docker-compose.yml`의 외부 포트를 변경한다. 예: `"5679:5678"`. 이 경우 외부에서 접속하는 주소가 바뀌므로 문서와 스크립트의 주소도 함께 수정한다.

## 성공 확인 방법
- `docker compose ps`에서 모든 서비스가 Up 상태이다.
- 해당 포트로 접속하면 프로젝트의 서비스 화면이 나온다.

## 예방 방법
- 프로젝트 실행 전 로컬 n8n 등 동일 포트 프로그램을 종료한다.
- 사용하는 포트 목록을 README에 명시한다.

## 관련 문서
- TS-002 컨테이너 재시작 반복
