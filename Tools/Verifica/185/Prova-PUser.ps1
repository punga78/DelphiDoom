<#
  Issue #185, passo 2f-1 (p_user in copia unica): prova meccanica delle routine parametriche.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1 e Prova-PMobj.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_user.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (IdTech1\Base\p_user.pas, le unit di Base per piu' giochi o la unit delle regole
  del gioco), sostituisce ogni chiamata a TUserGameRules con il corpo della regola di quel gioco e confronta il
  risultato con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PUser.ps1 [-Base c6c8903c] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = 'c6c8903c',
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife')
)
$ErrorActionPreference = 'Stop'
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

. (Join-Path $PSScriptRoot 'Prova-Common.ps1')


# ---------------------------------------------------------------------------------------------------------------
# Le sostituzioni (vedi Prova-Common.ps1). L'ordine conta: le voci di un gioco solo vengono prima di quelle di tutti.
# ---------------------------------------------------------------------------------------------------------------
$Expansions = @(
  # --- P_Thrust (Doom e Strife; Heretic e Hexen sono in $NotTextual) ---
  @{ R = 'P_Thrust'; F = 'FixedMul(TUserGameRules.ThrustMove(player, move), '; D = 'FixedMul(move, '; All = $true }

  # --- P_DeathThink (Doom, Heretic, Strife; Hexen e' il metodo DeathThink) ---
  @{ R = 'P_DeathThink'; F = 'if TUserGameRules.OwnsDeathThink then begin TUserGameRules.DeathThink(player); exit; end;'; D = ''; Note = 'la copia unica passa alla regola DeathThink solo quando OwnsDeathThink (Hexen, che ha il suo metodo)' }

  # --- la famiglia di P_CalcHeight ---
  # il rialzo fisso del volo: Heretic e Hexen avvolgono il calcolo del rimbalzo con if / else
  @{ F = 'if TUserGameRules.FlyBobs(player) then player.bob := FRACUNIT div 2 else begin'; D = ''
     Heretic = 'if (player.mo.flags2 and MF2_FLY <> 0) and not onground then player.bob := FRACUNIT div 2 else begin'
     Hexen = 'if (player.mo.flags2 and MF2_FLY <> 0) and not onground then player.bob := FRACUNIT div 2 else begin'
     Note = 'la copia unica ha sempre il ramo del volo (FlyBobs), falso in Doom e Strife: il "begin ... end" in piu'' si toglie' }
  @{ F = 'player.bob := MAXBOB; end;'; D = 'player.bob := MAXBOB;'; Heretic = $null; Hexen = $null }
  @{ R = 'P_CalcHeight'; F = 'if TUserGameRules.IsMorphed(player) then player.crouchheight := 0 else begin'; D = ''
     Heretic = 'if player.chickenTics <> 0 then player.crouchheight := 0 else begin'; Hexen = 'if player.morphTics <> 0 then player.crouchheight := 0 else begin'
     Note = 'la copia unica ha sempre il ramo del pollo o del maiale (IsMorphed), falso in Doom e Strife: il "begin ... end" in piu'' si toglie' }
  @{ R = 'P_CalcHeight'; F = 'player.mo.height := player.mo.info.height - player.crouchheight; end; end; end; if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then'
     D = 'player.mo.height := player.mo.info.height - player.crouchheight; end; end; if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then'; Heretic = $null; Hexen = $null }
  @{ F = 'if TUserGameRules.IsMorphed(player) then player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT) else'; D = ''
     Heretic = 'if player.chickenTics <> 0 then player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT) else'
     Hexen = 'if player.morphTics <> 0 then player.viewz := player.mo.z + player.viewheight - (20 * FRACUNIT) else' }
  @{ F = 'TUserGameRules.AdjustViewZ(player);'; D = '<<B:AdjustViewZ>>' }
  @{ F = 'TUserGameRules.ClampViewZ(player);'; D = '<<B:ClampViewZ>>' }
  @{ F = 'TMapGameRules.SlopesVersion'; Doom = 'VERSION122'; Heretic = 'VERSION115'; Hexen = 'VERSION142'; Strife = 'VERSION122'; All = $true }
  @{ F = 'if TUserGameRules.KeepsOldViewZInAir then player.oldviewz := oldviewz;'; D = 'player.oldviewz := oldviewz;'; Hexen = '' }
  @{ F = '+ TUserGameRules.SlopesFloorMargin'; D = '+ 4 * FRACUNIT'; Strife = ''; All = $true }

  # --- P_MovePlayer ---
  # le variabili: la copia unica non ha quelle del movimento (movefactor in Doom e Strife; fly, onair e mfactor in Heretic, onair e fly in Hexen)
  @{ R = 'P_MovePlayer'; F = 'look2: integer; cmd_crouch, cmd_jump: byte; begin'
     D = 'look2: integer; movefactor: fixed_t; cmd_crouch, cmd_jump: byte; begin'
     Heretic = 'look2: integer; fly: integer; onair: boolean; mfactor: integer; cmd_crouch, cmd_jump: byte; begin'
     Hexen = 'look2: integer; fly: integer; onair: boolean; cmd_crouch, cmd_jump: byte; begin'
     Note = 'le variabili locali del movimento e del volo sono ora nelle regole MoveByCommand e AfterMove (le stesse dichiarazioni)' }
  @{ R = 'P_MovePlayer'; F = 'TUserGameRules.SetOnGround(player);'; D = '<<B:SetOnGround>>' }
  @{ R = 'P_MovePlayer'; F = 'else if TUserGameRules.MapNoJump then'; D = 'else if (gamemapinfo <> nil) and gamemapinfo.nojump then'; Hexen = 'else if P_GetMapNoJump(gamemap) then' }
  @{ R = 'P_MovePlayer'; F = 'else if TUserGameRules.MapNoCrouch then'; D = 'else if (gamemapinfo <> nil) and gamemapinfo.nocrouch then'; Hexen = 'else if P_GetMapNoCrouch(gamemap) then' }
  @{ R = 'P_MovePlayer'; F = 'TUserGameRules.MoveByCommand(player, cmd, cmd_jump, cmd_crouch);'; D = '<<B:MoveByCommand>>' }
  @{ R = 'P_MovePlayer'; F = 'look := TUserGameRules.LookUpDown(cmd);'; D = 'look := cmd.lookupdown;'; Heretic = 'look := cmd.lookfly and 15;'; Hexen = 'look := cmd.lookfly and 15;' }
  @{ R = 'P_MovePlayer'; F = 'if TUserGameRules.AimsAtTarget(player) then player.centering := true else'; D = 'if player.angletargetticks > 0 then player.centering := true else'; Heretic = ''; Hexen = ''; All = $true }
  @{ R = 'P_MovePlayer'; F = 'if TUserGameRules.AimsAtTarget(player) then player.forwarding := true else'; D = 'if player.angletargetticks > 0 then player.forwarding := true else'; Heretic = ''; Hexen = '' }
  @{ R = 'P_MovePlayer'; F = 'if not TUserGameRules.JumpsAlways then P_JumpAndCrouch(player, cmd_jump, cmd_crouch);'; D = '<<S:P_JumpAndCrouch>>'; Strife = ''
     Note = 'il salto e l''accovacciamento sono una procedura (P_JumpAndCrouch): in Strife stanno fuori dal blocco del nuovo motore (JumpsAlways), negli altri dentro' }
  @{ R = 'P_MovePlayer'; F = 'if TUserGameRules.JumpsAlways then P_JumpAndCrouch(player, cmd_jump, cmd_crouch);'; D = ''; Strife = '<<S:P_JumpAndCrouch>>' }
  @{ R = 'P_MovePlayer'; F = 'TUserGameRules.AfterMove(player, cmd);'; D = '<<B:AfterMove>>' }

  # --- P_PlayerThink (Doom, Heretic, Strife: TPlayerThinker.Think; Hexen e' il metodo PlayerThink) ---
  @{ R = 'P_PlayerThink'; F = 'class procedure TPlayerThinker.Think(player: Pplayer_t); var cmd: Pticcmd_t; sec: Psector_t; begin'
     D = 'procedure P_PlayerThink(player: Pplayer_t); var cmd: Pticcmd_t; newweapon: weapontype_t; sec: Psector_t; begin'
     Note = 'la variabile newweapon e'' ora nella regola ChangeWeapon, l''unica che la usa' }
  @{ R = 'P_PlayerThink'; F = 'if TUserGameRules.GuardsNilMobj then if player.mo = nil then exit;'; D = 'if player.mo = nil then exit;'; Heretic = ''; Strife = ''
     Note = 'Heretic e Strife non controllavano che il giocatore avesse una cosa (GuardsNilMobj e'' falso)' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.BeforeMove(player);'; D = '<<B:BeforeMove>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.AfterSector(player, cmd);'; D = '<<B:AfterSector>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.ChangeWeapon(player, cmd);'; D = '<<B:ChangeWeapon>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.BeforeUseLines(player);'; D = '<<B:BeforeUseLines>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.BeforePsprites(player);'; D = '<<B:BeforePsprites>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.CountDown(player);'; D = '<<B:CountDown>>' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.Colormap(player);'; D = '<<B:Colormap>>' }
  @{ R = 'P_PlayerThink'; F = 'TPlayerColormap.Standard(player);'; D = '<<C:TPlayerColormap.Standard>>'; Strife = $null
     Note = 'il colore di Doom e Heretic e'' un metodo di TPlayerColormap (stesso testo)' }
  @{ R = 'P_PlayerThink'; F = 'TUserGameRules.AtEnd(player);'; D = '<<B:AtEnd>>' }

  # --- gli artefatti di Heretic e Hexen (IdTech1\Base\DelphiDoom.Engine.World.PlayerArtifacts.pas) ---
  @{ R = 'P_GetPlayerNum'; F = 'for i := 0 to MAXPLAYERS - 1 do if player = @players[i] then begin result := i; exit; end;'; D = $null
     Hexen = 'for i := 0 to MAXPLAYERS - 1 do begin if player = @players[i] then begin result := i; exit; end; end;'
     Note = 'Hexen scriveva un "begin ... end" attorno al solo if del for: stesso significato' }
  @{ R = 'P_PlayerRemoveArtifact'; F = 'if TUserGameRules.SlotIsEmpty(player, slot) then exit;'; D = ''; Hexen = 'if player.inventory[slot].count = 0 then exit;'
     Note = 'la guardia "slot vuoto" e'' una regola (SlotIsEmpty): solo Hexen la aveva' }
  @{ R = 'P_PlayerRemoveArtifact'; F = 'TUserGameRules.ClearFreedSlot(player);'; D = '<<B:ClearFreedSlot>>' }
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
  'Heretic|P_Thrust' = 'le tre rami (volo, ghiaccio, normale) aggiungono a momx e momy lo stesso prodotto con move oppure con move div 4: ThrustMove da'' il valore (le condizioni sono quelle vecchie, lette dal giocatore e dal settore senza effetti collaterali: la regola e'' chiamata due volte, una per asse)'
  'Hexen|P_Thrust' = 'come Heretic, con la condizione del ghiaccio data da P_GetThingFloorType(player.mo) = FLOOR_ICE'
}

# le routine che sono tutte di un gioco: metodi delle regole con il testo vecchio
$Methods = @{
  'Hexen|P_PlayerThink' = 'PlayerThink'; 'Hexen|P_DeathThink' = 'DeathThink'
}

$Alias = @{ 'Doom|P_PlayerThink' = 'TPlayerThinker.Think'; 'Heretic|P_PlayerThink' = 'TPlayerThinker.Think'; 'Strife|P_PlayerThink' = 'TPlayerThinker.Think' }

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_user' -BaseFiles 'IdTech1\Base\p_user.pas', 'IdTech1\Base\DelphiDoom.Engine.World.PlayerExtras.pas', 'IdTech1\Base\DelphiDoom.Engine.World.PlayerThinker.pas', 'IdTech1\Base\DelphiDoom.Engine.World.PlayerArtifacts.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.UserRules.pas' -Class 'TUserGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias -Extra @{ S = 'IdTech1\Base\p_user.pas'; C = 'IdTech1\Base\DelphiDoom.Engine.World.PlayerColormap.pas' }
exit $bad
