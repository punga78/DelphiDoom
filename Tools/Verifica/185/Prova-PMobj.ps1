<#
  Issue #185, passo 2c-2 (p_mobj in copia unica): prova meccanica delle routine parametriche.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_mobj.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_mobj.pas o la unit delle regole del gioco), sostituisce ogni
  chiamata a TMobjGameRules (e alle tre regole riusate di TMapGameRules) con il corpo della regola di quel gioco
  (le sostituzioni sono la tabella $Expansions qui sotto, scritta a mano; i corpi lunghi si leggono dalla unit
  del gioco con <<B:Metodo>>) e confronta il risultato con la routine vecchia, tolti commenti, spazi e maiuscole.
  Le routine che sono tutte di un gioco sono metodi delle regole ($Methods): il loro testo deve essere quello
  vecchio con la sola intestazione cambiata.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PMobj.ps1 [-Base d1852422] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = 'd1852422',
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife')
)
$ErrorActionPreference = 'Stop'
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

. (Join-Path $PSScriptRoot 'Prova-Common.ps1')

# pezzi di testo che tornano in piu' sostituzioni
$tics = 'th.tics := th.tics - (P_Random and 3); if th.tics < 1 then th.tics := 1;'
$half = 'ptryx := mo.x + xmove div 2; ptryy := mo.y + ymove div 2; xmove := _SHR1(xmove); ymove := _SHR1(ymove);'
$forbidden = 'if (gamestate <> GS_LEVEL) or demoplayback or demorecording or netgame then'
$setstate = 'if not P_SetMobjState(mobj, mobj.state.nextstate) then exit;'
$slope = 'if G_PlayingEngineVersion <= VERSION203 then exit; if wasonfloorz and wasonslope and (oldsector = Psubsector_t(mo.subsector).sector) then begin if oldsector.flags and SF_SLIPSLOPEDESCENT <> 0 then exit; mo.z := mo.floorz; end else exit;'
$respawn = 'if mobj.flags and MF_COUNTKILL = 0 then exit; if not respawnmonsters then exit; mobj.movecount := mobj.movecount + 1; if mobj.movecount < TMobjGameRules.RespawnTime then exit; if leveltime and 31 <> 0 then exit; if P_Random > 4 then exit; if TMobjGameRules.NeverRespawns(mobj) then exit; TMobjGameRules.NightmareRespawn(mobj);'
$infoMid = 'mobj.flags5_ex := info.flags5_ex; mobj.flags6_ex := info.flags6_ex; mobj.scale := info.scale; mobj.gravity := info.gravity; mobj.pushfactor := info.pushfactor; mobj.friction := info.friction;'
$stInit = 'mobj.state := st; mobj.tics := P_TicsFromState(st); mobj.sprite := st.sprite; mobj.frame := st.frame;'
function SpawnHeight([string]$i, [string]$middle) {
  "if mobjinfo[$i].flags and MF_SPAWNCEILING <> 0 then z := ONCEILINGZ $middle else z := ONFLOORZ;"
}
function FloatEx([string]$i) { "else if mobjinfo[$i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then z := ONFLOATZ" }
$oneread = 'la vecchia copia teneva il sottosettore e ne leggeva il campo sector: la copia unica legge il settore una volta (TMapGameRules.PointInSector, gia'' di p_map)'
$nonnil = 'Hexen controllava che P_SpawnMobj non desse nil: non lo da'' mai (Z_Malloc ferma il gioco se manca la memoria)'

# ---------------------------------------------------------------------------------------------------------------
# Le sostituzioni (vedi Prova-Common.ps1). L'ordine conta: le voci di un gioco solo vengono prima di quelle di tutti.
# ---------------------------------------------------------------------------------------------------------------
$Expansions = @(
  # --- P_SetMobjState (Doom: P_DoSetMobjState) ---
  @{ R = 'P_SetMobjState'; F = 'function P_DoSetMobjState(mobj: Pmobj_t; state: statenum_t; const runthinker: boolean): boolean;'
     Heretic = 'function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;'; Hexen = 'function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;'; Strife = 'function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;'
     Note = 'la copia unica e'' P_DoSetMobjState di Doom (con il parametro runthinker) chiamata da P_SetMobjState con true: una chiamata in piu'', stesso effetto' }
  @{ R = 'P_SetMobjState'; F = 'if Assigned(st.action.acp1) and runthinker then'; Heretic = 'if Assigned(st.action.acp1) then'; Hexen = 'if Assigned(st.action.acp1) then'; Strife = 'if Assigned(st.action.acp1) then'; Note = 'come sopra (runthinker e'' true)' }
  @{ F = 'TMobjGameRules.KeepPreviousState(mobj);'; D = 'if mobj.validcount <> validcount then begin mobj.validcount := validcount; mobj.prevstate := mobj.state; end;'
     Heretic = 'mobj.prevstate := mobj.state;'; Hexen = '' }
  @{ R = 'P_SetMobjStateNF'; F = 'result := TMobjGameRules.SetMobjStateNF(mobj, state);'; Doom = 'result := P_DoSetMobjState(mobj, state, false);' }

  # --- P_ExplodeMissile ---
  @{ F = 'TMobjGameRules.DeathState(mo)'; D = 'statenum_t(mobjinfo[Ord(mo._type)].deathstate)'; Doom = 'statenum_t(mo.info.deathstate)' }
  @{ F = 'TMobjGameRules.RandomizeExplosionTics(mo);'; D = 'mo.tics := mo.tics - (P_Random and 3); if mo.tics < 1 then mo.tics := 1;'; Hexen = ''; Strife = 'if mo.tics < 1 then mo.tics := 1;' }
  @{ F = 'TMobjGameRules.ExplosionSound(mo);'; D = '<<B:ExplosionSound>>' }

  # --- P_RemoveMobj ---
  @{ R = 'P_RemoveMobj'; F = 'procedure P_RemoveMobj(mobj: Pmobj_t); begin'; Strife = 'procedure P_RemoveMobj(mobj: Pmobj_t); var <<V:BeforeRemove>> begin' }
  @{ F = 'TMobjGameRules.BeforeRemove(mobj);'; D = '<<B:BeforeRemove>>' }
  @{ F = 'TMobjGameRules.ReleaseSectorList;'; D = 'if sector_list <> nil then while sector_list <> nil do sector_list := P_DelSecnode(sector_list);'; Heretic = ''; Hexen = '' }

  # --- P_RespawnSpecials ---
  @{ F = 'if TMobjGameRules.ItemRespawnWaits(itemrespawntime[iquetail]) then'; D = 'if leveltime - itemrespawntime[iquetail] < 30 * TICRATE then'; Strife = 'if leveltime < itemrespawntime[iquetail] then' }
  @{ R = 'P_RespawnSpecials'; F = 'ss := TMapGameRules.PointInSector(x, y); TMobjGameRules.SpawnItemFog(x, y, ss.floorheight, mthing);'
     Doom = 'ss := P_PointInSector(x, y); mo := P_SpawnMobj(x, y, ss.floorheight, Ord(MT_IFOG), mthing); S_StartSound(mo, Ord(sfx_itmbk));' }
  @{ R = 'P_RespawnSpecials'; F = 'ss := TMapGameRules.PointInSector(x, y); TMobjGameRules.SpawnItemFog(x, y, ss.floorheight, mthing);'
     Heretic = 'ss := R_PointInSubsector(x, y); mo := P_SpawnMobj(x, y, ss.sector.floorheight, Ord(MT_TFOG), mthing); S_StartSound(mo, Ord(sfx_telept));'
     Strife = 'ss := R_PointInSubsector(x, y); mo := P_SpawnMobj(x, y, ss.sector.floorheight, Ord(MT_IFOG), mthing); S_StartSound(mo, Ord(sfx_itmbk));'; Note = $oneread }
  @{ R = 'P_RespawnSpecials'; F = 'ss: Psector_t;'; Heretic = 'ss: Psubsector_t;'; Strife = 'ss: Psubsector_t;'; Note = $oneread }
  @{ R = 'P_RespawnSpecials'; F = 'z := TMobjGameRules.SpawnHeightOfType(i);'; D = (SpawnHeight 'i' (FloatEx 'i'))
     Heretic = (SpawnHeight 'i' ((FloatEx 'i') + ' else if mobjinfo[i].flags2 and MF2_SPAWNFLOAT <> 0 then z := ONFLOATZ')) }

  # --- P_CheckMissileSpawn ---
  @{ F = 'TMobjGameRules.RandomizeSpawnTics(th);'; D = $tics; Hexen = ''; Strife = '' }
  @{ R = 'P_CheckMissileSpawn'; F = 'if TMobjGameRules.HalvesMissileStepByDivision then'; Doom = 'if G_PlayingEngineVersion in [VERSION122..VERSION205] then' }
  @{ R = 'P_CheckMissileSpawn'
     F = 'if TMobjGameRules.HalvesMissileStepByDivision then begin th.x := th.x + th.momx div 2; th.y := th.y + th.momy div 2; th.z := th.z + th.momz div 2; end else begin th.x := th.x + _SHR1(th.momx); th.y := th.y + _SHR1(th.momy); th.z := th.z + _SHR1(th.momz); end;'
     D = 'th.x := th.x + th.momx div 2; th.y := th.y + th.momy div 2; th.z := th.z + th.momz div 2;'; Doom = $null }
  @{ R = 'P_CheckMissileSpawn'; F = '(th: Pmobj_t)'; Hexen = '(missile: Pmobj_t)'; Note = 'in Hexen il parametro si chiamava missile' }
  @{ R = 'P_CheckMissileSpawn'; F = 'th.'; Hexen = 'missile.'; All = $true; Note = 'in Hexen il parametro si chiamava missile' }
  @{ R = 'P_CheckMissileSpawn'; F = '(th,'; Hexen = '(missile,'; All = $true; Note = 'in Hexen il parametro si chiamava missile' }
  @{ R = 'P_CheckMissileSpawn'; F = '(th)'; Hexen = '(missile)'; All = $true; Note = 'in Hexen il parametro si chiamava missile' }

  # --- P_SpawnMissileAngleZSpeed ---
  @{ R = 'P_SpawnMissileAngleZSpeed'; F = 'mo := P_SpawnMobj(source.x, source.y, z, _type); TMobjGameRules.MissileSeeSound(mo);'
     Hexen = 'mo := P_SpawnMobj(source.x, source.y, z, _type); if mo <> nil then begin A_SeeSound(mo, mo);'; Note = $nonnil }
  @{ R = 'P_SpawnMissileAngleZSpeed'; F = 'result := nil; TMobjGameRules.RestoreRandom; end;'; Hexen = 'result := nil; end else result := nil; end;'; Note = $nonnil }
  @{ F = 'TMobjGameRules.SaveRandom;'; D = 'P_SaveRandom;'; Hexen = '' }
  @{ F = 'TMobjGameRules.RestoreRandom;'; D = 'P_RestoreRandom;'; Hexen = '' }
  @{ F = 'TMapGameRules.SlopesVersion'; Doom = 'VERSION122'; Heretic = 'VERSION115'; Hexen = 'VERSION142'; Strife = 'VERSION122'; All = $true }
  @{ F = 'TMobjGameRules.MissileSeeSound(mo);'; D = 'A_SeeSound(mo, mo);'; Heretic = '<<B:MissileSeeSound>>'; Strife = 'A_SeeSound1(mo);' }

  # --- P_SeekerMissile (Hexen e' in $NotTextual) ---
  @{ R = 'P_SeekerMissile'; F = 'target := TMobjGameRules.SeekerTarget(actor); speed := TMobjGameRules.SeekerSpeed(actor); if (target = nil) or (TMobjGameRules.SeekerNeedsSpeed and (speed = 0)) then'
     D = 'target := actor.tracer; speed := P_AproxDistance(actor.momx, actor.momy); if (target = nil) or (speed = 0) then' }
  @{ R = 'P_SeekerMissile'; F = 'if speed = 0 then dist := 1 else begin dist := dist div speed; if dist < 1 then dist := 1; end;'; D = 'dist := dist div speed; if dist < 1 then dist := 1;'
     Note = 'il ramo "speed = 0" serve a Hexen: negli altri giochi la routine e'' gia'' uscita se la velocita'' e'' zero' }

  # --- P_GetThingFloorType ---
  @{ R = 'P_GetThingFloorType'; F = 'function P_GetThingFloorType(thing: Pmobj_t): integer; begin result := flats[TMobjGameRules.TerrainFloorPic(thing)].terraintype;'
     Hexen = 'function P_GetThingFloorType(thing: Pmobj_t): integer; var <<V:TerrainFloorPic>> begin <<B:TerrainFloorPic|strip=result := s.floorpic;>> result := flats[s.floorpic].terraintype;' }
  @{ F = 'TMobjGameRules.TerrainFloorPic(thing)'; D = 'Psubsector_t(thing.subsector).sector.floorpic' }

  # --- spawnmobj, summon ---
  @{ F = 'if TMobjGameRules.ConsoleSpawnForbidden then'; D = $forbidden }
  @{ F = 'else if TMobjGameRules.IsFloatHeightName(tmp) then z := TMobjGameRules.FloatSpawnZ'; D = "else if (tmp = 'ONFLOATZ') or (tmp = 'FLOATZ') then z := ONFLOATZ"
     Hexen = "else if (tmp = 'ONFLOATZ') or (tmp = 'FLOATZ') or (tmp = 'FLOATRANDZRAND') or (tmp = 'ONFLOATRANDZRAND') then z := FLOATRANDZ" }
  @{ F = 'TMobjGameRules.SummonerRadius'; D = 'mobjinfo[Ord(MT_PLAYER)].radius'; Hexen = 'players[consoleplayer].mo.info.radius' }
  @{ R = 'CmdSummon'; F = 'z := TMobjGameRules.SpawnHeightOfType(mobjno);'
     Heretic = (SpawnHeight 'mobjno' ('else if mobjinfo[mobjno].flags2 and MF2_SPAWNFLOAT <> 0 then z := ONFLOATZ ' + (FloatEx 'mobjno')))
     Note = 'summon di Heretic guardava prima MF2_SPAWNFLOAT e poi MF_EX_SPAWNFLOAT, P_RespawnSpecials il contrario: i due rami danno lo stesso ONFLOATZ e le condizioni non hanno effetti, la regola e'' una sola' }
  @{ R = 'CmdSummon'; F = 'z := TMobjGameRules.SpawnHeightOfType(mobjno);'; D = (SpawnHeight 'mobjno' (FloatEx 'mobjno')); Heretic = $null
     Hexen = (SpawnHeight 'mobjno' 'else if mobjinfo[mobjno].flags2 and MF2_SPAWNFLOAT <> 0 then z := FLOATRANDZ') }

  # --- P_XYMovement ---
  @{ R = 'P_XYMovement'; F = 'special: integer; wasonfloorz: boolean; wasonslope: boolean; oldsector: Psector_t; begin'
     Hexen = 'special: integer; angle: angle_t; speed: fixed_t; skip: boolean; rnd: LongWord; wasonfloorz: boolean; wasonslope: boolean; oldsector: Psector_t; <<V:BlockedMove|lead=angle: angle_t; speed: fixed_t; skip: boolean; rnd: LongWord;>> begin' }
  @{ R = 'P_XYMovement'; F = 'special: integer;'; Doom = ''; Strife = '' }
  @{ F = 'if TMobjGameRules.StoppedBeforeMoving(mo) then exit;'; D = '<<B:StoppedBeforeMoving|lead=result := false;|ret=true>>'; Strife = '' }
  @{ F = 'special := TMobjGameRules.SectorWind(mo);'; D = '<<B:SectorWind|strip=result := special;>>'; Doom = ''; Strife = '' }
  @{ F = 'if TMobjGameRules.HasWindThrust(mo) then'; D = 'if mo.flags2 and MF2_WINDTHRUST <> 0 then'; Doom = 'if mo.flags4_ex and MF4_EX_WINDTHRUST <> 0 then'; Strife = 'if mo.flags4_ex and MF4_EX_WINDTHRUST <> 0 then' }
  @{ F = "if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) or (TMobjGameRules.HalvesBackwardMoves and ((xmove < -MAXMOVE div 2) or (ymove < -MAXMOVE div 2))) then begin $half end"
     Doom = "if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) then begin $half end else if (G_PlayingEngineVersion >= VERSION205) and ((xmove < -MAXMOVE div 2) or (ymove < -MAXMOVE div 2)) then begin $half end"
     Note = 'Doom aveva due rami di fila con lo stesso corpo (mossa veloce in avanti; dalla 2.05 anche all''indietro): uniti con "or", condizioni senza effetti' }
  @{ F = "if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) or (TMobjGameRules.HalvesBackwardMoves and ((xmove < -MAXMOVE div 2) or (ymove < -MAXMOVE div 2))) then begin $half end"
     D = "if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) then begin $half end"; Doom = $null }
  @{ F = 'if not P_TryMove(mo, ptryx, ptryy) then if TMobjGameRules.BlockedMove(mo, ptryx, ptryy, xmove, ymove) then exit;'
     D = 'if not P_TryMove(mo, ptryx, ptryy) then begin <<B:BlockedMove|lead=result := false;|exit=true>> end;' }
  @{ R = 'P_XYMovement'; F = 'until not ((xmove <> 0) or (ymove <> 0));'; Hexen = 'until (xmove = 0) and (ymove = 0);'; Note = 'Hexen scriveva la stessa condizione con De Morgan' }
  @{ F = 'if mo.flags and TMobjGameRules.NoFrictionFlags <> 0 then exit;'; D = 'if mo.flags and (MF_MISSILE or MF_SKULLFLY) <> 0 then exit;'
     Hexen = 'if mo.flags and (MF_MISSILE or MF_SKULLFLY) <> 0 then begin exit; end;'; Strife = 'if mo.flags and (MF_MISSILE or MF_BOUNCE) <> 0 then exit;' }
  @{ F = 'if TMobjGameRules.AirborneFriction(mo, player, wasonfloorz, wasonslope, oldsector) then exit;'; D = ''; Strife = '<<B:AirborneFriction|lead=result := false;|ret=true>>' }
  @{ R = 'P_XYMovement'; F = "if TMobjGameRules.FallsFree(mo, player) then begin $slope end;"; Strife = '' }
  @{ R = 'P_XYMovement'; F = "if TMobjGameRules.FallsFree(mo, player) then begin $slope end;"
     Hexen = "if (mo.z > mo.floorz) and (mo.flags2 and MF2_FLY = 0) and (mo.flags2 and MF2_ONMOBJ = 0) then begin if mo._type <> Ord(MT_BLASTEFFECT) then begin $slope end; end;"
     Note = 'Hexen aveva due "if" uno dentro l''altro senza "else": la regola FallsFree e'' la loro congiunzione' }
  @{ F = 'if TMobjGameRules.FallsFree(mo, player) then begin'; D = 'if (player <> nil) and (player.laddertics > 0) then else if mo.z > mo.floorz then begin'
     Note = '"se e'' su una scala niente, altrimenti se e'' in aria" scritto come una condizione sola' }
  @{ F = 'TMobjGameRules.StopWalking(player);'; D = '<<B:StopWalking>>' }
  @{ F = 'else TMobjGameRules.ApplyFriction(mo, special); end;'; D = 'else begin <<B:ApplyFriction>> end; end;' }

  # --- P_SpawnMobj ---
  @{ R = 'P_SpawnMobj'; F = 'function P_SpawnMobj(x, y, z: fixed_t;'; Hexen = 'function P_SpawnMobj(x: fixed_t; y: fixed_t; z: fixed_t;'; Note = 'in Hexen i tre parametri erano scritti uno per uno' }
  @{ R = 'P_SpawnMobj'; F = "mobj.flags_ex := info.flags_ex; TMobjGameRules.InitGameFields(mobj, info); mobj.flags3_ex := info.flags3_ex; $infoMid mobj.renderstyle := info.renderstyle;"
     Doom = "mobj.flags_ex := info.flags_ex; mobj.flags2_ex := info.flags2_ex; mobj.flags3_ex := info.flags3_ex; mobj.flags4_ex := info.flags4_ex or MF4_EX_JUSTAPPEARED; $infoMid mobj.renderstyle := info.renderstyle;"
     Heretic = "mobj.flags2 := info.flags2; mobj.flags_ex := info.flags_ex; mobj.flags2_ex := info.flags2_ex or MF2_EX_JUSTAPPEARED; mobj.flags3_ex := info.flags3_ex; mobj.flags4_ex := info.flags4_ex; $infoMid mobj.damage := info.damage; mobj.renderstyle := info.renderstyle;"
     Hexen = "mobj.flags2 := info.flags2; mobj.flags_ex := info.flags_ex; mobj.flags2_ex := info.flags2_ex or MF2_EX_JUSTAPPEARED; mobj.flags3_ex := info.flags3_ex; mobj.flags4_ex := info.flags4_ex; $infoMid mobj.damage := info.damage; mobj.renderstyle := info.renderstyle;"
     Strife = "mobj.flags_ex := info.flags_ex; mobj.flags2_ex := info.flags2_ex or MF2_EX_JUSTAPPEARED; mobj.flags3_ex := info.flags3_ex; mobj.flags4_ex := info.flags4_ex; $infoMid mobj.renderstyle := info.renderstyle;"
     Note = 'assegnazioni indipendenti di campi presi dall''info (nessuna legge un campo scritto da un''altra): quelle che cambiano per gioco sono raccolte nella regola InitGameFields, in un altro ordine' }
  @{ F = 'TMobjGameRules.InitBob(mobj);'; D = '<<B:InitBob>>'; Hexen = '' }
  @{ F = 'if TMobjGameRules.HasReactionTime then mobj.reactiontime := info.reactiontime;'; D = 'if gameskill <> sk_nightmare then mobj.reactiontime := info.reactiontime;'; Strife = 'mobj.reactiontime := info.reactiontime;' }
  @{ R = 'P_SpawnMobj'; F = "$stInit TMobjGameRules.InitStateMemory(mobj, st);"; Hexen = $stInit }
  @{ R = 'P_SpawnMobj'; F = "$stInit TMobjGameRules.InitStateMemory(mobj, st);"
     D = 'mobj.state := st; mobj.prevstate := st; mobj.validcount := validcount; mobj.tics := P_TicsFromState(st); mobj.sprite := st.sprite; mobj.frame := st.frame; mobj.touching_sectorlist := nil;'
     Heretic = 'mobj.state := st; mobj.prevstate := st; mobj.tics := P_TicsFromState(st); mobj.sprite := st.sprite; mobj.frame := st.frame;'; Hexen = $null
     Note = 'prevstate, validcount e touching_sectorlist (assegnazioni indipendenti, P_TicsFromState legge solo lo stato) sono raccolte nella regola InitStateMemory dopo sprite e frame' }
  @{ R = 'P_SpawnMobj'; F = 'TMobjGameRules.FloatSpawnZ'; D = 'ONFLOATZ'; Hexen = 'FLOATRANDZ'; All = $true }
  @{ F = 'if z = ONFLOORZ then begin mobj.z := mobj.floorz; TMobjGameRules.SpawnedOnFloor(mobj); end'; D = 'if z = ONFLOORZ then mobj.z := mobj.floorz'
     Strife = 'if z = ONFLOORZ then begin mobj.z := mobj.floorz; <<B:SpawnedOnFloor>> end' }
  @{ F = 'mobj.z := TMobjGameRules.RandomFloatHeight(space) + mobj.floorz + 40 * FRACUNIT; end else mobj.z := mobj.floorz end else if TMobjGameRules.SpawnZIsHeight(mobj) then mobj.z := mobj.floorz + z else mobj.z := z;'
     Doom = 'mobj.z := FixedMul(space, N_Random * 256) + mobj.floorz + 40 * FRACUNIT; end else mobj.z := mobj.floorz end else mobj.z := z;'
     Heretic = 'mobj.z := FixedMul(space, P_Random * 256) + mobj.floorz + 40 * FRACUNIT end else mobj.z := mobj.floorz end else mobj.z := z;'
     Hexen = 'mobj.z := _SHR8(space * P_Random) + mobj.floorz + 40 * FRACUNIT; end else begin mobj.z := mobj.floorz; end; end else if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then begin mobj.z := mobj.floorz + z; end else mobj.z := z;'
     Strife = 'mobj.z := FixedMul(space, N_Random * 256) + mobj.floorz + 40 * FRACUNIT end else mobj.z := mobj.floorz end else mobj.z := z;' }
  @{ F = 'TMobjGameRules.FootClipOnMidOrSlope(mobj); end else TMobjGameRules.FootClipOnFloor(mobj, sec);'; D = '<<B:FootClipOnMidOrSlope>> end else begin <<B:FootClipOnFloor>> end;' }

  # --- P_MobjThinker ---
  @{ R = 'P_MobjThinker'; F = 'procedure P_MobjThinker(mobj: Pmobj_t); begin'; D = 'procedure P_MobjThinker(mobj: Pmobj_t); var <<V:ZPhase>> begin'; Strife = $null }
  @{ F = 'TMobjGameRules.ClearJustAppeared(mobj);'; D = 'mobj.flags2_ex := mobj.flags2_ex and not MF2_EX_JUSTAPPEARED;'; Doom = 'mobj.flags4_ex := mobj.flags4_ex and not MF4_EX_JUSTAPPEARED;' }
  @{ F = 'TMobjGameRules.BeginThink;'; D = ''; Hexen = 'BlockingMobj := nil;' }
  @{ R = 'P_MobjThinker'; F = '(mobj.momy <> 0) or TMapGameRules.IsSkullFlying(mobj) then'; Strife = '(mobj.momy <> 0) then' }
  @{ R = 'P_MobjThinker'; F = 'TMapGameRules.IsSkullFlying(mobj) then'; D = '(mobj.flags and MF_SKULLFLY <> 0) then' }
  @{ F = 'TMobjGameRules.AfterXYMovement(mobj); end else TMobjGameRules.StandsStill(mobj);'; D = 'end;'
     Hexen = 'end else <<B:StandsStill>>'; Strife = '<<B:AfterXYMovement>> end;' }
  @{ F = 'if not TMobjGameRules.ZPhase(mobj) then exit;'; D = '<<B:ZPhase|strip=result := true;|exit=false>>' }
  @{ F = 'TMobjGameRules.BeforeStateCycle(mobj);'; D = ''; Strife = '<<B:BeforeStateCycle>>' }
  @{ F = "if TMobjGameRules.CyclesStatesWhileNoTics then begin while mobj.tics = 0 do $setstate end else if mobj.tics = 0 then $setstate"
     D = "if mobj.tics = 0 then $setstate"; Heretic = "while mobj.tics = 0 do $setstate"; Hexen = "while mobj.tics = 0 do begin $setstate end;" }
  @{ R = 'P_MobjThinker'; F = "end else if TMobjGameRules.MonstersRespawn then begin $respawn end; end;"; Hexen = 'end; end;' }
  @{ F = 'else if TMobjGameRules.MonstersRespawn then begin'; D = 'else begin' }
  @{ R = 'P_MobjThinker'; F = 'if mobj.movecount < TMobjGameRules.RespawnTime then exit;'; Heretic = 'if mobj.movecount < 12 * TICRATE then begin exit; end;' }
  @{ F = 'TMobjGameRules.RespawnTime'; D = '12 * TICRATE'; Strife = '16 * TICRATE' }
  @{ F = 'if TMobjGameRules.NeverRespawns(mobj) then exit;'; D = ''; Strife = 'if mobj.flags and MF_NOTDMATCH <> 0 then exit;' }
  @{ F = 'TMobjGameRules.NightmareRespawn(mobj);'; D = 'P_NightmareRespawn(mobj);' }
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
  'Hexen|P_SeekerMissile' = 'la copia unica legge una volta il bersaglio (special1) e la velocita'' (actor.info.speed, che nessuno cambia nel frattempo) con le regole SeekerTarget e SeekerSpeed; SeekerNeedsSpeed e'' falso, quindi con velocita'' zero la routine prosegue come in Hexen e la distanza vale 1'
}

# le routine che sono tutte di un gioco: metodi delle regole con il testo vecchio
$Methods = @{
  'P_NightmareRespawn' = 'NightmareRespawn'; 'P_SpawnPlayer' = 'SpawnPlayer'; 'P_SpawnMapThing' = 'SpawnMapThing'
  'P_SpawnPuff' = 'SpawnPuff'; 'P_SpawnMissile' = 'SpawnMissile'; 'P_SpawnMissileXYZ' = 'SpawnMissileXYZ'
  'P_SpawnPlayerMissile' = 'SpawnPlayerMissile'; 'P_HitFloor' = 'HitFloor'
  'Heretic|P_SetMobjStateNF' = 'SetMobjStateNF'; 'Hexen|P_SetMobjStateNF' = 'SetMobjStateNF'; 'Hexen|P_CreateTIDList' = 'CreateTIDList'
}
# la routine unificata ha un altro nome
$Alias = @{ 'Heretic|P_SetMobjState' = 'P_DoSetMobjState'; 'Hexen|P_SetMobjState' = 'P_DoSetMobjState'; 'Strife|P_SetMobjState' = 'P_DoSetMobjState' }

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_mobj' -BaseFiles 'Base\p_mobj.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.MobjRules.pas' -Class 'TMobjGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias
exit $bad
