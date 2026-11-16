@{
  # Routine di disegno passate in metodi statici di classi `sealed` (#247, fetta caldo): nome storico, espressione
  # dell'indirizzo e unit che la contiene. Genera-TabellaFunzioni.ps1 le usa per la tabella e per lo scarico
  # (il golden resta con i nomi storici).
  R_DrawColumnLowest = @{ Expression = 'TRendererColumnDrawers.DrawLowest'; Unit = 'r_column' }
  R_DrawColumnLow = @{ Expression = 'TRendererColumnDrawers.DrawLow'; Unit = 'r_column' }
  R_DrawColumnMedium = @{ Expression = 'TRendererColumnDrawers.DrawMedium'; Unit = 'r_column' }
  R_DrawColumnHi = @{ Expression = 'TRendererColumnDrawers.DrawHi'; Unit = 'r_column' }
  R_DrawColumnUltra = @{ Expression = 'TRendererColumnDrawers.DrawUltra'; Unit = 'r_column' }
}

