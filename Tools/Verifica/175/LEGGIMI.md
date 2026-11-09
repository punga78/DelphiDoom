# Verifica #175 (xGreed): parita' dei dati e prova dell'originale

Tre strumenti: i golden dal codice originale (`GreedGolden.dpr`, `SaveGolden.dpr`), l'originale DOS in DOSBox
(`Run-GreedDos.ps1`) e il sorgente Delphi originale compilato in una copia. I dati del gioco **non sono nel repository**
(`Reference\_dati\greed`, provenienza in `Reference\_dati\MANIFEST.md`).

## 1. Golden dal codice originale

`GreedGolden.dpr` usa `d_disk.pas`, `g_fixlump.pas` e le formule di `LoadTextures`/`ScaleMaskedPost` di xGreed
(`Reference\xGreed`, con le correzioni minime per Delphi 11 di `Reference\_analisi\fetta0.md`) e scrive:

```
GreedGolden <GREED.BLO> <uscita.txt> [LEVEL1.LAY ...]
```

Righe `H`, `R`, `L`, `K`, `W`, `F`, `S`, `P` (vedi `Tests\Data\README.md`) e, per le mappe **dentro il BLO**, `B numero lump piano
"nome" crc32` (`LoadNewMap` originale: `seek` alla posizione del lump e 18 `fread` da 4096). Golden nel repository:
`blo_demo1016`, `blo_demo20` (le demo), `blo_full` (gioco completo, 3911 righe).

Compilazione (fuori dal repository): `dcc32 -B -W- -H- -NSVcl;System;Xml;Data;Winapi;System.Win -U<src>;<src>\Base;<src>\Greed;<src>\zlib
-I<src>;<src>\Greed -R<src> GreedGolden.dpr` con `<src>` = copia corretta di `Reference\xGreed`.

Il test `DelphiDoom.Tests.Greed.Golden` (`Tools\build.bat DelphiDoom.Tests.Greed Debug`, poi `bin\Tests\DelphiDoom.Tests.Greed.exe`)
confronta la libreria con i tre golden; il gioco completo si cerca in `Reference\_dati\greed\full\GREED.BLO` e si salta se manca.

## 2. L'originale DOS in DOSBox

```
powershell -NoProfile -File Tools\Verifica\175\Run-GreedDos.ps1 -Data <greed\full> -Cd "<greed\cdrom\Greed CD-ROM>" -Out <cartella>
```

Cose imparate (gioco completo `GREED.EXE` v1.000.039, DOS4GW 1.97):

- E' la versione **CD-ROM**: senza controllo dice `CheckCDROM: In Pursuit of Greed CDROM not found!`; l'argomento
  `nocdromcheck` lo salta. I filmati sono `A:\MOVIES\*.FLI` (le `MOVIES` e `GREED.SHR`/`TMASTER.SHR` stanno nel
  secondo archivio, quello del CD): in DOSBox `mount a <cartella> -t floppy` con i filmati accanto a `GREED.BLO`.
- Con il `SETUP.CFG` fornito (Sound Blaster, `VSB.DRV`) DOSBox si ferma dopo il banner di DOS4GW: si toglie e si
  usa `sbtype = none`. Con `fixed 60000` cicli parte (circa 30 s per caricare).
- Cattura: `Ctrl+F5` di DOSBox (scrive in `%LOCALAPPDATA%\DOSBox\capture`). `CopyFromScreen` sulla finestra a
  volte non vede il contenuto; i tasti si mandano con `keybd_event` (il gioco legge la tastiera a polling).
- Sequenza: logo (Mind Shear), scheda del personaggio (Esc), menu (altri Esc; la freccia e' un puntatore mosso dai tasti),
  `NEW` (Invio), schermate della missione (spazio), livello 1 ("Desarian Orbital Penal Colony", sala dell'ispezione).
  Il numero di spazi dipende dai tempi (il testo si scrive lettera per lettera): le immagini si guardano a mano.

## 3. Il sorgente Delphi originale compilato in una copia

Copia in `Reference\_dati\xgreed_build` (mai in `Reference\xGreed`): le quattro correzioni di `correzioni.diff`
(`g_delphi.pas`, `pngimage.pas`, `menu.pas`, `timer.pas`) e, **solo per la prova**, `m_screenshot.pas` che scrive un BMP al
posto del PNG (con Delphi 11 `pngimage` scrive i nomi dei chunk in UTF-16, il file di Stampa e' illeggibile: difetto
Unicode dell'originale). Si compila con `dcc32` dalla cartella `src` (percorsi sopra, `xGreed.dpr`), si copia
`bass.dll` (`Reference\_dati\_strumenti\bass`), `GREED.BLO` e le musiche in `run\` e si avvia con
`Tools\Esegui-gioco.ps1 -Exe run\xGreed.exe -Arguments -x -Seconds 300` (l'argomento fittizio serve al lanciatore).
Il tasto **Stampa** salva lo schermo in `run\ScreenShots\` (la finestra e' DirectDraw a schermo intero: nessuna
altra cattura funziona). Con il gioco completo non c'e' l'errore `MCURSOR not found` della demo 1.016: carica,
mostra scheda del personaggio e menu (`Esc`; il tasto sinistro porta su `NEW`) e arriva al livello 1 con
l'interfaccia (HUD, bussola, radar), 640x400.

## 4. Greed32

`Greed32 -data <cartella> -list | -map N -png file | -lump nome -png file | -play N [-autoplay] [-ticks T] [-shot file.png]`
legge il gioco completo con la libreria (le 32 mappe sono dentro `GREED.BLO`, nessun `.LAY`); `-play` e' la vista dall'alto
con il giocatore che cammina (il renderer 3D e' G11, non fatto). Le immagini a schermo intero hanno la loro palette nel lump
seguente (768 byte): `-lump` usa la palette del gioco e i colori vengono sbagliati (logo `credits3`).
