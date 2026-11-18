# Issue #255 (Doom 3, phase 3, ondata 12a: the entity classes without renderer, sound and clipping): builds and runs the
# fourth parity harness against the REAL Doom 3 sources.
#
# Reads Reference\doom3\neo (never copies anything into the repository) and works in the scratch folder that Build-Harness.ps1
# prepared (run that script first with the same -Work). Everything below is cut out of the source at build time:
#   world\Trigger.h                the REAL header of the triggers
#   world\entityptr.inc            the REAL idEntityPtr template of Game_local.h
#   world\event_rt.inc             the REAL event queue: idEvent (Alloc, CopyArgs, Free, Schedule, CancelEvents, ServiceEvents, Init)
#                                  and idClass (PostEventArgs, PostEventMS/Sec, ProcessEvent, ProcessEventArgPtr)
#   world\entity.inc               the REAL bodies of idEntity (Hide, Show, targets, ActivateTargets, RunPhysics reduced,
#                                  InitDefaultPhysics, Spawn reduced) and of idGameLocal (GetTargets, RequirementMet)
#   world\physics.inc              the REAL bodies of idPhysics_Parametric (linear motion) and idPhysics::SnapTimeToPhysicsFrame
#   world\trigger.inc              the REAL bodies of idTrigger, idTrigger_Multi, _Timer, _Count, _Hurt, _Fade
#   world\mover.inc                the REAL bodies of idMover_Binary, idDoor and idMover (linear movement)
# and compiles them with bcc32c (32 bit, x87, -DNDEBUG) with harness_world.cpp (fakes of the engine: the entity and physics classes
# are declared there with the members the real bodies use; what the original asks of render, sound, clip and script is a stub that
# does nothing). Scenarios Tests\Data\D3World\scenarios\<name>.scn give Tests\Data\D3World\golden\<name>.golden.txt.
#
# Usage: Tools\Verifica\255\Build-Harness-World.ps1 [-Reference <path>] [-Work <scratch>] [-Only <scenario>] [-NoBuild]
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
$data = Join-Path $root 'Tests\Data\D3World'
if (-not (Test-Path $Compiler)) { throw "bcc32c not found: $Compiler" }
if (-not (Test-Path (Join-Path $Work 'obj\idlib_Str.o'))) { throw "run Build-Harness.ps1 -Work $Work first (the idlib objects)" }

function Read-Text($path) { [IO.File]::ReadAllText($path, [Text.Encoding]::GetEncoding(1252)).Replace("`r`n", "`n") }
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, [Text.Encoding]::GetEncoding(1252)) }
function Get-Member($text, $class, $name) {
	# the line of the definition ends in "{" (the comment above it names the function too)
	$m = [regex]::Match($text, "(?m)^(?:[A-Za-z_][^\n]*?)?$([regex]::Escape($class))::$([regex]::Escape($name))\([^\n]*\{[ \t]*\n.*?\n\}\n", 'Singleline')
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
function Get-Members($text, $class, $names) {
	$sb = New-Object System.Text.StringBuilder
	foreach ($n in $names) { [void]$sb.Append((Get-Member $text $class $n)).Append("`n") }
	return $sb.ToString()
}

$exe = Join-Path $Work 'harness_world.exe'
if (-not $NoBuild) {
	$fw = Join-Path $Work 'gamefw'; $inc = Join-Path $Work 'gameinc'; $w = Join-Path $Work 'world'
	# the game harness builds the shared extracts (gamefw\*.inc) first; it runs no scenario
	& (Join-Path $here 'Build-Harness-Game.ps1') -Reference $Reference -Work $Work -Only '__none__' | Out-Null
	New-Item -ItemType Directory -Force $fw, $inc, $w | Out-Null
	foreach ($h in 'Class.h', 'Event.h') { Copy-Item (Join-Path $neo "game\gamesys\$h") $fw -Force }
	Copy-Item (Join-Path $neo 'game\Trigger.h') $w -Force
	Copy-Item (Join-Path $neo 'game\Mover.h') $w -Force
	# the stub of precompiled.h: the one of the game harness without its idEntityPtr (the real one is cut below) and with the
	# members of trace_t that the real event code reads
	$pre = Read-Text (Join-Path $here 'precompiled_game.h')
	$pre = $pre.Replace('struct trace_s { int fraction; };', 'class idMaterial { public: const char *GetName() const { return "material"; } };' + "`n" + 'struct trace_s { float fraction; struct { const idMaterial *material; int id; int entityNum; } c; };')
	$pre = $pre.Replace('template< class type > class idEntityPtr { public: int spawnId; };', 'template< class type > class idEntityPtr;')
	Write-Text (Join-Path $inc 'precompiled.h') $pre
	Copy-Item (Join-Path $here 'harness_world.cpp') (Join-Path $Work 'harness\harness_world.cpp') -Force

	$ev = Read-Text (Join-Path $neo 'game\gamesys\Event.cpp')
	$cl = Read-Text (Join-Path $neo 'game\gamesys\Class.cpp')
	$en = Read-Text (Join-Path $neo 'game\Entity.cpp')
	$gl = Read-Text (Join-Path $neo 'game\Game_local.cpp')
	$gh = Read-Text (Join-Path $neo 'game\Game_local.h')
	$tr = Read-Text (Join-Path $neo 'game\Trigger.cpp')
	$mv = Read-Text (Join-Path $neo 'game\Mover.cpp')
	$ph = Read-Text (Join-Path $neo 'game\physics\Physics_Parametric.cpp')
	$ps = Read-Text (Join-Path $neo 'game\physics\Physics.cpp')
	$phh = Read-Text (Join-Path $neo 'game\physics\Physics_Parametric.h')

	# idEntityPtr, the template of Game_local.h without the save game members (the save game classes are not here)
	$m = [regex]::Match($gh, '(?s)template< class type >\nclass idEntityPtr \{.*?\n\};\n')
	if (-not $m.Success) { throw 'idEntityPtr class not found' }
	Write-Text (Join-Path $w 'entityptr_class.inc') $m.Value
	$p = Get-Between $gh "template< class type >`nID_INLINE idEntityPtr<type>::idEntityPtr() {" "//============================================================================`n`nclass idGameError"
	$p = [regex]::Replace($p, "(?s)template< class type >\nID_INLINE void idEntityPtr<type>::(Save|Restore)\(.*?\n\}\n\n", '')
	Write-Text (Join-Path $w 'entityptr_impl.inc') $p
	# the state of the parametric physics
	$m = [regex]::Match($phh, '(?s)typedef struct parametricPState_s \{.*?\} parametricPState_t;')
	if (-not $m.Success) { throw 'parametricPState_t not found' }
	Write-Text (Join-Path $w 'pstate.inc') $m.Value

	# the event queue
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append("static idLinkList<idEvent> FreeEvents;`nstatic idLinkList<idEvent> EventQueue;`nstatic idEvent EventPool[ MAX_EVENTS ];`nbool idEvent::initialized = false;`nidDynamicBlockAlloc<byte, 16 * 1024, 256> idEvent::eventDataAllocator;`n")
	foreach ($n in '~idEvent', 'Alloc', 'CopyArgs', 'Free', 'Schedule', 'CancelEvents', 'ClearEventList', 'ServiceEvents', 'Init') { [void]$sb.Append((Get-Member $ev 'idEvent' $n)).Append("`n") }
	$rt = Get-Between $cl "/*`n================`nidClass::CancelEvents`n" "/*`n================`nidClass::Event_Remove`n"
	$rt = $rt.Replace('gameLocal.isClient && ( gameLocal.GameState() != GAMESTATE_STARTUP ) && !IsType( idThread::Type )', 'false')
	[void]$sb.Append($rt)
	Write-Text (Join-Path $w 'event_rt.inc') $sb.ToString()

	# the names, the activity and the table of the entities (the same real bodies as the game harness, without the map and the cinematic)
	$sb = New-Object System.Text.StringBuilder
	foreach ($n in 'GetEntityDefName', 'SetName', 'GetName', 'IsActive') { [void]$sb.Append((Get-Member $en 'idEntity' $n)).Append("`n") }
	foreach ($n in 'BecomeActive', 'BecomeInactive') {
		$body = Get-Member $en 'idEntity' $n
		# the physics-team blocks: there are no teams here
		$body = [regex]::Replace($body, "(?s)\n\tif \( \( flags & TH_PHYSICS \) \) \{\n.*?\n\t\}\n", "`n")
		[void]$sb.Append($body).Append("`n")
	}
	[void]$sb.Append((Get-Members $gl 'idGameLocal' @('RegisterEntity', 'UnregisterEntity', 'SpawnEntityDef', 'FindEntityDef', 'AddEntityToHash', 'RemoveEntityFromHash', 'FindEntity')))
	Write-Text (Join-Path $w 'game2.inc') $sb.ToString()
	# the constructor and the destructor of the entity of the game harness (the statements of the real ones that this phase ports)
	$er = Read-Text (Join-Path $fw 'entity_reduced.inc')
	Write-Text (Join-Path $w 'entity_ctor.inc') $er.Substring(0, $er.IndexOf('void idEntity::Spawn( void ) {'))

	# the event definitions of Entity.cpp
	$evdefs = New-Object System.Text.StringBuilder
	foreach ($mm in [regex]::Matches($en, '(?m)^const idEventDef \w+\(.*\);\n')) { [void]$evdefs.Append($mm.Value) }
	Write-Text (Join-Path $w 'entity_events.inc') $evdefs.ToString()

	# idEntity and idGameLocal
	$sb = New-Object System.Text.StringBuilder
	foreach ($n in 'Think', 'IsHidden', 'Hide', 'Show', 'FindTargets', 'RemoveNullTargets', 'InitDefaultPhysics', 'GetLocalCoordinates', 'GetWorldVector',
		'Event_FindTargets', 'Event_ActivateTargets', 'Event_Hide', 'Event_Show') { [void]$sb.Append((Get-Member $en 'idEntity' $n)).Append("`n") }
	$act = Get-Member $en 'idEntity' 'ActivateTargets'
	# the gui triggers of the target: there is no render entity here
	$act = [regex]::Replace($act, "(?s)\t\tfor \( j = 0; j < MAX_RENDERENTITY_GUI; j\+\+ \) \{.*?\n\t\t\}\n", '')
	[void]$sb.Append($act).Append("`n")
	[void]$sb.Append((Get-Members $gl 'idGameLocal' @('GetTargets', 'RequirementMet')))
	Write-Text (Join-Path $w 'entity.inc') $sb.ToString()
	# idEntity::Spawn reduced to the statements this phase ports (cut from the real function, in order)
	$spawn = Get-Member $en 'idEntity' 'Spawn'
	function Get-Match($text, $pattern, $what) {
		$m = [regex]::Match($text, $pattern, 'Singleline')
		if (-not $m.Success) { throw "not found in Entity.cpp: $what" }
		return $m.Value
	}
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Match $spawn '\tgameLocal\.RegisterEntity\( this \);.*?\n\t\}\n' 'RegisterEntity to the entityDef')).Append("`n")
	[void]$sb.Append((Get-Match $spawn '\tfl\.hidden = [^\n]*\n\tif \( fl\.hidden \) \{.*?\n\t\}\n' 'hidden')).Append("`n")
	[void]$sb.Append((Get-Match $spawn '\tcinematic = [^\n]*\n' 'cinematic')).Append("`n")
	[void]$sb.Append((Get-Match $spawn '\t// every object will have a unique name\n.*?\tSetName\( temp \);\n' 'the name')).Append("`n")
	[void]$sb.Append((Get-Match $spawn '\t// if we have targets, wait until all entities are spawned to get them\n.*?\n\t\}\n\n' 'targets')).Append("`n")
	[void]$sb.Append((Get-Match $spawn '\thealth = [^\n]*\n' 'health')).Append("`n")
	# idEntity::ParseSpawnArgsToRenderEntity (the origin) comes after RegisterEntity has given the entity its spawn arguments
	[void]$sb.Append("`tspawnArgs.GetVector( `"origin`", `"0 0 0`", origin );`n`taxis.Identity();`n")
	[void]$sb.Append("`tInitDefaultPhysics( origin, axis );`n")
	Write-Text (Join-Path $w 'spawn.inc') $sb.ToString()
	# RunPhysics reduced: no team, no push, no network (the statements are the real ones)
	$run = Get-Member $en 'idEntity' 'RunPhysics'
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Match $run '\t// don.t run physics if not enabled\n.*?\n\t\}\n' 'physics enabled')).Append("`n")
	[void]$sb.Append((Get-Match $run '\tstartTime = gameLocal\.previousTime;\n\tendTime = gameLocal\.time;\n' 'times')).Append("`n")
	$ev1 = (Get-Match $run '\t\t\t// run physics\n\t\t\tmoved = part->physics->Evaluate\([^\n]*\n' 'evaluate').Replace('part->physics', 'physics').Replace("`t`t`t", "`t")
	[void]$sb.Append($ev1).Append("`n")
	$rp = Get-Match $run '\t// post reached event if the current time is at or past the end point of the motion\n.*?\n\t\}\n\n\treturn true;\n' 'reached'
	$rp = $rp.Replace('part->physics', 'physics').Replace('part->ProcessEvent', 'ProcessEvent')
	$rp = [regex]::Replace($rp, "\tfor \( part = this; part != NULL; part = part->teamChain \) \{\n+\t\tif \( physics \) \{\n", "`t{`n`t`tif ( physics ) {`n")
	[void]$sb.Append($rp)
	Write-Text (Join-Path $w 'runphysics.inc') $sb.ToString()

	# the parametric physics: the linear path and the accessors the movers use
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Members $ph 'idPhysics_Parametric' @('Activate', 'TestIfAtRest', 'Rest', 'idPhysics_Parametric', '~idPhysics_Parametric', 'SetPusher', 'IsPusher', 'SetLinearExtrapolation',
		'SetAngularExtrapolation', 'GetLinearExtrapolationType', 'GetAngularExtrapolationType', 'SetLinearInterpolation', 'SetAngularInterpolation', 'GetLocalOrigin', 'GetLocalAngles',
		'SetClipModel', 'GetClipModel', 'SetContents', 'GetContents', 'GetBounds', 'GetAbsBounds', 'Evaluate', 'UpdateTime', 'GetTime', 'IsAtRest', 'SaveState', 'RestoreState', 'SetOrigin',
		'SetAxis', 'GetOrigin', 'GetAxis', 'DisableClip', 'EnableClip', 'GetBlockingEntity', 'GetLinearEndTime', 'GetAngularEndTime')))
	[void]$sb.Append((Get-Member $ps 'idPhysics' 'SnapTimeToPhysicsFrame')).Append("`n")
	Write-Text (Join-Path $w 'physics.inc') $sb.ToString()

	# the triggers (no Save and Restore: the save game classes are not here; no DrawDebugInfo, EntityName and Touch)
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Members $tr 'idTrigger' @('Enable', 'Disable', 'CallScript', 'GetScriptFunction', 'Event_Enable', 'Event_Disable', 'idTrigger', 'Spawn')))
	[void]$sb.Append((Get-Members $tr 'idTrigger_Multi' @('idTrigger_Multi', 'Spawn', 'CheckFacing', 'TriggerAction', 'Event_TriggerAction', 'Event_Trigger', 'Event_Touch')))
	[void]$sb.Append((Get-Members $tr 'idTrigger_Timer' @('idTrigger_Timer', 'Spawn', 'Enable', 'Disable', 'Event_Timer', 'Event_Use')))
	[void]$sb.Append((Get-Members $tr 'idTrigger_Count' @('idTrigger_Count', 'Spawn', 'Event_Trigger', 'Event_TriggerAction')))
	[void]$sb.Append((Get-Members $tr 'idTrigger_Hurt' @('idTrigger_Hurt', 'Spawn', 'Event_Touch', 'Event_Toggle')))
	[void]$sb.Append((Get-Members $tr 'idTrigger_Fade' @('Event_Trigger')))
	Write-Text (Join-Path $w 'trigger.inc') $sb.ToString()
	$m = [regex]::Match($tr, '(?s)const idEventDef EV_Enable\(.*?\nEND_CLASS\n')
	$decl = ($tr -split "(?m)^CLASS_DECLARATION")[0]
	$evdefs = New-Object System.Text.StringBuilder
	foreach ($mm in [regex]::Matches($tr, '(?m)^const idEventDef \w+\(.*\);\n')) { [void]$evdefs.Append($mm.Value) }
	foreach ($mm in [regex]::Matches($tr, '(?s)(CLASS_DECLARATION\( idEntity, idTrigger \).*?END_CLASS\n|CLASS_DECLARATION\( idTrigger, idTrigger_(Multi|Timer|Count|Hurt|Fade) \).*?END_CLASS\n)')) { [void]$evdefs.Append($mm.Value) }
	Write-Text (Join-Path $w 'trigger_decl.inc') $evdefs.ToString()

	# the movers: whole bodies, the event lines of the classes of the harness are written in harness_world.cpp
	$sb = New-Object System.Text.StringBuilder
	[void]$sb.Append((Get-Members $mv 'idMover_Binary' @('idMover_Binary', '~idMover_Binary', 'Spawn', 'GetMovedir', 'Event_SetCallback', 'UpdateMoverSound', 'SetMoverState', 'MatchActivateTeam',
		'Enable', 'Event_MatchActivateTeam', 'JoinActivateTeam', 'Event_Enable', 'Event_Disable', 'Event_ReturnToPos1', 'Event_Reached_BinaryMover', 'GotoPosition1', 'GotoPosition2',
		'UpdateBuddies', 'SetGuiStates', 'Use_BinaryMover', 'Event_Use_BinaryMover', 'InitSpeed', 'InitTime', 'SetBlocked', 'IsBlocked', 'GetActivator')))
	[void]$sb.Append((Get-Members $mv 'idDoor' @('idDoor', '~idDoor', 'Think', 'Spawn', 'Open', 'Close', 'Lock', 'IsLocked', 'IsOpen', 'IsNoTouch', 'CalcTriggerBounds', 'Event_StartOpen', 'Event_SpawnDoorTrigger',
		'Event_Reached_BinaryMover', 'Event_Activate', 'Event_Open', 'Event_Close', 'Event_Lock', 'Event_IsOpen', 'Event_Locked')))
	[void]$sb.Append((Get-Members $mv 'idMover' @('idMover', 'Spawn', 'Event_SetCallback', 'Event_StopMoving', 'DoneMoving', 'UpdateMoveSound', 'Event_UpdateMove', 'BeginMove', 'Event_SetMoveSpeed',
		'Event_SetMoveTime', 'Event_SetAccellerationTime', 'Event_SetDecelerationTime', 'Event_MoveTo', 'MoveToPos', 'Event_MoveToPos', 'VectorForDir', 'Event_MoveDir', 'Event_IsMoving')))
	Write-Text (Join-Path $w 'mover.inc') $sb.ToString()
	$evdefs = New-Object System.Text.StringBuilder
	foreach ($mm in [regex]::Matches($mv, '(?m)^const idEventDef \w+\(.*\);\n')) { [void]$evdefs.Append($mm.Value) }
	Write-Text (Join-Path $w 'mover_events.inc') $evdefs.ToString()

	Push-Location $Work
	try {
		$o = 'obj\harness_harness_world.o'
		$log = & $Compiler -c -w- -DNDEBUG -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -Iidlib 'harness\harness_world.cpp' -o $o 2>&1
		if ($LASTEXITCODE -ne 0) {
			$log | Select-String 'error' | Select-Object -First 40 | ForEach-Object { Write-Host $_.Line }
			throw 'compilation failed: harness_world'
		}
		$objs = @(
			'idlib_Str', 'idlib_Token', 'idlib_Lexer', 'idlib_Parser', 'idlib_Dict', 'idlib_Heap', 'idlib_Timer', 'idlib_CmdArgs',
			'idlib_math_Math', 'idlib_math_Vector', 'idlib_math_Matrix', 'idlib_math_Angles', 'idlib_math_Quat', 'idlib_math_Rotation',
			'idlib_math_Simd_Generic', 'idlib_math_Plane', 'idlib_math_Pluecker', 'idlib_math_Polynomial', 'idlib_math_Complex',
			'idlib_bv_Bounds', 'idlib_bv_Sphere', 'idlib_hashing_MD4', 'idlib_hashing_CRC32', 'idlib_containers_HashIndex',
			'idlib_geometry_JointTransform', 'harness_harness_world') | ForEach-Object { "obj\$_.o" }
		$log = & $Compiler $objs -o harness_world.exe 2>&1
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
