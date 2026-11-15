<#
  Issue #185, passo 2g (p_spec e p_switch in copia unica): prova meccanica delle routine unificate.

  Il confronto e' in Prova-Common.ps1 (comune a Prova-PMap.ps1, Prova-PMobj.ps1, Prova-PUser.ps1, Prova-PInter.ps1,
  Prova-PPspr.ps1 e Prova-PEnemy.ps1).

  Per ogni gioco e per ogni routine della vecchia <Gioco>\p_spec.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (Base\p_spec.pas) o della unit delle regole del gioco
  (DelphiDoom.Engine.World.SpecRules.pas), sostituisce ogni chiamata a TSpecGameRules con il corpo della regola di quel
  gioco e confronta il risultato con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PSpec.ps1 [-Base aecc33fcd] [-Games Doom,Heretic]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = 'aecc33fcd',
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife')
)
$ErrorActionPreference = 'Stop'
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

. (Join-Path $PSScriptRoot 'Prova-Common.ps1')

$Expansions = @(
  @{ R = 'P_FindHighestFloorSurrounding'; F = 'result := TSpecGameRules.HighestFloorStart;'; D = '<<B:HighestFloorStart>>'
     Note = 'il punto di partenza e'' la regola HighestFloorStart (la soglia di versione del gioco)' }
  @{ R = 'P_FindLowestCeilingSurrounding'; F = 'result := TSpecGameRules.LowestCeilingStart;'; D = '<<B:LowestCeilingStart>>'
     Note = 'il punto di partenza e'' la regola LowestCeilingStart' }
  @{ R = 'P_FindHighestCeilingSurrounding'; F = 'result := TSpecGameRules.HighestCeilingStart;'; D = '<<B:HighestCeilingStart>>'
     Note = 'il punto di partenza e'' la regola HighestCeilingStart' }
  @{ R = 'P_FindNextHighestFloor'; F = 'maxsecs := TSpecGameRules.AdjoiningSectorsLimit;'; D = '<<B:AdjoiningSectorsLimit|map=Max>>'
     Note = 'il limite dei settori adiacenti e'' la regola AdjoiningSectorsLimit (il suo risultato e'' maxsecs)' }
  @{ R = 'twoSidedS'; F = 'result := sector.lines[line].sidenum[1] <> -1;'; Doom = 'result := sector.lines[line].sidenum[1] <> -1'
     Note = 'la vecchia copia di Doom non aveva il punto e virgola finale: nessuna differenza' }
)

$Maps = @{
  Max = @(
    , @('result', 'maxsecs')
  )
}

$NotTextual = @{
  'Doom|getNextSector'    = 'forma diversa, stessa logica: la vecchia metteva oldcompatibility a true solo dentro if G_PlayingEngineVersion <= VERSION115; ora oldcompatibility := NextSectorCompatible (stessa condizione) e il controllo ML_TWOSIDED e'' sotto quel valore'
  'Heretic|getNextSector' = 'Heretic non ha il modo nuovo: un lato solo da'' nil, poi frontsector = sec da'' backsector senza il confronto con sec. E'' la forma di Doom con oldcompatibility sempre vera (NextSectorCompatible = true): stesso risultato'
  'Hexen|getNextSector'   = 'come Heretic: oldcompatibility sempre vera (NextSectorCompatible = true)'
  'Strife|getNextSector'  = 'la vecchia valutava G_NeedsCompatibilityMode due volte (e'' una lettura di globali, senza effetti): ora e'' letta una volta e tenuta in oldcompatibility'
  'Doom|twoSided'         = 'la vecchia sceglieva con G_PlayingEngineVersion > VERSION115 (sidenum) o altrimenti il flag; ora TwoSidedByFlag = G_PlayingEngineVersion <= VERSION115 sceglie il flag: le stesse due strade, i rami scambiati'
  'Heretic|twoSided'      = 'solo il flag: TwoSidedByFlag = true'
  'Hexen|twoSided'        = 'solo sidenum[1]: TwoSidedByFlag = false'
  'Strife|twoSided'       = 'solo sidenum[1]: TwoSidedByFlag = false'
  'Doom|P_FindSectorFromLineTag'    = 'il tag e'' letto una volta prima del ciclo con la regola LineSectorTag (line.tag): la stessa condizione ad ogni giro'
  'Heretic|P_FindSectorFromLineTag' = 'idem (line.tag)'
  'Strife|P_FindSectorFromLineTag'  = 'idem (line.tag)'
  'Doom|P_FindSectorFromLineTag2'    = 'il tag e'' letto una volta prima del ciclo con la regola LineSectorTag (line.tag)'
  'Heretic|P_FindSectorFromLineTag2' = 'idem (line.tag)'
  'Strife|P_FindSectorFromLineTag2'  = 'idem (line.tag)'
  'Hexen|P_FindSectorFromLineTag2'   = 'il tag e'' letto una volta con la regola LineSectorTag (line.arg1 in Hexen)'
}

# Doom e Strife usano anche le due unit di famiglia (friction e pusher, ricerche nei settori); Heretic e Hexen solo Base\p_spec.pas
$bad = 0
$family = @($Games | Where-Object { $_ -in 'Doom', 'Strife' })
$others = @($Games | Where-Object { $_ -notin 'Doom', 'Strife' })
if ($family.Count -gt 0) {
  $bad += Invoke-Prova -Root $root -Base $Base -Games $family -Unit 'p_spec' `
    -BaseFiles 'Base\p_spec.pas', 'Base\DelphiDoom.Engine.World.FrictionPushers.pas', 'Base\DelphiDoom.Engine.World.SectorSearch.pas' `
    -RulesUnit 'DelphiDoom.Engine.World.SpecRules.pas' -Class 'TSpecGameRules' -Expansions $Expansions `
    -NotTextual $NotTextual -Maps $Maps
}
if ($others.Count -gt 0) {
  $bad += Invoke-Prova -Root $root -Base $Base -Games $others -Unit 'p_spec' `
    -BaseFiles 'Base\p_spec.pas' `
    -RulesUnit 'DelphiDoom.Engine.World.SpecRules.pas' -Class 'TSpecGameRules' -Expansions $Expansions `
    -NotTextual $NotTextual -Maps $Maps
}
exit $bad