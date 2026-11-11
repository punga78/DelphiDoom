# Verifica di Libs\ScriptHost (issue #173)

Rete di sicurezza per la fetta 2 della #172 (piano: `docs\SCRIPTHOST_PIANO.md`, sezione 4). Nessun file di codice di
produzione è toccato da questa cartella: gli aggiornamenti dei giochi e di `ps_main` si fanno con patch temporanee.
Il vecchio è il commit `919a19ef`.

| Livello | Cosa prova | Come |
|---|---|---|
| L1 | la registrazione: dichiarazioni verbatim di ogni unit di script, funzioni registrate (con parametri), tipi, membri di ogni classe, costanti, variabili | `Dump-L1.ps1 -Game <gioco>` (programma console, **non avvia il gioco**); golden in `Tests\Data\ScriptHost\<Gioco>.registration.golden.txt` |
| L2 | ogni funzione `PS_*` registrata chiamata da uno script, nel motore vero, su un livello: risultato e impronta FNV-1a dello stato | `Compila-ScriptHost.ps1 -Variant L2 -Which Old|New`, poi `Confronta.ps1 -Game <gioco>` |
| Salvataggi | i byte dei salvataggi con lo stato degli script (`mapvars`, `worldvars`, variabili globali dello script) | `Compila-ScriptHost.ps1 -Variant Save -Which Old|New`, poi `Confronta-Salvataggi.ps1 -Game <gioco>` |
| Spike | `RegisterDelphiMethod` (strada B del piano) a 32 e 64 bit | `spike\build.cmd` (programma console fuori dal motore) |

## L1: `Dump-L1.ps1`

Dal `ddc_<gioco>.dpr` fa un programma console `VshDump_<Gioco>` (stesse unit e define, `ComposeEngine` +
`DD_InitDoomEngine` come la DLL, poi `ScriptHostDump.pas` scrive il testo), lo compila con `Tools\build.bat`, lo esegue e
confronta con il golden (con `-Update` lo riscrive: solo sul vecchio codice). Il compilatore di Pascal Script libera le
sue tabelle dopo `Compile`, quindi il dump si fa **dentro** `OnUses` (un wrapper chiama `PS_ScriptOnUses` e scrive ciò
che quella chiamata ha aggiunto). Per ogni gioco: `[declarations]` (le stringhe di `ps_import`, per unit),
`[surface all]` (`uses all`) e `[surface PS_FIXED|PS_GAME|PS_OVERLAY]`. Il codice di `ScriptHostDump.pas` compila
nel vecchio (usa `PS_ImportUnits`/`TProcedureList`) e nel nuovo (`PS_ScriptRegistry`, scelto con `IF DECLARED`).

## L2: la batteria

`HarnessScriptHost.pas` (unico file, compilato nel vecchio e nel nuovo albero con gli stessi gancio):

* `VSH_AfterPSInit` alla fine di `PS_Init` (da `ps_main`), `VSH_AfterLevel` alla fine di `TLevelLoader.SetupLevel`:
  `hook-scripthost.patch` (le cinque `.dpr` software e GL di Doom, Heretic, Hexen, Strife; `ps_main`; il loader).
  La patch si rifà con `Genera-Patch.ps1` (lavora sul layout dopo la #170).
* Con `-vsh l2` dopo il primo livello legge dal compilatore l'elenco delle funzioni host (`SYSTEM`: da
  `OutputDebugString` in poi; `PS_FIXED`, `PS_GAME`, `PS_OVERLAY`), per ognuna **genera uno script** con argomenti fissi
  e sicuri (chiavi di mobj veri, indici 0/1, `65536` per i fixed, il nome di una texture e di un flat presi dal livello),
  lo compila con il compilatore del gioco, lo esegue con un `TDoomExec` e scrive risultato (`SetMapString('vsh_result')`)
  e impronta dello stato (settori, linee, lati, mobj, giocatore). Poi `Halt(0)`.
* Salta di default `G_ExitLevel`, `G_SecretExitLevel`, `ConsoleCommand`, `PlaySound`, `ActorPlaySound`,
  `SectorPlaySound`, `SpawnActorName` e tutta la famiglia `Polyobj_*` (con gli argomenti fissi dà `I_Error` se il livello non ha quel polyobj); altre con `-vshskip A,B`; `-vshfrom N`, `-vshonly <testo>`. `Confronta.ps1` ha un ciclo automatico: se un exe muore senza risultato legge il file di avanzamento, aggiunge la funzione alla lista dei salti (la stessa per vecchio, nuovo e ripetizioni: si riparte finché vecchio e nuovo finiscono con la lista invariata), rilancia (massimo 80 aggiunte, `-MaxRepetitions`), e stampa e salva (`skipped.txt`) l'elenco delle funzioni saltate; se muore due volte sulla stessa funzione si ferma. Se il gioco muore
  (un `I_Error` di una funzione chiamata con un argomento sbagliato) `verify_scripthost_L2_progress.txt` dice quale.
* `-vshtypes 0,1,...,19,-1,99999` (fetta 2f-4): una funzione con un parametro `typ` (i `GetMobjInfo*`, `GetEditorNumberFromMobjType`) si chiama una volta per ogni valore, e la riga del risultato porta il suffisso `[typ=N]`; con `Confronta.ps1 -Extra '-vshonly Mobj -vshtypes ...'` si provano le `GetMobjInfo*` per venti tipi, uno non valido e uno fuori dai limiti.
* `-vsh save`: aggiunge ai testi dei livelli E1M1, E1M2, MAP01, MAP02 uno script con variabili globali e gli eventi
  `OnMapStart`/`OnTick`, che scrive `mapvars` e `worldvars` a ogni tic: i salvataggi contengono lo stato degli script.

**Le esecuzioni non sono state fatte da chi ha scritto questi file**: nessun gioco è stato avviato.

## Ordine delle esecuzioni

```
# vecchio (919a19ef) e nuovo (questo albero)
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant L2 -Which Old
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant L2 -Which New
.\Tools\Verifica\scripthost\Confronta.ps1 -Game Doom -Twice
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant Save -Which Old
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant Save -Which New
.\Tools\Verifica\scripthost\Confronta-Salvataggi.ps1 -Game Doom
```

### Dopo le fette 2b e 2c (#174): cosa eseguire

Le variabili degli script (`TScriptVariables`), gli eventi e il serializzatore sono cambiati senza cambiare i byte: L1 è
identico (rifatto, non avvia giochi) e i test DUnitX provano i byte. Resta da provare nel motore:

```
# 1. L2 dei 4 giochi, nuovo contro vecchio (include A_*MapVar*, MapIntegers[...], gli eventi)
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant L2 -Which Old
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant L2 -Which New
.\Tools\Verifica\scripthost\Confronta.ps1 -Game Doom -Twice     # poi Heretic, Hexen, Strife
# 2. salvataggi con mapvars, worldvars e variabili globali dello script: i byte devono essere uguali
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant Save -Which Old
.\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant Save -Which New
.\Tools\Verifica\scripthost\Confronta-Salvataggi.ps1 -Game Doom  # poi Heretic, Hexen, Strife
# 3. a mano: salvare in gioco con almeno una variabile degli script (il difetto di StructureSize, commit 6c1456ab,
#    faceva uscire il gioco in silenzio al caricamento) e ricaricare; Hexen anche da un livello all'altro (worldvars su file)
```

`hook-scripthost.patch` e `hook-save-<gioco>.patch` si applicano ancora (`git apply --check` dà esito positivo dopo la #174);
se non si applicassero, `Genera-Patch.ps1` li rifà.

`-Twice` rifà ogni eseguibile due volte: ciò che cambia tra due esecuzioni dello stesso eseguibile è rumore (per
esempio una funzione che legge il tempo di sistema), non una differenza tra vecchio e nuovo.

## Spike di `RegisterDelphiMethod`

`spike\Spike173.dpr`, `spike\build.cmd` (dcc32 e dcc64, `Libs\Script\Shim` al posto di `d_delphi`). Cinque casi
(risultato `string`, `array of const`, array dinamico, `Extended`/`Double`/`Single`, `Self` letto da un campo): vedi il
rapporto in `docs\SCRIPTHOST_PIANO.md` (sezione 5, fetta 2a-0).

### Dopo la fetta 2f-5 (attori, issue #172): cosa c'e' di nuovo

* **Contesto implicito** (`verify_scripthost_L2_context.txt`, scritto da `-vsh l2` prima della batteria): lo script di evento della mappa
  (`OnPlayerEnter`, `OnActorDied`, `OnUseLine`: `Actor`, `GetActorX(0)`, `SetActorMOMX(0, ...)`) e lo script normale `VSHRUN`
  vengono eseguiti per i **due percorsi** del contesto, con l'impronta dello stato dopo ogni passo: `PS_EventPlayerEnter`,
  `PS_EventActorDied`, `PS_EventUseLine` (gli eventi) e `psmanager.RunScript` (il percorso di `A_RunScript`), la seconda volta con
  un attore diverso e la terza con `nil` (senza attore, `Actor` da il numero non valido). `Confronta.ps1` lo confronta come gli altri file.
  `RunScript` non e' nell'interfaccia di `ps_main`: la patch (`Genera-Patch.ps1`, `Hook-PsMain`) lo da' al harness con `VSH_SetScriptRunner`.
* **Una seconda esecuzione per le funzioni che cambiano il mondo**: `Confronta.ps1 -Game <gioco> -Twice -Extra '-vshskip RemoveActor'`
  (nuovo e vecchio con spawn e spostamenti, ma senza che l'attore tolto falsi le funzioni seguenti), poi `-Extra '-vshonly RemoveActor'`
  (solo la rimozione) e la batteria intera.
* **`-vsh demo`** (hook `VSH_AfterTick` in `PS_EventTick`) e `Confronta-Demo.ps1`: l'ultimo stato del primo giocatore di un
  `-timedemo demo1/2/3` di Doom (gametic, tempo del livello, posizione, angolo, salute, uccisioni), vecchio contro nuovo.
* **Salvataggi**: lo script di `-vsh save` ora fa nascere un attore (`SpawnActorType` del tipo del giocatore, con una velocita'), cosi' i
  byte dei salvataggi contengono un attore creato da uno script; `Confronta-Salvataggi.ps1 -Game Hexen` (poi gli altri tre).
* La patch si rifa' con `Genera-Patch.ps1` **da un albero pulito** (fa `git checkout` dei file che tocca): si e' lanciata nell'albero
  del vecchio commit e le patch copiate qui.
* **`-vshpad N`** (con `-vsh demo`) prende N KB di memoria all'avvio; il gestore di eccezioni di `-vsh demo` scrive in
  `verify_scripthost_demo_exceptions.txt` ogni eccezione (codice, indirizzo, e per un accesso non valido l'indirizzo dei dati
  e la `VirtualQuery`), `verify_scripthost_demo_trace.txt` uno stato ogni 35 tic (ogni tic dal 4255) e
  `verify_scripthost_demo_exit.txt` l'uscita. Servono per il difetto latente di `R_ReadDC32InternalCache` (`docs\PENDING_ISSUES.md`):
  `Confronta-Demo.ps1 -Pad 300` (e `-OldLabel BASE_b7155edf` per confrontare con il commit prima della fetta).
* **Salvataggi di Hexen**: il vecchio da usare e' il commit **prima della fetta** (`Compila-ScriptHost.ps1 -Variant Save -Which Old
  -OldCommit b7155edf -OldTree <worktree>`), non `919a19ef` (che ha ancora il `StructureSize` sbagliato della 2b: 23 e 31 byte in
  meno). I salvataggi contengono indirizzi grezzi (thinker `prev`/`next`, `function`, `state`): i byte di questi campi cambiano anche
  tra due esecuzioni dello stesso eseguibile, e il rumore di due esecuzioni non li copre tutti; la prima esecuzione dopo una
  ricompilazione puo' avere una dimensione diversa dalle altre (si vede dalle dimensioni dei `.hxs`). `Confronta-Salvataggi.ps1`
  ora funziona anche quando il rumore e' vuoto (`Union-Offsets` dava `$null`).

### Dopo la fetta 2h (issue #172)

`psmanager` non esiste piu' (`PS_Manager`, `TScriptManager`): gli `hook-*.patch` si applicano al commit vecchio, i `hook-*.new.patch` al nuovo (`Genera-Patch.ps1 -New`, da un albero pulito); `Compila-ScriptHost.ps1 -Which New` sceglie da solo. `Confronta.ps1` ora confronta anche `verify_scripthost_L2_props.txt` e `..._props_scripts.txt` (batteria delle proprieta' delle classi, fetta 2g).