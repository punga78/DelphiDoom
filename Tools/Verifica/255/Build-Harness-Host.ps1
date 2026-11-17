# Issue #255 (Doom 3, phases 2a-2c: keys, edit field, usercmd, console, idCommon life cycle): builds and runs the
# second parity harness against the REAL Doom 3 sources.
#
# Reads Reference\doom3\neo (never copies anything into the repository) and works in a scratch folder that
# Build-Harness.ps1 prepared (the idlib objects are shared: run that script first with the same -Work):
#   hostfw\key_extract.inc       the REAL framework\KeyInput.cpp, whole (only the precompiled.h include is removed)
#   hostfw\field_extract.inc     the REAL framework\EditField.cpp without idEditField::Draw (it needs the renderer)
#   hostfw\usercmd_extract.inc   the REAL framework\UsercmdGen.cpp, whole (the Session_local.h include is removed)
#   hostfw\console_extract.inc   the class of framework\Console.cpp, its cvars and the REAL bodies of every function that
#                                is not drawing (Con_Clear_f, Con_Dump_f, Init, Shutdown, Active, ClearNotifyLines,
#                                Close, Clear, Dump, PageUp, PageDown, Top, Bottom, KeyDownEvent, Scroll,
#                                SetDisplayFraction, UpdateDisplayFraction, ProcessEvent, Linefeed, Print)
#   hostfw\common_extract.inc    the REAL bodies of idCommonLocal::Init, Shutdown, InitGame, ShutdownGame, Frame,
#                                GUIFrame, SingleAsyncTic, Async, Quit, with the asyncStats_t block
#   hostfw\sys_enums.h           the enums of sys\sys_public.h that these files use
# and the headers KeyInput.h, EditField.h, UsercmdGen.h, Console.h. It compiles them with bcc32c (32 bit, x87, -DNDEBUG)
# together with the files of this folder (precompiled_host.h, host_common_local.h, harness_host.cpp: fakes of the
# engine, see the header of harness_host.cpp for the scenario and golden formats).
# Every scenario Tests\Data\D3Host\scenarios_host\<name>.scn runs in its own process and writes
# Tests\Data\D3Host\golden_host\<name>.golden.txt.
#
# Usage: Tools\Verifica\255\Build-Harness-Host.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario>] [-NoBuild]
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
if (-not (Test-Path (Join-Path $Work 'obj\idlib_Str.o'))) { throw "run Build-Harness.ps1 -Work $Work first (the idlib objects)" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)).Replace("`r`n", "`n") }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

function Get-Member($text, $class, $name) {
	$m = [regex]::Match($text, "(?m)^[A-Za-z_][^\n]*?$class::$name\(.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found: $class::$name" }
	return $m.Value
}
function Get-Static($text, $name) {
	$m = [regex]::Match($text, "(?m)^static void $name\(.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found: $name" }
	return $m.Value
}

$exe = Join-Path $Work 'harness_host.exe'
if (-not $NoBuild) {
	$fw = Join-Path $Work 'hostfw'; $inc = Join-Path $Work 'hostinc'
	New-Item -ItemType Directory -Force $fw, $inc | Out-Null
	foreach ($h in 'KeyInput.h', 'EditField.h', 'UsercmdGen.h', 'Console.h') { Copy-Item (Join-Path $neo "framework\$h") $fw -Force }
	Copy-Item (Join-Path $here 'precompiled_host.h') (Join-Path $inc 'precompiled.h') -Force
	Copy-Item (Join-Path $here 'host_common_local.h') (Join-Path $Work 'harness\host_common_local.h') -Force
	Copy-Item (Join-Path $here 'harness_host.cpp') (Join-Path $Work 'harness\harness_host.cpp') -Force

	# the enums of sys_public.h
	$sys = Read-Text (Join-Path $neo 'sys\sys_public.h')
	$enums = New-Object System.Text.StringBuilder
	foreach ($pattern in '(?s)typedef enum \{\s*AXIS_SIDE.*?\} joystickAxis_t;\n', '(?s)typedef enum \{\s*SE_NONE.*?\} sysEventType_t;\n', '(?s)typedef enum \{\s*M_ACTION1.*?\} sys_mEvents;\n', '(?s)typedef struct sysEvent_s \{.*?\} sysEvent_t;\n') {
		$m = [regex]::Match($sys, $pattern)
		if (-not $m.Success) { throw "block not found in sys_public.h: $pattern" }
		[void]$enums.Append($m.Value).Append("`n")
	}
	Write-Text (Join-Path $fw 'sys_enums.h') $enums.ToString()

	$pre = '#include "../idlib/precompiled.h"\n#pragma hdrstop\n'
	# KeyInput.cpp, whole
	$t = Read-Text (Join-Path $neo 'framework\KeyInput.cpp')
	Write-Text (Join-Path $fw 'key_extract.inc') ([regex]::Replace($t, '#include "\.\./idlib/precompiled\.h"\n#pragma hdrstop\n', ''))
	# EditField.cpp without Draw
	$t = Read-Text (Join-Path $neo 'framework\EditField.cpp')
	$t = [regex]::Replace($t, '#include "\.\./idlib/precompiled\.h"\n#pragma hdrstop\n', '')
	$i = $t.IndexOf("/*`n===============`nidEditField::Draw")
	if ($i -lt 0) { throw 'idEditField::Draw not found' }
	Write-Text (Join-Path $fw 'field_extract.inc') $t.Substring(0, $i)
	# UsercmdGen.cpp, whole
	$t = Read-Text (Join-Path $neo 'framework\UsercmdGen.cpp')
	$t = [regex]::Replace($t, '#include "\.\./idlib/precompiled\.h"\n#pragma hdrstop\n', '')
	$t = $t.Replace('#include "Session_local.h"', '')
	Write-Text (Join-Path $fw 'usercmd_extract.inc') $t
	# Console.cpp: the class and the cvars, then the bodies
	$t = Read-Text (Join-Path $neo 'framework\Console.cpp')
	$a = $t.IndexOf("#define`tLINE_WIDTH")
	$b = $t.IndexOf("/*`n=============================================================================`n`n`tMisc stats")
	if ($a -lt 0 -or $b -lt 0) { throw 'console class region not found' }
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append($t.Substring($a, $b - $a)).Append("`n")
	foreach ($n in 'Con_Clear_f', 'Con_Dump_f') { [void]$sb.Append((Get-Static $t $n)).Append("`n") }
	foreach ($n in 'Init', 'Shutdown', 'Active', 'ClearNotifyLines', 'Close', 'Clear', 'Dump', 'PageUp', 'PageDown', 'Top', 'Bottom', 'KeyDownEvent', 'Scroll', 'SetDisplayFraction',
		'UpdateDisplayFraction', 'ProcessEvent', 'Linefeed', 'Print') {
		[void]$sb.Append((Get-Member $t 'idConsoleLocal' $n)).Append("`n")
	}
	[void]$sb.Append("void idConsoleLocal::LoadGraphics() {}`nvoid idConsoleLocal::Draw( bool forceFullScreen ) {}`n")
	Write-Text (Join-Path $fw 'console_extract.inc') $sb.ToString()
	# Common.cpp: the life cycle
	$t = Read-Text (Join-Path $neo 'framework\Common.cpp')
	$sb = New-Object System.Text.StringBuilder
	$m = [regex]::Match($t, '(?s)typedef struct \{\s*int\s+milliseconds;.*?int\s+lastTicMsec;\n')
	if (-not $m.Success) { throw 'asyncStats block not found' }
	[void]$sb.Append($m.Value).Append("`n")
	foreach ($n in 'Init', 'Shutdown', 'InitGame', 'ShutdownGame', 'Frame', 'GUIFrame', 'SingleAsyncTic', 'Async', 'Quit') {
		[void]$sb.Append((Get-Member $t 'idCommonLocal' $n)).Append("`n")
	}
	Write-Text (Join-Path $fw 'common_extract.inc') $sb.ToString()

	Push-Location $Work
	try {
		$o = 'obj\harness_harness_host.o'
		$log = & $Compiler -c -w- -DNDEBUG -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -Iidlib 'harness\harness_host.cpp' -o $o 2>&1
		if ($LASTEXITCODE -ne 0) {
			$log | Select-String 'error' | Select-Object -First 25 | ForEach-Object { Write-Host $_.Line }
			throw 'compilation failed: harness_host'
		}
		$objs = @(
			'idlib_Str', 'idlib_Token', 'idlib_Lexer', 'idlib_Parser', 'idlib_Dict', 'idlib_Heap', 'idlib_Timer', 'idlib_CmdArgs',
			'idlib_math_Math', 'idlib_math_Vector', 'idlib_math_Matrix', 'idlib_math_Angles', 'idlib_math_Quat', 'idlib_math_Rotation',
			'idlib_math_Simd_Generic', 'idlib_math_Plane', 'idlib_math_Pluecker', 'idlib_math_Polynomial', 'idlib_math_Complex',
			'idlib_bv_Bounds', 'idlib_bv_Sphere', 'idlib_hashing_MD4', 'idlib_hashing_CRC32', 'idlib_containers_HashIndex',
			'idlib_geometry_JointTransform', 'harness_harness_host') | ForEach-Object { "obj\$_.o" }
		$log = & $Compiler $objs -o harness_host.exe 2>&1
		if ($LASTEXITCODE -ne 0) { $log | Select-Object -First 40 | ForEach-Object { Write-Host $_ }; throw 'link failed' }
	} finally {
		Pop-Location
	}
}

New-Item -ItemType Directory -Force (Join-Path $data 'golden_host') | Out-Null
$total = 0
foreach ($scn in Get-ChildItem (Join-Path $data 'scenarios_host\*.scn') | Sort-Object Name) {
	$name = [IO.Path]::GetFileNameWithoutExtension($scn.Name)
	if ($Only -and ($name -ne $Only)) { continue }
	$golden = Join-Path $data "golden_host\$name.golden.txt"
	& $exe $scn.FullName $golden
	if ($LASTEXITCODE -ne 0) { Write-Host "FAILED $name (exit $LASTEXITCODE)"; continue }
	$n = (Get-Content $golden | Measure-Object -Line).Lines
	$total += $n
	Write-Host ("{0,-28} {1,6} lines" -f $name, $n)
}
Write-Host "Total golden lines: $total"
