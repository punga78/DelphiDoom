# Issue #255 (Doom 3, idCommon and the event loop): builds and runs the parity harness against the REAL Doom 3 sources.
#
# Reads Reference\doom3\neo (never copies anything into the repository) and works in a scratch folder:
#   idlib\**                 the real idlib (patched as in Tools\Verifica\110: Simd_Generic, Math.h, Parser.cpp, Str.cpp)
#   framework\EventLoop.cpp  the real event loop, unchanged
#   harness\common_extract.inc  the REAL bodies of these functions of framework\Common.cpp, cut out of the source at
#                            build time: BeginRedirect, EndRedirect, CloseLogFile, SetRefreshOnPrint, VPrintf, Printf,
#                            DPrintf, DWarning, Warning, PrintWarnings, ClearWarnings, DumpWarnings, Error, FatalError,
#                            ParseCommandLine, ClearCommandLine, SafeMode, CheckToolMode, StartupVariable,
#                            AddStartupCommands, plus MAX_PRINT_MSG_SIZE, MAX_WARNING_LIST, errorParm_t and the
#                            com_consoleLines block. Common.cpp as a whole is not compiled: it pulls in the engine.
#                            Two patches to the extracted text: the "#ifdef _WIN32" block of VPrintf (a window message
#                            for the editors) and the "#if defined(_WIN32) && !defined(_DEBUG)" block of DumpWarnings
#                            (Notepad) are removed.
# and compiles them with bcc32c (32 bit, x87, -DNDEBUG) together with the files of this folder (precompiled.h,
# common_local.h, harness.cpp: fakes of the engine, see the header of harness.cpp for the scenario and golden formats).
# Every scenario Tests\Data\D3Host\scenarios\<name>.scn runs in its own process and writes
# Tests\Data\D3Host\golden\<name>.golden.txt.
#
# Usage: Tools\Verifica\255\Build-Harness.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario>] [-NoBuild]
param(
	[string]$Reference = 'C:\Progetti\DelphiDoom\Reference',
	[string]$Work = (Join-Path $env:TEMP 'dd255harness'),
	[string]$Compiler = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe',
	[string]$Only = '',
	[switch]$NoBuild
)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$neo = Join-Path $Reference 'doom3\neo'
$data = Join-Path $root 'Tests\Data\D3Host'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)).Replace("`r`n", "`n") }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

function Get-Function($text, $name) {
	$m = [regex]::Match($text, "(?m)^[A-Za-z_][^\n]*?idCommonLocal::$name\(.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found in Common.cpp: $name" }
	return $m.Value
}

$exe = Join-Path $Work 'harness.exe'
if (-not $NoBuild) {
	if (-not (Test-Path (Join-Path $Work 'idlib\Str.cpp'))) {
		New-Item -ItemType Directory -Force $Work | Out-Null
		Copy-Item -Recurse (Join-Path $neo 'idlib') (Join-Path $Work 'idlib')
		New-Item -ItemType Directory -Force (Join-Path $Work 'framework'), (Join-Path $Work 'harness'), (Join-Path $Work 'obj') | Out-Null
		foreach ($f in 'EventLoop.cpp', 'EventLoop.h') { Copy-Item (Join-Path $neo "framework\$f") (Join-Path $Work 'framework') }
		$gen = Read-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp')
		Write-Text (Join-Path $Work 'idlib\math\Simd_Generic.cpp') ($gen -replace '\bregister ', '')
		$math = Read-Text (Join-Path $Work 'idlib\math\Math.h')
		Write-Text (Join-Path $Work 'idlib\math\Math.h') ([regex]::Replace($math, '#ifdef _WIN32(\n\t_asm \{)', '#if 0$1'))
		$par = Read-Text (Join-Path $Work 'idlib\Parser.cpp')
		Write-Text (Join-Path $Work 'idlib\Parser.cpp') ([regex]::Replace($par, "token\[(\d+)\] = '\\0';", '/* $0 */'))
		$str = Read-Text (Join-Path $Work 'idlib\Str.cpp')
		Write-Text (Join-Path $Work 'idlib\Str.cpp') $str.Replace("#define USE_STRING_DATA_ALLOCATOR", "// USE_STRING_DATA_ALLOCATOR off")
	}
	Copy-Item (Join-Path $here 'precompiled.h') (Join-Path $Work 'idlib\precompiled.h') -Force
	Copy-Item (Join-Path $here 'common_local.h') (Join-Path $Work 'harness\common_local.h') -Force
	Copy-Item (Join-Path $here 'harness.cpp') (Join-Path $Work 'harness\harness.cpp') -Force

	# the real functions of Common.cpp
	$common = Read-Text (Join-Path $neo 'framework\Common.cpp')
	$defs = New-Object System.Text.StringBuilder
	foreach ($pattern in '(?m)^#define\s+MAX_PRINT_MSG_SIZE[^\n]*\n', '(?m)^#define\s+MAX_WARNING_LIST[^\n]*\n', '(?s)typedef enum \{\s*ERP_NONE.*?\} errorParm_t;\n') {
		$m = [regex]::Match($common, $pattern)
		if (-not $m.Success) { throw "block not found in Common.cpp: $pattern" }
		[void]$defs.Append($m.Value).Append("`n")
	}
	$header = Read-Text (Join-Path $neo 'framework\Common.h')
	$m = [regex]::Match($header, '(?s)typedef enum \{\s*EDITOR_NONE.*?\} toolFlag_t;\n')
	if (-not $m.Success) { throw 'toolFlag_t not found in Common.h' }
	[void]$defs.Append($m.Value).Append("`n")
	Write-Text (Join-Path $Work 'harness\common_defs.inc') $defs.ToString()

	$inc = New-Object System.Text.StringBuilder
	$m = [regex]::Match($common, '(?m)^#define\s+MAX_CONSOLE_LINES[^\n]*\nint\s+com_numConsoleLines;\nidCmdArgs\s+com_consoleLines\[MAX_CONSOLE_LINES\];\n')
	if (-not $m.Success) { throw 'com_consoleLines block not found in Common.cpp' }
	[void]$inc.Append($m.Value).Append("`n")
	foreach ($name in 'BeginRedirect', 'EndRedirect', 'CloseLogFile', 'SetRefreshOnPrint', 'VPrintf', 'Printf', 'DPrintf', 'DWarning', 'Warning',
		'PrintWarnings', 'ClearWarnings', 'DumpWarnings', 'Error', 'FatalError', 'ParseCommandLine', 'ClearCommandLine', 'SafeMode',
		'CheckToolMode', 'StartupVariable', 'AddStartupCommands') {
		$body = Get-Function $common $name
		$body = [regex]::Replace($body, '(?s)\n#ifdef _WIN32\n.*?\n#endif\n', "`n")
		$body = [regex]::Replace($body, '(?s)\n#if defined\(_WIN32\) && !defined\(_DEBUG\)\n.*?\n#endif\n', "`n")
		[void]$inc.Append($body).Append("`n")
	}
	Write-Text (Join-Path $Work 'harness\common_extract.inc') $inc.ToString()

	$sources = @(
		'idlib\Str', 'idlib\Token', 'idlib\Lexer', 'idlib\Parser', 'idlib\Dict', 'idlib\Heap', 'idlib\Timer', 'idlib\CmdArgs',
		'idlib\math\Math', 'idlib\math\Vector', 'idlib\math\Matrix', 'idlib\math\Angles', 'idlib\math\Quat', 'idlib\math\Rotation',
		'idlib\math\Simd_Generic', 'idlib\math\Plane', 'idlib\math\Pluecker', 'idlib\math\Polynomial', 'idlib\math\Complex',
		'idlib\bv\Bounds', 'idlib\bv\Sphere', 'idlib\hashing\MD4', 'idlib\hashing\CRC32', 'idlib\containers\HashIndex',
		'idlib\geometry\JointTransform',
		'framework\EventLoop', 'harness\harness')
	Push-Location $Work
	try {
		foreach ($s in $sources) {
			$o = 'obj\' + ($s -replace '\\', '_') + '.o'
			if ((Test-Path $o) -and ($s -notmatch '^(framework|harness)\\') -and ($s -ne 'idlib\CmdArgs')) { continue }
			$log = & $Compiler -c -w- -DNDEBUG -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -Iidlib "$s.cpp" -o $o 2>&1
			if ($LASTEXITCODE -ne 0) {
				$log | Select-String 'error' | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
				throw "compilation failed: $s"
			}
		}
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
	& $exe $scn.FullName $golden
	if ($LASTEXITCODE -ne 0) { Write-Host "FAILED $name (exit $LASTEXITCODE)"; continue }
	$n = (Get-Content $golden | Measure-Object -Line).Lines
	$total += $n
	Write-Host ("{0,-28} {1,6} lines" -f $name, $n)
}
Write-Host "Total golden lines: $total"
