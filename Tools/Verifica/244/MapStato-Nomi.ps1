# Issue #244, ondata 5: tabella dei nomi storici dello scorrimento, del tiro e dell'uso di p_map e dei campi delle
# classi che li sostituiscono (usata da Migra-MapStato.ps1 e da Prova-MapStato.ps1).
# Ogni nome ha la classe e il campo; 'Solo' limita la sostituzione ai file indicati (nome del file senza percorso):
# serve dove un'altra unit ha un nome omonimo suo (topslope e bottomslope di p_sight, parametri e locali).
$MapStatoGroups = @{
  Slide = @(
    @{ Old = 'bestslidefrac'; Class = 'TMapSlide'; Field = 'BestFrac' }
    @{ Old = 'bestslideline'; Class = 'TMapSlide'; Field = 'BestLine' }
    @{ Old = 'slidemo'; Class = 'TMapSlide'; Field = 'Mobj' }
    @{ Old = 'tmxmove'; Class = 'TMapSlide'; Field = 'XMove' }
    @{ Old = 'tmymove'; Class = 'TMapSlide'; Field = 'YMove' }
  )
  Aim   = @(
    @{ Old = 'linetarget'; Class = 'TMapAim'; Field = 'LineTarget' }
    @{ Old = 'attackrange'; Class = 'TMapAim'; Field = 'AttackRange' }
    @{ Old = 'shootthing'; Class = 'TMapAim'; Field = 'ShootThing' }
    @{ Old = 'shootz'; Class = 'TMapAim'; Field = 'ShootZ' }
    @{ Old = 'la_damage'; Class = 'TMapAim'; Field = 'Damage' }
    @{ Old = 'topslope'; Class = 'TMapAim'; Field = 'TopSlope'; Solo = @('p_map.pas') }
    @{ Old = 'bottomslope'; Class = 'TMapAim'; Field = 'BottomSlope'; Solo = @('p_map.pas') }
    @{ Old = 'aimslope'; Class = 'TMapAim'; Field = 'AimSlope'; Solo = @('p_map.pas') }
    @{ Old = 'aim_flags_mask2_ex'; Class = 'TMapAim'; Field = 'AimFlagsMask2Ex'; Solo = @('p_map.pas') }
  )
  Use   = @(
    @{ Old = 'usething'; Class = 'TMapUse'; Field = 'Thing' }
    @{ Old = 'bombsource'; Class = 'TMapBlast'; Field = 'Source' }
    @{ Old = 'bombspot'; Class = 'TMapBlast'; Field = 'Spot' }
    @{ Old = 'bombdamage'; Class = 'TMapBlast'; Field = 'Damage' }
    @{ Old = 'bombradius'; Class = 'TMapBlast'; Field = 'Radius' }
    @{ Old = 'onmobj'; Class = 'TMapCheck'; Field = 'OnMobj'; Solo = @('p_map.pas') }
    @{ Old = 'crushchange'; Class = 'TMapCheck'; Field = 'CrushChange' }
    @{ Old = 'nofit'; Class = 'TMapCheck'; Field = 'NoFit' }
  )
}
