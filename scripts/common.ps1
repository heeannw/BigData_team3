# 공통 함수 (다른 .ps1 스크립트에서 dot-source 로 사용)
# Windows PowerShell 5.1 기준으로 작성했다.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest 진행 표시줄로 인한 지연 방지
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Read-DotEnv {
    $envFile = Join-Path $RepoRoot '.env'
    $vars = @{}
    if (Test-Path $envFile) {
        foreach ($line in Get-Content $envFile -Encoding UTF8) {
            if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') { $vars[$Matches[1]] = $Matches[2].Trim() }
        }
    }
    return $vars
}

function Get-EnvValue($vars, $key, $default) {
    if ($vars.ContainsKey($key) -and $vars[$key] -ne '') { return $vars[$key] }
    return $default
}

# 네이티브 명령 실행 후 실패 시 중단
function Invoke-Native {
    param([string]$Exe, [string[]]$Arguments)
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "명령 실패 (exit $LASTEXITCODE): $Exe $($Arguments -join ' ')" }
}

function Test-Http($url, $method = 'GET', $body = $null) {
    try {
        $params = @{ Uri = $url; Method = $method; UseBasicParsing = $true; TimeoutSec = 10 }
        if ($body) { $params.Body = $body; $params.ContentType = 'application/json' }
        $r = Invoke-WebRequest @params
        return @{ Ok = ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300); Body = $r.Content }
    } catch {
        return @{ Ok = $false; Body = $_.Exception.Message }
    }
}

function Wait-Healthy($container, $timeoutSec = 300) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        $status = & docker inspect -f '{{.State.Health.Status}}' $container 2>$null
        if ($status -eq 'healthy') { return $true }
        Start-Sleep -Seconds 3
    }
    return $false
}
