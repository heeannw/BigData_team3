#!/usr/bin/env bash
# [폐쇄망 PC에서 실행] 설치 및 기동
#   1) .env 생성 (비밀값 자동 생성)
#   2) offline-assets 의 이미지 .tar 를 docker load
#   3) 전체 서비스 기동 → Workflow import/publish → 헬스체크
#
# 사용법: bash scripts/install.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."
TAR=offline-assets/docker-images/offline-rag-images.tar

command -v docker >/dev/null || { echo "Docker 가 설치되어 있지 않습니다."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker 데몬이 실행 중이 아닙니다. Docker Desktop 을 먼저 실행하세요."; exit 1; }

echo "==> [1/5] .env 준비"
if [ ! -f .env ]; then
  cp .env.example .env
  echo "    .env.example → .env 복사"
fi
gen_secret() { od -An -tx1 -N24 /dev/urandom | tr -d ' \n'; }
for key in N8N_ENCRYPTION_KEY POSTGRES_PASSWORD; do
  if grep -q "^${key}=CHANGE_ME$" .env; then
    sed -i.bak "s/^${key}=CHANGE_ME$/${key}=$(gen_secret)/" .env && rm -f .env.bak
    echo "    ${key} 자동 생성"
  fi
done
set -a; . ./.env; set +a

echo "==> [2/5] Docker 이미지 로드"
if [ -f "$TAR" ]; then
  docker load -i "$TAR"
else
  echo "    $TAR 없음 → 로컬에 이미 있는 이미지를 사용합니다 (온라인 개발 환경)."
fi

echo "==> [3/5] Ollama 모델 확인 (offline-assets/model-files)"
if [ ! -d offline-assets/model-files/manifests ]; then
  echo "    [경고] 모델 파일이 없습니다. 인터넷 PC에서 scripts/prepare-offline.sh 를 먼저 실행해 반입하세요."
fi

echo "==> [4/5] 서비스 기동"
# 폐쇄망에서 pull 을 시도하지 않도록 never 정책 사용 (이미지가 없으면 즉시 실패)
if [ -f "$TAR" ]; then
  docker compose up -d --pull never --no-build
else
  docker compose up -d
fi

echo "    n8n 준비 대기..."
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' offline-rag-n8n 2>/dev/null)" = healthy ] && break
  sleep 5
done

echo "==> [5/5] Workflow import"
bash scripts/import-workflows.sh

echo
bash scripts/health-check.sh || true
cat <<EOF

설치 완료
  챗봇 화면 : http://localhost:${FRONTEND_PORT:-8080}
  n8n 편집기: http://localhost:${N8N_PORT:-5678}  (최초 접속 시 관리자 계정 생성)
  문서 적재 : bash scripts/ingest-documents.sh
EOF
