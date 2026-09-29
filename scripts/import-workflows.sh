#!/usr/bin/env bash
# workflows/*.json 을 n8n(PostgreSQL)에 import 하고, Webhook 이 동작하도록 publish 한다.
# 같은 id 로 다시 import 하면 덮어쓰므로, Workflow JSON 을 수정한 뒤 재실행해도 된다.
#
# 사용법: bash scripts/import-workflows.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."

# Qdrant·Ollama 접속 정보(비밀값 없음). 02 질의응답 Workflow 의 Qdrant/Ollama 노드가 이 id 를 참조한다.
docker compose exec -T n8n n8n import:credentials --input=/data/workflows/credentials/local-services.json
docker compose exec -T n8n n8n import:workflow --separate --input=/data/workflows

for f in workflows/*.json; do
  id=$(sed -n 's/^  "id": "\([^"]*\)".*/\1/p' "$f" | tail -n 1)
  [ -n "$id" ] || { echo "    [건너뜀] $f : 최상위 id 없음"; continue; }
  echo "    publish: $f ($id)"
  docker compose exec -T n8n n8n publish:workflow --id="$id" >/dev/null
done

# CLI 로 바꾼 publish 상태는 실행 중인 n8n 에 반영되지 않으므로 재시작한다.
echo "    n8n 재시작 (Webhook 등록)"
docker compose restart n8n >/dev/null
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' offline-rag-n8n 2>/dev/null)" = healthy ] && break
  sleep 3
done
echo "    완료"
