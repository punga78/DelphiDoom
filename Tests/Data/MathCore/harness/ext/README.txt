Harness C++ di matx2.golden.txt (issue #236, parte A): LU_Update*, QR_*, SVD_*, Eigen_Solve di idMatX.

Fuori dal repository, in C:\harness\ext: una copia di neo\idlib in C:\harness\ext\idlib, con
  - precompiled.h = precompiled.h.txt (e' quello di harness\ode_curve, NON quello di harness\matx: il suo _alloca16
    azzera la memoria, quindi le letture di memoria non inizializzata del C++ danno zero);
  - driver.cpp = driver.cpp.txt;
  - C:\harness\ext\build.ps1 = build.ps1.txt.
Tre ritocchi alla copia di idlib (nessuna riga di logica cambia):
 1. math\Math.h, idMath::SinCos e idMath::SinCos64: l'`_asm` di MSVC non compila sotto clang. Nel corpo, subito dopo
    la riga della firma, si mette
        long double ss, cc;
        __asm__ ( "fsincos" : "=t"(cc), "=u"(ss) : "0"((long double)a) );
        s = (float)ss; c = (float)cc;      // (double) in SinCos64
        return;
    e il vecchio "#ifdef _WIN32 ... #else ... #endif" resta dopo il return (si cambia "#ifdef _WIN32" in "#if 0");
 2. Heap.cpp, Mem_Alloc16 e Mem_Free16: prima di "if ( !mem_heap ) {" si mette
    "if ( 1 ) { return _aligned_malloc( size, 16 ); }" e "if ( 1 ) { _aligned_free( ptr ); return; }";
 3. math\Ode.cpp: "const deriveFunction_t dr" nei costruttori (come harness\ode_curve).
Poi powershell -File C:\harness\ext\build.ps1 e C:\harness\ext\matx.exe > matx2.golden.txt
(= Tests\Data\MathCore\matx2.golden.txt, 222 righe).

Il C++ ha due letture non inizializzate che il driver evita: QR_Factor non scrive c[n-1] (il driver azzera c e d) e
SVD_MultiplyFactors legge w[r] per r < numRows (con piu' righe che colonne esce da w: il driver chiama
SVD_MultiplyFactors solo su matrici quadrate; la versione Pascal tratta w[r] come 0 fuori da w).
QR_MultiplyFactors e SVD_MultiplyFactors, anche su matrici quadrate, non restituiscono la matrice di partenza
(il golden ha gli stessi numeri del Pascal): sono difetti dell'originale, conservati.
Nel confronto "(Fabs(rv1[l]) + anorm) == anorm" di SVD_Factor il clang x87 somma in precisione estesa:
TIdMatXSvd.IsNegligible lo riproduce esattamente (meta' dell'ultima cifra della mantissa a 64 bit) a 32 e a 64 bit.
