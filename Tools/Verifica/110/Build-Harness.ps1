# Issue #110 (id Tech 4 script: compiler and virtual machine): builds and runs the parity harness against the REAL
# Doom 3 sources.
#
# The sources are copied from Reference\doom3\neo into a scratch folder (never into the repository):
#   idlib\**                         the real idlib
#   game\script\Script_*.cpp/.h      compiler, program, interpreter, thread
#   game\gamesys\Event.cpp/.h, Class.cpp/.h   events and classes
# and compiled with bcc32c (the clang of RAD Studio, 32 bit, x87, -DNDEBUG: assertions removed as in a release
# build) together with the files of this folder, written for this repository:
#   precompiled.h    replaces idlib\precompiled.h (common, sys, file system; "#define private public" so that the
#                    driver can print the private state)
#   Game_local.h     the fake game (gameLocal, cvars, save game on a buffer, fake entities)
#   main.cpp         the scenario driver; its header comment is the specification of the commands, of the golden
#                    format, of the fake entities and of the host stubs
# Every scenario Tests\Data\DoomScript\scenarios\<name>.scn runs in its own process, with
# Tests\Data\DoomScript\scripts as the root of the fake file system, and writes
# Tests\Data\DoomScript\golden\<name>.golden.txt.
#
# Patches to the copy (none touches the logic of scripts and events):
#   Simd_Generic.cpp  'register' is not accepted by this compiler
#   Math.h            SinCos and SinCos64 without the MSVC inline assembler
#   Parser.cpp        the three lines "token[N] = '\0';" of __DATE__ and __TIME__ do not compile: commented out
#   Str.cpp           the block allocator of the strings (stringDataAllocator) is turned off: it crashes without the
#                     memory system of the engine; the strings use new and delete
#   Event.cpp         one function appended, harnessEventQueue(), that returns the file static EventQueue so that
#                     the driver can print the queue
#   Script_Thread.cpp, Script_Interpreter.cpp, Script_Compiler.cpp, Script_Program.cpp, Class.cpp: none
#
# Usage: Tools\Verifica\110\Build-Harness.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario name>] [-NoBuild]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd110harness'),
	[string]$Compiler = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe',
	[string]$Only = '',
	[switch]$NoBuild
)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$neo = Join-Path $Reference 'doom3\neo'
$data = Join-Path $root 'Tests\Data\DoomScript'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)) }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

$exe = Join-Path $Work 'harness.exe'
if (-not $NoBuild) {
	if (-not (Test-Path (Join-Path $Work 'idlib\Str.cpp'))) {
		New-Item -ItemType Directory -Force $Work | Out-Null
		Copy-Item -Recurse (Join-Path $neo 'idlib') (Join-Path $Work 'idlib')
		New-Item -ItemType Directory -Force (Join-Path $Work 'game\script'), (Join-Path $Work 'game\gamesys'), (Join-Path $Work 'harness'), (Join-Path $Work 'obj') | Out-Null
		Copy-Item (Join-Path $neo 'game\script\Script_*') (Join-Path $Work 'game\script')
		foreach ($f in 'Event.cpp', 'Event.h', 'Class.cpp', 'Class.h') { Copy-Item (Join-Path $neo "game\gamesys\$f") (Join-Path $Work 'game\gamesys') }
		$gen = Read-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp')
		Write-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp') ($gen -replace '\bregister ', '')
		$math = Read-Text (Join-Path $Work 'idlib\math\Math.h')
		Write-Text (Join-Path $Work 'idlib\math\Math.h') ([regex]::Replace($math, '#ifdef _WIN32(\r?\n\t_asm \{)', '#if 0$1'))
		$par = Read-Text (Join-Path $Work 'idlib\Parser.cpp')
		Write-Text (Join-Path $Work 'idlib\Parser.cpp') ([regex]::Replace($par, "token\[(\d+)\] = '\\0';", '/* $0 */'))
		$str = Read-Text (Join-Path $Work 'idlib\Str.cpp')
		Write-Text (Join-Path $Work 'idlib\Str.cpp') $str.Replace("#define USE_STRING_DATA_ALLOCATOR", "// USE_STRING_DATA_ALLOCATOR off")
		$ev = Read-Text (Join-Path $Work 'game\gamesys\Event.cpp')
		Write-Text (Join-Path $Work 'game\gamesys\Event.cpp') ($ev + "`r`nidLinkList<idEvent> &harnessEventQueue( void ) { return EventQueue; }`r`n")
	}
	Copy-Item (Join-Path $here 'precompiled.h') (Join-Path $Work 'idlib\precompiled.h') -Force
	Copy-Item (Join-Path $here 'Game_local.h') (Join-Path $Work 'game\Game_local.h') -Force
	Copy-Item (Join-Path $here 'main.cpp') (Join-Path $Work 'harness\main.cpp') -Force

	$sources = @(
		'idlib\Str', 'idlib\Token', 'idlib\Lexer', 'idlib\Parser', 'idlib\Dict', 'idlib\Heap', 'idlib\Timer',
		'idlib\math\Math', 'idlib\math\Vector', 'idlib\math\Matrix', 'idlib\math\Angles', 'idlib\math\Quat', 'idlib\math\Rotation',
		'idlib\math\Simd_Generic', 'idlib\math\Plane', 'idlib\math\Pluecker', 'idlib\math\Polynomial', 'idlib\math\Complex',
		'idlib\bv\Bounds', 'idlib\bv\Sphere', 'idlib\hashing\MD4', 'idlib\hashing\CRC32', 'idlib\containers\HashIndex',
		'idlib\geometry\JointTransform',
		'game\script\Script_Compiler', 'game\script\Script_Program', 'game\script\Script_Interpreter', 'game\script\Script_Thread',
		'game\gamesys\Event', 'game\gamesys\Class', 'harness\main')
	Push-Location $Work
	try {
		foreach ($s in $sources) {
			$o = 'obj\' + ($s -replace '\\', '_') + '.o'
			$src = "$s.cpp"
			if ((Test-Path $o) -and ($s -notmatch '^(game|harness)\\') ) { continue }
			$log = & $Compiler -c -w- -DNDEBUG -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -Iidlib $src -o $o 2>&1
			if ($LASTEXITCODE -ne 0) {
				$log | Select-String 'error' | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
				throw "compilation failed: $s"
			}
		}
		# link order = order of static construction: idlib (idStr, the heap) before the game
		$log = & $Compiler ($sources | ForEach-Object { 'obj\' + ($_ -replace '\\', '_') + '.o' }) -o harness.exe 2>&1
		if ($LASTEXITCODE -ne 0) { $log | Select-Object -First 40 | ForEach-Object { Write-Host $_ }; throw 'link failed' }
	} finally {
		Pop-Location
	}
}

New-Item -ItemType Directory -Force (Join-Path $data 'golden') | Out-Null
$total = 0
foreach ($scn in Get-ChildItem (Join-Path $data 'scenarios\*.scn') | Sort-Object Name) {
	$name = [IO.Path]::GetFileNameWithoutExtension($scn.Name)
	if ($Only -and ($name -ne $Only)) { continue }
	$golden = Join-Path $data "golden\$name.golden.txt"
	& $exe (Join-Path $data 'scripts') $scn.FullName $golden
	if ($LASTEXITCODE -ne 0) { Write-Host "FAILED $name (exit $LASTEXITCODE)"; continue }
	$n = (Get-Content $golden | Measure-Object -Line).Lines
	$total += $n
	Write-Host ("{0,-28} {1,6} lines" -f $name, $n)
}
Write-Host "Total golden lines: $total"
