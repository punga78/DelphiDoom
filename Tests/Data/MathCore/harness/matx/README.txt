Harness C++ di matx.golden.txt (issue #95, seconda fetta)

Fuori dal repository: una cartella di lavoro (qui C:\harness\matx) con una copia di doom3\neo\idlib
(la cartella `idlib` di Reference\doom3\neo) il cui `precompiled.h` e' quello finto delle altre parita'
(stub di idSys, idCommon, idCVar; vedi Tests\Data\MapFile\harness\precompiled.h.txt, qui con in piu'
`#include "math/Lcp.h"` e `math/Ode.h`). `driver.cpp.txt` va copiato come `idlib\driver.cpp`,
`build.ps1.txt` come `build.ps1` accanto a `idlib`, poi `powershell -File build.ps1` e
`matx.exe > matx.golden.txt` (circa 700 KB: Tests\Data\MathCore\matx.golden.txt).

Tre ritocchi alla copia di idlib, perche' bcc32c e il motore di prova non li accettano cosi' come sono
(il C++ di Doom 3 resta quello vero, nessuna riga di logica cambia):
 1. math\Math.h, idMath::SinCos: l'`_asm { fld ... fsincos ... }` di MSVC si rompe sotto clang; si usa
    `__asm__ ( "fsincos" : "=t"(cc), "=u"(ss) : "0"((long double)a) )` (stessa istruzione x87).
 2. Heap.cpp, Mem_Alloc16 e Mem_Free16 senza lo heap del motore: `_aligned_malloc( size, 16 )` e
    `_aligned_free` al posto di malloc e free (idMatX e idVecX pretendono memoria a 16 byte).
 3. Si compilano Str, Heap, math\Math, Vector, Matrix, Angles, Quat, Rotation, Plane, Pluecker, Polynomial,
    Complex, Simd_Generic, Lcp e geometry\JointTransform; `SIMDProcessor` e' un `idSIMD_Generic`.

Formato: una riga per caso, "nome ingressi | uscite", i float come '#' e le otto cifre esadecimali del loro
pattern IEEE; i numeri interi e i flag come sono; ogni operazione di un caso scrive un token ';nome' prima
della sua risposta (la prima parola della riga e' `<famiglia>_all`). Le righe sono ricalcolate dagli ingressi
da Tests\Source\DelphiDoom.Tests.MathCore.Matrix.Parity.pas. Quattro accorgimenti per non confrontare
memoria non inizializzata o rumore del compilatore: le matrici "singolari" hanno una riga di zeri (la
cancellazione esatta e' uguale con x87 e con float), le matrici casuali hanno una diagonale dominante
(i metodi a blocchi di InverseFast perdono tutto su un blocco quasi singolare), dopo un
Cholesky/LDLT_UpdateIncrement fallito non si scrive nulla (la nuova diagonale non e' inizializzata) e di un
autovettore si scrive il segno con la componente maggiore positiva (il segno dipende dall'arrotondamento).
