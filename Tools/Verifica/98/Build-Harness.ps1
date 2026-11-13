# Issue #98: builds and runs the parity harness against the REAL Doom 3 sources.
#
# The sources of idBitMsg, idBitMsgDelta, idCompressor and idHashIndex are copied from Reference\doom3 into a
# scratch folder (never into the repository), compiled with the g++ of w64devkit together with the stub
# precompiled.h and main.cpp of this folder, and run. The goldens are written to Tests\Data\Compression\golden.txt
# and Tests\Data\Net\bitmsg-golden.txt.
#
# Usage: Tools\Verifica\98\Build-Harness.ps1 [-Reference <path to the main checkout>] [-Work <scratch folder>]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd98harness')
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$neo = Join-Path $Reference 'doom3\neo'
$gpp = Join-Path $Reference '_dati\_strumenti\w64devkit\w64devkit\bin\g++.exe'
if (-not (Test-Path $gpp)) { throw "g++ not found: $gpp" }

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force (Join-Path $Work 'idlib\containers') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $Work 'framework') | Out-Null

Copy-Item (Join-Path $neo 'idlib\BitMsg.cpp') (Join-Path $Work 'idlib')
Copy-Item (Join-Path $neo 'idlib\BitMsg.h') (Join-Path $Work 'idlib')
Copy-Item (Join-Path $neo 'idlib\containers\HashIndex.cpp') (Join-Path $Work 'idlib\containers')
Copy-Item (Join-Path $neo 'idlib\containers\HashIndex.h') (Join-Path $Work 'idlib\containers')
Copy-Item (Join-Path $neo 'framework\Compressor.cpp') (Join-Path $Work 'framework')
Copy-Item (Join-Path $neo 'framework\Compressor.h') (Join-Path $Work 'framework')
Copy-Item (Join-Path $here 'stub\precompiled.h') (Join-Path $Work 'idlib')
Copy-Item (Join-Path $here 'main.cpp') $Work

# FloatToBits and BitsToFloat of idMath::, copied from Math.cpp
$math = Get-Content (Join-Path $neo 'idlib\math\Math.cpp') -Raw
$out = '#include "idlib/precompiled.h"' + "`n"
foreach ($name in 'int idMath::FloatToBits', 'float idMath::BitsToFloat') {
	$start = $math.IndexOf($name)
	$end = $math.IndexOf("`n}", $start)
	$out += $math.Substring($start, $end - $start + 2) + "`n"
}
Set-Content (Join-Path $Work 'mathfn.inc') $out -Encoding ASCII

$exe = Join-Path $Work 'harness.exe'
$sources = @('main.cpp', 'idlib\BitMsg.cpp', 'idlib\containers\HashIndex.cpp', 'framework\Compressor.cpp')
Push-Location $Work
try {
	& $gpp -std=c++14 -O1 -w -I. -o harness.exe @sources
	if ($LASTEXITCODE -ne 0) { throw 'compilation failed' }
	$compression = Join-Path $root 'Tests\Data\Compression\golden.txt'
	$bitmsg = Join-Path $root 'Tests\Data\Net\bitmsg-golden.txt'
	New-Item -ItemType Directory -Force (Split-Path $compression), (Split-Path $bitmsg) | Out-Null
	& $exe $compression $bitmsg
	if ($LASTEXITCODE -ne 0) { throw "harness failed: $LASTEXITCODE" }
	Write-Host "Goldens written: $compression, $bitmsg"
} finally {
	Pop-Location
}
