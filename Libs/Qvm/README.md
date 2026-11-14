# Libs\Qvm

Port a classi della **macchina virtuale QVM di Quake III Arena** (`code\qcommon\vm.c`, `vm_interpreted.c`, `vm_local.h`, `vmHeader_t` di `qfiles.h`; GPL v2 o successiva, id Software), issue #120 (parte di #115, indice id Tech 3). Legge e valida un file `.qvm`, prepara il codice, lo interpreta e passa le chiamate di sistema a un host iniettato (`IQvmHost`), come `Libs\Acs` fa con l'host degli script. Intestazione di ogni unit: "Based on the Quake III Arena GPL Source Code (id Software)". La libreria **non ha chiamanti nel motore**: manca il codice che risponde alle `trap_*` (server, client, renderer: fuori dalla #115).

Un `.qvm` e' **input non fidato**: nessun programma, per quanto malevolo, legge o scrive fuori dalla memoria della macchina o fa eseguire altro che le proprie istruzioni (vedi "Sicurezza").

## Uso

```pascal
// una macchina dai byte di un file
LMachine := TQvmFactory.CreateMachine('qagame', LFileBytes, LHost);          // LHost: IQvmHost
LResult := LMachine.Call(GAME_INIT, [LLevelTime, LRandomSeed, LRestart]);     // VM_Call: comando + al piu' 9 argomenti

// la tabella dei moduli (vmTable): 'vm/<nome>.qvm' e, se richiesto, 'vm/<nome>.map'
LManager := TQvmFactory.CreateManager(LFiles, LLog, TQvmLimits.Default, True); // LFiles: IBotFileSource
LMachine := LManager.Load('cgame', LHost);                                    // nil se il file non c'e'

// l'host: una chiamata a un indirizzo negativo e' la syscall -1 - indirizzo
function THost.SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
begin
  case AArguments[0] of
    G_PRINT: FLog.Info(string(AMachine.Memory.ReadString(AArguments[1])));     // puntatori solo tramite Memory
    TRAP_MEMSET: AMachine.Memory.Fill(AArguments[1], Byte(AArguments[2]), AArguments[3]);
    ...
```

`TQvmLimits` (dato alla factory): `MaxDataSize` (64 MB), `InstructionLimit` (0 = nessuno; contro i cicli infiniti, vale per una chiamata esterna e per tutte quelle annidate), `MaxCallDepth` (64 rientri), `LegacyBitComplement`.

## Mappa C -> Delphi

| C | Delphi |
|---|---|
| `vmHeader_t`, `VM_MAGIC`, `STACK_SIZE`, `MAX_STACK`, `MAX_VM` | `DelphiDoom.Qvm.Types`: `TQvmHeader` (`packed`, 32 byte, `SizeOf` testato), `QVM_MAGIC`, `QVM_MAGIC_VER2`, `QVM_STACK_SIZE`, `QVM_OPERAND_STACK_SIZE`, `QVM_MAX_MACHINES`, `TQvmLimits`, `TQvmInfo`, `TQvmProfile`, `EQvmException` e le tre derivate |
| `opcode_t`, `opnames` | `DelphiDoom.Qvm.Opcodes`: `OP_*`, `TQvmOpcodes` (`OperandSize`, `IsBranch`, `Name`) |
| l'API `VM_*` di `qcommon.h` | `DelphiDoom.Qvm.Intf`: `IQvmHost`, `IQvmMachine`, `IQvmMemory`, `IQvmSymbols`, `IQvmManager` |
| `VM_Create`, prima meta' (intestazione, segmenti, `dataMask`) | `TQvmImage` (`Qvm.Image`) |
| `VM_PrepareInterpreter` | `TQvmCode` (`Qvm.Code`): un intero per byte del codice, come l'originale (cosi' un program counter e' lo stesso numero che l'originale salva nello stack: la memoria resta uguale byte per byte) |
| la memoria di `vm_t` (`dataBase`, `dataMask`), `VM_ArgPtr`, `VM_ExplicitArgPtr`, la copia di `OP_BLOCK_COPY`, la parte dati di `VM_Restart` | `TQvmMemory` (`Qvm.Memory`) |
| `VM_LoadSymbols`, `ParseHex`, `VM_ValueToSymbol`, `VM_ValueToFunctionSymbol`, `VM_SymbolToValue`, `VM_VmProfile_f` | `TQvmSymbols` (`Qvm.Symbols`); i token con `TQ3TokenReader` di `Libs\Models` (il `COM_Parse` gia' portato) |
| i casi float di `VM_CallInterpreted` | `TQvmFloatMath` (`Qvm.FloatMath`) |
| `VM_CallInterpreted` | `TQvmInterpreter` (`Qvm.Interpreter`) |
| `vm_t`, `VM_Call`, `VM_Restart`, `VM_StackTrace` | `TQvmMachine` (`Qvm.Machine`) |
| `vmTable`, `VM_Create` (tabella e file), `VM_Free`, `VM_Clear`, `VM_VmInfo_f` | `TQvmManager` (`Qvm.Manager`) |
| - | `TQvmFactory` (`Qvm.Factory`): l'unico punto che conosce le classi |

I globali `currentVM`, `lastVM`, `vm_debugLevel`, `vmTable` non esistono: l'host riceve la macchina come parametro, chi vuole due tabelle crea due gestori.

## Non portato

- **I JIT** `vm_x86.c`, `vm_ppc.c`, `vm_ppc_new.c` (`VM_Compile`, `VM_CallCompiled`): niente assembler nel codice nuovo. Un modulo e' sempre interpretato.
- **I moduli nativi** (`VMI_NATIVE`, `Sys_LoadDll`, `VM_DllSyscall`, `entryPoint`): caricare una DLL data dal gioco e' proprio cio' che una macchina virtuale evita.
- `VM_Init` (i cvar `vm_cgame`, `vm_game`, `vm_ui` e i comandi `vmprofile`, `vminfo`): le due funzioni sono **dati** (`IQvmManager.Info`, `IQvmSymbols.TakeProfile`), i comandi li registrera' chi colleghera' la console.
- `VM_Debug`, `VM_Indent`, le stampe di `DEBUG_VM` istruzione per istruzione, `VM_LogSyscalls` (scrive `syscalls.log`): la traccia delle syscall la fa l'host. `VM_SymbolForCompiledPointer` e' del JIT.
- Lo scambio dei byte (`LittleLong`): il file e' little endian come la macchina.

## Formato: Quake III 1.32 e ioquake3

Il `vm.c` di id accetta solo `VM_MAGIC` (`$12721444`). **I 12 `.qvm` di OpenArena 0.8.8 hanno tutti `VM_MAGIC_VER2` (`$12721445`)**, il formato di ioquake3: un campo in piu' in fondo all'intestazione (`jtrgLength`) e, dopo i letterali, la tabella dei bersagli dei salti (numeri di istruzione, usata dai JIT di ioquake3 per controllare `OP_JUMP`). `TQvmImage` legge tutti e due: la tabella e' esposta (`IQvmMachine.JumpTargets`) ma non serve all'interprete, che controlla ogni salto quando lo esegue. Le istruzioni sono le stesse.

## Sicurezza

Dove l'originale si fida, la scelta e' stata: **conservare cio' che e' definito e che i programmi veri usano** (le maschere), **eccezione dedicata per cio' che nel C e' comportamento indefinito**. Ogni riga ha un test (`DelphiDoom.Tests.Qvm.Image`, `.Code`, `.Memory`, `.Machine`, `.Fuzz`).

| Punto | Originale | Qui |
|---|---|---|
| Intestazione | controlla numero magico, lunghezze non negative, codice non vuoto; copia dagli offset senza guardare la dimensione del file | in piu': ogni segmento dentro il file, numero di istruzioni tra 1 e i byte del codice, memoria entro `MaxDataSize` e 2^30 (oltre, il ciclo dell'arrotondamento dell'originale non finisce) -> `EQvmFormatException` |
| Codice | un byte che non e' un'istruzione non fa nulla (errore solo con `DEBUG_VM`: "this should be scanned on load!"); il bersaglio di un salto condizionato non si guarda | rifiutati al caricamento: byte sopra `OP_CVFI`, operando tagliato dalla fine del codice, bersaglio che non e' un'istruzione |
| `OP_LOAD1/2/4`, `OP_STORE1/2/4` | indirizzo mascherato (`dataMask`, `& ~3`, `& ~1`): un indirizzo qualsiasi cade dentro | **uguale** (i programmi veri ne dipendono). Un `OP_LOAD4` sugli ultimi 3 byte legge oltre la fine: qui ci sono 128 byte a zero che nulla scrive |
| Stack degli operandi (256 posti, locale) | nessun controllo: scrive sullo stack del C | controllato a ogni push e pop: "VM opStack overflow/underflow". Il posto libero sotto il primo valore ("free spot") c'e' ed e' sempre zero, come tutto lo stack all'inizio di una chiamata (nel C e' quel che capita) |
| Stack del programma | usato senza maschera; controllato solo con `DEBUG_VM` | controllato ogni volta che cambia (`OP_ENTER`, `OP_LEAVE`, frame d'ingresso): sopra `stackBottom`, non negativo, dentro l'immagine con il posto per indirizzo di ritorno e numero di syscall, multiplo di 4 -> "VM stack overflow", "VM program stack misaligned/out of range" |
| `OP_ARG` | `image[offset + programStack]` senza maschera | errore se cade oltre l'ultima parola |
| `OP_CALL`, `OP_JUMP` | `instructionPointers[n]` senza controllo | `n` deve essere un'istruzione |
| `OP_LEAVE` | salta all'indirizzo letto dalla memoria del programma, qualunque sia | deve essere -1 (fine della chiamata) o l'offset dove comincia un'istruzione |
| Fine del codice | prosegue nell'hunk | dopo l'ultima istruzione ci sono sentinelle: "VM pc out of range" |
| `OP_BLOCK_COPY` | due tagli ("MrE: copy range check") che, con un conto negativo o con la sorgente oltre la fine, lasciano passare un conto che esce dall'immagine | stessi tagli (stesso risultato quando l'originale e' definito, anche le copie sovrapposte, dall'ultima parola), poi il conto finale deve stare nell'immagine: "OP_BLOCK_COPY out of range". "not dword aligned" come l'originale |
| `OP_DIVI/DIVU/MODI/MODU` per zero, `INT_MIN / -1` | il processore ferma il programma | `EQvmExecutionException` ("VM division by zero", "VM division overflow") |
| `OP_LSH`, `OP_RSHI`, `OP_RSHU` con conto >= 32 | indefinito in C; x86 usa i 5 bit bassi | i 5 bit bassi, dichiarato |
| Syscall | l'host riceve un puntatore dentro l'immagine e `VM_ArgPtr` maschera l'indirizzo senza sapere quanto e' lungo il buffer | `IQvmMemory`: stessa maschera (e `nil` per 0 in `ArgPtr`), poi **tutto l'intervallo chiesto** deve stare nell'immagine; i 16 interi degli argomenti sono `const` |
| Dopo una syscall | rilegge l'indirizzo di ritorno dalla memoria (l'host potrebbe averlo cambiato) | prosegue dopo la chiamata |
| Rientro (`VM_Call` dall'host) | senza limite: finisce lo stack del C | `MaxCallDepth` |
| Ciclo infinito | nessuna difesa | `InstructionLimit` -> `EQvmInstructionLimitException` |
| Dopo un errore | `Com_Error` lascia `vm_t` a meta' | la macchina torna com'era (stack, profondita') e si puo' chiamare ancora |

**Fuzzing** (`DelphiDoom.Tests.Qvm.Fuzz`, seme fisso, uguale a 32 e a 64 bit): 225 511 tentativi tra file di byte casuali, file troncati a ogni lunghezza, file con byte e intestazioni alterati, programmi di istruzioni casuali e programmi casuali ben formati (27 milioni di istruzioni eseguite). Esiti ammessi: un valore, `EQvmException`, l'errore dell'host. Dopo ogni tentativo: profondita' 0, stack del programma in cima, limite di istruzioni rispettato, byte dopo l'immagine ancora a zero.

## Differenze dal riferimento

**Difetto corretto**: `OP_BCOM` nell'interprete di Quake III 1.32 scrive il complemento **sotto** la cima dello stack e lascia la cima (`opStack[-1] = ~r0`), mentre il compilatore `q3lcc` e i JIT dello stesso gioco si aspettano che sostituisca la cima (ioquake3 l'ha corretto). Qui sostituisce la cima; `TQvmLimits.LegacyBitComplement` rifa' il difetto (serve alla parita' col C; test su tutti e due i modi).

**Float** (`TQvmFloatMath`): i risultati sono quelli del C compilato per le istruzioni SSE (cioe' di ogni programma a 64 bit), uguali a Win32 e a Win64 bit per bit. Il confronto con un NaN e' falso (`!=` vero), `-0 == +0`; `(int)float` tronca e da' `$80000000` per NaN e fuori intervallo (`cvttss2si`; il `Trunc` di Delphi passerebbe da 64 bit); un operando NaN e' il risultato, reso quieto, il primo se lo sono tutti e due (l'unita' x87 dei compilatori del 1999 sceglie quello con la mantissa piu' grande: e' l'unica differenza, 27 righe su 22 719 del golden); `OP_NEGF` cambia il bit del segno. La macchina maschera le eccezioni in virgola mobile per la durata di `Call` (con `TQ3FloatMask` di `Libs\Decl`) e le rimette com'erano: l'host e' chiamato con le eccezioni mascherate, come il motore originale.

**Altre**: `Q_strncpyz` e' una `strncpy` e azzera il resto del buffer: `IQvmMemory.WriteString` fa lo stesso (e chiede che tutto il buffer stia nell'immagine); `VM_Restart` rifiuta un file che chiede un'altra quantita' di memoria (l'originale azzererebbe oltre il blocco); `VM_VmProfile_f` conta solo con `DEBUG_VM`: qui il conteggio per funzione si accende con `IQvmMachine.Profiling`, con la stessa regola (l'`OP_ENTER` di una funzione e' contato su chi la chiama), a parita' di conti l'ordine e' quello del file (il `qsort` dell'originale non lo garantisce) e senza istruzioni le percentuali sono 0 (l'originale divide per zero); `VM_StackTrace` restituisce i nomi e controlla le letture; il nome di un modulo e' tagliato a 63 caratteri come `Q_strncpyz` su `MAX_QPATH`.

## Parita'

Con il **C vero** (`Tools\Verifica\120`: `vm.c` e `vm_interpreted.c` inclusi alla lettera, gcc di w64devkit, x86 a 32 bit, float SSE):

- `Tests\Data\Qvm\parity.golden.txt`: 131 scenari, 22 719 righe. Programmi costruiti dall'assemblatore dei test (`TQvmAssembler`, `TQvmPrograms`): uno o piu' per **ogni istruzione** (interi su 400 coppie di valori limite piu' 60 casuali, salti condizionati, float su 676 coppie di valori speciali piu' 600 casuali, conversioni su ogni esponente), le sei divisioni che fermano il processore, caricamenti e scritture a 1, 2, 4 byte con indirizzi mascherati e alla fine dell'immagine, copie a blocchi (sovrapposte, tagliate, non allineate), ricorsione, tabelle di salto, i nove argomenti, le syscall con le risposte dell'host, il rientro (30 livelli), sieve, ordinamento, serie armonica in float, struttura copiata con letterali e simboli di un `.map`, `VM_Restart`, e 60 programmi casuali di 120 istruzioni. Si confrontano valori di ritorno, righe delle syscall con nove argomenti, impronta della memoria (FNV-1a 64), messaggi d'errore, simboli. **Zero differenze a Win32 e a Win64**, float come bit, nessuna tolleranza.
- `Tests\Data\Qvm\openarena.golden.txt`: `GAME_INIT`, `CG_INIT`, `UI_GETAPIVERSION` + `UI_INIT` dei 12 file di OpenArena con l'host finto: valore di ritorno, numero e impronta delle syscall (da 98 a 15 602 per modulo), impronta della memoria (fino a 8 MB), testi stampati. Undici arrivano in fondo, `missionpack\ui` finisce con `UI_ERROR` ("menu file not found: ui/menus.txt"): uguali al C in tutti e dodici.

## Prestazioni

Il ciclo non ha chiamate virtuali ne' a interfaccia per istruzione: solo una syscall arriva all'host (`IQvmHost.SystemCall`). Sieve fino a 2 000 000 su un'immagine di 4 MB (155 878 069 istruzioni; `TTestQvmPerformance` stampa la misura, senza soglia): su una macchina virtuale rumorosa, in piu' giri, **tra 190 e 240 milioni di istruzioni al secondo a Win32 e tra 160 e 280 a Win64** (il migliore di 5 passaggi per giro); il C originale a `-O2` (`qvmrun_o2 bench`, x86 a 32 bit, senza alcun controllo, media di 5 passaggi) sulla stessa macchina tra 340 e 490. In breve: circa la meta' del C, con tutti i controlli e il contatore delle istruzioni.

## Test

`Tests\DelphiDoom.Tests.Qvm` (`Tools\build.bat Tests\DelphiDoom.Tests.Qvm Release both`): 236 test a Win32 e a Win64, tutti verdi; i 4 di OpenArena si saltano se `Reference\openarena` (o `DELPHIDOOM_OPENARENA`) non c'e'. I file di OpenArena si leggono dai pk3 con `TZipFileSource` di `Libs\Wad`. Come rifare i golden: `Tools\Verifica\120\LEGGIMI.md`. Copertura (`Tools\Copertura.ps1 -Test Qvm`, con `QVM_FUZZ_DIVISOR=100` perche' lo strumento e' lento su ogni eccezione): 96% di `Libs\Qvm` (947 righe su 978); le righe non contate sono i corpi delle funzioni `inline`, espanse nel chiamante.
