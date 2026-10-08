---
title: n8n 컨테이너가 계속 재시작되거나 기동에 실패할 때
doc_id: TS-002
category: troubleshooting
version: 1.0
created: 2026-09-30
keywords: [컨테이너, 재시작 반복, restarting, docker compose, 로그, encryption key, postgres]
---
# TS-002 n8n 컨테이너가 계속 재시작되거나 기동에 실패할 때

## 증상
- `docker compose ps`에서 n8n 상태가 Restarting으로 반복된다.
- http://localhost:5678에 접속할 수 없다.
- 기동 직후 컨테이너가 종료된다.

## 영향 범위
- n8n 편집기, 모든 Webhook, 이를 사용하는 챗봇 전체.

## 가능한 원인
1. PostgreSQL이 아직 준비되지 않았거나 접속 정보가 맞지 않는다.
2. `.env` 값이 누락되었거나 오타가 있다.
3. `N8N_ENCRYPTION_KEY`가 기존 데이터(볼륨)에 저장된 값과 다르다.
4. 포트 충돌(TS-003 참조) 또는 메모리 부족.

## 우선 점검 순서
1. 상태 확인
   ```bash
   docker compose ps
   ```
2. n8n 로그 확인
   ```bash
   docker compose logs n8n --tail 100
   ```
3. PostgreSQL 로그 확인
   ```bash
   docker compose logs postgres --tail 50
   ```
4. `.env` 파일에 필수 값이 채워져 있는지, 비밀번호·키가 이전과 같은지 확인한다.

## 조치 방법
1. 로그에 DB 접속 오류가 있으면 PostgreSQL이 Healthy가 된 뒤 n8n을 다시 기동한다.
   ```bash
   docker compose up -d
   ```
2. `.env` 값을 수정한 뒤 컨테이너를 다시 기동한다.
3. 암호화 키 불일치 오류가 나오면 `N8N_ENCRYPTION_KEY`를 기존에 사용하던 값으로 되돌린다. 키를 바꾸면 저장된 자격증명을 복호화할 수 없다.
4. 메모리 부족이 의심되면 Docker Desktop의 리소스 할당을 늘린다.

## 성공 확인 방법
- `docker compose ps`에서 n8n이 Up(또는 Healthy) 상태로 유지된다.
- n8n 편집기 접속이 가능하다.

## 예방 방법
- `N8N_ENCRYPTION_KEY`는 설치 후 변경하지 않고 별도로 안전하게 보관한다.
- `.env`는 Git에 커밋하지 않고 `.env.example`로만 예시를 공유한다.
- 데이터 초기화(`docker compose down -v`)는 DB·벡터 데이터가 삭제되므로 신중히 사용한다.

## 관련 문서
- TS-003 포트 충돌
- TS-001 Webhook 호출 실패
