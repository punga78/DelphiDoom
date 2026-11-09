# Tests\Data\Racing

`racing.golden.txt` (111 righe) e l'uscita del **vecchio codice** di Speed Haste (`Reference\Speed\Speed`: le funzioni di `speed_cars`, `speed_race`, `speed_path`, `speed_score` e
`speed_particles`) sugli scenari di `Tests\Source\DelphiDoom.Tests.Racing.Scenarios.pas`. `Libs\Racing` deve dare le stesse righe (`DelphiDoom.Tests.Racing.Parity`).

| Prefisso | Che cosa |
|---|---|
| `sizes` | dimensione di una riga e di tutto il file dei record del vecchio gioco (32 e 230400 byte) |
| `ground` | 600 punti sulla mappa del terreno (tipo e aderenza), una mappa di un'altra dimensione, 800 prodotti di `SH_SlipCalculation` |
| `scores` | 400 aggiornamenti casuali delle tabelle dei tempi con 400 controlli di record; impronta dei 230400 byte |
| `grid` | la scelta delle auto della griglia (3 famiglie x 4 insiemi di giocatori x 7 numeri di posizioni) |
| `track` | l'ordinamento del percorso (24, 40 e 12 punti, quest'ultimo fuori ordine), 200 ricerche casuali del punto successivo piu una su ogni punto |
| `physics` | 72 corse da 450 tic (4 auto, 3 difficolta, giocatore automatico e manuale e computer, con e senza terreno): impronta di ogni campo dell'auto (i `double` a bit), delle particelle, dei suoni e del risultato del giocatore ad ogni tic, ogni 150 tic e alla fine |
| `race` | 6 gare da 8 auto (3 piste, 2 difficolta, fino a 4800 tic), con la classifica ogni 5 tic e i tempi dei giri |

Come e fatto: `Tools\Verifica\168\Racing\Run-Golden.ps1` (serve `Reference\Speed`, che non e nel repository). `Extract-Old.ps1` **taglia** le funzioni dai sorgenti originali e `OldRacing.pas` le include cosi come sono, con un
mondo ridotto ai campi che il codice legge; l'unico cambiamento al testo originale e una riga di zeri in piu nella tabella `GEAR_ACCEL_FACTORS` (il vecchio la legge un elemento oltre la fine a 305 km/h in sesta).
Win32 (il vecchio codice usa `FixedMul` in `asm` e `Extended`). Si rifa solo se cambiano gli scenari.
