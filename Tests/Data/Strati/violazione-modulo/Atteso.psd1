# Esito atteso di Controlla-Strati.ps1 su questo caso.
@{
  Uscita = 1
  Argomenti = @()
  Contiene = @('usa ''Modulo.Tre'' (Libs\Modulo, strato Mod) da Libs\Alto (strato L1)', 'usa ''Altro.Quattro'' (Libs\Altro, strato Altro) da Libs\Modulo (strato Mod)', 'FALLITO: 2 violazioni nuove')
  NonContiene = @()
}
