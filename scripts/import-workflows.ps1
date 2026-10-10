# workflows/*.json 과 자격증명을 n8n 에 import 하고 publish 한다. (import-workflows.sh 와 동일)
# n8n Workflow JSON 이 아닌 파일(예: 브라우저에서 저장한 HTML)은 경고 후 건너뛴다.
# 사용법: powershell -ExecutionPolicy Bypass -File scripts\import-workflows.ps1
. "$PSScriptRoot\common.ps1"

# 검사·import·publish 는 bash/PowerShell 공용 스크립트로 n8n 컨테이너 안에서 수행한다.
Invoke-Native docker @('compose', 'cp', 'scripts/n8n/import-in-container.sh', 'n8n:/tmp/import-in-container.sh')
Invoke-Native docker @('compose', 'exec', '-T', 'n8n', 'sh', '/tmp/import-in-container.sh')

# CLI 로 바꾼 publish 상태는 실행 중인 n8n 에 반영되지 않으므로 재시작한다.
Write-Host '    n8n 재시작 (Webhook 등록)'
Invoke-Native docker @('compose', 'restart', 'n8n') | Out-Null
if (-not (Wait-Healthy 'offline-rag-n8n' 180)) { throw 'n8n 이 healthy 상태가 되지 않았습니다. docker compose logs n8n 을 확인하세요.' }
# 재시작 직후 몇 초 동안은 Webhook 이 이전 버전 Workflow 로 실행된다 (n8n 2.41 실측: 4초 후 이전 버전, 12초 후 새 버전).
Write-Host '    새 버전 Workflow 반영 대기 (15초)'
Start-Sleep -Seconds 15
Write-Host '    완료'
