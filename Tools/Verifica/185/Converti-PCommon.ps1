<#
  Issue #185 (ondata 11, tornata 185b, voce A13): le routine di IdTech1\Base\p_common.pas diventano metodi statici di
  classi `sealed` della STESSA unit, con lo stesso testo e gli stessi nomi (la tecnica di Converti-Regole.ps1 delle unit
  delle regole), un gruppo per volta. Le routine dichiarate nell'interfaccia vanno in una classe dell'interfaccia
  (T<Gruppo>), quelle che esistono solo nell'implementazione in una classe dell'implementazione (T<Gruppo>Local).
  I chiamanti (le unit delle regole, info, deh_main, a_action, Radix, Speed, i test) che nominano p_common passano a
  Classe.Nome. Restano libere P_ConfigureConsole e P_Console (collegamento della console, dato dal composition root).

  Uso: powershell -NoProfile -File Tools\Verifica\185\Converti-PCommon.ps1 -Group StateBits [-List]
#>
param(
  [Parameter(Mandatory = $true)][string]$Group,
  [switch]$List,
  [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$unit = 'IdTech1\Base\p_common.pas'

function Split-Names([string]$Text) { @($Text -split '\s+' | Where-Object { $_ -ne '' }) }

$groups = [ordered]@{
  # senza testo dipendente dal gioco ({$IF} di gioco): fase 1
  StateBits = @{ Class = 'TCommonStateBitActions'; Names = 'A_SetFrightened A_UnSetFrightened A_SetNoDamage A_UnSetNoDamage A_SetSolid A_UnSetSolid A_SetFloat A_UnSetFloat A_SetFloorBounce A_UnSetFloorBounce A_SetCeilingBounce A_UnSetCeilingBounce A_SetWallBounce A_UnSetWallBounce A_Blocking A_DoNotRunScripts A_DoRunScripts A_SetInteractive A_UnSetInteractive A_SetPainChance A_SetMonsterInfight A_UnSetMonsterInfight A_Missile A_NoMissile A_SetMass A_SetTargetMass A_SetTracerMass A_SetMasterMass A_SetPushFactor A_SetGravity A_SetFriction A_SetHeight A_SetSize A_SetFloatBobPhase' }
  Appearance = @{ Class = 'TCommonAppearanceActions'; Names = 'A_SetTranslucent A_FadeOut Do_FadeOut A_FadeOut10 A_FadeOut20 A_FadeOut30 A_FadeIn Do_FadeIn A_FadeIn10 A_FadeIn20 A_FadeIn30 A_GhostOn A_GhostOff A_GlowLight A_FlipSprite A_RandomFlipSprite A_NoFlipSprite A_RandomNoFlipSprite A_ChangeSpriteFlip A_SetRenderStyle A_FadeTo A_SetScale A_SetSpriteDX A_SetSpriteDY A_SetTranslation A_SetBloodColor' }
  Sound = @{ Class = 'TCommonSoundActions'; Names = 'A_CustomSound1 A_CustomSound2 A_CustomSound3 P_RandomSound A_RandomPainSound A_RandomSeeSound A_RandomAttackSound A_RandomDeathSound A_RandomActiveSound A_RandomRipSound A_RandomCustomSound1 A_RandomCustomSound2 A_RandomCustomSound3 A_RandomCustomSound A_RandomMeleeSound A_Playsound A_PlayWeaponsound A_RandomSound A_StopSound A_WeaponSound' }
  CustomParams = @{ Class = 'TCommonCustomParamActions'; Names = 'A_SetCustomParam A_AddCustomParam A_SubtractCustomParam A_SetTargetCustomParam A_AddTargetCustomParam A_SubtractTargetCustomParam A_SetMasterCustomParam A_AddMasterCustomParam A_SubtractMasterCustomParam A_SetTracerCustomParam A_AddTracerCustomParam A_SubtractTracerCustomParam A_SetMapStr A_SetWorldStr A_SetMapInt A_SetWorldInt A_SetMapFloat A_SetWorldFloat A_SetUserVar A_SetUserArray' }
  Jumps = @{ Class = 'TCommonJumpActions'; Names = 'A_GoTo A_GoToIfCloser A_GoToIfHealthLower A_JumpIf A_JumpIfCustomParam A_JumpIfCustomParamLess A_JumpIfCustomParamGreater A_JumpIfTargetCustomParam A_JumpIfTargetCustomParamLess A_JumpIfTargetCustomParamGreater A_JumpIfMasterCustomParam A_JumpIfMasterCustomParamLess A_JumpIfMasterCustomParamGreater A_JumpIfTracerCustomParam A_JumpIfTracerCustomParamLess A_JumpIfTracerCustomParamGreater A_JumpIfMapStringEqual A_JumpIfMapStringLess A_JumpIfMapStringGreater A_JumpIfMapIntegerEqual A_JumpIfMapIntegerLess A_JumpIfMapIntegerGreater A_JumpIfMapFloatEqual A_JumpIfMapFloatLess A_JumpIfMapFloatGreater A_JumpIfWorldStringEqual A_JumpIfWorldStringLess A_JumpIfWorldStringGreater A_JumpIfWorldIntegerEqual A_JumpIfWorldIntegerLess A_JumpIfWorldIntegerGreater A_JumpIfWorldFloatEqual A_JumpIfWorldFloatLess A_JumpIfWorldFloatGreater A_GoToIfCustomParam A_GoToIfCustomParamLess A_GoToIfCustomParamGreater A_GoToIfTargetCustomParam A_GoToIfTargetCustomParamLess A_GoToIfTargetCustomParamGreater A_GoToIfMasterCustomParam A_GoToIfMasterCustomParamLess A_GoToIfMasterCustomParamGreater A_GoToIfTracerCustomParam A_GoToIfTracerCustomParamLess A_GoToIfTracerCustomParamGreater A_GoToIfMapStringEqual A_GoToIfMapStringLess A_GoToIfMapStringGreater A_GoToIfMapIntegerEqual A_GoToIfMapIntegerLess A_GoToIfMapIntegerGreater A_GoToIfMapFloatEqual A_GoToIfMapFloatLess A_GoToIfMapFloatGreater A_GoToIfWorldStringEqual A_GoToIfWorldStringLess A_GoToIfWorldStringGreater A_GoToIfWorldIntegerEqual A_GoToIfWorldIntegerLess A_GoToIfWorldIntegerGreater A_GoToIfWorldFloatEqual A_GoToIfWorldFloatLess A_GoToIfWorldFloatGreater A_Jump A_RandomJump A_RandomGoto A_JumpIfCloser A_JumpIfHealthLower A_JumpIfTargetOutsideMeleeRange A_JumpIfTargetInsideMeleeRange A_JumpIfTracerCloser A_JumpIfHealthBelow A_JumpIfTargetInSight A_JumpIfTargetCloser A_JumpIfTracerInSight A_JumpIfTracerCloserMBF21 A_JumpIfFlagsSet A_WeaponJump' }
  Movement = @{ Class = 'TCommonMovementActions'; Names = 'A_ThrustZ A_ThrustXY A_Turn A_Turn5 A_Turn10 A_Wander A_Weave A_SetWeaveIndexXY A_SetWeaveIndexZ A_SetWeaveIndexes A_Tracer2 A_ChangeVelocity A_ScaleVelocity A_MatchTargetZ A_TraceNearestPlayer P_ThrustMobj P_FloatSpeed P_FaceMobj P_RandomChaseDir A_Face A_SetAngle A_Recoil A_AdjustSideSpot A_Stop' }
  Search = @{ Class = 'TCommonSearchActions'; Names = 'A_CheckSight A_CheckSightOrRange A_CheckRange A_CheckFloor A_CheckCeiling A_SeekTracer A_FindTracer A_ClearTracer P_RoughTargetSearch RoughBlockCheck P_CheckFov A_AlertMonsters P_RecursiveSoundEx P_NoiseAlertEx A_NoiseAlert A_MonsterRefire P_NearestPlayer A_GlobalEarthQuake A_LocalEarthQuake P_LocalEarthQuake A_WeaponAlert' }
  StateParams = @{ Class = 'TCommonStateParamActions'; Names = 'P_CheckStateParams P_CheckStateArgs A_SetArg A_SetMasterArg A_SetTargetArg A_SetTracerArg A_CountdownArg A_SetSpecial A_SetTics P_TicsFromState A_RearrangePointers A_TransferPointer A_SetDropItem A_SetDefaultDropItem A_TargetDropItem A_DefaultTargetDropItem P_ActorTarget A_LineEffect A_ConsoleCommand P_SetMobjRelativeState' }
  Damage = @{ Class = 'TCommonDamageActions'; Names = 'A_DamageSelf A_DamageTarget A_DamageTracer A_DamageMaster A_KillTarget A_KillTracer A_KillMaster A_KillChildren A_KillSiblings P_DoDamage P_DoRemoveThing A_RemoveTarget A_RemoveTracer A_RemoveMaster A_Remove A_RemoveChildren A_RemoveSiblings P_SetHealth A_ResetHealth A_SetHealth A_ResetTargetHealth A_SetTargetHealth A_RadiusDamage A_PlayerHurtExplode A_ScreamAndUnblock A_HealChase PIT_HealCheck P_HealCorpse A_RaiseMaster A_RaiseChildren A_RaiseSiblings' }
  Spawn = @{ Class = 'TCommonSpawnActions'; Names = 'P_CustomMissile A_CustomMissile A_RandomMissile A_SpawnItem A_SpawnItemEx A_SeekerMissile P_SeekerMissileEx A_Spawn A_SpawnObject A_MonsterProjectile A_WeaponProjectile' }
  Attacks = @{ Class = 'TCommonAttackActions'; Names = 'A_MissileAttack A_Scratch A_CustomMeleeAttack A_CustomComboAttack P_DoAttack A_BasicAttack A_MonsterBulletAttack A_MonsterMeleeAttack A_WeaponBulletAttack P_DoBulletSlope P_BulletSlope' }
  Friends = @{ Class = 'TCommonFriendActions'; Names = 'P_InfightingImmune P_ProjectileImmune P_SplashImmune A_SetProjectileGroup A_SetInfightingGroup A_SetSplashGroup PlayerToId' }
  Flags = @{ Class = 'TCommonFlagActions'; Names = 'A_AddFlags A_RemoveFlags' }
  Weapons = @{ Class = 'TCommonWeaponActions'; Names = 'A_Delayfire A_RefireTo P_SetPspritePtr' }
  # con testo dipendente dal gioco ({$IF} di gioco): fase 2, in una sola classe
  GameDependent = @{ Class = 'TCommonGameDependentActions'; Names = 'InitSpawnedItem A_CStaffMissileSlither A_ChangeFlag A_CheckFlag A_DropItem A_Detonate P_TransferFriendliness P_CopyFriendliness P_RaiseActor A_HealThing A_SetPushable A_UnSetPushable P_CheckFlag P_GetPlayerMeleeRange P_CheckCustomMeleeRange P_ResolveMBF21Flags P_SetMBF21Flags P_UnSetMBF21Flags P_CheckMBF21Flags A_WeaponMeleeAttack A_ConsumeAmmo A_CheckAmmo A_GunFlashTo' }
}

if ($List) {
  # controllo: ogni routine di p_common (salvo le due della console) in uno e un solo gruppo
  $text = [IO.File]::ReadAllText((Join-Path $Root $unit))
  $impl = $text.IndexOf("`nimplementation")
  $seen = @{}
  foreach ($k in $groups.Keys) { foreach ($n in (Split-Names $groups[$k].Names)) { if ($seen.ContainsKey($n)) { Write-Output "DOPPIO $n ($($seen[$n]) e $k)" }; $seen[$n] = $k } }
  $all = [regex]::Matches($text, '(?m)^(?:class\s+)?(?:procedure|function)\s+(?:\w+\.)?(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  foreach ($n in $all) { if (-not $seen.ContainsKey($n) -and $n -ne 'P_ConfigureConsole' -and $n -ne 'P_Console') { Write-Output "SENZA GRUPPO $n" } }
  foreach ($n in $seen.Keys) { if ($all -notcontains $n) { Write-Output "NON ESISTE (gia' convertita?) $n" } }
  return
}

$g = $groups[$Group]
if ($null -eq $g) { throw "Gruppo sconosciuto: $Group" }
$text = [IO.File]::ReadAllText((Join-Path $Root $unit))
$implIndex = $text.IndexOf("`r`nimplementation")
$interfaceText = $text.Substring(0, $implIndex)
$exported = @()
$helpers = @()
foreach ($n in (Split-Names $g.Names)) {
  if ($interfaceText -match ('(?m)^(?:procedure|function)\s+' + $n + '\b')) { $exported += $n } else { $helpers += $n }
}
$converter = Join-Path $PSScriptRoot 'Converti-Regole.ps1'
$callers = 'IdTech1', 'Tests\Source'
if ($exported.Count -gt 0) {
  & powershell -NoProfile -File $converter -Unit $unit -Class $g.Class -Names ($exported -join ',') -CallerDirs ($callers -join ',') -UsersOf p_common -Root $Root
  if ($LASTEXITCODE -ne 0) { throw "Converti-Regole (interfaccia) fallita" }
}
if ($helpers.Count -gt 0) {
  & powershell -NoProfile -File $converter -Unit $unit -Class ($g.Class + 'Local') -Names ($helpers -join ',') -ImplOnly -Root $Root
  if ($LASTEXITCODE -ne 0) { throw "Converti-Regole (implementazione) fallita" }
}
Write-Output ("{0}: {1} nell'interfaccia, {2} nell'implementazione" -f $g.Class, $exported.Count, $helpers.Count)
