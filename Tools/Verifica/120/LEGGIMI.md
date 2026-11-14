# Tools\Verifica\120 - parita' della macchina virtuale QVM (issue #120)

Strumenti che producono le risposte di riferimento di `Libs\Qvm` con il **codice di Quake III Arena** (`Reference\quake3\code\qcommon\vm.c`, `vm_interpreted.c`, `vm_local.h`, sola lettura). Non c'e' un compilatore C nel PATH: si usa il gcc di `Reference\_dati\_strumenti\w64devkit`, che produce programmi **x86 a 32 bit** (`i686-w64-mingw32`).

- `build.sh [cartella]` (sh, da Git Bash): costruisce `vm_original.inc` con **i tre file interi** (tolte solo le righe `#include`) piu' le funzioni di `game\q_shared.c` che usano (`COM_StripExtension`, `COM_Parse`, `SkipWhitespace`, `COM_ParseExt`, `Q_strncpyz`, `Q_stricmpn`, `Q_stricmp`, `Com_sprintf`, estratte per nome con awk, mai riscritte) e compila quattro programmi dallo stesso `qvmrun.c`:
  - `qvmrun.exe`: `-O1`, float con le istruzioni SSE (`-msse2 -mfpmath=sse`), `VM_MAGIC` `0x12721444`. E' quello dei golden.
  - `qvmrun_v2.exe`: lo stesso con `-DVM_MAGIC=0x12721445` (il `VM_MAGIC_VER2` di ioquake3): legge i file di OpenArena, che il `vm.c` di id rifiuta ("bad header"). Il resto dell'intestazione e' uguale e `vm.c` usa solo gli offset, quindi basta il numero magico.
  - `qvmrun_o2.exe`: `-O2`, per misurare la velocita'.
  - `qvmrun_x87.exe`: float con l'unita' x87 (i compilatori del 1999), per vedere dove differiscono i due modi: solo in quale NaN esce da un'operazione su NaN (27 righe su 22719 del golden).
- `stubs.h`: i tipi di `q_shared.h`/`qcommon.h`/`qfiles.h` che servono, l'hunk (zero, con 256 byte in piu' dopo ogni blocco: quello che l'originale legge oltre la fine dell'immagine, un `OP_LOAD4` sugli ultimi byte o gli argomenti di una syscall fatta in cima allo stack, sono zeri e non cio' che segue), il file system (due file in memoria: immagine e simboli), `Com_Error` (un `longjmp` al pilota), i cvar.
- `qvmrun.c`: il pilota. `qvmrun run <scenari>` esegue un file di scenari (formato nell'intestazione del sorgente) e stampa: `R valore` per ogni chiamata, `E testo` (un `Com_Error`) o `T codice` (un'eccezione del processore: `C0000094` divisione per zero, `C0000095` `INT_MIN / -1`, presa con un gestore vettoriale), le righe `S numero nove-argomenti` e `= valore` di ogni syscall (se `trace on`), `P`/`X` i testi delle syscall di stampa e di errore, `M impronta-della-memoria numero-di-syscall impronta-delle-syscall` (FNV-1a a 64 bit), `I` le informazioni di `VM_VmInfo_f`, `Y`/`V` i simboli. `qvmrun bench <file> <profilo> <comando> <argomento> <ripetizioni>` misura il tempo. Con `QVM_MEMDUMP=<cartella>` ogni riga `M` scrive anche l'immagine dei dati (`c_<n>.bin`; il test fa lo stesso con `p_<n>.bin`: un `cmp -l` dice quali byte differiscono).
- **`VM_Call` non si usa**: legge i suoi argomenti variabili come un array a partire dall'indirizzo del primo, cosa che vale solo con la convenzione `cdecl` dell'x86 a 32 bit; il pilota, per non dipendere da come e' compilato, fa le stesse sei righe (`currentVM`, `lastVM`) e chiama `VM_CallInterpreted` con un array vero. Tutto il resto (`VM_Create`, `VM_Restart`, `VM_ArgPtr`, `VM_LoadSymbols`, `VM_ValueToSymbol`, `VM_SymbolToValue`, `VM_PrepareInterpreter`, `VM_CallInterpreted`) e' l'originale. `VM_Compile`/`VM_CallCompiled` (il JIT) sono due stub: il modulo e' sempre interpretato.
- **L'host finto** (`host_dispatch`, rifatto riga per riga in `Tests\Source\DelphiDoom.Tests.Qvm.Support.pas`): stampa (`P`), errore (`X`, poi `Com_Error`), `memset`/`memcpy`/`strncpy` (100..102) con i limiti controllati (`host: out of range`), `sin`/`atan2` = 0, `cos` = 1, `sqrt`, `floor`, `ceil`; profilo `test`: 200 rientra nella macchina, 201 legge una parola con `VM_ArgPtr`, 202 la scrive, 203 restituisce il primo argomento; profilo `game`: 37 (`G_GET_ENTITY_TOKEN`) da' `{ "classname" "worldspawn" }`, 19 (`G_GET_CONFIGSTRING`) una stringa vuota; profilo `cgame`: 50 (`CG_GETGAMESTATE`) un gamestate con il solo `CS_GAME_VERSION` = `baseoa-1`; ogni altra syscall risponde 0.
- `golden.sh <cartella di build.sh> <cartella degli scenari> [programma]`: esegue `scenarios.txt` della cartella scritta dal test.
- `openarena.sh <cartella di build.sh>`: estrae i 12 `.qvm` di OpenArena dai pk3 (in `<cartella>\oa`, fuori dal repository), scrive gli scenari di inizializzazione (`GAME_INIT`, `CG_INIT`, `UI_GETAPIVERSION` + `UI_INIT`) e li esegue con `qvmrun_v2.exe`.

Per rifare i dati di `Tests\Data\Qvm`:

```
sh Tools/Verifica/120/build.sh <cartella nuova>
set QVM_DUMP=<cartella degli scenari>
bin\Win32\Release\Tests\DelphiDoom.Tests.Qvm.exe            (scrive scenarios.txt, un .qvm per scenario, bench.qvm)
sh Tools/Verifica/120/golden.sh <cartella nuova> <cartella degli scenari> > Tests/Data/Qvm/parity.golden.txt
sh Tools/Verifica/120/openarena.sh <cartella nuova> > Tests/Data/Qvm/openarena.golden.txt
<cartella nuova>/qvmrun_o2.exe bench <cartella degli scenari>/bench.qvm test 0 2000000 5
```

`DELPHIDOOM_ROOT` (radice del repository principale, dove sta `Reference\`) cambia il percorso di default `/c/Progetti/DelphiDoom`. I `.sh` devono restare con le fine riga LF.

## Cosa del C non entra nei golden

Cio' che nel C e' comportamento indefinito non ha una risposta di riferimento, e nella libreria e' un'eccezione (`EQvmExecutionException`) coperta da test propri (`DelphiDoom.Tests.Qvm.Machine`, `.Fuzz`): stack degli operandi oltre i 256 posti o sotto zero, stack del programma fuori dall'immagine, `OP_ARG` oltre la fine, salto, chiamata o ritorno a un indirizzo che non e' un'istruzione, fine del codice superata, `OP_BLOCK_COPY` il cui conto (negativo, o con la sorgente che passa la fine) esce dall'immagine dopo i due tagli dell'originale. Le divisioni che fermano il processore sono nei golden come `T`.
