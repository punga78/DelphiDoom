# TEMPORARY HARNESS (issue #177): paired timing of the OpenGL games, old against new.
# Runs <Game>_GL_OLD.exe and <Game>_GL_NEW.exe (Compila.ps1; the recorder is dormant without -glrecord) on a -timedemo,
# one run at a time (Tools\Esegui-gioco.ps1, global lock), swapping the order at every pair, and prints the realtics the
# game writes ("timed N gametics in R realtics") with minimum, median, mean and spread of each, and the difference.
# Refuses a verdict (exit 3) if the spread of the old executable is over -MaxSpread percent: a measure that varies more
# than the margin to prove proves nothing; the raw numbers are printed anyway.
#
#   .\Tools\Verifica\opengl\Misura-Gl.ps1 [-Game GLDoom] [-Demo demo3] [-Pairs 5] [-MaxSpread 3] [-Limit 5]
param(
  [ValidateSet('GLDoom', 'GLHeretic', 'GLHexen', 'GLStrife')][string]$Game = 'GLDoom',
  [string]$Demo = 'demo3',
  [string]$Iwad = 'DOOM1.WAD',
  [int]$Pairs = 5,
  [double]$MaxSpread = 3,
  [double]$Limit = 5,
  [int]$Seconds = 300,
  # the PK3 of Tests\Data\ModelsGl of the game (every state of the game is the MD2 cube; adds -devparm)
  [switch]$Models,
  # the PK3 of Tests\Data\LightsGl of the game (a GLDEFS with a dynamic light on three sprites out of four; adds -devparm)
  [switch]$Lights
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
$folder = $Game.Substring(2)
$binDir = Join-Path $common "bin\$folder"
$exeName = "${Game}32"
$modelArguments = ""
if ($Models) {
  $letter = @{ GLDoom = 'd'; GLHeretic = 'h'; GLHexen = 'x'; GLStrife = 's' }[$Game]
  $modelArguments = " -devparm -file " + (Join-Path $here "Tests\Data\ModelsGl\zmdl_$letter.pk3")
}
if ($Lights) {
  $letter = @{ GLDoom = 'd'; GLHeretic = 'h'; GLHexen = 'x'; GLStrife = 's' }[$Game]
  $iniSource = Join-Path $binDir "$($Game.Substring(2))32.ini"
  New-Item -ItemType Directory -Force (Join-Path $here 'harness_out') | Out-Null
  $lightIni = Join-Path $here "harness_out\lights_$Game.ini"
  $iniText = [System.IO.File]::ReadAllText($iniSource)
  $iniText = $iniText -replace '(?m)^uselightboost=\d', 'uselightboost=1' -replace '(?m)^gl_drawshadows=\d', 'gl_drawshadows=1'
  [System.IO.File]::WriteAllText($lightIni, $iniText)
  $modelArguments += " -devparm -file " + (Join-Path $here "Tests\Data\LightsGl\zlgt_$letter.pk3") + " -config $lightIni"
}

function Test-Busy {
  $busy = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(dcc32|dcc64|msbuild|rsvars|bds)$' })
  return $busy.Count -gt 0
}

function Measure-One([string]$Version) {
  $copy = Join-Path $binDir "${exeName}_G$($Version.ToUpper()).exe"
  Copy-Item (Join-Path $here "harness_out\${Game}_GL_$($Version.ToUpper()).exe") $copy -Force
  $log = Join-Path $binDir "DATA\LOGS\${exeName}_stdout.txt"
  Remove-Item $log -Force -ErrorAction SilentlyContinue
  try {
    & powershell -NoProfile -File $runner -Exe $copy -WorkDir $binDir -Seconds $Seconds -StopWhenExited `
      -Arguments "-iwad $Iwad -timedemo $Demo -windowed -nosound -nomusic -nomouse -nojoystick -nointerpolate$modelArguments" | Out-Null
  }
  finally {
    Remove-Item $copy -Force -ErrorAction SilentlyContinue
  }
  if (-not (Test-Path $log)) { return $null }
  $m = Select-String -Path $log -Pattern 'timed (\d+) gametics in (\d+) realtics' | Select-Object -Last 1
  if ($null -eq $m) { return $null }
  return [int]$m.Matches[0].Groups[2].Value
}

$busyBefore = Test-Busy
$old = @(); $new = @()
for ($i = 0; $i -lt $Pairs; $i++) {
  if ($i % 2 -eq 0) { $o = Measure-One 'Old'; $n = Measure-One 'New' } else { $n = Measure-One 'New'; $o = Measure-One 'Old' }
  Write-Host "coppia $($i + 1): vecchio $o nuovo $n"
  if ($null -ne $o) { $old += $o }
  if ($null -ne $n) { $new += $n }
}
$busyAfter = Test-Busy
function Stat($v) {
  $s = @($v | Sort-Object)
  $median = if ($s.Count % 2 -eq 1) { $s[($s.Count - 1) / 2] } else { ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2 }
  [pscustomobject]@{ Min = $s[0]; Median = $median; Mean = [Math]::Round(($s | Measure-Object -Average).Average, 1);
    Spread = [Math]::Round(($s[-1] - $s[0]) * 100.0 / $s[0], 1) }
}
$so = Stat $old; $sn = Stat $new
Write-Host "vecchio: min $($so.Min) mediana $($so.Median) media $($so.Mean) dispersione $($so.Spread)% ($($old -join ', '))"
Write-Host "nuovo  : min $($sn.Min) mediana $($sn.Median) media $($sn.Mean) dispersione $($sn.Spread)% ($($new -join ', '))"
$dMin = [Math]::Round(($sn.Min - $so.Min) * 100.0 / $so.Min, 1)
$dMed = [Math]::Round(($sn.Median - $so.Median) * 100.0 / $so.Median, 1)
$dMean = [Math]::Round(($sn.Mean - $so.Mean) * 100.0 / $so.Mean, 1)
Write-Host "differenza (realtic, piu' alto = piu' lento): minimi $dMin%, mediane $dMed%, medie $dMean%"
if ($busyBefore -or $busyAfter) { Write-Host 'MISURA NON AFFIDABILE: compilatori in esecuzione durante la misura'; exit 3 }
if ($so.Spread -gt $MaxSpread -or $sn.Spread -gt $MaxSpread) { Write-Host "MISURA NON AFFIDABILE: dispersione oltre il $MaxSpread%"; exit 3 }
if ($dMin -le $Limit -and $dMed -le $Limit) { Write-Host "entro il $Limit%"; exit 0 }
Write-Host "oltre il $Limit%"; exit 1
