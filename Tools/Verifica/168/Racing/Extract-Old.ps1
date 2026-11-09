# Issue #168 (S4, Libs\Racing): extracts from the ORIGINAL code of Speed Haste (Reference\Speed, read only)
# the lines that OldRacing.pas includes, so that the old code is compiled as it is.
#
#   Extract-Old.ps1 -Reference C:\Progetti\DelphiDoom\Reference\Speed\Speed -Out <folder>
#
# The only change to the original text is the table of the gears: the original reads one element past
# its end (gear 6 at the top speed), so the copy has one more row of zeros (see Libs\Racing\README.md).
param(
  [Parameter(Mandatory = $true)][string]$Reference,
  [Parameter(Mandatory = $true)][string]$Out
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Out | Out-Null

function Get-Lines([string]$File, [int[]]$Ranges) {
  $all = [System.IO.File]::ReadAllLines((Join-Path $Reference $File))
  $result = @()
  for ($i = 0; $i -lt $Ranges.Count; $i += 2) {
    $result += $all[($Ranges[$i] - 1)..($Ranges[$i + 1] - 1)]
  }
  return $result
}

function Save([string]$Name, [string[]]$Lines) {
  [System.IO.File]::WriteAllLines((Join-Path $Out $Name), $Lines, (New-Object System.Text.UTF8Encoding($false)))
}

Save 'cars_types.inc' (Get-Lines 'speed_cars.pas' @(40, 730))

$gears = Get-Lines 'speed_cars.pas' @(774, 801)
$text = $gears -join "`r`n"
$text = $text.Replace('array[-1..NUM_CAR_GEARS] of array[0..NUM_GEAR_ACCEL_FACTORS - 1] of fixed_t = (',
                      'array[-1..NUM_CAR_GEARS + 1] of array[0..NUM_GEAR_ACCEL_FACTORS - 1] of fixed_t = (')
$last = '    (  4,  6,  8, 12, 16, 24, 32, 40, 48, 56, 64, 64, 64, 48, 32, 16)'
if (-not $text.Contains($last)) { throw 'the last row of the gears was not found' }
$text = $text.Replace($last, $last + ",`r`n    (  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0)")
Save 'cars_gears.inc' ($text -split "`r`n")

Save 'cars_funcs.inc' (Get-Lines 'speed_cars.pas' @(831, 1577))
Save 'race_types.inc' (Get-Lines 'speed_race.pas' @(40, 92))
Save 'race_funcs.inc' (Get-Lines 'speed_race.pas' @(208, 260))
Save 'path_types.inc' (Get-Lines 'speed_path.pas' @(42, 64, 87, 89, 98, 115, 124, 126))
Save 'path_funcs.inc' (Get-Lines 'speed_path.pas' @(149, 201, 315, 552))
Save 'score_types.inc' (Get-Lines 'speed_score.pas' @(43, 68))
Save 'score_funcs.inc' (Get-Lines 'speed_score.pas' @(111, 222, 295, 303))
Save 'particles_vars.inc' (Get-Lines 'speed_particles.pas' @(59, 73))
Save 'particles_funcs.inc' (Get-Lines 'speed_particles.pas' @(79, 175))
Write-Host "Extracted to $Out"
