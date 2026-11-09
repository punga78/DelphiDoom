# Libs\XcomEngine

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Il motore di **OpenXcom** (`Engine\`: `Game`, `State`, `Action`, `Screen`, `InteractiveSurface`, `Language`, `LocalizedText`, `LanguagePlurality`, `Options`, `Timer`, `FileMap`, e la parte di `Mod` che serve all'interfaccia) a classi e **senza SDL**, issue #176. Il dispositivo (finestra, eventi, orologio, audio, file) sta dietro interfacce; l'implementazione di Windows (GDI) sta in `OpenXcom\XcomGame`. Solo il disegno e le regole che servono ai menu sono portati: vedi "Non portato".

Non e' un gioco del motore Doom: nessun collegamento a `ComposeEngine` ne' a `TIdTechGeneration`.

## Licenza (da decidere)

Il codice deriva da OpenXcom, **GPL v3 o successiva** (intestazione di ogni unit): e' un port, non una riscrittura da zero. La licenza dell'opera che lo contiene la decide il proprietario del repository; questa fetta non cambia quella del repository (`Libs\XcomFormats\README.md`).

## Cosa c'e'

| C++ (OpenXcom) | Delphi |
|---|---|
| `Game` (`run`, pila degli stati, `loadMods`, `loadLanguages`) | `TXcomGame` (`RunFrame` = un giro di `Game::run`, `Run`; `AdoptData`) |
| `State` e il suo `_game` statico | `TXcomState`; `TXcomStateHost` e' cio' che lo stato chiede al gioco (il gioco lo implementa) |
| `Surface` virtuale (`think`, `setPalette`, `setColor`, `initText`...) | `TXcomWidget` (sopra `TXcomSurface` di `Libs\XcomSurface`) |
| `InteractiveSurface` | `TXcomInteractiveSurface` (gestori come chiusure: `TXcomActionHandler`) |
| `Action` (e `SDL_Event`) | `TXcomAction`, `TXcomInputEvent` |
| `Timer` | `TXcomTimer` (orologio iniettato) |
| `Screen` (`flip`, `Zoom::_zoomSurfaceY`, fasce nere, `updateScale`) | `TXcomScreen` |
| `Language`, `LocalizedText`, `LanguagePlurality` | `TXcomLanguage`, `TXcomLocalizedText`, `TXcomLanguagePlurality` |
| `Options` (le opzioni usate) | `TXcomOptions` (istanza, non globali) |
| `FileMap` | `TXcomFileMap` (radici virtuali, l'ultima vince) |
| `RuleInterface` | `TXcomRuleInterface`, `TXcomInterfaceElement` |
| `Mod::getSurface/getFont/getPalette/getInterface/setPalette`, `loadVanillaResources`, `loadExtraResources`, `loadFile` (interfacce, costanti, `fontName`, `extraStrings`) | `IXcomResources`, `TXcomModResources` |
| `Font::loadTerminal` e `DosFont.h` | `TXcomTerminalFont`, `DelphiDoom.XcomEngine.DosFontData` |
| `Surface::loadImage` (i PNG dei font) | `TXcomPngSurfaceLoader` |
| il thread di `StartState::load` | `TXcomGameLoadTask` (`TXcomThreadLoadTask`, `TXcomImmediateLoadTask`, `TXcomHeldLoadTask`) sopra `IXcomGameLoader` (`TXcomModGameLoader`) |
| SDL (finestra, eventi, tempo) | `IXcomVideoDevice`, `IXcomEventSource`, `IXcomClock`, `IXcomAudioDevice`, `IXcomFileSystem`, `IXcomLog`; finti: `TXcomMemoryVideoDevice`, `TXcomQueueEventSource`, `TXcomManualClock`; file: `TXcomDiskFileSystem` |

Cambiamenti a `Libs\XcomSurface` (le superfici devono essere polimorfiche): `Draw`, `Blit`, `SetWidth`, `SetHeight`, `SetX`, `SetY`, `SetVisible` virtuali; `TXcomFont.GetChar` imposta il crop come `Font::getChar` (prima non lo faceva: i testi non si disegnavano giusti); `ImageCount`/`ImageSurface` per `Font::setPalette` e `getPalette`.

## Parita'

Il riferimento e' **il vero OpenXcom** (nightly ufficiale 2026-06-05, `Reference\_dati\_strumenti\openxcom_nightly`) con i dati veri di TFTD: il suo tasto degli screenshot (F12, `Tools\Verifica\176\Capture-OpenXcomScreen.ps1`) salva i pixel del frame a 640x400, e `Tools\Verifica\176\Compare-Png.ps1` li confronta con quelli di `XcomGame -shot`. Risultato: **menu principale 0 pixel diversi su 256000; schermata di avvio 0 diversi** (con il cursore del terminale nella stessa fase). `Tests\Data\XcomEngine\frames.golden.txt` ha l'impronta FNV-1a dei due frame veri e `TTestXcomRealData` la verifica sull'intero percorso (caricamento dei dati, palette, font PNG, regole `interfaces.rul`, lingua, `Window`, `Text`, `TextButton`); i test si saltano se `Reference\_dati\xcom_tftd\TFTD` non c'e'. Non c'e' un harness C++ che ricolleghi `Window.cpp`, `TextButton.cpp`... su SDL: il confronto col programma vero sui frame intelligibili e' piu' forte per cio' che copre, ma **non copre** `TextList`, `ComboBox`, `TextEdit`, `Slider`, `ScrollBar`, `ArrowButton` (non portati) e gli stati con lo scorrimento o gli effetti.

## Differenze volute e difetti conservati

- Le opzioni sono un'istanza (`TXcomOptions`) con i soli campi usati; `Save` scrive solo le principali. La lingua non guarda il locale del sistema: vale `Options.Language` o `en-US`.
- `Screen::flip` usa solo lo scalatore software senza filtri (`_zoomSurfaceY`, il passo `csax` identico); HQX, xBRZ, Scale2x e OpenGL non ci sono.
- Il suono dei pulsanti e dei popup non c'e' (nessun `IXcomAudioDevice` collegato); il filmato introduttivo (`CutsceneState`) non c'e'.
- `LocalizedText.arg` si comporta come quello di un temporaneo (avanza il numero dell'argomento).
- Il caricamento dei rulesets legge solo i file `.rul` che contengono `interfaces:`, `constants:`, `fontName:` o `extraStrings:`.
- Il thread di caricamento non si "uccide" come `SDL_KillThread`: il distruttore lo aspetta.
- `Cursor` disegna le linee con Bresenham (SDL_gfx `lineColor` non e' portato): un pixel delle diagonali puo' differire dall'originale; nei frame confrontati il cursore non c'e'.

## Non portato

`Sound`, `Music`, `SoundSet`, `CatFile`, `GMCat`, `AdlibMusic` (sopra `Libs\Audio`/`Libs\Opl`: il collegamento al dispositivo audio e' la prossima fetta), `Zoom` con i filtri, `OpenGL`, `FlcPlayer`, `Options` completo con `OptionInfo`, `ModInfo` e la scoperta dei mod, `CrossPlatform`, `Mod` e le sue `Rule*`, `SurfaceSet`, `Unicode` (solo i token e i test usati da `Text`).

Test: `Tests\DelphiDoom.Tests.XcomEngine` (209 test con `XcomUi` e `XcomMenu`; copertura `XcomEngine` 93%, `XcomUi` 96%, `XcomMenu` 93%); `Tools\build.bat Tests\DelphiDoom.Tests.XcomEngine`.
