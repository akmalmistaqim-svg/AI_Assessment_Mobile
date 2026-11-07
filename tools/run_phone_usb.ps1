param([string]$DeviceId)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'ADB belum ditemukan di Android SDK.' }
try {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:3001/health/ready' -TimeoutSec 5
    if ($health.status -ne 'ready' -or $health.database -ne 'connected') {
        throw 'Backend belum siap.'
    }
} catch {
    throw 'FastAPI/PostgreSQL belum siap. Nyalakan Docker, lalu jalankan python tools/run_backend_local.py di terminal lain. Setelah itu ulangi perintah ini.'
}
$deviceOutput = & $adb devices
if ($LASTEXITCODE -ne 0) { throw 'Gagal membaca perangkat Android.' }
$phones = @($deviceOutput | ForEach-Object {
    if ($_ -match '^(S+)s+device$' -and $Matches[1] -notlike 'emulator-*') {
        $Matches[1]
    }
})
if (-not $DeviceId) {
    if ($phones.Count -ne 1) {
        throw 'Sambungkan satu HP USB dan izinkan USB debugging, atau tentukan -DeviceId.'
    }
    $DeviceId = $phones[0]
}
if ($DeviceId -notin $phones) { throw 'HP yang dipilih belum terhubung atau belum diizinkan.' }
& $adb -s $DeviceId reverse tcp:3001 tcp:3001
if ($LASTEXITCODE -ne 0) { throw 'Sambungan backend melalui USB gagal dibuat.' }
& D:\flutter\bin\flutter.bat run -d $DeviceId --target=lib/main.dart --dart-define=DEXA_API_BASE_URL=http://127.0.0.1:3001
exit $LASTEXITCODE
