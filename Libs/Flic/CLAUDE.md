# Libs\Flic — note per Claude

`Libs\Flic` (issue #229, fetta 1 del framework, indice #227) e' il **decoder dei fotogrammi FLI/FLC** in uno strato "Formati": nessuna dipendenza da `Xcom*`, da `Greed`, da `Base\` ne' da altre librerie (solo la RTL). Era `TXcomFlcDecoder` di `Libs\XcomFormats` (port del decoder di `FlcPlayer` di OpenXcom, GPL v3 o successiva, vedi `Libs\XcomFormats\README.md` per la licenza): **spostato alla lettera**, solo i nomi cambiano. Nome scelto: `Flic` (come i `Cinematic.Flic.*` che lo usano) e non una libreria `Formats` generica: un lettore di una sola famiglia di file non giustifica un contenitore di formati diversi; se un giorno arrivano altri formati di immagine/animazione a 8 bit si decide allora.

| Unit | Contenuto |
|---|---|
| `DelphiDoom.Flic.Types` | `EFlicFormatException` (file non FLI/FLC, o un pezzo che legge oltre il file o scrive fuori dall'immagine), `TFlicColor` (`packed`, 4 byte, come `TXcomColor`) |
| `DelphiDoom.Flic.FrameDecoder` | `TFlicFrameDecoder`: intestazione, `FindFrame`, `FrameDelay`, `DecodeFrame(buffer, passo, offset, saltaUltimo)`, `NextAudioChunk`, `ToSigned16`, `OnPalette`, `Color`; chunk `COLOR_256`, `COLOR_64`, `FLI_BRUN`, `FLI_LC`, `FLI_SS2`, `FLI_COPY`, `BLACK`; i prefissi `$F100` e i pezzi audio `$AAAA` (TFTD) si saltano |

Un'interfaccia non c'e': c'e' un solo decoder e i due consumatori (`TXcomFlcDecoder`, `TFlicDecoder` di `Libs\Cinematic`) lo possiedono; le dipendenze sono i byte del file e il buffer del chiamante. **Chi lo usa**: `Libs\XcomFormats` (`TXcomFlcDecoder` e' ora un **adattatore sottile** con la stessa API: palette come `TXcomColor`, errori come `EXcomFlcException`; lo usano `XcomMenu.VideoState` e i test di `XcomEngine`) e `Libs\Cinematic` (`Flic.Decoder` lo usa direttamente, senza piu' dipendere da `XcomFormats`).

**Difetti del C++ conservati** (identici byte per byte al decoder di prima): il salto di un pacchetto `COLOR_256` somma il conteggio del pacchetto prima (piu' uno); `BLACK` azzera "altezza" pixel per riga e non "larghezza"; l'ultimo byte di una riga `FLI_SS2` va a `riga + passo - 1` del buffer. Non conservato (gia' prima): `readS16` con il byte basso con segno. Cio' che il C++ lascia indefinito (pezzo oltre il file, scrittura fuori dal buffer) e' `EFlicFormatException`.

## Confronto con `TGreedFliDecoder` (`Libs\Greed`, 353 righe)

Letti riga per riga. **Decisione: `TGreedFliDecoder` resta com'e'** (non e' unificabile con un'opzione: servirebbero cinque interruttori e il risultato sarebbe un decoder "unico quasi", e Greed ha la parita' sui pixel con 39 filmati veri del CD-ROM, 28588 schermi, da non rimettere in gioco). Le differenze sono **osservabili** (stessi byte in ingresso, byte diversi in uscita), pinzate da `TTestGreedFliVsFlic` (`Tests\Source\DelphiDoom.Tests.Greed.FliVsFlic.pas`, progetto `DelphiDoom.Tests.Greed`).

| Aspetto | `TFlicFrameDecoder` (ex Xcom) | `TGreedFliDecoder` | Osservabile? |
|---|---|---|---|
| Intestazione | tipo `$AF11`/`$AF12` controllato, larghezza e altezza dal file | tipo e magic non controllati; schermo fisso 320x200 (64000 byte, passo 320) | si': un file di altra dimensione |
| Cammino dei fotogrammi | `FindFrame`: salta `$F100` e `$AAAA`, usa la dimensione del fotogramma per trovare il successivo, finisce quando cio' che segue non e' un fotogramma | i chunk si leggono uno dopo l'altro, la dimensione del fotogramma non serve; magic `$F1FA` obbligatorio (errore), numero dei fotogrammi dall'intestazione, dimensione 0 = fotogramma vuoto | si': un file con prefisso o audio da' errore in Greed |
| `COLOR_256` (4) | si'; il salto del secondo pacchetto somma il conteggio prima (difetto) | **ignorato** | si' (test) |
| `COLOR_64` (11) | si'; salto non cumulativo, valori `shl 2` con giro a 8 bit, conteggio 0 = 256, oltre la palette non si scrive | uguale (`Byte(x*4)`, stessi limiti), piu' `PaletteChanged` e `ApproxZero` ricalcolato | **no** (stessi colori; test) |
| `DELTA_FLC` (7, SS2) | si' (ultimo pixel, salto di righe, coppie) | **ignorato** | si' |
| `DELTA_FLI` (12, LC) | si'; una riga fuori dall'immagine e' errore | stessa decodifica dei pacchetti; una riga fuori dallo schermo non si scrive e basta | **no** sui dati validi (test); si' sui malformati |
| `BYTE_RUN` (15) | per riga: salta il conteggio dei pacchetti e legge finche' `pixel = larghezza` | usa il conteggio dei pacchetti; la destinazione continua da una riga alla successiva (non riparte dalla colonna 0: difetto conservato) | **no** sui dati validi con larghezza 320 (test); si' se il conteggio non e' giusto |
| `FLI_COPY` (16) | copia `larghezza x altezza` con il passo del chiamante | copia i primi 64000 byte del buffer del chunk (anche quelli che il chunk non ha: restano i byte del chunk prima) | si' se l'immagine non e' 320x200 o il chunk e' corto |
| `BLACK` (13) | azzera "altezza" pixel per riga (difetto del C++) | riempie **tutto** lo schermo con `ApproxZero` | **si'** sempre (test) |
| Pixel 0 | resta 0 | dopo ogni chunk d'immagine ogni 0 diventa `ApproxZero` (il colore piu' simile al nero, perche' lo 0 e' il trasparente dello schermo di Greed; `TGreedPaletteFader`) | **si'** (test) |
| Palette | `FColors` (4 byte per colore, alpha 255 sui colori letti) e callback `OnPalette` | 768 byte ereditati dal filmato prima (`flipal`), modificati sul posto | stessi byte per i colori scritti |
| Ritardo | `FrameDelay`: millisecondi (FLI: proprio o `velocita' * 1000/70`; FLC: velocita'; TFTD: durata dell'audio) | `Speed` in tic da 1/70 s, usato dal player di Greed | si' (altra unita') |
| Audio | `NextAudioChunk` e `ToSigned16` (TFTD) | nessuno | si' |
| Errori | `EFlicFormatException` per ogni lettura oltre il file o scrittura fuori dal buffer | `EGreedDataException` solo per file troncato; scritture fuori dallo schermo scartate, letture oltre il chunk danno zero o i byte residui | si' |
| Costo | un `ByteAt` con controllo per byte | un buffer di chunk copiato e una scansione di 64000 byte per chunk d'immagine (`Translate`) | non osservabile nei byte |

## Fuori dalla fetta

- **`TXcomLbmReader`** (283 righe, IFF PBM/ILBM) **resta in `Libs\XcomFormats`**: segue le stranezze di **SDL_image 1.2.12** (larghezza arrotondata a 16, piano di maschera contato come un bit, CMAP ripetuta, PBM completato di nero) con parita' su 600 file e 53 `.LBM` veri; metterlo in una libreria "generica" senza quel contesto lo farebbe sembrare un lettore IFF generale e non lo e'. Un posto comune lo avra' se nasce un secondo consumatore che ne vuole il comportamento. **Duplicazione da elencare**: `Keen.Shape` (`Libs\Keen`) ha un lettore ILBM proprio (la parte ILBM di `LoadLIBShape`: piani, `ByteRun1`, intestazione `BitMapHeader`, numeri big endian per il gioco): non unificato.
- Il **lettore di byte comune** e' la fetta 2 della #229 e non e' fatto.

## Test

`Tests\DelphiDoom.Tests.Flic` (9): parita' con una **copia fedele del vecchio decoder** (`DelphiDoom.Tests.Flic.XcomReference`: il commit `b6fedafb` con i soli nomi cambiati) su file costruiti in memoria (FLC con `COLOR_256` a due pacchetti, ultimo pixel `$86` (byte basso >= `$80`), `BLACK`, `COPY`, prefisso, miniatura, palette oltre il 255; FLI con ritardi propri; audio TFTD), su **ogni troncamento** dei tre file e su **1200 copie mutate** (seme fisso, 3 file x 400, i 16 byte dell'intestazione di ogni fotogramma non si toccano perche' un prefisso di dimensione 0 farebbe girare per sempre entrambi i decoder): per ogni fotogramma si confrontano impronta del buffer, impronta della palette, ritardi (con e senza audio interno), `Finished`, `FrameCount`, i pezzi audio e il tipo di eccezione. Riuso: `TFlcBuilder` di `Tests\Source\DelphiDoom.Tests.XcomEngine.FlcBuilder.pas` (nessuna dipendenza). I test del decoder di `XcomEngine` (21 + il confronto con i 891 fotogrammi veri di UFO, saltato senza i dati) e di `Cinematic` (150, con i 634 fotogrammi veri di Warcraft se i dati ci sono) girano sull'adattatore e sul decoder comune senza golden rigenerati.
