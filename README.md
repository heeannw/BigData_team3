# BigData_team3

> 폐쇄망에서도 동작하는 n8n·Docker 기반 운영 문의·장애 진단 RAG(Retrieval-Augmented Generation) 챗봇 프로젝트

## 1. 프로젝트 목적

본 프로젝트의 목적은 팀 또는 조직 내부에 흩어진 운영 문서, 매뉴얼, 장애 대응 가이드, 로그 관련 지식을 검색 가능한 형태로 정리하고, 사용자가 자연어로 질문했을 때 **근거 문서를 바탕으로 빠르게 답변·진단을 지원하는 시스템**을 만드는 것입니다. 외부 인터넷과 클라우드 AI를 사용할 수 없는 **폐쇄망 환경**에서도 동작하도록 모든 구성 요소를 로컬 Docker 컨테이너로 실행합니다.

단순한 일반 챗봇이 아니라, 다음 두 상황을 지원하는 것을 목표로 합니다.

- **운영 문의(`operation`)**: 사용자가 업무 시스템, 자동화, n8n Workflow 등의 사용 방법이나 운영 절차를 질문하면 관련 문서를 검색해 안내합니다.
- **장애 진단(`diagnosis`)**: 사용자가 오류 상황이나 로그를 입력하면 관련 지식과 점검 절차를 바탕으로 가능한 원인, 확인 항목, 조치 방향을 제시합니다.

## 2. 프로젝트 목표

### 최종 목표

문서 기반 RAG 파이프라인과 n8n Workflow를 연결하여, 사용자의 질문 유형에 따라 운영 안내 또는 장애 진단 결과를 반환하는 웹 기반 지원 도구를 폐쇄망에서 설치·실행 가능하게 구현합니다.

### 단계별 목표

| 단계 | 내용 | 상태 |
|---|---|---|
| 1 | 브라우저 Mock UI와 n8n Webhook의 API 연동 | ✅ 완료 |
| 2 | 폐쇄망 인프라(Docker Compose) 구성 및 오프라인 설치 | ✅ 완료 |
| 3 | 문서 수집·텍스트 추출·청킹·임베딩·Vector DB 저장 (RAG 데이터 파이프라인) | ✅ 완료 (실제 지식베이스 문서 작성 중) |
| 4 | `operation`과 `diagnosis` 요청 분기 | ⏳ 진행 예정 |
| 5 | 검색된 문서를 근거로 LLM 답변 생성, 출처 반환, 근거 부족 시 답변 보류 | ⏳ 진행 예정 |
| 6 | 평가 질문·기준으로 정확성, 근거 제시, 응답 시간, 장애 진단 품질 검증 | ⏳ 진행 예정 |

## 3. 현재 구현 범위

현재 버전은 **폐쇄망 인프라와 문서 적재(RAG 데이터 파이프라인)까지 완료된 상태**입니다. 질의응답은 아직 Mock 응답을 반환하며, 다음 단계에서 Qdrant 검색과 Ollama 답변을 연결합니다.

```text
[질의응답 - 현재 Mock]
브라우저 ──POST──→ n8n Webhook /webhook/mock-chat ──→ Mock JSON 응답

[문서 적재 - 완료]
knowledge-base/<카테고리>/*.md ──→ 01 문서 적재 Workflow
    ──→ 섹션·청크 분할 ──→ Ollama bge-m3 임베딩 ──→ Qdrant 저장

[인프라 - 완료]
frontend(Nginx) · n8n · PostgreSQL · Qdrant · Ollama  (docker-compose 한 번에 기동)
```

### 현재 완료 기능

**Mock 프로토타입 (표정인)**

- n8n Webhook 기반 Mock Workflow 구성, Production Webhook Publish/Active 검증
- 브라우저 Mock UI에서 `fetch()` POST 요청, HTTP 200 및 JSON 응답 화면 표시
- 빈 질문 입력 시 브라우저 요청 차단
- 기본 평가 케이스와 평가 기준 문서 작성

**폐쇄망 인프라·문서 적재 (원희)**

- Docker Compose로 frontend(Nginx)·n8n·PostgreSQL·Qdrant·Ollama 5개 서비스 구성 (버전 고정, 헬스체크, 내부 네트워크)
- Nginx `/api/*` → n8n `/webhook/*` 프록시 (같은 주소에서 호출하므로 CORS 불필요)
- 01 문서 적재 Workflow: Markdown 섹션 분리 → 청크 분할 → bge-m3 임베딩 → Qdrant 저장, 출처용 메타데이터 저장
- 인터넷 PC에서 이미지·모델을 준비하고 폐쇄망 PC에서 설치하는 스크립트 (bash / PowerShell)
- n8n에 Qdrant·Ollama 자격증명과 Workflow 자동 import·publish
- 이미지 삭제 후 `.tar`만으로 설치 → 적재 → 헬스체크 전 항목 통과 검증

### 현재 미구현 기능

- `operation`과 `diagnosis`의 실제 n8n Switch 분기
- 질문 → Qdrant 검색 → Ollama 답변 생성 (02 질의응답 Workflow)
- 검색 근거 문서 및 출처 표시, 근거 부족 시 답변 보류
- 로그 기반 장애 원인 분석
- 최종 챗봇 UI (`frontend/public/`에 추가 예정. 현재 `http://localhost:8080` 접속 시 403이 정상)
- 실제 지식베이스 문서 (현재 `knowledge-base/` 폴더는 비어 있음)
- 평가 자동화 Workflow
- PDF·DOCX 문서 적재 (현재 `.md`, `.txt`만 지원)
- 인증·권한 관리

## 4. 기술 구조

| 구분 | 사용 기술 | 역할 |
|---|---|---|
| 컨테이너 | Docker Desktop + Docker Compose v2 | 전체 서비스 실행, 폐쇄망 설치 패키지화 |
| 프론트엔드 | HTML, CSS, JavaScript (Fetch API) | 챗봇 화면, 질문 입력, 결과 표시 |
| 정적 웹 서버 | Nginx 1.30 | 화면 제공, `/api` 요청을 n8n으로 내부 프록시 |
| Workflow·API | n8n 2.41.3 (Webhook, Respond to Webhook) | 질문 수신, 분기, 검색·답변 실행, 문서 적재 |
| n8n 영속 DB | PostgreSQL 17 | Workflow, 자격증명, 실행 이력 저장 |
| Vector DB | Qdrant 1.19.1 | 문서 청크·임베딩·메타데이터 저장 및 유사도 검색 |
| 로컬 LLM·임베딩 | Ollama 0.35.0 (bge-m3, qwen2.5:3b) | 문서·질문 벡터 생성(bge-m3, 1024차원), 답변 생성(qwen2.5:3b) |
| 문서·테스트 | Markdown/TXT, CSV/JSON | 지식베이스, 테스트 질문, 평가 결과 |
| 버전 관리 | Git, GitHub | 코드·문서·Workflow JSON 관리 |

## 5. 저장소 구조

```text
BigData_team3/
├── docker-compose.yml                 # 전체 서비스 구성
├── .env.example                       # 환경변수 예시 (.env 로 복사해 사용, .env 는 커밋 금지)
├── frontend/
│   ├── Dockerfile                     # Nginx 이미지
│   ├── nginx.conf                     # /api → n8n 프록시 설정
│   └── public/                        # 최종 챗봇 UI 파일 위치 (index.html, css/, js/ 추가 예정)
├── knowledge-base/                    # RAG 지식베이스 문서 (카테고리별 폴더)
│   ├── operations/
│   ├── rag-guide/
│   ├── security/
│   └── troubleshooting/
├── workflows/
│   ├── 00_webhook_mock_prototype.json # Mock Webhook (POST /webhook/mock-chat)
│   ├── 01_document_ingestion.json     # 문서 적재 (POST /webhook/ingest-documents)
│   └── credentials/
│       └── local-services.json        # Qdrant·Ollama 자격증명 (비밀값 없음)
├── scripts/                           # 설치·적재·점검 스크립트 (.sh / .ps1 / install.bat)
├── offline-assets/                    # 폐쇄망 반입 파일 (GitHub 에는 올라가지 않음)
│   ├── docker-images/                 # offline-rag-images.tar
│   └── model-files/                   # Ollama 모델 파일
├── n8n-webhook-browser-test/          # 초기 Mock 프로토타입
│   ├── frontend/public/index.html     # Mock UI (localhost:5500 으로 실행)
│   └── evaluation/
│       ├── evaluation_cases.csv       # 테스트 케이스 및 실행 결과
│       └── evaluation_rubric.md       # 프로토타입 평가 기준
├── tests/evaluation_results/          # 평가 결과 저장 위치
└── README.md
```

## 6. 시작하기

> 처음 설치한다면 **6.1 → 6.5(전체 환경 설치) → 6.6(문서 적재)** 순서로 진행합니다.

### 6.1 저장소 내려받기

```bash
cd ~/Desktop
git clone https://github.com/heeannw/BigData_team3.git
cd BigData_team3
```

모든 작업은 `main` 브랜치에서 시작합니다.

```bash
git switch main
```

### 6.2 최신 코드 받기

작업 전에는 항상 최신 변경사항을 받습니다.

```bash
git pull origin main
```

### 6.3 Mock UI 실행 (localhost:5500)

초기 연동 테스트용 Mock UI입니다. 항상 켜져 있는 서버가 아니라 **직접 켜야 하는 임시 서버**이므로, 켜기 전에는 `localhost:5500` 접속 시 "연결을 거부했습니다"가 뜨는 것이 정상입니다.

프로젝트 루트에서 다음 명령을 실행합니다.

```bash
# Windows
python -m http.server 5500 --directory n8n-webhook-browser-test/frontend/public --bind 127.0.0.1
```

```bash
# Mac / Linux
python3 -m http.server 5500 --directory n8n-webhook-browser-test/frontend/public --bind 127.0.0.1
```

브라우저에서 아래 주소를 엽니다.

```text
http://localhost:5500
```

서버를 종료하려면 실행 중인 터미널에서 `Ctrl + C`를 누릅니다. 화면은 뜨는데 "요청 실패"가 나오면 n8n이 실행 중인지 확인합니다(6.4).

> 최종 챗봇 UI는 `frontend/public/`에 추가되며, 추가 후에는 `http://localhost:8080`에서 열립니다.

### 6.4 n8n 실행 및 Workflow 확인

n8n은 Docker 환경(6.5)으로 실행합니다. `install` 스크립트가 `workflows/` 폴더의 Workflow JSON과 자격증명을 **자동으로 import·publish**하므로 수동 import는 필요 없습니다.

| 주소 | 내용 |
|---|---|
| `http://localhost:5678` | n8n 편집기 (최초 접속 시 관리자 계정 생성, 계정은 각 PC 로컬에만 저장) |
| `POST http://localhost:5678/webhook/mock-chat` | 00 Mock Webhook |
| `POST http://localhost:5678/webhook/ingest-documents` | 01 문서 적재 |

- 이미 설치했다면 `docker compose up -d`로 다시 켭니다.
- n8n 편집기에서 Workflow를 수정했다면 JSON으로 export해 `workflows/`에 저장한 뒤, 아래 명령으로 다시 등록합니다. JSON 최상위 `id`가 같으면 기존 Workflow를 덮어씁니다.

```bash
bash scripts/import-workflows.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
```

- Webhook CORS는 각 Webhook 노드의 Options → Allowed Origins로 설정합니다(기본값 `*`). 최종 UI는 Nginx `/api` 프록시로 같은 주소에서 호출하므로 CORS 설정이 필요 없습니다.
- Docker 없이 n8n을 따로 설치해 쓰고 있다면 5678 포트가 겹칩니다. 기존 n8n을 끈 뒤 Docker 환경을 실행합니다.

> 브라우저 주소창에서 `http://localhost:5678/webhook/mock-chat`을 직접 열면 GET 요청이 발생합니다. 현재 Webhook은 POST 전용이므로 GET 요청에는 안내성 404가 표시되는 것이 정상입니다.

### 6.5 Docker Compose 전체 환경 (폐쇄망 인프라)

`frontend(Nginx)`, `n8n`, `postgres`, `qdrant`, `ollama` 5개 서비스를 한 번에 기동합니다. 모든 스크립트는 bash(`.sh`)와 Windows PowerShell(`.ps1`) 두 가지로 제공합니다. Windows 폐쇄망 PC에서는 `scripts\install.bat`을 더블클릭하면 됩니다.

```text
브라우저 → frontend(Nginx :8080) ─ /api/* → n8n(:5678) /webhook/* ─→ qdrant(Vector DB)
                                                                  └→ ollama(LLM·Embedding)
                                              n8n 영속 데이터 → postgres
```

| 서비스 | 이미지(버전 고정) | 외부 포트 | 비고 |
|---|---|---|---|
| frontend | `offline-rag-frontend:local` (nginx 1.30) | 8080 | `/api/<path>` → n8n `/webhook/<path>` 프록시 |
| n8n | `n8nio/n8n:2.41.3` | 5678 | Workflow 편집·실행 |
| postgres | `postgres:17-alpine` | 없음 | n8n Workflow·실행 이력 저장 |
| qdrant | `qdrant/qdrant:v1.19.1` | 127.0.0.1:6333 | 개발 디버깅용으로 로컬에만 노출 |
| ollama | `ollama/ollama:0.35.0` | 127.0.0.1:11434 | 모델 파일은 `offline-assets/model-files/`에 저장 |

**인터넷 PC에서 반입 패키지 준비** (이미지 pull·저장, 모델 다운로드)

```bash
bash scripts/prepare-offline.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\prepare-offline.ps1
```

완료 후 저장소 폴더 전체를 폐쇄망 PC로 복사합니다. 반입 대상은 `offline-assets/docker-images/offline-rag-images.tar`(약 4GB)와 `offline-assets/model-files/`(bge-m3 + qwen2.5:3b, 약 3GB)입니다. 둘 다 `.gitignore` 대상이라 GitHub에는 올라가지 않습니다.

**폐쇄망 PC에서 설치·기동** (`.env` 생성·비밀값 자동 생성 → 이미지 load → 기동 → 자격증명·Workflow import/publish → 헬스체크)

```bash
bash scripts/install.sh
```

```powershell
scripts\install.bat
```

> 인터넷이 되는 개발 PC에서는 `prepare-offline` 없이 `install`만 실행해도 됩니다. 이미지는 자동으로 받고, 모델은 `prepare-offline`을 한 번 실행하거나 `docker compose exec ollama ollama pull bge-m3`, `docker compose exec ollama ollama pull qwen2.5:3b`로 받습니다.

| 스크립트 (`.sh` / `.ps1`) | 역할 |
|---|---|
| `prepare-offline` | [인터넷 PC] 이미지 `.tar` 저장, Ollama 모델 다운로드 |
| `install` (+ `install.bat`) | [폐쇄망 PC] 설치·기동 전체 수행. `.tar`가 있으면 `--pull never`로 기동하여 인터넷 접근 시 즉시 실패 |
| `import-workflows` | 자격증명과 `workflows/*.json`을 n8n에 import 후 publish (JSON 수정 후 재실행 가능) |
| `ingest-documents` | 지식베이스 문서를 Qdrant에 재적재. 서비스·임베딩 모델 사전 점검, 실패 시 종료 코드 1 |
| `health-check` | 컨테이너·서비스·모델·컬렉션 상태 점검 |

> 모든 설정값은 `.env`(= `.env.example` 복사본)에서 관리합니다. `.env`는 커밋하지 않습니다. `.env`의 `N8N_ENCRYPTION_KEY`는 설치 후 바꾸지 않습니다(바꾸면 저장된 자격증명을 읽지 못함).

자주 쓰는 명령:

```bash
docker compose up -d        # 기동 (데이터 유지)
docker compose stop         # 중지 (데이터 유지)
docker compose ps           # 상태 확인
docker compose down -v      # 전체 초기화 (DB·벡터 데이터 삭제, 모델 파일은 유지)
```

**n8n 자격증명 (자동 등록)**: `workflows/credentials/local-services.json`이 import되어 아래 두 자격증명이 생깁니다. 02 질의응답 Workflow의 Qdrant Vector Store / Embeddings Ollama / Ollama Chat Model 노드에서 선택하면 됩니다. 비밀값이 없는 내부 주소라 저장소에 포함합니다.

| 이름 | id | 값 |
|---|---|---|
| Qdrant (local) | `qdrantLocalCred1` | `http://qdrant:6333` |
| Ollama (local) | `ollamaLocalCred1` | `http://ollama:11434` |

**검증 기록 (2026-09-29, Windows 11 / Docker Desktop, CPU 16코어·GPU 없음)**

| 항목 | 결과 |
|---|---|
| 이미지 삭제 후 `.tar`만으로 `install.ps1` 설치 | 성공, 약 7분 (대부분 이미지 load) |
| 헬스체크 (`.sh`, `.ps1`) | 전 항목 OK |
| n8n 기본 Qdrant Vector Store 노드로 적재 데이터 검색 | `pageContent`·`metadata` 정상 반환 |
| qwen2.5:3b RAG 프롬프트(약 1,100토큰) 응답 | 첫 호출 21초(모델 로드 포함), 이후 6초, 약 17 tokens/s |
| Ollama 컨텍스트 길이 | 기본 4096 → 8192로 설정 (`OLLAMA_CONTEXT_LENGTH`) |

### 6.6 문서 적재 (01 문서 적재 Workflow)

`knowledge-base/<카테고리>/*.md|*.txt` 문서를 읽어 **섹션 분리 → 청크 분할 → bge-m3 임베딩 → Qdrant 저장**을 수행합니다.

```bash
bash scripts/ingest-documents.sh
# 또는 n8n 편집기에서 "01 - 문서 적재" Workflow 를 수동 실행
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1
```

- 실행할 때마다 컬렉션(`knowledge_base`)을 **전체 재생성**합니다. 임베딩까지 성공한 뒤에만 기존 컬렉션을 교체하므로, 적재가 실패해도 기존 데이터는 유지됩니다.
- 문서가 없으면 `{"success": false, "error": "NO_DOCUMENTS", "message": ...}`를 반환하고 컬렉션은 건드리지 않습니다.
- 02 Workflow의 Embeddings Ollama 노드는 적재와 같은 모델(`bge-m3:latest`)을 써야 합니다. 모델이 다르면 벡터 차원·공간이 달라 검색되지 않습니다.
- 청크 크기는 `.env`의 `CHUNK_SIZE`(기본 800자), `CHUNK_OVERLAP`(기본 100자)으로 조정합니다.
- `#`, `##` 제목 단위로 섹션이 나뉘고, 제목 경로가 출처(`section`)로 저장됩니다. 제목을 의미 있게 작성하면 출처 표시 품질이 좋아집니다.
- 카테고리는 상위 폴더명으로 자동 지정됩니다. 문서 맨 위에 front matter를 넣으면 메타데이터로 저장됩니다(모두 선택 사항).

```markdown
---
title: n8n 워크플로우 백업 가이드
category: operations        # 생략 시 상위 폴더명
version: 1.0
keywords: [n8n, 백업, export]
---
# n8n 워크플로우 백업
## CLI 백업
...
```

Qdrant 포인트 payload 구조 (n8n Qdrant Vector Store 노드 기본 키 `content`/`metadata`와 호환):

```json
{
  "content": "청크 본문",
  "metadata": {
    "documentName": "backup.md", "title": "n8n 워크플로우 백업 가이드",
    "category": "operations", "section": "n8n 워크플로우 백업 > CLI 백업",
    "chunkId": "operations/backup.md#000", "chunkIndex": 0,
    "source": "operations/backup.md", "version": "1.0", "keywords": ["n8n", "백업", "export"]
  }
}
```

`metadata.documentName / category / section / chunkId`는 API 응답 `sources` 필드에 그대로 사용할 수 있습니다. `metadata.category`에는 필터 검색용 인덱스가 생성됩니다.

## 7. API 명세

### Endpoint

| 용도 | 브라우저(Nginx 경유) | n8n 직접 호출 |
|---|---|---|
| Mock 질의응답 (현재) | `POST http://localhost:8080/api/mock-chat` | `POST http://localhost:5678/webhook/mock-chat` |
| 문서 적재 | - | `POST http://localhost:5678/webhook/ingest-documents` |

최종 UI는 `fetch('/api/<webhook경로>')`처럼 **상대 경로**로 호출합니다. 02 질의응답 Workflow가 추가되면 이 표에 경로를 추가합니다.

### Request Body

```json
{
  "question": "Webhook은 수신되는데 다음 노드가 실행되지 않습니다.",
  "requestType": "diagnosis",
  "logText": "",
  "sessionId": "local-demo-session"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `question` | string | 사용자가 입력한 질문 |
| `requestType` | string | `operation` 또는 `diagnosis` |
| `logText` | string | 장애 진단 시 전달할 로그 또는 추가 정보 |
| `sessionId` | string | 사용자 세션 식별자 |

### 목표 Response (역할 분담 설계서 기준)

```json
{
  "success": true,
  "requestType": "diagnosis",
  "answer": "답변 본문",
  "diagnosis": {
    "summary": "요약",
    "possibleCauses": ["원인 후보"],
    "checkSteps": ["점검 항목"],
    "actions": ["조치 방향"]
  },
  "sources": [
    { "documentName": "webhook.md", "category": "troubleshooting", "section": "Webhook 장애 > 증상", "chunkId": "troubleshooting/webhook.md#000" }
  ],
  "responseTimeMs": 6200
}
```

- `operation` 요청은 `diagnosis`를 `null`로 반환합니다.
- 근거가 부족하면 `answer`는 "제공된 내부 자료에서는 확인할 수 없습니다."로 반환하고 `sources`는 빈 배열로 반환합니다.

### 현재 Mock Response

```json
{
  "success": true,
  "requestType": "operation",
  "answer": "현재는 초기 프로토타입의 임시 응답입니다. 실제 RAG 연결 후 내부 문서를 근거로 답변합니다.",
  "diagnosis": null,
  "sources": [],
  "responseTimeMs": 0
}
```

> 현재 Mock Workflow는 요청 유형 분기가 없어서 `diagnosis` 요청에도 같은 임시 응답을 반환합니다.

### 문서 적재 Response 예시

```json
{
  "success": true,
  "collection": "knowledge_base",
  "embedModel": "bge-m3",
  "vectorSize": 1024,
  "documentCount": 2,
  "chunkCount": 7,
  "chunksByCategory": { "operations": 2, "troubleshooting": 5 },
  "failedBatches": 0,
  "documents": ["operations/backup.md", "troubleshooting/webhook.md"]
}
```

## 8. 테스트 및 평가

Mock 프로토타입 평가 자료는 `n8n-webhook-browser-test/evaluation/` 폴더에 있습니다. RAG 평가 결과는 `tests/evaluation_results/`에 저장합니다.

| 파일 | 역할 |
|---|---|
| `n8n-webhook-browser-test/evaluation/evaluation_cases.csv` | 테스트 케이스, 기대 결과, 실제 결과, PASS/FAIL 기록 |
| `n8n-webhook-browser-test/evaluation/evaluation_rubric.md` | Mock UI·Webhook 연동 평가 기준 |

### Mock 프로토타입 테스트 케이스

| ID | 테스트 내용 | 기대 결과 |
|---|---|---|
| TC-001 | `operation` 정상 질문 | HTTP 200, JSON 응답, 화면 출력 |
| TC-002 | `diagnosis` 정상 질문 | HTTP 200, JSON 응답, 화면 출력 |
| TC-003 | 빈 질문 제출 | API 호출 없이 안내 문구 표시 |

### 현재 평가 결과

- TC-001: PASS — Production Webhook 호출과 HTTP 200·JSON 응답 확인
- TC-002: PASS — diagnosis 요청에 대한 HTTP 200·JSON 응답 확인
- TC-003: PASS — 빈 질문 브라우저 입력 검증 확인
- Docker 환경 전환 후에도 Mock UI(5500) → Docker n8n `mock-chat` 호출 HTTP 200 확인

환경 상태는 아래 명령으로 점검합니다. 하나라도 실패하면 종료 코드 1을 반환합니다.

```bash
bash scripts/health-check.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts\health-check.ps1
```

## 9. 다음 개발 순서

역할 분담 설계서의 개발·통합 순서 기준입니다.

| 순서 | 담당 | 작업 | 상태 |
|---|---|---|---|
| 1 | 원희 | Docker Compose 기동, frontend/Nginx 기본 설정 | ✅ 완료 |
| 2 | 박윤아 | n8n Webhook 임시 JSON 응답 (Mock) | ✅ 완료 (표정인 프로토타입) |
| 3 | 박윤아 | HTML/CSS/JavaScript 챗봇 화면, 입력·전송·로딩·오류 처리 | ⏳ |
| 4 | 김해인 | 운영 문서·장애 사례집 작성 및 카테고리 분류 | ⏳ |
| 5 | 원희 | 문서 적재 Workflow (청크·임베딩·Qdrant 저장) | ✅ 완료 (문서 추가 시 재적재) |
| 6 | 박윤아 | RAG 검색·Ollama 답변, 일반/진단 분기, 출처·답변 보류 | ⏳ |
| 7 | 표정인 | 평가 Workflow로 응답·검색 품질·출처·답변 보류 자동 검증 | ⏳ |
| 8 | 이예린 | 전체 Docker Compose 실행, 설치 재현, 사용자 시나리오 테스트 | ⏳ |
| 9 | 전체 | 네트워크 차단 상태 최종 시연, 제출물 점검 | ⏳ |

### 요청 유형 분기 및 RAG 답변 (02 질의응답 Workflow)

```text
Webhook
  │
  ▼
Switch: requestType
  ├── operation → Qdrant 검색 → Ollama 답변 → 출처 포함 응답
  └── diagnosis → Qdrant 검색(troubleshooting 우선) → 원인·점검·조치 구조화
```

- Qdrant Vector Store 노드: 자격증명 `Qdrant (local)`, 컬렉션 `knowledge_base`
- Embeddings Ollama 노드: 자격증명 `Ollama (local)`, 모델 `bge-m3:latest`
- 답변 모델: `qwen2.5:3b` (`.env`의 `OLLAMA_CHAT_MODEL`)
- 잘못된 요청 유형에는 명확한 오류 응답을 반환합니다.
- 근거가 부족하면 추측하지 않고 답변을 보류합니다.
- CPU 환경에서 답변 1건에 6~30초가 걸리므로 UI에 로딩 표시가 필요합니다.
- 완성한 Workflow는 `workflows/02_xxx.json`으로 export해 GitHub에 올립니다.

### 폐쇄망 설치·운영

- 인터넷 PC에서 `prepare-offline` → 폴더 복사 → 폐쇄망 PC에서 `install.bat`
- 네트워크를 실제로 차단한 상태에서 설치·질의응답 재현 테스트
- n8n 실행 이력·실패 실행·응답 시간 확인
- Workflow를 수정하면 JSON을 export해 GitHub에 지속적으로 반영

## 10. 협업 규칙

### 작업 시작 전

```bash
git status
git switch main
git pull origin main
```

### 새 기능 작업 브랜치 생성 예시

```bash
git switch main
git pull origin main
git switch -c feature/request-type-switch
```

### 작업 후 GitHub 업로드

```bash
git status
git add .
git commit -m "feat: split operation and diagnosis responses"
git push -u origin feature/request-type-switch
```

이후 같은 브랜치에서 추가 작업을 업로드할 때는 아래를 사용합니다.

```bash
git add .
git commit -m "feat: update diagnosis response"
git push
```

작업이 끝나면 GitHub에서 `main ← 작업 브랜치` Pull Request를 만들어 머지합니다.

### 커밋 전 주의사항

- `.env`, `offline-assets/`의 이미지·모델 파일은 커밋하지 않습니다(`.gitignore` 대상). 변경 목록에 보이면 `.gitignore`가 없는 브랜치에 있는지 확인합니다.
- GitHub Desktop에서 "Files too large" 경고가 뜨면 **Commit anyway를 누르지 말고** 취소합니다.

## 11. 팀 인수인계 요약

현재 아래 흐름까지 구현·검증되어 있습니다.

```text
[완료] 폐쇄망 설치 (install.bat) → 5개 서비스 기동 → Workflow·자격증명 자동 등록
[완료] knowledge-base 문서 → 01 문서 적재 → Qdrant 저장 (검색 동작 확인)
[완료] Mock UI → n8n Webhook → Mock JSON 응답 → 브라우저 출력
```

다음 작업자는 인프라와 적재를 다시 만들 필요 없이 아래부터 진행하면 됩니다.

- **지식베이스**: `knowledge-base/<카테고리>/`에 문서를 추가하고 `ingest-documents`로 적재합니다(6.6).
- **질의응답**: 자동 등록된 자격증명으로 02 질의응답 Workflow(검색·답변·분기·출처)를 구현하고, 최종 UI를 `frontend/public/`에 추가합니다(9장).
- **평가**: `ingest-documents` 후 02 Workflow를 반복 호출하는 평가 Workflow를 구현합니다.
- **설치 재현**: 다른 PC·네트워크 차단 환경에서 6.5 절차대로 설치를 재현합니다.
