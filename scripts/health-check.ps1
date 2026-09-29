# 전체 서비스 상태 점검. 하나라도 실패하면 종료 코드 1. (health-check.sh 와 동일)
# 사용법: powershell -ExecutionPolicy Bypass -File scripts\health-check.ps1
. "$PSScriptRoot\common.ps1"
$ErrorActionPreference = 'Continue'

$cfg = Read-DotEnv
$p = @{
    frontend = Get-EnvValue $cfg 'FRONTEND_PORT' '8080'
    n8n      = Get-EnvValue $cfg 'N8N_PORT' '5678'
    qdrant   = Get-EnvValue $cfg 'QDRANT_PORT' '6333'
    ollama   = Get-EnvValue $cfg 'OLLAMA_PORT' '11434'
}
$collection = Get-EnvValue $cfg 'QDRANT_COLLECTION' 'knowledge_base'
$script:fail = $false

function Report($name, $ok, $detail) {
    $detail = "$detail" -replace '\s+', ' '
    if ($detail.Length -gt 80) { $detail = $detail.Substring(0, 80) }
    if ($ok) { Write-Host ("  [OK]   {0,-24} {1}" -f $name, $detail) -ForegroundColor Green }
    else { Write-Host ("  [FAIL] {0,-24} {1}" -f $name, $detail) -ForegroundColor Red; $script:fail = $true }
}

Write-Host '== 컨테이너 상태'
& docker compose ps --format 'table {{.Service}}\t{{.Status}}'
Write-Host ''
Write-Host '== 서비스 점검'
$user = Get-EnvValue $cfg 'POSTGRES_USER' 'n8n'
& docker compose exec -T postgres pg_isready -q -U $user 2>$null | Out-Null
Report 'postgres' ($LASTEXITCODE -eq 0) ''
$r = Test-Http "http://localhost:$($p.qdrant)/readyz";          Report 'qdrant /readyz' $r.Ok $r.Body
$r = Test-Http "http://localhost:$($p.ollama)/api/version";     Report 'ollama /api/version' $r.Ok $r.Body
$r = Test-Http "http://localhost:$($p.n8n)/healthz/readiness";  Report 'n8n /healthz/readiness' $r.Ok $r.Body
$r = Test-Http "http://localhost:$($p.frontend)/healthz";       Report 'frontend /healthz' $r.Ok $r.Body
$r = Test-Http "http://localhost:$($p.frontend)/api/mock-chat" 'POST' '{"question":"health","requestType":"operation"}'
Report 'nginx /api -> n8n' $r.Ok $r.Body

Write-Host ''
$embed = Get-EnvValue $cfg 'OLLAMA_EMBED_MODEL' 'bge-m3'
$chat = Get-EnvValue $cfg 'OLLAMA_CHAT_MODEL' 'qwen2.5:3b'
Write-Host "== 모델 (필요: $embed, $chat)"
$models = (& docker compose exec -T ollama ollama list 2>$null) -join "`n"
foreach ($m in @($embed, $chat)) {
    $line = ($models -split "`n" | Where-Object { $_ -match "^$([regex]::Escape($m))[: ]" } | Select-Object -First 1)
    Report "model $m" ([bool]$line) $line
}

Write-Host ''
Write-Host "== Qdrant 컬렉션 '$collection'"
$r = Test-Http "http://localhost:$($p.qdrant)/collections/$collection"
$count = if ($r.Ok -and $r.Body -match '"points_count":(\d+)') { $Matches[1] } else { $null }
Report 'points_count' ([bool]$count) $(if ($count) { $count } else { '컬렉션 없음 - scripts\ingest-documents.ps1 실행 필요' })

Write-Host ''
if ($script:fail) { Write-Host '결과: 실패 항목이 있습니다' -ForegroundColor Red; exit 1 }
Write-Host '결과: 정상' -ForegroundColor Green
exit 0
