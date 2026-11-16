# Framework\GameHost

Piattaforma comune dei giochi che non girano sul motore di Doom (Keen, Greed, OpenXcom, Speed): finestra di Windows che mostra un fotogramma a 8 bit, eventi di tastiera e mouse, dispositivi video GDI e OpenGL (issue #179).

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md).

## Progetto

La libreria **non dipende da nessun gioco**: conosce solo `Winapi`, `Framework\Logging` (`ILog`) e `Framework\OpenGlBinding\dglOpenGL` (di terzi, non modificato). Ogni gioco tiene in casa propria gli **adattatori** verso i suoi contratti.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.GameHost.Types` | colori e palette, evento di input neutro (tasto virtuale di Windows, carattere, pulsante, posizione nell'immagine), filtro del display, bande nere, sorgente di uno shader, eccezioni |
| `DelphiDoom.GameHost.Video.Intf` | `IGameHostVideoDevice` (modo, fotogramma, titolo), `IGameHostWindowStyle`, `IGameHostWindowPlacement`, `IGameHostFilteredDisplay`, `IGameHostShaderLoader` |
| `DelphiDoom.GameHost.TrueColor.Intf` | `IGameHostTrueColorDisplay` (issue #183): interfaccia facoltativa di un dispositivo che mostra anche un'immagine a colori (`$FFRRGGBB` per pixel); la implementano GDI, OpenGL e il selettore |
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
| `DelphiDoom.GameHost.MouseState` | `IGameHostEventSink` che ricorda i pulsanti del mouse premuti e se la finestra ha il fuoco (`IGameHostMouseState`, issue #175) |
| `DelphiDoom.GameHost.EventFanOut` | `IGameHostEventSink` che da' ogni evento a piu' ascoltatori (la finestra ne ha uno solo) |
| `DelphiDoom.GameHost.Win.CursorArea` | `IGameHostCursorArea`: dov'e' l'area client della finestra sullo schermo e se la finestra e' in primo piano (per un gioco che legge il cursore di sistema e lo riporta al centro) |
| `DelphiDoom.GameHost.Win.PcmOutput` | uscita PCM waveOut a richiesta (16 bit stereo, un thread chiede i campioni alla sorgente) |
| `DelphiDoom.GameHost.Factory`, `...OpenGl.Factory` | gli unici punti che conoscono le classi (finestra, GDI, PCM; OpenGL e selettore a parte, per non linkare OpenGL dove non serve) |

Adattatori dei giochi (restano nella cartella del gioco):

- `Games\OpenXcom\`: `DelphiDoom.Xcom.HostVideoDevice` (`IXcomVideoDevice`, `IXcomWindowStyle`, `IXcomWindowPlacement`, `IXcomFilteredDisplay` sopra un `IGameHostVideoDevice`), `DelphiDoom.Xcom.HostEventSink` (eventi neutri -> `TXcomQueueEventSource` con i codici SDL 1.2), `DelphiDoom.Xcom.HostShaderLoader` (catalogo e lettore degli shader di XcomEngine), `DelphiDoom.Xcom.HostLog` (`ILog` -> `IXcomLog`), `DelphiDoom.Xcom.HostClock` (`IXcomClock` sopra `IClock` di `Framework\Clock`), `DelphiDoom.Xcom.HostPcmOutput` (`IXcomPcmOutput` sopra `IGameHostPcmOutput`).
- `Games\Greed\`: `DelphiDoom.Greed.HostWindow` (`IGreedFramePresenter` e `IGreedInput` sopra il dispositivo GDI e `IGameHostKeyState`), `DelphiDoom.Greed.HostMouse` (`IMouseDevice`, `IScreenSize` e `IInputGate` di `Framework\Input` sopra `IGameHostCursorArea` e `IGameHostMouseState`).

Seconda parte della #179 (dettagli in CLAUDE.md): l'orologio dei giochi e' `IClock` di `Framework\Clock` (`TManualClock` per screenshot e test), la riga di comando e' `TVerbatimCommandLine` e `ICommandLineCursor` di `Framework\CommandLine`, i file su piu' cartelle sono `IFolderFiles` di `Framework\Platform`, l'immagine a 8 bit e l'encoder PNG sono `TIndexedImage` e `TPngIndexedEncoder` di `Framework\Png`, il codice comune dei test e' `Tests\Source\DelphiDoom.Tests.Shared.*`. Restano separati per scelta `IKeenClock`, `IGreedRenderClock` e l'uscita waveOut dei moduli tracker.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.GameHost` (`Tools\build.bat DelphiDoom.Tests.GameHost`).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Analisi da cui nasce: [docs/ANALISI_DUPLICATI.md](../../docs/ANALISI_DUPLICATI.md).

### Unit aggiunte per Keen32 (issue #165)

- `DelphiDoom.GameHost.WindowMouse`: `TGameHostWindowMouse`, il cursore di sistema dentro la finestra del gioco (`IMouseDevice`, `IScreenSize`, `IInputGate`); era `TGreedHostMouse`.
- `DelphiDoom.GameHost.ForegroundGate`: `TGameHostForegroundGate`, un `IInputGate` aperto solo con la finestra in primo piano.
