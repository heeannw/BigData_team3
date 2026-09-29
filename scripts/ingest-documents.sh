#!/usr/bin/env bash
# knowledge-base/ 문서를 청크 분할·임베딩하여 Qdrant 에 (전체) 재적재한다.
# 01 문서 적재 Workflow 의 Webhook 을 호출하며, 결과 요약 JSON 을 출력한다.
# 실패하면 원인을 출력하고 종료 코드 1 을 반환한다.
#
# 사용법: bash scripts/ingest-documents.sh
set -uo pipefail
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."
[ -f .env ] && { set -a; . ./.env; set +a; }
EMBED_MODEL=${OLLAMA_EMBED_MODEL:-bge-m3}
URL="http://localhost:${N8N_PORT:-5678}/webhook/ingest-documents"

die() { echo "[실패] $*" >&2; exit 1; }

# --- 사전 점검: 실패 원인을 워크플로 실행 전에 명확히 알려준다 ---
curl -sf "http://localhost:${N8N_PORT:-5678}/healthz" >/dev/null \
  || die "n8n 에 연결할 수 없습니다. 'docker compose up -d' 또는 'bash scripts/install.sh' 를 먼저 실행하세요."
curl -sf "http://localhost:${QDRANT_PORT:-6333}/readyz" >/dev/null \
  || die "Qdrant 가 준비되지 않았습니다. 'docker compose ps' 로 qdrant 상태를 확인하세요."
docker compose exec -T ollama ollama list 2>/dev/null | grep -q "^${EMBED_MODEL}[: ]" \
  || die "임베딩 모델 '${EMBED_MODEL}' 이 Ollama 에 없습니다. offline-assets/model-files 반입 여부를 확인하세요. (인터넷 PC: bash scripts/prepare-offline.sh)"

echo "POST $URL"
echo "(CPU 환경에서는 문서 양에 따라 수 분 걸릴 수 있습니다)"
body=$(curl -sS --max-time 1800 -X POST "$URL" -H 'Content-Type: application/json' -d '{}' -w $'\n%{http_code}')
code=${body##*$'\n'}
body=${body%$'\n'*}
echo "$body"

case "$code" in
  200) ;;
  404) die "Webhook 이 등록되지 않았습니다. 'bash scripts/import-workflows.sh' 를 실행하세요." ;;
  *)   die "HTTP $code — n8n 편집기(Executions)에서 '01 - 문서 적재' 실행 로그를 확인하세요." ;;
esac
grep -q '"success":true' <<<"$body" || die "적재가 완료되지 않았습니다. 위 message 를 확인하세요."
echo "[완료] 적재 성공"
