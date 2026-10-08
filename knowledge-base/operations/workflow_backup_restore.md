---
title: n8n 워크플로우 내보내기·백업·복원
doc_id: OP-004
category: operations
version: 1.0
created: 2026-10-01
keywords: [워크플로우, 백업, 복원, export, import, json, import-workflows, GitHub]
---
# OP-004 n8n 워크플로우 내보내기·백업·복원

## 목적
n8n 편집기에서 수정한 워크플로우를 JSON으로 저장해 백업하고, 다른 환경에서 복원하는 방법을 안내한다.

## 적용 범위
`workflows/` 폴더의 워크플로우 JSON과 `import-workflows` 스크립트.

## 사전 조건
1. n8n이 실행 중이다(`http://localhost:5678`).
2. 저장소 폴더에서 작업한다.

## 절차 1: 워크플로우 내보내기(백업)
1. n8n 편집기에서 워크플로우를 연다.
2. 우측 상단 메뉴에서 Download(내보내기)를 선택해 JSON 파일을 받는다.
3. 파일을 `workflows/` 폴더에 저장한다. 이름은 `02_xxx.json`처럼 번호를 붙인다.
4. 변경 내용을 Git에 커밋하고 push한다.

## 절차 2: 복원(다시 등록)
1. 저장소를 최신 상태로 받는다.
2. 아래 스크립트를 실행한다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
   ```
   Mac·Linux·Git Bash는 `bash scripts/import-workflows.sh`를 사용한다.
3. 스크립트는 `workflows/*.json`과 자격증명을 import한 뒤 publish하고 n8n을 재시작한다.

## 확인 방법
- n8n 편집기에 워크플로우가 목록에 보이고 게시(Publish/Active) 상태이다.
- Webhook을 POST로 호출했을 때 정상 응답이 온다.

## 주의사항
- JSON 최상위 `id`를 고정해 두어야 다시 import할 때 기존 워크플로우를 덮어쓴다. `id`가 다르면 같은 이름의 워크플로우가 중복되거나 새로 만들어질 수 있다.
- 편집기에서 수정만 하고 JSON을 내보내지 않으면 저장소에 반영되지 않는다.
- 자격증명(Qdrant, Ollama)은 `workflows/credentials/local-services.json`으로 자동 등록되며 비밀값이 들어 있지 않다.
- `docker compose down -v`를 실행하면 n8n 데이터가 모두 삭제되므로, JSON이 저장소에 있어야 복원할 수 있다.

## 관련 문서
- OP-002 Docker Compose 기동·중지·초기화
- SC-002 암호화 키와 자격증명 관리
- TS-001 Webhook 404 또는 미실행
