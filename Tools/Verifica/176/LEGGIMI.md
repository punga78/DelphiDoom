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

## Strumenti della sessione "Battlescape dentro la battaglia"

- `Edit-XcomBattleSave.ps1 -In <sav o start.sav.gz> -OutGz <radice>\Tests\Data\XcomBattle\bg\<nome>\start.sav.gz -Edit { ... }`:
  prepara uno scenario che i salvataggi del repository non hanno (`SetUnit`, `SetUnitList`, `SetItem`, `DropItemKey`:
  un oggetto in mano, un alieno accanto a un soldato, ferite, unita' morte). Gli scenari preparati non si committano:
  si mettono in una cartella radice finta (con `bin\OpenXcom\Xcom32.exe` e `Tools\Verifica\176` copiati) e si passa quella
  come `-Root` a `Compare-XcomBattle.ps1`. Gli oggetti alieni vogliono una lista `discovered:` di primo livello.
- `Xcom32 -script`: oltre a `wait`, `move`, `click`, `key`, `shot` ci sono `rclick:x,y` (tasto destro),
  `drag:x1,y1,x2,y2,tasto` e `ckey:sdlkey` (con Ctrl: `ckey:100` = Ctrl+D, il modo di debug con `debug: true` nelle
  opzioni). `Capture-OpenXcomScreen.ps1` ha `chord:mod,vk` (`chord:17,68` = Ctrl+D nel vero).
- `Run-XcomBattleSounds.ps1` (`Xcom32 -soundlog <file>`): il registro dei suoni della battaglia col mixer vero su
  un'uscita senza dispositivo; ogni riga e' `<ms> play <profondita'> <suono> <angolo> (canali, suoni partiti)`, l'ultima
  le statistiche del mixer (RMS, picco, suoni partiti). Il volume dei suoni delle opzioni di riferimento e' 0:
  `-Option soundVolume=100`.
- Quando `Xcom32` cade scrive anche `stack:` con gli indirizzi dei chiamanti nei termini del `.map` (i piu' vicini per
  primi; sono le parole dello stack che puntano dopo una CALL, qualcuna puo' essere un residuo).
- Coordinate utili della finestra 640x400 in battaglia: mano destra (592,346), mano sinistra (48,346), inventario
  (320,304), opzioni (448,330), fine turno (512,304), pulsante di lancio del missile (608,24); le righe del menu delle
  azioni dal basso: (320,360), (320,280), (320,200). Il mouse lasciato su un bordo scorre la mappa (`battleEdgeScroll`).
