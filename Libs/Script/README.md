# Libs\Script — PascalScript in `DDScript.dll`

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Estrazione del compilatore e dell'interprete di Pascal Script (ex `SCRIPT\`, ora `Libs\PascalScript\` e `Libs\ScriptHost\`) in una DLL con interfaccia COM-style, secondo il modello di `Libs\Zlib`, `Libs\Xmi`, `Libs\Mp3`.
Questo documento contiene la **Fase 1** (analisi delle dipendenze) e descrive la **fetta verticale** della Fase 2 consegnata.

## Stato

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | Mappa delle dipendenze, isolamento, stima | completa (questo file) |
| 2 | `DDScript.dll`: compilare, eseguire per nome, funzioni host, globali | completa |
| 3A (#18) | Tipi, costanti e dichiarazioni per unit (`SelectUnit`, `AddType`, `AddConstant`) | fatto, da provare |
| 3B (#19) | `TScriptHostList` (equivalente di `ps_proclist`) fatto; il ponte verso `TPSRuntimeClassImporter` **non si fa** (vedi sotto) | chiusa, non pianificata |
| 3C (#20) | Regola della memoria condivisa: la DLL rifiuta le funzioni host che restituiscono o cambiano stringhe/array/variant (`NeedsSharedMemory`), salvo `SCRIPT_SHARED_MEMORY` | fatto |
| 3D (#21) | Enumerazione delle globali, reali e testo, gestori di riga ed eccezione | fatto |
| 3E (#22) | Tabella di parole chiave dei modelli e preprocessore con define/include dell'host | fatto |
| 3F (#23) | Prove nel gioco | non pianificata |

**Decisione (#10)**: il motore resta su PascalScript in-process (`Libs\ScriptHost\ps_*` e `Libs\PascalScript\ps_*`). Gli script del gioco usano classi Delphi vere (`Actors`, `Lines`, `MapStrings`…) registrate con `TPSRuntimeClassImporter` dal `TClass` e dai puntatori ai metodi, che non attraversano il confine di una DLL: `Libs\ScriptHost\ps_*` e `Libs\PascalScript\ps_*` è il motore degli script, non codice storico da togliere. `DDScript` è la facciata per script semplici (funzioni, costanti, tipi, unit, globali, parole chiave, preprocessore).

Build: `DDScript` (progetto in `Libs\Script`, `bin\Win32\Release\Libs\DDScript.dll`). Test: `Tests\DelphiDoom.Tests.Script` (`bin\Win32\Release\Tests`). Da aggiungere a `Tools\build.bat` (`LIBRERIE` e `TESTS`) a cura di chi integra.

---

## Fase 1 — Mappa delle dipendenze

### Dimensioni

La vecchia `SCRIPT\` aveva circa 72.000 righe, ma il 52% è nel nucleo e il 20% in un solo file di binding.

| Gruppo | Unit | Righe |
|---|---|---|
| **Nucleo** | `ps_defs` 158, `ps_keywords` 166, `ps_utils` 1.794, `ps_compiler` 18.344, `ps_runtime` 16.856 (+ include `PascalScript.inc`, `eDefines.inc`, `x86.inc`/`x64.inc`/`arm.inc`/`powerpc.inc`) | ~37.300 |
| Nucleo opzionale (autonome) | `uPSPreProcessor` 962 (`#include`, `#define`, `$IFDEF` del sorgente), `uPSC_dateutils` 43, `uPSR_dateutils` 91 | ~1.100 |
| Nucleo con uscite minime | `uPSC_dll` 206, `uPSR_dll` 432, `ps_dll` 216 (import di DLL esterne: leggono file dal motore) | ~850 |
| Binding al motore | `ps_import` 1.646 (**TDoomCompiler**, **TDoomExec**, `OnUses`, ~570 dichiarazioni testuali), `ps_main` 1.252 (gestore degli script dei livelli), `ps_events` 406, `ps_serializer` 563 (savegame), `ps_proclist` 271, `uPSDisassembly` 683, `dd_compiler` 1.046 | ~5.900 |
| Funzioni del gioco esposte agli script | `psi_game` 14.207, `psi_overlay` 2.865, `psi_map` 1.979, `psi_globals` 1.962, `psi_system` 887 (~1.600 routine `PS_*`) | ~21.900 |
| Strumenti da riga di comando | `ddc_base` 949, `cmdline_compiler` 238 | ~1.200 |
| Script dei modelli (OpenGL) | `Libs\OpenGl\Legacy\mdl_script`, `mdl_script_functions`, `mdl_script_model`, `mdl_script_proclist` (usano `ps_keywords`, `ps_compiler`, `ps_runtime`, `ps_defs` con la tabella `DDModelScriptLookupTable`) | ~2.400 |

### Il nucleo è autonomo

`ps_defs`, `ps_keywords`, `ps_utils`, `ps_compiler`, `ps_runtime` non nominano il motore (nessun `I_Error`, `devparm`, `doomdef`, `printf`…) e **non hanno define di gioco** (`DOOM`, `HERETIC`, `OPENGL` compaiono solo nella tabella dei modelli di `ps_keywords`, sotto `{$IFDEF OPENGL}`).

Le sole uscite dal nucleo, ricavate confrontando ogni identificatore con le dichiarazioni di `Common\d_delphi.pas`:

| Unit | `uses` che escono | Che cosa serve davvero | Isolamento |
|---|---|---|---|
| `ps_defs` | `{$I Doom32.inc}` | opzioni di codice (`Z1`, `ALIGN 8`, `H+`…) | `Libs\Script\Shim\Doom32.inc` (come `Libs\Mp3\Shim`) |
| `ps_keywords` | `{$I Doom32.inc}` | idem | idem |
| `ps_utils` | `d_delphi` (implementation) | `FreeAndNil` (c'è in `System.SysUtils`) e `CharPos` | `Libs\Script\Shim\d_delphi.pas` |
| `ps_compiler` | `d_delphi` (implementation) | `CharPos` (23 chiamate, sempre con `TbtChar` e `TbtString`) | idem |
| `ps_runtime` | `d_delphi` (implementation) | `CharPos` (4 chiamate) | idem |
| `uPSC_dll` | `d_delphi` | `CharPos` | idem |
| `uPSR_dll` | `d_delphi`, `ps_dll` | `CharPos`; `ps_dll` vedi sotto | shim + `ps_dll` fuori dalla DLL |
| `ps_dll` | `d_delphi`, `w_folders`, `w_pak`, `doomdef`, `i_tmp`, `i_system` | ricerca del file `.dll` nei pak/cartelle del gioco | **non entra nella DLL**: resta nel motore, collegato con l'evento `OnExternalProc` del compilatore |
| `uPSPreProcessor` | nessuna (RTL + nucleo) | — | può entrare così com'è (non in questa fetta) |
| `uPSC_dateutils`, `uPSR_dateutils` | nessuna | — | possono entrare così come sono |

Lo shim `d_delphi` ha **una sola funzione**, `CharPos`, in versione `AnsiChar`/`AnsiString` (l'originale è `Char`/`string`: passerebbe per UnicodeString e, con una code page a più byte, sposterebbe le posizioni). Ha lo stesso nome dell'unit del motore: il progetto che lo usa non deve avere `Common\` nel search path, e le due unit non possono stare nello stesso eseguibile (stessa regola di `Libs\Xmi\Shim`).

`TbtString` è `AnsiString` (`ps_defs`, `DELPHI2009UP`): i byte del bytecode e dei sorgenti non passano mai da UnicodeString nel nucleo.

### Il binding al motore

Che cosa fa ciascuna unit e perché non può stare nella DLL così com'è:

- **`ps_import`**: `TDoomCompiler` e `TDoomExec` (sottoclassi di `TPSPascalCompiler` e `TPSExec`), `PS_ScriptOnUses` che alla unit `SYSTEM` registra tipi (`AddTypeS`), costanti (flag dei mobj, stati, tipi di mobj, costanti di `doomdef`: `AddConstant`), la classe `!TOBJECT`, la libreria date e le procedure di `psi_*` tramite `TProcedureList`. Dipende da `d_main`, `g_game`, `info*`, `p_*`, `r_main`, `m_*`… (una trentina di unit del gioco).
- **`ps_proclist`**: `TProcedureList` = lista di coppie (dichiarazione testuale, indirizzo) con `RegisterProcsComp` (→ `AddDelphiFunction`) e `RegisterProcsExec` (→ `RegisterDelphiFunction(..., cdRegister)`). **È già il modello "funzione host"** implementato dalla DLL: usa `d_delphi` solo per `TString`, `realloc`, `strtrim`.
- **`psi_*`**: i corpi delle funzioni esposte (`PS_*`, convenzione `register`, parametri `TbtString`/interi/`float`/`fixed_t`). Sono la sola parte che *deve* restare nel motore: toccano `mobj_t`, `player_t`, il renderer, il sonoro.
- **`ps_main`**: `TPSExecManager` (un `TDoomExec` per script di livello, compilazione a richiesta, `A_RunScript`, caricamento da pak), dipende da `p_*`, `d_main`, `w_*`.
- **`ps_events`**, **`ps_serializer`**: eventi ed esportazione dello stato per i savegame; il serializzatore scorre le variabili globali dell'interprete e i tipi (`TPSTypeRec`), quindi richiede un'API di enumerazione che la DLL non ha ancora.
- **`uPSDisassembly`**: sottoclasse `TMyPSExec = class(TDoomExec)`; da riscrivere su `TPSExec` se deve entrare nella DLL.
- **`dd_compiler`**: compila gli script di DECORATE/DEHACKED/ACTORDEF; usa `deh_*`, `sc_*`, `info*`: resta nel motore.
- **`mdl_script*`**: lo stesso compilatore/interprete con la tabella di parole chiave `DDModelScriptLookupTable` e una propria `TProcedureList`; richiede che la DLL permetta di scegliere la tabella di parole chiave.

### Come isolare le uscite (riepilogo)

1. Opzioni di compilazione: `Libs\Script\Shim\Doom32.inc` (stesso schema di `Libs\Mp3\Shim\Doom32.inc`).
2. `d_delphi`: `Libs\Script\Shim\d_delphi.pas` (stesso schema di `Libs\Xmi\Shim\d_delphi.pas`, che ha 2 routine; qui 1).
3. `i_system` (`I_Error`/`I_Warning`) non serve: il nucleo non li chiama. Se in futuro entrassero `ps_dll`/`ps_serializer`, servirebbe lo shim `i_system` di `Libs\Mp3\Shim` (che lancia eccezione invece di terminare il programma).
4. Nessun codice del nucleo è stato modificato.

### Stima per portare tutto

Fetta consegnata (Fase 2): nucleo isolato + 5 livelli (Intf, Native, Engine, Loader, Client) + test. Per collegare il motore:

| Passo | Contenuto | Stima |
|---|---|---|
| A | API per tipi (`AddTypeS`), costanti (`AddConstant` intere/reali/stringa), variabili e classe `!TOBJECT` dichiarati dall'host, e `OnUses` per più unit (oggi solo `SYSTEM`) | 1–2 giorni |
| B | `TProcedureList` e `ps_import` che registrano tramite `TScriptCompilerClient`/`TScriptExecutorClient` invece che su `TPSPascalCompiler`/`TPSExec` (le ~570 + le liste di `psi_*` sono già dichiarazioni testuali + indirizzi: lavoro meccanico) | 2–3 giorni |
| C | Gestione di memoria condivisa tra eseguibile e DLL (vedi "Rischi"): ShareMem/FastMM condiviso, oppure rinunciare a stringhe e array dinamici nei contratti delle funzioni | 1–2 giorni |
| D | Enumerazione delle variabili globali per `ps_serializer` (savegame), `TDoomExec.LoadData` (controllo intestazione `DDPS`/versione/gioco), eventi (`OnRunLine`, `OnException`) | 2 giorni |
| E | Scelta della tabella di parole chiave per `mdl_script` (parametro di `CreateCompiler`) e preprocessore (`uPSPreProcessor`) dentro la DLL | 1 giorno |
| F | Prove nel gioco (Doom, Heretic, Hexen, Strife, GL), confronto prestazioni con l'esecuzione in-process | 2 giorni |

Totale indicativo **9–12 giorni**; il rischio maggiore è C (A e D sono contratti nuovi, B è ripetitivo). Il costo a runtime di una chiamata script→host non cambia (la chiamata passa dall'interprete nella DLL direttamente all'indirizzo dell'host, senza strati intermedi).

---

## Fase 2 — `DDScript.dll`

### Struttura (una classe per unit)

| Unit | Classe | Ruolo |
|---|---|---|
| `DelphiDoom.Script.Intf` | `IScriptLibrary`, `IScriptCompiler`, `IScriptExecutor`, `TScriptValue`, `TScriptMessageInfo`, `EScriptException`, codici `SCRIPT_*`, `DDSCRIPT_LIBRARY_NAME`, `DDSCRIPT_CREATE_EXPORT`, `TDDScriptCreate` | contratto condiviso, solo `stdcall`, buffer grezzi e interi |
| `DelphiDoom.Script.Native` | `TScriptNative` | conversioni tra contratto e nucleo (convenzioni di chiamata, nome di una dichiarazione, copia di testo in buffer) |
| `DelphiDoom.Script.Native.Compiler` | `TScriptNativeCompiler` | `TPSPascalCompiler` con parole chiave standard; registra le funzioni host in `OnUses('SYSTEM')`; esporta tutte le variabili globali; copia i messaggi |
| `DelphiDoom.Script.Native.Executor` | `TScriptNativeExecutor` | `TPSExec`; chiamate **senza Variant** (non si usa `RunProcPN`); variabili globali |
| `DelphiDoom.Script.Engine.Compiler` / `.Executor` | `TScriptCompilerEngine`, `TScriptExecutorEngine` | implementano `IScriptCompiler`/`IScriptExecutor`; nessuna eccezione attraversa l'interfaccia |
| `DelphiDoom.Script.Engine` | `TScriptEngine` | `IScriptLibrary`: crea compilatori ed esecutori |
| `DelphiDoom.Script.Loader` | `TScriptLoader` | carica la DLL, chiama `DDScriptCreate`, rilascia l'interfaccia prima di `FreeLibrary` |
| `DelphiDoom.Script.Client` / `.Client.Compiler` / `.Client.Executor` | `TScriptClient`, `TScriptCompilerClient`, `TScriptExecutorClient` (+ `TScriptData`, `TScriptMessage`) | classi che il motore userà: `AnsiString`/`TBytes`, eccezioni `EScriptException` al posto dei codici |

La DLL è `DDScript.dpr`/`.dproj` in questa cartella; esporta `DDScriptCreate(out ALibrary: IScriptLibrary): Integer; stdcall`.

### Funzioni offerte

1. **Compilare** — `IScriptCompiler.Compile(ASource, ASourceSize, ADest, var ADestSize)`: sorgente ANSI (non serve il terminatore), bytecode nel buffer del chiamante. Con buffer nullo o piccolo restituisce `SCRIPT_ERROR_BUFFER` e in `ADestSize` la dimensione richiesta; la seconda chiamata con lo stesso sorgente non ricompila. Messaggi (errori, avvisi, suggerimenti): `GetMessageCount` e `GetMessageInfo(i, info, buffer, size)` con `Kind`, `Position` (offset in byte), `Row`, `Col`, testo ANSI nel buffer del chiamante.
2. **Eseguire** — `IScriptExecutor.LoadBytecode`, `RunMain` (il `begin…end.` del programma, che inizializza le globali), `CallProcedure(name, args, count, var result)` con `TScriptValue` (`SCRIPT_VALUE_INTEGER` Int64, `DOUBLE`, `TEXT` PAnsiChar, `NONE`). Il nome non distingue maiuscole. Risultato di testo: buffer del chiamante in `result.Text`/`result.TextSize`; se non basta si ottiene `SCRIPT_ERROR_BUFFER` **ma la procedura è già stata eseguita**: il testo si legge con `GetResultText` (non va richiamata).
3. **Funzioni host** — la stessa dichiarazione testuale va data al compilatore e all'esecutore: `IScriptCompiler.AddHostFunction('function Nome(a: Integer): Integer;')` e `IScriptExecutor.AddHostFunction(dichiarazione, @Funzione, SCRIPT_CALL_*)`, **prima** di `LoadBytecode`.
4. **Variabili globali** — `GetGlobalInteger`/`SetGlobalInteger(name, Int64)`, qualunque tipo intero (Byte…Int64). Il compilatore esporta tutte le globali del sorgente (`ps_compiler` non le esporta di suo).

### Convenzione di chiamata delle funzioni host

- **Predefinita: `SCRIPT_CALL_REGISTER`**, la `register` di Delphi, che è quella con cui `ps_proclist` registra le funzioni del motore (`cdRegister`). Sono supportate anche `PASCAL`, `CDECL`, `STDCALL`, `SAFECALL`: la scelta è del chiamante, per funzione.
- Il tipo `string` degli script è **`AnsiString`** (`TbtString`). Un parametro `string` arriva alla funzione host come puntatore a un `AnsiString` con contatore di riferimenti: va **solo letto** (dichiararlo `const`).
- Parametri e risultati `Integer`, `Double`, `Boolean`, `PAnsiChar`, puntatori: nessun vincolo.
- **Vincolo di memoria**: una funzione host che *restituisce* una `string`, o che modifica un parametro `var string`, o che ridimensiona un array dinamico dello script, alloca/libera memoria con il *suo* gestore di memoria mentre la DLL usa il proprio. Funziona solo se eseguibile e DLL condividono il gestore (`ShareMem`/FastMM condiviso). Altrimenti usare `PAnsiChar` o numeri. Il test `TestHostFunctionAcrossTheBuiltLibrary` usa solo parametri `string` in lettura, `Integer` e `stdcall`.
- L'eccezione lanciata da una funzione host dentro uno script viene catturata dall'interprete e diventa `SCRIPT_ERROR_RUNTIME` (come nel motore).

### Il confine della DLL

Passano solo interi, `Int64`, `Double`, `Pointer`, `PAnsiChar` e record `packed` (`TScriptValue`, `TScriptMessageInfo`); mai `string`, `TBytes` o oggetti. Le interfacce sono `stdcall`. La DLL non alloca nulla che il chiamante debba liberare. Ogni compilatore/esecutore va rilasciato **prima** di `FreeLibrary` (lo fa `TScriptLoader` per la propria interfaccia radice, non per gli oggetti creati). Ogni istanza va usata da un thread alla volta; non c'è stato globale della DLL oltre al nucleo.

Byte, non caratteri: sorgente, bytecode e testi attraversano il confine con `Move`/`SetString(PAnsiChar)` su `AnsiString`; nessun passaggio da `string`/`Char`. Gli unici `string` sono i messaggi di `EScriptException`.

### Cosa manca (rispetto al motore)

- Tipi, costanti, variabili, classi dichiarati dall'host (passo A) e `uses` di unit diverse da `SYSTEM` (oggi la risposta è "unit non trovata").
- `uPSPreProcessor` (`#include`, `#define`): autonomo, non incluso.
- Scelta della tabella di parole chiave (serve a `mdl_script`).
- Import di DLL esterne (`uPSC_dll`/`uPSR_dll`/`ps_dll`), disassemblatore, serializzatore per i savegame, eventi (`OnRunLine`, `OnException`).
- Passaggio per riferimento dei parametri (`var`) nelle chiamate dall'host; array, record, set e puntatori come argomenti o risultati (`SCRIPT_ERROR_TYPE`).
- Il motore **non** è collegato alla DLL.

### Rischi di compilazione e di esecuzione

Nulla è stato compilato. Punti da guardare per primi:

1. `Doom32.inc`: il progetto mette `Libs\Script\Shim` per primo nell'include path; se Delphi cercasse nella cartella del progetto prima del path, userebbe il `Doom32.inc` vero (innocuo, ma con `APPTYPE GUI`).
2. `ps_compiler`/`ps_runtime` compilano con `Libs\Script\Shim\d_delphi.pas` al posto di quello del motore: se mancasse un simbolo oltre a `CharPos`, l'errore sarà "Undeclared identifier" in quei file (non modificarli: aggiungere la routine allo shim).
3. Conversione implicita `AnsiString`→`string` negli avvisi W1057/W1058 dentro `Libs\PascalScript\` e `Libs\ScriptHost\`: preesistenti.
4. `GetVar` di `TPSExec` restituisce l'indice nella tabella delle variabili esportate, non il numero della variabile: le due cose coincidono solo se **tutte** le globali sono esportate, nell'ordine di dichiarazione. `ScriptExportGlobals` (in `Native.Compiler`) lo garantisce; il test `TestGlobalIntegers` legge due variabili diverse per verificarlo.
5. L'errore a runtime di una divisione per zero dipende dalla mappatura delle eccezioni hardware di Delphi: nel test `TestRuntimeErrorIsReported` il risultato atteso è `SCRIPT_ERROR_RUNTIME`.
6. Dopo un errore a runtime lo stato dell'interprete non viene rimesso a punto: dopo `SCRIPT_ERROR_RUNTIME` conviene ricaricare il bytecode prima di nuove chiamate.
7. I test dei file `*.dll` si saltano se `bin\Win32\Release\Libs\DDScript.dll` non esiste (come per le altre librerie).
