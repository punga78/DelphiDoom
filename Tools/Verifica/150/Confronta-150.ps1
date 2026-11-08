<#
  Issue #150: compares the console output of an old and a new executable of the same game.
  It runs each one with the file comandi.con (cmdline, commandlineparams with and without a mask,
  cmdlist = all the registered commands, typeof) and compares the text between ===BEGIN-150 and
  ===END-150 of the stdout log. Expected result: no difference.

  Use (the old executable is built from the commit before the issue, the new one from this worktree):
    powershell -NoProfile -File Tools\Verifica\150\Confronta-150.ps1 `
      -OldExe <old>\bin\Doom\Doom32.exe -NewExe <new>\bin\Doom\Doom32.exe [-Iwad FREEDOOM2.WAD]

  The game is started with Tools\Esegui-gioco.ps1 (global lock) and stopped after -Seconds.
#>
param(
  [Parameter(Mandatory = $true)][string]$OldExe,
  [Parameter(Mandatory = $true)][string]$NewExe,
  [string]$Iwad = 'FREEDOOM2.WAD',
  [string]$Extra = '-skill 4 -nomonsters',
  [int]$Seconds = 25
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $here '..\..\Esegui-gioco.ps1'
$con = Join-Path $here 'comandi.con'

function Get-Output([string]$exe, [string]$tag) {
  $exe = (Resolve-Path -LiteralPath $exe).Path
  $dir = Split-Path -Parent $exe
  $logs = Join-Path $dir 'DATA\LOGS'
  Get-ChildItem -LiteralPath $logs -Filter '*_stdout.txt' -ErrorAction SilentlyContinue | Remove-Item -Force
  $arguments = "-iwad $Iwad -nosound -nomusic -devparm -con `"$con`" $Extra"
  & powershell -NoProfile -File $runner -Exe $exe -Arguments $arguments -Seconds $Seconds | Out-Null
  $log = Get-ChildItem -LiteralPath $logs -Filter '*_stdout.txt' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $log) { throw "$tag : nessun *_stdout.txt in $logs" }
  $text = Get-Content -LiteralPath $log.FullName
  $begin = [array]::IndexOf($text, '===BEGIN-150')
  $end = [array]::IndexOf($text, '===END-150')
  if ($begin -lt 0 -or $end -lt 0) { throw "$tag : marcatori non trovati in $($log.FullName) (il file .con non e' stato eseguito?)" }
  $cut = $text[$begin..$end]
  $cut | Set-Content -LiteralPath (Join-Path $here "$tag.output.txt")
  return ,$cut
}

$old = Get-Output $OldExe 'vecchio'
$new = Get-Output $NewExe 'nuovo'
Write-Output ("righe vecchio={0} nuovo={1}" -f $old.Count, $new.Count)
$diff = Compare-Object -ReferenceObject $old -DifferenceObject $new -SyncWindow 0
if ($diff) {
  $diff | ForEach-Object { Write-Output ("{0} {1}" -f $_.SideIndicator, $_.InputObject) }
  Write-Output 'DIFFERENZE'
  exit 1
}
Write-Output 'IDENTICO'
