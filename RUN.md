# RUN.md — verifica della issue #148 (`Libs\Threading`)

Codice scritto **senza compilatore**: niente di ciò che segue è stato eseguito. Eseguire dalla radice di questo worktree, un passo alla volta, leggendo i log (`logs\*.log`, righe `error`).

## 0. Prerequisito (solo se si compila da questo worktree)

I `.dproj` dei test cercano DUnitX con `..\..\Skema\...`, che da un worktree non esiste. Prima di `build.bat`:

```
set DCC_UnitSearchPath=D:\Progetti\Skema\SupervisioneNats\lib\DUnitX\Source
```

## 1. Compilazione dei test della libreria (nessun file del motore dentro)

```
build.bat Tests\DelphiDoom.Tests.Threading Debug
```

Atteso: `[DelphiDoom.Tests.Threading.dproj] OK`, nessun `error` in `logs\DelphiDoom.Tests.Threading.dproj.log`. Guardare anche i warning nuovi delle unit `DelphiDoom.Threading.*` (nessuno previsto).

## 2. Esecuzione dei test

```
bin\Tests\DelphiDoom.Tests.Threading.exe --exitbehavior:Continue
```

Atteso: **45 test, 45 passati** (WorkerThread 21, WorkerPool 15, Factory 6, Types 3), exit code 0. Durata prevista pochi secondi (le prove più pesanti: 2 x 2000 creazioni di thread, 1000 chiusure a thread occupato, 20000 + 20000 lavori brevi, 300 pool da 8). Ripeterla **almeno 5 volte** di fila: sono prove di concorrenza e un difetto di corsa può non vedersi al primo giro. Un test che si blocca ha un limite di 20 s (`TEST_TIMEOUT`): se compare un fallimento con "did not start" o un blocco, è il segnale di un difetto vero in `DelphiDoom.Threading.WorkerThread`.

I test sul conteggio dei thread (`AssertNotAbove`) accettano 2 thread in più del prima (thread del sistema): se falliscono con una differenza di 3 o più, c'è un thread rimasto vivo.

## 3. Copertura (Debug, serve CodeCoverage)

```
powershell -NoProfile -File Tools\Copertura.ps1 -Test Threading
```

Atteso: almeno **90%** di righe per `Libs\Threading`. Righe che nessun test raggiunge per costruzione: il ramo `CreateThread` fallito in `TWorkerThread.Create` e `FHandle = 0` di `TWorkerThread.Destroy`. Se è sotto il 90%, dire quali righe mancano e si aggiungono i test.

## 4. Compilazione del motore (i 12 `.dpr` toccati)

```
build.bat Doom32 Release
build.bat all Release
```

Atteso: nessun `error` nei log di `Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32`, `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife` (gli altri progetti non toccano i file cambiati).

## 5. La #147: `demo1` di Doom32 ripetuta

Controllare che il multithread sia acceso: nel log di avvio (`bin\Doom\DATA\LOGS\*_stdout.txt`) deve esserci la riga `MT_Init: Initializing multithreading utilities.` e in `bin\Doom\Doom32.ini` `usemultithread=1` (altrimenti i thread non lavorano e la prova non vale).

```
powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 10 -Demo demo1
```

Atteso: dieci righe `Doom32.exe alive=False exit=<codice> crash=False`, lo stesso `exit` in tutti i giri, nessun `crash.txt` (prima: access violation in `i_system.I_Sleep +0x7` chiamato da `i_threads.ThreadWorker`, 2 volte su 2), `RIEPILOGO: 10 giri, 0 con crash o senza uscita`. Poi:

```
powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 3 -Demo demo2
powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 3 -Demo demo3
```

Atteso: come prima escono con `I_Error: G_CheckDemoStatus(): timed ...`; i gametics sono **identici tra i giri e identici al vecchio eseguibile** (demo3 = 2134 gametics). Se il vecchio eseguibile non è più disponibile: il confronto è tra i giri e con `HEAD~` compilato a parte.

## 6. Prestazioni (massimo +5%)

`-timedemo demo3` (e `demo1` se esce) con il vecchio e con il nuovo eseguibile, almeno 4 coppie, macchina ferma (nessuna altra build): confrontare i `realtics` (tempo minimo e mediano). I punti caldi toccati: attesa dei muri (`R_WaitWallsCache8/32` ora aspetta su evento, prima un ciclo con `I_Sleep(0)`), `MT_Execute*`/`MT_Iterate` (una chiamata a interfaccia per lavoro più `ResetEvent`/`SetEvent`), niente più `SuspendThread`/`ResumeThread` per fotogramma. Se il nuovo è oltre +5%, il candidato è la latenza del risveglio su evento: la correzione prevista è un breve giro di attesa attiva (qualche decina di iterazioni di `YieldProcessor`) in `TWorkerThread.RunLoop` prima di `FWake.WaitFor` e in `Wait` prima di `FIdle.WaitFor`; non farla senza la misura.

## 7. Smoke degli otto eseguibili

Con `Tools\Esegui-gioco.ps1` (lock globale), come nelle altre fette, ad esempio:

```
powershell -NoProfile -File Tools\Esegui-gioco.ps1 -Exe bin\Doom\Doom32.exe -Arguments '-iwad FREEDOOM2.WAD -warp 1 -devparm -nomusic' -Seconds 25
```

per `Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32` (con i loro WAD e `-warp` come nelle altre prove). Atteso: `alive=True crash=False` per tutti; in `*_stderr.txt` nessun `I_Error` e nessuna riga `Threads are not configured` (sarebbe `ComposeThreading` non chiamato).

Una prova in più utile per i muri a più thread: nel `.ini` `usemultithread=1` e `force_numwallrenderingthreads_8bit` / `_32bit` a 2, 4 e 8, e il cambio a gioco in corso (console) fra questi valori: crea e libera `TDThread` mentre il gioco gira.

## 8. Cosa NON è garantito dalla lettura del codice

- Compilazione (vedi i rischi nel rapporto del commit).
- Parità dei fotogrammi: i thread ora nascono con `CreateThread` come prima (stessa FPU di Windows, 53 bit su x87), ma l'ordine di sveglia dei thread è diverso; i lavori dei muri e dei piani si dividono per intervalli fissi e ThreadInc/ThreadSet non sono cambiati, quindi il risultato non dovrebbe dipendere dall'ordine. Va confermato con i gametics identici delle demo e, se si può, con un confronto di screenshot (`-timedemo` + screenshot allo stesso tic) tra vecchio e nuovo.
- Le prestazioni (punto 6).
