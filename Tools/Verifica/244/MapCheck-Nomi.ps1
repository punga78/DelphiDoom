# Issue #244: tabella dei nomi storici di p_map e dei campi di TMapCheck che li sostituiscono
# (usata da Migra-MapCheck.ps1 e da Prova-MapCheck.ps1).
$MapCheckGroups = @{
  Tm   = [ordered]@{
    'tmthing'      = 'Thing'
    'tmflags'      = 'Flags'
    'tmx'          = 'X'
    'tmy'          = 'Y'
    'tmbbox'       = 'BBox'
    'tmfloorz'     = 'FloorZ'
    'tmceilingz'   = 'CeilingZ'
    'tmdropoffz'   = 'DropOffZ'
    'tmfloorpic'   = 'FloorPic'
    'tmbounceline' = 'BounceLine'
  }
  Spec = [ordered]@{
    'spechit'      = 'SpecHit'
    'numspechit'   = 'NumSpecHit'
    'maxspechit'   = 'MaxSpecHit'
    'ceilingline'  = 'CeilingLine'
    'floatok'      = 'FloatOk'
  }
}
