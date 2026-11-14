<#
  Issue #219: prova di Controlla-Strati.ps1 sui mini-alberi di Tests\Data\Strati.

  Ogni sottocartella di Tests\Data\Strati e' un caso: Radice\ (file .pas finti), Strati.psd1
  (il manifesto del caso) e Atteso.psd1 con Uscita (codice di uscita atteso), Argomenti (parametri
  in piu' per lo script), Contiene e NonContiene (frammenti che devono o non devono comparire
  nell'output). Lo script del controllo gira in un processo a parte, come dal vero.

  Uso:  powershell -File Tools\Verifica\219\Prova-Controlla-Strati.ps1 [-Caso <nome>]
  Uscita: 0 se tutti i casi danno l'esito atteso, 1 se almeno uno fallisce (o non ce ne sono).
#>
param([string]$Caso = '')

$ErrorActionPreference = 'Stop'
$radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$controllo = Join-Path $PSScriptRoot 'Controlla-Strati.ps1'
$casi = Get-ChildItem (Join-Path $radice 'Tests\Data\Strati') -Directory | Sort-Object Name
if ($Caso -ne '') { $casi = @($casi | Where-Object { $_.Name -eq $Caso }) }
if ($casi.Count -eq 0) {
  Write-Host 'Nessun caso di prova trovato in Tests\Data\Strati' -ForegroundColor Red
  exit 1
}

$riusciti = 0
$falliti = 0
foreach ($c in $casi) {
  $atteso = Import-PowerShellDataFile -Path (Join-Path $c.FullName 'Atteso.psd1')
  $argomenti = @('-NoProfile', '-File', $controllo, '-Radice', (Join-Path $c.FullName 'Radice'), '-Manifesto', (Join-Path $c.FullName 'Strati.psd1'))
  foreach ($a in $atteso.Argomenti) { $argomenti += $a }
  $uscita = (& powershell @argomenti 2>&1 | Out-String)
  $codice = $LASTEXITCODE
  $errori = New-Object Collections.Generic.List[string]
  if ($codice -ne $atteso.Uscita) { $errori.Add("codice di uscita $codice invece di $($atteso.Uscita)") }
  foreach ($s in $atteso.Contiene) { if (-not $uscita.Contains($s)) { $errori.Add("manca: $s") } }
  foreach ($s in $atteso.NonContiene) { if ($uscita.Contains($s)) { $errori.Add("c'e' ma non doveva: $s") } }
  if ($errori.Count -eq 0) {
    $riusciti++
    Write-Host ("  ok      {0} (uscita {1})" -f $c.Name, $codice)
  }
  else {
    $falliti++
    Write-Host ("  FALLITO {0}" -f $c.Name) -ForegroundColor Red
    foreach ($e in $errori) { Write-Host "          $e" -ForegroundColor Red }
    Write-Host '          --- output ---'
    foreach ($r in ($uscita -split "`r?`n")) { Write-Host "          $r" }
  }
}

Write-Host ("Casi di prova: {0}; riusciti: {1}; falliti: {2}" -f $casi.Count, $riusciti, $falliti)
if ($falliti -gt 0) { exit 1 }
exit 0
