# Libs\Cinematic

Decoder dei video RoQ (id Tech 3 e 4) a classi: dai byte del file i fotogrammi a 32 bit e l'audio DPCM a 16 bit, con il tempo dato dall'esterno (issue #114, prima fetta).

Il testo di riferimento (cosa e' portato e cosa no, parita' con il codice di Quake III, difetti del C, differenze volute, riuso) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 13 (nome a punti `DelphiDoom.Cinematic.*`).
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

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Cinematic` (90 test, Win32 e Win64). Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Filmati FLIC (issue #199)

Il decoder dei FLI/FLC (`DelphiDoom.Cinematic.Flic.*`) da' i fotogrammi dei filmati di Warcraft: Orcs & Humans (`CAVE1.WAR`, `TITLE.WAR`, ... sono FLC puri). `TFlicFactory.CreateDecoder(bytes)` + `TFlicFactory.CreatePlayer(decoder, ciclo)`, poi `ImageForTime(ms)` con il tempo del chiamante. Parita' sul `FlcPlayer` di OpenXcom (`Tools\Verifica\199`): identici i CRC su 4 file di prova e sui 13 filmati veri. Dettagli, difetti ereditati e cosa resta nel [CLAUDE.md](CLAUDE.md).
## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Usa `Libs\Imaging` (`TImagingPixels`) e `Libs\IdLib\Math` (`TIdMath.Sar`); nei test `Libs\MathCore` (`TCrc32`).
