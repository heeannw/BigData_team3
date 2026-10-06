---
title: 지식베이스 문서 추가·수정 후 재적재 절차
doc_id: OP-005
category: operations
version: 1.0
created: 2026-10-01
keywords: [재적재, ingest-documents, 문서 추가, 문서 수정, knowledge-base, 청크, qdrant, 임베딩]
---
# OP-005 지식베이스 문서 추가·수정 후 재적재 절차

## 목적
`knowledge-base/`의 문서를 추가하거나 수정한 뒤, 변경 내용이 검색에 반영되도록 다시 적재한다.

## 적용 범위
`knowledge-base/<카테고리>/` 아래의 `.md`, `.txt` 문서와 01 문서 적재 워크플로우.

## 사전 조건
1. Docker 서비스가 실행 중이다(`docker compose ps`).
2. Ollama에 임베딩 모델 `bge-m3`가 준비되어 있다.
3. 문서는 `.md` 또는 `.txt` 형식이다. PDF·DOCX는 텍스트로 변환해서 넣는다.

## 절차
1. 문서를 `knowledge-base/<카테고리>/파일.md`에 추가하거나 수정하고 저장한다. 카테고리 폴더는 operations, security, troubleshooting, rag-guide이다.
2. 적재 스크립트를 실행한다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1
   ```
   Mac·Linux·Git Bash는 `bash scripts/ingest-documents.sh`를 사용한다. n8n 편집기에서 "01 - 문서 적재" 워크플로우를 수동 실행하거나 `POST /webhook/ingest-documents`를 호출해도 된다.
3. 결과 요약을 확인한다.
   - `success`가 `true`이다.
   - `documentCount`, `chunkCount`가 예상과 맞다.
   - `failedBatches`가 `0`이다.
   - `documents` 목록에 추가한 문서가 있다.
4. 필요하면 Qdrant 대시보드(`http://localhost:6333/dashboard`)에서 컬렉션 `knowledge_base`를 확인한다.

## 문서 작성 규칙 요약
- 카테고리는 상위 폴더 이름으로 자동 지정된다. 머리말의 `category`가 있으면 그 값이 우선한다.
- 머리말 `title`, `category`, `version`, `keywords`는 모두 선택 사항이다.
- `#`, `##` 제목 단위로 섹션이 나뉘고, 섹션 제목 경로가 출처로 표시된다. 제목을 의미 있게 쓴다.
- 한 섹션이 800자를 넘으면 문단 단위로 자동 분할된다.

## 동작 방식과 안전장치
- 매번 전체 재적재를 한다. 같은 문서를 여러 번 적재해도 중복이 생기지 않는다.
- 임베딩이 모두 성공한 뒤에만 기존 컬렉션을 교체하므로, 중간에 실패해도 기존 검색 데이터는 유지된다.
- 문서가 하나도 없으면 `NO_DOCUMENTS`를 반환하고 컬렉션을 건드리지 않는다.

## 확인 방법
- 적재 결과가 `success: true`이다.
- 수정한 내용과 관련된 질문을 했을 때 바뀐 내용이 검색된다.

## 주의사항
- 질문 검색에 쓰는 임베딩 모델은 적재할 때와 같은 `bge-m3:latest`여야 한다. 다르면 검색되지 않는다.
- 문서가 많아지면 전체 재적재 시간이 길어질 수 있다.

## 관련 문서
- TS-006 문서 적재 오류와 검색 결과 없음
- TS-005 Ollama 모델 문제
- RG-002 청크 크기 조정 가이드
