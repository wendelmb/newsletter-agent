# deploy-vps.ps1 - Deploya o workflow atual para o n8n da VPS
# Uso: .\deploy-vps.ps1
# Pre-requisito: estar na branch main com as mudancas mergeadas

$SSH_KEY = "$env:USERPROFILE\.ssh\lounge_cafe_vps"
$VPS = "root@145.79.7.215"
$JSON_PATH = "$PSScriptRoot\n8n-workflow\newsletter-agent.json"

Write-Host "Lendo workflow sanitizado..."
$json = Get-Content $JSON_PATH -Raw
$json = $json -replace 'YOUR_ANTHROPIC_API_KEY', $env:ANTHROPIC_API_KEY
$json = $json -replace 'YOUR_NOTION_TOKEN', $env:NOTION_TOKEN
$json = $json -replace 'YOUR_NOTION_PARENT_PAGE_ID', '3614f073-2f28-80b1-974a-eddb345456fa'

if ($json -match 'YOUR_') {
    Write-Error "Faltam variaveis de ambiente. Defina ANTHROPIC_API_KEY e NOTION_TOKEN."
    exit 1
}

$obj = $json | ConvertFrom-Json
$obj | Add-Member -NotePropertyName 'id' -NotePropertyValue 'newsletter-agent-vps' -Force
$jsonFinal = $obj | ConvertTo-Json -Depth 20 -Compress

$tmp = "$env:TEMP\na-vps-deploy.json"
$jsonFinal | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

Write-Host "Enviando para VPS..."
scp -i $SSH_KEY -o StrictHostKeyChecking=no $tmp "${VPS}:/tmp/na.json"
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $VPS `
    "docker cp /tmp/na.json n8n:/tmp/na.json && docker exec n8n n8n import:workflow --input=/tmp/na.json && docker exec n8n n8n publish:workflow --id=newsletter-agent-vps && rm /tmp/na.json"

Write-Host "Reiniciando n8n..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $VPS "cd /opt/lounge-cafe && docker compose restart n8n"

Remove-Item $tmp -ErrorAction SilentlyContinue
Write-Host "Deploy concluido. Verifique em http://145.79.7.215:5678"
