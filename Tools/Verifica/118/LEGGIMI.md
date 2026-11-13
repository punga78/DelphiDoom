# Verifica #118: collisione di Quake III (BSP, brush, contenuti, tracce)

Produce `Tests\Data\Collision\q3cm.golden.txt` e i BSP `q3world0.bsp`, `q3world1.bsp` con il codice **vero** di Quake III, non riscritto: `build.sh` copia in una cartella di lavoro `cm_load.c`, `cm_test.c`, `cm_trace.c`, `cm_local.h`, `cm_polylib.h`, `cm_public.h`, `qfiles.h` di `Reference\quake3\code\qcommon` e `game\q_math.c`, e li compila con il gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`, `-DNDEBUG`). Gli stub sono due: `qcommon.h` (memoria da un'arena, cvar a zero, file system che legge il file, `Com_Error` che ferma il programma) e `stubs.c`; `game\q_shared.h` e' un guscio che include quello vero dopo aver tolto il `M_PI` di `math.h`, cosi' vale il `float` di `q_shared.h` come in MSVC (anche `q_math.c` e' copiato accanto al guscio). `cm_patch.c` **non** e' compilato: `stubs.c` ha una patch che non collide, come la libreria Pascal finche' non c'e' un costruttore delle patch.

```
sh Tools/Verifica/118/build.sh <cartella di uscita>
sh Tools/Verifica/118/make-golden.sh <cartella di uscita>
```

- `cmgen write <variante> <file>` scrive un BSP sintetico (variante 0: 45 brush, visibilita'; variante 1: 30 brush, senza visibilita'); xorshift32 con seme fisso.
- `cmgen run <file> <seme>` carica con `CM_LoadMap` e stampa conteggi e impronte dei dati caricati, poi le risposte a `CM_PointLeafnum`, `CM_PointContents` (mondo e due modelli interni), `CM_TransformedPointContents`, `CM_BoxLeafnums`, `CM_BoxBrushes`, `CM_BoxTrace` (punto, box, capsula, posizione ferma, maschere diverse), `CM_TransformedBoxTrace`, `CM_TempBoxModel` con tracce contro il box, `CM_ModelBounds`, `CM_InlineModel`, `CM_LeafCluster/Area`, `CM_ClusterPVS` e la sequenza dei portali delle aree.
- Cosa **non** viene dal C: i BSP (il generatore e' scritto qui), il guscio dei file e della memoria. Il C vero da' le risposte; la lettura del file e i controlli sui lump sono quelli di `CM_LoadMap`.
