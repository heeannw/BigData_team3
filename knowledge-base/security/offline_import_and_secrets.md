---
title: 폐쇄망 반입 파일 관리와 비밀정보 취급 원칙
doc_id: SC-001
category: security
version: 1.0
created: 2026-10-01
keywords: [보안, 비밀정보, 반입, .gitignore, .env, offline-assets, 외부 호출, 포트 노출]
---
# SC-001 폐쇄망 반입 파일 관리와 비밀정보 취급 원칙

## 목적
폐쇄망 환경에서 반입 파일과 비밀정보를 안전하게 다루는 기본 원칙을 안내한다.

## 적용 범위
Docker 이미지·모델 반입 파일, `.env`, 로그와 문서 공유.

## 외부 통신 차단 설계
1. 최종 시스템은 외부 인터넷과 클라우드 API 없이 동작한다.
2. 설치 스크립트는 `--pull never`로 이미지를 기동하므로 인터넷에서 받는 이미지가 없다.
3. n8n의 통계 전송, 업데이트 확인, 템플릿 기능은 꺼 두었다.

## 반입 파일 관리
1. 반입 대상은 `offline-assets/docker-images/offline-rag-images.tar`(약 4GB)와 `offline-assets/model-files/`(약 3GB)이다.
2. 두 항목은 `.gitignore` 대상이라 GitHub에 올라가지 않는다. USB 등으로 직접 옮긴다.
3. 이미지나 모델 버전을 바꾸면 인터넷 PC에서 `prepare-offline`을 다시 실행해 패키지를 새로 만든다.

## 비밀정보 취급
1. 비밀번호와 키는 `.env`에만 둔다. `N8N_ENCRYPTION_KEY`와 `POSTGRES_PASSWORD`는 설치 스크립트가 자동 생성한다.
2. `.env`는 커밋하지 않고, 공유 예시는 `.env.example`에 PLACEHOLDER 값으로 작성한다.
3. 실제 API Key, 비밀번호, 토큰, 내부 IP, 개인정보, 회사 기밀은 AI 도구에 입력하지 않는다.
4. 로그를 공유할 때는 민감정보를 마스킹한다.
5. GitHub Desktop에서 "파일이 너무 큽니다" 경고가 뜨면 커밋하지 않고 취소한다. 이미지·모델·`.env`가 섞였다는 뜻이다.

## 포트와 접근 범위
- Qdrant(6333)와 Ollama(11434)는 이 PC(127.0.0.1)에서만 접속할 수 있다.
- PostgreSQL은 외부에 노출하지 않고 Docker 내부 네트워크로만 통신한다.
- n8n 관리자 계정은 각 PC의 로컬 DB에만 있고 팀원끼리 공유되지 않는다.
- 현재 구성에는 사용자 로그인·권한 관리 기능이 없다.

## 확인 방법
- `git status`에 `.env`나 `offline-assets`의 큰 파일이 변경 목록으로 보이지 않는다.
- `docker compose ps`의 포트 표시에서 Qdrant와 Ollama가 `127.0.0.1`로만 열려 있다.

## 관련 문서
- SC-002 암호화 키와 자격증명 관리
- OP-001 폐쇄망 설치 절차
- OP-003 .env 환경변수 설정
