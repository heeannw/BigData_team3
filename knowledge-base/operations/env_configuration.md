---
title: .env 환경변수 설정과 관리
doc_id: OP-003
category: operations
version: 1.0
created: 2026-10-01
keywords: [.env, 환경변수, env.example, N8N_ENCRYPTION_KEY, CHUNK_SIZE, CHUNK_OVERLAP, OLLAMA_CHAT_MODEL, 설정]
---
# OP-003 .env 환경변수 설정과 관리

## 목적
서비스 설정 값을 `.env` 파일에서 관리하는 방법과 주의사항을 안내한다.

## 적용 범위
저장소 폴더의 `.env`와 `.env.example`. 모든 설정 값은 `.env`에서 관리한다.

## 사전 조건
1. 저장소 폴더에서 작업한다.
2. 최초 설치는 `install` 스크립트가 `.env`를 만들어 준다(OP-001 참조).

## 주요 설정 값
| 변수 | 설명 |
|---|---|
| `N8N_ENCRYPTION_KEY` | n8n이 자격증명을 암호화하는 키. 설치 시 자동 생성 |
| `POSTGRES_PASSWORD` | PostgreSQL 비밀번호. 설치 시 자동 생성 |
| `CHUNK_SIZE` | 문서 청크 크기(기본 800자) |
| `CHUNK_OVERLAP` | 청크 겹침 길이(기본 100자) |
| `OLLAMA_CHAT_MODEL` | 답변 생성 모델(기본 `qwen2.5:3b`) |
| `OLLAMA_CONTEXT_LENGTH` | Ollama 컨텍스트 길이(8192로 설정) |

## 절차: 설정 값 바꾸기
1. `.env` 파일을 텍스트 편집기(VS Code 등)로 연다.
2. 값을 수정하고 저장한다.
3. 변경을 반영하려면 서비스를 다시 기동한다.
   ```bash
   docker compose up -d
   ```
4. `CHUNK_SIZE`나 `CHUNK_OVERLAP`을 바꿨다면 문서를 다시 적재한다(OP-005).

## 확인 방법
- `docker compose ps`에서 서비스가 정상 기동되었다.
- 적재 결과의 `chunkCount`가 설정 변경에 맞게 달라졌다.

## 주의사항
- `.env`는 Git에 커밋하지 않는다(`.gitignore` 대상). 공유할 때는 `.env.example`만 사용하고 예시 값에는 PLACEHOLDER를 쓴다.
- `N8N_ENCRYPTION_KEY`는 설치 후 변경하지 않는다. 바꾸면 저장된 자격증명을 읽을 수 없다(SC-002).
- 비밀번호와 키 값은 메신저·AI 채팅에 붙여 넣지 않는다.
- `.env`는 PC마다 설치 시 새로 만들어지므로 팀원끼리 파일을 주고받지 않는다.

## 관련 문서
- OP-001 폐쇄망 설치 절차
- OP-005 문서 재적재 절차
- SC-002 암호화 키와 자격증명 관리
- RG-002 청크 크기 조정 가이드
