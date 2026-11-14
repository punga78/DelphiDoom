<#
  Measures the speed of Keen32 in its window (issue #165): tics of the game clock a second (70 by construction),
  refreshes of the game a second (at most 70 / MINTICS = 35, as in the original) and pictures a second, once with
  the fine timer of Windows (the program) and once with the tick of 15.6 ms (-coarsetimer, how it ran before).
  The number that matters is "steady": the refreshes a second after the first 3 seconds, when the loading and the
  fades of the start are over. Exit code 1 if the fine timer is below 34.5 refreshes a second or the clock is not
  at 70 tics a second. One run at a time on the machine (the machine must not be busy: the numbers are timings).

    powershell -NoProfile -File Tools\Verifica\165\Misura-Velocita.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -DataFolders <folder>,<folder> -Seconds 10
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string[]]$DataFolders,
  [int]$Seconds = 10,
  [int]$Level = 1
)
$ErrorActionPreference = 'Stop'
# with -File the folders come as one string with commas
$DataFolders = @($DataFolders | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$save = Join-Path $env:TEMP 'keen_speed_save'
New-Item -ItemType Directory -Force $save | Out-Null
$data = @()
foreach ($folder in $DataFolders) { $data += '-data'; $data += $folder }

function Measure-Run([string[]]$Extra) {
  $arguments = $data + @('-save', $save, '-warp', "$Level", '-quitafter', "$Seconds", '-report') + $Extra
  $text = (& $Exe @arguments 2>&1 | Out-String)
  $tics = [regex]::Match($text, 'speed: ([0-9.]+) tics/s, ([0-9.]+) refreshes/s, ([0-9.]+) pictures/s')
  $steady = [regex]::Match($text, 'steady ([0-9.]+) refreshes/s')
  if (-not $tics.Success -or -not $steady.Success) { throw "No speed in the report: $text" }
  [pscustomobject]@{
    Tics     = [double]::Parse($tics.Groups[1].Value, [cultureinfo]::InvariantCulture)
    Overall  = [double]::Parse($tics.Groups[2].Value, [cultureinfo]::InvariantCulture)
    Pictures = [double]::Parse($tics.Groups[3].Value, [cultureinfo]::InvariantCulture)
    Steady   = [double]::Parse($steady.Groups[1].Value, [cultureinfo]::InvariantCulture)
  }
}

$coarse = Measure-Run @('-coarsetimer')
$fine = Measure-Run @()
'{0,-10} tics/s {1,5:N1}  refreshes/s {2,5:N1}  steady {3,5:N1}  pictures/s {4,5:N1}' -f 'coarse', $coarse.Tics, $coarse.Overall, $coarse.Steady, $coarse.Pictures
'{0,-10} tics/s {1,5:N1}  refreshes/s {2,5:N1}  steady {3,5:N1}  pictures/s {4,5:N1}' -f 'fine', $fine.Tics, $fine.Overall, $fine.Steady, $fine.Pictures
if ([math]::Abs($fine.Tics - 70.0) -gt 1.0) { Write-Error 'The clock of the game is not at 70 tics a second'; exit 1 }
if ($fine.Steady -lt 34.5) { Write-Error 'The refresh is below 34.5 a second'; exit 1 }
'OK'
