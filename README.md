# BigData_team3

> n8n Webhook과 RAG(Retrieval-Augmented Generation)를 활용해 운영 문의와 장애 진단을 지원하는 지식 기반 챗봇 프로젝트

## 1. 프로젝트 목적

본 프로젝트의 목적은 팀 또는 조직 내부에 흩어진 운영 문서, 매뉴얼, 장애 대응 가이드, 로그 관련 지식을 검색 가능한 형태로 정리하고, 사용자가 자연어로 질문했을 때 **근거 문서를 바탕으로 빠르게 답변·진단을 지원하는 시스템**을 만드는 것입니다.

단순한 일반 챗봇이 아니라, 다음 두 상황을 지원하는 것을 목표로 합니다.

- **운영 문의(`operation`)**: 사용자가 업무 시스템, 자동화, n8n Workflow 등의 사용 방법이나 운영 절차를 질문하면 관련 문서를 검색해 안내합니다.
- **장애 진단(`diagnosis`)**: 사용자가 오류 상황이나 로그를 입력하면 관련 지식과 점검 절차를 바탕으로 가능한 원인, 확인 항목, 조치 방향을 제시합니다.

## 2. 프로젝트 목표

### 최종 목표

문서 기반 RAG 파이프라인과 n8n Workflow를 연결하여, 사용자의 질문 유형에 따라 운영 안내 또는 장애 진단 결과를 반환하는 웹 기반 지원 도구를 구현합니다.

### 단계별 목표

1. 브라우저 Mock UI와 n8n Webhook의 API 연동을 구현합니다.
2. `operation`과 `diagnosis` 요청을 분기하는 Workflow를 구현합니다.
3. 문서 수집, 텍스트 추출, 청킹, 임베딩, Vector DB 검색으로 RAG 데이터 파이프라인을 구축합니다.
4. 검색된 문서를 근거로 LLM이 답변을 생성하고, 출처 정보를 함께 반환하도록 구현합니다.
5. 평가 질문과 평가 기준을 통해 응답 정확성, 근거 제시 여부, 응답 시간, 장애 진단 품질을 검증합니다.

## 3. 현재 구현 범위

현재 버전은 **RAG 연결 전 초기 Mock 프로토타입**입니다. 브라우저에서 n8n Production Webhook을 실제로 호출하고, n8n이 JSON 응답을 반환하는 최소 실행 흐름을 구현·검증했습니다.

```text
브라우저 Mock UI
      │
      │ POST JSON
      ▼
n8n Production Webhook
/webhook/mock-chat
      │
      ▼
Mock Workflow
      │
      ▼
Respond to Webhook
      │
      │ JSON 응답
      ▼
브라우저 결과 화면
```

### 현재 완료 기능

- n8n Webhook 기반 Mock Workflow 구성
- Test URL과 Production URL 분리 검증
- Production Webhook Publish/Active 상태 확인
- 브라우저 Mock UI에서 `fetch()`를 이용한 POST 요청 구현
- HTTP 200 및 JSON 응답 화면 표시 확인
- 빈 질문 입력 시 브라우저 요청 차단
- n8n Workflow JSON export 및 GitHub 버전 관리
- 기본 평가 케이스와 평가 기준 문서 작성

### 현재 미구현 기능

- `operation`과 `diagnosis`의 실제 n8n Switch 분기
- 문서 업로드 및 텍스트 추출
- 문서 청킹, 임베딩 생성, Vector DB 저장·검색
- LLM 기반 RAG 답변 생성
- 검색 근거 문서 및 출처 표시
- 로그 기반 장애 원인 분석
- 인증, 권한 관리, 팀 공유용 배포 환경

## 4. 기술 구조

| 구분 | 현재 사용 기술/역할 |
|---|---|
| Workflow 자동화 | n8n |
| API 진입점 | n8n Webhook (`POST /webhook/mock-chat`) |
| 응답 방식 | Respond to Webhook JSON 응답 |
| 프론트엔드 | HTML, CSS, JavaScript |
| 브라우저 요청 | Fetch API (`POST`, `application/json`) |
| 버전 관리 | Git, GitHub |
| 향후 검색 계층 | Embedding Model, Vector DB, RAG |
| 향후 생성 계층 | LLM 기반 답변·장애 진단 |

## 5. 저장소 구조

```text
BigData_team3/
├── frontend/
│   └── public/
│       └── index.html                 # n8n Webhook 호출 Mock UI
├── evaluation/
│   ├── evaluation_cases.csv           # 테스트 케이스 및 실행 결과
│   └── evaluation_rubric.md           # 프로토타입 평가 기준
├── workflows/
│   └── *.json                         # n8n Workflow export JSON (업로드된 경우)
├── README.md
└── ...
```

> n8n Workflow JSON의 실제 파일명과 위치는 저장소에 업로드된 구조에 맞춰 확인합니다.

## 6. 시작하기

### 6.1 저장소 내려받기

```bash
cd ~/Desktop
git clone https://github.com/heeannw/BigData_team3.git
cd BigData_team3
```

원격 브랜치를 확인합니다.

```bash
git branch -a
```

초기 Mock 프로토타입 작업 브랜치로 이동합니다.

```bash
git switch --track origin/feature/initial-prototype
```

이미 로컬 브랜치가 만들어져 있다면 아래 명령을 사용합니다.

```bash
git switch feature/initial-prototype
```

### 6.2 최신 코드 받기

작업 전에는 항상 현재 브랜치의 최신 변경사항을 받습니다.

```bash
git pull origin feature/initial-prototype
```

### 6.3 프론트엔드 실행

프로젝트 루트에서 다음 명령을 실행합니다.

```bash
python3 -m http.server 5500 --directory frontend/public --bind 127.0.0.1
```

브라우저에서 아래 주소를 엽니다.

```text
http://localhost:5500
```

서버를 종료하려면 실행 중인 터미널에서 `Ctrl + C`를 누릅니다.

### 6.4 n8n 실행 및 Workflow 확인

n8n이 로컬에서 실행 중이어야 합니다. 현재 Mock UI는 아래 Production Webhook으로 요청을 보냅니다.

```text
POST http://localhost:5678/webhook/mock-chat
```

n8n에서 확인할 사항은 다음과 같습니다.

1. Webhook Workflow JSON을 import합니다. 
2. Webhook의 HTTP Method가 `POST`인지 확인합니다.
3. Webhook Path가 `mock-chat`인지 확인합니다.
4. Workflow를 Publish/Active 상태로 전환합니다.
5. 브라우저 UI를 `http://localhost:5500`에서 열었다면 CORS Allowed Origins에 아래를 허용합니다.

```text
http://localhost:5500
```

> 브라우저 주소창에서 `http://localhost:5678/webhook/mock-chat`을 직접 열면 GET 요청이 발생합니다. 현재 Webhook은 POST 전용이므로 GET 요청에는 안내성 404가 표시되는 것이 정상입니다.

## 7. API 명세

### Endpoint

```text
POST /webhook/mock-chat
```

로컬 전체 주소:

```text
http://localhost:5678/webhook/mock-chat
```

### Request Body

```json
{
  "question": "n8n 워크플로우 백업 방법을 알려줘.",
  "requestType": "operation",
  "logText": "",
  "sessionId": "browser-demo-session"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `question` | string | 사용자가 입력한 질문 |
| `requestType` | string | `operation` 또는 `diagnosis` |
| `logText` | string | 장애 진단 시 전달할 로그 또는 추가 정보 |
| `sessionId` | string | 사용자 세션 식별자 |

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

> 현재 Workflow는 Mock 단계이므로 `diagnosis` 요청에도 공통 임시 응답이 반환될 수 있습니다. 다음 단계에서 Switch 노드를 사용해 요청 유형별 응답을 분리합니다.

## 8. 테스트 및 평가

평가 자료는 `evaluation/` 폴더에서 관리합니다.

| 파일 | 역할 |
|---|---|
| `evaluation/evaluation_cases.csv` | 테스트 케이스, 기대 결과, 실제 결과, PASS/FAIL 기록 |
| `evaluation/evaluation_rubric.md` | Mock UI·Webhook 연동 평가 기준 |

### 필수 테스트 케이스

| ID | 테스트 내용 | 기대 결과 |
|---|---|---|
| TC-001 | `operation` 정상 질문 | HTTP 200, JSON 응답, 화면 출력 |
| TC-002 | `diagnosis` 정상 질문 | HTTP 200, JSON 응답, 화면 출력 |
| TC-003 | 빈 질문 제출 | API 호출 없이 안내 문구 표시 |

### 현재 평가 결과

- TC-001: PASS — Production Webhook 호출과 HTTP 200·JSON 응답 확인
- TC-002: PASS — diagnosis 요청에 대한 HTTP 200·JSON 응답 확인
- TC-003: PASS — 빈 질문 브라우저 입력 검증 확인

## 9. 다음 개발 순서

### 1단계: 요청 유형 실제 분기

n8n Workflow에서 Webhook 다음에 Switch 노드를 추가합니다.

```text
Webhook
  │
  ▼
Switch: requestType
  ├── operation → 운영 문의용 응답
  └── diagnosis → 장애 진단용 응답
```

- `operation`과 `diagnosis`에 서로 다른 응답 JSON을 정의합니다.
- 잘못된 요청 유형에는 명확한 오류 응답을 반환합니다.
- 분기 결과를 평가 CSV에 추가 기록합니다.

### 2단계: RAG 데이터 파이프라인

- 대상 문서 및 데이터 범위 정의
- 텍스트 추출 및 정제
- 문서 청킹과 메타데이터 설계
- 임베딩 생성
- Vector DB 저장 및 유사도 검색
- 검색 결과와 출처 정보를 `sources`에 반환

### 3단계: LLM 답변·장애 진단

- 검색 결과를 바탕으로 운영 안내 답변 생성
- 장애 로그와 검색 근거를 기반으로 원인·점검 항목·조치 순서 제시
- 근거가 부족하면 추측하지 않고 추가 정보 요청
- 문서 출처를 답변과 함께 제공

### 4단계: 배포·운영

- 팀 공유가 가능한 서버 또는 클라우드 환경으로 배포
- CORS, 인증, 권한, 비밀값 관리를 설정
- n8n 실행 이력·실패 실행·응답 시간 모니터링
- Workflow JSON을 GitHub에 지속적으로 export하여 변경 이력 관리

## 10. 협업 규칙

### 작업 시작 전

```bash
git status
git pull origin feature/initial-prototype
```

### 새 기능 작업 브랜치 생성 예시

```bash
git switch feature/initial-prototype
git pull origin feature/initial-prototype
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

## 11. 팀 인수인계 요약

현재 Mock 프로토타입은 아래 흐름까지 검증되어 있습니다.

```text
Mock UI → n8n Production Webhook → Mock JSON Response → 브라우저 출력
```

다음 작업자는 기존 연결을 다시 만들 필요 없이 `requestType` 실제 분기부터 구현하면 됩니다. 이후 RAG 문서 검색, LLM 답변, 장애 진단 고도화, 배포 환경 구성 순서로 확장합니다.
