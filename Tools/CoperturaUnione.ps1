<#
  Unisce le misure di copertura di piu' progetti di test sulle stesse cartelle: una riga e' coperta se l'ha
  eseguita almeno una suite. Serve per le librerie che non hanno un progetto di test proprio, o che sono provate
  da piu' progetti (Libs\XcomMenu: DelphiDoom.Tests.XcomEngine e DelphiDoom.Tests.XcomTour).

  Uso (dopo aver misurato ogni progetto con Tools\Copertura.ps1 -Test <nome> -Cartella "<cartelle>"):
    powershell -NoProfile -File Tools\CoperturaUnione.ps1 -Test "XcomTour,XcomEngine" -Cartella "Libs\XcomMenu,Libs\XcomUi"
    powershell -NoProfile -File Tools\CoperturaUnione.ps1 -Test "XcomTour,XcomEngine" -Cartella Libs\XcomMenu -Sotto 90
    powershell -NoProfile -File Tools\CoperturaUnione.ps1 -Test XcomTour -Cartella Libs\XcomMenu -Righe AbandonGameState

  -Test      i progetti gia' misurati (logs\copertura\<nome>\CodeCoverage_Summary.xml), separati da virgole.
  -Cartella  le cartelle dei sorgenti, separate da virgole.
  -Sotto     elenca anche le unit con una copertura sotto questa percentuale (0 = nessun elenco).
  -Righe     stampa le righe non coperte delle unit il cui nome contiene questo testo.

  Le righe di una unit sono l'unione di quelle che i progetti hanno nella mappa: una unit che nessun progetto
  collega non compare (e non conta).
#>
param(
  [Parameter(Mandatory = $true)][string]$Test,
  [Parameter(Mandatory = $true)][string]$Cartella,
  [int]$Sotto = 0,
  [string]$Righe = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$folderOf = @{}
foreach ($folder in $Cartella.Split(',')) {
  foreach ($f in Get-ChildItem -LiteralPath (Join-Path $root $folder.Trim()) -Filter *.pas -File -Recurse) {
    $folderOf[$f.Name.ToLowerInvariant()] = $folder.Trim()
  }
}

# unit -> line -> covered
$lines = @{}
foreach ($name in $Test.Split(',')) {
  $summary = Join-Path $root ("logs\copertura\{0}\CodeCoverage_Summary.xml" -f $name.Trim())
  if (-not (Test-Path -LiteralPath $summary)) { throw "Misura non trovata: $summary" }
  $xml = [xml](Get-Content -LiteralPath $summary -Raw)
  foreach ($file in $xml.SelectNodes('//linehits/file')) {
    $unit = ([string]$file.name).ToLowerInvariant()
    if (-not $folderOf.ContainsKey($unit)) { continue }
    if (-not $lines.ContainsKey($unit)) { $lines[$unit] = @{} }
    $ofUnit = $lines[$unit]
    foreach ($pair in ([string]$file.InnerText).Split(';')) {
      $parts = $pair.Split('=')
      if ($parts.Count -ne 2) { continue }
      $line = [int]$parts[0]
      $hit = ([int]$parts[1]) -gt 0
      if (-not $ofUnit.ContainsKey($line)) { $ofUnit[$line] = $hit } elseif ($hit) { $ofUnit[$line] = $true }
    }
  }
}

$totals = @{}
$units = @()
foreach ($unit in $lines.Keys) {
  $ofUnit = $lines[$unit]
  $covered = @($ofUnit.Keys | Where-Object { $ofUnit[$_] }).Count
  $folder = $folderOf[$unit]
  if (-not $totals.ContainsKey($folder)) { $totals[$folder] = @(0, 0) }
  $totals[$folder][0] += $covered
  $totals[$folder][1] += $ofUnit.Count
  $units += [pscustomobject]@{ Unit = $unit; Folder = $folder; Covered = $covered; Total = $ofUnit.Count
    Percent = [Math]::Floor(100 * $covered / [Math]::Max(1, $ofUnit.Count)) }
}

foreach ($folder in ($totals.Keys | Sort-Object)) {
  $t = $totals[$folder]
  Write-Output ("{0}: {1}% ({2} righe coperte su {3}, mancano {4} al 90%)" -f $folder,
    [Math]::Floor(100 * $t[0] / [Math]::Max(1, $t[1])), $t[0], $t[1],
    [Math]::Max(0, [Math]::Ceiling(0.9 * $t[1]) - $t[0]))
}
if ($Sotto -gt 0) {
  foreach ($u in ($units | Where-Object { $_.Percent -lt $Sotto } | Sort-Object { $_.Covered - $_.Total })) {
    Write-Output ("  {0,4} scoperte  {1,3}%  {2}\{3}" -f ($u.Total - $u.Covered), $u.Percent, $u.Folder, $u.Unit)
  }
}
if ($Righe -ne '') {
  foreach ($unit in ($lines.Keys | Where-Object { $_ -like "*$($Righe.ToLowerInvariant())*" } | Sort-Object)) {
    $ofUnit = $lines[$unit]
    $missing = @($ofUnit.Keys | Where-Object { -not $ofUnit[$_] } | Sort-Object)
    # consecutive lines as ranges
    $ranges = @()
    $start = $null; $prev = $null
    foreach ($n in $missing) {
      if ($null -ne $prev -and $n -le $prev + 2) { $prev = $n; continue }
      if ($null -ne $start) { $ranges += $(if ($start -eq $prev) { "$start" } else { "$start-$prev" }) }
      $start = $n; $prev = $n
    }
    if ($null -ne $start) { $ranges += $(if ($start -eq $prev) { "$start" } else { "$start-$prev" }) }
    Write-Output ("{0}: {1}" -f $unit, ($ranges -join ' '))
  }
}
