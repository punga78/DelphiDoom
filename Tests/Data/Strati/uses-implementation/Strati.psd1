# Prova #219: strati L0 < L1, moduli Mod e Altro (nessun modulo ne ammette un altro).
@{
  Versione = 1
  Strati = @(
    @{ Nome = 'L0'; Tipo = 'Strato'; Livello = 0 }
    @{ Nome = 'L1'; Tipo = 'Strato'; Livello = 1 }
    @{ Nome = 'Mod'; Tipo = 'Modulo'; Ammessi = @() }
    @{ Nome = 'Altro'; Tipo = 'Modulo'; Ammessi = @() }
  )
  Escluse = @('Tests', 'Tools')
  Gruppi = @{  }
  Aree = @{
    'Libs\Basso' = 'L0'
    'Libs\Alto' = 'L1'
    'Libs\Modulo' = 'Mod'
    'Libs\Altro' = 'Altro'

  }
  Eccezioni = @()
}