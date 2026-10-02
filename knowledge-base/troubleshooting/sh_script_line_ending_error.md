---
title: Windows에서 .sh 스크립트 실행 시 bash 오류가 날 때(줄바꿈 CRLF 문제)
doc_id: TS-009
category: troubleshooting
version: 1.0
created: 2026-10-02
keywords: [sh 스크립트, bash 오류, CRLF, LF, 줄바꿈, git bash, gitattributes, 스크립트 실행 안 됨]
---
# TS-009 Windows에서 .sh 스크립트 실행 시 bash 오류가 날 때

## 증상
- Git Bash나 WSL에서 `bash scripts/install.sh` 같은 `.sh` 스크립트를 실행하면 오류가 난다.
- `$'\r': command not found` 또는 문법 오류(syntax error)가 반복해서 출력된다.
- 같은 이름의 `.ps1` 스크립트는 정상 실행된다.

## 영향 범위
- Windows에서 `.sh` 스크립트(`install.sh`, `ingest-documents.sh`, `health-check.sh` 등)를 사용하는 팀원.

## 가능한 원인
1. `.sh` 파일의 줄바꿈이 Windows 방식(CRLF)으로 바뀌었다. bash는 줄바꿈이 LF여야 정상 실행된다.
2. 메모장 등 편집기에서 `.sh` 파일을 열어 저장하면서 CRLF로 바뀌었다.
3. Git의 줄바꿈 자동 변환 설정 때문에 내려받을 때 CRLF로 바뀌었다.

## 우선 점검 순서
1. 오류 메시지에 `\r`이 포함되어 있는지 확인한다.
2. VS Code로 해당 `.sh` 파일을 열고 오른쪽 아래의 줄바꿈 표시가 `CRLF`인지 `LF`인지 확인한다.
3. Windows라면 `.sh` 대신 `.ps1` 또는 `install.bat`을 사용할 수 있는지 확인한다.

## 조치 방법
1. Windows에서는 `.ps1` 스크립트와 `scripts\install.bat`을 사용한다. 모든 스크립트가 bash와 PowerShell 두 가지로 제공된다.
2. `.sh`를 꼭 써야 하면 VS Code에서 오른쪽 아래의 `CRLF`를 눌러 `LF`로 바꾸고 저장한다.
3. 저장소 최신 `main`을 다시 받는다. 저장소의 `.gitattributes`가 `.sh`는 LF, `.ps1`·`.bat`는 CRLF로 고정한다.

## 성공 확인 방법
- `bash scripts/health-check.sh`가 `\r` 오류 없이 실행된다.

## 예방 방법
- `.sh` 파일을 메모장으로 열어 저장하지 않는다.
- `.gitattributes`를 삭제하거나 수정하지 않는다.

## 관련 문서
- OP-001 폐쇄망 설치 절차
- OP-006 서비스 상태 확인 방법
