# Libs\GameHost

Piattaforma comune dei giochi che non girano sul motore di Doom (Keen, Greed, OpenXcom, Speed): finestra di Windows che mostra un fotogramma a 8 bit, eventi di tastiera e mouse, dispositivi video GDI e OpenGL (issue #179).

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md).

## Progetto

La libreria **non dipende da nessun gioco**: conosce solo `Winapi`, `Libs\Logging` (`ILog`) e `Libs\OpenGl\Binding\dglOpenGL` (di terzi, non modificato). Ogni gioco tiene in casa propria gli **adattatori** verso i suoi contratti.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.GameHost.Types` | colori e palette, evento di input neutro (tasto virtuale di Windows, carattere, pulsante, posizione nell'immagine), filtro del display, bande nere, sorgente di uno shader, eccezioni |
| `DelphiDoom.GameHost.Video.Intf` | `IGameHostVideoDevice` (modo, fotogramma, titolo), `IGameHostWindowStyle`, `IGameHostWindowPlacement`, `IGameHostFilteredDisplay`, `IGameHostShaderLoader` |
| `DelphiDoom.GameHost.Events.Intf` | `IGameHostEventSink` (dove vanno gli eventi), `IGameHostKeyboard` (modificatori e carattere di un tasto), `IGameHostKeyState` (tasti premuti), `TGameHostPump` |
| `DelphiDoom.GameHost.Audio.Intf` | `IGameHostPcmSource`, `IGameHostPcmOutput` |
| `DelphiDoom.GameHost.PictureLayout` | geometria pura: rettangolo dell'immagine a schermo intero, punto dell'area client -> punto dell'immagine |
| `DelphiDoom.GameHost.Win.MessageTranslator` | messaggi di Windows -> eventi neutri (senza finestra: si prova con finti) |
| `DelphiDoom.GameHost.Win.Keyboard` | `IGameHostKeyboard` su `GetKeyState`/`ToUnicode` |
| `DelphiDoom.GameHost.Win.Window` | la finestra: stile, posizione, modo, schermo intero senza cambiare il modo del sistema, pompa dei messaggi |
| `DelphiDoom.GameHost.Win.WindowDevice` | base dei dispositivi che disegnano nella finestra |
| `DelphiDoom.GameHost.Win.GdiVideoDevice` | fotogramma con GDI (DIB a 8 bit con palette) |
| `DelphiDoom.GameHost.Win.OpenGlProgram`, `...Win.OpenGlVideoDevice` | fotogramma con OpenGL (WGL), programma GLSL facoltativo |
| `DelphiDoom.GameHost.VideoDeviceSelector` | sceglie GDI o OpenGL a ogni `SetMode`, con ripiego su GDI e avviso nel log |
| `DelphiDoom.GameHost.KeyState` | `IGameHostEventSink` che ricorda i tasti premuti (per i giochi che interrogano lo stato) |
| `DelphiDoom.GameHost.Win.PcmOutput` | uscita PCM waveOut a richiesta (16 bit stereo, un thread chiede i campioni alla sorgente) |
| `DelphiDoom.GameHost.Factory`, `...OpenGl.Factory` | gli unici punti che conoscono le classi (finestra, GDI, PCM; OpenGL e selettore a parte, per non linkare OpenGL dove non serve) |

Adattatori dei giochi (restano nella cartella del gioco):

- `OpenXcom\`: `DelphiDoom.Xcom.HostVideoDevice` (`IXcomVideoDevice`, `IXcomWindowStyle`, `IXcomWindowPlacement`, `IXcomFilteredDisplay` sopra un `IGameHostVideoDevice`), `DelphiDoom.Xcom.HostEventSink` (eventi neutri -> `TXcomQueueEventSource` con i codici SDL 1.2), `DelphiDoom.Xcom.HostShaderLoader` (catalogo e lettore degli shader di XcomEngine), `DelphiDoom.Xcom.HostLog` (`ILog` -> `IXcomLog`), `DelphiDoom.Xcom.HostClock` (`IXcomClock` sopra `IClock` di `Libs\Clock`), `DelphiDoom.Xcom.HostPcmOutput` (`IXcomPcmOutput` sopra `IGameHostPcmOutput`).
- `Greed\`: `DelphiDoom.Greed.HostWindow` (`IGreedFramePresenter` e `IGreedInput` sopra il dispositivo GDI e `IGameHostKeyState`).

Seconda parte della #179 (dettagli in CLAUDE.md): l'orologio dei giochi e' `IClock` di `Libs\Clock` (`TManualClock` per screenshot e test), la riga di comando e' `TVerbatimCommandLine` e `ICommandLineCursor` di `Libs\CommandLine`, i file su piu' cartelle sono `IFolderFiles` di `Libs\Platform`, l'immagine a 8 bit e l'encoder PNG sono `TIndexedImage` e `TPngIndexedEncoder` di `Libs\Png`, il codice comune dei test e' `Tests\Source\DelphiDoom.Tests.Shared.*`. Restano separati per scelta `IKeenClock`, `IGreedRenderClock` e l'uscita waveOut dei moduli tracker.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.GameHost` (`Tools\build.bat DelphiDoom.Tests.GameHost`).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Analisi da cui nasce: [docs/ANALISI_DUPLICATI.md](../../docs/ANALISI_DUPLICATI.md).
