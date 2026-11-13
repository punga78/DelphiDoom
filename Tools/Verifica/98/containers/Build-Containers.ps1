# Issues #97/#98: builds and runs the parity harness of idList, idStaticList and idHashTable against the REAL
# Doom 3 headers. They are copied from Reference\doom3 into a scratch folder (never into the repository),
# compiled with the g++ of w64devkit together with the stub precompiled.h and main.cpp of this folder, and run.
# The golden is written to Tests\Data\IdLib\lists.golden.txt.
#
# Usage: Tools\Verifica\98\containers\Build-Containers.ps1 [-Reference <path to the main checkout>] [-Work <scratch folder>]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'ddcontainers')
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..\..')).Path
$neo = Join-Path $Reference 'doom3\neo'
$gpp = Join-Path $Reference '_dati\_strumenti\w64devkit\w64devkit\bin\g++.exe'
if (-not (Test-Path $gpp)) { throw "g++ not found: $gpp" }

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force (Join-Path $Work 'idlib\containers') | Out-Null
foreach ($name in 'List.h', 'StaticList.h', 'HashTable.h') {
	Copy-Item (Join-Path $neo "idlib\containers\$name") (Join-Path $Work 'idlib\containers')
}
Copy-Item (Join-Path $here 'precompiled.h') $Work
Copy-Item (Join-Path $here 'main.cpp') $Work

Push-Location $Work
try {
	# NDEBUG: the asserts of the headers are compiled out, as in a release build of the game
	& $gpp -std=c++14 -O1 -w -DNDEBUG -I. -o harness.exe main.cpp
	if ($LASTEXITCODE -ne 0) { throw 'compilation failed' }
	$golden = Join-Path $root 'Tests\Data\IdLib\lists.golden.txt'
	& (Join-Path $Work 'harness.exe') $golden
	if ($LASTEXITCODE -ne 0) { throw "harness failed: $LASTEXITCODE" }
	Write-Host "Golden written: $golden"
} finally {
	Pop-Location
}
