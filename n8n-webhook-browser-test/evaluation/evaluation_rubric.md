# Mock UI · n8n Webhook 평가 기준

## 평가 범위

현재 단계는 RAG 연결 전 Mock 프로토타입이다.

평가 대상은 다음과 같다.

- 브라우저 Mock UI의 버튼 동작
- `POST /webhook/mock-chat` Production Webhook 호출
- HTTP 200 및 JSON 응답 수신
- 화면에서 응답 결과 표시
- 빈 질문 입력 차단
- 오류 발생 시 사용자에게 오류 메시지 표시

## 테스트 환경

| 항목 | 값 |
|---|---|
| 프로젝트 경로 | `/Users/pyojeongin/Desktop/BigData_team3/n8n-webhook-browser-test` |
| 프론트엔드 | `frontend/public/index.html` |
| UI 주소 | `http://localhost:5500` |
| n8n API | `http://localhost:5678/webhook/mock-chat` |
| 요청 방식 | `POST` |
| 요청 형식 | `application/json` |
| n8n Workflow 상태 | Published/Active |

## 통과 조건

| 평가 항목 | 배점 | 통과 기준 |
|---|---:|---|
| UI → Webhook 연결 | 30점 | 버튼 클릭 후 Production Webhook에 POST 요청이 전달된다 |
| HTTP·JSON 응답 | 25점 | HTTP 200과 파싱 가능한 JSON을 받는다 |
| 응답 화면 표시 | 20점 | 응답 JSON과 answer 내용이 화면에 표시된다 |
| 빈 질문 차단 | 15점 | 빈 입력 시 API 호출 없이 안내 문구를 표시한다 |
| 오류 안내 | 10점 | 네트워크·HTTP·CORS 오류 시 오류 메시지를 표시한다 |
| 합계 | 100점 | 70점 이상이면 1차 통과 |

## 현재 확인 결과

- TC-001 operation 요청: PASS
- 결과: 브라우저에서 `성공: HTTP 200` 확인
- 결과: n8n Production Webhook JSON 응답 확인
- 결과: Mock UI에서 응답 화면 표시 확인

## 현재 한계

현재 Workflow는 RAG 연결 전의 임시 Mock 응답 단계다.

아직 구현·평가하지 않은 항목:

- RAG 문서 검색 정확도
- 답변 근거 문서·출처 표시
- operation과 diagnosis 요청의 실제 n8n 분기
- 장애 로그 분석 및 원인 진단
- 사용자 인증 및 권한 제어
- 세션별 대화 문맥 유지
