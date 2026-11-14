# Issue #109: builds the REAL obstacle avoidance of Doom 3 (the lines of game\ai\AI_pathing.cpp that make the dynamic
# obstacle avoidance, and Ballistics) with bcc32c (the 32 bit clang of Delphi 11), together with the real idAASLocal
# (AAS.cpp, AAS_routing.cpp, AAS_pathing.cpp, AASFile*.cpp) and the idlib, runs avoid_driver.cpp on the .aas files of
# Tests\Data\AasD3 and writes Tests\Data\AasD3\avoid.golden.txt.
# Nothing of Doom 3 is copied into the repository: the tree is made in $Dir (outside) from Reference\doom3.
# The only change to the real lines of AI_pathing.cpp: FindOptimalPath's optimizedPath array is not initialised in the original
# (the entries after the last point of a path are stack garbage that is read when a path has one point): the copy clears it.
# The game (entities, physics, clip, render world) is stubbed by avoid_stub.h; the AAS is the real idAASLocal.
param(
  [string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
  [string]$Reference = 'C:\Progetti\DelphiDoom\Reference\doom3\neo',
  [string]$Dir = 'C:\harness\d3avoid'
)
$ErrorActionPreference = 'Continue'
$B = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
$harness = Join-Path $Repo 'Tests\Data\MapFile\harness'
$data = Join-Path $Repo 'Tests\Data\AasD3'

if (Test-Path "$Dir\idlib") { Remove-Item -Recurse -Force "$Dir\idlib" }
New-Item -ItemType Directory -Force $Dir | Out-Null
robocopy "$Reference\idlib" "$Dir\idlib" /E /NFL /NDL /NJH /NJS | Out-Null
$aas = "$Reference\tools\compilers\aas"
foreach ($f in 'AASFile.cpp', 'AASFile.h', 'AASFile_local.h', 'AASFile_sample.cpp', 'AASFileManager.cpp', 'AASFileManager.h') { Copy-Item "$aas\$f" "$Dir\idlib\$f" }
foreach ($f in 'AAS.cpp', 'AAS.h', 'AAS_local.h', 'AAS_routing.cpp', 'AAS_pathing.cpp') { Copy-Item "$Reference\game\ai\$f" "$Dir\idlib\$f" }
Copy-Item "$harness\aas_precompiled.h.txt" "$Dir\idlib\precompiled.h"
Get-Content "$Reference\framework\File.cpp" | Select-Object -Skip 35 -First 111 | Set-Content "$Dir\idlib\fsw.inc" -Encoding ascii

function Patch($file, $pairs) {
  $t = [System.IO.File]::ReadAllText("$Dir\idlib\$file")
  foreach ($p in $pairs) { $t = $t.Replace($p[0], $p[1]) }
  [System.IO.File]::WriteAllText("$Dir\idlib\$file", $t, (New-Object System.Text.UTF8Encoding($false)))
}
$pre = @(, @('#include "../../../idlib/precompiled.h"', '#include "precompiled.h"'))
$pre += , @('#include "../../idlib/precompiled.h"', '#include "precompiled.h"')
foreach ($f in 'AASFile.cpp', 'AASFile_sample.cpp', 'AASFileManager.cpp', 'AAS.cpp', 'AAS_routing.cpp', 'AAS_pathing.cpp') { Patch $f $pre }
Patch 'AAS_local.h' @(, @('#include "../Pvs.h"', ''))
Patch 'AAS_local.h' @(, @('private:', 'public:'))
Patch 'AASFile_local.h' @(, @('private:', 'public:'))
$t = [System.IO.File]::ReadAllText("$Dir\idlib\AAS_routing.cpp")
$t = [regex]::Replace($t, '#include "\.\./Game_local\.h".*', '')
[System.IO.File]::WriteAllText("$Dir\idlib\AAS_routing.cpp", $t, (New-Object System.Text.UTF8Encoding($false)))
Patch 'math\Simd_Generic.cpp' @(, @('register ', ''))

# precompiled.h: the AAS headers, the game of the stubs
$stub = [System.IO.File]::ReadAllText("$PSScriptRoot\avoid_stub.h")
Patch 'precompiled.h' @(, @('#include "AASFile_local.h"', ("#include `"AASFile_local.h`"`n#include `"AASFileManager.h`"`n#include `"AAS.h`"`n#include `"AAS_local.h`"`n" + $stub)))

# the real lines of AI_pathing.cpp: the obstacle avoidance (up to idAI::FreeObstacleAvoidanceNodes) and Ballistics
$lines = [System.IO.File]::ReadAllLines("$Reference\game\ai\AI_pathing.cpp")
$free = 0; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match 'idAI::FreeObstacleAvoidanceNodes') { $free = $i; break } }
$end1 = $free; while ($lines[$end1] -ne '}') { $end1++ }
$b0 = 0; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^typedef struct ballistics_s') { $b0 = $i; break } }
$t0 = 0; for ($i = $b0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match 'idAI::TestTrajectory') { $t0 = $i; break } }
$b1 = $t0 - 3
$part1 = ($lines[0..$end1] | Where-Object { $_ -notmatch '#include|#pragma hdrstop' }) -join "`n"
$part1 = $part1.Replace("`tidVec2 optimizedPath[MAX_OBSTACLE_PATH];`n", "`tidVec2 optimizedPath[MAX_OBSTACLE_PATH];`n`tmemset( optimizedPath, 0, sizeof( optimizedPath ) );`n")
$part2 = ($lines[$b0..$b1]) -join "`n"
$head = Get-Content "$harness\aas_driver.cpp.txt" -Raw
$head = $head.Substring(0, $head.IndexOf('int main('))
$tail = Get-Content "$PSScriptRoot\avoid_driver.cpp" -Raw
Set-Content "$Dir\idlib\driver.cpp" ($head + "`n" + $part1 + "`n" + $part2 + "`n" + $tail) -Encoding ascii

$files = 'driver', 'Str', 'Token', 'Lexer', 'Dict', 'Heap', 'math\Math', 'math\Vector', 'math\Matrix', 'math\Angles', 'math\Quat', 'math\Rotation', 'math\Plane', 'math\Pluecker', 'math\Polynomial', 'math\Complex', 'math\Simd_Generic', 'hashing\CRC32', 'containers\HashIndex', 'geometry\JointTransform', 'geometry\DrawVert', 'geometry\Winding2D', 'bv\Bounds', 'bv\Box', 'AASFile', 'AASFile_sample', 'AASFileManager', 'AAS', 'AAS_routing', 'AAS_pathing'
$obj = "$Dir\obj"
if (Test-Path $obj) { Remove-Item -Recurse -Force $obj }
New-Item -ItemType Directory -Force $obj | Out-Null
Set-Location "$Dir\idlib"
$failed = $false
foreach ($f in $files) {
  $o = "$obj\" + ($f -replace '\\', '_') + '.o'
  $out = & $B -c -w- '-D_XKEYCHECK_H' -I. "-o$o" "$f.cpp" 2>&1
  if ($LASTEXITCODE -ne 0) { $failed = $true; Write-Host "== $f exit $LASTEXITCODE"; $out | Select-String 'error' | Select-Object -First 8 | ForEach-Object { $_.Line } }
}
if ($failed) { throw 'compile failed' }
$all = Get-ChildItem "$obj\*.o" | ForEach-Object { $_.FullName }
& $B -o "$Dir\avoid.exe" @all
New-Item -ItemType Directory -Force "$Dir\data" | Out-Null
Copy-Item "$data\*.aas" "$Dir\data"
Copy-Item "$data\cases.txt" "$Dir\data\cases.txt"
& "$Dir\avoid.exe" "$Dir\data" | Set-Content (Join-Path $data 'avoid.golden.txt') -Encoding ascii
Write-Host "avoid.golden.txt : $((Get-Content (Join-Path $data 'avoid.golden.txt')).Count) lines"
Set-Location $Repo
