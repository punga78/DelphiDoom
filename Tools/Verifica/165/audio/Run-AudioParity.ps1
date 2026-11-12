<#
  Makes the golden file of the AdLib sound effects of Keen Dreams from the original C (issue #165, K10):
    1. the test exe (bin\Tests\DelphiDoom.Tests.Keen.exe) writes the scripts (SCEN.TXT) with the generator of
       DelphiDoom.Tests.Keen.AdLibScenarios;
    2. id_sd.c of Reference\_dati\keen_build\src is copied to the work folder as ID_SD_P.C with alOut renamed
       alOut_hw (sdharn.c has the alOut that writes the log) and Build-AudioHarness.cmd compiles it with Open Watcom;
    3. DOSBox runs SDHARN.EXE (reads SCEN.TXT, writes OUT.TXT);
    4. New-ActionsGolden.ps1 makes Tests\Data\Keen\adlib.golden.txt from OUT.TXT (one FNV-1a per script).
  The work folder is outside the repository and outside Reference (default: %TEMP%\keen165-audio).
#>
param([string]$Work = (Join-Path $env:TEMP 'keen165-audio'), [int]$Seconds = 60)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$src = 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\src'
if (-not (Test-Path $Work)) { New-Item -ItemType Directory $Work | Out-Null }
$env:DELPHIDOOM_KEEN_ADLIB_SCENARIOS = Join-Path $Work 'SCEN.TXT'
& (Join-Path $root 'bin\Tests\DelphiDoom.Tests.Keen.exe') '--run:DelphiDoom.Tests.Keen.AdLibParity.TTestKeenAdLibParity.GeneraGliScenariPerIlC' | Out-Null
Remove-Item Env:DELPHIDOOM_KEEN_ADLIB_SCENARIOS
Copy-Item (Join-Path $PSScriptRoot 'sdharn.c') $Work -Force
$text = [IO.File]::ReadAllText((Join-Path $src 'id_sd.c'), [Text.Encoding]::GetEncoding(437))
$needle = "`nalOut(byte n,byte b)"
if ($text.IndexOf($needle) -lt 0) { throw 'alOut was not found in id_sd.c' }
$text = $text.Replace($needle, "`nalOut(byte n,byte b);`nvoid alOut_hw(byte n,byte b)")
[IO.File]::WriteAllText((Join-Path $Work 'ID_SD_P.C'), $text, [Text.Encoding]::GetEncoding(437))
$ErrorActionPreference = 'Continue'
cmd /c "`"$(Join-Path $PSScriptRoot 'Build-AudioHarness.cmd')`" `"$Work`"" 2>&1 | Write-Host
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Work 'SDHARN.EXE'))) { throw 'the harness was not built' }
if (Test-Path (Join-Path $Work 'OUT.TXT')) { Remove-Item (Join-Path $Work 'OUT.TXT') }
& powershell -NoProfile -File 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\dosrun.ps1' -Dir $Work -Cmd 'SDHARN.EXE > OUT.TXT' -Seconds $Seconds
& (Join-Path $PSScriptRoot '..\New-ActionsGolden.ps1') -Out (Join-Path $Work 'OUT.TXT') -Golden (Join-Path $root 'Tests\Data\Keen\adlib.golden.txt')
