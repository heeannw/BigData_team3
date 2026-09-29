# knowledge-base/ 문서를 Qdrant 에 (전체) 재적재한다. (ingest-documents.sh 와 동일)
# 사용법: powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1
. "$PSScriptRoot\common.ps1"

$cfg = Read-DotEnv
$n8nPort = Get-EnvValue $cfg 'N8N_PORT' '5678'
$qdrantPort = Get-EnvValue $cfg 'QDRANT_PORT' '6333'
$embedModel = Get-EnvValue $cfg 'OLLAMA_EMBED_MODEL' 'bge-m3'

function Fail($msg) { Write-Host "[실패] $msg" -ForegroundColor Red; exit 1 }

# --- 사전 점검 ---
if (-not (Test-Http "http://localhost:$n8nPort/healthz").Ok) { Fail "n8n 에 연결할 수 없습니다. scripts\install.ps1 을 먼저 실행하세요." }
if (-not (Test-Http "http://localhost:$qdrantPort/readyz").Ok) { Fail "Qdrant 가 준비되지 않았습니다. 'docker compose ps' 로 상태를 확인하세요." }
$models = (& docker compose exec -T ollama ollama list 2>$null) -join "`n"
if ($models -notmatch "(?m)^$([regex]::Escape($embedModel))[: ]") {
    Fail "임베딩 모델 '$embedModel' 이 Ollama 에 없습니다. offline-assets\model-files 반입 여부를 확인하세요."
}

$url = "http://localhost:$n8nPort/webhook/ingest-documents"
Write-Host "POST $url"
Write-Host '(CPU 환경에서는 문서 양에 따라 수 분 걸릴 수 있습니다)'
try {
    $r = Invoke-WebRequest -Uri $url -Method POST -Body '{}' -ContentType 'application/json' -UseBasicParsing -TimeoutSec 1800
    # PS 5.1 은 응답 charset 을 잘못 판단할 수 있으므로 바이트에서 UTF-8 로 직접 디코딩한다
    $body = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404) { Fail 'Webhook 이 등록되지 않았습니다. scripts\import-workflows.ps1 을 실행하세요.' }
    Fail "HTTP $code - n8n 편집기(Executions)에서 '01 - 문서 적재' 실행 로그를 확인하세요."
}
Write-Host $body
if ($body -notmatch '"success"\s*:\s*true') { Fail '적재가 완료되지 않았습니다. 위 message 를 확인하세요.' }
Write-Host '[완료] 적재 성공' -ForegroundColor Green
