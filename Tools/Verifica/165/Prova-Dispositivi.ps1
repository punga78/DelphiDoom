<#
  Plays the first level of Keen32 with a script that moves the mouse or the joystick (issue #165): KDREAMS.CFG in a
  scratch folder gets the control of the player 0 (4 = mouse, 2 = joystick 1) and the run writes the pictures.
  The same run with the keyboard control is the reference for "Keen moves": the position of Keen on the screen
  (the pictures) must differ from the first one after "mouse 4 0" and move back after "mouse -4 0".

    powershell -NoProfile -File Tools\Verifica\165\Prova-Dispositivi.ps1 -Exe bin\Win32\Release\Keen\Keen32.exe `
      -DataFolders <folder>,<folder> -Script Tools\Verifica\165\Prove\mouse.script -Control 4 -Out <folder>
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string[]]$DataFolders,
  [Parameter(Mandatory = $true)][string]$Script,
  [Parameter(Mandatory = $true)][string]$Out,
  [int]$Control = 4,
  [int]$Level = 1,
  [string[]]$ExtraArguments = @()
)
$ErrorActionPreference = 'Stop'
$DataFolders = @($DataFolders | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$ExtraArguments = @($ExtraArguments | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
$save = Join-Path $Out 'save'
$shots = Join-Path $Out 'shots'
New-Item -ItemType Directory -Force $save, $shots | Out-Null
# the configuration of the original: 10 scores of 64 bytes, the sound mode, the music mode, the control (words)
$cfg = New-Object byte[] 656
[BitConverter]::GetBytes([uint16]$Control).CopyTo($cfg, 644)
[BitConverter]::GetBytes([uint16]1).CopyTo($cfg, 640)
[IO.File]::WriteAllBytes((Join-Path $save 'KDREAMS.CFG'), $cfg)
$data = @()
foreach ($folder in $DataFolders) { $data += '-data'; $data += $folder }
$arguments = $data + @('-save', $save, '-script', $Script, '-shots', $shots, '-report', '-nodevice', '-warp', "$Level") + $ExtraArguments
(& $Exe @arguments 2>&1 | Out-String).Trim()
foreach ($file in Get-ChildItem $shots -Filter *.png) {
  '{0} {1}' -f $file.Name, (Get-FileHash $file.FullName -Algorithm SHA256).Hash.Substring(0, 16)
}
