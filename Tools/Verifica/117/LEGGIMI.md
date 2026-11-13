# Verifica #117: suddivisione delle patch di Quake III

Produce `Tests\Data\MathCore\patch.golden.txt` con le funzioni **vere** di Quake III (`R_SubdividePatchToGrid`, `R_GridInsertColumn`, `R_GridInsertRow`, `MakeMeshNormals`...), non riscritte: `build.sh` ritaglia per intervalli di righe `Reference\quake3\code\renderer\tr_curve.c`, le funzioni vettoriali di `game\q_shared.h` e `q_math.c` e le struct di `qfiles.h` e `tr_local.h` in `grid_original.inc`; `stubs.h` sostituisce il renderer (memoria, cvar `r_subdivisions`, macro dei vettori) e `gridgen.c` e' il pilota con le patch scritte a mano.

```
sh Tools/Verifica/117/build.sh <cartella di uscita>
<cartella>/gridgen.exe > Tests/Data/MathCore/patch.golden.txt
```

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`: ogni operazione float arrotondata da sola).
- Il programma **non** si deve chiamare `patch*.exe`: Windows lo prende per un installatore e chiede i privilegi.
- Le patch sono quelle di `Tests\Source\DelphiDoom.Tests.MathCore.Patch.Parity.pas` (stessi generatori: reticolo da 64 unita' con z a righe/colonne dispari, anello chiuso, punto, retta, 24 patch casuali da xorshift32 con seme fisso, limite di 65x65, inserimenti). Se si cambia uno scenario vanno rifatti entrambi.
- Una riga per caso: `case nome larghezza altezza FNV-1a32 dei vertici`, poi `we`/`he` (errori di colonne e righe), `bounds`, `origin`/`radius`/`lod`, e tre vertici; tutti i float come bit esadecimali.
