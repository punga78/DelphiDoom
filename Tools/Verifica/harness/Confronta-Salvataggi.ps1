# TEMPORARY HARNESS: compares the savegames of the OLD executable (31ee71e3, before the waves of lights,
# doors, planes and platforms) and of the NEW one (master), and checks that a savegame loads back.
#
#   .\Tools\Verifica\harness\Confronta-Salvataggi.ps1 -Game Doom|Heretic|Strife|Hexen [-BinDir <cartella>] [-Seconds 600]
#
# Needs harness_out\<Game>_SOLD.exe and <Game>_SNEW.exe (Compila-Salvataggi.ps1). Six runs, one at a time
# with Tools\Esegui-gioco.ps1 -StopWhenExited:
#   old1, new1, old2, new2          the four continuous runs (saves at leveltime 600, 1000, 1500, 2500; the
#                                   second pair of runs only gives the noise that two identical runs have)
#   newload, oldload                -hload <save_lt_1000 of the same executable>: loads it and saves at 1500, 2500
# Prints, for every save: sizes, differing bytes old-old, new-new, old-new, those of old-new outside the
# noise (offsets that differ in no pair of identical runs), and load_lt_<N> against save_lt_<N>.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Strife', 'Hexen')][string]$Game,
  [string]$BinDir = '',
  [int]$Seconds = 600,
  [int]$ListOffsets = 24
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom\bin'
if ($BinDir -eq '') {
  if (Test-Path (Join-Path $common $Game)) { $BinDir = Join-Path $common $Game } else { $BinDir = Join-Path $root "bin\$Game" }
}
$runner = Join-Path $root 'Tools\Esegui-gioco.ps1'
$outRoot = Join-Path $root "harness_out\saves\$Game"
$times = 600, 1000, 1500, 2500
$slotOf = @{ 'save_600' = 0; 'save_1000' = 1; 'save_1500' = 2; 'save_2500' = 3; 'load_1500' = 4; 'load_2500' = 5 }

switch ($Game) {
  'Doom'    { $iwad = '-iwad DOOM1.WAD -warp 1 1' }
  'Heretic' { $iwad = '-iwad HERETIC1.WAD -warp 1 2' }
  'Strife'  { $iwad = '-iwad STRIFE0.WAD -warp 2' }
  'Hexen'   { $iwad = '-iwad HEXEN.WAD -warp 2' }
}
$baseArguments = "$iwad -nomusic -nosound"

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
public static class SaveDiff {
  // offsets where a and b differ; the bytes of the longer one beyond the shorter count as differences
  public static int[] Offsets(byte[] a, byte[] b) {
    var list = new List<int>();
    int n = Math.Min(a.Length, b.Length);
    for (int i = 0; i < n; i++) if (a[i] != b[i]) list.Add(i);
    for (int i = n; i < Math.Max(a.Length, b.Length); i++) list.Add(i);
    return list.ToArray();
  }
}
'@

function Clear-Outputs {
  Get-ChildItem $BinDir -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(save_lt_|load_lt_|hsave_lt_|hload_lt_|hl_in|harness_)' } |
    Remove-Item -Recurse -Force
  foreach ($d in Get-ChildItem $BinDir -Recurse -Directory -Filter HEXNDATA -ErrorAction SilentlyContinue) {
    Get-ChildItem $d.FullName -File | Where-Object { $_.Name -match '^hex[0-5]' } | Remove-Item -Force
  }
}

function Find-HexenDir {
  $d = Get-ChildItem $BinDir -Recurse -Directory -Filter HEXNDATA -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($d) { return $d.FullName }
  return $null
}

function Collect-Outputs([string]$Label) {
  $dest = Join-Path $outRoot $Label
  Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $dest | Out-Null
  Get-ChildItem $BinDir -Force | Where-Object { $_.Name -match '^(save_lt_|load_lt_|hsave_lt_|hload_lt_|harness_)' } |
    ForEach-Object { Copy-Item $_.FullName $dest -Recurse -Force }
  if ($Game -eq 'Hexen') {
    $h = Find-HexenDir
    if ($h) { Get-ChildItem $h -File | Where-Object { $_.Name -match '^hex[0-5]' } | ForEach-Object { Copy-Item $_.FullName $dest -Force } }
  }
}

function Invoke-Run([string]$Label, [string]$Suffix, [string]$Extra) {
  $name = "${Game}_$Suffix.exe"
  Copy-Item (Join-Path $root "harness_out\$name") (Join-Path $BinDir "${Game}32_$Suffix.exe") -Force
  Write-Host "--- $Label : $name $baseArguments $Extra"
  & powershell -NoProfile -File $runner -Exe (Join-Path $BinDir "${Game}32_$Suffix.exe") -Arguments "$baseArguments $Extra" `
    -WorkDir $BinDir -Seconds $Seconds -StopWhenExited
  Collect-Outputs $Label
  Remove-Item (Join-Path $BinDir "${Game}32_$Suffix.exe") -Force -ErrorAction SilentlyContinue
}

# the files of one save: key -> bytes. kind is 'save' or 'load', time the leveltime
function Get-SaveFiles([string]$Label, [string]$Kind, [int]$Time) {
  $dir = Join-Path $outRoot $Label
  $set = @{}
  switch ($Game) {
    { $_ -in 'Doom', 'Heretic' } {
      $f = Join-Path $dir "${Kind}_lt_$Time.dsg"
      if (Test-Path $f) { $set['dsg'] = [IO.File]::ReadAllBytes($f) }
    }
    'Strife' {
      $d = Join-Path $dir "h${Kind}_lt_$Time"
      if (Test-Path $d) {
        foreach ($f in Get-ChildItem $d -File) { $set[$f.Name] = [IO.File]::ReadAllBytes($f.FullName) }
      }
    }
    'Hexen' {
      $s = $slotOf["${Kind}_$Time"]
      foreach ($f in Get-ChildItem $dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^hex$s" }) {
        $set[$f.Name.Substring(4)] = [IO.File]::ReadAllBytes($f.FullName)
      }
    }
  }
  return $set
}

function Show-Offsets($Offsets) {
  if ($Offsets.Count -eq 0) { return '-' }
  $shown = ($Offsets | Select-Object -First $ListOffsets) -join ','
  if ($Offsets.Count -gt $ListOffsets) { $shown += ',...' }
  return $shown
}

function Union-Offsets([int[]]$A, [int[]]$B) {
  $h = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach ($x in $A) { [void]$h.Add($x) }
  foreach ($x in $B) { [void]$h.Add($x) }
  return $h
}

# --- the runs ---
if (-not (Test-Path $BinDir)) { throw "Cartella non trovata: $BinDir" }
New-Item -ItemType Directory -Force $outRoot | Out-Null

Clear-Outputs
Invoke-Run 'old1' 'SOLD' ''
Clear-Outputs
Invoke-Run 'new1' 'SNEW' ''
Clear-Outputs
Invoke-Run 'old2' 'SOLD' ''
Clear-Outputs
Invoke-Run 'new2' 'SNEW' ''

# what the load runs read: the save at leveltime 1000 of the same executable
function Prepare-Load([string]$FromLabel) {
  Clear-Outputs
  $dir = Join-Path $outRoot $FromLabel
  switch ($Game) {
    { $_ -in 'Doom', 'Heretic' } {
      Copy-Item (Join-Path $dir 'save_lt_1000.dsg') (Join-Path $BinDir 'hl_in.dsg') -Force
      return '-hload hl_in.dsg'
    }
    'Strife' {
      $d = Join-Path $BinDir 'hl_in'
      New-Item -ItemType Directory -Force $d | Out-Null
      Copy-Item (Join-Path $dir 'hsave_lt_1000\*') $d -Recurse -Force
      $map = Get-ChildItem $d -File | Where-Object { $_.Name -match '^\d+$' } | Select-Object -First 1
      return "-hload hl_in\$($map.Name)"
    }
    'Hexen' {
      $h = Find-HexenDir
      if (-not $h) { throw 'cartella HEXNDATA non trovata: eseguire prima le altre prove' }
      Get-ChildItem $dir -File | Where-Object { $_.Name -match '^hex1' } | ForEach-Object { Copy-Item $_.FullName $h -Force }
      return '-hload 1'
    }
  }
}

$extra = Prepare-Load 'new1'
Invoke-Run 'newload' 'SNEW' $extra
$extra = Prepare-Load 'old1'
Invoke-Run 'oldload' 'SOLD' $extra
Clear-Outputs

# --- the report ---
Write-Host ''
Write-Host "===== $Game : savegames (offsets are 0-based byte positions in the file) ====="
foreach ($t in $times) {
  $o1 = Get-SaveFiles 'old1' 'save' $t; $o2 = Get-SaveFiles 'old2' 'save' $t
  $n1 = Get-SaveFiles 'new1' 'save' $t; $n2 = Get-SaveFiles 'new2' 'save' $t
  $keys = @($o1.Keys) + @($n1.Keys) | Sort-Object -Unique
  if ($keys.Count -eq 0) { Write-Host "leveltime ${t}: NESSUN FILE (la prova non e' arrivata al tic?)"; continue }
  foreach ($k in $keys) {
    if (-not ($o1.ContainsKey($k) -and $n1.ContainsKey($k) -and $o2.ContainsKey($k) -and $n2.ContainsKey($k))) {
      Write-Host "leveltime $t [$k]: file mancante in almeno una prova"; continue
    }
    $oo = [SaveDiff]::Offsets($o1[$k], $o2[$k])
    $nn = [SaveDiff]::Offsets($n1[$k], $n2[$k])
    $on = [SaveDiff]::Offsets($o1[$k], $n1[$k])
    $noise = Union-Offsets $oo $nn
    $outside = @($on | Where-Object { -not $noise.Contains($_) })
    Write-Host ("leveltime {0} [{1}] size old={2} new={3} | diff old-old={4} new-new={5} old-new={6} outside-noise={7}" -f `
      $t, $k, $o1[$k].Length, $n1[$k].Length, $oo.Count, $nn.Count, $on.Count, $outside.Count)
    if ($oo.Count) { Write-Host "    old-old offsets: $(Show-Offsets $oo)" }
    if ($nn.Count) { Write-Host "    new-new offsets: $(Show-Offsets $nn)" }
    if ($outside.Count) { Write-Host "    OUTSIDE NOISE old-new offsets: $(Show-Offsets $outside)" }
  }
}

Write-Host ''
Write-Host "===== $Game : reload (load_lt_<N> of the run with -hload against save_lt_<N> of the continuous run) ====="
foreach ($pair in @(@('new1', 'new2', 'newload', 'NEW'), @('old1', 'old2', 'oldload', 'OLD'))) {
  foreach ($t in 1500, 2500) {
    $s = Get-SaveFiles $pair[0] 'save' $t; $s2 = Get-SaveFiles $pair[1] 'save' $t; $l = Get-SaveFiles $pair[2] 'load' $t
    if ($s.Count -eq 0 -or $l.Count -eq 0) { Write-Host "$($pair[3]) leveltime ${t}: file mancanti (save=$($s.Count) load=$($l.Count))"; continue }
    foreach ($k in $s.Keys) {
      if (-not $l.ContainsKey($k)) { Write-Host "$($pair[3]) leveltime $t [$k]: manca nel salvataggio dopo il ricaricamento"; continue }
      $d = [SaveDiff]::Offsets($s[$k], $l[$k])
      $noise = [SaveDiff]::Offsets($s[$k], $s2[$k])
      $outside = @($d | Where-Object { $noise -notcontains $_ })
      Write-Host ("{0} leveltime {1} [{2}] size save={3} load={4} | diff={5} (identical-run noise {6}) outside-noise={7}" -f `
        $pair[3], $t, $k, $s[$k].Length, $l[$k].Length, $d.Count, $noise.Count, $outside.Count)
      if ($d.Count) { Write-Host "    offsets: $(Show-Offsets $d)" }
    }
  }
}
$ln = Get-SaveFiles 'newload' 'load' 1500; $lo = Get-SaveFiles 'oldload' 'load' 1500
foreach ($k in $ln.Keys) {
  if ($lo.ContainsKey($k)) {
    $d = [SaveDiff]::Offsets($lo[$k], $ln[$k])
    Write-Host ("load_lt_1500 old-load vs new-load [{0}]: size {1}/{2} diff={3} {4}" -f $k, $lo[$k].Length, $ln[$k].Length, $d.Count, (Show-Offsets $d))
  }
}
Write-Host ''
foreach ($l in 'old1', 'new1', 'newload', 'oldload') {
  $f = Join-Path $outRoot "$l\harness_sweep.txt"
  if (Test-Path $f) { Write-Host "sweep $l : $(Get-Content $f)" }
  $tr = Join-Path $outRoot "$l\harness_trace.txt"
  if (Test-Path $tr) { Write-Host "trace $l (last 3): $((Get-Content $tr | Select-Object -Last 3) -join ' | ')" }
}
Write-Host "Files kept in $outRoot"
