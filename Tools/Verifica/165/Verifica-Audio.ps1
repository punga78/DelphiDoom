<#
  Plays every sound effect of Keen Dreams through Keen32 (issue #165: the sound cannot be heard from here, so it is
  counted): each of the 28 AdLib effects and the 28 PC speaker effects is played to its end, once without the sound
  device of the machine (-nodevice: the mixer is rendered by the clock) and the report must say that the mixer made
  services at 140 a second and that the effect has audible frames (the PC speaker effects 26 and 27 have a silent
  note in their data and are listed as they are). With the device (-device) the report also gives the buffers that
  waveOut played: frames / 1024 when nothing was lost.

    powershell -NoProfile -File Tools\Verifica\165\Verifica-Audio.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -DataFolders <folder>,<folder>,<folder> [-Device]
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string[]]$DataFolders,
  [switch]$Device
)
$ErrorActionPreference = 'Stop'
$DataFolders = @($DataFolders | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$data = @()
foreach ($folder in $DataFolders) { $data += '-data'; $data += $folder }
$silent = @()
$rows = @()
foreach ($mode in 'adlib', 'pc') {
  for ($sound = 0; $sound -lt 28; $sound++) {
    $extra = @('-sound', "$sound")
    if ($mode -eq 'pc') { $extra += '-pcspeaker' }
    if (-not $Device) { $extra += '-nodevice' }
    $line = (& $Exe @data @extra 2>&1 | Out-String).Trim()
    $m = [regex]::Match($line, 'services (\d+), frames (\d+), audible frames (\d+), peak (\d+), buffers played (\d+)')
    if (-not $m.Success) { throw "No statistics for sound $sound ($mode): $line" }
    $row = [pscustomobject]@{ Mode = $mode; Sound = $sound; Services = [int]$m.Groups[1].Value; Frames = [int]$m.Groups[2].Value; Audible = [int]$m.Groups[3].Value; Peak = [int]$m.Groups[4].Value; Buffers = [int]$m.Groups[5].Value }
    $rows += $row
    if ($row.Audible -eq 0) { $silent += "$mode $sound" }
  }
}
$rows | Format-Table -AutoSize | Out-String -Width 200
'silent effects: ' + $(if ($silent.Count -eq 0) { 'none' } else { $silent -join ', ' })
