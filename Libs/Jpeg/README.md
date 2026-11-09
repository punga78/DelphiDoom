# Libs\Jpeg

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Decoder JPEG a classi, port della parte di decompressione di libjpeg 6b (IJG) al posto di `JPEGLIB\jpg_*.pas` (una traslitterazione letterale con globali, puntatori a funzione, un memory manager proprio e l'IDCT in `asm`), che è stata cancellata. Il motore lo usa per le immagini JPEG delle texture (`TEXLIB\t_jpeg.pas`, tramite `TJpegProvider` e `TJpegBitmapBuilder`); la DLL `DDJpeg` lo espone con `IJpeg`.

## Struttura

| Unit | Ruolo |
|---|---|
| `Intf`, `Client`, `Loader`, `Provider`, `Engine` | contratto `IJpeg` (buffer e interi, `stdcall`), il client che il motore usa, il caricamento della DLL, il provider e `TJpegEngine`, che chiama `TJpegDecoder` |
| `Decoder` | `TJpegDecoder.ReadInfo/Decode`: crea un `TJpegDecompressor` per chiamata e traduce le eccezioni in codici `DDJPEG_*` |
| `Decompressor` | l'ordine delle operazioni (intestazioni, scelte che possono fallire, scansioni, IDCT, righe) |
| `Types`, `Frame` | costanti, errori (`EJpegDecodeException`, `TJpegDecodeError`), stato delle intestazioni e geometria in blocchi e MCU |
| `ByteSource`, `MarkerReader` | il flusso in memoria e i marcatori (SOI, SOF0/1/2, DHT, DQT, DRI, SOS, APP0 JFIF, APP14 Adobe, restart) |
| `HuffmanTable`, `BitReader` | tabelle derivate con la ricerca a 8 bit e lettura dei bit |
| `EntropyDecoder`, `EntropyDecoderBase`, `SequentialDecoder`, `ProgressiveDecoder` | `IJpegEntropyDecoder` e le due implementazioni |
| `InverseDct`, `SlowInverseDct` | `IJpegInverseDct` e l'IDCT intera accurata di `jidctint.c` |
| `McuTarget`, `SampleTarget`, `CoefficientTarget`, `ComponentBuffers`, `BlockSmoother` | dove vanno i blocchi di un MCU (IDCT subito, o coefficienti dell'immagine intera), i piani e la levigatura di un progressive interrotto |
| `RowUpsampler`, `ReplicatingUpsampler`, `FancyUpsamplerH2V1`, `FancyUpsamplerH2V2`, `ColorConverter`, `GrayConverter`, `YccConverter`, `RgbConverter`, `ColorConverterFactory`, `RowRenderer` | l'allargamento dei componenti e la conversione dei colori, riga per riga |
| `Encoder` | scrittore baseline (non è di libjpeg, che qui non ha il compressore); il motore non lo usa |

## Cosa è portato e cosa no

Portato (quello che il motore usa: immagine intera, 8 bit, grigio o RGB): JFIF/Adobe, sequenziale (SOF0/SOF1) e progressive (SOF2) in Huffman, immagini in più scansioni, restart con risincronizzazione, qualsiasi campionamento intero (anche 3x, 4x), upsampling "fancy" (triangolo) h2v1 e h2v2, levigatura dei blocchi, IDCT `islow`, YCbCr/RGB/grigio. Le righe sopra la prima e sotto l'ultima di un componente sono la prima e l'ultima (i context rows di libjpeg).

**Non portato** (nessun chiamante): compressione, codifica aritmetica (SOF9/SOF10 danno `DDJPEG_ERR_UNSUPPORTED`), 12 bit, scalatura con l'IDCT (1/2, 1/4, 1/8), IDCT `ifast` e float, upsampling "merged", quantizzazione dei colori a 1 e 2 passate, `buffered_image`, dati grezzi, marcatori salvati, i messaggi e gli avvisi di libjpeg (l'unico che conta è `JWRN_HIT_MARKER` con la sorgente esaurita: il flusso è troncato, `DDJPEG_ERR_TRUNCATED`).

## Struttura diversa dal C

libjpeg decodifica a strisce di righe e tiene buffer di contesto con puntatori a righe; qui i piani dei componenti contengono l'immagine intera e le righe di pixel si fanno alla fine. Per un'immagine in una scansione ogni MCU passa dall'IDCT subito (senza coefficienti); per più scansioni o progressive si tengono i coefficienti (`Integer`, come il vecchio) di tutta l'immagine. Il risultato, gli errori e l'ordine in cui si scoprono sono gli stessi del vecchio decoder.

## Difetti del vecchio conservati

- I JPEG con componenti R,G,B (Adobe con trasformazione 0, o identificatori `R`,`G`,`B`) escono con i byte nell'ordine del flusso (R,G,B); quelli YCbCr escono B,G,R come i pixel di una bitmap di Windows.
- I coefficienti sono `Integer` e non a 16 bit: nei flussi fuori norma non si perdono bit.

## Differenze volute (difetti del vecchio non copiati, ognuno con un test in `DelphiDoom.Tests.Jpeg.Regression`)

1. Un marcatore APP0 o APP14 con lunghezza di 0, 1 o 2 mandava il vecchio decoder in un ciclo di 4 miliardi di giri su un `uint` (`for i := 0 to numtoread - 1` con `numtoread = 0`) che sovrascriveva la memoria. Ora il segmento si salta.
2. Nel ciclo di `start_pass` di `jpg_ddctmgr` un `continue` saltava `inc(compptr)`: se un componente non aveva alcuna scansione, quelli che lo seguivano restavano senza tabella di dequantizzazione e uscivano grigi. Ora hanno la loro tabella e il componente senza scansione è grigio.
3. In un'immagine con una sola scansione che non nomina un componente (la scansione può nominarne uno due volte) il vecchio leggeva memoria che nessuno aveva scritto. Ora il piano di quel componente è 128, come i blocchi a zero di un'immagine in più scansioni.

## Verifica

`Tests\DelphiDoom.Tests.Jpeg` (vedi `Tests\Data\README.md`, sezione `Jpeg`): i flussi di `TJpegCases` danno la stessa impronta (codici, dimensioni e pixel) che dava il vecchio decoder; più i test di ogni classe con flussi scritti a mano e con `TJpegSynthesizer`. Prima di cancellare `JPEGLIB` il vecchio e il nuovo decoder sono stati confrontati nello stesso eseguibile su circa un milione di flussi alterati a caso e su 160000 specifiche casuali (zero differenze, tranne i tre difetti qui sopra, che nel confronto erano corretti anche nel vecchio).
