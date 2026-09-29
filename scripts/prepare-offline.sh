#!/usr/bin/env bash
# [인터넷 연결 PC에서 실행] 폐쇄망 반입 패키지 준비
#   1) 고정 버전 Docker 이미지 pull + frontend 이미지 build
#   2) Ollama 모델을 offline-assets/model-files 에 다운로드
#   3) 이미지를 offline-assets/docker-images/offline-rag-images.tar 로 저장
# 완료 후 저장소 폴더 전체(offline-assets 포함)를 USB 등으로 폐쇄망 PC에 복사한다.
#
# 사용법: bash scripts/prepare-offline.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Windows Git Bash 경로 변환 방지

cd "$(dirname "$0")/.."
[ -f .env ] || cp .env.example .env
set -a; . ./.env; set +a

IMAGES=(
  "n8nio/n8n:${N8N_VERSION}"
  "postgres:${POSTGRES_VERSION}"
  "qdrant/qdrant:${QDRANT_VERSION}"
  "ollama/ollama:${OLLAMA_VERSION}"
  "offline-rag-frontend:${FRONTEND_VERSION}"
)
TAR=offline-assets/docker-images/offline-rag-images.tar

echo "==> [1/3] Docker 이미지 준비"
for img in "${IMAGES[@]}"; do
  [[ $img == offline-rag-frontend:* ]] && continue
  docker pull "$img"
done
docker compose build frontend

echo "==> [2/3] Ollama 모델 다운로드: ${OLLAMA_EMBED_MODEL}, ${OLLAMA_CHAT_MODEL}"
docker compose up -d ollama
until docker compose exec -T ollama ollama list >/dev/null 2>&1; do sleep 2; done
docker compose exec -T ollama ollama pull "${OLLAMA_EMBED_MODEL}"
docker compose exec -T ollama ollama pull "${OLLAMA_CHAT_MODEL}"
docker compose exec -T ollama ollama list
docker compose stop ollama

echo "==> [3/3] 이미지 저장 → ${TAR}"
docker save -o "$TAR" "${IMAGES[@]}"

echo
echo "완료. 반입 대상:"
du -sh "$TAR" offline-assets/model-files 2>/dev/null || true
echo "폐쇄망 PC에서: bash scripts/install.sh"
