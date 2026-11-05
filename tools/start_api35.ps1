param([switch]$Visible)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$env:ANDROID_AVD_HOME=Join-Path (Get-Location) '.local/avd'
if (-not (Test-Path -LiteralPath (Join-Path $env:ANDROID_AVD_HOME 'Dexa_API35.avd/config.ini'))) { throw 'API 35 installation is not ready. Check docs/evidence/api35-setup-status.json.' }
$emulatorArgs=@('-avd','Dexa_API35','-no-audio','-no-snapshot-load','-no-snapshot-save','-gpu','host','-memory','2048','-cores','2')
if (-not $Visible) { $emulatorArgs += '-no-window' }
& 'C:\Users\user\AppData\Local\Android\sdk\emulator\emulator.exe' @emulatorArgs
