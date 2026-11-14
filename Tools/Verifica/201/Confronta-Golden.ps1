<#
  Issue #201: rifa dal C del remake tutti i golden di Libs\War e li confronta con quelli di Tests\Data\War.

  Per ogni gruppo (191 archivio, 192 grafica, 193 livelli, 198 suoni, musica e scelta dei suoni) compila con gcc il codice
  ORIGINALE di Reference\war1, esegue i programmi e confronta le righe con il golden che il progetto di test legge.
  Zero differenze = i golden sono ancora quelli del C e i test di Delphi (che leggono gli stessi file) provano la parita'.
  Una differenza e' un golden fuori data o un'estrazione del C cambiata: non si riscrive il golden per far tornare il conto,
  si guarda perche' (Registra-Golden.ps1 e' solo per quando il C e' cambiato di proposito).

  Con -Test <eseguibile> esegue anche il progetto di test (bin\Win32\Release\Tests\DelphiDoom.Tests.War.exe, o la versione Win64) e
  riporta i numeri di DUnitX: e' il confronto lato Delphi.

  Si salta da solo cio' che non si puo' fare: senza il DATA.WAR vero i golden che lo vogliono (lo dice come SALTATO), senza
  gcc il gruppo. Esce con 1 se una riga differisce; i salti non alzano il codice di uscita.

  Uso:
    powershell -NoProfile -File Tools\Verifica\201\Confronta-Golden.ps1 [-DataWar <...\DATA.WAR>] [-Solo 191|192|193|198|musica|suoni]
      [-Out <cartella nuova fuori dal repository>] [-Test <...\DelphiDoom.Tests.War.exe>]
#>
param(
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR',
  [string]$Solo = '',
  [string]$Out = '',
  [string]$Test = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Golden-Common.ps1')

$ownsOut = $false
if ($Out -eq '') { $Out = Join-Path ([IO.Path]::GetTempPath()) ("war-golden-" + [guid]::NewGuid().ToString('N')); $ownsOut = $true }
$differences = 0
$compared = 0
$skipped = 0
try {
  foreach ($group in (Select-Groups $Solo)) {
    "== $($group.Name)"
    try { $dir = Build-Group $group $Out }
    catch { "   ERRORE: $($_.Exception.Message)"; $differences++; continue }
    foreach ($job in $group.Jobs) {
      $actual = Invoke-Job $job $dir $DataWar
      if ($null -eq $actual) { "   SALTATO  $($job.Golden)  (serve il DATA.WAR)"; $skipped++; continue }
      $golden = Read-GoldenFile (Join-Path $script:GoldenDir $job.Golden)
      $now = Get-NormalizedText $actual
      $first = -1
      $limit = [Math]::Min($golden.Count, $now.Count)
      for ($i = 0; $i -lt $limit; $i++) { if ($golden[$i] -ne $now[$i]) { $first = $i; break } }
      if ($first -lt 0 -and $golden.Count -ne $now.Count) { $first = $limit }
      $compared++
      if ($first -lt 0) { "   IDENTICO $($job.Golden)  ($($now.Count) righe)" }
      else {
        $differences++
        "   DIFFERENTE $($job.Golden): righe golden $($golden.Count), righe del C $($now.Count); la prima differenza e' la riga $($first + 1)"
        if ($first -lt $golden.Count) { "     golden: " + $golden[$first].Substring(0, [Math]::Min(160, $golden[$first].Length)) }
        if ($first -lt $now.Count) { "     C:      " + $now[$first].Substring(0, [Math]::Min(160, $now[$first].Length)) }
      }
    }
  }
}
finally {
  if ($ownsOut -and (Test-Path $Out)) { Remove-Item -Recurse -Force $Out -ErrorAction SilentlyContinue }
}

"golden confrontati: $compared, differenti: $differences, saltati: $skipped"

if ($Test -ne '') {
  "== test di Delphi: $Test"
  $report = & $Test 2>&1 | Select-String -Pattern '^Tests (Found|Ignored|Passed|Failed|Errored)'
  $report | ForEach-Object { "   " + $_.Line }
  $failed = ($report | Where-Object { $_.Line -match 'Failed\s*:\s*(\d+)' } | ForEach-Object { [int]$Matches[1] } | Measure-Object -Sum).Sum
  $errored = ($report | Where-Object { $_.Line -match 'Errored\s*:\s*(\d+)' } | ForEach-Object { [int]$Matches[1] } | Measure-Object -Sum).Sum
  if ($failed -gt 0 -or $errored -gt 0) { $differences++ }
}
if ($differences -gt 0) { exit 1 }
exit 0
