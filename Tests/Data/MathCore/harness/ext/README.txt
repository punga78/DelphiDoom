Harness C++ di matx2.golden.txt (issue #236, parte A): LU_Update*, QR_*, SVD_*, Eigen_Solve di idMatX.
Come harness\matx: copiare neo\idlib in C:\harness\ext\idlib, sostituire precompiled.h con precompiled.h.txt,
copiare driver.cpp.txt come idlib\driver.cpp e build.ps1.txt come C:\harness\ext\build.ps1.
Ritocchi alla copia di idlib (la logica del C++ non cambia):
 1. math\Math.h, idMath::SinCos e SinCos64: fsincos con __asm__ come in harness\matx (poi "return;" prima del vecchio blocco);
 2. Heap.cpp, Mem_Alloc16 e Mem_Free16: _aligned_malloc e _aligned_free;
 3. math\Ode.cpp: "const deriveFunction_t dr" nei costruttori.
Poi powershell -File build.ps1 e matx.exe > matx2.golden.txt (Tests\Data\MathCore\matx2.golden.txt).
Il C++ ha due letture non inizializzate che il driver evita: QR_Factor non scrive c[n-1] (il driver azzera c e d) e
SVD_MultiplyFactors legge w[r] per r < numRows (con piu' righe che colonne esce da w: il driver chiama
SVD_MultiplyFactors solo su matrici quadrate). Con le matrici piu' alte che larghe la versione Pascal tratta w[r] come 0 fuori da w.
Nel confronto "(Fabs(rv1[l]) + anorm) == anorm" di SVD_Factor il clang x87 somma in precisione estesa: il Pascal usa un Extended.
