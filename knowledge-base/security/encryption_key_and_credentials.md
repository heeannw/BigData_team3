---
title: N8N_ENCRYPTION_KEY와 자격증명 관리
doc_id: SC-002
category: security
version: 1.0
created: 2026-10-01
keywords: [N8N_ENCRYPTION_KEY, 암호화 키, 자격증명, credential, qdrant, ollama, 복호화]
---
# SC-002 N8N_ENCRYPTION_KEY와 자격증명 관리

## 목적
n8n의 자격증명(Credential) 암호화 키와 프로젝트 자격증명을 올바르게 관리하는 방법을 안내한다.

## 적용 범위
`.env`의 `N8N_ENCRYPTION_KEY`, `workflows/credentials/local-services.json`.

## N8N_ENCRYPTION_KEY란
- n8n이 저장하는 자격증명을 암호화하는 키이다.
- 설치 스크립트가 `.env`에 자동으로 만든다.
- **설치 후에는 바꾸지 않는다.** 바꾸면 이미 저장된 자격증명을 읽을 수 없다.

## 프로젝트 자격증명
| 이름 | id | 주소 |
|---|---|---|
| Qdrant (local) | `qdrantLocalCred1` | `http://qdrant:6333` |
| Ollama (local) | `ollamaLocalCred1` | `http://ollama:11434` |

- 내부 주소만 있고 비밀값이 없어서 저장소에 포함되어 있다.
- import할 때 n8n이 암호화해서 저장한다.
- 워크플로우의 Qdrant Vector Store, Embeddings Ollama, Ollama Chat Model 노드에서 위 이름을 선택해서 사용한다.

## 절차: 키 보관
1. 설치가 끝나면 `.env`의 `N8N_ENCRYPTION_KEY` 값을 안전한 별도 위치에 보관한다.
2. 이 값은 Git, 메신저, AI 채팅에 올리지 않는다.

## 문제가 생겼을 때
1. 키가 바뀌었다면 n8n이 시작되지 않거나 자격증명을 읽지 못한다(TS-002 참조).
2. 원래 키를 알고 있으면 `.env`에 원래 값으로 되돌리고 `docker compose up -d`로 다시 기동한다.
3. 원래 키를 알 수 없으면 `docker compose down -v`로 초기화한 뒤 `install` 스크립트로 다시 설치한다. n8n 데이터와 벡터 데이터가 삭제되므로 문서 재적재와 관리자 계정 재생성이 필요하다.

## 확인 방법
- n8n이 정상 기동되고 노드에서 자격증명 연결 테스트가 성공한다.

## 관련 문서
- SC-001 반입 파일 관리와 비밀정보 취급
- OP-003 .env 환경변수 설정
- TS-002 컨테이너 재시작 반복
- TS-004 Qdrant·Ollama 연결 실패
