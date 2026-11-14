<#
  Makes the golden file of US_CheckParm of Keen Dreams from the original C (issue #165):
    1. the function US_CheckParm is cut out of Reference\keen\id_us.c (nothing is changed in it);
    2. parmharn.c is compiled with Open Watcom 16 bit with it and asks it 60 parameters against the five tables of
       strings of the managers of the game (input, refresh, sound, user, video);
    3. DOSBox runs PARMHARN.EXE; OUT.TXT becomes Tests\Data\Keen\parm.golden.txt (LF line ends).
  The work folder is outside the repository and outside Reference (default: %TEMP%\keen165-parm).
#>
param([string]$Work = (Join-Path $env:TEMP 'keen165-parm'), [int]$Seconds = 60)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$reference = 'C:\Progetti\DelphiDoom\Reference\keen\id_us.c'
if (-not (Test-Path $Work)) { New-Item -ItemType Directory $Work | Out-Null }
Copy-Item (Join-Path $PSScriptRoot 'parmharn.c') $Work -Force
$text = [IO.File]::ReadAllText($reference, [Text.Encoding]::GetEncoding(437))
$start = $text.IndexOf("`nint`r`nUS_CheckParm(")
if ($start -lt 0) { $start = $text.IndexOf("`nint`nUS_CheckParm(") }
if ($start -lt 0) { throw 'US_CheckParm was not found in id_us.c' }
$end = $text.IndexOf("`n}", $start)
$function = $text.Substring($start, $end + 2 - $start)
[IO.File]::WriteAllText((Join-Path $Work 'USCHECK.INC'), $function, [Text.Encoding]::GetEncoding(437))
$build = @(
  '@echo off',
  'call C:\Progetti\DelphiDoom\Reference\_dati\keen_build\ow_env.cmd',
  "cd /d `"$Work`"",
  'wcc -bt=dos -mm -0 -od -zq -fo=parmharn.obj parmharn.c',
  'if errorlevel 1 exit /b 1',
  'wlink system dos name PARMHARN.EXE option quiet file parmharn.obj'
)
Set-Content -Encoding ascii (Join-Path $Work 'build.cmd') $build
$ErrorActionPreference = 'Continue'
cmd /c "`"$(Join-Path $Work 'build.cmd')`"" 2>&1 | Write-Host
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Work 'PARMHARN.EXE'))) { throw 'the harness was not built' }
if (Test-Path (Join-Path $Work 'OUT.TXT')) { Remove-Item (Join-Path $Work 'OUT.TXT') }
& powershell -NoProfile -File 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\dosrun.ps1' -Dir $Work -Cmd 'PARMHARN.EXE' -Seconds $Seconds
$out = [IO.File]::ReadAllText((Join-Path $Work 'OUT.TXT'), [Text.Encoding]::ASCII).Replace("`r`n", "`n")
if (-not $out.TrimEnd().EndsWith('E')) { throw 'the harness did not end well' }
[IO.File]::WriteAllText((Join-Path $root 'Tests\Data\Keen\parm.golden.txt'), $out)
'cases: ' + ([regex]::Matches($out, "(?m)^[^\t]+\t")).Count
