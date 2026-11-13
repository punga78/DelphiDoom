# Libs\Cinematic — note per Claude

`Libs\Cinematic` (issue #114, prima fetta; indici #94 id Tech 4 e #115 id Tech 3) e' il **decoder dei video RoQ** a classi: dai byte del file i fotogrammi a 32 bit (`TImagingPixels`, `$AABBGGRR`, il rosso e' il byte basso come in `Libs\Imaging`) e l'audio DPCM a 16 bit, con il tempo dato dall'esterno. **Senza chiamanti nel motore** (percorso freddo, nessun gioco cambia). Nessuna dipendenza dal renderer, da un orologio o da un dispositivo audio.

**Licenza.** Le unit sono derivate da `code\client\cl_cin.c` di Quake III Arena (GPL v2 o successiva, Id Software, Inc.) e da `renderer\Cinematic.cpp` di Doom 3 (GPL v3 con i termini aggiuntivi della licenza del sorgente di Doom 3, id Software LLC): intestazione con attribuzione e "Based on the Doom 3 GPL Source Code (id Software)" in ogni unit che ne deriva; `Types`, `Intf`, le sorgenti e `AudioCollector` sono scritte dalla sola descrizione del formato (licenza del repository). Nessun sorgente C nel repository salvo l'harness di verifica (`Tools\Verifica\114`, che include le righe dell'originale leggendole da `Reference\` a ogni compilazione).

## Classi (nome C -> classe)

| C | Pascal |
|---|---|
| file e `Sys_StreamedRead` | `IRoqSource` (`TRoqMemorySource`, `TRoqStreamSource`) |
| `ROQ_GenYUVTables`, `yuv_to_rgb24` | `TRoqYuvConverter` (tabelle dell'oggetto; alpha $FF come Quake III, 0 come Doom 3) |
| `RllSetupTable`, `RllDecodeMonoToMono/MonoToStereo/StereoToStereo/StereoToMono` | `TRoqSoundDecoder` |
| `decodeCodeBook` (percorso a 32 bit) | `TRoqCodebook` (`vq2`, `vq4`, `vq8`) |
| `recurseQuad`, `setupQuad` (`qStatus`) | `TRoqQuadMap` |
| `blitVQQuad32fs`, `blit8/4/2_32`, `move8/4_32`, `RoQPrepMcomp`, il doppio buffer `linbuf` | `TRoqFramePainter` |
| `RoQ_init`, `RoQReset`, `readQuadInfo`, i chunk di `RoQInterrupt` | `TRoqDecoder` (`IRoqDecoder`: `ReadChunk`, `NextFrame`, `Reset`) |
| `ImageForTime` (Doom 3) | `TRoqPlayer` (`IRoqPlayer`: `ImageForTime(ms)`, `ResetTime`) |
| `S_RawSamples` (la destinazione dell'audio) | `IRoqAudioSink` (`TRoqAudioCollector` tiene i blocchi) |
| — | `TCinematicFactory` (composition root) |

Eccezioni (`DelphiDoom.Cinematic.Types`): `ERoqTruncatedException` (intestazione, chunk, codebook, audio o dati del fotogramma troncati), `ERoqMissingCodebookException` (un fotogramma usa un vettore senza codebook), `ERoqMissingInfoException` (un fotogramma prima del chunk `ROQ_QUAD_INFO`), `ERoqInvalidDataException` (non e' un RoQ, chunk oltre 65536 byte, dimensioni non multiple di 16, vettore di movimento fuori dai buffer); base `ECinematicException`.

## Cosa fa il decoder

File: intestazione di 8 byte (`$1084`, `$FFFFFFFF`, fotogrammi al secondo; 0 = 30), poi chunk di 8 byte (id, dimensione a 32 bit, flag) piu' dati. `ROQ_QUAD_INFO` (solo il primo): larghezza e altezza; `ROQ_CODEBOOK`: i vettori 2x2 (6 byte: 4 luminanze, Cr, Cb) e le coppie che fanno i 4x4 e gli 8x8 (flag: byte alto = numero dei 2x2, 0 = 256; byte basso = numero dei 4x4; flag 0 = 256 e 256); `ROQ_QUAD_VQ`: per ogni macroblocco 16x16 e ogni blocco 8x8 un codice di 2 bit (8 codici per parola da 16 bit: 00 salta, 01 movimento, 10 vettore 8x8, 11 divide in quattro 4x4 con gli stessi codici piu' i vettori 2x2) e i suoi byte; i flag del chunk sono lo scostamento (due `char`) dei vettori di movimento. Un fotogramma si dipinge in una meta' di un buffer doppio e il movimento legge l'altra (quella del fotogramma prima); il primo fotogramma si copia nella seconda meta'. `ROQ_SOUND_MONO` e `ROQ_SOUND_STEREO`: DPCM (ogni byte e' l'indice di un quadrato con segno sommato al campione precedente; 16 bit con giro); il mono arriva al sink come due canali uguali (come in Quake III), a 22050 Hz.

`TRoqPlayer`: il primo tempo e' l'inizio; il fotogramma mostrato e' `(tempo - inizio) * fps div 1000`; un tempo che torna indietro riavvolge; a fine file un video in ciclo riparte (nuovo inizio = quel tempo), altrimenti l'ultimo fotogramma resta con `rpsEnded`. L'audio va al sink mentre i chunk si decodificano, quindi con i riavvolgimenti si ripete: chi vuole l'audio in sincronia usa `IRoqDecoder` direttamente.

## Parita' (Tools\Verifica\114, Tests\Data\Cinematic)

Non c'e' compilatore C nel PATH: `Tools\Verifica\114\build.sh` usa il gcc di `Reference\_dati\_strumenti\w64devkit` (**i686**: l'originale tiene differenze di puntatori in interi a 32 bit). `roq_original.inc` si costruisce con **intervalli di righe di `cl_cin.c`** (non riscritto: tabelle YUV, `Rll*`, `blit*`, `move*`, `decodeCodeBook`, `recurseQuad`, `setupQuad`, `readQuadInfo`, `RoQPrepMcomp`, `initRoQ`, `RoQReset`, `RoQInterrupt`, `RoQ_init`); `stubs.h` rimpiazza file system, suono, orologio e `glConfig`; `roqextract.c` e' il solo codice nuovo (pilota di `RoQInterrupt` con CRC-32 per fotogramma e blocco audio). `roqgen.c` fa i file di prova (casuali, semi fissi, nessun materiale commerciale: `basic` 32x32 con mono, secondo `ROQ_QUAD_INFO`, codebook parziale e movimenti con scostamento negativo; `wide` 64x16, il caso `xsize == ysize*4`; `stereo` 48x32, flag 0 e flag con byte alto 0). Risultato: **tutte le impronte identiche** su 6 + 4 + 3 fotogrammi e 2 + 0 + 2 blocchi audio, sulle 16.777.216 terne YUV (impronta unica `yuv crc`), sui quattro `RllDecode*` con quattro flag e sul **vero `idlogo.RoQ` di OpenArena** (512x512, 124 fotogrammi, 123 blocchi audio stereo, letto dal pk3 dove sta e saltato se manca). Tolleranze: nessuna (interi; le tabelle YUV usano `Single` con ogni operazione arrotondata, uguali a 32 e a 64 bit). Ricostruzione: `Tools\Verifica\114\LEGGIMI.md`.

## Difetti del C trovati

- **Fotogrammi fantasma a fine file** (Quake III): `RoQPlayed` parte da 24 e la lettura a fine file non aggiorna il buffer, quindi l'ultimo chunk di `idlogo.RoQ` viene decodificato ancora 11 volte (135 "fotogrammi" invece di 124, con l'impronta dell'ultimo). **Non conservato**: il decoder si ferma alla fine dei dati. Il test accetta i ripetuti solo se uguali all'ultimo.
- **Audio mono dimezzato** (Quake III): `RllDecodeMonoToStereo` produce due copie di ogni campione ma `S_RawSamples` e' chiamata con `samples = size` e un solo canale, quindi il mixer ne legge la meta' (mono a meta' velocita'). **Non conservato**: il sink riceve il blocco intero a due canali.
- **Differenze di puntatori in `unsigned int`** (`mcomp`, `t[]`): giusto solo a 32 bit; qui `Integer` con segno.
- **Letture fuori dai buffer**: un vettore di movimento che punta fuori dal doppio buffer, dati del fotogramma o del codebook piu' corti del necessario, dimensioni non multiple di 16 (il C legge memoria a caso o scrive fuori), dimensione dispari di un blocco stereo (il C scrive uno `short` oltre): eccezioni dedicate (o l'ultimo byte scartato).
- `ROQ_QUAD_INFO` ripetuto azzera il contatore `numQuads` (`if (numQuads != 1) numQuads = 0`) e con lui il numero di fotogramma: **conservato** per la scelta del buffer e per la copia del "primo" fotogramma (parita' sui pixel), non per il tempo (il player usa il numero dei fotogrammi decodificati).

## Differenze volute dal riferimento

Un chunk di id sconosciuto si salta (il C ferma il video); `ROQ_FILE` a meta' file ferma (come il C); un chunk di piu' di 65536 byte e' un errore (il C ferma); `ROQ_PACKET` e' un contenitore (si legge la sola intestazione e i chunk che contiene seguono: il C legge i dati del pacchetto in un blocco e ne decodifica uno solo; **nessun file di prova lo usa, non verificato**); il fotogramma mostrato dal player e' quello col numero `tempo * fps` (Doom 3 resta indietro di uno); i fps sono la parola a 16 bit dell'intestazione (Quake III; Doom 3 legge un solo byte e trasforma 32 in 31,25).

## Non portato (e perche')

- `ROQ_QUAD_JPEG` (Doom 3 `JPEGBlit`, Quake III lo ignora): i file RoQ veri di Quake III non lo usano; si potra' fare con `Libs\Jpeg`. Il chunk si salta.
- I modi di `decodeCodeBook` per 16 bit (`samplesPerPixel` 2, RGB565, `yuv_to_rgb`), per grigi (1), `half` (un quarto dello schermo) e `smootheddouble`: opzioni di rendering di Quake III che nessun percorso attivo imposta (`initRoQ` fissa 4 e `half`/`smootheddouble` sono falsi), e Doom 3 usa solo i 32 bit. Le varianti `MACOS_X`.
- Il collegamento al motore: i `cinData_t`/`cinTable`, `CIN_PlayCinematic`, i comandi `cinematic`, la trama su shader, il mixer (`S_RawSamples`), l'`idSndWindow`.

## Riuso

`TImagingPixels` di `Libs\Imaging` (immagine a 32 bit, nessun tipo nuovo), `TIdMath.Sar` di `Libs\IdLib\Math` (scorrimento aritmetico), `TCrc32` di `Libs\MathCore` (nei test), `System.Zip` (i test leggono il pk3 di OpenArena). `TArray<SmallInt>` e' il PCM a 16 bit come in `Libs\Mikmod`, `Libs\Opl` e `Libs\XcomAudio`. Non riusati: `IClock` (da' secondi dal primo uso e il player vuole i millisecondi del chiamante, come `ImageForTime` di Doom 3) e `TTextureByteReader` (otto byte di intestazione letti a mano, senza dipendere da `Libs\Texture`). Duplicazioni che restano nel repository (da unificare): lo scorrimento aritmetico a destra e' in `Libs\Yaml\DelphiDoom.Yaml.EmitterUtils.pas` (`Sar`), `Libs\Jpeg\DelphiDoom.Jpeg.YccConverter.pas` e `DelphiDoom.Jpeg.SlowInverseDct.pas` (`ArithmeticShiftRight`), `Libs\Sound\DelphiDoom.Sound.Codec.G72x.pas` (`Sar`) e `TIdMath.Sar`; i pixel a 32 bit come `TArray<Cardinal>` hanno quattro nomi (`TImagingPixels` in `Libs\Imaging`, `TTexturePixels` in `Libs\Texture`, `TGameHostTrueColorPixels` in `Libs\GameHost`, `TXcomTrueColorPixels` in `Libs\XcomEngine`; `TVoxelEditorImage` in `Libs\VoxelEditor` e' lo stesso tipo).

Test in `Tests\DelphiDoom.Tests.Cinematic` (90; copertura 99%: 553 righe su 557). Win32 e Win64 passano.
