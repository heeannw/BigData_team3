---
title: Docker Compose 기동·중지·초기화 방법
doc_id: OP-002
category: operations
version: 1.0
created: 2026-10-01
keywords: [docker compose, 기동, 중지, 재시작, 초기화, down -v, 로그, 서비스 상태]
---
# OP-002 Docker Compose 기동·중지·초기화 방법

## 목적
프로젝트의 5개 서비스를 켜고, 끄고, 상태를 확인하고, 필요하면 초기화하는 방법을 안내한다.

## 적용 범위
저장소 폴더에서 실행하는 `docker compose` 명령. 서비스는 frontend(Nginx), n8n, postgres, qdrant, ollama 5개이다.

## 사전 조건
1. Docker Desktop이 실행 중이다.
2. 터미널의 현재 위치가 저장소 폴더(`docker-compose.yml`이 있는 곳)이다.
3. 최초 설치는 OP-001을 먼저 완료한다.

## 서비스와 접속 주소
| 서비스 | 외부 주소 | 용도 |
|---|---|---|
| frontend | `http://localhost:8080` | 챗봇 화면과 `/api` 프록시 |
| n8n | `http://localhost:5678` | 워크플로우 편집·실행 |
| qdrant | `127.0.0.1:6333` | 벡터 DB(이 PC에서만 접속) |
| ollama | `127.0.0.1:11434` | 로컬 LLM·임베딩(이 PC에서만 접속) |
| postgres | 외부 노출 없음 | n8n 내부 데이터 저장 |

## 자주 쓰는 명령
1. 기동(데이터 유지)
   ```bash
   docker compose up -d
   ```
2. 중지(데이터 유지)
   ```bash
   docker compose stop
   ```
3. 상태 확인
   ```bash
   docker compose ps
   ```
4. 로그 확인(서비스 이름은 n8n, qdrant, ollama, postgres, frontend)
   ```bash
   docker compose logs n8n --tail 100
   ```
5. 전체 초기화(주의)
   ```bash
   docker compose down -v
   ```

## 전체 초기화 시 삭제되는 것
- `docker compose down -v`는 n8n 데이터(워크플로우, 자격증명, 계정, 실행 이력)와 벡터 데이터를 삭제한다.
- 모델 파일은 `offline-assets/model-files/`에 있으므로 유지된다.
- 초기화한 뒤에는 `install` 스크립트로 환경을 다시 올리고, n8n 관리자 계정을 다시 만들고, `ingest-documents`로 문서를 다시 적재한다.

## 워크플로우를 수정한 뒤 반영하기
1. n8n 편집기에서 워크플로우를 수정하고 JSON으로 export해 `workflows/` 폴더에 저장한다.
2. 아래 스크립트로 다시 등록한다. JSON 최상위 `id`가 같으면 기존 워크플로우를 덮어쓴다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
   ```

## 확인 방법
- `docker compose ps`에서 5개 서비스가 모두 Up(또는 Healthy)이다.
- `http://localhost:8080/healthz`에서 `ok`가 표시된다.

## 주의사항
- 데이터를 지우려는 의도가 아니면 `down -v`를 사용하지 않는다. 일반적인 재시작은 `stop`과 `up -d`를 쓴다.
- 이미 다른 n8n이 5678 포트를 쓰고 있으면 충돌한다(TS-003).

## 관련 문서
- OP-001 폐쇄망 설치 절차
- OP-006 서비스 상태 확인 방법
- TS-002 컨테이너 재시작 반복
- TS-003 포트 충돌
