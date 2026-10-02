# 장애 사례집 (Troubleshooting Casebook)

폐쇄망 n8n·Docker AI 자동화 운영/장애진단 RAG 챗봇 · 작성 담당: 김해인 · 작성일: 2026-10-01 · 버전 1.0

> 이 문서는 `knowledge-base/troubleshooting/`의 장애 문서(TS-001~008)를 한눈에 볼 수 있게 묶은 **요약본**이다. 챗봇이 검색하는 원본은 개별 문서이며, 이 사례집은 보고서·발표용이다. (`knowledge-base/`에 넣으면 같은 내용이 중복 적재되므로 `docs/`에 둔다.)

## 1. 사례 요약표

| ID | 증상 | 가장 먼저 볼 것 | 대표 조치 |
|---|---|---|---|
| TS-001 | Webhook 호출 시 404, 다음 노드 미실행 | 워크플로우 게시(Active) 여부, Production URL 사용 여부 | 게시하고 POST로 호출, Test URL 대신 Production URL 사용 |
| TS-002 | n8n 컨테이너가 계속 재시작 | `docker compose logs n8n --tail 100` | `.env` 값, DB 접속, `N8N_ENCRYPTION_KEY` 원복 |
| TS-003 | 포트가 이미 사용 중(5678 등) | `netstat`/`lsof`로 포트 사용 프로세스 | 충돌 프로그램 종료 또는 외부 포트 변경 |
| TS-004 | n8n에서 Qdrant·Ollama 연결 실패(ECONNREFUSED) | 자격증명 주소가 `localhost`인지 | 서비스명 주소(`http://qdrant:6333`, `http://ollama:11434`)로 수정 |
| TS-005 | Ollama 모델 없음, 첫 응답 느림 | `ollama list`, 모델 이름·태그 | 모델 반입/내려받기, 적재와 같은 임베딩 모델 사용, 사전 워밍업 |
| TS-006 | 적재 시 `NO_DOCUMENTS`, 검색 결과 없음 | `knowledge-base/`에 `.md`·`.txt` 존재 여부 | 올바른 폴더에 저장 후 `ingest-documents` 재실행 |
| TS-007 | 화면에서 "요청 실패", CORS 오류 | 브라우저 콘솔·Network, curl 직접 호출 | Allowed Origins 설정, Nginx 경유(`/api/...`) 호출, 워크플로우 등록·게시 |
| TS-008 | `localhost:5500` 연결 거부, `localhost:8080` 403 | 임시 서버 실행 여부, `/healthz`, `frontend/public/index.html` | 임시 서버 실행, `index.html` 배치 |

## 2. 빠른 진단 순서

1. `docker compose ps`로 5개 서비스가 Up인지 확인한다. (아니면 TS-002, TS-003)
2. `http://localhost:8080/healthz`가 `ok`인지 확인한다. (아니면 TS-008)
3. n8n 편집기(`http://localhost:5678`)가 열리고 워크플로우가 게시되어 있는지 확인한다. (아니면 TS-001)
4. 워크플로우에서 Qdrant·Ollama 연결이 되는지 확인한다. (아니면 TS-004, TS-005)
5. 문서가 적재되어 있는지 확인한다. (아니면 TS-006)
6. 브라우저에서만 실패하면 콘솔 오류를 확인한다. (TS-007)

`scripts\health-check.ps1`을 먼저 실행하면 1~5번을 한 번에 점검할 수 있다(OP-006).

## 3. 사례별 상세 형식

각 개별 문서(TS-001~008)는 다음 항목으로 구성되어 있다: 장애 ID, 증상, 영향 범위, 가능한 원인, 우선 점검 순서, 조치 방법, 성공 확인 방법, 예방 방법, 관련 문서.

## 4. 예방 체크리스트

- [ ] 워크플로우를 수정한 뒤 게시 상태와 JSON export를 확인했다.
- [ ] `N8N_ENCRYPTION_KEY`를 변경하지 않고 별도로 보관했다.
- [ ] `.env`를 커밋하지 않았다.
- [ ] 문서를 추가·수정한 뒤 재적재했다.
- [ ] 적재와 검색에 같은 임베딩 모델(`bge-m3:latest`)을 사용했다.
- [ ] 시연 전에 모델을 한 번 미리 호출해 두었다.
- [ ] 포트 충돌 가능성이 있는 로컬 프로그램을 종료했다.

## 5. 한계

- 이 사례집은 등록된 8개 사례의 범위 안에서 점검 절차를 안내하며, 모든 오류를 해결하지는 않는다.
- 일부 오류 문구와 명령어는 팀 환경에서 직접 재현해 확인하는 과정이 필요하다(문서 목록의 "재현 검증 필요" 항목).
- 로컬 LLM(qwen2.5:3b)의 한계와 문서 최신성에 따라 답변 품질이 달라질 수 있다.
