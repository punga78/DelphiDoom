# Libs\ScriptHost

Il **collegamento di Pascal Script al motore** (issue #172, spostato qui da `SCRIPT\`): registra nell'interprete le classi, le funzioni e le variabili del gioco, cioè ciò che gli script ACTORDEF/DECORATE possono vedere e chiamare.

| Unit | Ruolo |
|---|---|
| `ps_import` | `TDoomCompiler` e `TDoomExec`: compilatore e interprete con le classi del gioco registrate |
| `ps_main` | avvio, ciclo di compilazione/esecuzione degli script del gioco |
| `ps_events` | eventi del gioco chiamati negli script |
| `ps_serializer` | salvataggio e caricamento dello stato degli script |
| `ps_proclist` | elenco delle funzioni host e delle dichiarazioni |
| `ps_dll` | DLL contenute in un PAK, copiate su file prima di `LoadLibrary` |
| `psi_game`, `psi_overlay`, `psi_map`, `psi_globals`, `psi_system` | le circa 1.600 funzioni `PS_*` che gli script chiamano (giocatori, mobj, overlay, mappa, sistema) |

## Stato e prossimo passo

Per ora le unit hanno **gli stessi nomi di prima** (`psi_*`, `ps_*`) per non rompere i `uses` dei giochi: la fetta 1 della #172 è solo meccanica (nessuna modifica al codice). La **fetta 2** (issue successiva) converte le funzioni procedurali `PS_*` a classi con dipendenze iniettate, con le regole dello schema di `Libs\` (una classe per unit, nomi `DelphiDoom.ScriptHost.*`, composition root `ComposeEngine`); vedi anche `Libs\Script\README.md` per l'analisi di cosa resta nel motore.

Il nucleo dell'interprete sta in `Libs\PascalScript`; il compilatore da riga di comando in `Libs\Ddc`.
