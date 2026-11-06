# Libs\Net — come collegarla al motore (issue #70, parte della #45)

La libreria non conosce i globali del motore. Qui sotto: cosa aggiungere, cosa sostituisce cosa,
cosa resta nel motore, cosa si può cancellare.

## 1. Unit da aggiungere ai `.dpr` dei giochi (e a `ddc_*` solo se `d_net` è nei loro `uses`)

Dipendenze già nei progetti: `Libs\Logging` (Types, Intf), `Libs\Clock` (Intf), `Libs\GameState` (Intf).

```
DelphiDoom.Net.Types                in 'Libs\Net\DelphiDoom.Net.Types.pas'
DelphiDoom.Net.Intf                 in 'Libs\Net\DelphiDoom.Net.Intf.pas'
DelphiDoom.Net.PacketCodec          in 'Libs\Net\DelphiDoom.Net.PacketCodec.pas'
DelphiDoom.Net.TicSync              in 'Libs\Net\DelphiDoom.Net.TicSync.pas'
DelphiDoom.Net.ConsistencyTracker   in 'Libs\Net\DelphiDoom.Net.ConsistencyTracker.pas'
DelphiDoom.Net.StartArbiter         in 'Libs\Net\DelphiDoom.Net.StartArbiter.pas'
DelphiDoom.Net.NodeListParser       in 'Libs\Net\DelphiDoom.Net.NodeListParser.pas'
DelphiDoom.Net.WinsockTransport     in 'Libs\Net\DelphiDoom.Net.WinsockTransport.pas'
DelphiDoom.Net.Factory              in 'Libs\Net\DelphiDoom.Net.Factory.pas'
```

Più, per le unit del motore nuove (vedi sotto), le implementazioni delle interfacce:
`DelphiDoom.Engine.Net.LocalInput`, `.Players`, `.Trace`, `.AbortCheck` (nomi suggeriti, in `Base\`).

Riga per `build.bat` (lista `TESTS`, in coda): `Tests\DelphiDoom.Tests.Net`

## 2. Funzione per funzione

### `Base\i_net.pas`

| Vecchio | Dopo |
|---|---|
| `UDPsocket`, `BindToLocalPort`, `PacketSend`, `PacketGet`, `GetLocalAddress` | `TWinsockNetTransport` (`Send`/`Receive`). `GetLocalAddress` non era usata: si cancella |
| `netsend`/`netget`, `I_NetCmd`, `CMD_SEND`/`CMD_GET`, `doomcom.command`/`remotenode`/`datalength` | spariscono: `INetTransport.Send(nodo, byte)` e `Receive(nodo, byte)` |
| `sendaddress[]`, `DOOMPORT` | `TNetNodeAddress` + `NET_DEFAULT_PORT` (5029) |
| `I_InitNetwork`: lettura di `-dup`, `-extratic`, `-port`, `-net`, `-left/-right/-back/-drone` | **resta nel motore** (legge la riga di comando, imposta `R_SetViewAngleOffset`, `netgame`). La lista di host dopo `-net n` si può passare a `TNetNodeListParser.Parse(args, indice, porta)` (stessa sintassi: `nome`, `.1.2.3.4`, `:porta`) e poi `TNetFactory.CreateWinsockTransport(porta, nodi)` |
| `CheckIfDrone` | resta nel motore |
| `I_ShutDownNetwork` | il motore rilascia l'`INetTransport` (il distruttore chiude i socket e chiama `WSACleanup`) |
| `WSAStartup` | dentro il costruttore di `TWinsockNetTransport` |

### `Base\d_net.pas`

| Vecchio | Dopo |
|---|---|
| `NetbufferSize`, `NetbufferChecksum`, `doomdata_t`/`Tcmds` | `TNetPacketCodec` (`Encode`/`Decode`/`ComputeChecksum`/`PacketSize`), `TNetPacket` |
| `HSendPacket`, `HGetPacket`, rimbalzo (`reboundpacket`/`reboundstore`) | `INetPacketPort` (`SendPacket`, `TryReceivePacket`), implementato da `TNetTicSync` |
| `ExpandTics`, `GetPackets`, `nettics`, `nodeingame`, `remoteresend`, `resendto`, `resendcount`, `nodeforplayer`, `localcmds`, `netcmds`, `maketic`, `skiptics`, `gametime` | dentro `TNetTicSync` (stato privato). Accesso: `INetTicSync.NetCommand/SetNetCommand/NetTic/IsNodeInGame/MakeTic` |
| `NetUpdate` | `INetTicSync.NetUpdate`. `procedure NetUpdate;` resta come facciata (la chiama `r_main`, 11 volte): `begin net_sync.NetUpdate; end;` |
| `D_QuitNetGame` | `INetTicSync.QuitNetGame`; il motore tiene la guardia `not usergame or (consoleplayer = -1)` prima di chiamarla |
| `D_ArbitrateNetStart`, `NCMD_SETUP` | `INetStartArbiter.Arbitrate(TNetSetupInfo)`. **Resta nel motore**: riempire `TNetSetupInfo` da `startskill/deathmatch/nomonsters/respawnparm/startmap/startepisode/allowplayerjumps/spawnrandommonsters/allowterrainsplashes/majorbossdeathendsdoom1level` (`TNetSetupInfo.PackMap(episodio, mappa)`; Strife: `MapByte := startmap`; i flag: bit 1 jump, 2 random monsters, 4 terrain splashes, 8 boss Doom1) e rileggerli dal risultato. `SUC_StartingNetwork`/`SUC_FinishedNetwork` restano attorno alla chiamata |
| `D_CheckAbort` | resta nel motore, come `INetAbortCheck.Check` (`I_Error` sul tasto ESC, come oggi) |
| `D_CheckNetGame` | resta nel motore: chiama il suo `I_InitNetwork`, imposta `consoleplayer/displayplayer/playeringame`, crea la libreria (vedi 3) |
| `D_RunMultipleTicks` | **il ciclo resta nel motore** (interpolazione, `G_Ticker`, `D_Display`, `E_Ticker`...). Le decisioni vanno a `INetTicPlanner`: `BeginRun` (realtics), `PlanTics(realtics)` (counts + adattamento di velocità + `skiptics`), `TicsReady(counts)` (la condizione del `repeat..until` e l'errore `lowtic < gametic`), `MustYield` (il `>= 10` con le guardie demo), `VerifyCanRunTic` (l'errore `gametic > lowtic`), `EnterTime` (per `R_StoreInterpolationData`). La modifica dei comandi duplicati (`chatchar`, `commands`, `BT_SPECIAL`) sta nel motore: `cmd := NetCommand(i, buf); ...; SetNetCommand(i, buf, cmd)` |
| `D_RunSingleTick` | resta nel motore con `BuildSingleTic` al posto di `G_BuildTiccmd(@netcmds[...])` e `EndSingleTic` al posto di `inc(maketic)` |
| `frameon`, `frameskip`, `oldnettics`, `oldentertics`, `isinterpolateddisplay`, `firstinterpolation` | i primi quattro dentro `TNetTicSync`; gli ultimi due restano nel motore (display) |
| `maxsend` | calcolato e mai usato: si cancella |

### Altre unit

- `Base\d_net_h.pas`, `Base\d_ticcmd.pas`: `ticcmd_t` e `Tcmds` restano (il motore usa `ticcmd_t`); `doomdata_t`/`netbuffer` si cancellano. La libreria tratta il comando come `CommandSize` byte (`SizeOf(ticcmd_t)` = 14 Doom, 16 Heretic/Hexen, 19 Strife).
- `g_game.pas` (×4): `G_Ticker` legge `memcpy(cmd, @netcmds[i][buf], SizeOf(ticcmd_t))` → `Move(NetCommand(i, buf)[0], cmd^, SizeOf(ticcmd_t))`. Il controllo di coerenza (`consistency[][]`, righe 1695-1706) → `INetConsistency.Verify(i, gametic, cmd.consistency, valore)` con `valore = pl.mo.x` oppure `rndindex`; la condizione `netgame and not netdemo and (gametic mod ticdup = 0)` resta nel motore. `G_BuildTiccmd`: `cmd.consistency := INetConsistency.Expected(consoleplayer, maketic)`. Il `consistency` globale si cancella.
- `ticdup` (usato da `g_game` per `turnheld` ecc.) resta una variabile del motore, impostata da `doomcom`/`-dup` in `D_CheckNetGame`.

## 3. Come il composition root crea la libreria

Le interfacce che il motore deve implementare (tutte piccole, sopra i globali):

| Interfaccia | Cosa fa nel motore |
|---|---|
| `INetLocalInput` | `PollInput` = `I_StartTic; D_ProcessEvents`; `IsGameFinished` = `I_GameFinished`; `BuildTicCmd(tic)` = `G_BuildTiccmd` su un `ticcmd_t` locale, ritornato come `TBytes` di `SizeOf(ticcmd_t)` |
| `INetPlayers` | `IsPlayerInGame(i)` = `playeringame[i]`; `PlayerLeft(i)` = `playeringame[i] := false`, messaggio `Player N left the game` (come `exitmsg` di prima), `if demorecording then G_CheckDemoStatus` |
| `INetTrace` (facoltativa) | `fprintf(debugfile, ...)` se `debugfile <> nil` |
| `INetAbortCheck` | `D_CheckAbort` |
| `IGameContext` (già c'è, `TEngineGameContext`) | `IsNetGame`, `IsDemoPlayback`, `IsDemoRecording`, `IsDeveloperMode`, `GameTic` |
| `IClock` (già c'è) | `engine_clock`; la libreria usa `Steps(TicRate)` (= `I_GetTime`) e `Wait(1)` (= `I_WaitVBL(1)`) |
| `ILog` (già c'è) | avvisi di sviluppo (pacchetto ignorato) |

Ordine in `D_CheckNetGame` (non in `ComposeEngine`: dipende dai parametri e da `ticdup`, che si conoscono solo dopo la riga di comando):

```pascal
codec := TNetFactory.CreateCodec(SizeOf(ticcmd_t));
transport := nil;
if netgame then
  transport := TNetFactory.CreateWinsockTransport(port, TNetNodeListParser.Parse(args, i, port));
settings := TNetSyncSettings.Make(numnodes, MAXPLAYERS, consoleplayer);
settings.TicDup := ticdup;  settings.ExtraTics := extratics;  settings.TicRate := TICRATE;
net_sync := TNetFactory.CreateTicSync(settings, transport, codec, engine_clock, engine_log,
  game_context, local_input, players, trace);        // INetTicSync
net_planner := net_sync as INetTicPlanner;
net_port := net_sync as INetPacketPort;
if netgame then
  info := TNetFactory.CreateStartArbiter(net_port, abort_check, numnodes, consoleplayer).Arbitrate(info);
consistency := TNetFactory.CreateConsistencyTracker(MAXPLAYERS, ticdup);
```

Vanno catturati in un solo punto gli `ENetException` (e derivate: `ENetVersionMismatchException` → `I_Error(S_ERR_DIF_NET)`, `ENetConsistencyException`, il resto) e girati a `I_Error(E.Message)`, perché la libreria non termina il programma. Il motore deve chiamare `net_sync.SingleTics := singletics` quando cambia.

## 4. Cosa si cancella dopo il collegamento

`Base\i_net.pas` (tutto, salvo la lettura degli argomenti che passa nel motore), `Base\d_net_h.pas` (`doomdata_t`, `netbuffer`, `Tcmds`), da `Base\d_net.pas`: `doomcom_t`, `doomcom`, `NetbufferSize/Checksum`, `ExpandTics`, `HSendPacket`, `HGetPacket`, `GetPackets`, `NetUpdate` (diventa facciata), `D_ArbitrateNetStart`, `D_QuitNetGame` (facciata), le variabili `localcmds nettics nodeingame remoteresend resendto resendcount nodeforplayer skiptics maxsend reboundpacket reboundstore gametime frameon frameskip oldnettics oldentertics netcmds`, le costanti `NCMD_*`, `CRESENDCOUNT`, `PL_DRONE`, `DOOMCOM_ID`, `MAXNETNODES`; `consistency[][]` da `g_game`.

## 5. Differenze dal vecchio codice

- **Checksum**: il vecchio sommava le parole `p[1..size div 4]`; quando la dimensione è multipla di 4 (Heretic/Hexen con qualsiasi numero di tic, Doom con tic pari) o `size mod 4 = 2` legge fino a 4 byte *dopo la fine del pacchetto*, cioè i byte che il buffer teneva da un pacchetto più lungo. Il valore dipende da spazzatura diversa sul mittente e sul destinatario. Qui quei byte valgono 0. È **uguale** al vecchio dove il buffer dopo la fine era a zero (verificato sui golden), diverso dove no (il vecchio non era comunque d'accordo con se stesso: la differenza è dimostrata nel test `TestStaleBytesAfterTheEndAreZeroHere`). Un eseguibile vecchio e uno nuovo si capiscono solo se i byte "stale" erano zero sul vecchio.
- Il campo `flags` dei pacchetti di gioco vale 0 (il vecchio mandava quello che era rimasto dai pacchetti di setup; il destinatario lo ignora fuori dal setup).
- Un pacchetto con `player` ≥ `MaxPlayers` viene ignorato (il vecchio indicizzava gli array con quel byte, senza controlli).
- Un datagramma più grande del buffer (`WSAEMSGSIZE`) e un `WSAECONNRESET` (ICMP di porta irraggiungibile dopo che l'altro ha chiuso) sono datagrammi persi; il vecchio li trattava come `I_Error('PacketGet(): Network error.')`.
- Una richiesta di ritrasmissione che farebbe un pacchetto con `numtics < 0` o `> BACKUPTICS` dà `ENetException` (come l'`I_Error` di prima, anche per i negativi che prima diventavano byte grandi).
- `nodeforplayer` in `PlanTics` non si indicizza fuori dall'array se nessun giocatore è in gioco.
- I tic che nessuno ha ancora fatto si leggono come comandi a zero (il vecchio leggeva memoria azzerata o fuori array con `resendto = -1`).
- Il controllo `gametic > lowtic` usa il `LowTic` calcolato al momento, il vecchio quello dell'ultimo giro di attesa (può solo diventare più permissivo, mai meno).

## 6. Difetti conservati

- Il pacchetto verso il nodo 0 (rimbalzo) tiene un solo posto: due invii di fila prima di una lettura perdono il primo.
- L'attribuzione del mittente è solo per indirizzo IP (non per porta): due istanze sulla stessa macchina (`127.0.0.1`) con più di un nodo remoto non si distinguono.
- Il giocatore chiave non riceve una risposta esplicita al setup: considera "risposta" il primo pacchetto di gioco di ogni nodo, e i pacchetti di gioco letti durante l'arbitraggio si perdono.
- `D_ArbitrateNetStart` non dorme: gira a vuoto fino a `D_CheckAbort` (che aspetta 2 tic a giro).
- `resendcount` scende senza limite sotto zero.
- Il formato sul filo dipende da `SizeOf(ticcmd_t)` di ciascun gioco: chi aggiunge campi al `ticcmd_t` cambia il formato (e la compatibilità tra versioni).

## 7. Rischi

- **Compatibilità sul filo**: i byte (offset, dimensioni, checksum) sono verificati contro il vecchio `doomdata_t` compilato per i 4 giochi (`Tests\Data\Net\wire_golden.txt`), ma **mai contro un vecchio eseguibile reale in rete**. Il caveat dei byte "stale" sopra resta.
- **Demo**: `HSendPacket`/`HGetPacket` in riproduzione demo mantengono le stesse guardie (`IsDemoPlayback`) e il rimbalzo, ma `G_Ticker` legge i comandi da `NetCommand`: se un `NetCommand` fuori da `0..MaxPlayers - 1` arrivava prima a memoria arbitraria, ora è `ENetException`. Provare registrazione e riproduzione di una demo in tutti e 4 i giochi.
- **Tempo**: `I_GetTime` è `engine_clock.Steps(TICRATE)`; se un giorno cambia, `TNetTicSync` va con lui solo se resta lo stesso `IClock` (non c'è una seconda sorgente).
- **`NetUpdate` rientrante**: chiamata dal renderer in mezzo al disegno: non tocca nulla del renderer, ma `IsGameFinished` e `PollInput` sono chiamati lì dentro come prima.
- **Multiplayer reale**: non provato (nessuna seconda macchina). Provare prima due istanze su due macchine con `-net 1 <host>` / `-net 2 <host>` e una demo di prova, poi `-extratic` e `-dup 2`.
