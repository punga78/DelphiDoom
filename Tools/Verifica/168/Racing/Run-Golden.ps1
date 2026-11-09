# Issue #168 (S4, Libs\Racing): compiles the OLD code of Speed Haste in a harness and writes the golden file.
#
#   Run-Golden.ps1 [-Reference C:\Progetti\DelphiDoom\Reference\Speed\Speed] [-Work <folder>] [-Output <file>]
#
# Needs Delphi 11 (Win32: the old code has x87 and asm). Reference is read only. Nothing is written in the
# repository except -Output (default Tests\Data\Racing\racing.golden.txt).
param(
  [string]$Reference = 'C:\Progetti\DelphiDoom\Reference\Speed\Speed',
  [string]$Work = (Join-Path $env:TEMP 'racing-golden'),
  [string]$Output
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $here '..\..\..\..')
if (-not $Output) { $Output = Join-Path $root 'Tests\Data\Racing\racing.golden.txt' }

$inc = Join-Path $Work 'inc'
& (Join-Path $here 'Extract-Old.ps1') -Reference $Reference -Out $inc

$units = @(
  (Join-Path $root 'Libs\Racing'),
  (Join-Path $root 'Libs\MathCore'),
  (Join-Path $root 'Tests\Source'),
  $here,
  $inc
) -join ';'

$dcu = Join-Path $Work 'dcu'
New-Item -ItemType Directory -Force -Path $dcu | Out-Null
$rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat'
$cmd = "call `"$rsvars`" >nul && dcc32 -B -Q -NSSystem;Winapi;System.Win -E`"$Work`" -N0`"$dcu`" -U`"$units`" -I`"$units`" `"$(Join-Path $here 'RacingGolden.dpr')`""
& cmd /c $cmd
if ($LASTEXITCODE -ne 0) { throw 'compile failed' }

New-Item -ItemType Directory -Force -Path (Split-Path $Output) | Out-Null
& (Join-Path $Work 'RacingGolden.exe') $Output
if ($LASTEXITCODE -ne 0) { throw 'run failed' }
