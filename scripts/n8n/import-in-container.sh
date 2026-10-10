#!/bin/sh
# n8n 컨테이너 안에서 실행된다. 직접 실행하지 말고 scripts/import-workflows.sh / .ps1 을 사용한다.
#
# 1) Qdrant·Ollama 자격증명 import
# 2) /data/workflows/*.json 중 "n8n Workflow JSON" 인 파일만 골라 import
#    (브라우저에서 저장한 HTML 등 잘못된 파일이 하나 섞여도 전체 import 가 실패하지 않도록 건너뛴다)
# 3) import 한 Workflow 를 publish
set -e

SRC=/data/workflows
TMP=/tmp/wf-import
rm -rf "$TMP"
mkdir -p "$TMP"

n8n import:credentials --input="$SRC/credentials/local-services.json"

ids=""
skipped=0
for f in "$SRC"/*.json; do
  name=$(basename "$f")
  # 유효하면 최상위 id 를 출력, 아니면 종료 코드 1
  if id=$(node -e '
      const fs = require("fs");
      try {
        const w = JSON.parse(fs.readFileSync(process.argv[1], "utf8").replace(/^﻿/, ""));
        if (!Array.isArray(w.nodes) || typeof w.connections !== "object") process.exit(1);
        process.stdout.write(w.id || "");
      } catch (e) { process.exit(1); }
    ' "$f"); then
    cp "$f" "$TMP/"
    if [ -n "$id" ]; then
      ids="$ids $id"
    else
      echo "    [경고] $name : 최상위 id 가 없어 publish 하지 않습니다."
    fi
  else
    echo "    [건너뜀] $name : n8n Workflow JSON 이 아닙니다."
    echo "             n8n 편집기에서 Workflow 를 열고 우측 상단 ... > Download 로 다시 저장하세요."
    skipped=$((skipped + 1))
  fi
done

n8n import:workflow --separate --input="$TMP"

for id in $ids; do
  echo "    publish: $id"
  n8n publish:workflow --id="$id" >/dev/null
done

rm -rf "$TMP"
[ "$skipped" -eq 0 ] || echo "    [주의] 건너뛴 파일 ${skipped}개 - 위 안내를 확인하세요."
