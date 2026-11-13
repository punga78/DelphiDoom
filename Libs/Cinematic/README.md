# Libs\Cinematic

Decoder dei video RoQ (id Tech 3 e 4) a classi: dai byte del file i fotogrammi a 32 bit e l'audio DPCM a 16 bit, con il tempo dato dall'esterno (issue #114, prima fetta).

Il testo di riferimento (cosa e' portato e cosa no, parita' con il codice di Quake III, difetti del C, differenze volute, riuso) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 17 per il RoQ (nome a punti `DelphiDoom.Cinematic.*`).
- Interfacce dichiarate: `IRoqSource`, `IRoqAudioSink`, `IRoqDecoder`, `IRoqPlayer`.
- Punto di creazione delle classi: `DelphiDoom.Cinematic.Factory` (`TCinematicFactory`).
- Licenza: unit derivate da `cl_cin.c` di Quake III Arena (GPL v2 o successiva) e da `Cinematic.cpp` di Doom 3 (GPL v3 con i termini aggiuntivi della licenza del sorgente di Doom 3); vedi l'intestazione di ogni unit.

## Uso

```pascal
Decoder := TCinematicFactory.CreateDecoder(
  TCinematicFactory.CreateMemorySource(Bytes), nil);   // il secondo parametro e' l'audio: IRoqAudioSink o nil
while Decoder.NextFrame do
  Use(Decoder.Width, Decoder.Height, Decoder.Frame);   // TImagingPixels $AABBGGRR

Player := TCinematicFactory.CreatePlayer(Decoder, True);
Image := Player.ImageForTime(MillisecondiDelChiamante);
```

## Parita'

`Tools\Verifica\114` (gcc di w64devkit, righe di `cl_cin.c` incluse alla lettera) e `Tests\Data\Cinematic` (tre file sintetici, le tabelle YUV e DPCM, le impronte del vero `idlogo.RoQ` di OpenArena, letto dal pk3 dove sta). Tutte le impronte sono identiche.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Cinematic` (181 test, Win32 e Win64). Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Fotogrammi JPEG e modi di Quake III (issue #114, seconda fetta)

- **Chunk `ROQ_QUAD_JPEG` di Doom 3**: `TCinematicFactory.CreateDecoder(sorgente, nil, ROQ_ALPHA_OPAQUE, TRoqJpegFactory.CreateDecoder)`; il JPEG lo decodifica `IRoqJpegDecoder` (`DelphiDoom.Cinematic.Jpeg.Intf`), che `TRoqJpegDecoder` (`Jpeg.Decoder`) realizza sopra `Libs\Jpeg`. Senza decoder JPEG il chunk si salta come prima. Solo il primo fotogramma, righe capovolte, come `JPEGBlit`.
- **Codebook di Quake III nei modi a 32 bit, 16 bit (RGB 5-6-5), grigi, `half` e `smootheddouble`**: `TCinematicFactory.CreateModeCodebook(modo, alpha, tabellaGrigi)` (`TRoqModeCodebook`); `TRoqYuvConverter.ToRgb565` e' `yuv_to_rgb`. Solo il codebook: i pittori dei fotogrammi di Quake III leggono sempre pixel a 32 bit e non sono portati negli altri modi.
- Parita' sul vero `decodeCodeBook` (`Tools\Verifica\114\modeextract.c`, `Tests\Data\Cinematic\modes.golden.txt`): 10 modi x 3 chunk, CRC dei tre buffer (32, 128 e 512 KB) e CRC di `yuv_to_rgb` su 16.777.216 terne: tutto identico.

## Filmati FLIC (issue #199)

Il decoder dei FLI/FLC (`DelphiDoom.Cinematic.Flic.*`) da' i fotogrammi dei filmati di Warcraft: Orcs & Humans (`CAVE1.WAR`, `TITLE.WAR`, ... sono FLC puri). `TFlicFactory.CreateDecoder(bytes)` + `TFlicFactory.CreatePlayer(decoder, ciclo)`, poi `ImageForTime(ms)` con il tempo del chiamante. Parita' sul `FlcPlayer` di OpenXcom (`Tools\Verifica\199`): identici i CRC su 4 file di prova e sui 13 filmati veri. Dettagli, difetti ereditati e cosa resta nel [CLAUDE.md](CLAUDE.md).
## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Usa `Libs\Imaging` (`TImagingPixels`) e `Libs\IdLib\Math` (`TIdMath.Sar`); nei test `Libs\MathCore` (`TCrc32`).

## Scena di filmato saltabile e presentazione (issue #199, seconda fetta)

`TFlicSceneFactory.TryCreateScene(nome, sorgente, opzioni, voce)` da' un `IFlicScene` sopra il player FLIC: `Update(ms, salto)` torna lo stato (`fssPlaying`, `fssEnded`, `fssSkipped`), l'immagine e se il fotogramma e' cambiato; un salto la ferma, la fine la termina (e dice alla voce `SceneFinished`, una volta sola). `TFlicFolderSource` legge le animazioni per nome da una cartella (`CAVE1` + `.WAR`); un'animazione che manca da' `nil` (si salta). `TFlicPresenter.Present` mette l'immagine su uno schermo a 32 bit (adatta con le bande, multiplo intero o stira, pixel piu' vicino). Nessun orologio, nessuna tastiera, nessuna finestra. Il catalogo delle animazioni di Warcraft, le voci e la prova sui file veri sono in `Libs\War` (`TWarCinematicDirector`). Dettagli e cosa resta nel [CLAUDE.md](CLAUDE.md).
