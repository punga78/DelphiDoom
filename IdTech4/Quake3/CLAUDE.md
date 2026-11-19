# IdTech4\Quake3 — note per Claude

Issue #254, fase 7 (ondata 14): il primo eseguibile di Quake III, il **server dedicato a console** `Quake3Server`. Descrizione, uso, codici di uscita e mappa C -> Pascal: [README.md](README.md); piano: `docs\QUAKE3_CENSIMENTO.md` (par. 11). Qui il metodo.

## Unit (una classe per unit, `DelphiDoom.Quake3.*`)

`Types` (opzioni, codici `Q3_EXIT_*`, `EQ3ProgramException`), `CommandLine` (`TQ3CommandLine`), `Clock.Intf` (`IQ3Clock`), `Clock.Adapter` (sopra `IClock` di `Framework\Clock`), `ConsoleOutput`, `Calendar`, `HostTime`, `BotCvars`, `ServerCommands`, `DummyClient`, `DedicatedLoop`, `DedicatedServer` (`TQ3DedicatedServer` + `TQ3DedicatedParts`), `Factory` (`TQuake3Factory`, il composition root), `Application` (`TQ3Application.Run`: quello che l'eseguibile fa senza il processo intorno). `Quake3Server.dpr` e' solo l'argomento della riga di comando, l'orologio vero (`TClockFactory`, un timer da 1 ms) e lo scrittore su stdout.

## Regole che costano

- **Mai usare test o classi dei test nell'eseguibile**: `TQ3LoopSession`, `TQ3RecordingConsole`, `TQ3FixedCalendar` e simili stanno in `Tests\Source`; l'eseguibile ha le sue (`TQ3ConsoleOutput`, `TQ3SystemCalendar`...). La factory del server e della botlib e' `Q3Host`; qui si assembla soltanto.
- **Un'unit non puo' chiamarsi `...Program`** (parola riservata, E2029): `Application`.
- **Ordine di avvio**: console + `Init`, variabili dei bot, poi le righe `set` della riga di comando (eseguite subito), poi file system (`fs_basepath`, `fs_game`, `fs_homepath`), poi il server (`TQ3Server.Create` fa i `Get` delle sue cvar: quelle LATCH tengono il valore gia' dato), rete e client, comandi, ciclo; le altre righe (`map`, `addbot`...) vanno nel buffer e girano nel primo frame. Chi mette un `set` dopo il server ottiene "will be changed upon restarting".
- **Il client senza schermo** usa gli stessi `IQ3CommandArguments` della console (nel C il tokenizzatore e' uno) e lo stesso `IQ3HuffmanCoder` del server. Il server e il filo vanno liberati prima del client? No: l'ordine e' scritto nel distruttore di `TQ3DedicatedServer` (output del server a nil, client, filo, ciclo, comandi, server, sorgenti, file system, console).
- **`addbot` non si registra**: arriva a `qagame` come `GAME_CONSOLE_COMMAND` da `TQ3UnhandledCommands`. Funziona subito dopo `map` nello stesso buffer perche' `SpawnServer` ha gia' fatto 4 `BOTAI_START_FRAME` (la AAS e' inizializzata).
- **L'eco `broadcast:`** (`TQ3ServerSettings.EchoBroadcast`) e' acceso solo dalla factory: i test di `Q3Host` non lo accendono (210 invariati).
- Il tempo: `IQ3Clock.Sleep` e' la sola attesa. Nei test `TManualClock` (`Framework\Clock`) la fa avanzare: nessun `Sleep` vero, nessun test dipende dalla macchina.

## Come si prova

```
Tools\build.bat Quake3Server Release [Win64]
Tools\build.bat Tests\DelphiDoom.Tests.Quake3 Release [Win64]     # 41 test; i due su OpenArena si ignorano senza i dati
```

Esecuzione vera (console, nessuna finestra; senza compilare nello stesso momento): `Tools\Esegui-gioco.ps1` con `cmd.exe /c "Quake3Server.exe ... > log"` per catturare stdout. DELPHIDOOM_OPENARENA indica la cartella dei dati ai test (altrimenti `Reference\openarena\openarena-0.8.8` risalendo dalla cartella dell'exe).

## Esecuzione registrata (2026-11-19, Win32 Release, oa_dm1, 2 bot + client, `-frames 300`)

Uscita 0; 300 frame in circa 15,5 s di tempo reale (frame da 50 ms come `sv_fps 20`; circa 7 s in piu' per aprire i `.pk3` e caricare); `Quake3Server: 300 frames in 15480 ms, map oa_dm1, 1 players, 2 bots, client Playing (297 commands, 297 snapshots, 1 entities in the last), exit code 0`. Messaggi: botlib (`AAS initialized.`, i caratteri dei bot), `broadcast: print "Major connected\n"`, `... entered the game`, `Dummy entered the game`.

## Resta da fare

Il client vero (finestra, input, cgame con il renderer R2, suono, menu `ui`), la rete su socket (`TWinsockNetTransport` non e' mai stato collegato), `exec` dei `.cfg`, `devmap`, `kick`, rcon: `docs\QUAKE3_CENSIMENTO.md` par. 11.
