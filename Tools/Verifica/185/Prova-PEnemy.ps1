<#
  Issue #185, passo 2f-4 (p_enemy in copia unica): prova meccanica delle routine unificate.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1, Prova-PMobj.ps1, Prova-PUser.ps1, Prova-PInter.ps1 e
  Prova-PPspr.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_enemy.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_enemy.pas, Base\DelphiDoom.Engine.World.EnemyMoveSpecials.pas) o della
  unit delle regole del gioco, sostituisce ogni chiamata a TEnemyGameRules con il corpo della regola di quel gioco e
  confronta il risultato con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PEnemy.ps1 [-Base 06d774591] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = '06d774591',
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
  # P_Move: il corpo di Doom, Heretic e Strife e' P_MoveDefault (Hexen: metodo Move delle regole, testo spostato)
  @{ R = 'P_Move'; F = 'function P_MoveDefault(actor: Pmobj_t): boolean;'; D = 'function P_Move(actor: Pmobj_t): boolean;'
     Note = 'la routine di Base si chiama P_MoveDefault e P_Move sceglie tra lei e il metodo Move delle regole (Hexen)' }
  @{ R = 'P_Move'; F = 'tryy: fixed_t; try_ok: boolean; begin'; D = 'tryy: fixed_t; ld: Pline_t; try_ok: boolean; ret1, ret2: boolean; begin'
     Note = 'le variabili ld, ret1 e ret2 sono ora della routine UseHitLines (il ciclo sulle linee ha cambiato unit)' }
  @{ R = 'P_Move'; F = 'I_Error(TEnemyGameRules.WeirdMoveDirMessage, [Ord(actor.movedir)]);'
     D = 'I_Error(''P_Move(): Weird actor.movedir = %d'', [Ord(actor.movedir)]);'
     Doom = 'I_Error(''P_Move(): Weird actor->movedir = %d'', [Ord(actor.movedir)]);'
     Note = 'il testo dell''errore e'' la costante WeirdMoveDirMessage di ogni gioco (Doom scrive actor->movedir, gli altri actor.movedir)' }
  @{ R = 'P_Move'; F = 'result := TEnemyGameRules.UseSpecialLines(actor);'; D = '<<S:TEnemyMoveSpecials.UseHitLines>>'
     Note = 'il ciclo sulle linee colpite e'' TEnemyMoveSpecials.UseHitLines (Doom, Heretic, Strife), con ld, ret1 e ret2 separati come prima' }
  @{ R = 'P_Move'; F = 'else TEnemyGameRules.ClearFloating(actor);'; D = 'else <<B:ClearFloating>>'
     Strife = 'else begin <<B:ClearFloating>> end;' }

  # P_NewChaseDir: bersaglio nullo, chi puo' arretrare dal corpo a corpo, arma che fa fuggire
  @{ R = 'P_NewChaseDir'; F = 'if target = nil then begin TEnemyGameRules.NoTarget(actor); exit; end;'
     D = 'if target = nil then <<B:NoTarget>>'
     Strife = 'if target = nil then begin <<B:NoTarget>> exit; end;'
     Note = 'il bersaglio nullo e'' la regola NoTarget (Doom, Heretic, Hexen: I_Error, che non torna; Strife: stato di partenza e uscita)' }
  @{ R = 'P_NewChaseDir'; F = 'TEnemyGameRules.CanBackAway(actor) and'
     D = ''
     Doom = '(<<B:CanBackAway|lead=result:=|strip=;>>) and'
     Note = 'solo Doom esclude il teschio e i suoi eredi (CanBackAway); negli altri giochi la regola e'' sempre vera' }
  @{ R = 'P_NewChaseDir'; F = 'TEnemyGameRules.FleesMeleeWeapon(Pplayer_t(target.player))'
     D = '(<<B:FleesMeleeWeapon|lead=result:=|strip=;|map=Flee>>)'
     Note = 'l''arma che fa fuggire e'' la regola FleesMeleeWeapon (il giocatore e'' Pplayer_t(target.player))' }
)

$Maps = @{
  Flee = @(
    , @('player.readyweapon', 'Pplayer_t(target.player).readyweapon')
    , @('player._class', 'Pplayer_t(target.player)._class')
  )
}

$NotTextual = @{
  'Heretic|P_NewChaseDir' = 'il vecchio testo sceglie la tabella dell''arma (livello 1 o 2 del potere) con la funzione annidata _weaponinfo, che restituisce un puntatore; la regola FleesMeleeWeapon fa lo stesso con un if su pw_weaponlevel2 e legge mbf21bits dalla stessa tabella (wpnlev2info o wpnlev1info) indicizzata da readyweapon: stessa espressione, il resto del testo e'' uguale alle altre'
}
$Methods = @{ 'Hexen|P_Move' = 'Move' }
$Alias = @{ 'P_Move' = 'P_MoveDefault' }
$Extra = @{ S = 'Base\DelphiDoom.Engine.World.EnemyMoveSpecials.pas' }

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_enemy' `
  -BaseFiles 'Base\p_enemy.pas' -Extra $Extra `
  -RulesUnit 'DelphiDoom.Engine.World.EnemyRules.pas' -Class 'TEnemyGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias -Maps $Maps
exit $bad
