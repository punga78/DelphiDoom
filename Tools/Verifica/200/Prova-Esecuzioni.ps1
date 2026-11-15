<#
.SYNOPSIS
  Decine di esecuzioni di Warcraft32 senza finestra (issue #200) con semi diversi: dal titolo, da ogni missione
  della campagna (umani e orchi), con salvataggio e ricaricamento. Ognuna deve finire con codice 0, senza nulla su
  stderr (un Debug scrive li' "Unexpected Memory Leak") e, per un salvataggio, ridare la stessa pittura.

.PARAMETER Dati
  La cartella col DATA.WAR (di solito Reference\_dati\warcraft: i dati non sono nel repository).
.PARAMETER Exe
  Warcraft32.exe da provare (predefinito: la build Debug Win32, che scrive le perdite di memoria).
.PARAMETER Semi
  Quanti semi (1..N).
.PARAMETER Fotogrammi
  Fotogrammi di ogni esecuzione (60 al secondo del gioco).
#>
param(
  [Parameter(Mandatory = $true)][string]$Dati,
  [string]$Exe = '',
  [int]$Semi = 6,
  [int]$Fotogrammi = 900,
  [string]$Lavoro = (Join-Path $env:TEMP 'war200')
)

$ErrorActionPreference = 'Stop'
if ($Exe -eq '') { $Exe = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\..\..\bin\Win32\Debug\War\Warcraft32.exe' }
$Exe = (Resolve-Path $Exe).Path
New-Item -ItemType Directory -Force $Lavoro | Out-Null
$base = @('-data', $Dati, '-headless')
$eseguite = 0
$fallite = @()

function Esegui([string]$Nome, [string[]]$Argomenti, [string]$ErroreAtteso = '') {
  $out = Join-Path $Lavoro 'out.txt'
  $err = Join-Path $Lavoro 'err.txt'
  $p = Start-Process -FilePath $Exe -ArgumentList ($base + $Argomenti) -NoNewWindow -Wait -PassThru `
    -RedirectStandardOutput $out -RedirectStandardError $err
  $script:eseguite++
  $errore = (Get-Content $err -Raw)
  if ($ErroreAtteso -ne '') {
    # un difetto del C che il port conserva (Libs\War\CLAUDE.md): deve fallire cosi' e non in un altro modo
    if ($p.ExitCode -ne 1 -or $errore -notmatch $ErroreAtteso) { $script:fallite += "$Nome (atteso: $ErroreAtteso; codice $($p.ExitCode)): $errore" }
    return
  }
  if ($p.ExitCode -ne 0 -or ($errore -and $errore.Trim().Length -gt 0)) {
    $script:fallite += "$Nome (codice $($p.ExitCode)): $errore"
    Write-Host "FALLITA $Nome" -ForegroundColor Red
  }
}

foreach ($seme in 1..$Semi) {
  Esegui "titolo seme $seme" @('-seed', $seme, '-quitafter', $Fotogrammi, '-audiostats')
  foreach ($razza in 'human', 'orc') {
    foreach ($missione in 1..12) {
      if ((($seme + $missione) % 3) -ne 0 -and $seme -gt 1) { continue }
      $atteso = ''
      # il livello 123 (umani 4) ha unita' senza dati nelle tabelle: nel C e' un assert
      if ($razza -eq 'human' -and $missione -eq 4) { $atteso = 'unit type 16 has no data' }
      Esegui "$razza $missione seme $seme" @('-seed', $seme, '-play', $razza, $missione, '-quitafter', $Fotogrammi) $atteso
    }
  }
}

# salvare e ricaricare: la stessa pittura (il fotogramma dopo il salvataggio, con e senza passare dal file)
foreach ($seme in 1..$Semi) {
  $file = Join-Path $Lavoro "s$seme.sav"
  foreach ($razza in 'human', 'orc') {
    $a = Join-Path $Lavoro "a.png"; $b = Join-Path $Lavoro "b.png"
    Esegui "salva $razza seme $seme" @('-seed', $seme, '-play', $razza, 1, '-quitafter', 700, '-save', $file)
    Esegui "continua $razza seme $seme" @('-seed', $seme, '-play', $razza, 1, '-quitafter', 701, '-shot', $a)
    Esegui "carica $razza seme $seme" @('-load', $file, '-quitafter', 1, '-shot', $b)
    if ((Get-FileHash $a).Hash -ne (Get-FileHash $b).Hash) {
      $fallite += "carica $razza seme ${seme}: la pittura dopo il caricamento non e' quella del gioco continuato"
    }
  }
}

Write-Host "$eseguite esecuzioni, $($fallite.Count) fallite"
$fallite | ForEach-Object { Write-Host $_ }
if ($fallite.Count -gt 0) { exit 1 }
