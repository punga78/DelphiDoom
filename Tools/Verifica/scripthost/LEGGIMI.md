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
