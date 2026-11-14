<#
  Issue #110: compila il progetto di test della libreria Doom script e lo esegue, scrivendo le righe prodotte dal
  driver Pascal di ogni scenario in una cartella, per confrontarle a mano con i golden del C++.

  Uso:
    powershell -NoProfile -File Tools\Verifica\110\Prova-Pascal.ps1 [-Piattaforma Win32|Win64] [-SenzaCompilare]

  Uscita: logs\doomscript-parity\<Piattaforma>\<scenario>.actual.txt, l'esito del runner in runner.txt nella stessa
  cartella e, a video, gli errori di compilazione oppure il riepilogo dei test e la prima riga diversa di ogni
  scenario.
#>
param(
  [string]$Piattaforma = 'Win32',
  [switch]$SenzaCompilare
)

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Set-Location $root
$out = Join-Path $root "logs\doomscript-parity\$Piattaforma"
New-Item -ItemType Directory -Force $out | Out-Null

if (-not $SenzaCompilare) {
  cmd /c "Tools\build.bat Tests\DelphiDoom.Tests.DoomScript Release $Piattaforma" | Out-Null
  $log = if ($Piattaforma -eq 'Win64') { 'logs\Win64\DelphiDoom.Tests.DoomScript.log' } else { 'logs\DelphiDoom.Tests.DoomScript.log' }
  $errors = Select-String -Path $log -Pattern '(error|Fatal|warning|hint) [EFWH]\d+' | ForEach-Object { $_.Line.Trim() } |
    Sort-Object -Unique
  if ($errors) { $errors | Select-Object -First 30 }
  if ($errors | Where-Object { $_ -match 'error|Fatal' }) { exit 1 }
}

$env:DOOMSCRIPT_PARITY_OUT = $out
$exe = Join-Path $root "bin\$Piattaforma\Release\Tests\DelphiDoom.Tests.DoomScript.exe"
& $exe '-exit:Continue' > (Join-Path $out 'runner.txt') 2>&1
$code = $LASTEXITCODE
Get-Content (Join-Path $out 'runner.txt') | Select-String -Pattern '^Tests |^  (Passed|Failed|Errored|Ignored)|golden:|port:|, line \d+|the port|the golden' |
  ForEach-Object { $l = $_.Line; if ($l.Length -gt 400) { $l.Substring(0, 400) + ' ...' } else { $l } }
exit $code
