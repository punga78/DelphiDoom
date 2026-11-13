# Issue #96 (id Tech 4 geometry), second slice: builds and runs the parity harnesses against the REAL Doom 3 sources.
#
# The sources of idlib are copied from Reference\doom3 into a scratch folder (never into the repository), a few
# lines are patched in the COPY (listed below), and they are compiled with bcc32c (the clang of RAD Studio, x87)
# together with the stub precompiled.h and the two main files of this folder. Output:
#   Tests\Data\Geometry\surface.golden.txt   DrawVert, JointMat, Winding2D, Surface, Polytope, Patch
#   Tests\Data\Geometry\frustum.golden.txt   Frustum
#
# Patches to the copy (none touches the logic):
#   Lib.h            only the headers the geometry needs (no parser, dict, map file...)
#   Math.h           SinCos and SinCos64 without the MSVC inline assembler (surface harness only: the frustum
#                    golden was written with the fsincos version)
#   Simd.h           the definition of dominantTri_s, which lives in the renderer
#   Simd_Generic.cpp 'register' is not accepted by this compiler
#   Surface.cpp      idSurface::Split and ClipInPlace reserve too few indexes (the front part of a cut tetrahedron
#                    needs 21, the formula gives 18): a heap overflow in the original, +512 here
#   Frustum.h        private members made public so that the harness can print the fields (frustum harness only)
#
# Usage: Tools\Verifica\96\Build-Harness.ps1 [-Reference <path to the main checkout>] [-Work <scratch folder>]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd96harness'),
	[string]$Compiler = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$idlib = Join-Path $Reference 'doom3\neo\idlib'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)) }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

function New-Copy($name) {
	$dir = Join-Path $Work $name
	if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
	New-Item -ItemType Directory -Force $dir | Out-Null
	Copy-Item -Recurse $idlib (Join-Path $dir 'idlib')
	Copy-Item (Join-Path $here 'precompiled.h') (Join-Path $dir 'idlib\precompiled.h')
	# Lib.h: everything up to "// text manipulation", without Ode.h and Lcp.h, then a few containers
	$lib = Read-Text (Join-Path $dir 'idlib\Lib.h')
	$cut = $lib.IndexOf('// text manipulation')
	$head = ($lib.Substring(0, $cut) -split "`r?`n" | Where-Object { $_ -notmatch 'Ode\.h|Lcp\.h' }) -join "`r`n"
	$tail = "#include `"Str.h`"`r`n#include `"containers/HashIndex.h`"`r`n#include `"containers/StaticList.h`"`r`n" +
		"#include `"containers/PlaneSet.h`"`r`n#include `"containers/BinSearch.h`"`r`n#include `"containers/Queue.h`"`r`n`r`n#endif`r`n"
	Write-Text (Join-Path $dir 'idlib\Lib.h') ($head + "`r`n" + $tail)
	$simd = Read-Text (Join-Path $dir 'idlib\math\Simd.h')
	Write-Text (Join-Path $dir 'idlib\math\Simd.h') $simd.Replace('struct dominantTri_s;', 'struct dominantTri_s { int v2, v3; float normalizationScale[3]; };')
	$gen = Read-Text (Join-Path $dir 'idlib\math\Simd_Generic.cpp')
	Write-Text (Join-Path $dir 'idlib\math\Simd_Generic.cpp') ($gen -replace '\bregister ', '')
	return $dir
}

function Build($dir, $sources, $main, $outFile) {
	$obj = Join-Path $dir 'obj'
	New-Item -ItemType Directory -Force $obj | Out-Null
	Push-Location $dir
	try {
		foreach ($s in $sources) {
			$n = Split-Path $s -Leaf
			& $Compiler -c -w -I. "idlib\$s.cpp" -o "obj\$n.o" 2>&1 | Out-Null
			if ($LASTEXITCODE -ne 0) { throw "compilation failed: $s" }
		}
		Copy-Item (Join-Path $here $main) (Join-Path $dir 'main.cpp')
		& $Compiler -c -w -I. main.cpp -o obj\main.o 2>&1 | Out-Null
		if ($LASTEXITCODE -ne 0) { throw 'compilation failed: main' }
		& $Compiler (Get-ChildItem obj\*.o | ForEach-Object { $_.FullName }) -o harness.exe 2>&1 | Out-Null
		if ($LASTEXITCODE -ne 0) { throw 'link failed' }
		New-Item -ItemType Directory -Force (Split-Path $outFile) | Out-Null
		& .\harness.exe $outFile
		if ($LASTEXITCODE -ne 0) { throw "harness failed: $LASTEXITCODE" }
		Write-Host "Golden written: $outFile"
	} finally {
		Pop-Location
	}
}

# surface harness
$dir = New-Copy 'surface'
$math = Read-Text (Join-Path $dir 'idlib\math\Math.h')
Write-Text (Join-Path $dir 'idlib\math\Math.h') ([regex]::Replace($math, '#ifdef _WIN32(\r?\n\t_asm \{)', '#if 0$1'))
$surf = Read-Text (Join-Path $dir 'idlib\geometry\Surface.cpp')
$surf = $surf.Replace('( numEdgeSplitVertexes * 4 ) );', '( numEdgeSplitVertexes * 4 ) + 512 );').Replace('( numEdgeSplitVertexes << 2 ) );', '( numEdgeSplitVertexes << 2 ) + 512 );').Replace('( maxOnPlaneEdges + 1 )', '( maxOnPlaneEdges + 513 )')
Write-Text (Join-Path $dir 'idlib\geometry\Surface.cpp') $surf
Build $dir @('math\Math', 'math\Vector', 'math\Plane', 'math\Pluecker', 'math\Simd_Generic', 'geometry\Winding',
	'geometry\Winding2D', 'geometry\Surface', 'geometry\Surface_Patch', 'geometry\Surface_Polytope',
	'geometry\JointTransform', 'geometry\DrawVert', 'bv\Bounds', 'bv\Sphere', 'bv\Box', 'math\Matrix', 'math\Angles',
	'math\Quat', 'math\Rotation') 'surface-main.cpp' (Join-Path $root 'Tests\Data\Geometry\surface.golden.txt')

# frustum harness
$dir = New-Copy 'frustum'
$fr = Read-Text (Join-Path $dir 'idlib\bv\Frustum.h')
Write-Text (Join-Path $dir 'idlib\bv\Frustum.h') ($fr.Replace('private:', 'public:'))
Build $dir @('math\Angles', 'bv\Bounds', 'bv\Box', 'bv\Frustum', 'math\Math', 'math\Matrix', 'math\Plane', 'math\Pluecker',
	'math\Quat', 'math\Rotation', 'bv\Sphere', 'math\Vector', 'geometry\Winding') 'frustum-main.cpp' (Join-Path $root 'Tests\Data\Geometry\frustum.golden.txt')
