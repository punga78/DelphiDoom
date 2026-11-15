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

  # --- 2f-2c: P_GiveArmor e P_SpawnDroppedMobj (Base\DelphiDoom.Engine.World.PickupGivers) ---
  @{ R = 'P_GiveArmor'; F = 'if TInterGameRules.AllowsNegativeArmor and (armortype < 0) then begin if player.armorpoints <> 0 then begin result := false; exit; end; armortype := -armortype; end;'; D = ''
     Strife = 'if armortype < 0 then begin if player.armorpoints <> 0 then begin result := false; exit; end; armortype := -armortype; end;'
     Note = 'il ramo dell''armatura negativa (AllowsNegativeArmor) e'' solo di Strife: negli altri giochi non c''e''' }
  @{ R = 'P_SpawnDroppedMobj'; F = 'if not TInterGameRules.NeedsCompatibility then'; Doom = 'if not G_NeedsCompatibilityMode then'; Heretic = 'if not compatibilitymode then' }
  @{ R = 'P_SpawnDroppedMobj'; F = 'if G_PlayingEngineVersion >= TInterGameRules.DroppedScatterVersion then'; Doom = 'if G_PlayingEngineVersion >= VERSION117 then'; Heretic = 'if G_PlayingEngineVersion >= VERSION207 then' }

  # --- 2f-2d: il filtro dei flag dell'inflictor (Base\p_inter.pas), uguale nei quattro giochi ---
  @{ R = 'P_DamageMobj'; F = 'if not P_DamageFlagFilter(target, inflictor, damage) then exit;'
     D = 'if inflictor <> nil then begin if inflictor.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then begin if target.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then exit; if target.flags3_ex and MF3_EX_FREEZEDAMAGERESIST <> 0 then if damage > 1 then damage := _SHR1(damage); end; if inflictor.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then begin if target.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then exit; if target.flags4_ex and MF4_EX_FLAMEDAMAGERESIST <> 0 then if damage > 1 then damage := _SHR1(damage); end; end;'
     Note = 'il blocco del congelamento e della fiamma e'' P_DamageFlagFilter: stessi controlli nello stesso ordine, senza effetti collaterali oltre a damage (parametro per riferimento)' }
)

# le routine la cui forma unificata non si riconduce al testo vecchio per sostituzione: perche' sono equivalenti
$NotTextual = @{
  'Doom|P_GiveBody' = 'GiveBodyUpTo e'' il vecchio testo con maxhealth come parametro; il valore e'' MaxPlayerHealth, cioe'' mobjinfo[Ord(MT_PLAYER)].spawnhealth (l''espressione che il vecchio testo scriveva tre volte, senza effetti collaterali)'
  'Heretic|P_GiveBody' = 'GiveBodyUpTo e'' il vecchio testo con maxhealth come parametro; MaxPlayerHealth e'' il vecchio if/else (pollo: p_maxchickenhealth, altrimenti spawnhealth), valutato una volta all''inizio come prima'
  'Hexen|P_GiveBody' = 'come Heretic: MaxPlayerHealth e'' P_MaxPlayerHealth(player), valutata una volta all''inizio come prima'
}

# le routine che sono metodi delle regole: testo vecchio con l'intestazione del metodo
$Methods = @{
  'Strife|P_GiveBody' = 'GiveBody'
  'P_TouchSpecialThing' = 'TouchSpecialThing'
  'P_DamageMobj' = 'DamageMobj'
}

$Alias = @{ 'Hexen|P_GiveArmor' = 'P_GiveArmor#hexen'; 'Hexen|P_SpawnDroppedMobj' = 'P_SpawnDroppedMobj#hexen' }

$bad = Invoke-Prova -Root $root -Base $Base -Games $Games -Unit 'p_inter' -BaseFiles 'Base\p_inter.pas', 'Base\DelphiDoom.Engine.World.SpecialRespawn.pas', 'Base\DelphiDoom.Engine.World.MinotaurSlam.pas', 'Base\DelphiDoom.Engine.World.PlayerArtifacts.pas', 'Base\DelphiDoom.Engine.World.PickupGivers.pas' `
  -RulesUnit 'DelphiDoom.Engine.World.InterRules.pas' -Class 'TInterGameRules' -Expansions $Expansions `
  -NotTextual $NotTextual -Methods $Methods -Alias $Alias
exit $bad
