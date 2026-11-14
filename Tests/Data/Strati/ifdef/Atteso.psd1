# Esito atteso di Controlla-Strati.ps1 su questo caso.
@{
  Uscita = 1
  Argomenti = @('-Riepilogo')
  Contiene = @('VIOLAZIONE: Libs\Basso\Basso.Uno.pas: usa ''Alto.Due'' (Libs\Alto, strato L1) da Libs\Basso (strato L0) [sotto {$IFDEF GIOCO}]')
  NonContiene = @()
}
