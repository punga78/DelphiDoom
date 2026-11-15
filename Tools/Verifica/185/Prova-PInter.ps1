<#
  Issue #185, passo 2f-2 (p_inter in copia unica): prova meccanica delle routine parametriche.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1, Prova-PMobj.ps1 e Prova-PUser.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_inter.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_inter.pas, le unit di Base per piu' giochi o la unit delle regole
  del gioco), sostituisce ogni chiamata a TInterGameRules con il corpo della regola di quel gioco e confronta il
  risultato con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PInter.ps1 [-Base 5348560dc] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = '5348560dc',
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
  # --- 2f-2b: la famiglia di Heretic e Hexen (Base\DelphiDoom.Engine.World.SpecialRespawn e MinotaurSlam) ---
  @{ R = 'A_RestoreSpecialThing1'; F = 'TInterGameRules.RepositionSpecial(thing);'; D = '<<B:RepositionSpecial>>' }
  @{ R = 'P_MinotaurSlam'; F = 'HITDICE(TInterGameRules.MinotaurSlamDice)'; Heretic = 'HITDICE(6)'; Hexen = 'HITDICE(4)' }
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
}

# le routine che sono metodi delle regole: testo vecchio con l'intestazione del metodo
$Methods = @{
  'P_TouchSpecialThing' = 'TouchSpecialThing'
  'P_DamageMobj' = 'DamageMobj'
}

$Alias = @{}

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_inter' -BaseFiles 'Base\p_inter.pas', 'Base\DelphiDoom.Engine.World.SpecialRespawn.pas', 'Base\DelphiDoom.Engine.World.MinotaurSlam.pas', 'Base\DelphiDoom.Engine.World.PlayerArtifacts.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.InterRules.pas' -Class 'TInterGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias
exit $bad
