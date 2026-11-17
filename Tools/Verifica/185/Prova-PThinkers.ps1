<#
  Issue #185, passo 2f-6 (thinker rimasti in copia unica): prova meccanica delle routine unificate.

  Il confronto e' in Prova-Common.ps1 (come Prova-PSpec.ps1). Per ogni gioco e per ogni routine della vecchia
  <Gioco>\<unit>.pas (presa dal commit di partenza con git show) prende il testo della routine unificata in IdTech1\Base\
  (o delle regole del gioco), sostituisce ogni chiamata a TSpecGameRules con il corpo della regola di quel gioco e
  confronta il risultato con la routine vecchia, tolti commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in $NotTextual
    DIVERSA       errore: la prima differenza e' stampata

  Unit provate: p_lights (Doom, Heretic, Strife), p_plats (Doom, Strife), p_telept (Doom, Strife: solo le due
  routine silenziose, spostate in DelphiDoom.Engine.World.SilentTeleport; EV_Teleport resta della unit del gioco).

  Uso:  powershell -NoProfile -File Tools\Verifica\185\Prova-PThinkers.ps1 [-Base 748ee6f2c] [-Units p_lights,p_plats,p_telept]
  Esce con il numero delle routine DIVERSE.
#>
param(
  [string]$Base = '748ee6f2c',
  [string]$BasePlats = '8d46e9c5f',
  [string[]]$Units = @('p_lights', 'p_plats', 'p_telept')
)
$ErrorActionPreference = 'Stop'
$Units = @($Units | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

. (Join-Path $PSScriptRoot 'Prova-Common.ps1')

$bad = 0

if ($Units -contains 'p_lights') {
  $Expansions = @(
    @{ F = 'TSpecGameRules.SectorSpecialAfterLight(sector.special)'
       Doom = 'sector.special and not 31'; Strife = 'sector.special and not 31'; Heretic = '0'
       Note = 'il settore perde il tipo non generalizzato (Doom e Strife: and not 31) o tutto (Heretic: 0): regola SectorSpecialAfterLight' }
    @{ F = 'not TSpecGameRules.LightingBusy(sec)'
       Doom = 'not P_SectorActive(lighting_special, sec)'; Strife = 'not P_SectorActive(lighting_special, sec)'
       Note = 'il controllo del settore occupato e'' la regola LightingBusy' }
  )
  $NotTextual = @{
    'Heretic|EV_StartLightStrobing' = 'era una procedura: ora e'' la funzione di Doom (result := 1 quando trova un settore, nessun chiamante lo legge in Heretic); il controllo del settore occupato `not LightingBusy(sec)` e'' `sec.specialdata = nil` (regola LightingBusy di Heretic: sec.specialdata <> nil)'
    'Heretic|EV_TurnTagLightsOff'   = 'era una procedura: ora e'' la funzione di Doom (result := 1 quando trova un settore, nessun chiamante lo legge in Heretic)'
    'Heretic|EV_LightTurnOn'        = 'era una procedura: ora e'' la funzione di Doom (result := 1 quando trova un settore, nessun chiamante lo legge in Heretic)'
  }
  $bad += Invoke-Prova -Root $root -Base $Base -Games @('Doom', 'Heretic', 'Strife') -Unit 'p_lights' `
    -BaseFiles 'IdTech1\Base\p_lights.pas' `
    -RulesUnit 'DelphiDoom.Engine.World.SpecRules.pas' -Class 'TSpecGameRules' -Expansions $Expansions -NotTextual $NotTextual
}

if ($Units -contains 'p_plats') {
  # ondata 9: Doom, Heretic e Strife in IdTech1\Base\p_plats.pas; il vecchio testo e' quello di $BasePlats
  # (Doom e Strife: la copia di Base di allora; Heretic: IdTech1\Heretic\p_plats.pas)
  $Expansions = @(
    @{ F = 'TSpecGameRules.PlatIsToggle(_type)'; Doom = '_type = toggleUpDn'; Strife = '_type = toggleUpDn'
       Note = 'il ramo dei toggle e'' la regola PlatIsToggle' }
    @{ F = 'TSpecGameRules.PlatNextSector(line, secnum)'; Doom = 'P_FindSectorFromLineTag2(line, secnum) >= 0'; Strife = 'P_FindSectorFromLineTag2(line, secnum) >= 0'
       Note = 'la ricerca del settore e'' la regola PlatNextSector' }
    @{ F = 'TSpecGameRules.PlatSectorBusy(sec)'; Doom = 'P_SectorActive(floor_special, sec)'; Strife = 'P_SectorActive(floor_special, sec)'
       Note = 'il controllo del settore occupato e'' la regola PlatSectorBusy' }
    @{ F = 'TSpecGameRules.PlatAttach(plat.sector, plat)'; Doom = 'plat.sector.floordata := plat'; Strife = 'plat.sector.floordata := plat'
       Note = 'il campo del settore e'' la regola PlatAttach' }
    @{ F = 'TSpecGameRules.PlatDetach(Pplat_t(P_World.ActivePlats[i]).sector)'
       Doom = 'Pplat_t(P_World.ActivePlats[i]).sector.floordata := nil'; Strife = 'Pplat_t(P_World.ActivePlats[i]).sector.floordata := nil'
       Heretic = 'Pplat_t(P_World.ActivePlats[i]).sector.specialdata := nil'
       Note = 'il campo del settore e'' la regola PlatDetach' }
  )
  $NotTextual = @{
    'Heretic|EV_DoPlat' = 'il ciclo sui settori calcolava il successivo prima del corpo (P_FindSectorFromLineTag con ritorno), ora PlatNextSector lo calcola in testa al giro: stessa sequenza di settori (il corpo non cambia i tag); `sec.specialdata <> nil` e'' PlatSectorBusy, `sec.specialdata := plat` PlatAttach; senza toggle (PlatIsToggle e'' false) resta result := 0 e P_ActivateInStasis solo per perpetualRaise'
    'Heretic|P_ActivateInStasis' = 'la copia di Base legge Pplat_t(P_World.ActivePlats[i]) in una variabile locale: stesso test e stesse assegnazioni'
    'Heretic|EV_StopPlat' = 'era una procedura: ora e'' la funzione di Doom (result 1 se ferma una piattaforma); i chiamanti la usano come istruzione e nessuno prende l''indirizzo'
  }
  $bad += Invoke-Prova -Root $root -Base $BasePlats -Games @('Doom', 'Heretic', 'Strife') -Unit 'p_plats' `
    -BaseFiles 'IdTech1\Base\p_plats.pas' `
    -OldPaths @{ Doom = 'IdTech1/Base/p_plats.pas'; Strife = 'IdTech1/Base/p_plats.pas' } `
    -RulesUnit 'DelphiDoom.Engine.World.SpecRules.pas' -Class 'TSpecGameRules' -Expansions $Expansions -NotTextual $NotTextual
}
if ($Units -contains 'p_telept') {
  # le routine silenziose di Doom e Strife sono in Base; EV_Teleport (propria di ogni gioco) resta nella unit del gioco
  $bad += Invoke-Prova -Root $root -Base $Base -Games @('Doom', 'Strife') -Unit 'p_telept' `
    -BaseFiles 'IdTech1\Base\DelphiDoom.Engine.World.SilentTeleport.pas' `
    -RulesUnit 'p_telept.pas' -Class 'TSpecGameRules' -Expansions @()
}

exit $bad