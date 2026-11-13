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

## Seconda fetta: la mappa di gioco

```
powershell -NoProfile -File Registra-GoldenMap.ps1 -Out <cartella nuova fuori dal repository>   # compila war_map_ref.c e riscrive map.*.golden.txt
powershell -NoProfile -File Make-WarMapTables.ps1                                               # rigenera DelphiDoom.War.Map.UnitData.pas dal golden delle tabelle
war_map_ref.exe <DATA.WAR> maps | trees | tables
```

`Compila-MapRef.ps1` estrae alla lettera (per testo) `wmap_enterMap` (le funzioni `init*` e `create*`), le funzioni di stato delle tegole, `updateFoW`, `determineFoWTypes`, il ciclo di `renderMinimap`, `we_createUnit`, le `wpath_*` della griglia, le `wu_*` delle unita', le tabelle di `war_units.c` e `war_trees.c`, `war_roads.c`, `war_walls.c`, `war_ruins.c` interi. Gli stub di `war_map_ref.c` sono dichiarati nell'intestazione: SDL, Tracy, log, liste, gestore delle entita', gli stati delle unita' (nessuna e' morta), `we_setInitialIdleState` e `randomi` (la direzione iniziale, a 0). Risultato (2026-11-13): 65 livelli e il 123 che si ferma (`WAR_UNIT_WOUNDED` senza statistiche: un `assert` nel C), 60 scenari di alberi; `Tests\DelphiDoom.Tests.War` da' le stesse righe, a Win32 e a Win64.

## Seconda fetta: la mappa di gioco

```
powershell -NoProfile -File Registra-GoldenMap.ps1 -Out <cartella nuova fuori dal repository>   # compila war_map_ref.c e riscrive map.*.golden.txt
powershell -NoProfile -File Make-WarMapTables.ps1                                               # rigenera DelphiDoom.War.Map.UnitData.pas dal golden delle tabelle
war_map_ref.exe <DATA.WAR> maps | trees | tables
```

`Compila-MapRef.ps1` estrae alla lettera (per testo) `wmap_enterMap` (le funzioni `init*` e `create*`), le funzioni di stato delle tegole, `updateFoW`, `determineFoWTypes`, il ciclo di `renderMinimap`, `we_createUnit`, le `wpath_*` della griglia, le `wu_*` delle unita', le tabelle di `war_units.c` e `war_trees.c`, `war_roads.c`, `war_walls.c`, `war_ruins.c` interi. Gli stub di `war_map_ref.c` sono dichiarati nell'intestazione: SDL, Tracy, log, liste, gestore delle entita', gli stati delle unita' (nessuna e' morta), `we_setInitialIdleState` e `randomi` (la direzione iniziale, a 0). Risultato (2026-11-13): 65 livelli e il 123 che si ferma (`WAR_UNIT_WOUNDED` senza statistiche: un `assert` nel C), 60 scenari di alberi; `Tests\DelphiDoom.Tests.War` da' le stesse righe, a Win32 e a Win64.