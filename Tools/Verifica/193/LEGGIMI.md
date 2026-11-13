# Verifica #193: parita' dei livelli, delle campagne e dei raccordi di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). Il C originale si compila e si esegue con gcc di
`Reference\_dati\_strumenti\w64devkit` (non c'e' un compilatore C nel PATH) sul `DATA.WAR` vero.

```
powershell -NoProfile -File Registra-Golden.ps1 -Out <cartella nuova fuori dal repository>     # compila e riscrive i golden in Tests\Data\War
powershell -NoProfile -File Make-WarTables.ps1                                                  # rigenera Campaign.Data e Autotile.Data dai golden
war_lvl_ref.exe <DATA.WAR> levels | - campaigns | - objectives | - tables | - autotile | - grid
```

`Compila-LevelRef.ps1` **non modifica** il remake: scrive in `-Out` gli estratti alla lettera (cercando le righe per testo) di
`war_file.c`, `war_resources.h/.c` (da `buildRgbaLut` a `wres_loadTileset`, quindi anche le funzioni dei livelli), `war_enums.h`,
`war_database.h`, `war_units.c` (le tabelle), `war_roads.c`, `war_walls.c`, `war_ruins.c`, `war_trees.c`, `war_map_grid.c` e la copia
INTERA di `war_campaigns.c`, e li compila con `war_lvl_ref.c`: stub di SDL, Tracy, `wm_alloc`, log, liste di `shl`, componenti delle
entita' e conteggi dei giocatori (`wu_*`, un finto guidato dallo scenario). Gli scenari casuali usano un generatore congruenziale
(`x = x * 1103515245 + 12345`, `(x >> 16) & 0x7FFF`), lo stesso nei test: le estrazioni sono istruzioni separate (in C l'ordine di
valutazione degli argomenti non e' definito; la prima versione dava un ordine diverso).

Risultato (2026-11-13, `DATA.WAR` DOS 12852768 byte): 66 livelli (24 della campagna e 42 mappe personalizzate), 36 mappe visive e 36
dei passaggi; `Tests\DelphiDoom.Tests.War` da' le stesse righe di tutti i golden. Trovato nel C: `wcamp_getCampaignData` per un tipo
che non e' in tabella legge fuori dall'array; nelle mappe personalizzate le unita' del primo giocatore si perdono (un array nuovo
per giocatore) e restano le strade dell'ultima posizione (vedi `Libs\War\CLAUDE.md`).
Per compilare i test in un worktree serve `DCC_UnitSearchPath` con la cartella `DUnitX\Source` (vedi `Libs\War\CLAUDE.md`).
