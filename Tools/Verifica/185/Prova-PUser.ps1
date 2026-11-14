<#
  Issue #185, passo 2f-1 (p_user in copia unica): prova meccanica delle routine parametriche.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1 e Prova-PMobj.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_user.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_user.pas, le unit di Base per piu' giochi o la unit delle regole
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
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
  'Heretic|P_Thrust' = 'le tre rami (volo, ghiaccio, normale) aggiungono a momx e momy lo stesso prodotto con move oppure con move div 4: ThrustMove da'' il valore (le condizioni sono quelle vecchie, lette dal giocatore e dal settore senza effetti collaterali: la regola e'' chiamata due volte, una per asse)'
  'Hexen|P_Thrust' = 'come Heretic, con la condizione del ghiaccio data da P_GetThingFloorType(player.mo) = FLOOR_ICE'
}

# le routine che sono tutte di un gioco: metodi delle regole con il testo vecchio
$Methods = @{
  'P_PlayerThink' = 'PlayerThink'; 'Hexen|P_DeathThink' = 'DeathThink'
}

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_user' -BaseFiles 'Base\p_user.pas', 'Base\DelphiDoom.Engine.World.PlayerExtras.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.UserRules.pas' -Class 'TUserGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods
exit $bad
