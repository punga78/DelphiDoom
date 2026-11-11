# Analisi dei duplicati tra i giochi (2026-11-11)

Fatta sul codice di `master` (`899f2e9a`) con ricerche mirate e `diff` dei file candidati; non è una rilettura riga per riga di ogni unit.
Conclusione: di duplicato vero c'è soprattutto l'infrastruttura intorno ai giochi (finestra, file, PNG, orologio, test), non la logica di gioco.

## Duplicati veri, da unificare

| Cosa | Dove è duplicato | Cosa riusare |
|---|---|---|
| Encoder PNG da immagine a 8 bit + palette | `Libs\Keen\DelphiDoom.Keen.PngEncoder`, `Libs\Greed\DelphiDoom.Greed.PngEncoder`, `Libs\XcomFormats\DelphiDoom.Xcom.PngEncoder` (84-92 righe l'uno, quasi uguali tolti i nomi), più `Libs\Screenshot` | Un solo encoder "indicizzato -> PNG" in `Libs\Imaging` o `Libs\Png` |
| Immagine a 8 bit (larghezza, altezza, pixel) | `TKeenChunkyImage`, `TGreedImage`, `TXcomImage`, `TSpeedBitmap`, `TRadixBitmap`, `TFontImage` | Un record comune; è la causa dei tre encoder e dei tre esportatori |
| File da una o più cartelle | `Keen.FolderFiles`, `Greed.FolderFiles`, `IXcomDataFiles`/`IXcomFileSystem`, `Tools.Win.FileSystem`, `IIdeFileSystem`, `IIwadFileSystem` | `IFileStore` di `Libs\Platform`, a cui manca la ricerca su più cartelle senza maiuscole |
| Finestra Windows che mostra un fotogramma | `Greed\DelphiDoom.Greed.Win.Window` (202 righe), `OpenXcom\DelphiDoom.Xcom.Win.VideoDevice` (336), il pannello di `DD_Tools` | Libreria comune (finestra GDI, tasti e mouse come eventi, cattura PNG); `IGreedFramePresenter` e `IXcomVideoDevice` sono lo stesso contratto |
| Uscita audio PCM (`waveOut`) | `OpenXcom\DelphiDoom.Xcom.Win.PcmOutput`, `Tracker.WaveOutDevice` in `Libs\Mikmod`, il player MP3 in `Base` | Un solo dispositivo PCM in `Libs\Audio` |
| Orologio | `IKeenClock`, `IXcomClock`, `IGreedRenderClock`, `IIdeClock`, due `ManualClock` gemelli, `Xcom.Win.Clock` | `IClock` di `Libs\Clock`, con un solo orologio manuale per i test |
| Log | `IXcomLog`, `IIdeLog`, `IIdLibLog` | `ILog` di `Libs\Logging` |
| Impostazioni su file | `Greed.SettingsStore`, `ISettingsStore` di `ToolsCore`, `Libs\Configuration` | Greed può usare `ToolsCore`; le opzioni di OpenXcom sono YAML e restano a parte |
| Riga di comando degli eseguibili | `Keen32`, `Greed32`, `Speed32`, `Xcom32`: ognuno scorre `ParamStr` a mano | `ICommandLine` di `Libs\CommandLine` |
| Supporto dei test | FNV-1a riscritta in 34 unit di test, `FindUp` in 7, una decina di lettori di golden (`*.Golden.pas`) | Una unit comune di test: impronta, ricerca dei dati, confronto riga per riga |
| Mixer audio | `XcomAudio.Mixer` (543 righe), `Tracker.Mixer`, i canali di `TSfxPlayer`, i 64 canali di Greed | Solo in parte: il mixer di XcomAudio può servire anche Greed e Keen |

## Già riusato bene

- Decoder audio: XcomAudio usa `Libs\Sound`, `Mp3`, `Mikmod`, `Midi`, `Opl`.
- Matematica: Greed usa `TFixedMath` di `MathCore`.
- WAD e patch: Speed e Radix usano `Libs\GameData` e `Libs\Wad`.
- PNG e palette: tutti passano da `TPngClient` e `IPaletteConverter`; è duplicato solo l'involucro.

## Da non unificare

- Generatori casuali (`IKeenRandom`, `IGreedRandom`, `IXcomRandom`, `IGameRandom`): ogni gioco ha la sua sequenza e la parità con l'originale dipende da quella.
- Palette (EGA di Keen, VGA a 6 bit di Greed e X-COM): poche righe ciascuna, formati diversi.
- Ricampionatori: quello di `Imaging` è per immagini, quello di `XcomAudio` per audio.
- Formati dei dati e logica di gioco.

## Proposta, in ordine di valore

1. Libreria di piattaforma per i giochi (`Libs\GameHost`): finestra, eventi, orologio, uscita PCM, file su più cartelle, riga di comando; per Keen, Greed, OpenXcom, Speed e poi Radix.
2. Immagine a 8 bit comune ed encoder PNG unico.
3. Unit comune per i test.

Rischio basso: sono parti senza parità con gli originali; bastano build, suite e un avvio per gioco.
