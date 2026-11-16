# Analisi dei duplicati tra i giochi (2026-11-11)

Fatta sul codice di `master` (`899f2e9a`) con ricerche mirate e `diff` dei file candidati; non è una rilettura riga per riga di ogni unit.
Conclusione: di duplicato vero c'è soprattutto l'infrastruttura intorno ai giochi (finestra, file, PNG, orologio, test), non la logica di gioco.

## Duplicati veri, da unificare

| Cosa | Dove è duplicato | Cosa riusare |
|---|---|---|
| Encoder PNG da immagine a 8 bit + palette | `Games\Keen\DelphiDoom.Keen.PngEncoder`, `Games\Greed\DelphiDoom.Greed.PngEncoder`, `Games\XcomFormats\DelphiDoom.Xcom.PngEncoder` (84-92 righe l'uno, quasi uguali tolti i nomi), più `Framework\Screenshot` | Un solo encoder "indicizzato -> PNG" in `Framework\Imaging` o `Framework\Png` |
| Immagine a 8 bit (larghezza, altezza, pixel) | `TKeenChunkyImage`, `TGreedImage`, `TXcomImage`, `TSpeedBitmap`, `TRadixBitmap`, `TFontImage` | Un record comune; è la causa dei tre encoder e dei tre esportatori |
| File da una o più cartelle | `Keen.FolderFiles`, `Greed.FolderFiles`, `IXcomDataFiles`/`IXcomFileSystem`, `Tools.Win.FileSystem`, `IIdeFileSystem`, `IIwadFileSystem` | `IFileStore` di `Framework\Platform`, a cui manca la ricerca su più cartelle senza maiuscole |
| Finestra Windows che mostra un fotogramma | `Games\Greed\DelphiDoom.Greed.Win.Window` (202 righe), `Games\OpenXcom\DelphiDoom.Xcom.Win.VideoDevice` (336), il pannello di `DD_Tools` | Libreria comune (finestra GDI, tasti e mouse come eventi, cattura PNG); `IGreedFramePresenter` e `IXcomVideoDevice` sono lo stesso contratto |
| Uscita audio PCM (`waveOut`) | `Games\OpenXcom\DelphiDoom.Xcom.Win.PcmOutput`, `Tracker.WaveOutDevice` in `Framework\Mikmod`, il player MP3 in `Base` | Un solo dispositivo PCM in `Framework\Audio` |
| Orologio | `IKeenClock`, `IXcomClock`, `IGreedRenderClock`, `IIdeClock`, due `ManualClock` gemelli, `Xcom.Win.Clock` | `IClock` di `Framework\Clock`, con un solo orologio manuale per i test |
| Log | `IXcomLog`, `IIdeLog`, `IIdLibLog` | `ILog` di `Framework\Logging` |
| Impostazioni su file | `Greed.SettingsStore`, `ISettingsStore` di `ToolsCore`, `Framework\Configuration` | Greed può usare `ToolsCore`; le opzioni di OpenXcom sono YAML e restano a parte |
| Riga di comando degli eseguibili | `Keen32`, `Greed32`, `Speed32`, `Xcom32`: ognuno scorre `ParamStr` a mano | `ICommandLine` di `Framework\CommandLine` |
| Supporto dei test | FNV-1a riscritta in 34 unit di test, `FindUp` in 7, una decina di lettori di golden (`*.Golden.pas`) | Una unit comune di test: impronta, ricerca dei dati, confronto riga per riga |
| Mixer audio | `XcomAudio.Mixer` (543 righe), `Tracker.Mixer`, i canali di `TSfxPlayer`, i 64 canali di Greed | Solo in parte: il mixer di XcomAudio può servire anche Greed e Keen |

## Già riusato bene

- Decoder audio: XcomAudio usa `Framework\Sound`, `Mp3`, `Mikmod`, `Midi`, `Opl`.
- Matematica: Greed usa `TFixedMath` di `LibsGameMath` (ex `MathCore`, #225).
- WAD e patch: Speed e Radix usano `IdTech1\GameData` e `Framework\Wad`.
- PNG e palette: tutti passano da `TPngClient` e `IPaletteConverter`; è duplicato solo l'involucro.

## Da non unificare

- Generatori casuali (`IKeenRandom`, `IGreedRandom`, `IXcomRandom`, `IGameRandom`): ogni gioco ha la sua sequenza e la parità con l'originale dipende da quella.
- Palette (EGA di Keen, VGA a 6 bit di Greed e X-COM): poche righe ciascuna, formati diversi.
- Ricampionatori: quello di `Imaging` è per immagini, quello di `XcomAudio` per audio.
- Formati dei dati e logica di gioco.

## Proposta, in ordine di valore

1. Libreria di piattaforma per i giochi (`Framework\GameHost`): finestra, eventi, orologio, uscita PCM, file su più cartelle, riga di comando; per Keen, Greed, OpenXcom, Speed e poi Radix.
2. Immagine a 8 bit comune ed encoder PNG unico.
3. Unit comune per i test.

Rischio basso: sono parti senza parità con gli originali; bastano build, suite e un avvio per gioco.

## Stato (issue #179, 2026-11-12)

Fatto in `Framework\GameHost`: finestra, eventi e dispositivi video GDI/OpenGL (Xcom32 e Greed32), uscita PCM waveOut di Xcom32, orologio di sistema di Xcom32 su `IClock`. Non fatto: `Tracker.WaveOutDevice` (lo usano gli eseguibili di Doom), sostituzione di `IKeenClock`/`IXcomClock`/`IGreedRenderClock` (sono il tempo del gioco, non orologi di sistema), file su piu' cartelle e riga di comando (`ICommandLine` mette in maiuscolo gli argomenti: serve prima una versione che conservi le maiuscole), immagine a 8 bit, encoder PNG e unit comune dei test. Dettagli in `Framework\GameHost\CLAUDE.md`.

## Stato dopo la seconda parte (issue #179, 2026-11-12)

| Voce della tabella | Esito | Dove |
|---|---|---|
| Encoder PNG | **Unificato**: un solo encoder, PNG identici byte per byte | `TPngIndexedEncoder` in `Framework\Png`; i tre dei giochi tengono solo le regole del gioco |
| Immagine a 8 bit | **In parte**: record comune `TIndexedImage`; `TKeenChunkyImage` e' lui; `TGreedImage` (origine) e `TXcomImage` (palette e metodi) si avvolgono all'encoder; `TSpeedBitmap`, `TRadixBitmap` e `TFontImage` restano (Speed non scrive PNG, Radix e' una classe con operazioni, Font e' a 32 bit) | `Framework\Png` |
| File da una o piu' cartelle | **Unificato per Keen, Greed e i dati di X-COM**: `IFolderFiles` | `Framework\Platform`; restano `IXcomFileSystem`/`TXcomFileMap` (regole di OpenXcom), `IIdeFileSystem`, `IIwadFileSystem`, i tool |
| Finestra | Unificata nella prima parte | `Framework\GameHost` |
| Uscita PCM | Unificata per Xcom32; `TTrackerWaveOutDevice` **resta separato per scelta** (contratto a scrittura contro contratto a richiesta, lo usano Doom, Heretic, Hexen e `DDMikmod`) | `Framework\GameHost\CLAUDE.md` |
| Orologio | **`IXcomClock` sostituito da `IClock`**, un solo orologio manuale per X-COM (`TManualClock`); `IKeenClock` e `IGreedRenderClock` **restano per scelta** (tempo del gioco, scrivibile o derivato dal ciclo: non orologi); `IIdeClock` non toccato | `Framework\Clock`, `Games\XcomEngine` |
| Log | Xcom32 passa da `ILog` con un adattatore (prima parte); `IXcomLog`, `IIdeLog`, `IIdLibLog` restano | - |
| Impostazioni su file | Non toccato | - |
| Riga di comando | **Unificata**: i quattro programmi leggono un `ICommandLine` che conserva le maiuscole con un cursore | `Framework\CommandLine` |
| Supporto dei test | **In parte**: `DelphiDoom.Tests.Shared.*` (FNV su byte, `FindUp`, file dei dati, confronto delle righe, salto) nelle suite dei giochi; restano le impronte su valori non byte, i lettori di golden con formato proprio e le suite delle librerie del motore di Doom | `Tests\Source` |
| Mixer audio | Non toccato | - |

Le aggiunte a `Framework\CommandLine`, `Framework\Platform`, `Framework\Clock` e `Framework\Png` sono solo unit nuove: `Doom32` e `GLDoom32` compilano come prima e `Doom32 -timedemo demo3` da' ancora 2134 gametic.
