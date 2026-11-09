<#
  Makes the golden file of the actions of Keen Dreams from the original C (issue #165, K8b):
    1. the test exe (bin\Tests\DelphiDoom.Tests.Keen.exe, built with Tools\build.bat DelphiDoom.Tests.Keen) writes the
       scenarios (SCEN.TXT) with the generator of DelphiDoom.Tests.Keen.ActionScenarios;
    2. Build-Harness.cmd compiles harness.c with Open Watcom (16 bit) and links it with the original kd_keen, kd_act1
       and kd_act2 objects of Reference\_dati\keen_build\src\obj;
    3. DOSBox runs ACTHARN.EXE (the harness reads SCEN.TXT and writes the log of every scenario to OUT.TXT);
    4. New-ActionsGolden.ps1 makes Tests\Data\Keen\actions.golden.txt from OUT.TXT.
  Then Tools\build.bat DelphiDoom.Tests.Keen and the test DovrebbeDareLoStessoRisultatoDelCInOgniScenario compare the
  port with the golden file. Compare-Actions.ps1 shows the differences line by line (PORT.TXT is written by
  ScriviIlRisultatoDelPorting when DELPHIDOOM_KEEN_PORT_OUT is set).
#>
param([int]$Seconds = 150)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$work = 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\actions'
$env:DELPHIDOOM_KEEN_SCENARIOS = Join-Path $work 'SCEN.TXT'
if (-not (Test-Path $work)) { New-Item -ItemType Directory $work | Out-Null }
& (Join-Path $root 'bin\Tests\DelphiDoom.Tests.Keen.exe') '--run:DelphiDoom.Tests.Keen.ActionsParity.TTestKeenActionsParity.GeneraGliScenariPerIlC' | Out-Null
Remove-Item Env:DELPHIDOOM_KEEN_SCENARIOS
$ErrorActionPreference = 'Continue'
cmd /c (Join-Path $PSScriptRoot 'Build-Harness.cmd') 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $work 'OUT.TXT')) { Remove-Item (Join-Path $work 'OUT.TXT') }
& powershell -NoProfile -File 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\dosrun.ps1' -Dir $work -Cmd 'ACTHARN.EXE > OUT.TXT' -Seconds $Seconds
& (Join-Path $PSScriptRoot 'New-ActionsGolden.ps1') -Out (Join-Path $work 'OUT.TXT') -Golden (Join-Path $root 'Tests\Data\Keen\actions.golden.txt')
