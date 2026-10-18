# 실제 RAG 1차 평가 기준

## 범위
- 입력: tests/test_questions_draft.csv의 Q01~Q12
- Q01~Q06: diagnosis
- Q07~Q10: operation
- Q11~Q12: 근거 부족에 따른 답변 보류
- Mock 평가 기록과 구분한다.

## 실행 조건
- n8n 2.41.3
- bge-m3 / qwen2.5:3b
- Docker Ollama, CPU 실행
- 실제 모델 컨텍스트: 4096
- 문서 21개 / 청크 49개
- 한 번에 한 사례씩 순차 실행한다.
- 클라이언트 대기 제한: 1800초
- 600초 이내 응답 여부는 별도로 기록한다.
- 실행 중 모델·프롬프트·검색 설정을 바꾸지 않는다.

## 자동 검사
- HTTP 200, 파싱 가능한 JSON, success=true
- 요청과 응답 requestType 일치
- 비어 있지 않은 answer 및 sources 배열
- operation: diagnosis=null
- diagnosis: summary 문자열과 possibleCauses/checkSteps/actions 배열
- expected_hold=false: 보류하지 않고 기대 출처 중 하나 이상 포함
- expected_hold=true: 지정 보류 문구와 sources=[]
- expected_source의 |는 허용 출처 중 하나 이상을 의미한다.
- 키워드는 answer와 diagnosis의 문자열 내용을 함께 검사한다.
- 키워드 일치는 보조 결과이며 최종 정확성 판정과 구분한다.

## 사람 검토
- 핵심 답변의 원문 근거 일치
- 질문 및 로그에 대한 진단 적합성
- 근거 없는 주장 및 위험한 조치 여부
- 여러 문서 종합이 필요한 사례의 충분성

## 시간 및 캐시
- clientElapsedMs: 클라이언트 실측 시간
- responseTimeMs: 서버가 반환한 시간
- cached: 캐시 HIT 여부
- 캐시 응답을 신규 검색·생성 응답시간에 포함하지 않는다.
- sessionId 변경만으로 캐시를 우회할 수 없다.
- 캐시된 결과는 기능 검증에 사용할 수 있으나 신규 추론과 구분한다.
- 타임아웃 후 같은 요청을 즉시 재실행하지 않는다.
- 자동 재시도는 하지 않는다.

## 판정
- 자동 검사 결과와 사람 검토 결과를 분리한다.
- 자동 검사 PASS만으로 전체 답변 정확성 PASS를 확정하지 않는다.
- TIMEOUT, HTTP_ERROR, INVALID_JSON 등 실행 실패를 별도 기록한다.
- 제한시간 내 응답 실패와 이후 서버 처리 완료를 구분한다.
- 검색 10/10 기록을 전체 챗봇 정확도 100%로 표현하지 않는다.

## Q01 사전 확인
- 최초 요청: 600초 타임아웃
- 서버 처리 및 캐시 저장: 확인, responseTimeMs=716826
- 캐시 재호출: HTTP 200, cached=true, clientElapsedMs=155
- diagnosis 구조, 기대 키워드, 기대 출처: 확인
- 원문 근거 충실성: 추가 검토 필요
