# Verifica #176: i dati veri di X-COM: Terror from the Deep

Dati forniti dall'utente in `Reference\_dati\_download` (non fidati: non si esegue nulla da lì; ogni passo lavora su
copie in cartelle nuove di `Reference\_dati\xcom_tftd`). **Nessun dato di gioco nel repository.**

## Preparazione (ordine)

```
# 1. i quattro floppy del gioco: le immagini FAT12 si aprono leggendo i byte
foreach ($i in 1..4) { Extract-Fat12.ps1 -Image ...\disk$i.img -Out ...\xcom_tftd\floppy\disk$i }
# 2. TFTD.001..004 sono 33 archivi ZIP uno dopo l'altro (non uno ZIP suddiviso): si concatenano e si aprono uno a uno
Extract-TftdZips.ps1 -Volumes disk1\TFTD.001,disk2\TFTD.002,disk3\TFTD.003,disk4\TFTD.004 -Out ...\xcom_tftd\gioco
# 3. i file messi nelle cartelle del gioco (quello che vede OpenXcom e Libs\XcomFormats)
Make-TftdLayout.ps1 -Flat ...\xcom_tftd\gioco -Out ...\xcom_tftd\TFTD
```

La demo (`PCGamerTerrorFromTheDeepDemo.zip`) è un'immagine floppy FAT12 con `TFTD.ZIP`: `Extract-Fat12.ps1`, poi
`Expand-Archive` (sottocartelle `DEMOLBM`, `GEODATA`, `MAPS`, `MISSDAT`, `ROUTES`, `SOUND`, `TERRAIN`, `TFTDEXE`,
`UFOGRAPH`, `UNITS`; la demo è una sola missione tattica, `tftdexe\tactical "1"`).

## OpenXcom vero

`Run-OpenXcomTftd.ps1 -Root ...\xcom_tftd -Out <cartella> -Steps ...` avvia `openxcom\OpenXcom.exe` (copia del nightly
ufficiale 2026-06-05 con `TFTD\` dentro e `openxcom_user\options.cfg`: finestra 640x400 senza OpenGL, suono a 0,
`mods: - xcom2: true`) e salva schermate della finestra. Passi: `wait:s`, `click:x,y` (area client 640x400), `key:vk`,
`shot:nome`. Sequenza che arriva al basescape: `click:320,326` (OK dell'avviso), `click:250,200` (la base sul globo),
`key:65` `key:13` (nome "A"), `click:320,372` (relazioni internazionali), `click:575,34` (Basi).

Per far partire OpenXcom con i dati servivano queste cartelle (il log dice quale manca, una alla volta):
`GEOGRAPH` ha `BASEBITS`, `INTICON`, `TEXTURE.DAT`, `.SCR`, `.BDY`, `.SPK`; `UFOGRAPH` `CURSOR`, `SMOKE`, `HIT`, `X1`,
`SPICONS.DAT`, `MEDIBITS.DAT`, `DETBLOB.DAT`, `.BDY`, `.SPK`, `.SCR`; `UNITS` ogni altro `.PCK` con il suo `.TAB`
(anche `BIGOBS`, `FLOOROB`, `HANDOB`, `BASEBITS`, `INTICON`: `UNIBORD.PCK` non ha `.TAB` e sta solo in `UFOGRAPH`,
altrimenti OpenXcom si ferma con "UNITS/unibord.TAB not found"); `TERRAIN` `.MCD` e i `.PCK`/`.TAB` dei terreni più
`BLANKS` e `LOFTEMPS.DAT`.

## L'originale in DOSBox

`Run-TftdDos.ps1 -Data ...\xcom_tftd\dos -Out ...\xcom_tftd\dosrun -Command terror.com -Steps ...` (DOSBox Staging
0.83, `sbtype none`, `cycles max`). `TERROR.COM` è il lanciatore: chiama `SOUND\sndstart`, `INTRO`, `UFOEXE\black`,
`UFOEXE\geoscape "0"`, `UFO2exe\tactical "1"`, `SOUND\sndend`, e senza quelle cartelle risponde "Bad command or file
name" cinque volte; per questo `dos\` ha `UFOEXE\` e `UFO2EXE\` con `GEOSCAPE.EXE`, `TACTICAL.EXE`, `BLACK.EXE`,
`DOS4GW.EXE` e `SOUND\` con `SNDSTART.EXE`, `SNDEND.EXE`, `SOUNDRV.COM`, `MUSIC.COM`, `VECTOR.COM`. Il caricamento
dura circa 70 secondi prima della scelta della lingua (`click:800,430` = English: le coordinate sono quelle
dell'immagine catturata 1600x1200, l'area di gioco sta al centro di una finestra 960x600), poi logo MicroProse,
introduzione e titolo; `key:esc` salta le schermate dell'introduzione. Le animazioni (`ANIMS`) e `SOUND\INTRO.CAT` non
sono nei floppy. **Non riuscito**: dopo l'introduzione (anche saltata con Esc) `UFOEXE\geoscape` non disegna nulla (schermo nero per almeno 90 secondi, con `cycles max` e senza scheda audio); non si è indagato (serve guardare `black.exe` e gli argomenti di `terror.com`, o provare `geoscape.exe` da solo).

## Test

`Tests\DelphiDoom.Tests.Xcom` trova la cartella `Reference\_dati\xcom_tftd\TFTD` risalendo dall'eseguibile (o
`DELPHIDOOM_XCOM_DATA`) ed esegue `DelphiDoom.Tests.Xcom.RealData`. `Xcom32 -data ...\TFTD -pal 0 -pck TERRAIN\PORT01.PCK
-png x.png` esporta gli sprite.

`Xcom32.exe` e' l'unico programma (issue #180): con `-pck`, `-dat`, `-scr` o `-map` esporta (e `-data` e' la cartella
del gioco), altrimenti e' il gioco (`-data` e' la cartella con `common\` e `standard\`, `-game` quella del gioco): gli
script di questa cartella lo chiamano cosi'. E' un programma GUI: in PowerShell va lanciato con una pipe (`| Out-Null`,
`| Out-String`) perche' la shell aspetti la fine e riceva il testo; con `> file` non aspetta e il file resta vuoto.

## Battaglia in corso: `Compare-XcomBattle.ps1`

Carica un salvataggio con la battaglia in corso (`Tests\Data\XcomBattle\bg\<scenario>\start.sav.gz`, scritto dal vero
OpenXcom con `battle\bgame`) in `Xcom32 -script` e, con `-Real`, nel vero OpenXcom (F12), poi confronta le schermate
con `Compare-Png.ps1`. Coordinate della finestra 640x400. `-Option chiave=valore` cambia `options.cfg` per entrambi
(per esempio `battleNewPreviewPath=3`). La cartella utente e' `<Out>\user`: mai quella di `bin\OpenXcom`. Le
animazioni della mappa vanno allineate con piu' scatti a 100 ms. Dettagli e numeri in
`Libs\XcomBattleStates\CLAUDE.md`.

## Missioni dal geoscape: `Make-XcomMissionSave.ps1` e `Run-XcomMission.ps1`

`Make-XcomMissionSave.ps1 -Root <worktree> -Out <file.sav> -Kind crash|landed|site|alienbase|defense|final` scrive un
salvataggio (da `Tests\Data\XcomSave\variants\save02_dogfight.sav`, senza dati del gioco) in cui il Triton con sei
soldati e' gia' sul bersaglio, o un UFO di ritorsione e' sulla base (`-Defenses n`, `-Shield`, `-Undefended`,
`-Ufo STR_SURVEY_SHIP`), o il Leviathan puo' partire per T'leth (`-Craft STR_LEVIATHAN`, `-Locked` senza la ricerca).
`-Away 0.01` fa partire il velivolo lontano dal bersaglio. I salvataggi di `Tests\Data\XcomSave\missions` (usati da
`DelphiDoom.Tests.XcomTour`) sono fatti cosi'. `Run-XcomMission.ps1 -Root .. -Data <xcom_tftd> -Out <cartella tua>
-Kind .. -Script '<passi>'` lo carica in `Xcom32 -script` (cartella utente `<Out>\user`, ripulita dai salvataggi e
dagli autosalvataggi) e lascia le schermate in `<Out>\shots`. Coordinate utili (640x400): Yes di ConfirmLanding
160,320; OK del briefing 320,345; OK dell'inventario 508,22; fine turno 512,304; abbandono 512,336 e il suo OK
150,235; OK del debriefing 72,372; OK di BaseDefenseState 320,358; OK di BaseDestroyedState 320,305; Intercept
575,12, prima riga 100,161, pulsante T'leth 420,28, Yes 220,305. Il vero OpenXcom carica gli stessi salvataggi
(`Capture-OpenXcomScreen.ps1 -SeedFolder`): cosi' sono stati confrontati i pixel delle conferme.

## Harness della battaglia: fasi successive e debriefing

`battle\gengen.cpp`: `GEN_STAGE=1` (vero `nextStage` dopo un esito scritto in `genNN.stage`), `GEN_MISSION=<deployment>`
(missione degli scenari senza UFO), `GEN_EXTRA=1` (sito o base aliena nel salvataggio, due veicoli nel velivolo).
`battle\debriefgen.cpp`: `DEBRIEF_ZOMBIES=1` (uno zombie preso con la psi-capture). Un processo per scenario (il vero
generatore ogni tanto va in crash), una cartella utente per harness.

## Filmati FLI/FLC: `battle\flcgen.cpp`

`battle\build.cmd <cartella> flcgen` collega il vero `FlcPlayer` di OpenXcom; `flcgen <dati> <utente> <file .FLI/.FLC>
<uscita> [skiplast]` decodifica il file un fotogramma alla volta (un vero `Game` sui driver finti di SDL, velocita' 0
per non aspettare) e scrive per ogni fotogramma l'impronta FNV-1a dei pixel dello schermo e della palette. L'uscita di
`UFOINTRO\UFOINT.FLI` e' `Tests\Data\XcomEngine\flc\ufoint.txt` (891 fotogrammi), confrontata da `TTestXcomRealFlc`.
Durante un filmato il vero OpenXcom non salva schermate con F12 (ogni tasto lo salta): per questo il confronto e'
sulle impronte e non sui PNG. Le diapositive invece si catturano: `Capture-OpenXcomScreen.ps1 -Option 'playIntro=true'`
(la diapositiva che si vede dipende dal tempo: ogni cattura si confronta con tutte quelle di `Xcom32`).
