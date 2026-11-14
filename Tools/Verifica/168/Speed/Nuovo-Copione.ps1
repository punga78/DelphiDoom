<#
  Writes the script of commands (-autoscript) that drives the car of the player round a circuit of Speed Haste
  (issue #168). The points come from the state log that SpeedHaste32 writes with -speedstate (the lines
  "path N x X y Y angle A speed S": the points of the path in the order of the track); the script is a
  "goto X Y drive speed N" for each point, for the laps asked, plus the first points of one more lap (the line is
  crossed at the first point) and a pause at the end for the end of the race (a script that ends closes the game).

    powershell -NoProfile -File Tools\Verifica\168\Speed\Nuovo-Copione.ps1 -State C:\ddsp\t1.state `
      -Out Tests\Data\Parity\Speed\e1m1.script -Laps 2
#>
param(
  [Parameter(Mandatory = $true)][string]$State,
  [Parameter(Mandatory = $true)][string]$Out,
  [int]$Laps = 2,
  # how much of the speed of the path the car drives at (the computer cars drive at all of it)
  [double]$SpeedFactor = 0.8,
  [int]$Radius = 170,
  [int]$Pause = 900
)
$ErrorActionPreference = 'Stop'
$points = @()
foreach ($line in Get-Content $State) {
  if ($line -match '^path (\d+) x (-?\d+) y (-?\d+) angle (-?\d+) speed (\d+)') {
    $points += [pscustomobject]@{ X = [int]$Matches[2]; Y = [int]$Matches[3]; Speed = [int]$Matches[5] }
  }
}
if ($points.Count -eq 0) { throw "no path lines in $State" }
$text = New-Object System.Collections.Generic.List[string]
$text.Add("# Speed Haste: $Laps laps driven by the script ($($points.Count) points of the path, speed factor $SpeedFactor)")
$text.Add('# the lights are off at tic 209 (-warp: the level starts at tic 0)')
$text.Add('hold 215')
for ($lap = 0; $lap -lt $Laps; $lap++) {
  foreach ($p in $points) {
    # km/h to map units for each tic: 1 km/h is 4370 / 65536 of a unit
    $units = [Math]::Max(3, [Math]::Min(50, [int][Math]::Round($p.Speed * 4370 / 65536 * $SpeedFactor)))
    $text.Add("goto $($p.X) $($p.Y) drive speed $units radius $Radius timeout 3000")
  }
}
foreach ($p in $points[0..4]) {
  $units = [Math]::Max(3, [Math]::Min(50, [int][Math]::Round($p.Speed * 4370 / 65536 * $SpeedFactor)))
  $text.Add("goto $($p.X) $($p.Y) drive speed $units radius $Radius timeout 3000")
}
$text.Add("hold $Pause")
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[IO.File]::WriteAllText($Out, ($text -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
"written $Out ($($text.Count) lines)"
