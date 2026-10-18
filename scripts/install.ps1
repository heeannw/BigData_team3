# [폐쇄망 PC에서 실행] 설치 및 기동 (install.sh 와 동일)
# 사용법:
#   scripts\install.bat 더블클릭
# 또는:
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1

. "$PSScriptRoot\common.ps1"

$tar = Join-Path `
    $RepoRoot `
    'offline-assets\docker-images\offline-rag-images.tar'

$sqlFile = Join-Path `
    $RepoRoot `
    'scripts\sql\init-rag-cache.sql'


# ============================================================
# Docker 확인
# ============================================================

if (
    -not (
        Get-Command `
            docker `
            -ErrorAction SilentlyContinue
    )
) {
    throw 'Docker 가 설치되어 있지 않습니다.'
}

# Windows PowerShell 5.1에서는 docker info의 WARNING(stderr)을
# NativeCommandError로 처리할 수 있으므로 잠시 Continue로 변경한다.
$previousErrorActionPreference = `
    $ErrorActionPreference

try {
    $ErrorActionPreference = `
        'Continue'

    & docker info *> $null

    $dockerExitCode = `
        $LASTEXITCODE
}
finally {
    $ErrorActionPreference = `
        $previousErrorActionPreference
}

if ($dockerExitCode -ne 0) {
    throw `
        'Docker 데몬이 실행 중이 아닙니다. Docker Desktop 을 먼저 실행하세요.'
}


# ============================================================
# [1/6] .env 준비
# ============================================================

Write-Host '==> [1/6] .env 준비'

$envFile = Join-Path `
    $RepoRoot `
    '.env'

if (
    -not (
        Test-Path $envFile
    )
) {
    Copy-Item `
        (Join-Path $RepoRoot '.env.example') `
        $envFile

    Write-Host `
        '    .env.example -> .env 복사'
}

$content = `
    [System.IO.File]::ReadAllText(
        $envFile
    )

foreach (
    $key in
    'N8N_ENCRYPTION_KEY',
    'POSTGRES_PASSWORD'
) {
    if (
        $content -match
        "(?m)^$key=CHANGE_ME\r?$"
    ) {
        $bytes = `
            New-Object byte[] 24

        $rng = `
            [System.Security.Cryptography.RandomNumberGenerator]::Create()

        try {
            $rng.GetBytes(
                $bytes
            )
        }
        finally {
            $rng.Dispose()
        }

        $secret = `
            -join (
                $bytes |
                ForEach-Object {
                    $_.ToString('x2')
                }
            )

        $content = `
            $content -replace `
            "(?m)^$key=CHANGE_ME(\r?)$", `
            "$key=$secret`$1"

        Write-Host `
            "    $key 자동 생성"
    }
}

# BOM 없는 UTF-8 로 저장
# docker compose 가 BOM 을 변수명으로 인식하는 문제 방지
[System.IO.File]::WriteAllText(
    $envFile,
    $content,
    (
        New-Object `
            System.Text.UTF8Encoding `
            $false
    )
)

$cfg = Read-DotEnv


# ============================================================
# [2/6] Docker 이미지 로드
# ============================================================

Write-Host `
    '==> [2/6] Docker 이미지 로드'

$offline = `
    Test-Path $tar

if ($offline) {
    Invoke-Native `
        docker `
        @(
            'load',
            '-i',
            $tar
        )
}
else {
    Write-Host `
        "    $tar 없음 -> 로컬에 이미 있는 이미지를 사용합니다 (온라인 개발 환경)."
}


# ============================================================
# [3/6] Ollama 모델 확인
# ============================================================

Write-Host `
    '==> [3/6] Ollama 모델 확인 (offline-assets\model-files)'

$modelManifestPath = Join-Path `
    $RepoRoot `
    'offline-assets\model-files\manifests'

if (
    -not (
        Test-Path $modelManifestPath
    )
) {
    Write-Host `
        '    [경고] 모델 파일이 없습니다. 인터넷 PC에서 scripts\prepare-offline.ps1 을 먼저 실행해 반입하세요.' `
        -ForegroundColor Yellow
}


# ============================================================
# [4/6] 서비스 기동
# ============================================================

Write-Host `
    '==> [4/6] 서비스 기동'

if ($offline) {
    Invoke-Native `
        docker `
        @(
            'compose',
            'up',
            '-d',
            '--pull',
            'never',
            '--no-build'
        )
}
else {
    Invoke-Native `
        docker `
        @(
            'compose',
            'up',
            '-d'
        )
}


# ============================================================
# PostgreSQL 준비 대기
# ============================================================

Write-Host `
    '    PostgreSQL 준비 대기...'

if (
    -not (
        Wait-Healthy `
            'offline-rag-postgres' `
            120
    )
) {
    throw `
        'PostgreSQL 이 healthy 상태가 되지 않았습니다. docker compose logs postgres 를 확인하세요.'
}


# ============================================================
# [5/6] PostgreSQL 캐시 테이블 생성
# ============================================================

Write-Host `
    '==> [5/6] PostgreSQL 캐시 테이블 확인'

if (
    -not (
        Test-Path $sqlFile
    )
) {
    throw `
        "SQL 파일을 찾을 수 없습니다: $sqlFile"
}

$postgresUser = `
    Get-EnvValue `
        $cfg `
        'POSTGRES_USER' `
        'n8n'

$postgresDb = `
    Get-EnvValue `
        $cfg `
        'POSTGRES_DB' `
        'n8n'

$containerSqlPath = `
    '/tmp/init-rag-cache.sql'

Write-Host `
    '    SQL 파일 컨테이너로 복사'

Invoke-Native `
    docker `
    @(
        'cp',
        $sqlFile,
        "offline-rag-postgres:$containerSqlPath"
    )

Write-Host `
    '    rag_response_cache 테이블 생성/확인'

Invoke-Native `
    docker `
    @(
        'exec',
        'offline-rag-postgres',
        'psql',
        '-v',
        'ON_ERROR_STOP=1',
        '-U',
        $postgresUser,
        '-d',
        $postgresDb,
        '-f',
        $containerSqlPath
    )

Write-Host `
    '    임시 SQL 파일 삭제'

Invoke-Native `
    docker `
    @(
        'exec',
        'offline-rag-postgres',
        'rm',
        '-f',
        $containerSqlPath
    )

Write-Host `
    '    rag_response_cache 테이블 준비 완료'


# ============================================================
# n8n 준비 대기
# ============================================================

Write-Host `
    '    n8n 준비 대기...'

if (
    -not (
        Wait-Healthy `
            'offline-rag-n8n' `
            300
    )
) {
    throw `
        'n8n 이 healthy 상태가 되지 않았습니다. docker compose logs n8n 을 확인하세요.'
}


# ============================================================
# [6/6] Workflow import
# ============================================================

Write-Host `
    '==> [6/6] Workflow import'

& "$PSScriptRoot\import-workflows.ps1"

if ($LASTEXITCODE -ne 0) {
    throw `
        'Workflow import 중 오류가 발생했습니다.'
}


# ============================================================
# 최종 헬스체크
# ============================================================

Write-Host ''

Write-Host `
    '==> 최종 환경 점검'

& "$PSScriptRoot\health-check.ps1"

if ($LASTEXITCODE -ne 0) {
    throw `
        '최종 헬스체크에 실패했습니다.'
}


# ============================================================
# 완료
# ============================================================

Write-Host ''

Write-Host `
    '설치 완료'

$frontendPort = `
    Get-EnvValue `
        $cfg `
        'FRONTEND_PORT' `
        '8080'

$n8nPort = `
    Get-EnvValue `
        $cfg `
        'N8N_PORT' `
        '5678'

Write-Host `
    "  챗봇 화면 : http://localhost:$frontendPort"

Write-Host `
    "  n8n 편집기: http://localhost:$n8nPort  (최초 접속 시 관리자 계정 생성)"

Write-Host `
    '  문서 적재 : powershell -ExecutionPolicy Bypass -File scripts\ingest-documents.ps1'