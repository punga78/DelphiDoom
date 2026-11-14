# Issue #109: builds the REAL routing of Doom 3 (AAS.cpp, AAS_routing.cpp, AAS_pathing.cpp, with AASFile.cpp,
# AASFile_sample.cpp and AASFileManager.cpp of the AAS compiler, and the idlib that they need) with bcc32c (the 32 bit
# clang of Delphi 11), runs route_driver.cpp on the .aas files of Tests\Data\AasD3 and writes the golden files:
#   Tests\Data\AasD3\route.golden.txt        (cache of 2 MB: the original)
#   Tests\Data\AasD3\route_small.golden.txt  (MAX_ROUTING_CACHE_MEMORY patched to 3000 bytes: the oldest caches are dropped)
# Nothing of Doom 3 is copied into the repository: the tree is made in $Dir (outside) from Reference\doom3.
# The stubs are the ones of Tests\Data\MapFile\harness (files in memory, idCommon that prints P: and W: lines).
param(
  [string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
  [string]$Reference = 'C:\Progetti\DelphiDoom\Reference\doom3\neo',
  [string]$Dir = 'C:\harness\d3',
  [string]$Std = ''          # '-std=c++14' if the idlib does not compile without it
)
$ErrorActionPreference = 'Continue'
$B = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
$harness = Join-Path $Repo 'Tests\Data\MapFile\harness'
$data = Join-Path $Repo 'Tests\Data\AasD3'

# --- the tree ----------------------------------------------------------------------------------------------------
if (Test-Path "$Dir\idlib") { Remove-Item -Recurse -Force "$Dir\idlib" }
New-Item -ItemType Directory -Force $Dir | Out-Null
robocopy "$Reference\idlib" "$Dir\idlib" /E /NFL /NDL /NJH /NJS | Out-Null
$aas = "$Reference\tools\compilers\aas"
foreach ($f in 'AASFile.cpp', 'AASFile.h', 'AASFile_local.h', 'AASFile_sample.cpp', 'AASFileManager.cpp', 'AASFileManager.h') { Copy-Item "$aas\$f" "$Dir\idlib\$f" }
foreach ($f in 'AAS.cpp', 'AAS.h', 'AAS_local.h', 'AAS_routing.cpp', 'AAS_pathing.cpp') { Copy-Item "$Reference\game\ai\$f" "$Dir\idlib\$f" }
Copy-Item "$harness\aas_precompiled.h.txt" "$Dir\idlib\precompiled.h"
# fsw.inc: FS_WriteFloatString, the lines 36-146 of File.cpp
Get-Content "$Reference\framework\File.cpp" | Select-Object -Skip 35 -First 111 | Set-Content "$Dir\idlib\fsw.inc" -Encoding ascii

function Patch($file, $pairs) {
  $t = [System.IO.File]::ReadAllText("$Dir\idlib\$file")
  foreach ($p in $pairs) { $t = $t.Replace($p[0], $p[1]) }
  [System.IO.File]::WriteAllText("$Dir\idlib\$file", $t, (New-Object System.Text.UTF8Encoding($false)))
}
$pre = @(, @('#include "../../../idlib/precompiled.h"', '#include "precompiled.h"'))
$pre += , @('#include "../../idlib/precompiled.h"', '#include "precompiled.h"')
foreach ($f in 'AASFile.cpp', 'AASFile_sample.cpp', 'AASFileManager.cpp', 'AAS.cpp', 'AAS_routing.cpp', 'AAS_pathing.cpp') { Patch $f $pre }
# AAS_local.h: the members are read by the driver (private: -> public:), the PVS is not needed
Patch 'AAS_local.h' @(, @('#include "../Pvs.h"', ''))
Patch 'AAS_local.h' @(, @('private:', 'public:'))
Patch 'AASFile_local.h' @(, @('private:', 'public:'))
$t = [System.IO.File]::ReadAllText("$Dir\idlib\AAS_routing.cpp")
$t = [regex]::Replace($t, '#include "\.\./Game_local\.h".*', '')
[System.IO.File]::WriteAllText("$Dir\idlib\AAS_routing.cpp", $t, (New-Object System.Text.UTF8Encoding($false)))
$tail = Get-Content "$PSScriptRoot\route_driver.cpp" -Raw
$head = Get-Content "$harness\aas_driver.cpp.txt" -Raw
$head = $head.Substring(0, $head.IndexOf('int main('))
# the log of the head prints P: lines through idCommon::Printf: keep them (the Delphi twin prints the same)
Set-Content "$Dir\idlib\driver.cpp" ($head + $tail) -Encoding ascii

# the AAS needs the manager and the game; the head of the driver does not know the AASFileManager
Patch 'precompiled.h' @(, @('#include "AASFile_local.h"', "#include `"AASFile_local.h`"`n#include `"AASFileManager.h`"`nclass idGameLocal { public: void Printf(const char *fmt, ...); void Error(const char *fmt, ...); };`nextern idGameLocal gameLocal;`n#include `"AAS.h`"`n#include `"AAS_local.h`""))
# the old keyword of C: no longer allowed by C++17
Patch 'math\Simd_Generic.cpp' @(, @('register ', ''))

$files = 'driver', 'Str', 'Token', 'Lexer', 'Dict', 'Heap', 'math\Math', 'math\Vector', 'math\Matrix', 'math\Angles', 'math\Quat', 'math\Rotation', 'math\Plane', 'math\Pluecker', 'math\Polynomial', 'math\Complex', 'math\Simd_Generic', 'hashing\CRC32', 'containers\HashIndex', 'geometry\JointTransform', 'geometry\DrawVert', 'bv\Bounds', 'AASFile', 'AASFile_sample', 'AASFileManager', 'AAS', 'AAS_routing', 'AAS_pathing'

function Run($suffix, $maxMemory) {
  $obj = "$Dir\obj$suffix"
  if (Test-Path $obj) { Remove-Item -Recurse -Force $obj }
  New-Item -ItemType Directory -Force $obj | Out-Null
  if ($maxMemory -gt 0) {
    $t = [System.IO.File]::ReadAllText("$Dir\idlib\AAS_routing.cpp")
    $t = [regex]::Replace($t, '#define MAX_ROUTING_CACHE_MEMORY\s+\(2\*1024\*1024\)', "#define MAX_ROUTING_CACHE_MEMORY ($maxMemory)")
    [System.IO.File]::WriteAllText("$Dir\idlib\AAS_routing.cpp", $t, (New-Object System.Text.UTF8Encoding($false)))
  }
  Set-Location "$Dir\idlib"
  $failed = $false
  foreach ($f in $files) {
    $o = "$obj\" + ($f -replace '\\', '_') + '.o'
    $args2 = @('-c', '-w-', '-D_XKEYCHECK_H', '-I.', "-o$o", "$f.cpp")
    if ($Std) { $args2 = @($Std) + $args2 }
    $out = & $B @args2 2>&1
    if ($LASTEXITCODE -ne 0) { $failed = $true; Write-Host "== $f exit $LASTEXITCODE"; $out | Select-String 'error' | Select-Object -First 8 | ForEach-Object { $_.Line } }
  }
  if ($failed) { throw 'compile failed' }
  $all = Get-ChildItem "$obj\*.o" | ForEach-Object { $_.FullName }
  & $B -o "$Dir\route$suffix.exe" @all
  New-Item -ItemType Directory -Force "$Dir\data" | Out-Null
  Copy-Item "$data\*.aas" "$Dir\data"
  Copy-Item "$data\cases.txt" "$Dir\data\cases.txt"
  $golden = if ($suffix) { "route$suffix.golden.txt" } else { 'route.golden.txt' }
  & "$Dir\route$suffix.exe" "$Dir\data" | Set-Content (Join-Path $data $golden) -Encoding ascii
  Write-Host "$golden : $((Get-Content (Join-Path $data $golden)).Count) lines"
}
$orig = [System.IO.File]::ReadAllText("$Dir\idlib\AAS_routing.cpp")
Run '' 0
Run '_small' 3000
Set-Location $Repo
