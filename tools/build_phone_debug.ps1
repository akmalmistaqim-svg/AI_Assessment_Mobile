param([Parameter(Mandatory=$true)][string]$BackendHost)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$parsedAddress = [System.Net.IPAddress]::Parse($BackendHost)
if ($parsedAddress.AddressFamily -ne 'InterNetwork' -or $BackendHost -in @('0.0.0.0','127.0.0.1','10.0.2.2')) { throw 'Use the laptop Wi-Fi IPv4 address.' }
$endpoint = "http://${BackendHost}:3001"
& D:\flutter\bin\flutter.bat build apk --debug --no-pub --target=lib/main.dart --split-per-abi --target-platform android-arm,android-arm64 "--dart-define=DEXA_API_BASE_URL=$endpoint"
if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed; no APK was copied.' }
New-Item -ItemType Directory -Force -Path build/qa-artifacts | Out-Null
foreach ($abi in @('arm64-v8a','armeabi-v7a')) {
  Copy-Item -LiteralPath "build/app/outputs/flutter-apk/app-$abi-debug.apk" -Destination "build/qa-artifacts/dexa-phone-wifi-$abi-debug.apk"
}
Write-Host "APK endpoint: $endpoint"
