<#
  Issue #41 (assembler -> Pascal): confronta due eseguibili dello stesso gioco su -timedemo.

  - Il numero di gametic deve essere IDENTICO (stesso stato finale della demo: FixedMul/FixedDiv
    entrano nella simulazione, un bit diverso desincronizza la demo).
  - I realtic (tempo reale) non devono crescere piu' del 5% (mediana di -Runs prove alternate).

  Uso (dalla radice del repository, con i due eseguibili gia' compilati: quello vecchio copiato
  prima della build, quello nuovo appena compilato):
    powershell -NoProfile -File Tools\Verifica\41\Confronta-timedemo.ps1 `
      -OldExe bin\Doom\Doom32.old.exe -NewExe bin\Doom\Doom32.exe `
      -Arguments '-iwad DOOM1.WAD -timedemo demo1 -nomusic -nosound' [-Runs 5] [-MaxSlowdownPercent 5]

  Gli eseguibili girano nella cartella del NUOVO (servono WAD e *.swd); l'esecuzione passa da
  Tools\Esegui-gioco.ps1 (lock globale: una sola esecuzione per volta). Il risultato e' letto da
  <cartella>\DATA\LOGS\*_stdout.txt, riga "N gametics in M realtics".
#>
param(
  [Parameter(Mandatory = $true)][string]$OldExe,
  [Parameter(Mandatory = $true)][string]$NewExe,
  [string]$Arguments = '-iwad DOOM1.WAD -timedemo demo1 -nomusic -nosound',
  [int]$Runs = 5,
  [int]$MaxSlowdownPercent = 5,
  [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
$runner = Join-Path (Split-Path -Parent $PSScriptRoot | Split-Path -Parent) 'Esegui-gioco.ps1'
if (-not (Test-Path -LiteralPath $runner)) { throw "Esegui-gioco.ps1 non trovato: $runner" }
$OldExe = (Resolve-Path -LiteralPath $OldExe).Path
$NewExe = (Resolve-Path -LiteralPath $NewExe).Path
$workDir = Split-Path -Parent $NewExe
$logDir = Join-Path $workDir 'DATA\LOGS'

function Invoke-Timedemo([string]$Exe) {
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $before = Get-Date
  & powershell -NoProfile -File $runner -Exe $Exe -Arguments $Arguments -WorkDir $workDir `
    -Seconds $TimeoutSeconds -StopWhenExited | Out-Null
  $files = Get-ChildItem -LiteralPath $logDir -Filter '*_stdout.txt' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $before.AddSeconds(-2) } | Sort-Object LastWriteTime -Descending
  foreach ($f in $files) {
    $m = Select-String -LiteralPath $f.FullName -Pattern '(\d+) gametics in (\d+) realtics' |
      Select-Object -Last 1
    if ($m) {
      return [pscustomobject]@{ Gametics = [int]$m.Matches[0].Groups[1].Value; Realtics = [int]$m.Matches[0].Groups[2].Value }
    }
  }
  throw "Nessuna riga 'gametics in realtics' nei log di $logDir dopo l'esecuzione di $Exe"
}

$old = @(); $new = @()
for ($i = 1; $i -le $Runs; $i++) {
  $old += Invoke-Timedemo $OldExe
  $new += Invoke-Timedemo $NewExe
  Write-Output ("prova {0}: vecchio {1} gametic / {2} realtic, nuovo {3} gametic / {4} realtic" -f
    $i, $old[-1].Gametics, $old[-1].Realtics, $new[-1].Gametics, $new[-1].Realtics)
}

function Get-Median($values) {
  $sorted = @($values | Sort-Object)
  return $sorted[[int][math]::Floor(($sorted.Count - 1) / 2)]
}

$oldGametics = @($old | ForEach-Object { $_.Gametics } | Select-Object -Unique)
$newGametics = @($new | ForEach-Object { $_.Gametics } | Select-Object -Unique)
$medOld = Get-Median ($old | ForEach-Object { $_.Realtics })
$medNew = Get-Median ($new | ForEach-Object { $_.Realtics })
$slowdown = if ($medOld -gt 0) { 100.0 * ($medNew - $medOld) / $medOld } else { 0.0 }

Write-Output ''
Write-Output ("gametic vecchio: {0}; nuovo: {1}" -f ($oldGametics -join ','), ($newGametics -join ','))
Write-Output ("realtic mediana vecchio: {0}; nuovo: {1}; differenza: {2:N1}% (limite +{3}%)" -f
  $medOld, $medNew, $slowdown, $MaxSlowdownPercent)

$ok = $true
if ($oldGametics.Count -ne 1 -or $newGametics.Count -ne 1 -or $oldGametics[0] -ne $newGametics[0]) {
  Write-Output 'ERRORE: i gametic non coincidono (la simulazione e'' cambiata)'
  $ok = $false
}
if ($slowdown -gt $MaxSlowdownPercent) {
  Write-Output 'ERRORE: il nuovo eseguibile e'' piu'' lento del limite'
  $ok = $false
}
if ($ok) { Write-Output 'OK' } else { exit 1 }
