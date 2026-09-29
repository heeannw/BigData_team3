#!/usr/bin/env bash
# 전체 서비스 상태 점검. 하나라도 실패하면 종료 코드 1.
#
# 사용법: bash scripts/health-check.sh
set -uo pipefail
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."
[ -f .env ] && { set -a; . ./.env; set +a; }
COLLECTION=${QDRANT_COLLECTION:-knowledge_base}
fail=0

check() {  # check <이름> <명령...>
  local name=$1; shift
  if out=$("$@" 2>&1); then
    printf '  [OK]   %-28s %s\n' "$name" "${out:0:80}"
  else
    printf '  [FAIL] %-28s %s\n' "$name" "${out:0:120}"
    fail=1
  fi
}

echo "== 컨테이너 상태"
docker compose ps --format 'table {{.Service}}\t{{.Status}}'
echo
echo "== 서비스 점검"
check "postgres"            docker compose exec -T postgres pg_isready -q -U "${POSTGRES_USER:-n8n}"
check "qdrant /readyz"      curl -sf "http://localhost:${QDRANT_PORT:-6333}/readyz"
check "ollama /api/version" curl -sf "http://localhost:${OLLAMA_PORT:-11434}/api/version"
check "n8n /healthz/readiness" curl -sf "http://localhost:${N8N_PORT:-5678}/healthz/readiness"
check "frontend /healthz"   curl -sf "http://localhost:${FRONTEND_PORT:-8080}/healthz"
check "nginx /api → n8n"     curl -sf -X POST "http://localhost:${FRONTEND_PORT:-8080}/api/mock-chat" \
                              -H 'Content-Type: application/json' -d '{"question":"health","requestType":"operation"}'

echo
echo "== 모델 (필요: ${OLLAMA_EMBED_MODEL:-bge-m3}, ${OLLAMA_CHAT_MODEL:-qwen2.5:3b})"
models=$(docker compose exec -T ollama ollama list 2>/dev/null)
for m in "${OLLAMA_EMBED_MODEL:-bge-m3}" "${OLLAMA_CHAT_MODEL:-qwen2.5:3b}"; do
  check "model $m" grep -m1 "^${m}" <<<"$models"
done

echo
echo "== Qdrant 컬렉션 '${COLLECTION}'"
check "points_count" sh -c "curl -sf http://localhost:${QDRANT_PORT:-6333}/collections/${COLLECTION} | grep -o '\"points_count\":[0-9]*'"

echo
[ $fail -eq 0 ] && echo "결과: 정상" || echo "결과: 실패 항목이 있습니다"
exit $fail
