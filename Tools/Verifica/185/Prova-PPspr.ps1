<#
  Issue #185, passo 2f-3 (p_pspr in copia unica): prova meccanica delle routine unificate.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1, Prova-PMobj.ps1, Prova-PUser.ps1 e Prova-PInter.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_pspr.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_pspr.pas) o della unit delle regole del gioco, sostituisce ogni
  chiamata a TPspriteGameRules con il corpo della regola di quel gioco e confronta il risultato con la routine
  vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PPspr.ps1 [-Base 4232a8e03] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = '4232a8e03',
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
  # P_MovePsprites: il mirino di Strife e' il corpo di AfterMovePsprites, negli altri giochi la regola e' vuota
  @{ R = 'P_MovePsprites'; F = 'TPspriteGameRules.AfterMovePsprites(player);'; D = '<<B:AfterMovePsprites>>' }

  # P_DropWeapon: lo stato in cui scende l'arma
  @{ R = 'P_DropWeapon'; F = 'P_SetPsprite(player, Ord(ps_weapon), TPspriteGameRules.DropWeaponState(player));'
     D = 'P_SetPsprite(player, Ord(ps_weapon), <<B:DropWeaponState|lead=result:=|strip=;>>);'
     Heretic = '<<B:DropWeaponState|map=Drop>>'
     Hexen = 'P_SetPsprite(player, Ord(ps_weapon), <<B:DropWeaponState|lead=result:=|strip=;>>)'
     Note = 'la regola da'' lo stato e P_DropWeapon lo passa a P_SetPsprite (Heretic: una chiamata per ramo, qui una sola con il ramo scelto dalla regola); il vecchio Hexen non aveva il punto e virgola prima di end' }

  # A_ReFire: il controllo di munizioni o mana
  @{ R = 'A_ReFire'; F = 'TPspriteGameRules.CheckSupplies(player);'; D = '<<B:CheckSupplies>>' }

  # A_Lower: l'arma scende di colpo (pollo, maiale) e il cambio dell'arma di mbf21 (Doom)
  @{ R = 'A_Lower'; F = 'if TPspriteGameRules.StaysLowered(player) then psp.sy := WEAPONBOTTOM else psp.sy := psp.sy + LOWERSPEED;'
     D = 'if <<B:StaysLowered|lead=result:=|strip=;>> then psp.sy := WEAPONBOTTOM else psp.sy := psp.sy + LOWERSPEED;'
     Doom = 'psp.sy := psp.sy + LOWERSPEED;'
     Strife = 'psp.sy := psp.sy + LOWERSPEED;'
     Note = 'in Doom e Strife la regola StaysLowered e'' false: il ramo "then" non c''e'' mai' }
  @{ R = 'A_Lower'; F = 'TPspriteGameRules.AfterLowered(player);'; D = '<<B:AfterLowered>>' }

  # A_Raise: lo stato a cui va l'arma alzata; il vecchio testo lo metteva in newstate (Doom, Heretic, Strife)
  @{ R = 'A_Raise'; F = 'procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t); begin'
     D = 'procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t); var newstate: statenum_t; begin'
     Hexen = 'procedure A_Raise(player: Pplayer_t; psp: Ppspdef_t); begin'
     Note = 'la variabile locale newstate del vecchio testo e'' il risultato della regola RaisedState' }
  @{ R = 'A_Raise'; F = 'P_SetPsprite(player, Ord(ps_weapon), TPspriteGameRules.RaisedState(player));'
     D = 'newstate := <<B:RaisedState|lead=result:=|strip=;>>; P_SetPsprite(player, Ord(ps_weapon), newstate);'
     Heretic = '<<B:RaisedState|map=NewState>> P_SetPsprite(player, Ord(ps_weapon), newstate);'
     Hexen = '<<B:RaisedState|map=Raise>>' }
)

$Maps = @{
  # Heretic: i due rami della regola diventano una P_SetPsprite ciascuno, come nel vecchio P_DropWeapon
  Drop = @(
    , @('result := statenum_t(wpnlev2info[Ord(player.readyweapon)].downstate)', 'P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev2info[Ord(player.readyweapon)].downstate))')
    , @('result := statenum_t(wpnlev1info[Ord(player.readyweapon)].downstate)', 'P_SetPsprite(player, Ord(ps_weapon), statenum_t(wpnlev1info[Ord(player.readyweapon)].downstate))')
  )
  # Heretic, A_Raise: result e' newstate
  NewState = @(
    , @('result := statenum_t(wpnlev2info[Ord(player.readyweapon)].readystate)', 'newstate := statenum_t(wpnlev2info[Ord(player.readyweapon)].readystate)')
    , @('result := statenum_t(wpnlev1info[Ord(player.readyweapon)].readystate)', 'newstate := statenum_t(wpnlev1info[Ord(player.readyweapon)].readystate)')
  )
  # Hexen, A_Raise: i due rami della regola sono le due P_SetPsprite del vecchio testo
  Raise = @(
    , @('result := S_FAXEREADY_G', 'P_SetPsprite(player, Ord(ps_weapon), S_FAXEREADY_G)')
    , @('result := statenum_t(WeaponInfo[Ord(player.readyweapon), Ord(player._class)].readystate)', 'P_SetPsprite(player, Ord(ps_weapon), statenum_t(WeaponInfo[Ord(player.readyweapon), Ord(player._class)].readystate))')
  )
}

$NotTextual = @{}
$Methods = @{}
$Alias = @{}

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_pspr' -BaseFiles 'Base\p_pspr.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.PspriteRules.pas' -Class 'TPspriteGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias -Maps $Maps
exit $bad
