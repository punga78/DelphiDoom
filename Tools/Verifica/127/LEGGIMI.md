# Verifica #127: il movimento del giocatore di Quake III (bg_pmove)

Produce `Tests\Data\Pmove\pmove-golden.txt` con il codice **vero** di Quake III, non riscritto.

```
sh Tools/Verifica/127/build.sh <cartella di uscita>
sh Tools/Verifica/127/make-golden.sh <cartella di uscita>
```

- **Compilatore**: il gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`: ogni operazione float e' arrotondata da sola, come nel #117, #116 e #128). Lanciare con `sh` di Git Bash; i `.sh` sono in LF (`.gitattributes`).
- **Cosa viene dal C**: `build.sh` compila **tali e quali** `Reference\quake3\code\game\bg_pmove.c`, `bg_slidemove.c` e `bg_misc.c` (quest'ultimo per `BG_AddPredictableEventToPlayerstate` e `bg_itemlist`), con i veri `q_shared.h`, `bg_public.h`, `bg_local.h`. Di `q_math.c` (ha assembler di MSVC) si estraggono per nome, con awk, le funzioni intere che il movimento usa: `vec3_origin`, `AngleVectors`, `VectorNormalize`, `VectorNormalize2`.
- **Cosa non viene dal C** (`pmgen.c`): gli stub del motore (`Com_Printf` raccolto in un buffer, `Com_Error`, `trap_SnapVector` = arrotondamento al pari come il `fistp` di `Sys_SnapVector`), **il mondo finto**, la generazione degli scenari e le impronte.
- `premath.h` (`gcc -include`): nella compilazione originale (MSVC) `M_PI` e' la costante **float** di `q_shared.h`; il `math.h` di mingw la definisce prima come double e `AngleVectors` moltiplicherebbe in double. Il file rimette la costante float. Senza, le direzioni di movimento differiscono di 1 o 2 ulp (trovato cosi').
- `MISSIONPACK` e `_DEBUG` non sono definiti (baseq3 e baseoa): `STAT_WEAPONS` e' 2, `WP_NUM_WEAPONS` 11.

## Il mondo finto

Una lista di **brush convessi** (piani) spazzati da una scatola con l'algoritmo di `CM_TraceThroughBrush` (epsilon 0,125, `startsolid`, `allsolid`, entita' del mondo o `ENTITYNUM_NONE` come `SV_Trace`), piu' il contenuto di un punto. 90 brush: pavimento, 5 zone con flag di superficie (`SLICK`, `METALSTEPS`, `NOSTEPS`, `NODAMAGE`, due insieme), scale di 8, ostacoli di 20, 16, 18 e 17 (il passo e' 18), tre rampe (camminabile, troppo ripida, con la normale z esattamente `0.7f`), tre vasche con bordo a 108 e superficie a 100 (acqua, melma, lava: dall'acqua si esce con il salto sul bordo), acqua bassa a 12 e a 30, una piattaforma alta, un pilastro, un corridoio con soffitto a 44 (in piedi servono 56, accovacciato 40), cinque gradini bassi (3, 6, 9, 13, 17), due muri a 45 gradi che si incrociano, 36 pali di entita' diverse, un mover, un corpo (`CONTENTS_BODY`, che un cadavere attraversa), un blocco `PLAYERCLIP`, le mura esterne, un soffitto e il pavimento. Il Pascal (`Tests\Source\DelphiDoom.Tests.Pmove.Support.World.pas`) legge gli **stessi brush dal golden** (piani come bit di float) e li spazza con lo stesso algoritmo: il mondo non e' scritto due volte.

## Gli scenari

192 scenari di 16 tipi (camminata, salti, accovacciata, gradini, rampe, superfici, acqua, melma e lava, cadute, muri e angoli, noclip/spettatore/volo, morte e blocchi, rinculo/salto dall'acqua/rampino, armi e oggetti, tempi e passi fissi, stati casuali), seme fisso (xorshift32), 32220 comandi. Ogni scenario e' nel golden con lo stato iniziale (solo le parole non zero del `playerState_t`), i parametri (`tracemask`, `noFootsteps`, `gauntletHit`, `pmove_fixed`, `pmove_msec`, `debugLevel`) e i **comandi come segmenti** (stesso comando ripetuto, angoli che crescono di un passo); il Pascal non genera niente, riesegue. Dopo **ogni comando** il golden ha l'impronta FNV-1a a 32 bit di: le 117 parole dello stato, `numtouch` e le entita', `mins`, `maxs`, `watertype`, `waterlevel`, `xyspeed` (float come bit), il comando come l'ha lasciato la chiamata (`Pmove` lo cambia) e il testo che `Com_Printf` ha scritto.

Il `pmove_t` e' azzerato a ogni comando, come fa `ClientThink_real`.

Coperture (stderr di `make-golden.sh`): eventi 1-3, 5-12, 14-18, 21-26, 30, 76 (tutti quelli che il movimento genera tranne `EV_FOOTWADE`, che non genera), tutti i `pm_flags`, tutti i `pm_type`, i quattro livelli d'acqua, terra sul mondo e su un'entita'.

## Cercare la prima differenza

`pmgen dump <id>` stampa, per ogni comando, le parole dello stato, i risultati e il testo; il test del Pascal, quando un'impronta differisce, scrive nella cartella temporanea `pmove-scenario-<id>.txt` con lo stesso formato (parole in maiuscolo, i float come bit): `tr 'A-F' 'a-f'` e `diff` danno il primo comando e il campo (indice della parola = posizione nel record, vedi `TQ3PlayerState`). Per valori intermedi (dentro `PM_WalkMove`, ...) si compila una copia di `bg_pmove.c` con `printf` (si ritaglia con awk) e si stampano gli stessi valori dal Pascal: cosi' sono stati trovati `M_PI` e `float total` di `PM_CmdScale`.
