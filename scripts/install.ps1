# [폐쇄망 PC에서 실행] 설치 및 기동 (install.sh 와 동일)
# 사용법: scripts\install.bat 더블클릭
#     또는 powershell -ExecutionPolicy Bypass -File scripts\install.ps1
. "$PSScriptRoot\common.ps1"

$tar = Join-Path $RepoRoot 'offline-assets\docker-images\offline-rag-images.tar'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker 가 설치되어 있지 않습니다.' }
& docker info *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker 데몬이 실행 중이 아닙니다. Docker Desktop 을 먼저 실행하세요.' }

Write-Host '==> [1/5] .env 준비'
$envFile = Join-Path $RepoRoot '.env'
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $RepoRoot '.env.example') $envFile
    Write-Host '    .env.example -> .env 복사'
}
$content = [System.IO.File]::ReadAllText($envFile)
foreach ($key in 'N8N_ENCRYPTION_KEY', 'POSTGRES_PASSWORD') {
    if ($content -match "(?m)^$key=CHANGE_ME\r?$") {
        $bytes = New-Object byte[] 24
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $secret = -join ($bytes | ForEach-Object { $_.ToString('x2') })
        $content = $content -replace "(?m)^$key=CHANGE_ME(\r?)$", "$key=$secret`$1"
        Write-Host "    $key 자동 생성"
    }
}
# BOM 없는 UTF-8 로 저장 (docker compose 가 BOM 을 변수명으로 인식하는 문제 방지)
[System.IO.File]::WriteAllText($envFile, $content, (New-Object System.Text.UTF8Encoding $false))
$cfg = Read-DotEnv

Write-Host '==> [2/5] Docker 이미지 로드'
$offline = Test-Path $tar
if ($offline) { Invoke-Native docker @('load', '-i', $tar) }
else { Write-Host "    $tar 없음 -> 로컬에 이미 있는 이미지를 사용합니다 (온라인 개발 환경)." }

Write-Host '==> [3/5] Ollama 모델 확인 (offline-assets\model-files)'
if (-not (Test-Path (Join-Path $RepoRoot 'offline-assets\model-files\manifests'))) {
    Write-Host '    [경고] 모델 파일이 없습니다. 인터넷 PC에서 scripts\prepare-offline.ps1 을 먼저 실행해 반입하세요.' -ForegroundColor Yellow
}

Write-Host '==> [4/5] 서비스 기동'
if ($offline) { Invoke-Native docker @('compose', 'up', '-d', '--pull', 'never', '--no-build') }
else { Invoke-Native docker @('compose', 'up', '-d') }
Write-Host '    n8n 준비 대기...'
if (-not (Wait-Healthy 'offline-rag-n8n' 300)) { throw 'n8n 이 healthy 상태가 되지 않았습니다. docker compose logs n8n 을 확인하세요.' }

Write-Host '==> [5/5] Workflow import'
& "$PSScriptRoot\import-workflows.ps1"

Write-Host ''
& "$PSScriptRoot\health-check.ps1"
Write-Host ''
Write-Host '설치 완료'
Write-Host "  챗봇 화면 : http://localhost:$(Get-EnvValue $cfg 'FRONTEND_PORT' '8080')"
Write-Host "  n8n 편집기: http://localhost:$(Get-EnvValue $cfg 'N8N_PORT' '5678')  (최초 접속 시 관리자 계정 생성)"
Write-Host '  문서 적재 : powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1'
