# War — note per Claude

`War\` e' il **programma** `Warcraft32` (issue #200, parte di #203): composition root, finestra, uscita audio e file del
salvataggio di Warcraft: Orcs & Humans. Il gioco (archivio, risorse, livello, modello, scene, mappa, audio) sta in
`Libs\War` (leggere `Libs\War\CLAUDE.md` e `README.md` prima di toccare qualcosa); qui sta solo cio' che tocca il sistema
operativo o conosce le classi concrete. Uso e tasti: [README.md](README.md). Modello: `Greed\Greed32` + `Libs\Greed`.

## Struttura

- `Warcraft32.dpr` + `.dproj` (Base/Cfg_1/Cfg_2, Win32 e Win64, uscita `bin\<Piattaforma>\<Configurazione>\War`), icona
  `Warcraft32_Icon.rc` -> `war1.ico` (`BRCC_CompilerToUse=rc`). Il `.dpr` elenca solo le unit proprie e le due delle opzioni
  (come `Greed32`): le altre si trovano dal `DCC_UnitSearchPath` del `.dproj` (le cartelle di `Libs\` che `Libs\War` usa: War,
  AudioMix, GameHost, Audio, Xmi, M2m, Midi, Input, Clock, Logging, MathCore, Video, CommandLine, Configuration, Png, Zlib,
  Platform). **Una unit nuova di `Libs\War` che usa un'altra libreria vuole la cartella nel percorso del `.dproj` e, per il
  progetto di test, le unit nel `.dpr` (F2613).** Voce in `Tools\build.bat` (lista `STRUMENTI`, accanto a Greed32), in
  `DelphiDoom.Games.groupproj` e `'War' = 'Giochi'` in `Libs\Strati.psd1`.
- `DelphiDoom.War.Composition` (`TWarComposition.Run`): **l'unico** posto che mette insieme le classi. Apre i dati
  (`TWarDataLocator`, `TDataFolderLocator`), fa il suono, la funzione che fa un gioco (`MakeUiGame`: `TWarMapLauncher` con
  `UnsignedDirections = True` come il C fatto con gcc e un `TWarSeededRandom` per gioco, `TWarUiFactory.CreateGame` con le
  richieste di salvare e caricare) e le due strade: `RunScript` (`TWarUiScriptRunner`, per le prove) e `RunSession` (la sessione
  e il ciclo, con o senza finestra). Nessun `{$IFDEF}`; sceglie finestra o no, suono o no con le opzioni.
- Adattatori (uno per unit): `DelphiDoom.War.HostWindow` (`IWarFramePresenter` sull'`IGameHostTrueColorDisplay` del GDI),
  `DelphiDoom.War.HostAudio` (apre l'`IGameHostPcmOutput` sul `TWarPcmSource` di mixer e musica; il sorgente resta vivo fino a
  `Close`), `DelphiDoom.War.FileSaveStorage` (`IWarSaveStorage` su file, scrive accanto e rinomina).
- In `Libs\War` (nuove, una classe per unit, con test): `DelphiDoom.War.App.*` (opzioni, lettore delle opzioni, ricerca dei
  dati, impostazioni `.ini` sopra `Libs\Configuration`, `TWarSceneAudio` = `IWarSceneAudio` sul mixer e sul player della musica,
  `TWarFrameConverter` RGBA -> `$FFRRGGBB`, `TWarSession`, `TWarSessionRequests`, `TWarSessionEventSink`, `TWarRunner`,
  `TWarUiSessionGame`) e `DelphiDoom.War.Save.*`.

## Salvataggio: scelta e regole

**Il salvataggio e' la storia del gioco, non uno snapshot del modello** (`TWarSession`): seme + missione di `-play` + per
ogni fotogramma il tempo (`Single`, bit per bit) e gli eventi della finestra (mouse, tasti, focus). Caricare = `FBuilder`
(un gioco nuovo, un generatore nuovo) + rigioco senza schermo (`Muted` sul suono). Funziona **solo perche' il modello e'
deterministico** (provato dai golden contro il C): se una modifica cambia come un gioco gia' giocato va avanti, **alzare
`WAR_SAVE_MODEL_VERSION`** (i salvataggi vecchi sono rifiutati con un messaggio) e rifare i test. Il formato (`Save.Types`)
e' packed e senza puntatori (`SizeOf` coperto); alzare `WAR_SAVE_FORMAT_VERSION` se cambia. Cio' che deve restare vero:
(1) gli eventi che il gioco non legge (rotella, ridimensionamento, uscita) non si salvano; (2) F5 e F9 non arrivano al gioco ne'
alla storia; (3) le richieste fatte *durante* il rigioco si buttano (`Requests.Clear`: un clic di allora non e' un clic di
adesso); (4) il gioco che girava si lascia solo a rigioco riuscito; (5) `-script` non si salva (muove l'ingresso del gioco da solo).
Il costo del caricamento e' il tempo di calcolo della partita (circa 2 ms a fotogramma). Alternativa se non basta: salvare lo
stato (pool delle entita', stati, mappa, nebbia, muri, IA, generatore): non fatto.

## Cose da sapere

- **`TWarSceneServices.Sessions`** (nuovo campo, `IWarSessionRequests`) arriva dal terzo parametro opzionale di
  `TWarUiFactory.CreateGame`: i bottoni Save e Load del menu F10 (`TWarMapMenu.SaveGame/LoadGame`, via `IWarMapMenuSessions` che
  `TWarMapScene` implementa), il Save della fine della mappa e "Load existing game" del menu principale chiedono di salvare o
  caricare; senza (i golden, gli script) fanno cio' che facevano, niente. Il salvataggio e il caricamento si fanno **tra due
  fotogrammi** (`TWarRunner`), mai dentro uno.
- **`TWarMapAudio` ha ora un'uscita opzionale** (`IWarSceneAudio`, ultimo parametro del costruttore): suona il suono scelto (senza
  posizione sulla mappa). Le estrazioni e le entita' sono quelle di prima, con o senza uscita: i golden non cambiano.
- Il mouse di una finestra e' diviso per la scala (`TWarSessionEventSink`): il gioco vuole pixel di 320 x 200.
- Una finestra senza mouse (`-headless`) mette il mouse al centro con un evento registrato nella storia; senza, la mappa scorre
  verso l'angolo (0, 0).
- Le impostazioni (`Warcraft32.ini`): header `[Warcraft32 ver 1.10]`; la versione parte da 1.10 perche' `Libs\Configuration` accetta
  da `CONFIGURATION_OLDEST_VERSION` = 110, il formato non controlla di chi e' il file (lo fa `TWarAppSettings.TryFromLines`).
- Leak: il `.dpr` ha `ReportMemoryLeaksOnShutdown := True` sotto `{$IFDEF DEBUG}`; in un'applicazione console scrive "Unexpected
  Memory Leak" su stderr (non apre finestre): una esecuzione senza finestra con niente su stderr non ha perdite.

## Non fatto

Musica (sintetizzatore muto: il SoundFont del remake non ha licenza dichiarata), suoni con la posizione sulla mappa, filmati
nel gestore delle scene (la sequenza delle introduzioni e "Replay introduction"), schermo intero, selezione della risoluzione,
salvataggi multipli (uno slot rapido; `-save`/`-load` per i file), umani 4 (livello 123: il C si ferma su un `assert`).
