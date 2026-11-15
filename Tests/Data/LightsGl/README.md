# PK3 di prova delle luci dinamiche (GLDEFS) nel renderer OpenGL (issue #249)

Dati sintetici scritti da `Make-LightPk3.ps1`: **dominio pubblico (CC0)**, nessun asset di un gioco.
Servono a mettere il disegno delle luci dinamiche (`gld_SortDlights` e `gld_DrawDLights`, ora
`TEngineGlSceneLightSorter` e `TEngineGlSceneLightPainter`) nel flusso del registratore delle chiamate OpenGL
(`Tools\Verifica\opengl`): le luci si disegnano solo con `uselightboost=1` e solo per le cose che hanno una luce
legata a uno stato.

| File | Contenuto |
|---|---|
| `zlgt_d.pk3`, `zlgt_h.pk3`, `zlgt_x.pk3`, `zlgt_s.pk3` | un PK3 per gioco (Doom, Heretic, Hexen, Strife) con il solo lump `GLDEFS`. Il nome non supera 8 caratteri: `-file` lo passa a `ExtractFileBase` |
| `GLDEFS` | sei luci (due `pointlight`, una con `offset`; due `flickerlight`; due `pulselight`, una con `colorinterval`) e, per ogni tipo di oggetto del gioco (da `<Gioco>\info.pas`, indicato col **numero**: il parser accetta `object <numero>`), una riga `frame <SPRITE> { light <luce> }` per ogni sprite dei suoi stati, con le luci a turno; **un oggetto ogni quattro** e' lasciato senza luce, cosi' il motore gli mette l'ombra (`gl_drawshadows`) |

**Non si usa `object -1`**: il software lega a ogni oggetto le luci con indice -1 (`r_softlights`), il disegno OpenGL
legge solo quelle con il tipo dell'oggetto (`TEngineGlSceneLightMarker.MarkLights`); la differenza e' conservata.

Uso (il gioco rifiuta file esterni nelle versioni shareware senza `-devparm`; `-Lights` lo aggiunge e passa con `-config` una copia del `.ini`
del gioco con `uselightboost=1` e `gl_drawshadows=1`: nei `.ini` dei giochi `uselightboost` e' 0):

```
Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom -Lights
Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom -Lights -WithMonsters -Tics 300 -Scenario "-iwad DOOM1.WAD -timedemo demo3"
Tools\Verifica\opengl\Misura-Gl.ps1 -Game GLDoom -Lights -Pairs 6
```

`Confronta.ps1` stampa dopo ogni confronto i dischi del flusso: una luce e' `glBegin($0006)` (`GL_TRIANGLE_FAN`, 18 vertici),
colore `glColor4f(r*0.2, g*0.2, b*0.2, 0.1)`; le ombre degli sprite (`gld_GetDynamicShadow`) sono dischi con rosso e blu a 0.
Senza `-Lights` i dischi sono 0 in ogni gioco.

Rigenerare: `powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\LightsGl\Make-LightPk3.ps1` (uscita deterministica).

Cosa si vede nel flusso (tic registrati dal 35; `-WithMonsters` dove scritto):

| Scenario | righe del flusso | dischi | di cui ombre |
|---|---|---|---|
| Freedoom 2 MAP01, 70 tic | 178171 | 420 | 0 |
| Doom 1 E1M1, 70 tic | 163001 | 1400 | 0 |
| Freedoom 2 MAP01, 300 tic con i mostri | 814901 | 2700 | 0 |
| Doom 1 `-timedemo demo1` (E1M5), 300 tic con i mostri | 533015 | 4837 | 30 |
| Doom 1 `-timedemo demo3` (E1M7), 300 tic con i mostri | 805753 | 7368 | 309 |
| Heretic E1M1, 300 tic con i mostri | 1341981 | 11700 | 300 |
| Hexen MAP01, 300 tic con i mostri | 3906906 | 9000 | 600 |
| Strife map32, 300 tic con i mostri | 72001 | **0** | 0 |

**Strife: nessuna luce nel flusso.** Le cose che la mappa 32 dello shareware mostra nei primi 300 tic non danno ne' luci ne' ombre
(il flusso con e senza pacchetto ha le stesse righe, 16801 a 70 tic): il pacchetto di Strife e' pronto ma la parita' su Strife prova
solo che, con la luce accesa e il buffer vuoto, nulla cambia. Una scena con cose vicine al giocatore servirebbe
un pilota (`-record -autodemo` con `-glrecord` va in crash anche con il codice di partenza).

La texture di luce: il disco non ha texture (`glDisable(GL_TEXTURE_2D)`); quella delle luci e' la lightmap
(`gl_uselightmaps`, `gl_lightmaps`), che legge lo stesso buffer ordinato e nel flusso compare come `glTexSubImage3D`
(14412 chiamate in `demo3`, 300 tic).

Non coperti: luci di settore (`sectorlight` non esiste nel parser), Strife (vedi sopra), Win64 (solo compilato).
