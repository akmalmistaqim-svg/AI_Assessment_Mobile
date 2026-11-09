param([string]$BackendHost, [string]$DeviceId, [switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
if (-not $BackendHost) {
    $adapters = @(Get-NetIPConfiguration | Where-Object {
        $_.InterfaceAlias -like '*Wi-Fi*' -and $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up'
    })
    if ($adapters.Count -ne 1) { throw 'Tentukan -BackendHost dengan IPv4 Wi-Fi laptop.' }
    $BackendHost = $adapters[0].IPv4Address.IPAddress
}
$address = [System.Net.IPAddress]::Parse($BackendHost)
if ($address.AddressFamily -ne 'InterNetwork' -or $BackendHost -in @('0.0.0.0', '127.0.0.1', '10.0.2.2')) {
    throw 'Gunakan IPv4 Wi-Fi laptop, bukan alamat emulator/localhost.'
}
$localAddresses = @(Get-NetIPAddress -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress)
if ($BackendHost -notin $localAddresses) { throw 'Alamat ini bukan IP laptop saat ini. Periksa ipconfig.' }
$endpoint = "http://${BackendHost}:3001"
try {
    $health = Invoke-RestMethod -Uri "$endpoint/health/ready" -TimeoutSec 5
    if ($health.status -ne 'ready' -or $health.database -ne 'connected') { throw 'Backend belum siap.' }
} catch {
    throw "FastAPI belum siap di $endpoint. Nyalakan Docker, lalu di terminal lain: powershell -File tools/start_backend_wifi.ps1 -BackendHost $BackendHost"
}
Write-Host "Backend HP melalui Wi-Fi: $endpoint"
Write-Host "Cek dari browser HP: $endpoint/health/ready"
if ($BuildOnly) {
    & "$PSScriptRoot/build_phone_debug.ps1" -BackendHost $BackendHost
    exit $LASTEXITCODE
}
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'ADB belum ditemukan.' }
$deviceOutput = & $adb devices
if ($LASTEXITCODE -ne 0) { throw 'Gagal membaca perangkat Android.' }
$phones = @($deviceOutput | ForEach-Object {
    if ($_ -match '^(\S+)\s+device\s*$' -and $Matches[1] -notlike 'emulator-*') { $Matches[1] }
})
if (-not $DeviceId) {
    if ($phones.Count -ne 1) { throw 'Pilih HP dengan -DeviceId, atau gunakan -BuildOnly untuk pemasangan APK tanpa USB/ADB.' }
    $DeviceId = $phones[0]
}
if ($DeviceId -notin $phones) { throw 'HP belum terhubung/diizinkan melalui ADB. Gunakan -BuildOnly bila ingin memasang APK manual.' }
& D:\flutter\bin\flutter.bat run -d $DeviceId --target=lib/main.dart "--dart-define=DEXA_API_BASE_URL=$endpoint"
exit $LASTEXITCODE
