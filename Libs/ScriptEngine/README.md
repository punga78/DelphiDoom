# Libs\ScriptEngine

> Note per Claude e paragrafi di dettaglio: [CLAUDE.md](CLAUDE.md).

Il **collegamento di Pascal Script al motore di id Tech 1** (issue #221): cio' che nomina `mobj_t`, `players[]`, `d_main`, `g_game`, `info`, `deh_*`. Strato: modulo `IdTech1` (`docs\Strati.psd1`). La parte generica (registro delle funzioni, variabili, eventi, serializzatore, catalogo delle classi, compilatore, interprete) sta in `Framework\ScriptHost`, il nucleo del linguaggio in `Framework\PascalScript`.

| Unit | Ruolo |
|---|---|
| `ps_main` | avvio degli script del gioco, comandi `compile`/`pscomp`, accesso al manager |
| `ps_import` | facciata `PS_Configure*`/`PS_HostServices`; le tabelle delle funzioni di `PS_GAME` e `PS_OVERLAY` e le classi di `psi_*` |
| `DelphiDoom.ScriptEngine.Manager` | `TScriptManager`: i sorgenti e i compilati degli script, un interprete per ognuno, `RunScript` con l'attore corrente |
| `psi_game`, `psi_globals`, `psi_map`, `psi_overlay`, `psi_system` | le facciate `PS_*` storiche che il motore chiama (attori, variabili di mappa e di mondo, speciali, overlay, sistema) |
| `dd_compiler` | l'implementazione delle DLL `ddc_<gioco>` (compila, elenca unit, funzioni, costanti, classi, ACTORDEF, CSV delle tabelle) |

Gli adattatori che leggono i globali (`Base\DelphiDoom.Engine.Script.*`) e `ComposeScriptHost` (in `DelphiDoom.Engine.Composition`) restano in `Base`. Nomi delle unit invariati, tranne il manager (`DelphiDoom.ScriptHost.Manager` -> `DelphiDoom.ScriptEngine.Manager`).