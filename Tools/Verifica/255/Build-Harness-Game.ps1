# Issue #255 (Doom 3, phase 3 "the game without a renderer": idClass/idTypeInfo, the entity table of idGameLocal, the
# activity of idEntity): builds and runs the third parity harness against the REAL Doom 3 sources.
#
# Reads Reference\doom3\neo (never copies anything into the repository) and works in a scratch folder that
# Build-Harness.ps1 prepared (the idlib objects are shared: run that script first with the same -Work). It cuts out of the
# source, at build time:
#   gamefw\Class.h, Event.h             the REAL headers of game\gamesys
#   gamefw\event_extract.inc            the REAL bodies of idEventDef::idEventDef, NumEventCommands, GetEventCommand and
#                                       FindEvent (game\gamesys\Event.cpp)
#   gamefw\class_extract.inc            the REAL idTypeInfo and idClass of game\gamesys\Class.cpp (registration, Init,
#                                       Shutdown, GetClass, GetType, CreateInstance, CallSpawn, ListClasses_f, ...)
#   gamefw\game_extract.inc             the REAL bodies of idEntity (GetEntityDefName, SetName, GetName, IsActive,
#                                       BecomeActive, BecomeInactive: the physics-team blocks are cut out) and of
#                                       idGameLocal (RegisterEntity, UnregisterEntity, SpawnEntityType, SpawnEntityDef,
#                                       FindEntityDef, FindEntityDefDict, InhibitEntitySpawn, SpawnMapEntities,
#                                       AddEntityToHash, RemoveEntityFromHash, FindEntity, FindEntityUsingDef, MapPopulate)
#   gamefw\think_extract.inc            the think loop of idGameLocal::RunFrame ("let entities think" to
#                                       "numEntitiesToDeactivate = 0")
# and compiles them with bcc32c (32 bit, x87, -DNDEBUG) together with precompiled_game.h and harness_game.cpp (fakes of the
# engine and the entity classes of the harness, see the header of harness_game.cpp for the scenario and golden formats).
# Every scenario Tests\Data\D3Game\scenarios\<name>.scn runs in its own process and writes
# Tests\Data\D3Game\golden\<name>.golden.txt.
#
# Usage: Tools\Verifica\255\Build-Harness-Game.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario>] [-NoBuild]
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
$data = Join-Path $root 'Tests\Data\D3Game'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }
if (-not (Test-Path (Join-Path $Work 'obj\idlib_Str.o'))) { throw "run Build-Harness.ps1 -Work $Work first (the idlib objects)" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)).Replace("`r`n", "`n") }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }

function Get-Member($text, $class, $name) {
	$m = [regex]::Match($text, "(?m)^(?:[A-Za-z_][^\n]*?)?${class}::${name}\(.*?\n\}\n", 'Singleline')
	if (-not $m.Success) { throw "function not found: ${class}::${name}" }
	return $m.Value
}
function Get-Between($text, $from, $to) {
	$a = $text.IndexOf($from)
	if ($a -lt 0) { throw "start marker not found: $from" }
	$b = $text.IndexOf($to, $a)
	if ($b -lt 0) { throw "end marker not found: $to" }
	return $text.Substring($a, $b - $a)
}

$exe = Join-Path $Work 'harness_game.exe'
if (-not $NoBuild) {
	$fw = Join-Path $Work 'gamefw'; $inc = Join-Path $Work 'gameinc'
	New-Item -ItemType Directory -Force $fw, $inc | Out-Null
	foreach ($h in 'Class.h', 'Event.h') { Copy-Item (Join-Path $neo "game\gamesys\$h") $fw -Force }
	Copy-Item (Join-Path $here 'precompiled_game.h') (Join-Path $inc 'precompiled.h') -Force
	Copy-Item (Join-Path $here 'harness_game.cpp') (Join-Path $Work 'harness\harness_game.cpp') -Force

	# Event.cpp: the event definitions
	$t = Read-Text (Join-Path $neo 'game\gamesys\Event.cpp')
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append("idEventDef *idEventDef::eventDefList[MAX_EVENTS];`nint idEventDef::numEventDefs = 0;`nstatic bool eventError = false;`nstatic char eventErrorMsg[ 128 ];`n")
	foreach ($n in 'idEventDef', 'NumEventCommands', 'GetEventCommand', 'FindEvent') { [void]$sb.Append((Get-Member $t 'idEventDef' $n)).Append("`n") }
	Write-Text (Join-Path $fw 'event_extract.inc') $sb.ToString()

	# Class.cpp: idTypeInfo and idClass
	$t = Read-Text (Join-Path $neo 'game\gamesys\Class.cpp')
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Between $t '// this is the head of a singly linked list' "/*`n================`nidClass::new`n")).Append("`n")
	[void]$sb.Append((Get-Between $t "/*`n================`nidClass::GetClass`n" "/*`n================`nidClass::CancelEvents`n")).Append("`n")
	foreach ($n in 'Event_Remove', 'Event_SafeRemove') { [void]$sb.Append((Get-Member $t 'idClass' $n)).Append("`n") }
	Write-Text (Join-Path $fw 'class_extract.inc') $sb.ToString()

	# Entity.cpp and Game_local.cpp
	$e = Read-Text (Join-Path $neo 'game\Entity.cpp')
	$g = Read-Text (Join-Path $neo 'game\Game_local.cpp')
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append("#define idMapEntity idMapEntityFake`n")
	foreach ($n in 'GetEntityDefName', 'SetName', 'GetName', 'IsActive') { [void]$sb.Append((Get-Member $e 'idEntity' $n)).Append("`n") }
	foreach ($n in 'BecomeActive', 'BecomeInactive') {
		$body = Get-Member $e 'idEntity' $n
		# the physics-team blocks: this harness has no physics and no teams
		$body = [regex]::Replace($body, "(?s)\n\tif \( \( flags & TH_PHYSICS \) \) \{\n.*?\n\t\}\n", "`n")
		[void]$sb.Append($body).Append("`n")
	}
	foreach ($n in 'RegisterEntity', 'UnregisterEntity', 'SpawnEntityType', 'SpawnEntityDef', 'FindEntityDef', 'FindEntityDefDict', 'InhibitEntitySpawn', 'SpawnMapEntities',
		'AddEntityToHash', 'RemoveEntityFromHash', 'FindEntity', 'FindEntityUsingDef', 'MapPopulate') {
		[void]$sb.Append((Get-Member $g 'idGameLocal' $n)).Append("`n")
	}
	Write-Text (Join-Path $fw 'game_extract.inc') $sb.ToString()
	$m = [regex]::Match($g, "(?s)\t\t// let entities think\n.*?numEntitiesToDeactivate = 0;\n\t\t\}\n")
	if (-not $m.Success) { throw 'think loop not found in Game_local.cpp' }
	Write-Text (Join-Path $fw 'think_extract.inc') $m.Value

	Push-Location $Work
	try {
		$o = 'obj\harness_harness_game.o'
		$log = & $Compiler -c -w- -DNDEBUG -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -Iidlib 'harness\harness_game.cpp' -o $o 2>&1
		if ($LASTEXITCODE -ne 0) {
			$log | Select-String 'error' | Select-Object -First 30 | ForEach-Object { Write-Host $_.Line }
			throw 'compilation failed: harness_game'
		}
		$objs = @(
			'idlib_Str', 'idlib_Token', 'idlib_Lexer', 'idlib_Parser', 'idlib_Dict', 'idlib_Heap', 'idlib_Timer', 'idlib_CmdArgs',
			'idlib_math_Math', 'idlib_math_Vector', 'idlib_math_Matrix', 'idlib_math_Angles', 'idlib_math_Quat', 'idlib_math_Rotation',
			'idlib_math_Simd_Generic', 'idlib_math_Plane', 'idlib_math_Pluecker', 'idlib_math_Polynomial', 'idlib_math_Complex',
			'idlib_bv_Bounds', 'idlib_bv_Sphere', 'idlib_hashing_MD4', 'idlib_hashing_CRC32', 'idlib_containers_HashIndex',
			'idlib_geometry_JointTransform', 'harness_harness_game') | ForEach-Object { "obj\$_.o" }
		$log = & $Compiler $objs -o harness_game.exe 2>&1
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
