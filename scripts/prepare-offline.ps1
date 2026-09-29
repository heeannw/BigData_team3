# [인터넷 연결 PC에서 실행] 폐쇄망 반입 패키지 준비 (prepare-offline.sh 와 동일)
# 사용법: powershell -ExecutionPolicy Bypass -File scripts\prepare-offline.ps1
. "$PSScriptRoot\common.ps1"

if (-not (Test-Path (Join-Path $RepoRoot '.env'))) { Copy-Item (Join-Path $RepoRoot '.env.example') (Join-Path $RepoRoot '.env') }
$cfg = Read-DotEnv
$images = @(
    "n8nio/n8n:$(Get-EnvValue $cfg 'N8N_VERSION' '2.41.3')",
    "postgres:$(Get-EnvValue $cfg 'POSTGRES_VERSION' '17-alpine')",
    "qdrant/qdrant:$(Get-EnvValue $cfg 'QDRANT_VERSION' 'v1.19.1')",
    "ollama/ollama:$(Get-EnvValue $cfg 'OLLAMA_VERSION' '0.35.0')"
)
$frontendImage = "offline-rag-frontend:$(Get-EnvValue $cfg 'FRONTEND_VERSION' 'local')"
$embed = Get-EnvValue $cfg 'OLLAMA_EMBED_MODEL' 'bge-m3'
$chat = Get-EnvValue $cfg 'OLLAMA_CHAT_MODEL' 'qwen2.5:3b'
$tar = Join-Path $RepoRoot 'offline-assets\docker-images\offline-rag-images.tar'

Write-Host '==> [1/3] Docker 이미지 준비'
foreach ($img in $images) { Invoke-Native docker @('pull', $img) }
Invoke-Native docker @('compose', 'build', 'frontend')

Write-Host "==> [2/3] Ollama 모델 다운로드: $embed, $chat"
Invoke-Native docker @('compose', 'up', '-d', 'ollama')
if (-not (Wait-Healthy 'offline-rag-ollama' 120)) { throw 'ollama 컨테이너가 준비되지 않았습니다.' }
Invoke-Native docker @('compose', 'exec', '-T', 'ollama', 'ollama', 'pull', $embed)
Invoke-Native docker @('compose', 'exec', '-T', 'ollama', 'ollama', 'pull', $chat)
Invoke-Native docker @('compose', 'exec', '-T', 'ollama', 'ollama', 'list')
Invoke-Native docker @('compose', 'stop', 'ollama')

Write-Host "==> [3/3] 이미지 저장 -> $tar"
Invoke-Native docker (@('save', '-o', $tar) + $images + @($frontendImage))

Write-Host ''
Write-Host ('완료. 이미지 tar: {0:N1} GB' -f ((Get-Item $tar).Length / 1GB))
Write-Host '저장소 폴더 전체(offline-assets 포함)를 폐쇄망 PC로 복사한 뒤 scripts\install.bat 을 실행하세요.'
