# Libs\IdLib - il port in Delphi di idLib (Doom 3 / idTech 4)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

idLib e la libreria di base di Doom 3 (`Reference\doom3\neo\idlib`, circa 100000 righe, di cui 60000 sono SIMD).
Qui ci sono i pezzi con comportamento proprio, riscritti a classi nello stile del repository (interfacce piccole,
dipendenze dal costruttore, eccezioni dedicate al posto di `common->Error`). **Nessun chiamante nel motore** di
Doom, Heretic, Hexen e Strife: e una base per codice ispirato a idTech 4 (il come usarla e in `WIRING.md`).

## Licenza

Doom 3 e sotto **GPL v3 con i termini aggiuntivi** di id Software (`Reference\doom3\COPYING.txt`); il repository e
GPL v2 o successiva. Le unit che portano codice di idLib lo dichiarano nell'intestazione ("derived from the Doom 3 GPL
source code ... GPL v3 con i termini aggiuntivi"), quindi **l'opera che le contiene va distribuita sotto GPL v3**.
Dichiarazione per unit:

| Unit | Origine |
|---|---|
| `Text.Strings`, `Text.Str`, `Text.Types`, `Text.Token`, `Text.Lexer`, `Text.CmdArgs`, `Text.Base64` | **port** di `Str`, `Token`, `Lexer`, `CmdArgs`, `Base64` (traduzione del comportamento, stesso algoritmo) |
| `Containers.*` | **port** di `containers\*.h` e `HashIndex.cpp` |
| `Math.Math`, `Math.Random`, `Math.Vec2/3/4` | **port** di `math\Math.*`, `Random.h`, `Vector.*` |
| `Hashing.Md4`, `Hashing.Md5`, `Hashing.Types` | **riscritte da zero** dagli RFC 1320 e 1321 (il C++ serve solo come riferimento di parita) |
| `Core.*` | nuove (sostituiscono i singleton `idLib::common` e `idLib::fileSystem`) |

Nessun sorgente C++ di Doom 3 e nel repository (nemmeno nei test): i golden sono **dati** prodotti dal vero idLib.

## Come e stata provata la parita con il C++

Sul PC c'e `bcc32c` (il compilatore clang di Delphi 11, 32 bit, x87): un harness **fuori dal repository** compila il vero
idLib (una copia di `neo\idlib` con un `precompiled.h` e stub di `idSys`, `idCommon`, `idFile`, `idFileSystem`,
`idCVarSystem`) e stampa le risposte di batterie deterministiche (LCG con seme fisso, file di ingresso condivisi in
`Tests\Data\IdLib`). Le risposte sono i `*.golden.txt` di `Tests\Data\IdLib`, che i test DUnitX rifanno con le classi
Delphi, riga per riga (`TIdLibGolden`: i float sono scritti come `#` piu i bit in esadecimale e confrontati **bit a bit**,
salvo dove dichiarato). Modifiche alla copia (non al sorgente): `idHashTable::GetSpread` usava una variabile `numItems`
mai dichiarata (non era mai istanziata: con clang non compila); `__DATE__`/`__TIME__` del parser scrivevano su `token[7]`
(un oggetto, non un carattere); l'assembler inline MSVC di `SinCos`, `FtoiFast` e `FtolFast` non e accettato da clang e
vale `sinf/cosf`, `rintf`. Per rifare i golden: ricostruire l'harness come sopra e lanciare `golden.exe <fetta> <ingresso>`.

| Golden | Righe | Test |
|---|---|---|
| `hashing.golden.txt` | 168 | `Tests\DelphiDoom.Tests.IdLib.Hashing` (6) |
| `str.golden.txt`, `lexer.golden.txt` (+ `lexer.input.txt`), `codec.golden.txt` | 2271, 6156, 156 | `Tests\DelphiDoom.Tests.IdLib.Text` (15) |
| `containers.golden.txt` | 3999 | `Tests\DelphiDoom.Tests.IdLib.Containers` (16) |
| `math.golden.txt` (+ `math.input.txt`) | 11035 | `Tests\DelphiDoom.Tests.IdLib.Math` (18) |

## Classe idLib -> soluzione Delphi

**Legenda**: *nuova* = classe in `Libs\IdLib`; *RTL* = generics della RTL, nessuna classe; *MathCore* = gia nel repository;
*non portata* = vedi il motivo.

### Contenitori (`containers\`)

| idLib | Soluzione |
|---|---|
| `idHashIndex` | **nuova** `TIdHashIndex` (ordine delle catene, crescita a passi, `GetSpread`, `InsertIndex`/`RemoveIndex` identici) |
| `idHashTable<T>` | RTL `TDictionary<string, T>`: il C++ e una tabella a catene con ordine di inserimento dei nodi, ma non ha chiamanti che lo richiedano (e `GetSpread` non compila: vedi sopra) |
| `idLinkList<T>` | **nuova** `TIdLinkList<T: class>` |
| `idHierarchy<T>` | **nuova** `TIdHierarchy<T: class>` |
| `idBTree<T,K,N>` | **nuova** `TIdBTree<TObj, TKey>` (N e un parametro del costruttore, il confronto un `IComparer<TKey>`) |
| `idBinSearch_*` | **nuova** `TIdBinSearch<T>` (`IComparer<T>` al posto degli operatori) |
| `idStrPool`, `idPoolStr` | **nuova** `TIdStrPool`, `TIdPoolStr` |
| `idList<T>`, `idStaticList<T,N>` | RTL `TList<T>`/`TArray<T>`. Differenze note: `idList::Append` cresce a multipli della granularita, `RemoveIndex` conserva l'ordine (come `TList.Delete`), `RemoveIndexFast` scambia con l'ultimo, `Sort` e `qsort` (non stabile come `TArray.Sort`) |
| `idStrList` | RTL `TList<string>` / `TStringList` |
| `idQueue<T>`, `idStack<T>` | non portate: sono liste intrusive con puntatori `next` dentro l'oggetto; con le classi Delphi si usa `TQueue<T>`/`TStack<T>` |
| `idVectorSet<T,D>`, `idPlaneSet` | **non portate** in questo giro: servono i tipi `idPlane`/`idVec*` della fetta Math (vettore a D dimensioni con tolleranza); da fare con la geometria |

### Stringhe e testo

| idLib | Soluzione |
|---|---|
| `idStr` | **nuova** `TIdStr` (record con tutti i metodi di istanza, sopra `AnsiString`) e `TIdStrings` (le funzioni statiche: `Cmp`, `Icmp`, `IcmpPath`, `Filter`, `Hash`, `FileNameHash`, `FormatNumber`, `FloatArrayToString`...). Non portati: gestione della memoria (`Allocated`, `ReAllocate`, `ShowMemoryUsage_f`), `sprintf`/`snPrintf`/`va` (usare `Format`), `BestUnit`/`SetUnit` (formati `printf`), `ColorForIndex` (tabella di `idVec4`) |
| `idToken` | **nuova** `TIdToken` (record; la catena `next` serve solo al parser) |
| `idLexer` | **nuova** `TIdLexer` (tutta l'API; `baseFolder` e una proprieta dell'istanza) |
| `idCmdArgs` | **nuova** `TIdCmdArgs` (la cvar e opzionale: `IIdLibCVars`) |
| `idBase64` | **nuova** `TIdBase64` (la decodifica a `idFile` non c'e: si scrive il `TBytes` dove serve) |
| `idParser` (macro, `#define`, `#if`) | **non portata**: 3250 righe di preprocessore; il repository ha gia `Libs\Scanner` (scanner dei testi di Doom con `#define`/`#ifdef`/`#include`), con un dialetto diverso. Da portare quando serve il dialetto di Doom 3 (le macro `__LINE__`, `__DATE__`) |
| `idDict`, `idKeyValue` | **non portato**: `TDictionary<string,string>` con `TIStringComparer` copre l'uso; il pool globale di chiavi e valori (`globalKeys`) e un'ottimizzazione di memoria |
| `idLangDict` | **non portato** (usa `idDict` e `idLexer`; una classe di 300 righe sopra `TDictionary`, da fare) |
| `idMapFile` | **portato in `Libs\MapFile`** (issue #106) |
| `idTimer`, `idTimerReport` | non portati: `TStopwatch` della RTL |

### Hash

| idLib | Soluzione |
|---|---|
| `MD4_BlockChecksum`, `MD5_BlockChecksum` | **nuove** `TIdMd4`, `TIdMd5` (digest da 16 byte, aggiornamento a pezzi, `BlockChecksum`) |
| `CRC32_*` | **MathCore** `TCrc32` (il CRC-32 standard: un test lo mostra uguale) |

### Matematica (`math\`)

| idLib | Soluzione |
|---|---|
| `idMath` | **nuova** `TIdMath` (tutte le funzioni, costanti `Single`) |
| `idRandom`, `idRandom2` | **nuove** `TIdRandom`, `TIdRandom2` (record con il seme) |
| `idVec2`, `idVec3`, `idVec4` | **nuovi** `TIdVec2/3/4` (record con operatori; `ToAngles`/`ToPolar` danno i tre numeri perche `idAngles`/`idPolar3` non sono ancora portati) |
| `idVec5`, `idVec6`, `idVecX`, `idPolar3` | non portati in questo giro (servono a `idPluecker`, `idLCP`, `idMatX`) |
| `idMat2`, `idMat3`, `idMat4`, `idMat5`, `idMat6`, `idMatX` (`Matrix.h`, 11000 righe) | **non portate** in questo giro. `Libs\MathCore` ha `TMat3` come `array[0..2,0..2] of Single` con le sole funzioni del motore di Doom (nessun inverso, nessun prodotto con vettore di idTech 4) |
| `idQuat`, `idCQuat`, `idAngles`, `idRotation`, `idPlane`, `idPluecker`, `idComplex`, `idPolynomial`, `idLCP`, `idODE`, `idExtrapolate`, `idInterpolate`, `idCurve*` | non portate in questo giro |
| `idSIMD*` (Simd.cpp, Simd_*.cpp, 40000 righe) | **non portate di proposito**: Pascal puro, nessun SIMD; le funzioni scalari equivalenti stanno nei record |
| tabelle, `idBounds`, `idSphere`, `idBox`, `idFrustum` (`bv\`) | non portate in questo giro (`Libs\MathCore` ha le bbox di Doom a 4 interi, un'altra cosa) |
| `idWinding`, `idWinding2D`, `idSurface*`, `idTraceModel`, `idDrawVert`, `idJointTransform` (`geometry\`) | non portate in questo giro; `Winding` e `TraceModel` servono al modello di collisione, dove lavora un altro port |

### Resto

| idLib | Soluzione |
|---|---|
| `idBitMsg`, `idBitMsgDelta` | **non portato** in questo giro (1100 righe, serve `netadr_t` e `idFile`) |
| `idLib` (`Init`, `ShutDown`, `Error`, `Warning`), `idSys`, `idCommon`, `idCVarSystem` | **interfacce iniettate**: `IIdLibLog` (`Printf`, `Warning`), `IIdLibFileSystem` (`TryReadFile`, `WriteFile`), `IIdLibCVars`; gli errori sono `EIdLibException` (`EIdLibFatalException` per `FatalError`, `EIdLexerException` per il lexer) |
| `idHeap`, `idBlockAlloc`, `idDynamicBlockAlloc`, `Mem_Alloc` | non portate: la gestione della memoria e della RTL |
| endian (`BigLong`...), `Swap_Init`, colori (`PackColor`...), `idException` | non portati (nessun chiamante nelle parti portate; x86/x64 sono little endian) |

## Sovrapposizioni con `Libs\MathCore` e con il lavoro su `cm`

* `Libs\MathCore` ha `TVec2/TVec3 = array of Single` e `TMat3` come **alias di array** con funzioni statiche (`TVectorMath`),
  per il motore di Doom; i `TIdVec2/3/4` di qui sono **record con operatori** e il comportamento di idTech 4. Sono tipi
  distinti: non c'e conflitto di nomi (`TIdVec*` contro `TVec*`), ne unit in comune. Per unificarli basta un `Implicit` tra
  `TIdVec3` e `TVec3` (stessa disposizione di 3 `Single`).
* `TCrc32` (MathCore) e `CRC32_BlockChecksum` di idLib sono lo stesso algoritmo: nessuna classe nuova.
* Il lavoro su `Reference\doom3\neo\cm` (`Libs\Collision`) avra bisogno di `idPlane`, `idBounds`, `idWinding`, `idTraceModel`,
  `idMat3`, `idVec5/6`, `idPluecker`: **non sono qui** (e `Libs\Collision` non e stato toccato). Cio che e gia pronto per quel
  lavoro: `TIdVec2/3/4`, `TIdMath`, `TIdHashIndex`, `TIdBTree`, `TIdLinkList`, i contenitori e `TIdLexer` (per i file `.cm`).

## Differenze volute dal C++

| Cosa | C++ | Delphi |
|---|---|---|
| `float` | 32 bit, x87 con precisione estesa nelle espressioni | `Single`. Il compilatore Delphi (x87) e `bcc32c` tengono entrambi i risultati intermedi in 80 bit e arrotondano agli assegnamenti, **ma clang arrotonda a 32 bit anche quando un valore parziale e salvato prima della chiamata di una funzione** (sqrt, floor...). Dove succede il codice Delphi usa una variabile `Single` locale (esempio `TIdMath.ASin16`). A 64 bit (SSE) i bit possono cambiare nell'ultimo posto: i test dovrebbero usare una tolleranza |
| costanti `float` | `0.0187293f` e un float | un letterale Delphi e `Extended`: le costanti sono `Single` tipizzate (`C_SIN_0`...) |
| `M_RAD2DEG`, `M_DEG2RAD` | `180.0f / PI`, `PI / 180.0f` con il `float` PI | uguali (non il rapporto esatto) |
| funzioni di libreria `sinf`, `cosf`, `tanf`, `atan2f`, `expf`, `logf`, `powf` | Dinkumware (riduzione dell'argomento in float: `sinf(2*pi)` da 0) | `fsin` ecc. dell'x87 in precisione estesa: **fino a 16 ULP o 1e-5 assoluti di differenza** (il test lo dichiara, solo per quelle righe; il resto e a bit) |
| `idMath::Sin64`, `Cos64`, `Exp64`, `Log64` | con `float` in ingresso la libreria C++ usa l'overload `float` (precisione 32 bit) | vera precisione a 64 bit |
| maschere dell'FPU | divisioni per zero danno infinito | in Delphi le eccezioni sono attive di default: chi usa la libreria con valori limite deve fare `SetExceptionMask(exAllArithmeticExceptions)` (i test lo fanno) |
| `>>` su `int` | aritmetico | `shr` di Delphi e logico: `TIdMath.Sar` (e `Ftoi`, `FtoiFast`, `Ftol` danno `$80000000` fuori intervallo senza eccezione) |
| `unsigned long` | 32 bit su Win32 | `Cardinal` (uguale su Win32 e Win64) |
| `char` con segno | byte sopra 127 negativi (confronti, hash, spazio bianco del lexer) | riprodotto (`ShortInt`) |
| `idStr` con byte `#0` | la stringa termina | le funzioni statiche si fermano al `#0` (`TIdStrings.Length`), i metodi di `TIdStr` no |
| `idStr::Append(text, len)` con testo piu corto di `len` | `len` resta incoerente | aggiunge solo i caratteri che ci sono |
| `idStr::Replace` con vecchio testo vuoto | ciclo infinito | non fa nulla |
| `idVec3::Cross(a, b)` con `a` o `b` uguale a `this` | sovrascrive prima di leggere (risultato sbagliato) | calcola le tre componenti prima |
| `idStr::Mid` con inizio negativo | legge prima del buffer | taglia la parte prima dell'inizio |
| `"%f"` | `printf` della libreria C | `TIdStrings.FormatFixed`: stesso arrotondamento (valore binario esatto, pari al pari, segno meno sullo zero negativo) |
| lexer: `1.#INF` con `LEXFL_ALLOWFLOATEXCEPTIONS` | `CheckString("INF")` confronta da `#` (difetto: la bandiera non e mai messa) | **conservato**: il token ha lo stesso valore sbagliato (e nei golden); i cinque `CheckString` mai veri sono stati tolti (issue #141), restano i quattro caratteri presi dopo il `#` |
| lexer: stringa con `\0` dentro | `idStr::ReAllocate` usa `strcpy` e perde il resto | non coperto dai golden (comportamento indefinito) |
| lexer: lettura oltre la fine del testo (`1.#X` in fondo) | legge i byte dopo il terminatore | legge `#0` |

## Cosa resta

`idParser`, `idDict`, `idLangDict`, `idMapFile`, `idBitMsg`, la parte di matrici (`idMat*`, `idMatX`, `idLCP`), la geometria
(`idPlane`, `idBounds`, `idWinding`, `idSurface`, `idTraceModel`), i quaternioni e gli angoli, le curve. Il piano di lavoro e
l'ordine consigliato (dipendenze) sono nel `WIRING.md`.
