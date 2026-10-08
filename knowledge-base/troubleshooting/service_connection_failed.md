---
title: n8n에서 Qdrant 또는 Ollama 연결에 실패할 때(ECONNREFUSED)
doc_id: TS-004
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [qdrant, ollama, ECONNREFUSED, 연결 실패, credential, localhost, 서비스명]
---
# TS-004 n8n에서 Qdrant 또는 Ollama 연결에 실패할 때

## 증상
- 워크플로우 실행 중 `ECONNREFUSED` 오류가 발생한다.
- Qdrant Vector Store 또는 Ollama 노드의 자격증명(Credential) 테스트가 실패한다.
- 문서 적재나 질의응답 워크플로우가 검색·임베딩 단계에서 멈춘다.

## 영향 범위
- 문서 적재, 문서 검색, 답변 생성 워크플로우.

## 가능한 원인
1. 자격증명 주소를 `localhost`로 입력했다. 컨테이너 안에서 localhost는 n8n 컨테이너 자신을 가리킨다.
2. Qdrant 또는 Ollama 컨테이너가 실행 중이 아니다.
3. 같은 Docker Compose 네트워크에 속해 있지 않다.
4. 모델이 아직 설치되지 않았다(TS-005 참조).

## 우선 점검 순서
1. 컨테이너 상태를 확인한다.
   ```bash
   docker compose ps
   ```
2. n8n 자격증명의 주소가 서비스명 기준인지 확인한다.
   - Qdrant: `http://qdrant:6333`
   - Ollama: `http://ollama:11434`
3. 프로젝트 헬스체크 스크립트를 실행한다(`scripts/health-check`).
4. 해당 컨테이너의 로그를 확인한다.
   ```bash
   docker compose logs qdrant --tail 50
   docker compose logs ollama --tail 50
   ```

## 조치 방법
1. 자격증명 주소를 `localhost` 대신 서비스명으로 수정한다.
2. 중지된 서비스를 기동한다.
   ```bash
   docker compose up -d
   ```
3. 자격증명을 저장한 뒤 연결 테스트를 다시 실행한다.

## 성공 확인 방법
- 자격증명 연결 테스트가 성공한다.
- 헬스체크 스크립트의 모든 항목이 OK이다.

## 예방 방법
- 자격증명은 프로젝트에서 자동 등록되는 값(서비스명 기준)을 그대로 사용한다.
- 서비스 기동 후 헬스체크를 먼저 실행한 뒤 워크플로우를 실행한다.

## 관련 문서
- TS-005 Ollama 모델을 찾을 수 없거나 응답이 느릴 때
- TS-002 컨테이너 재시작 반복
