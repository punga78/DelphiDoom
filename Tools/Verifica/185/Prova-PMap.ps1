<#
  Issue #185, passo 2c-1 (p_map in copia unica): prova meccanica delle routine parametriche.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMobj.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_map.pas (presa dal commit di partenza con git show) prende
  il testo della routine unificata (IdTech1\Base\p_map.pas, IdTech1\Base\p_secnodes.pas o la unit delle regole del gioco), sostituisce
  ogni chiamata a TMapGameRules con il corpo della regola di quel gioco (le sostituzioni sono la tabella $Expansions
  qui sotto, scritta a mano; i corpi lunghi si leggono dalla unit del gioco con <<B:Metodo>>) e confronta il risultato
  con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PMap.ps1 [-Base 7bcb9a13] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = '7bcb9a13',
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife')
)
$ErrorActionPreference = 'Stop'
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$rulesUnit = 'DelphiDoom.Engine.World.MapRules.pas'

. (Join-Path $PSScriptRoot 'Prova-Common.ps1')

# ---------------------------------------------------------------------------------------------------------------
# Le sostituzioni. F = il testo nella routine unificata; D = con che cosa si sostituisce in ogni gioco, salvo il
# gioco nominato; R = solo in queste routine; Note = riscrittura dichiarata (non e' il corpo della regola alla
# lettera) e perche' e' equivalente. <<B:X>> = corpo del metodo TMapGameRules.X del gioco; <<V:X>> = le sue
# variabili locali; <<S:X>> = corpo della routine X di p_secnodes; "|strip=testo" toglie un testo in coda.
# ---------------------------------------------------------------------------------------------------------------
$ret = 'begin result := true; exit; end;'
$stop = 'begin result := false; exit; end;'
$sub = 'newsubsec'
$Expansions = @(
  # --- costanti ---
  @{ F = 'TMapGameRules.SlopesVersion'; Doom = 'VERSION122'; Heretic = 'VERSION115'; Hexen = 'VERSION142'; Strife = 'VERSION122' }
  @{ F = 'margin := TMapGameRules.SlideStepMargin;'; D = 'margin := 24 * FRACUNIT;'; Strife = 'margin := 16 * FRACUNIT;' }
  @{ F = 'dropoffmargin := TMapGameRules.DropoffHeight;'; D = 'dropoffmargin := 24 * FRACUNIT;'; Strife = 'dropoffmargin := 32 * FRACUNIT;' }
  @{ F = 'dropoffmargin + TMapGameRules.JumpDownMargin;'; D = 'dropoffmargin + 120 * FRACUNIT;'; Strife = 'dropoffmargin + 112 * FRACUNIT;' }
  @{ F = 'thing.flags and TMapGameRules.NoSpecHitFlags = 0'; D = 'thing.flags and (MF_TELEPORT or MF_NOCLIP) = 0'; Strife = 'thing.flags and MF_NOCLIP = 0'; All = $true }
  @{ F = 'if TMapGameRules.TeleportSetsZ then thing.z := tmfloorz;'; D = ''; Strife = 'thing.z := tmfloorz;' }

  # --- PIT_StompThing ---
  @{ F = "if not TMapGameRules.CanStomp(thing) then $stop"
     Doom = "if (tmthing.player = nil) and (gamemap <> 30) then $stop"
     Heretic = "if tmthing.flags2 and MF2_TELESTOMP = 0 then $stop"
     Hexen = "if tmthing.flags2 and MF2_TELESTOMP = 0 then $stop"
     Strife = "if not ((tmthing.player <> nil) or (thing.player <> nil)) then $stop" }

  # --- il settore di un punto: P_TeleportMove, P_CheckOnmobj, P_CheckPosition ---
  @{ F = 'newsec := TMapGameRules.PointInSector(x, y);'; Doom = 'newsec := P_PointInSector(x, y);' }
  @{ R = 'P_TeleportMove', 'P_CheckOnmobj'; F = 'newsec: Psector_t;'; Heretic = "$sub`: Psubsector_t;"; Hexen = "$sub`: Psubsector_t;"; Strife = "$sub`: Psubsector_t;"
     Note = 'le vecchie copie tenevano il sottosettore e ne leggevano tre volte il campo sector: la copia unica legge il settore una volta (nessuno lo cambia nel frattempo)' }
  @{ R = 'P_TeleportMove', 'P_CheckOnmobj'; F = 'newsec := TMapGameRules.PointInSector(x, y);'; D = "$sub := R_PointInSubsector(x, y);"; Doom = $null; Note = 'come sopra' }
  @{ R = 'P_TeleportMove'; F = 'P_SectorJumpOverhead(newsec, thing.player)'; Doom = 'P_SectorJumpOverhead(newsec)'; Strife = "P_SectorJumpOverhead($sub.sector)"
     Note = 'Doom e Strife non passavano il giocatore: il parametro in piu'' serve solo a HasFlightPower, che per loro e'' sempre falso' }
  @{ R = 'P_TeleportMove', 'P_CheckOnmobj'; F = 'newsec'; Heretic = "$sub.sector"; Hexen = "$sub.sector"; Strife = "$sub.sector"; Note = 'come sopra (newsubsec.sector)'; All = $true }
  @{ R = 'P_CheckPosition'; F = 'newsec: Psector_t;'; Heretic = "$sub`: Psubsector_t; newsec: Psector_t;"; Hexen = "$sub`: Psubsector_t; newsec: Psector_t;"; Strife = "$sub`: Psubsector_t; newsec: Psector_t;"; Note = 'come sopra' }
  @{ R = 'P_CheckPosition'; F = 'newsec := TMapGameRules.PointInSector(x, y);'; D = "$sub := R_PointInSubsector(x, y); newsec := $sub.sector;"; Doom = $null; Note = 'come sopra' }
  @{ R = 'P_CheckPosition'; F = 'P_SectorJumpOverhead(newsec, thing.player)'; Doom = 'P_SectorJumpOverhead(newsec)'; Heretic = "P_SectorJumpOverhead($sub.sector, thing.player)"; Hexen = "P_SectorJumpOverhead($sub.sector, thing.player)"; Strife = "P_SectorJumpOverhead($sub.sector)"; Note = 'come sopra' }
  @{ F = 'TMapGameRules.MarkJustAppeared(thing);'; D = 'thing.flags2_ex := thing.flags2_ex or MF2_EX_JUSTAPPEARED;'; Doom = 'thing.flags4_ex := thing.flags4_ex or MF4_EX_JUSTAPPEARED;' }

  # --- P_CheckPosition ---
  @{ F = 'TMapGameRules.BeginCheckPosition;'; D = ''; Strife = 'blockingline := nil;' }
  @{ F = 'if TMapGameRules.NoClipSkipsThings(tmflags) then'; D = 'if tmflags and MF_NOCLIP <> 0 then'; Hexen = 'if (tmflags and MF_NOCLIP <> 0) and (tmflags and MF_SKULLFLY = 0) then' }
  @{ F = "if TMapGameRules.NoClipSkipsLines(tmflags) then $ret"; D = ''; Hexen = "if tmflags and MF_NOCLIP <> 0 then $ret" }
  @{ F = 'TMapGameRules.ClearBlockingThing;'; D = ''; Hexen = 'BlockingMobj := nil;'; All = $true }

  # --- P_FakeZMovement ---
  @{ F = 'if not TMapGameRules.IsSkullFlying(mo) and (mo.flags and MF_INFLOAT = 0) then'; D = 'if (mo.flags and MF_SKULLFLY = 0) and (mo.flags and MF_INFLOAT = 0) then' }
  @{ F = 'if TMapGameRules.IsSkullFlying(mo) then'; D = 'if mo.flags and MF_SKULLFLY <> 0 then'; All = $true }
  @{ F = 'if TMapGameRules.FlightBobs(mo) then if (mo.player <> nil) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then'
     Doom = 'if G_PlayingEngineVersion <= VERSION204 then if (mo.player <> nil) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then' }
  @{ F = 'if TMapGameRules.FlightBobs(mo) then if (mo.player <> nil) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then'
     Heretic = 'if (mo.player <> nil) and (mo.flags2 and MF2_FLY <> 0) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then'
     Hexen = 'if (mo.player <> nil) and (mo.flags2 and MF2_FLY <> 0) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then'
     Note = 'la condizione del volo (un confronto di flag, senza effetti) e'' valutata per prima invece che seconda' }
  @{ F = 'else if TMapGameRules.HasLowGravity(mo) then'; Doom = 'else if mo.flags_ex and MF_EX_LOWGRAVITY <> 0 then'
     Heretic = 'else if (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0) then'; Hexen = 'else if (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0) then' }

  # --- P_ThingHeightClip, P_TryMove ---
  @{ F = 'TMapGameRules.StoreFloorPic(thing);'; D = ''; Hexen = 'thing.floorpic := tmfloorpic;'; All = $true }
  @{ F = 'if TMapGameRules.SnapsToFloor(thing) then thing.z := thing.floorz;'; D = 'thing.z := thing.floorz;'
     Hexen = 'if (thing.z - thing.floorz < 9 * FRACUNIT) or (thing.flags and MF_NOGRAVITY <> 0) then thing.z := thing.floorz;' }

  # --- PTR_SlideTraverse ---
  @{ R = 'PTR_SlideTraverse'; F = 'bestslidefrac := intr.frac;'; Heretic = 'secondslidefrac := bestslidefrac; secondslideline := bestslideline; bestslidefrac := intr.frac;'
     Hexen = 'secondslidefrac := bestslidefrac; secondslideline := bestslideline; bestslidefrac := intr.frac;'
     Note = 'secondslidefrac e secondslideline erano scritte e mai lette (nessun altro riferimento in Heretic; in Hexen solo un''altra scrittura in PTR_BounceTraverse): le due assegnazioni sono tolte' }

  # --- mira e colpo ---
  @{ F = "if TMapGameRules.SkipsAimAt(th) then $ret"; D = ''; Hexen = "if (th.player <> nil) and netgame and (deathmatch = 0) then $ret" }
  @{ F = 'shootz := TMapGameRules.AimOriginZ(t1);'; D = 'shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;'; Strife = 'shootz := t1.z + (t1.height div 2) + 8 * FRACUNIT;' }
  @{ F = 'else result := TMapGameRules.NoTargetSlope(t1);'; D = 'else result := 0;'; Strife = 'else if t1.player <> nil then result := (Pplayer_t(t1.player).lookdir * FRACUNIT) div 160 else result := 0;' }
  @{ F = 'shootz := TMapGameRules.AttackOriginZ(t1);'; D = 'shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;'
     Heretic = 'shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT; if t1.flags2 and MF2_FEETARECLIPPED <> 0 then shootz := shootz - FOOTCLIPSIZE;'
     Hexen = 'shootz := t1.z + _SHR1(t1.height) + 8 * FRACUNIT - t1.floorclip;' }
  @{ F = 'if P_PathTraverse(t1.x, t1.y, x2, y2, TMapGameRules.LineAttackFlags(damage), PTR_ShootTraverse) then TMapGameRules.LineAttackMissed(t1, x2, y2, slope, distance);'
     D = 'P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_ShootTraverse);'
     Hexen = 'if P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_ShootTraverse) then begin <<B:LineAttackMissed>> end;'
     Strife = 'if damage >= 1 then P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_ShootTraverse) else P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES, PTR_ShootTraverse);' }

  # --- PTR_ShootTraverse ---
  @{ F = 'if G_NeedsCompatibilityMode = TMapGameRules.SkyHackPuffInCompatibility then'; D = 'if G_NeedsCompatibilityMode then'; Doom = 'if not G_NeedsCompatibilityMode then' }
  @{ F = "P_RestoreRandom; result := false; exit; end; if not TMapGameRules.SkyHackPuffInCompatibility then $stop"
     D = 'P_RestoreRandom; result := false; exit; end;'; Doom = 'P_RestoreRandom; end; result := false; exit;'
     Note = 'Doom: lo sbuffo solo fuori dal modo di compatibilita'' e poi sempre "result := false; exit": scritto come due uscite, una dopo lo sbuffo e una senza' }
  @{ F = 'TMapGameRules.SpawnWallPuff(x, y, z);'; D = 'P_SpawnPuff(x, y, z);'; Strife = '<<B:SpawnWallPuff>>' }
  @{ F = 'if li.special <> 0 then TMapGameRules.ShootSpecialLine(shootthing, li);'
     D = 'if li.special <> 0 then begin P_ShootSpecialLine(shootthing, li); P_ActivateLine(li, shootthing, 0, ULAC_IMPACT); end;'
     Hexen = 'if li.special <> 0 then P_ActivateLine(li, shootthing, 0, SPAC_IMPACT);' }
  @{ F = "if TMapGameRules.ShotPassesThrough(th) then $ret"; D = ''; Strife = "if th.flags and MF_SPECTRAL <> 0 then $ret" }
  @{ F = 'result := TMapGameRules.ShotHitsThing(intr, th, x, y, z);'; D = '<<B:ShotHitsThing>>' }
  @{ R = 'PTR_ShootTraverse'; F = 'th: Pmobj_t; slope: fixed_t;'; Strife = 'th: Pmobj_t; <<V:ShotHitsThing>> slope: fixed_t;' }

  # --- PTR_UseTraverse (Doom, Heretic, Strife; Hexen e' in $NotTextual) ---
  @{ F = 'TMapGameRules.UseBlockedByWall(usething);'; D = 'S_StartSound(usething, Ord(sfx_noway));'; Heretic = '' }
  @{ F = 'TMapGameRules.UseNonSpecialLine(usething);'; D = '' }
  @{ F = 'result := TMapGameRules.UseSpecialLine(usething, li, side);'
     Doom = 'P_UseSpecialLine(usething, li, side); P_ActivateLine(intr.d.line, usething, 0, ULAC_USE); result := not G_NeedsCompatibilityMode and (li.flags and ML_PASSUSE <> 0);'
     Heretic = 'P_UseSpecialLine(usething, li, side); P_ActivateLine(intr.d.line, usething, 0, ULAC_USE); result := false;'
     Strife = 'P_UseSpecialLine(usething, li, side); P_ActivateLine(intr.d.line, usething, 0, ULAC_USE); result := not G_NeedsCompatibilityMode and ((li.flags and ML_PASSUSE) <> 0);'
     Note = 'la regola riceve li, che e'' intr.d.line' }

  # --- PIT_RadiusAttack, P_RadiusAttack ---
  @{ F = "if TMapGameRules.IsConcussionProof(thing) then $ret"
     Doom = "if (thing._type = Ord(MT_CYBORG)) or (thing._type = Ord(MT_SPIDER)) then $ret"
     Heretic = "if (thing._type = Ord(MT_MINOTAUR)) or (thing._type = Ord(MT_SORCERER1)) or (thing._type = Ord(MT_SORCERER2)) then $ret"
     Hexen = "if thing.flags2 and MF2_BOSS <> 0 then $ret"
     Strife = "if thing.flags and MF_SPECTRAL <> 0 then $ret if thing._type = Ord(MT_INQUISITOR) then $ret" }
  @{ R = 'PIT_RadiusAttack'; F = 'if thing.flags_ex and MF_EX_BOSS <> 0 then'; Heretic = 'if (thing.flags_ex and MF_EX_BOSS <> 0) or (thing.flags2 and MF2_BOSS <> 0) then'
     Note = 'Heretic: il confronto con MF2_BOSS sta nella regola IsConcussionProof (una riga prima) invece che accanto a MF_EX_BOSS; Strife: i due "if" di fila sono un "or"; tutti confronti senza effetti che danno "result := true"' }
  @{ F = "if TMapGameRules.OutOfBlast(thing, bombspot, bombsource) then $ret"; D = ''
     Hexen = "if not damagesource and (thing = bombsource) then $ret if abs(thing.z - bombspot.z) > 2 * bombdistance * FRACUNIT then $ret" }
  @{ F = 'P_DamageMobj(thing, bombspot, bombsource, TMapGameRules.BlastDamage(thing, bombdamage, dist));'; D = 'P_DamageMobj(thing, bombspot, bombsource, bombdamage - dist);'
     Hexen = 'damage := (bombdamage * (bombdistance - dist) div bombdistance) + 1; if thing.player <> nil then damage := _SHR2(damage); P_DamageMobj(thing, bombspot, bombsource, damage);' }
  @{ R = 'PIT_RadiusAttack'; F = 'dist: fixed_t; begin'; Hexen = 'dist: fixed_t; damage: integer; begin' }
  @{ R = 'P_RadiusAttack'; F = 'const damage: integer; const distance: integer = 0; const dmsource: boolean = true);'; D = 'const damage: integer);'
     Hexen = 'const damage: integer; const distance: integer; const dmsource: boolean);'
     Note = 'la firma ha i due parametri di Hexen con un valore predefinito: i chiamanti degli altri giochi ne passano tre come prima' }
  @{ F = 'TMapGameRules.SetBlastExtent(distance, dmsource);'; D = ''; Hexen = 'bombdistance := distance; damagesource := dmsource;' }
  @{ F = 'TMapGameRules.AfterRadiusAttack(spot, dist);'; D = ''; Strife = '<<B:AfterRadiusAttack>>'; All = $true }

  # --- P_DoChangeSector, P_SectorJumpOverhead, P_TestMobjLocation ---
  @{ R = 'P_DoChangeSector'; F = 'pbox: PIntegerArray; begin if not TMapGameRules.ChangeSectorByThingList(sector) then begin'
     Doom = 'pbox: PIntegerArray; n: Pmsecnode_t; begin if G_NeedsCompatibilityMode then begin'; Strife = 'pbox: PIntegerArray; n: Pmsecnode_t; begin if G_NeedsCompatibilityMode then begin'
     Heretic = 'pbox: PIntegerArray; begin'; Hexen = 'pbox: PIntegerArray; begin'
     Note = 'Doom e Strife: il ramo delle liste dei settori e'' P_ChangeSectorNodes di p_secnodes, chiamato dalla regola quando non si e'' nel modo di compatibilita''' }
  @{ R = 'P_DoChangeSector'; F = 'P_BlockThingsIterator(x, y, PIT_ChangeSector); end; end;'
     Doom = 'P_BlockThingsIterator(x, y, PIT_ChangeSector); end else begin <<S:P_ChangeSectorNodes>> end; end;'
     Strife = 'P_BlockThingsIterator(x, y, PIT_ChangeSector); end else begin <<S:P_ChangeSectorNodes>> end; end;'
     Heretic = 'P_BlockThingsIterator(x, y, PIT_ChangeSector); end;'; Hexen = 'P_BlockThingsIterator(x, y, PIT_ChangeSector); end;'; Note = 'come sopra' }
  @{ R = 'P_SectorJumpOverhead'; F = 'function P_SectorJumpOverhead(const s: Psector_t; const p: Pplayer_t = nil): integer;'
     Doom = 'function P_SectorJumpOverhead(const s: Psector_t): integer;'; Strife = 'function P_SectorJumpOverhead(const s: Psector_t): integer;'
     Note = 'Doom e Strife: parametro in piu'' con valore predefinito, usato solo da HasFlightPower che per loro e'' falso' }
  @{ R = 'P_SectorJumpOverhead'; F = "if s.ceilingpic = skyflatnum then begin if p <> nil then if TMapGameRules.HasFlightPower(p) then begin result := 0; exit; end;"
     Doom = 'if s.ceilingpic = skyflatnum then'; Strife = 'if s.ceilingpic = skyflatnum then'
     Heretic = 'if s.ceilingpic = skyflatnum then begin if p <> nil then if p.powers[Ord(pw_flight)] <> 0 then begin result := 0; exit; end;'; Note = 'come sopra' }
  @{ R = 'P_SectorJumpOverhead'; F = 'exit; end; end; result := 0; end;'; Doom = 'exit; end; result := 0; end;'; Strife = 'exit; end; result := 0; end;'; Note = 'come sopra' }
  @{ F = 'flags := TMapGameRules.SuspendPickup(mobj);'; D = 'flags := mobj.flags; mobj.flags := mobj.flags and not MF_PICKUP;'; Strife = '' }
  @{ F = 'TMapGameRules.RestorePickup(mobj, flags);'; D = 'mobj.flags := flags;'; Strife = ''; All = $true }
  @{ R = 'P_TestMobjLocation'; F = 'var flags: integer; begin'; Strife = 'begin' }

  # --- PIT_CheckLine, PIT_CheckLineTM ---
  @{ F = 'TMapGameRules.BlastedHitsWall(tmthing);'; D = ''; Hexen = 'if tmthing.flags2 and MF2_BLASTED <> 0 then P_DamageMobj(tmthing, nil, nil, _SHR(tmthing.mass, 5));'; All = $true }
  @{ F = "if tmthing.flags and MF_MISSILE = 0 then if not TMapGameRules.CheckLineBlocking(ld) then $stop"; D = 'if tmthing.flags and MF_MISSILE = 0 then begin <<B:CheckLineBlocking|strip=result := true;>> end;' }
  @{ F = "if tmthing.flags and MF_MISSILE = 0 then if not TMapGameRules.CheckLineBlockingTM(ld) then $stop"; D = 'if tmthing.flags and MF_MISSILE = 0 then begin <<B:CheckLineBlockingTM|strip=result := true;>> end;' }

  # --- P_TryMove ---
  @{ F = "if not P_CheckPosition(thing, x, y) then if not TMapGameRules.StepsOnBlockingThing(thing) then begin if TMapGameRules.PushesLinesWhenBlocked then pushline; result := false; exit; end;"
     D = "if not P_CheckPosition(thing, x, y) then $stop"
     Hexen = 'if not P_CheckPosition(thing, x, y) then begin if (BlockingMobj = nil) or (BlockingMobj.player <> nil) or (thing.player = nil) then begin pushline; result := false; exit; end; if (BlockingMobj.z + BlockingMobj.height - thing.z > 24 * FRACUNIT) or (Psubsector_t(BlockingMobj.subsector).sector.ceilingheight - (BlockingMobj.z + BlockingMobj.height) < thing.height) or (tmceilingz - (BlockingMobj.z + BlockingMobj.height) < thing.height) then begin pushline; result := false; exit; end; end;' }
  @{ F = 'if not TMapGameRules.IgnoresCeilingFit(thing) and (tmceilingz - thing.z < thing.height) then'
     D = 'if (thing.flags and MF_TELEPORT = 0) and (tmceilingz - thing.z < thing.height) then'
     Hexen = 'if (thing.flags and MF_TELEPORT = 0) and (tmceilingz - thing.z < thing.height) and (thing._type <> Ord(MT_LIGHTNING_CEILING)) and (thing.flags2 and MF2_FLY = 0) then'
     Strife = 'if tmceilingz - thing.z < thing.height then' }
  @{ F = 'if TMapGameRules.FlightBlocked(thing) then begin pushline; result := false; exit; end;'; D = ''
     Hexen = 'if thing.flags2 and MF2_FLY <> 0 then begin if thing.z + thing.height > tmceilingz then begin thing.momz := thing.momz -8 * FRACUNIT; pushline; result := false; exit; end; if (thing.z < tmfloorz) and (tmfloorz - tmdropoffz > 24 * FRACUNIT) then begin thing.momz := 8 * FRACUNIT; pushline; result := false; exit; end; end;' }
  @{ F = "if TMapGameRules.StepTooHighOnFoot(thing) then $stop"; D = ''; Strife = "if (thing.flags and MF_NOBLOOD = 0) and (tmfloorz - thing.z > 16 * FRACUNIT) then $stop" }
  @{ F = 'if not TMapGameRules.IgnoresStepHeight(thing) and (tmfloorz - thing.z > jumpupmargin) then'
     D = 'if (thing.flags and MF_TELEPORT = 0) and (tmfloorz - thing.z > jumpupmargin) then'
     Hexen = 'if (thing.flags and MF_TELEPORT = 0) and (thing._type <> Ord(MT_MNTRFX2)) and (thing._type <> Ord(MT_LIGHTNING_FLOOR)) and (tmfloorz - thing.z > jumpupmargin) then'
     Strife = 'if tmfloorz - thing.z > jumpupmargin then' }
  @{ F = "if TMapGameRules.MissileStepTooHigh(thing) then $stop"; D = ''; Strife = "if (thing.flags and MF_MISSILE <> 0) and (tmfloorz - thing.z > 4 * FRACUNIT) then $stop" }
  @{ F = '(tmfloorz - tmdropoffz > dropoffmargin) and not TMapGameRules.IgnoresDropoff(thing) then'; D = '(tmfloorz - tmdropoffz > dropoffmargin) then'
     Hexen = '(tmfloorz - tmdropoffz > dropoffmargin) and (thing.flags2 and MF2_BLASTED = 0) then' }
  @{ F = 'if TMapGameRules.CannotLeaveFloorPic(thing) and ((tmfloorpic'; D = 'if G_PlayingEngineVersion >= VERSION204 then if (thing.flags2_ex and MF2_EX_CANTLEAVEFLOORPIC <> 0) and ((tmfloorpic'
     Hexen = 'if (thing.flags2 and MF2_CANTLEAVEFLOORPIC <> 0) and ((tmfloorpic' }
  @{ F = 'TMapGameRules.UpdateFloorClip(thing);'; D = '<<B:UpdateFloorClip>>' }
  @{ F = 'if ld.special <> 0 then TMapGameRules.CrossSpecialLine(ld, oldside, thing);'; D = 'if ld.special <> 0 then begin <<B:CrossSpecialLine>> end;' }

  # --- P_ThingsInSameZ (Doom; gli altri giochi sono in $NotTextual) ---
  @{ F = 'TMapGameRules.KeepsOldSameZ(A, B)'; Doom = '((A.flags2_ex and MF2_EX_ONMOBJ = 0) and (B.flags2_ex and MF2_EX_ONMOBJ = 0))'; All = $true }

  # --- PIT_ChangeSector (IdTech1\Base\p_map.pas: lo scheletro; il corpo che schiaccia e il sangue sono regole del gioco) ---
  $csHead = 'function PIT_ChangeSector(thing: Pmobj_t): boolean; var'
  $csNote = 'le variabili locali sono passate dalla vecchia routine alle regole (CrunchBody, CrushBlood) che le usano'
  @{ R = 'PIT_ChangeSector'; F = 'function PIT_ChangeSector(thing: Pmobj_t): boolean; begin'
     Doom = "$csHead mo: Pmobj_t; plr: Pplayer_t; st: integer; bt: bloodtype_t; begin"; Heretic = "$csHead mo: Pmobj_t; begin"
     Hexen = "$csHead mo: Pmobj_t; st: integer; begin"; Strife = "$csHead mo: Pmobj_t; plr: Pplayer_t; begin"; Note = $csNote }
  @{ R = 'PIT_ChangeSector'; F = 'if TMapGameRules.IsCrushedBody(thing) then begin result := TMapGameRules.CrunchBody(thing); exit; end;'
     D = 'if thing.health <= 0 then begin <<B:CrunchBody>> end;'; Hexen = 'if (thing.flags and MF_CORPSE <> 0) and (thing.health <= 0) then begin <<B:CrunchBody>> end;' }
  @{ R = 'PIT_ChangeSector'; F = 'if TMapGameRules.IsDroppedItem(thing) then'; D = 'if thing.flags and MF_DROPPED <> 0 then'; Hexen = 'if thing.flags2 and MF2_DROPPED <> 0 then' }
  @{ R = 'PIT_ChangeSector'; F = 'TMapGameRules.CrushDamage'; D = '10'; Hexen = '1' }
  @{ R = 'PIT_ChangeSector'; F = 'TMapGameRules.CrushBlood(thing);'; D = '<<B:CrushBlood|map=exitr>>' }
  # --- PIT_CheckThing ---
  @{ R = 'PIT_CheckThing'; F = 'if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then'; Heretic = 'if (thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE)) = 0 then'
     Note = 'Heretic aveva una coppia di parentesi in piu'' attorno al primo operando' }
  @{ R = 'PIT_CheckThing'; F = 'blockdist: fixed_t; begin'; D = 'blockdist: fixed_t; <<V:CheckThingContact|map=cvA>> begin'; Hexen = 'blockdist: fixed_t; <<V:CheckThingContact|map=cvHexen>> begin'
     Note = 'solid e pushfactor sono passate alle funzioni P_ContactPickup e P_PushByContact che le usano' }
  @{ F = 'result := TMapGameRules.CheckThingContact(thing);'; D = '<<B:CheckThingContact>>' }
  # il contatto: i due blocchi che spingono una cosa e la coda della raccolta sono P_PushByContact e P_ContactPickup di p_map
  @{ R = 'PIT_CheckThing'; F = 'P_PushByContact(thing);'; D = '<<M:P_PushByContact>>'; All = $true }
  @{ R = 'PIT_CheckThing'; F = 'result := P_ContactPickup(thing);'; D = '<<M:P_ContactPickup>>' }
  @{ R = 'PIT_CheckThing'; F = 'TMapGameRules.CanBePushed(thing)'; D = '(thing.flags2_ex and MF2_EX_PUSHABLE <> 0) and (tmthing.flags2_ex and MF2_EX_CANNOTPUSH = 0)'
     Heretic = '(thing.flags2 and MF2_PUSHABLE <> 0) and (tmthing.flags2 and MF2_CANNOTPUSH = 0)'; Hexen = '(thing.flags2 and MF2_PUSHABLE <> 0) and (tmthing.flags2 and MF2_CANNOTPUSH = 0)'; All = $true }
  @{ R = 'PIT_CheckThing'; F = 'TMapGameRules.QuarterMomentum(tmthing.momx)'; D = 'tmthing.momx div 4'; Hexen = '_SHR2(tmthing.momx)'; All = $true }
  @{ R = 'PIT_CheckThing'; F = 'TMapGameRules.QuarterMomentum(tmthing.momy)'; D = 'tmthing.momy div 4'; Hexen = '_SHR2(tmthing.momy)'; All = $true }
  @{ R = 'PIT_CheckThing'; F = 'TMapGameRules.PicksUpOnContact'; D = 'tmflags and MF_PICKUP <> 0'; Strife = 'tmthing.player <> nil' }
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
  'Hexen|PTR_UseTraverse' = 'la copia unica calcola side e li una volta (P_PointOnLineSide e intr.d.line non hanno effetti); i tre pezzi di Hexen sono UseBlockedByWall, UseNonSpecialLine e UseSpecialLine, righe vecchie alla lettera'
  'Hexen|P_SectorJumpOverhead' = 'Hexen metteva "result := 0" prima del controllo del cielo e usciva con "exit" se il giocatore vola: stesso risultato di "result := 0; exit"'
  'Heretic|P_ThingsInSameZ' = 'la copia unica e'' il testo di Doom con KeepsOldSameZ falso: sotto la 2.07 meta'' altezza e intervalli chiusi (= P_ThingsInSameZ206), dalla 2.07 P_ThingHeightOffsZ e intervalli aperti (= il resto della vecchia routine)'
  'Hexen|P_ThingsInSameZ' = 'come Heretic'
  'Strife|P_ThingsInSameZ' = 'come Heretic'
  'Heretic|P_ThingsInSameZ206' = 'assorbita da P_ThingsInSameZ (ramo sotto la 2.07)'
  'Hexen|P_ThingsInSameZ206' = 'assorbita da P_ThingsInSameZ (ramo sotto la 2.07)'
  'Strife|P_ThingsInSameZ206' = 'assorbita da P_ThingsInSameZ (ramo sotto la 2.07)'
  'Heretic|P_ThingHeightOffsZ' = 'assorbita da P_ThingsInSameZ (_getheightoffs dalla 2.07)'
  'Hexen|P_ThingHeightOffsZ' = 'assorbita da P_ThingsInSameZ (_getheightoffs dalla 2.07)'
  'Strife|P_ThingHeightOffsZ' = 'assorbita da P_ThingsInSameZ (_getheightoffs dalla 2.07)'
}

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_map' -BaseFiles 'IdTech1\Base\p_map.pas', 'IdTech1\Base\p_secnodes.pas' `
  -Extra @{ S = 'IdTech1\Base\p_secnodes.pas'; M = 'IdTech1\Base\p_map.pas' } -RulesUnit $rulesUnit -Class 'TMapGameRules' -Expansions $Expansions -NotTextual $NotTextual -Maps @{ exitr = @(,@('exit;', 'result := true; exit;')); cvA = @(,@('damage: integer;', 'solid: boolean; damage: integer; pushfactor: fixed_t;')); cvHexen = @(@('damage: integer;', 'solid: boolean; damage: integer;'), @('lmo: Pmobj_t;', 'lmo: Pmobj_t; pushfactor: fixed_t;')) }
exit $bad
