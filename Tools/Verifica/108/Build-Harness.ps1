# Issue #108 (id Tech 4 collision model): builds the parity harness against the REAL Doom 3 sources.
#
# idlib, framework\File.cpp and neo\cm are copied from Reference\doom3 into a scratch folder (never into the
# repository), a few lines are patched in the COPY (listed below), and everything is compiled with bcc32c (the
# clang of RAD Studio, x87) together with the stubs of this folder (the pieces of the engine the code calls:
# precompiled.h, engine.h, stubs.cpp) and the harness main. Nothing from Doom 3 is added to the repository.
#
# Patches to the copy (none touches the logic):
#   Lib.h               only the headers the collision code needs (no BitMsg, Ode, Lcp...)
#   Simd.h              the definition of dominantTri_s, which lives in the renderer
#   Simd_Generic.cpp    'register' is not accepted by this compiler
#   Math.h              SinCos and SinCos64 without the MSVC inline assembler
#   File.h              private members made public so that the stubs can fill an idFile_Permanent
#   File.cpp            cut before idFile_InZip (it needs unzip) and before idFile_BitMsg (it needs idBitMsg)
#   CollisionModel_*    'unsigned long' (32 bit on the Win32 target) is kept; nothing else
#
# Usage: Tools\Verifica\108\Build-Harness.ps1 [-Reference <path to the main checkout's Reference>] [-Work <scratch>]
#        -Main <name of the main file in this folder>   (default main.cpp)
# The harness exe is left in <Work>\harness.exe.
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd108harness'),
	[string]$Main = 'main.cpp',
	[string]$Compiler = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$neo = Join-Path $Reference 'doom3\neo'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)) }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force $Work | Out-Null
Copy-Item -Recurse (Join-Path $neo 'idlib') (Join-Path $Work 'idlib')
Copy-Item -Recurse (Join-Path $neo 'cm') (Join-Path $Work 'cm')
New-Item -ItemType Directory -Force (Join-Path $Work 'framework') | Out-Null
Copy-Item (Join-Path $neo 'framework\File.h') (Join-Path $Work 'framework\File.h')
Copy-Item (Join-Path $neo 'framework\File.cpp') (Join-Path $Work 'framework\File.cpp')
New-Item -ItemType Directory -Force (Join-Path $Work 'harness') | Out-Null
foreach ($f in 'engine.h', 'stubs.cpp', $Main) { Copy-Item (Join-Path $here $f) (Join-Path $Work "harness\$f") }
Copy-Item (Join-Path $here 'precompiled.h') (Join-Path $Work 'idlib\precompiled.h')

# Lib.h: everything up to "// text manipulation", then the containers and the map file
$lib = Read-Text (Join-Path $Work 'idlib\Lib.h')
$cut = $lib.IndexOf('// text manipulation')
$head = ($lib.Substring(0, $cut) -split "`r?`n" | Where-Object { $_ -notmatch 'Ode\.h|Lcp\.h|Frustum\.h|SweptSpline\.h|Polytope\.h' }) -join "`r`n"
$tail = "#include `"Str.h`"`r`n#include `"Token.h`"`r`n#include `"Lexer.h`"`r`n#include `"containers/BinSearch.h`"`r`n#include `"containers/HashIndex.h`"`r`n" +
	"#include `"containers/StaticList.h`"`r`n#include `"containers/PlaneSet.h`"`r`n#include `"containers/Queue.h`"`r`n#include `"containers/StrList.h`"`r`n" +
	"#include `"containers/StrPool.h`"`r`n#include `"containers/VectorSet.h`"`r`n#include `"hashing/CRC32.h`"`r`n#include `"Parser.h`"`r`n#include `"Dict.h`"`r`n#include `"BitMsg.h`"`r`n#include `"MapFile.h`"`r`n#include `"Timer.h`"`r`n`r`n#endif`r`n"
Write-Text (Join-Path $Work 'idlib\Lib.h') ($head + "`r`n" + $tail)
$simd = Read-Text (Join-Path $Work 'idlib\math\Simd.h')
Write-Text (Join-Path $Work 'idlib\math\Simd.h') $simd.Replace('struct dominantTri_s;', 'struct dominantTri_s { int v2, v3; float normalizationScale[3]; };')
$gen = Read-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp')
Write-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp') ($gen -replace '\bregister ', '')
$math = Read-Text (Join-Path $Work 'idlib\math\Math.h')
Write-Text (Join-Path $Work 'idlib\math\Math.h') ([regex]::Replace($math, '#ifdef _WIN32(\r?\n\t_asm \{)', '#if 0$1'))
$fh = Read-Text (Join-Path $Work 'framework\File.h')
Write-Text (Join-Path $Work 'framework\File.h') ($fh.Replace('private:', 'public:'))
$fc = Read-Text (Join-Path $Work 'framework\File.cpp')
$cutBit = $fc.LastIndexOf("/*", $fc.IndexOf("idFile_BitMsg::idFile_BitMsg"))
$cutPerm = $fc.LastIndexOf("/*", $fc.IndexOf("idFile_Permanent::idFile_Permanent"))
$cutZip = $fc.LastIndexOf("/*", $fc.IndexOf("idFile_InZip::idFile_InZip"))
if ($cutBit -lt 0 -or $cutPerm -lt 0 -or $cutZip -lt 0) { throw 'File.cpp layout changed' }
# keep: idFile, idFile_Memory (before BitMsg) and idFile_Permanent (between Permanent and InZip)
$fcNew = $fc.Substring(0, $cutBit) + "`r`n" + $fc.Substring($cutPerm, $cutZip - $cutPerm)
$fcNew = $fcNew.Replace('#include "Unzip.h"', '')
Write-Text (Join-Path $Work 'framework\File.cpp') $fcNew

# CollisionModel_debug.cpp: only the contents names (needed by the .cm writer and reader); the drawing code needs
# the renderer, so its entry points are empty here
$dbg = (Read-Text (Join-Path $Work 'cm\CollisionModel_debug.cpp')) -split "`r?`n"
$dbgNew = ($dbg[0..87] + $dbg[98..144]) -join "`r`n"
$dbgNew += "`r`nvoid idCollisionModelManagerLocal::DebugOutput( const idVec3 &origin ) {}`r`n"
$dbgNew += "void idCollisionModelManagerLocal::DrawModel( cmHandle_t model, const idVec3 &origin, const idMat3 &axis, const idVec3 &viewOrigin, const float radius ) {}`r`n"
Write-Text (Join-Path $Work 'cm\CollisionModel_debug.cpp') $dbgNew

$sources = @(
	'idlib\Heap', 'idlib\Str', 'idlib\Timer','idlib\Lib', 'idlib\Token', 'idlib\Lexer', 'idlib\Dict', 'idlib\MapFile', 'idlib\containers\HashIndex',
	'idlib\hashing\CRC32', 'idlib\math\Math', 'idlib\math\Vector', 'idlib\math\Matrix', 'idlib\math\Angles', 'idlib\math\Quat',
	'idlib\math\Rotation', 'idlib\math\Plane', 'idlib\math\Pluecker', 'idlib\math\Simd_Generic', 'idlib\math\Complex',
	'idlib\math\Polynomial', 'idlib\bv\Bounds', 'idlib\bv\Sphere', 'idlib\bv\Box',
	'idlib\geometry\Winding', 'idlib\geometry\Surface', 'idlib\geometry\Surface_Patch', 'idlib\geometry\DrawVert',
	'idlib\geometry\TraceModel', 'idlib\geometry\JointTransform', 'framework\File',
	'cm\CollisionModel_load', 'cm\CollisionModel_files', 'cm\CollisionModel_debug', 'cm\CollisionModel_translate', 'cm\CollisionModel_rotate',
	'cm\CollisionModel_trace', 'cm\CollisionModel_contents', 'cm\CollisionModel_contacts', 'harness\stubs'
)
$obj = Join-Path $Work 'obj'
New-Item -ItemType Directory -Force $obj | Out-Null
Push-Location $Work
try {
	$failed = $false
	foreach ($s in $sources) {
		$n = Split-Path $s -Leaf
		$out = & $Compiler -c -w -std=c++11 -I. "$s.cpp" -o "obj\$n.o" 2>&1
		if ($LASTEXITCODE -ne 0) { Write-Host "compilation failed: $s"; $out | Where-Object { "$_" -match "error" } | Select-Object -First 12 | ForEach-Object { Write-Host $_ }; $failed = $true; break }
	}
	if ($failed) { throw 'compilation failed' }
	$mainName = [IO.Path]::GetFileNameWithoutExtension($Main)
	$out = & $Compiler -c -w -std=c++11 -I. "harness\$Main" -o "obj\$mainName.o" 2>&1
	if ($LASTEXITCODE -ne 0) { $out | Where-Object { "$_" -match "error" } | Select-Object -First 30 | ForEach-Object { Write-Host $_ }; throw 'compilation failed: main' }
	$out = & $Compiler (Get-ChildItem obj\*.o | ForEach-Object { $_.FullName }) -o harness.exe 2>&1
	if ($LASTEXITCODE -ne 0) { $out | Where-Object { "$_" -notmatch "warning" } | Select-Object -First 60 | ForEach-Object { Write-Host $_ }; throw 'link failed' }
	Write-Host "Harness built: $Work\harness.exe"
} finally {
	Pop-Location
}
