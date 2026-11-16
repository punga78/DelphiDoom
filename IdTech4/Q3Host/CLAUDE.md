# IdTech4\Q3Host — note per Claude

Issue #254 (Quake III: dalle librerie a un eseguibile), fase 2a. Descrizione e tabella C -> Pascal: [README.md](README.md); piano e censimento: `docs\QUAKE3_CENSIMENTO.md`. Qui il metodo.

## Unit (una classe per unit, `DelphiDoom.Q3Host.*`)

`Types` (`TQ3Module`, `TQ3OpcodeEntry`, eccezioni `EQ3HostException` -> `EQ3ModuleErrorException`, `EQ3UnknownSyscallException`, `EQ3UnhandledSyscallException`), `Opcodes` e `OpcodeTables` (**generate**), `OpcodeCatalog` (`TQ3OpcodeCatalog`), `Intf` (`TQ3SyscallHandler` = `reference to function`, `IQ3SyscallRegistry`, `IQ3SyscallHost`, `IQ3HostConsole`, `IQ3HostTime`), `Arguments` (`TQ3SyscallArguments`), `SyscallHost` (`TQ3SyscallHost`: implementa `IQvmHost` e `IQ3SyscallRegistry`; `GetRegistry` rende `Self`, un solo oggetto), `CommonSyscalls` (`TQ3CommonSyscalls.Register`), `Factory` (`TQ3HostFactory`, composition root). Usa `IdTech4\Qvm` e `TQ3FloatMask` di `IdTech4\Decl`.

## Come si rifanno i dati (`Tools\Verifica\254`, gcc di `Reference\_dati\_strumenti\w64devkit`, i programmi C sono a 32 bit con float SSE)

```
sh Tools/Verifica/254/opcodes.sh <cartella> > Tests/Data/Q3Host/opcodes.golden.txt
sh Tools/Verifica/254/opcodes-pascal.sh <radice del repository>      # riscrive Opcodes.pas e OpcodeTables.pas dal golden
sh Tools/Verifica/254/init-golden.sh <cartella> > Tests/Data/Q3Host/init.golden.txt
sh Tools/Verifica/254/math.sh <cartella> > Tests/Data/Q3Host/math.golden.txt
```

- **I numeri non si scrivono a mano**: `opcodes.sh` estrae i nomi degli enum con awk e fa stampare i valori a un programma compilato con gli header veri. Trappola trovata: le `TRAP_MEMSET`...`TRAP_CEIL` di `game` non sono in `g_public.h` ma in `sharedTraps_t` di `qcommon.h`; la tabella degli import di `game` e' `gameImport_t` + `sharedTraps_t`. I `.asm` dei moduli (`equ trap_Print -1`: indirizzo = -1 - numero) sono una seconda fonte letta dal test.
- `Exports` e' una parola riservata di Delphi: i metodi del catalogo sono `ImportEntries`/`ExportEntries`.
- `init.golden.txt` non e' `Tests\Data\Qvm\openarena.golden.txt`: il pilota di `Tools\Verifica\120` risponde a `memset` e `memcpy` con la destinazione, `sv_game.c` con 0; `init-golden.sh` ricompila una copia del pilota con quelle due righe cambiate e il resto uguale. Le risposte che il pilota inventa (`G_GET_ENTITY_TOKEN`, `G_GET_CONFIGSTRING`, `CG_GETGAMESTATE`) stanno nel test (`DelphiDoom.Tests.Q3Host.Init`), perche' sono del pilota.
- Un `Com_Error` di un modulo (il `ui` di `mp-pak0` a `UI_INIT` per il file `ui/menus.txt` assente) e' `EQ3ModuleErrorException`: il test lo scrive come "X" e "E", come il pilota.

## Numeri (2026-11-16)

`Tests\DelphiDoom.Tests.Q3Host` (`Tools\build.bat Tests\DelphiDoom.Tests.Q3Host Release [Win64]`): **19 test**, verdi a Win32 e a Win64, 0 avvisi. Catalogo: 427 membri di enum uguali a gcc, 361 `equ` dei tre `.asm` risolti. Matematica: 4289 coppie x 6 funzioni x 3 moduli, bit per bit come il C (NaN contati uguali tra loro); a Win64 `Sin(-0)` della RTL perde il segno (corretto nel gestore). Inizializzazione: 12 `.qvm` di OpenArena, 19480 chiamate di sistema, valori di ritorno, testi, immagine dei dati, conteggio e impronta (FNV-1a 64 di argomenti e risultati) uguali al C.

## Resta da fare

Le trap con servizio (fasi 2b, 2c, 3 e 4 del censimento): ognuna e' un gruppo di gestori registrati nel registro, con il suo servizio come interfaccia piccola iniettata (cvar -> `Framework\Console`, file -> `Framework\Wad`, `G_TRACE` e `G_ENTITIES_IN_BOX` -> `IdTech4\Collision` e il mondo del server, `BOTLIB_*` -> `IdTech4\BotAi` e `IdTech4\Aas`). Una trap senza gestore solleva con il nome: cosi' un modulo che ne chiama una nuova si vede subito.
