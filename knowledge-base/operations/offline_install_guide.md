---
title: 폐쇄망 설치 절차(반입 패키지 준비부터 설치·기동까지)
doc_id: OP-001
category: operations
version: 1.0
created: 2026-10-01
keywords: [폐쇄망, 설치, 오프라인, prepare-offline, install, install.bat, 반입, docker 이미지, 모델]
---
# OP-001 폐쇄망 설치 절차

## 목적
인터넷이 차단된 PC에 n8n·Qdrant·Ollama 기반 RAG 챗봇 환경을 설치하고 기동한다.

## 적용 범위
- 인터넷이 되는 PC(반입 패키지 준비)와 폐쇄망 PC(설치)
- Windows는 PowerShell 스크립트와 `install.bat`, Mac·Linux·Git Bash는 `.sh` 스크립트를 사용한다.

## 사전 조건
1. 두 PC 모두 Docker Desktop(Docker Compose v2)이 설치되어 있다.
2. 반입 파일 합계 약 7GB(이미지 약 4GB, 모델 약 3GB)를 저장할 여유 공간이 있다.
3. USB 등 파일 이동 수단이 있다.

## 절차 1: 인터넷 PC에서 반입 패키지 준비
1. 저장소를 내려받고 저장소 폴더에서 스크립트를 실행한다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\prepare-offline.ps1
   ```
   Mac·Linux는 `bash scripts/prepare-offline.sh`를 실행한다.
2. 완료되면 다음 두 가지가 만들어졌는지 확인한다.
   - `offline-assets/docker-images/offline-rag-images.tar` (약 4GB)
   - `offline-assets/model-files/` (bge-m3, qwen2.5:3b 모델, 약 3GB)
3. `offline-assets`를 포함한 저장소 폴더 전체를 USB 등으로 폐쇄망 PC에 복사한다. 이 두 항목은 GitHub에 올라가지 않으므로 반드시 직접 복사해야 한다.

## 절차 2: 폐쇄망 PC에서 설치·기동
1. Docker Desktop을 실행한다.
2. `scripts\install.bat`을 더블클릭한다. Mac·Linux는 `bash scripts/install.sh`를 실행한다.
3. 스크립트가 다음을 자동으로 수행한다.
   - `.env` 생성과 비밀값 자동 생성
   - Docker 이미지 load
   - 서비스 기동(`--pull never`, 인터넷에서 받는 이미지가 없음)
   - Qdrant·Ollama 자격증명과 워크플로우 import·publish
   - 헬스체크
4. 개발 PC에서 검증한 설치 소요 시간은 약 7분이며 대부분 이미지 load 시간이다.

## 절차 3: 설치 후 첫 설정
1. 브라우저에서 `http://localhost:5678`에 접속해 n8n 관리자 계정을 만든다. 이 계정은 각 PC에만 저장되고 팀원끼리 공유되지 않는다.
2. 지식베이스 문서를 적재한다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1
   ```
3. 상태를 점검한다.
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\health-check.ps1
   ```

## 확인 방법
- `health-check` 결과가 전 항목 OK이다.
- `http://localhost:8080/healthz`에서 `ok`가 표시된다.
- `http://localhost:5678`에서 n8n 편집기가 열린다.

## 주의사항
- 인터넷이 되는 개발 PC에서는 `prepare-offline` 없이 `install`만 실행해도 된다. 이미지는 자동으로 받고 모델은 직접 내려받는다.
- Docker 이미지나 Ollama 모델의 버전을 바꾸면 `prepare-offline`을 다시 실행해 반입 패키지를 새로 만들어야 한다.
- `.env` 파일은 Git에 커밋하지 않는다.
- `.env`의 `N8N_ENCRYPTION_KEY`는 설치 후 바꾸지 않는다. 바꾸면 저장된 자격증명을 읽지 못한다.

## 관련 문서
- OP-002 Docker Compose 기동·중지·초기화
- OP-006 서비스 상태 확인 방법
- TS-002 컨테이너 재시작 반복
- TS-005 Ollama 모델 문제
