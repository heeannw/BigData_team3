# workflows/*.json 과 자격증명을 n8n 에 import 하고 publish 한다. (import-workflows.sh 와 동일)
# 사용법: powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
. "$PSScriptRoot\common.ps1"

Invoke-Native docker @('compose', 'exec', '-T', 'n8n', 'n8n', 'import:credentials', '--input=/data/workflows/credentials/local-services.json')
Invoke-Native docker @('compose', 'exec', '-T', 'n8n', 'n8n', 'import:workflow', '--separate', '--input=/data/workflows')

foreach ($f in Get-ChildItem (Join-Path $RepoRoot 'workflows') -Filter *.json) {
    $wf = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $wf.id) { Write-Host "    [건너뜀] $($f.Name) : 최상위 id 없음"; continue }
    Write-Host "    publish: $($f.Name) ($($wf.id))"
    Invoke-Native docker @('compose', 'exec', '-T', 'n8n', 'n8n', 'publish:workflow', "--id=$($wf.id)") | Out-Null
}

# CLI 로 바꾼 publish 상태는 실행 중인 n8n 에 반영되지 않으므로 재시작한다.
Write-Host '    n8n 재시작 (Webhook 등록)'
Invoke-Native docker @('compose', 'restart', 'n8n') | Out-Null
if (-not (Wait-Healthy 'offline-rag-n8n' 180)) { throw 'n8n 이 healthy 상태가 되지 않았습니다. docker compose logs n8n 을 확인하세요.' }
Write-Host '    완료'
