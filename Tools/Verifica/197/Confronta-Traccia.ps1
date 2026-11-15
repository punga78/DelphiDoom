<#
  Issue #197: quando l'impronta di un fotogramma di Delphi differisce da quella del C, si guardano le CHIAMATE DI DISEGNO
  (molto piu' a buon mercato dei pixel): la traccia del remake in C (war_frame_ref.c con "trace on") e quella di Delphi
  (TWarUiScriptRunner, "trace on"), una riga per chiamata, senza l'indirizzo della texture (non ha senso fuori dal processo):
    T sx sy sw sh > dx dy dw dh aALFA cR,G,B b1        una texture
    R sx sy sw sh > dx dy dw dh aALFA cR,G,B b1 fF     una texture specchiata (F = 1 orizzontale, 2 verticale, 3 tutte e due)
    F x y w h cR,G,B,A                                 un rettangolo pieno
    S x y w h cR,G,B,A                                 un contorno

  Scrive <Out>\<script>.c.trace.txt (e, con -Pixel, <script>.c.rgba: i pixel dell'ultimo fotogramma, 320 x 200 x 4 byte).
  La traccia di Delphi la scrive il test DelphiDoom.Tests.War.UiParity quando un fotogramma differisce, se la variabile
  d'ambiente DELPHIDOOM_WAR_UI_DUMP e' una cartella: <script>.delphi.trace.txt. Con -Delphi si confrontano e si dice la
  prima riga diversa (con il numero di riga e le due righe).

  Uso:
    powershell -NoProfile -File Tools\Verifica\197\Confronta-Traccia.ps1 -Script cheats -Out <cartella NUOVA fuori dal repository>
      [-Delphi <...\cheats.delphi.trace.txt>] [-Pixel]
#>
param(
  [Parameter(Mandatory)][string]$Script,
  [Parameter(Mandatory)][string]$Out,
  [string]$Delphi = '',
  [switch]$Pixel
)
$ErrorActionPreference = 'Stop'
$scripts = Join-Path $PSScriptRoot 'scripts'
$source = Join-Path $scripts ($Script + '.script')
if (-not (Test-Path $source)) { throw "Script non trovato: $source" }
$build = Join-Path $Out 'build'
& (Join-Path $PSScriptRoot 'Compila-FrameRef.ps1') -Out $build | Out-Null

# lo script con "trace on" in testa (e "rgba" in fondo con -Pixel)
$lines = @('trace on') + [IO.File]::ReadAllLines($source)
if ($Pixel) { $lines += ('rgba ' + (Join-Path $Out ($Script + '.c.rgba'))) }
$traced = Join-Path $Build ($Script + '.traced.script')
[IO.File]::WriteAllLines($traced, $lines)

Push-Location $build
try {
  $ErrorActionPreference = 'Continue'
  $stderr = & (Join-Path $build 'war_frame_ref.exe') $traced 2>&1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }
  $ErrorActionPreference = 'Stop'
} finally { Pop-Location }

$normal = foreach ($l in $stderr) { if ($l -match '^[TRFS] ') { $l -replace '^([TR]) \S+ ', '$1 ' } }
$cTrace = Join-Path $Out ($Script + '.c.trace.txt')
[IO.File]::WriteAllLines($cTrace, [string[]]@($normal))
"Scritto $cTrace ($(@($normal).Count) righe)"

if ($Delphi -ne '') {
  $d = [IO.File]::ReadAllLines($Delphi)
  $c = [IO.File]::ReadAllLines($cTrace)
  $n = [Math]::Min($d.Count, $c.Count)
  for ($i = 0; $i -lt $n; $i++) {
    if ($d[$i] -ne $c[$i]) { "Prima riga diversa: $($i + 1)`n  C:      $($c[$i])`n  Delphi: $($d[$i])"; return }
  }
  if ($d.Count -ne $c.Count) { "Stesse $n righe, ma il C ne ha $($c.Count) e Delphi $($d.Count)" } else { "Tracce uguali ($n righe)" }
}
