<#
  Misura delle prestazioni a coppie (issue #185, fase 0): alterna un eseguibile vecchio e uno nuovo su una demo
  (-timedemo), un'esecuzione per volta con Tools\Esegui-gioco.ps1 (lock globale), invertendo l'ordine a ogni coppia, e
  riporta per ciascuno minimo, mediana, media e dispersione (max-min)/min in tic reali (il tempo che il gioco stesso
  misura e scrive: "timed N gametics in R realtics"), la differenza percentuale delle mediane e dei minimi, e il verdetto.

  RIFIUTA il verdetto (scrive "misura non affidabile" ed esce con 3) se
    - la dispersione del vecchio supera -MaxDispersione (predefinito 3%: se il vecchio stesso varia di piu' del margine
      che si vuole provare, la misura non prova nulla), oppure
    - si trovano altri processi pesanti (compilatori dcc32/dcc64/msbuild, altri giochi) o la CPU e' occupata
      da altro prima o dopo le esecuzioni.
  Altrimenti: "entro il 5%" (esce con 0) se mediana e minimo del nuovo non sono oltre +5% del vecchio, "oltre il 5%"
  (esce con 1) altrimenti.

  La configurazione e' quella fissa di Registra-Golden.ps1 (p8.ini / p32.ini: 640x480, niente fili), con i valori e
  l'orologio veri (nessuna opzione degli strumenti di parita'); -noblit perche' la presentazione e' legata al vsync.

  Uso:
    powershell -NoProfile -File Tools\Misura-Coppie.ps1 -Vecchio <exe> -Nuovo <exe> [-Demo demo1] [-Coppie 5]
      (gli exe stanno in bin\<Piattaforma>\<Configurazione>\<Gioco>, es. bin\Win32\Release\Doom\Doom32.exe)
      [-Iwad DOOM1.WAD] [-Modo 8|32] [-MaxDispersione 3] [-Soglia 5] [-WorkRoot <cartella>] [-DataRoot <bin con i WAD>]
#>
param(
  [Parameter(Mandatory = $true)][string]$Vecchio,
  [Parameter(Mandatory = $true)][string]$Nuovo,
  [string]$Demo = 'demo1',
  [int]$Coppie = 5,
  [string]$Iwad = '',
  [ValidateSet(8, 32)][int]$Modo = 32,
  [double]$MaxDispersione = 3,
  [double]$Soglia = 5,
  [string]$Game = '',
  [string]$WorkRoot = 'C:\ddparity',
  [string]$DataRoot = ''
)
. (Join-Path $PSScriptRoot 'Verifica\185\Parity-Common.ps1')
$games = Get-ParityGames

if ($Game -eq '') {
  foreach ($candidate in $games.Keys) { if ((Split-Path -Leaf $Vecchio) -like "$candidate*") { $Game = $candidate } }
  if ($Game -eq '') { $Game = 'Doom' }
}
if ($Iwad -eq '') {
  $Iwad = @{ Doom = 'DOOM1.WAD'; Heretic = 'HERETIC1.WAD'; Hexen = 'HEXEN.WAD'; Strife = 'STRIFE0.WAD' }[$Game]
}

$heavy = 'dcc32', 'dcc64', 'dccosx', 'msbuild', 'bds', 'Doom32', 'GLDoom32', 'Heretic32', 'GLHeretic32', 'Hexen32', 'GLHexen32',
  'Strife32', 'GLStrife32', 'Radix32', 'SpeedHaste32', 'Xcom32', 'Keen32', 'Greed32', 'Speed32'

# Processi pesanti che girano (esclusi i nostri eseguibili di prova, che hanno un nome diverso) e carico della CPU.
function Get-Disturbance {
  $found = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $heavy -contains $_.ProcessName -and $_.ProcessName -notlike 'mis_*' } |
    ForEach-Object { $_.ProcessName })
  $samples = @()
  for ($i = 0; $i -lt 3; $i++) {
    $samples += (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
    Start-Sleep -Milliseconds 700
  }
  $load = ($samples | Measure-Object -Average).Average
  [pscustomobject]@{ Processes = $found; CpuLoad = [Math]::Round($load, 1) }
}

function Get-Stats {
  param([double[]]$Values)
  $sorted = $Values | Sort-Object
  $n = $sorted.Count
  $median = if ($n % 2 -eq 1) { $sorted[($n - 1) / 2] } else { ($sorted[$n / 2 - 1] + $sorted[$n / 2]) / 2 }
  $min = $sorted[0]; $max = $sorted[$n - 1]
  [pscustomobject]@{
    Min = $min; Median = $median; Mean = ($Values | Measure-Object -Average).Average; Max = $max
    Dispersion = ($max - $min) / $min * 100
  }
}

$oldName = 'mis_old_' + $games[$Game].Exe
$newName = 'mis_new_' + $games[$Game].Exe
$dir = Initialize-ParityRunDir -Game $Game -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{ $oldName = $Vecchio; $newName = $Nuovo }

function Invoke-Timed {
  param([string]$ExeName)
  $arguments = "-iwad $Iwad -config p$Modo.ini -dontsavedefaults -nomusic -nosound -noblit -timedemo $Demo"
  $run = Invoke-ParityGame -Exe (Join-Path $dir $ExeName) -Arguments $arguments -WorkDir $dir -TimeoutSeconds 900
  $log = Join-Path $dir ("DATA\LOGS\{0}32_stdout.txt" -f $Game)
  $hit = Select-String -Path $log -Pattern 'timed (\d+) gametics in (\d+) realtics' | Select-Object -Last 1
  if ($run.Alive -or $run.Crash -or -not $hit) { throw "esecuzione fallita: $($run.Text)" }
  [pscustomobject]@{ Gametics = [int]$hit.Matches[0].Groups[1].Value; Realtics = [int]$hit.Matches[0].Groups[2].Value }
}

$before = Get-Disturbance
Write-Output ("Prima: processi pesanti = [{0}], CPU = {1}%" -f ($before.Processes -join ','), $before.CpuLoad)
$old = New-Object System.Collections.Generic.List[double]
$new = New-Object System.Collections.Generic.List[double]
$gametics = @{}
for ($pair = 1; $pair -le $Coppie; $pair++) {
  if ($pair % 2 -eq 1) { $order = @('old', 'new') } else { $order = @('new', 'old') }
  foreach ($which in $order) {
    if ($which -eq 'old') { $name = $oldName } else { $name = $newName }
    $r = Invoke-Timed -ExeName $name
    $gametics[$which] = $r.Gametics
    if ($which -eq 'old') { $old.Add($r.Realtics) } else { $new.Add($r.Realtics) }
    Write-Output ("coppia {0} {1,-3} {2} tic reali ({3} gametic)" -f $pair, $which, $r.Realtics, $r.Gametics)
  }
}
$after = Get-Disturbance
Write-Output ("Dopo:  processi pesanti = [{0}], CPU = {1}%" -f ($after.Processes -join ','), $after.CpuLoad)

$so = Get-Stats $old.ToArray()
$sn = Get-Stats $new.ToArray()
Write-Output ("vecchio: min {0}  mediana {1}  media {2:N1}  dispersione {3:N2}%" -f $so.Min, $so.Median, $so.Mean, $so.Dispersion)
Write-Output ("nuovo:   min {0}  mediana {1}  media {2:N1}  dispersione {3:N2}%" -f $sn.Min, $sn.Median, $sn.Mean, $sn.Dispersion)
$deltaMedian = ($sn.Median - $so.Median) / $so.Median * 100
$deltaMin = ($sn.Min - $so.Min) / $so.Min * 100
Write-Output ("differenza: mediane {0:+0.00;-0.00}%  minimi {1:+0.00;-0.00}%  (positivo = il nuovo e' piu' lento)" -f $deltaMedian, $deltaMin)
if ($gametics['old'] -ne $gametics['new']) { Write-Output "ATTENZIONE: i gametic sono diversi ($($gametics['old']) e $($gametics['new']))" }

$unreliable = @()
if ($so.Dispersion -gt $MaxDispersione) { $unreliable += ("la dispersione del vecchio ({0:N2}%) supera {1}%" -f $so.Dispersion, $MaxDispersione) }
if ($before.Processes.Count -gt 0 -or $after.Processes.Count -gt 0) { $unreliable += 'altri processi pesanti in esecuzione' }
if ($before.CpuLoad -gt 25 -or $after.CpuLoad -gt 25) { $unreliable += 'CPU occupata da altro' }
if ($unreliable.Count -gt 0) {
  Write-Output ("misura non affidabile: " + ($unreliable -join '; '))
  exit 3
}
if ($deltaMedian -le $Soglia -and $deltaMin -le $Soglia) { Write-Output "verdetto: entro il $Soglia%"; exit 0 }
Write-Output "verdetto: oltre il $Soglia%"
exit 1
