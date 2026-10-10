#!/usr/bin/env bash
# workflows/*.json 과 자격증명을 n8n(PostgreSQL)에 import 하고, Webhook 이 동작하도록 publish 한다.
# 같은 id 로 다시 import 하면 덮어쓰므로, Workflow JSON 을 수정한 뒤 재실행해도 된다.
# n8n Workflow JSON 이 아닌 파일(예: 브라우저에서 저장한 HTML)은 경고 후 건너뛴다.
#
# 사용법: bash scripts/import-workflows.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."

docker compose cp scripts/n8n/import-in-container.sh n8n:/tmp/import-in-container.sh
docker compose exec -T n8n sh /tmp/import-in-container.sh

# CLI 로 바꾼 publish 상태는 실행 중인 n8n 에 반영되지 않으므로 재시작한다.
echo "    n8n 재시작 (Webhook 등록)"
docker compose restart n8n >/dev/null
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' offline-rag-n8n 2>/dev/null)" = healthy ] && break
  sleep 3
done
# 재시작 직후 몇 초 동안은 Webhook 이 이전 버전 Workflow 로 실행된다 (n8n 2.41 실측: 4초 후 이전 버전, 12초 후 새 버전).
echo "    새 버전 Workflow 반영 대기 (15초)"
sleep 15
echo "    완료"
