# Quake3 — il server dedicato di Quake III / OpenArena

Primo eseguibile di Quake III (issue #254, fase 7, ondata 14): **`Quake3Server.exe`**, un server dedicato a console, senza finestra, senza renderer, senza suono e senza socket. Il motore e' quello delle librerie gia' fatte: `Framework\Wad` (file system sui `.pk3`), `Framework\Console` (cvar e comandi), `IdTech4\Qvm` (la macchina virtuale), `IdTech4\Q3Host` (le chiamate di sistema, il server in memoria `TQ3Server`, il ponte della botlib), `IdTech4\BotAi` e `IdTech4\Aas` (i bot), `IdTech4\NetQ3` (netchan e parser dei messaggi), `Framework\NetTransport` (il filo in memoria) e `Framework\Clock`.

I dati non sono nel repository: la cartella di OpenArena 0.8.8 (quella che ha `baseoa\pak0.pk3`) si dice con `-fs_basepath`.

## Come si lancia

```
Tools\build.bat Quake3Server            # Release Win32; bin\Win32\Release\Tools\Quake3Server.exe (anche Win64)

Quake3Server.exe -fs_basepath <cartella di openarena-0.8.8> +set g_gametype 0 +set sv_maxclients 8 ^
                 +map oa_dm1 +addbot Sarge 3 +addbot Major 3 -frames 300
```

La riga di comando e' quella di Quake III: ogni parola che comincia per `+` apre un comando di console e le parole dopo sono i suoi argomenti.

| Opzione | Significato |
|---|---|
| `+set nome valore` | variabile (g_gametype, sv_maxclients, bot_enable, fs_game ...). Le righe `set` girano **prima** che il server esista (come `Com_StartupVariable`): g_gametype e sv_maxclients sono LATCH e altrimenti resterebbero "in attesa del riavvio" |
| `+map <mappa>` | `SV_Map_f`; una mappa che non c'e' ferma il programma con il codice 3 |
| `+addbot <nome> [skill]` | non e' un comando del programma: e' di `qagame` (`GAME_CONSOLE_COMMAND`), come in Quake III |
| `+map_restart [secondi]`, `+status`, `+quit`, `+echo`, `+set...` | gli altri comandi |
| `-fs_basepath`, `-fs_homepath`, `-fs_game` | scorciatoie di `+set fs_basepath ...` ecc. (basepath: dove sta `baseoa`; homepath: dove si puo' scrivere, default la cartella temporanea; game: la mod sopra `baseoa`, ad esempio `missionpack`) |
| `-frames <n>` | si ferma dopo n frame del ciclo principale (senza: fino a `quit`) |
| `-noclient` | niente client nel processo: girano solo il server e i bot |
| `-help` | l'uso |

**Codice di uscita**: 0 ok (i frame sono finiti o `quit` ha girato), 1 `Com_Error` di un modulo (il gioco o la botlib), 2 chiamata di sistema che l'host non serve, 3 altro (nessuna mappa, cartella assente, errore della macchina virtuale), 4 riga di comando sbagliata. Alla fine, se un server girava, scrive una riga di riepilogo: frame, millisecondi, mappa, giocatori e bot, stato del client e snapshot arrivati.

## Cosa fa

- **Ciclo `Com_Frame`** (`TQ3DedicatedLoop`) col tempo reale: aspetta (dorme, non gira a vuoto) finche' e' passato un frame del server (`1000 / sv_fps`, `SV_FrameMsec` come ioquake3), esegue il buffer dei comandi, passa i millisecondi da `Com_ModifyMsec` (avviso `Hitch warning` oltre 500 ms, taglio a 5000 per un dedicato) e fa girare gli stadi: client, pacchetti del server, `SV_Frame`, pacchetti per il client. Il tempo e' `IQ3Clock` (sopra `IClock` di `Framework\Clock`; in produzione le sorgenti di Windows e un timer da 1 ms, nei test `TManualClock`, il cui `Sleep` fa avanzare l'orologio).
- **Console su stdout** (`TQ3ConsoleOutput`): `Com_Printf` del server, del gioco e della botlib (con i codici colore `^1` tolti, come `Q_CleanStr`) e, come un server dedicato, l'eco dei `print` mandati a tutti (`broadcast: print "Major entered the game\n"`).
- **Comandi del server** (`TQ3ServerCommands`): `map`, `map_restart`, `status`, `quit`. Tutto il resto (`addbot` e gli altri comandi del gioco) e' una riga che nessuno prende e che `TQ3UnhandledCommands` manda a `qagame` come `GAME_CONSOLE_COMMAND`, come `SV_GameCommand`.
- **Un client senza schermo** (`TQ3DummyClient`): sul filo in memoria (`TNetLoopbackPair`, nessun socket) fa `getchallenge`, `connect` con le info utente compresse, prende il gamestate (a frammenti) e gli snapshot dal parser dei messaggi e a ogni frame manda un usercmd che cammina avanti e gira, cosi' c'e' un giocatore e i bot hanno qualcuno da vedere. Senza cgame, renderer, suono, input.
- **Composition root** `TQuake3Factory.CreateDedicatedServer` (l'unico posto che conosce le classi concrete): console con `TQ3ConsoleInfoWriter`, file system su disco con `PakExtension = '.pk3'`, `TQ3SourceHandles` (la tabella dei sorgenti per il precompilatore della botlib), `TQ3Server` con `UnalignedBlockCopy` (OpenArena gira su ioquake3), `TQ3ServerNetwork`, il client, il ciclo. `TQ3DedicatedServer` possiede i pezzi e li libera nell'ordine che funziona.

## Mappa dal C

| C | Pascal |
|---|---|
| `Com_Frame`, `Com_ModifyMsec` (`common.c`) | `TQ3DedicatedLoop.RunFrame`, `ModifyMilliseconds` |
| `Com_ParseCommandLine`, `Com_AddStartupCommands`, `Com_StartupVariable` | `TQ3CommandLine`, `TQuake3Factory` (le righe `set` prima del server) |
| `Com_Printf`, `Q_CleanStr` | `TQ3ConsoleOutput` |
| `SV_Map_f`, `SV_MapRestart_f`, `SV_Status_f`, `Com_Quit_f` | `TQ3ServerCommands` |
| `SV_BotInitCvars` (`sv_bot.c`) | `TQ3BotCvars.Register` |
| `Sys_Milliseconds`, `Sys_Sleep` | `IQ3Clock`, `TQ3ClockAdapter` |
| `CL_Connect_f`, `CL_CheckForResend`, `CL_WritePacket` | `TQ3DummyClient` sopra `TQ3ClientNetwork` |
| `SV_SendServerCommand` (eco del dedicato) | `TQ3Server.SendServerCommand` con `TQ3ServerSettings.EchoBroadcast` |

## Differenze dal C e cose non fatte

- **Il server non ha socket**: la rete e' il filo in memoria con il client del processo; un client vero (anche OpenArena) non puo' collegarsi. Il protocollo e' il 68 (Quake III 1.32), non il 71 di OpenArena 0.8.8.
- **Niente `dedicated 0`, menu, `connect`, `disconnect`, `rcon`, `kick`, `devmap`, `exec` di file `.cfg`** (la console non ha il file system collegato), master server, download, pure server (`sv_pure` resta 0), ping.
- Il Hitch warning e il taglio sono quelli del C per un dedicato, ma il primo frame conta dal momento in cui il ciclo e' creato (il C parte da `lastTime = 0`).
- `Sys_Sleep(1)` a ogni giro che non e' ancora un frame: il C del 1.32 gira a vuoto.
- I campi di `TQ3DedicatedParts` sono pubblici perche' la factory li riempie uno a uno e, se qualcosa fallisce, l'oggetto libera solo quelli fatti.

## Cosa manca per un client

Vedi `docs\QUAKE3_CENSIMENTO.md`, par. 11.
