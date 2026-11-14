# Libs\DoomScript — note per Claude

`Libs\DoomScript` (issue #110) e' il port a classi del linguaggio di script di Doom 3 / id Tech 4:
`Reference\doom3\neo\game\script\Script_Compiler.cpp`, `Script_Program.cpp`, `Script_Interpreter.cpp`,
`Script_Thread.cpp`, `game\gamesys\Event.cpp` e la parte di `Class.cpp` che riguarda gli eventi. Sorgente GPL v3 con
termini aggiuntivi: **port** (stesso algoritmo, stesso bytecode, stessi messaggi), dichiarato nell'intestazione di ogni
unit; il repository e' GPL v2 o successiva. **Non ha chiamanti nel motore.**

## Portato e non portato

Portati: `idCompiler` (tutto), `idProgram`, `idTypeDef`, `idVarDef`, `idVarDefName`, `function_t`, `statement_t`,
`idScriptObject`, `idInterpreter`, `idThread` (classe e tutti gli eventi di `Script_Thread.cpp` come definizioni),
`idEventDef`, `idEvent` (coda, consegna, salvataggio), di `idClass`/`idTypeInfo` cio' che serve agli eventi (classe,
superclasse, gestori, `RespondsTo`, `ProcessEvent`, `PostEvent`, `CancelEvents`).

Non portati, e perche':

- **Gli eventi di mondo di `idThread`** (`say`, `trigger`, `setcvar`, `getcvar`, `clearPersistantArgs`,
  `setPersistantArg`, `getPersistant*`, `setCamera`, `firstPerson`, `trace`, `tracePoint`, `getTrace*`, `fadeIn`,
  `fadeOut`, `fadeTo`, `music`, `radiusDamage`, `cacheSoundShader`, `setShaderParm`, `debugLine`, `debugArrow`,
  `debugCircle`, `debugBounds`, `drawText`, `influenceActive`, `isClient`, `isMultiplayer`): sono **definiti**
  (`TDoomScriptSysEvents` ha un campo per ognuno) ma senza gestore, perche' parlano con parti del gioco che qui non
  esistono (cvar, console, renderer, collisioni, giocatore). L'host li aggiunge con
  `Machine.Context.ThreadClass.AddEvent(Machine.SysEvents.<Evento>, gestore)`; finche' non lo fa il compilatore rifiuta
  la chiamata (`"x" is not callable as a 'sys' function`). Il driver di parita'
  (`Tests\Source\DelphiDoom.Tests.DoomScript.Parity.Game.pas`) li implementa tutti come li fa `Script_Thread.cpp` ed e'
  il modello da copiare. `getEntity`, `spawn`, `copySpawnArgs`, `onSignal`, `clearSignalThread` sono della libreria ma
  hanno il gestore solo se la macchina ha un `IDoomScriptWorld`.
- Gli argomenti di tipo **trace** (`'t'`) degli eventi: la dimensione c'e' (per `GetArgSize`), il contenuto no (nessun
  evento di script li usa: l'interprete da' l'errore dell'originale).
- Di `idClass`: RTTI, `CreateInstance`, `Spawn`, salvataggio degli oggetti. `idSaveGame`/`idRestoreGame`: solo i
  primitivi che servono (`TDoomScriptSaveStream`) e la codifica degli oggetti (`TDoomScriptMachine.WriteObject`).
- `idPlayer`, `idEntity` e ogni altra classe di gioco: l'host da' i suoi `TDoomScriptEventTarget`.
- La regola di `idClass::PostEventArgs` per cui un client di rete non accoda gli eventi degli oggetti che non sono
  thread: e' una decisione del gioco, l'host non accoda.

## Mappa C++ -> Pascal

Una classe per unit, `DelphiDoom.DoomScript.<Nome>`.

| C++ | Pascal |
|---|---|
| limiti (`MAX_GLOBALS`, `MAX_STRING_LEN`...), `etype_t`, `idCompileError`, conversioni | `Types`: costanti `DS_*`, `TDoomScriptEType`, `EDoomScriptCompileError` / `EDoomScriptError` / `EDoomScriptMemoryError`, `TDoomScriptConvert` (`(int)float`, `SEC2MS`, `%f`, confronti del C con i NaN), `TDoomScriptMemory` (stringhe in buffer da 128 byte) |
| `gameLocal.time/msec/realClientTime/random`, `fileSystem->*Path`, cvar, `DPrintf` | `Intf`: `IDoomScriptHost` |
| `gameLocal.FindEntity/SpawnEntityDef`, `idEntity::spawnArgs/SetSignal/ClearSignalThread` | `Intf`: `IDoomScriptWorld` |
| `idEventDef`, lista statica degli eventi | `EventDef` (`TDoomScriptEventDef`), `EventRegistry` (`Define`, `FindEvent`) |
| `idTypeInfo`, `CLASS_DECLARATION`, `EVENT( ev, fn )` | `ClassInfo` (`TDoomScriptClassInfo.AddEvent`, `TDoomScriptEventHandler` = `reference to procedure(target, event, args)`), `ClassRegistry` |
| `idClass` (cio' che riceve eventi) | `EventTarget` (`TDoomScriptEventTarget`: `RespondsTo`, `ProcessEvent`, `ProcessHostEvent` = `idClass::ProcessEvent` con i controlli di `idEvent::CopyArgs`) |
| `idTypeDef`, `idVarDef`, `idVarDefName`, `function_t`, `statement_t` | `Defs` (quattro classi che si riferiscono a vicenda: l'unica unit con piu' classi) |
| `idCompiler::opcodes` | `Opcodes` (`DoomScriptOpcodes`, `OP_*`) |
| `idProgram` | `ScriptProgram` (`TDoomScriptProgram`) |
| `idCompiler` | `Compiler` (`TDoomScriptCompiler`, sopra `TIdParser`) |
| `idScriptObject` | `ScriptObject` |
| `gameLocal.entities[]`, `spawnIds[]`, `idEntityPtr` | `Entities` (`TDoomScriptEntityTable`: target, nome, script object, spawn id; `EntityPtr`/`ResolveEntityPtr`) |
| `idInterpreter` | `Interpreter` |
| `idEvent` (pool, coda, `ServiceEvents`, `Save`/`Restore`) | `EventQueue` |
| statici di `idThread` (`threadList`, `currentThread`, `threadIndex`) e `gameLocal.program` | `Context` (`TDoomScriptContext`: lo stato di una macchina) |
| `idThread` | `Thread` |
| `idThread::Event_*` | `SysEvents` |
| `idSaveGame`/`idRestoreGame` (primitivi) | `SaveStream` |
| `idGameLocal` per la parte script (creare thread, `ServiceEvents`, `idEntity::ConstructScriptObject`, salvataggio) | `Machine` (facciata) |
| — | `Factory` (composition root) |

Rappresentazione della memoria (diversa dall'originale, stesso comportamento visibile):

- `idVarDef::value` e' un'unione di puntatori; qui `TDoomScriptVarDef.Value` e' un **offset** (nei globali, nella pila
  locale se `Initialized = diStackVariable`, nell'oggetto per un campo) o il numero di un salto / dimensione /
  funzione virtuale; la funzione e' `FunctionPtr`.
- Un **puntatore a un campo** di uno script object (`OP_ADDRESS`, `OP_STOREP_*`) nell'originale e' un indirizzo di
  macchina; qui e' un **handle** `$80000000 or (entita shl 18) or offset`, controllato a ogni uso (entita' ancora
  viva, offset dentro l'oggetto). E' l'unico dato della pila che differisce dai golden (vedi "Parita'").
- Ogni accesso a globali, pila locale, oggetti, tabelle e flussi di salvataggio e' controllato: fuori dai limiti e'
  `EDoomScriptMemoryError`.

## Proprieta' degli oggetti (chi libera cosa)

- `TDoomScriptMachine` (del chiamante di `CreateMachine`: `Free`) possiede contesto, registri di eventi e classi,
  programma, tabella delle entita', coda, compilatore, eventi di sistema; li libera nel distruttore dopo aver
  terminato i thread. Host, mondo, log e file system sono **interfacce** (contate): la macchina ne tiene un
  riferimento.
- **Thread**: un `TDoomScriptThread` si registra nel contesto quando nasce. Un thread normale si libera da solo (evento
  `<immediateremove>` accodato quando la funzione finisce: sparisce alla `ServiceEvents` successiva, anche nella stessa
  in cui e' finito). Dopo `ManualDelete` lo libera chi l'ha creato. `Restart` (del programma o della macchina) li
  libera tutti. Non tenere un riferimento a un thread oltre una `ServiceEvents` senza `ManualDelete`.
- **Entita'**: il `TDoomScriptEventTarget` e' dell'host (lo crea, lo registra con `Entities.Add`, lo toglie con
  `Entities.Remove` e lo libera dopo aver chiamato `Queue.CancelEvents(target)`, come `idClass::~idClass`). Lo script
  object dell'entita' e' della tabella (nasce con `Add`, muore con `Remove`).
- **Programma**: tipi, def, funzioni e statement sono suoi. Le funzioni e i tipi tolti da un `Restart` restano vivi
  (svuotati) fino a `FreeData`: un tipo oggetto piu' vecchio puo' ancora elencare la funzione e il def del ritorno puo'
  ancora avere il tipo (nell'originale: puntatori pendenti).
- **Eventi in coda**: della coda; un evento estratto per la consegna e' liberato dopo il gestore anche se questo fallisce.

## Differenze dal riferimento

- Nessun globale: `gameLocal.program`, la lista dei thread, la coda degli eventi e la lista degli `idEventDef` sono di
  una macchina (`TDoomScriptContext`).
- I gestori degli eventi sono metodi anonimi registrati su una classe, non puntatori a membro con dispatch per
  numero di argomenti; gli argomenti arrivano come `TDoomScriptEventArgs` (un'entita' e' il suo numero, -1 = nessuna).
- `idThread::ReturnInt` scrive un float (come l'originale: gli interi veri non esistono nel linguaggio): l'host usa
  `ScriptProgram.ReturnFloat`.
- `CompileStats` stampa le stesse righe; i byte sono le dimensioni di questo port (l'harness li normalizza a `?`).
  "Files loaded" va a `IDoomScriptHost.DebugPrintf` (il `DPrintf`).
- `Compiled '<file>': 0.0 ms`: la libreria non ha un orologio, il tempo e' sempre 0.0 (normalizzato dall'harness).
- `%f` di un float enorme (da 9e12 in su): le cifre esatte arrotondate a 20 cifre significative e poi zeri, come il
  runtime C dell'harness (bcc32c); il runtime del gioco (MSVC) si fermava a 17. Verificato dai golden solo su 1e30.
- `TDoomScriptMachine.Restore` fa `Restart` del programma prima di leggere (il salvataggio contiene le differenze dallo
  stato appena caricato), come fa il gioco.
- `ConstructScriptObject`/`DeconstructScriptObject` della macchina seguono il vero `idEntity` (thread in controllo
  manuale, eseguito subito); l'harness usa una variante semplificata, che il driver di parita' riproduce a mano.

## Difetti dell'originale

**Conservati** (sono nei golden; ognuno ha un test o uno scenario):

- `=` lega piu' di `&&` e `||`; `return` con conversione usa l'opcode con gli operandi scambiati; `int( a / b )` non
  compila; un blocco vuoto `{ }` e' un errore; `+=` su un campo non compila e `self.count++` incrementa un
  temporaneo; `campo_entity = self` non compila; la riga di un errore e' spesso quella del token precedente; `#elif`
  dopo un `#if` preso viene preso; un namespace non chiuso e' accettato; `a %= 0` scrive 0.
- `statement_t::linenumber` e' a 16 bit: la riga 65537 diventa 1.
- Un argomento `'e'` nullo termina il thread con un warning. `ProcessEvent`/`PostEvent` dall'host con un argomento di
  formato `'E'` fallisce sempre ("Wrong type passed in for arg").
- `killthread` di un thread in pausa lo lascia nella lista (morente) per sempre; `StackTrace` stampa una voce oltre
  quelle in uso; dopo una compilazione fallita le funzioni gia' compilate restano eseguibili.
- **Thread corrente dopo un errore**: `idThread::Execute` non rimette il thread precedente se lo script finisce con un
  errore (`TDoomScriptThread.Execute` non ha `try/finally` apposta).
- **Pool degli eventi**: l'evento in consegna non e' nel pool, e se il gestore fallisce non ci torna piu': dopo N
  errori il limite di 4096 eventi scende di N fino a `Queue.Clear` (`TDoomScriptEventQueue.FOutOfPool`).
- **`idEvent::Save` non scrive gli argomenti stringa** (dopo il restore l'originale consegna memoria non
  inizializzata; qui la stringa e' vuota).
- **`Compiled '<nome>'`**: il compilatore riceve il buffer della stringa `filename` del programma, che cambia mentre
  compila. Si stampa cio' che quel puntatore legge alla fine (`TDoomScriptProgram.FileNameInBuffer`, modello del
  buffer di `idStr`: 20 byte interni, poi blocchi da 32): di norma il file giusto, ma per un testo senza token dopo
  l'include di default esce `script/doom_defs.script` se il nome e' lungo da 20 a 31 caratteri.
- `sys.strMid( s, a, 2147483647 )`: il float vale 2^31, `(int)` da' un negativo, risultato vuoto.

**Trasformati in eccezione** (crash o comportamento indefinito nell'originale; ognuno ha un test che lo nomina):

- `a % b` con `|b| < 1` (zero come intero, non come float), a runtime e nella piegatura delle costanti; `a % 0`
  costante: "Divide by zero" (`a % -1` da' 0).
- `entita.f()` con `f` funzione globale: `Function 'f' not found in scope 'namespace'` (l'originale chiede il nome di
  `def_namespace`).
- Eseguire una funzione la cui compilazione e' fallita a meta': esegue gli statement emessi e poi
  `EDoomScriptMemoryError` (puntatore di istruzione fuori dal programma).
- Stato ripristinato non valido (`callStackDepth`, `localstackUsed`, `localstackBase`, base dei frame, indice di
  funzione, `popParms`, entita' attesa), ritorno a un frame senza funzione, puntatore di istruzione fuori dal
  programma, locali oltre la pila, puntatore a campo falso / di un oggetto rimosso / oltre l'oggetto, statement senza
  operando, opcode non valido, indici di variabili del salvataggio fuori intervallo, riferimento a un thread che non
  c'e', evento salvato senza oggetto: `EDoomScriptMemoryError` o `EDoomScriptError`.
- Una funzione con parametri avviata dall'host senza argomenti in pila (base dei locali negativa): errore controllato.
- `GetRegisterValue` su un campo di oggetto (l'originale prende il numero dell'entita' per un puntatore): `False`.
- Il thread corrente che punta a un thread rimosso: dimenticato (`nil`).
- `sys.drawText` senza giocatore e `sys.copySpawnArgs` di un'entita' nulla sono dell'host: il driver di parita' non
  crasha.

Messaggi dell'originale che il testo di uno script non puo' raggiungere tramite l'API pubblica (restano nel codice,
senza test): "Unknown token", "Invalid return type for function", "Function ... has not been defined yet", "No 'self'
within scope", "weird immediate type", "weird type on".

## Parita' (issue #110)

- **Harness C++**: `Tools\Verifica\110` (`main.cpp`, `Game_local.h`, `precompiled.h`, `Build-Harness.ps1`): i veri
  sorgenti di Doom 3 con un gioco finto, compilati con bcc32c (x87, `NDEBUG`). La testata di `main.cpp` descrive i
  comandi degli scenari e il formato dei golden. Per rigenerare i golden (solo se cambia uno scenario o uno script):
  `powershell -File Tools\Verifica\110\Build-Harness.ps1` (`-Only <scenario>`, `-NoBuild`); servono `Reference\doom3`
  e RAD Studio.
- **Dati**: `Tests\Data\DoomScript\scenarios\*.scn` (16), `scripts\script\*.script`, `golden\*.golden.txt` (16660
  righe).
- **Driver Pascal** (`Tests\Source\DelphiDoom.Tests.DoomScript.Parity.*`): `Output` (righe, `PRINT`/`DPRINT`/`WARN`,
  normalizzazione), `FileSystem` (radice, prefisso `/base/`, `genfile`), `Entity` e `Game` (gioco finto: entita',
  eventi, stub `HOST`), `Dump` (programma, thread, eventi, entita', save/restore), `Scenario` (comandi), e la fixture
  `TTestDoomScriptParity` (un test per scenario, confronto riga per riga con numero e testo della prima riga
  diversa). Con la variabile d'ambiente `DOOMSCRIPT_PARITY_OUT` le righe del driver vanno in quella cartella
  (`Tools\Verifica\110\Prova-Pascal.ps1` lo fa).
- **Risultato**: 16 scenari su 16 uguali a Win32 e a Win64.
- **Normalizzazioni** (le sole dell'harness): il tempo di `Compiled '..': ? ms` e i byte delle righe di memoria di
  `CompileStats`.
- **Differenze dichiarate** nella fixture:
  1. righe `STACK` e `SAVE stack`: una parola della pila puo' differire solo se nel port e' un handle di puntatore a
     campo (`$80000000..$BFFFFFFF`) e nell'originale non e' zero;
  2. scenario `sysmath`: `sys.sin( 1234.5 )` e `sys.cos( -777.25 )` (`3EDC6C11`/`3F0A7D50` nel golden,
     `3EDC6C01`/`3F0A7D4B` nel port, e i sei decimali `0.540975`/`0.540974`): il `sinf`/`cosf` del runtime dell'harness
     riduce in precisione singola un angolo grande ed e' a 16 e 5 ulp dal valore esatto; il port usa il seno
     dell'x87 come il gioco. Nessun'altra tolleranza, nemmeno a 64 bit.

## Test e copertura

`Tests\DelphiDoom.Tests.DoomScript`: 324 test (Win32 e Win64). Oltre alla parita': una fixture per classe
(`Convert`, `Memory`, `EventDef`, `EventRegistry`, `ClassInfo`, `ClassRegistry`, `EventTarget`, `SaveStream`,
`TypeDef`, `VarDef`, `Opcodes`, `EventQueue`, `Entities`, `ScriptObject`, `Compiler`, `ScriptProgram`, `Interpreter`,
`Thread`, `SysEvents`, `Machine`/`MachineState`, `Factory`), con `TDoomScriptTestRig` (macchina su finti) e
`TDoomScriptFakeHost`. I test di sicurezza: stato ripristinato ostile campo per campo, ogni operando di ogni
statement tolto a turno (`DovrebbeSopravvivereAOgniOperandoMancante`), ogni salvataggio tronco, e ogni posizione di
un salvataggio vero sostituita da sette valori limite seguita da tre fotogrammi di gioco
(`DovrebbeSopravvivereAUnSalvataggioGuastoInOgniPunto`): solo eccezioni della macchina.

Copertura (righe, `Tools\Copertura.ps1 -Test DoomScript`): 96% in totale.

| Unit | % | Unit | % |
|---|---|---|---|
| ClassInfo | 100 | Interpreter | 97 |
| ClassRegistry | 100 | Machine | 100 |
| Compiler | 97 | SaveStream | 100 |
| Context | 100 | ScriptObject | 97 |
| Defs | 98 | ScriptProgram | 97 |
| Entities | 88 | SysEvents | 99 |
| EventDef | 100 | Thread | 99 |
| EventQueue | 100 | Types | 89 |
| EventRegistry | 97 | Factory | 72 |
| EventTarget | 100 | | |

`Entities` e `Types` sotto il 90%: le righe mancanti sono funzioni `inline` (il rapporto le conta nel punto di
dichiarazione, mai eseguito). `Factory`: il ramo che smonta una macchina costruita a meta', che nessun test puo'
provocare.

## Riuso

Da `Libs\IdLib`: `TIdLexer`, `TIdToken` (vettori tra apici, token), `TIdStrings` (`%f`, `%.2f`, ricerca), `TIdVec3`,
`TIdMath`, `TIdMd4` (checksum del programma), `IIdLibLog`, `IIdLibFileSystem`, `EIdLibException`. Da `Libs\Scanner`:
`TIdParser` (preprocessore e `#include`), `TIdDict` (argomenti di spawn), `TIdCNumbers` (`atoi`/`atof`). Da
`Libs\MathCore`: `TIdAngles`. Nessuna di queste librerie e' stata modificata.

Nuovo, perche' non esisteva: tutto cio' che e' specifico dello script (tipi, def, opcode, compilatore, interprete,
thread), il sistema degli eventi (`idEvent`/`idEventDef`/`idTypeInfo` non erano portati), la tabella delle entita' e
il flusso di salvataggio con i primitivi di `SaveGame.cpp`.

## Da collegare

Un host vero deve: implementare `IDoomScriptHost`/`IDoomScriptWorld`; dichiarare le sue classi sotto `idClass` e i
loro eventi; dare i gestori degli eventi di mondo; chiamare `ServiceEvents` a ogni fotogramma; registrare e togliere
le entita'; nel salvataggio, scrivere `Entities.SpawnCount` e gli script object delle entita' (`TDoomScriptObject.Save`)
accanto a `Machine.Save`. Prestazioni non misurate (nessun chiamante): il ciclo di `RunStatements` non fa chiamate
virtuali ne' a interfaccia per istruzione.
