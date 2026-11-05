param([string]$BackendHost)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
if (-not $BackendHost) {
  $addresses = @(Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -eq 'Wi-Fi' -and $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' })
  if ($addresses.Count -ne 1) { throw 'Specify -BackendHost with the laptop Wi-Fi IPv4 address.' }
  $BackendHost = $addresses[0].IPv4Address.IPAddress
}
$parsedAddress = [System.Net.IPAddress]::Parse($BackendHost)
if ($parsedAddress.AddressFamily -ne 'InterNetwork' -or $BackendHost -eq '0.0.0.0' -or $BackendHost -eq '127.0.0.1') { throw 'Use one explicit Wi-Fi IPv4 address.' }
Write-Host "HP readiness URL: http://${BackendHost}:3001/health/ready"
python tools/run_backend_local.py --host $BackendHost
exit $LASTEXITCODE
