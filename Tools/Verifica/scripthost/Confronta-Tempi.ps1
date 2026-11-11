# TEMPORARY HARNESS (issue #172, fetta 2i): times of the -timedemo demo1/2/3 of Doom with the old executable and the new
# one (harness_out\Doom_L2_<label>.exe, the same executables as Confronta-Demo.ps1, run without -vsh: the harness does
# nothing). The two sides alternate N times for every demo; the line "timed <gametics> gametics in <realtics> realtics"
# of the log is read and the realtics of the runs are averaged (lower is faster). The limit of the slice is +5%.
#
#   .\Tools\Verifica\scripthost\Confronta-Tempi.ps1 [-Demos demo1,demo2,demo3] [-Runs 3] [-OldLabel OLD] [-Pad 300]
param(
  [string[]]$Demos = @('demo1', 'demo2', 'demo3'),
  [int]$Runs = 3,
  [string]$OldLabel = 'OLD',
  [int]$Pad = 300,
  [int]$Seconds = 600
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
$binDir = Join-Path $common 'bin\Doom'
$logs = Join-Path $binDir 'DATA\LOGS'
foreach ($demo in $Demos) {
  $ticks = @{ $OldLabel = @(); 'NEW' = @() }
  $gametics = @{}
  $seq = @()
  for ($i = 1; $i -le $Runs; $i++) {
    $order = if ($NewFirst) { @('NEW', $OldLabel) } else { @($OldLabel, 'NEW') }
    foreach ($label in $order) {
      $exe = Join-Path $here "harness_out\Doom_L2_$label.exe"
      $copy = Join-Path $binDir "Doom32_TIME$label.exe"
      Copy-Item $exe $copy -Force
      Get-ChildItem $logs -Filter '*stdout*.txt' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
      try {
        & powershell -NoProfile -File $runner -Exe $copy -Arguments "-iwad DOOM1.WAD -timedemo $demo -nosound -nomusic -vshpad $Pad" -WorkDir $binDir -Seconds $Seconds -StopWhenExited | Out-Null
      }
      finally {
        Remove-Item $copy -Force -ErrorAction SilentlyContinue
      }
      $text = (Get-ChildItem $logs -Filter '*stdout*.txt' | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
      if ($text -match 'timed (\d+) gametics in (\d+) realtics') {
        $gametics[$label] = [int]$Matches[1]
        $ticks[$label] += [int]$Matches[2]
        $seq += ('{0}={1}' -f $label, $Matches[2])
      } else {
        Write-Host "  [$label] run $i : nessuna riga 'timed' nel log"
      }
    }
  }
  # the median: the machine is shared and a single run can be far from the others
  function Get-Median($values) { $s = @($values | Sort-Object); if ($s.Count -eq 0) { return 0 }; if ($s.Count % 2) { return $s[[int](($s.Count - 1) / 2)] } else { return ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2 } }
  $o = Get-Median $ticks[$OldLabel]
  $n = Get-Median $ticks['NEW']
  if ($o -gt 0) { $delta = ($n - $o) / $o * 100 } else { $delta = [double]::NaN }
  Write-Host ('  in ordine: ' + ($seq -join ' '))
  Write-Host ("{0}: gametic vecchio {1} nuovo {2}; realtic vecchio {3} (mediana di {4}: {5}) nuovo {6} ({7}); differenza {8:N1}%" -f $demo, $gametics[$OldLabel], $gametics['NEW'],
    [math]::Round($o, 1), $ticks[$OldLabel].Count, ($ticks[$OldLabel] -join ','), [math]::Round($n, 1), ($ticks['NEW'] -join ','), $delta)
}
