# DelphiDoom — istruzioni per Claude

Informazioni specifiche di questo repository. Le regole generali (commit, issue, lingua, MCP) sono nel CLAUDE.md globale.

## Progetto

Source port di Doom, Heretic, Hexen e Strife in Delphi (versione software e OpenGL), più Launcher, DD_IDE (editor degli script) e i compilatori `ddc*`.
Il target di sviluppo è **Delphi 11 (XE11), Win32**. Il codice nasce per Delphi 7: non si mantiene più la compatibilità con Delphi 7 nelle parti toccate.

- Cartelle di gioco: `Doom`, `Heretic`, `Hexen`, `Strife`; codice condiviso in `Base`, `Common`, `OPENGL`. Nel repository non c'è più codice C: libsndfile, libvorbis, libflac e il runtime `C_LIB` sono stati cancellati (restano nella storia di git, ultimo commit che li contiene: `a449cacd`).
- Un `.dpr` + `.dproj` per ogni eseguibile (`Doom32`, `GLDoom32`, `Heretic32`, …). I define di gioco (`DOOM`, `HERETIC`, `HEXEN`, `STRIFE`, `OPENGL`) stanno nei `.dproj`.
- **Script engine (issue #172, fetta 1, meccanica)**: la cartella `SCRIPT\` non esiste più. `Libs\PascalScript\` è il nucleo di Pascal Script (di terzi, modificato: `ps_defs`, `ps_keywords`, `ps_utils`, `ps_compiler`, `ps_runtime`, `uPSPreProcessor`, `uPSDisassembly`, `uPSC_/uPSR_dateutils` e `dll`, più i `.inc`); `Libs\ScriptHost\` è il collegamento al motore (`ps_import`, `ps_main`, `ps_events`, `ps_serializer`, `ps_proclist`, `ps_dll`, `psi_*`; la conversione dei `PS_*` a classi sarà la fetta 2); `Libs\Ddc\` è il compilatore da riga di comando (`ddc`, `ddc_base`, `dd_compiler`, `cmdline_compiler`). Le unit mantengono i nomi di prima; i `.dproj` dei giochi e dei `ddc_*` hanno `..\Libs\PascalScript` nel `DCC_UnitSearchPath` perché i `.inc` si includono a catena. Spostamento con `git mv`, nessuna modifica al codice: Doom32.exe, Hexen32.exe e ddc.exe hanno le stesse dimensioni di prima. README in ognuna delle tre cartelle.
- **Layout della radice (issue #170)**: in radice restano solo `CLAUDE.md`, `README.md`, `.gitignore`, `.gitattributes`, `DelphiDoom.groupproj` (tutti i progetti, da aprire nell'IDE) e le cartelle. I progetti stanno nella cartella del loro prodotto: `Doom\` (`Doom32`, `GLDoom32`, `ddc_doom`, icone), `Heretic\`, `Hexen\`, `Strife\` (idem), `Launcher\`, `DD_IDE\`, `DD_Tools\`, `Libs\Ddc\ddc.dpr`, `Keen\`, `Libs\<Lib>\DD*.dpr`, `Tests\*.dproj`. Nei `.dpr` le unit sono `in '..\Base\x.pas'`; i `.dproj` dei giochi hanno `..\Doom;..\Base;..\Common` nei percorsi e scrivono ancora in `..\bin\...` e `..\dcu\...` (le uscite sono quelle di sempre). `Doom32.inc` (incluso da centinaia di unit con `{$I Doom32.inc}`) sta in `Common\`: il compilatore lo trova perché `..\Common` è nel `DCC_UnitSearchPath` dei progetti dei giochi, di `ddc`, `Launcher`, `DD_IDE` e `DD_Tools`; i progetti di test e le DLL che hanno un loro `Doom32.inc` ridotto (`Tests\Include`, `Libs\Mp3\Shim`, `Libs\Script\Shim`) lo mettono nel percorso prima di `Common`. La documentazione sta in `docs\` (`docs\FACCIATE.md`, `docs\PENDING_ISSUES.md`, `docs\RUN*.md`, le note di versione dei giochi).

## Build e prove

```
Tools\build.bat                     # Doom32, Release
Tools\build.bat all                 # tutti i progetti (giochi + strumenti)
Tools\build.bat giochi | strumenti  # gruppi
Tools\build.bat Heretic32 Debug     # un progetto
Tools\build.bat all Release clean   # cancella prima la cartella dcu
Tools\build.bat all Release Win64   # 64 bit (dcc64); Win32 (predefinita) | Win64 | both
Tools\build.bat tests Release both  # librerie e test a 32 e a 64 bit, li esegue
```

- Il progetto si indica per nome (`Doom32`, `ddc_hexen`, `DDWad`, `DelphiDoom.Tests.Wad`) o per percorso senza estensione; `Tools\build.bat` si chiama da qualsiasi cartella (calcola la radice dal proprio percorso) e ha la tabella nome -> percorso nelle liste `GIOCHI`, `STRUMENTI`, `LIBRERIE`, `TESTS`. Per l'IDE: `DelphiDoom.groupproj`.
- Output: `bin\Doom|Heretic|Hexen|Strife` (giochi), `bin\Tools` (DD_IDE, ddc, DLL), `bin` (Launcher); `.dcu` in `dcu\`; log in `logs\<progetto>.log`. Tutte queste cartelle sono ignorate da git. **Win64 (issue #44)**: ogni `.dproj` dichiara anche Win64 (`TargetedPlatforms` 3, gruppo `'$(Platform)'=='Win64'` con `DCC_Platform` x64 e uscite separate): eseguibili e DLL in `bin\Win64\...` (DLL in `bin\Win64\Libs`, test in `bin\Win64\Tests`: stessa bitness), `.dcu` in `dcu\Win64\...`, log in `logs\Win64\`. Il riepilogo di `build.bat` è per piattaforma; a 64 bit i progetti che non compilano ancora (asm, `{$L}`: #41, #42, #43) sono elencati a parte con il primo errore e non alzano il codice di uscita (quello di Win32 sì). **Stato a 64 bit (2026-11-13)**: `build.bat all Release Win64` compila tutti i 34 progetti (10 DLL `DD*`, i 10 giochi, `ddc` e i quattro `ddc_*`, Launcher, DD_IDE, DD_Tools, Keen32, Greed32, Speed32, Xcom32, ParityTool); Debug Win64 provato per Doom32 e Strife32. Prova a runtime: le impronte dello stato di `-statehash` coincidono con i golden a 32 bit per Doom, Heretic, Hexen e Strife (corpus intero in modo 8); le impronte dei fotogrammi differiscono in 1 o 2 pixel su pochi fotogrammi di Doom e Heretic (vedi "Aree ancora aperte"). I giochi OpenGL, Radix32 e SpeedHaste32 compilano ma non sono stati avviati a 64 bit.
- Delphi è installato **in una VM** che legge il progetto da una cartella condivisa. Conseguenze: i file possono risultare bloccati (`Device or resource busy`) o letti con dimensione vecchia (errori di "fine file" su sorgenti integri); `Tools\build.bat` elenca i file prima di compilare per aggiornare la cache. Se un file è bloccato non ritentare in ciclo: chiedere di sospendere la VM.
- Per leggere i risultati di una build usare `logs\*.log` (righe `error`), non gli output a video.
- Prove a runtime: i WAD stanno in `bin\<Gioco>` (`DOOM1.WAD`, `FREEDOOM2.WAD`, `HERETIC1.WAD`, `HEXEN.WAD`, `STRIFE0.WAD`) insieme ai `*32.swd`. Log in `bin\<Gioco>\DATA\LOGS\` (`*_stderr.txt`, `*_stdout.txt`). Con `-devparm` si vedono le tracce di caricamento; in caso di crash `crash.txt` (unit `Base\i_crashlog.pas`) e il file `.map` accanto all'exe permettono di risalire all'indirizzo.
- **Strumenti di parita' (issue #185)**: prima di toccare logica o renderer dei giochi si verifica che il comportamento non cambi. `Tools\Verifica\185\Confronta-Golden.ps1` rilancia l'eseguibile sul corpus (`Corpus.psd1`: demo interne dei WAD e demo registrate col pilota in `Tests\Data\Parity\<Gioco>\*.lmp`) e confronta le impronte dello stato (per tic) e dei fotogrammi (8 e 32 bit) con i golden `Tests\Data\Parity\<Gioco>\*.gz`, dicendo la prima differenza (tic, oggetto e campo con `-RefExe`); `Registra-Golden.ps1` li rifa (solo con un eseguibile del codice di partenza), `Registra-Demo.ps1` registra le demo del pilota, `Rumore-Zero.ps1` prova che due esecuzioni danno impronte uguali, `Tools\Misura-Coppie.ps1` misura vecchio e nuovo a coppie e rifiuta la misura non affidabile. Opzioni del motore (inerti se non passate): `-statehash file`, `-statehash-detail primo ultimo`, `-framehash file`, `-framedump tic file`, `-autodemo seme tic`. Uso ed esempi: `docs\PARITA_MOTORE.md`; librerie: `Libs\Parity`.
- Non committare i `.res` (riscritti dal compilatore a ogni build) né i file generati dall'IDE.

## Librerie in DLL (`Libs\`)

Le librerie di uso comune si estraggono una alla volta in una DLL Delphi, con questo schema (modello: `Libs\Zlib`):

| Unit | Ruolo |
|---|---|
| `DelphiDoom.<Lib>.Intf` | contratto condiviso: interfaccia `I<Lib>`, codici di errore, eccezione `E<Lib>Exception`, nome della DLL e dell'export. Solo buffer grezzi e interi attraversano la DLL; l'interfaccia è `stdcall` e non passa mai `string` o tipi gestiti |
| `DelphiDoom.<Lib>.Native` | binding verso il codice C/Pascal della libreria (`{$L}` degli `.obj`), senza dipendenze dal resto del motore |
| `DelphiDoom.<Lib>.Engine` | `T<Lib>Engine`: implementa `I<Lib>` sopra il binding |
| `DelphiDoom.<Lib>.Loader` | `T<Lib>Loader`: carica la DLL, chiama l'export `DDxxxCreate` e rilascia l'interfaccia prima di `FreeLibrary` |
| `DelphiDoom.<Lib>.Client` | `T<Lib>Client`: la classe che il motore usa al posto della libreria; riceve un `I<Lib>` dal costruttore (funziona con la DLL, con l'engine in-process o con un finto nei test) |

La DLL è un progetto `DDxxx.dpr/.dproj` dentro la cartella della libreria, `Libs\<Lib>\` (output in `bin\Libs`; per compilarla `Tools\build.bat Libs\<Lib>\DDxxx`) che esporta `DDxxxCreate(out A: I<Lib>): Integer`. Test in `Tests\Source`, progetto `Tests\DelphiDoom.Tests.dproj` (`Tools\build.bat tests`, eseguibile in `bin\Tests`).
Librerie già estratte (sorgenti in `Libs\<Lib>`, DLL in `bin\Libs`, un progetto di test per libreria in `Tests\`): `Zlib` (`DDZlib`), `Jpeg` (`DDJpeg`), `Mp3` (`DDMp3`), `Xmi` (`DDXmi`), `Sndfile` (`DDSndfile`), `Mikmod` (`DDMikmod`), `Glbsp` (`DDGlbsp`), `Png` (`DDPng`), `Script` (`DDScript`), più `M2m` (convertitore MIDI→MUS), `Ogg` (contenitore Ogg), `IdTech` (il motore e la sua versione), `CommandLine` (gli argomenti del programma), `Configuration` (il file `.ini`) e `Wad` (lettura e scrittura di WAD, PAK, ZIP e cartelle, issue #46; ha la DLL `DDWad`, il motore non la usa). Ogni libreria ha il proprio progetto di test (`DelphiDoom.Tests` per zlib, poi `DelphiDoom.Tests.Jpeg`, …) perché le unit di libreria possono avere lo stesso nome (gli shim di `d_delphi`) o simboli C in conflitto, e non vanno linkate nello stesso eseguibile.

## Indice delle librerie e delle sezioni trasversali

Il CLAUDE.md di radice è stato diviso (issue #178): qui restano le regole generali valide per tutto il repository; il testo di dettaglio di ogni libreria (paragrafi spostati alla lettera, senza riassunti) sta in `Libs\<Nome>\CLAUDE.md`, accanto al suo `README.md`. Un paragrafo che riguarda più librerie sta nella libreria principale e le altre rimandano a lui.

Sezioni trasversali (non di una singola libreria), in [docs/CLAUDE_TRASVERSALI.md](docs/CLAUDE_TRASVERSALI.md):

- **Caricamento del livello** (issue #142): `TLevelLoader`, `ILevelLoader` e le regole per gioco.
- **Assembler inline** (issue #41): doppia versione `{$IFDEF CPUX86}` e Pascal di `Libs\MathCore`.
- **Uscita e schermi per le classi del motore** (issue #155): `IEngineShutdown`, `IEngineScreens`.
- **Lump e zone per le classi del motore** (issue #151): `IEngineLumps`, `TEngineZoneAllocator`.
- **Prova dei percorsi PK3** (issue #48): dati di prova e `Prova-Pk3.ps1`.

Librerie (CLAUDE.md di dettaglio, README):

- **Acs** — Compilatore ACS (ACC 1.10 di Raven) e interprete del bytecode BEHAVIOR di Hexen, a classi. [CLAUDE.md](Libs/Acs/CLAUDE.md), [README.md](Libs/Acs/README.md)
- **Actions** — Registro delle azioni degli stati (`A_Look`, `A_Chase`, quelle di ACTORDEF e MBF21). [CLAUDE.md](Libs/Actions/CLAUDE.md), [README.md](Libs/Actions/README.md)
- **ActorDef** — Parser di ACTORDEF/DECORATE e SNDINFO a classi. [CLAUDE.md](Libs/ActorDef/CLAUDE.md), [README.md](Libs/ActorDef/README.md)
- **Audio** — Effetti sonori (canali, voci, dispositivo) e musica (backend e player) del motore. [CLAUDE.md](Libs/Audio/CLAUDE.md), [README.md](Libs/Audio/README.md)
- **Automap** — Modello dell'automap (finestra sulla mappa, navigazione, segni, trasformazioni, ritaglio). [CLAUDE.md](Libs/Automap/CLAUDE.md), [README.md](Libs/Automap/README.md)
- **Blockmap** — Costruzione e lettura della blockmap e rimozione delle slime trails. [CLAUDE.md](Libs/Blockmap/CLAUDE.md), [README.md](Libs/Blockmap/README.md)
- **Clock** — Tempo del motore: sorgente di contatore monotono e orologio. [CLAUDE.md](Libs/Clock/CLAUDE.md), [README.md](Libs/Clock/README.md)
- **Collision** — Port del modello di collisione di Doom 3 / id Tech 4 (senza chiamanti nel motore). [CLAUDE.md](Libs/Collision/CLAUDE.md), [README.md](Libs/Collision/README.md)
- **CommandLine** — Argomenti del programma, file di argomenti di default, file di risposta, liste di autoload, riga di comando dell'avvio (`M_InitArgv`). [CLAUDE.md](Libs/CommandLine/CLAUDE.md), [README.md](Libs/CommandLine/README.md)
- **Configuration** — Formato del file `.ini` del motore (lettura e scrittura) e tabella delle impostazioni a classi (#185, fetta 1c). [CLAUDE.md](Libs/Configuration/CLAUDE.md), [README.md](Libs/Configuration/README.md)
- **Console** — Meccanismo della console: registro dei comandi, interprete, variabili, coda, cronologia, riga di input. [CLAUDE.md](Libs/Console/CLAUDE.md), [README.md](Libs/Console/README.md)
- **Ddc** — Compilatore da riga di comando degli script (`ddc`, `ddc_base`, `dd_compiler`, `cmdline_compiler`). [CLAUDE.md](Libs/Ddc/CLAUDE.md), [README.md](Libs/Ddc/README.md) (paragrafo in `Libs\ScriptHost`)
- **Decl** — Gestore delle dichiarazioni di id Tech 4 (issue #100, prima fetta): tipi registrati, lettura a richiesta, `table`, `skin`, `entityDef` con `inherit`, `pda`; parita' col vero DeclManager di Doom 3. [CLAUDE.md](Libs/Decl/CLAUDE.md), [README.md](Libs/Decl/README.md)
- **Definitions** — Lettura di ANIMDEFS, della tabella degli interruttori e della tabella del terreno. [CLAUDE.md](Libs/Definitions/CLAUDE.md), [README.md](Libs/Definitions/README.md)
- **Dehacked** — Parser delle patch DEHACKED/BEX con modello neutro. [CLAUDE.md](Libs/Dehacked/CLAUDE.md), [README.md](Libs/Dehacked/README.md)
- **DynLights** — Parser e registro delle luci dinamiche (GLDEFS/LIGHTDEF). [CLAUDE.md](Libs/DynLights/CLAUDE.md), [README.md](Libs/DynLights/README.md)
- **Endoom** — Schermo di testo di fine gioco (ENDOOM/ENDTEXT/ENDSTRF) e modello modificabile dell'editor. [CLAUDE.md](Libs/Endoom/CLAUDE.md), [README.md](Libs/Endoom/README.md)
- **EndoomEditor** — Logica della finestra di ENDEDIT senza VCL (presenter e viste). [CLAUDE.md](Libs/EndoomEditor/CLAUDE.md), [README.md](Libs/EndoomEditor/README.md)
- **EngineSystem** — Parte fredda delle unit `i_*` (fetta 1d della #185): sequenza di uscita e gestore degli errori fatali, rapporto di crash, opzioni di rete della riga di comando, scelta del player MIDI, player MIDI legacy, musica a moduli, buffer dello stdout, nomi dei log, profilo della macchina. [CLAUDE.md](Libs/EngineSystem/CLAUDE.md), [README.md](Libs/EngineSystem/README.md)
- **Font** — Logica del creatore di font DD_FONT. [CLAUDE.md](Libs/Font/CLAUDE.md), [README.md](Libs/Font/README.md)
- **FontEditor** — Presenter e viste del creatore di font (modulo Font di DD_Tools). [CLAUDE.md](Libs/FontEditor/CLAUDE.md), [README.md](Libs/FontEditor/README.md) (paragrafo in `Libs\Font`)
- **GameData** — Parte comune dei fork Mars3D, Rad-X e Speed: costruttore di patch e compositore di WAD. [CLAUDE.md](Libs/GameData/CLAUDE.md), [README.md](Libs/GameData/README.md)
- **GameHost** — Piattaforma comune dei giochi fuori dal motore di Doom (Keen, Greed, OpenXcom, Speed): finestra di Windows, eventi, dispositivi video GDI e OpenGL, uscita PCM waveOut; adattatori nelle cartelle dei giochi. [CLAUDE.md](Libs/GameHost/CLAUDE.md), [README.md](Libs/GameHost/README.md)
- **GameState** — `IGameContext`: ciò che una classe può chiedere del gioco in corso senza leggere i globali. [CLAUDE.md](Libs/GameState/CLAUDE.md), [README.md](Libs/GameState/README.md)
- **Geometry** — Tipi geometrici di base (vettori, matrici, piani, bounds, winding, trace model) usati da Collision. [CLAUDE.md](Libs/Geometry/CLAUDE.md), [README.md](Libs/Geometry/README.md) (paragrafo in `Libs\Collision`)
- **GlMath** — Geometria del renderer OpenGL a classi (clipper degli angoli, angolo del frustum). [CLAUDE.md](Libs/GlMath/CLAUDE.md), [README.md](Libs/GlMath/README.md)
- **Glbsp** — Port in Pascal di glBSP 2.24. [CLAUDE.md](Libs/Glbsp/CLAUDE.md), [README.md](Libs/Glbsp/README.md) (paragrafo in `Libs\Png`)
- **Greed** — Port a classi di xGreed ("In Pursuit of Greed"): archivio BLO, mappe, palette, immagini. [CLAUDE.md](Libs/Greed/CLAUDE.md), [README.md](Libs/Greed/README.md)
- **Hud** — HUD del motore (messaggi, chat, widget di testo, contatore FPS, layout dei glifi) a classi: `hu_stuff` e `hu_lib` sono facciate (issue #185, fetta 1a del piano "tutto a classi"). [CLAUDE.md](Libs/Hud/CLAUDE.md), [README.md](Libs/Hud/README.md)
- **IdLib** — Port a classi di idLib, la libreria di base di Doom 3. [CLAUDE.md](Libs/IdLib/CLAUDE.md), [README.md](Libs/IdLib/README.md)
- **IdTech** — Descrizione del motore su cui gira il port (generazione id Tech e versione). [CLAUDE.md](Libs/IdTech/CLAUDE.md), [README.md](Libs/IdTech/README.md)
- **Ide** — Logica dell'editor degli script DD_IDE senza VCL. [CLAUDE.md](Libs/Ide/CLAUDE.md), [README.md](Libs/Ide/README.md)
- **Imaging** — Patch, flat e immagini a classi su buffer, ricampionatore, miniatura dei salvataggi. [CLAUDE.md](Libs/Imaging/CLAUDE.md), [README.md](Libs/Imaging/README.md)
- **Info** — Logica delle tabelle `info` (ricerca per numero e nome, alias, ereditarieta', catene di stati, gruppi MBF21, mostri a caso, nomi degli stati degli script); le tabelle restano dati (issue #185, fetta 1b). [CLAUDE.md](Libs/Info/CLAUDE.md), [README.md](Libs/Info/README.md)
- **Input** — Tastiera, mouse e joystick: dispositivi, poller e mappa dei tasti. [CLAUDE.md](Libs/Input/CLAUDE.md), [README.md](Libs/Input/README.md)
- **Iwad** — Ricerca e riconoscimento degli IWAD. [CLAUDE.md](Libs/Iwad/CLAUDE.md), [README.md](Libs/Iwad/README.md)
- **Jpeg** — Decoder JPEG a classi (port della decompressione di libjpeg 6b). [CLAUDE.md](Libs/Jpeg/CLAUDE.md), [README.md](Libs/Jpeg/README.md)
- **Keen** — Port a classi di Commander Keen in Keen Dreams (formati di dati, mappe, grafica, input, motore dei livelli, azioni del giocatore e dei nemici, audio AdLib, ID_US e salvataggi, schermate di avvio, ciclo di gioco: `Keen32` e' il gioco in finestra). [CLAUDE.md](Libs/Keen/CLAUDE.md), [README.md](Libs/Keen/README.md)
- **Logging** — Log del motore: `ILog`, canali e sink. [CLAUDE.md](Libs/Logging/CLAUDE.md), [README.md](Libs/Logging/README.md)
- **M2m** — Convertitore MIDI in MUS. [CLAUDE.md](Libs/M2m/CLAUDE.md), [README.md](Libs/M2m/README.md) (paragrafo in `Libs\Zlib`)
- **MapInfo** — Lettura di UMAPINFO e catalogo delle mappe. [CLAUDE.md](Libs/MapInfo/CLAUDE.md), [README.md](Libs/MapInfo/README.md)
- **MathCore** — Parti pure di generatore casuale, hash, CRC, SHA-1, tabelle trigonometriche, aritmetica fixed, vettori e bbox; in virgola mobile di id Tech 4 (issue #95, prima fetta: angoli, quaternioni, matrice 3x3, rotazione, complessi, polinomi). [CLAUDE.md](Libs/MathCore/CLAUDE.md), [README.md](Libs/MathCore/README.md)
- **Midi** — Sequencer MIDI senza dispositivo, volume ed event feeder. [CLAUDE.md](Libs/Midi/CLAUDE.md), [README.md](Libs/Midi/README.md)
- **Mikmod** — Lettore di moduli tracker (MOD, S3M, XM, IT) in Pascal. [CLAUDE.md](Libs/Mikmod/CLAUDE.md), [README.md](Libs/Mikmod/README.md) (paragrafo in `Libs\Zlib`)
- **Models** — Lettura dei modelli 3D (MD2, liste di comandi procedurali, I3D di Speed). [CLAUDE.md](Libs/Models/CLAUDE.md), [README.md](Libs/Models/README.md)
- **Mp3** — Decoder MP3 (MPEG-1/2 layer III). [CLAUDE.md](Libs/Mp3/CLAUDE.md), [README.md](Libs/Mp3/README.md) (paragrafo in `Libs\Zlib`)
- **MusInfo** — Lettura del lump MUSINFO. [CLAUDE.md](Libs/MusInfo/CLAUDE.md), [README.md](Libs/MusInfo/README.md)
- **Net** — Trasporto UDP, protocollo dei pacchetti e sincronizzazione dei ticcmd. [CLAUDE.md](Libs/Net/CLAUDE.md), [README.md](Libs/Net/README.md) (paragrafo in `Libs\DynLights`)
- **Nodes** — Lettura dei nodi di una mappa (nodi GL, GWA di glBSP, nodi originali) e WAD per glBSP. [CLAUDE.md](Libs/Nodes/CLAUDE.md), [README.md](Libs/Nodes/README.md)
- **Obituary** — Testo dei necrologi e tabella dei generi. [CLAUDE.md](Libs/Obituary/CLAUDE.md), [README.md](Libs/Obituary/README.md)
- **Ogg** — Contenitore Ogg (port di libogg 1.3.x). [CLAUDE.md](Libs/Ogg/CLAUDE.md), [README.md](Libs/Ogg/README.md) (paragrafo in `Libs\Zlib`)
- **OpenGl** — Binding OpenGL di terzi e unit del renderer OpenGL storico. [CLAUDE.md](Libs/OpenGl/CLAUDE.md), [README.md](Libs/OpenGl/README.md)
- **Palette** — Palette, colormap e tabelle di traduzione come classi pure. [CLAUDE.md](Libs/Palette/CLAUDE.md), [README.md](Libs/Palette/README.md)
- **Parity** — Strumenti di parita' del motore (issue #185, fase 0 di `docs\PIANO_TUTTO_A_CLASSI.md`): impronta dello stato per tic (`-statehash`), impronta del fotogramma (`-framehash`, `-framedump`), pilota automatico per registrare demo (`-autodemo`), orologio e input ripetibili, golden e misura a coppie; si usano con `Tools\Verifica\185` e `Tools\Misura-Coppie.ps1`, istruzioni in `docs\PARITA_MOTORE.md`. [CLAUDE.md](Libs/Parity/CLAUDE.md), [README.md](Libs/Parity/README.md)
- **PascalScript** — Nucleo di Pascal Script (di terzi, modificato). [CLAUDE.md](Libs/PascalScript/CLAUDE.md), [README.md](Libs/PascalScript/README.md) (paragrafo in `Libs\ScriptHost`)
- **Platform** — Servizi del sistema operativo: file, cartelle temporanee, informazioni su sistema, CPU ed eseguibile. [CLAUDE.md](Libs/Platform/CLAUDE.md), [README.md](Libs/Platform/README.md)
- **Png** — Codifica e decodifica PNG (la compressione arriva da un `IZlib` iniettato). [CLAUDE.md](Libs/Png/CLAUDE.md), [README.md](Libs/Png/README.md)
- **Racing** — Auto, fisica, IA, percorso, giri e tabelle dei tempi di Speed Haste (S4 di Speed, parità con il vecchio codice). [CLAUDE.md](Libs/Racing/CLAUDE.md), [README.md](Libs/Racing/README.md)
- **Renderer** — Analisi del renderer e prime fette fredde (tabella colonne delle texture, precalcolo del livello). [CLAUDE.md](Libs/Renderer/CLAUDE.md), [README.md](Libs/Renderer/README.md)
- **Scanner** — Scanner dei testi degli script, preprocessore, valutatore di espressioni, AUTOLOAD. [CLAUDE.md](Libs/Scanner/CLAUDE.md), [README.md](Libs/Scanner/README.md)
- **Screenshot** — Scrittura degli screenshot (TGA, PNG, JPEG). [CLAUDE.md](Libs/Screenshot/CLAUDE.md), [README.md](Libs/Screenshot/README.md)
- **Script** — Fetta verticale di Pascal Script (compilare, eseguire, funzioni host, globali). [CLAUDE.md](Libs/Script/CLAUDE.md), [README.md](Libs/Script/README.md) (paragrafo in `Libs\Png`)
- **ScriptHost** — Collegamento di Pascal Script al motore: registro delle funzioni, variabili, eventi, serializzatore, speciali, attori, mondo, catalogo delle classi, overlay (fetta 2 della #172 conclusa). [CLAUDE.md](Libs/ScriptHost/CLAUDE.md), [README.md](Libs/ScriptHost/README.md)
- **Serializer** — Serializzatore dei record dei salvataggi. [CLAUDE.md](Libs/Serializer/CLAUDE.md), [README.md](Libs/Serializer/README.md)
- **Sndfile** — Contratto `ISndfile` e provider che usa il motore di `LibsSound`. [CLAUDE.md](Libs/Sndfile/CLAUDE.md), [README.md](Libs/Sndfile/README.md) (paragrafo in `Libs\Sound`)
- **Sound** — Sostituto in Pascal di libsndfile, libvorbis e libflac. [CLAUDE.md](Libs/Sound/CLAUDE.md), [README.md](Libs/Sound/README.md)
- **Specials** — Registro degli special delle linee al posto del grande `case`. [CLAUDE.md](Libs/Specials/CLAUDE.md), [README.md](Libs/Specials/README.md)
- **Speed** — Traduzione del contenitore `SPEEDH.JCL` di Speed Haste in un WAD in memoria; la cartella `Speed\` ha il programma `Speed32` (traduce e fa correre le auto del computer con `Libs\Racing`, senza finestra né motore) e `SpeedHaste32` (il motore di Doom con i define `DOOM;SPEED`, `Tools\build.bat SpeedHaste32`: traduce `SPEEDH.JCL` e carica un circuito; il gioco non c'è ancora). [CLAUDE.md](Libs/Speed/CLAUDE.md), [README.md](Libs/Speed/README.md)
- **TableExport** — Scrittura delle tabelle correnti del motore come DEH, ACTORDEF, WEAPONDEF, CSV e sorgente Pascal. [CLAUDE.md](Libs/TableExport/CLAUDE.md), [README.md](Libs/TableExport/README.md)
- **Texture** — Decoder dei file di immagine delle texture esterne e immagine in memoria. [CLAUDE.md](Libs/Texture/CLAUDE.md), [README.md](Libs/Texture/README.md)
- **TextureDefs** — Lettura delle definizioni delle texture (PNAMES, TEXTURE1..3, TEXTURE0) e dei flat (FLATINFO). [CLAUDE.md](Libs/TextureDefs/CLAUDE.md), [README.md](Libs/TextureDefs/README.md)
- **Thinkers** — Luci, porte, piattaforme, teletrasporti, passo di pavimenti e soffitti a classi. [CLAUDE.md](Libs/Thinkers/CLAUDE.md), [README.md](Libs/Thinkers/README.md)
- **Threading** — Thread di lavoro e pool del motore. [CLAUDE.md](Libs/Threading/CLAUDE.md), [README.md](Libs/Threading/README.md)
- **ToolsCore** — Codice comune dei tool: annulla/rifai, file recenti, impostazioni, avanzamento, copia di sicurezza. [CLAUDE.md](Libs/ToolsCore/CLAUDE.md), [README.md](Libs/ToolsCore/README.md) (paragrafo in `Libs\EndoomEditor`)
- **Udmf** — Conversione di una mappa UDMF (TEXTMAP) nei record del motore. [CLAUDE.md](Libs/Udmf/CLAUDE.md), [README.md](Libs/Udmf/README.md)
- **Video** — Parte del video indipendente dall'API grafica: palette, limiti, catalogo dei modi, risoluzione. [CLAUDE.md](Libs/Video/CLAUDE.md), [README.md](Libs/Video/README.md)
- **Voxel** — Lettura dei file dei voxel e del lump VOXELDEF. [CLAUDE.md](Libs/Voxel/CLAUDE.md), [README.md](Libs/Voxel/README.md)
- **VoxelEditor** — Editor di voxel (modulo Voxel di DD_Tools): cubo, viste, strumenti, formati DDVOX/KVX/VOX/DDMESH, presenter. [CLAUDE.md](Libs/VoxelEditor/CLAUDE.md), [README.md](Libs/VoxelEditor/README.md)
- **Wad** — Lettura e scrittura di WAD, PAK, ZIP e cartelle; directory dei lump del motore. [CLAUDE.md](Libs/Wad/CLAUDE.md), [README.md](Libs/Wad/README.md)
- **War** — Lettura dell'archivio `DATA.WAR` di Warcraft: Orcs & Humans (port a classi di `war_file.c` del remake war1, zlib; issue #191, indice #203); i dati non sono nel repository. [CLAUDE.md](Libs/War/CLAUDE.md), [README.md](Libs/War/README.md)
- **XcomAudio** — Mixer, musica (Adlib e WAV) ed effetti di OpenXcom sopra `Libs\Opl`; uscita waveOut in `OpenXcom\`. [CLAUDE.md](Libs/XcomAudio/CLAUDE.md), [README.md](Libs/XcomAudio/README.md)
- **XcomBattle** — Battlescape di OpenXcom (modello e logica senza UI): tegole, oggetti, unita', battaglia salvata, pathfinding, motore delle tegole (luce, vista, linee, esplosioni); parita' sul vero OpenXcom. [CLAUDE.md](Libs/XcomBattle/CLAUDE.md), [README.md](Libs/XcomBattle/README.md)
- **XcomBattlescape** — Disegno della battaglia di OpenXcom: camera, mappa tattica (tegole, muri, oggetti, unita', fuoco, fumo, cursore) e sprite delle unita'; parita' sui pixel col vero `Map::draw()`. [CLAUDE.md](Libs/XcomBattlescape/CLAUDE.md), [README.md](Libs/XcomBattlescape/README.md)
- **XcomBattleStates** — Stati del Battlescape di OpenXcom (schermo della battaglia, menu delle azioni, inventario, statistiche, minimappa, turni, briefing) e ingresso nella battaglia dal geoscape e da un salvataggio; parita' sui pixel col vero OpenXcom. [CLAUDE.md](Libs/XcomBattleStates/CLAUDE.md), [README.md](Libs/XcomBattleStates/README.md)
- **XcomEngine** — Motore di OpenXcom a classi senza SDL (gioco, stato, schermo, lingua, opzioni, risorse del mod, dispositivi dietro interfacce); parita' sui pixel col vero OpenXcom. [CLAUDE.md](Libs/XcomEngine/CLAUDE.md), [README.md](Libs/XcomEngine/README.md)
- **XcomFormats** — Lettura dei formati di dati di UFO: Enemy Unknown e Terror from the Deep. [CLAUDE.md](Libs/XcomFormats/CLAUDE.md), [README.md](Libs/XcomFormats/README.md)
- **XcomDebriefing** — Fine missione di OpenXcom (DebriefingState: recupero, punteggio, medaglie, promozioni, base attaccata) con parita' sul vero programma; schermate Debriefing e CannotReequip. [CLAUDE.md](Libs/XcomDebriefing/CLAUDE.md), [README.md](Libs/XcomDebriefing/README.md)
- **XcomBasescape** — Basescape di OpenXcom a classi senza SDL (schermata della base, griglia delle strutture, mini mappe); parita' sui pixel col vero OpenXcom. [CLAUDE.md](Libs/XcomBasescape/CLAUDE.md), [README.md](Libs/XcomBasescape/README.md)
- **XcomGeoscape** — Geoscape di OpenXcom a classi senza SDL (globo con parita' sui pixel, schermata principale, scelta del sito della prima base, avvio di una partita nuova). [CLAUDE.md](Libs/XcomGeoscape/CLAUDE.md), [README.md](Libs/XcomGeoscape/README.md)
- **XcomMenu** — Stati di Menu\ di OpenXcom (schermata di avvio, menu principale). [CLAUDE.md](Libs/XcomMenu/CLAUDE.md), [README.md](Libs/XcomMenu/README.md)
- **XcomStrategy** — Gioco strategico di OpenXcom mentre il tempo passa: missioni aliene, produzione, radar, script delle missioni e i passi di `GeoscapeState` (`time5Seconds` ... `time1Month`) con i popup come eventi; parita' sui salvataggi veri (harness `simgen`). [CLAUDE.md](Libs/XcomStrategy/CLAUDE.md), [README.md](Libs/XcomStrategy/README.md)
- **XcomUfopaedia** — Ufopaedia di OpenXcom a classi senza SDL (catalogo degli articoli secondo le ricerche, schermata iniziale, lista di una sezione, `ArticleState` e i 17 tipi di articolo di UFO e TFTD); parita' sui pixel col vero OpenXcom. [CLAUDE.md](Libs/XcomUfopaedia/CLAUDE.md), [README.md](Libs/XcomUfopaedia/README.md)
- **XcomUi** — Widget di Interface\ di OpenXcom (Text, Window, TextButton, Frame, Cursor, FpsCounter, NumberText). [CLAUDE.md](Libs/XcomUi/CLAUDE.md), [README.md](Libs/XcomUi/README.md)
- **Xmi** — Convertitore XMI/CMF in MIDI. [CLAUDE.md](Libs/Xmi/CLAUDE.md), [README.md](Libs/Xmi/README.md) (paragrafo in `Libs\Zlib`)
- **Zlib** — Compressione e decompressione zlib (sopra `System.ZLib`). [CLAUDE.md](Libs/Zlib/CLAUDE.md), [README.md](Libs/Zlib/README.md)
- **Zone** — Allocatore della zone memory a classi. [CLAUDE.md](Libs/Zone/CLAUDE.md), [README.md](Libs/Zone/README.md)
- **OpenGl/Recorder** — Registratore delle chiamate OpenGL, criterio di parità per le fette del renderer OpenGL. [CLAUDE.md](Libs/OpenGl/Recorder/CLAUDE.md), [README.md](Libs/OpenGl/Recorder/README.md)

## Stile del codice

**Riferimento obbligatorio:** `D:\Progetti\Skema\SupervisioneNats\lib\delphi-neon` (libreria Neon). Prima di scrivere codice nuovo leggere un'unit di `Source\` e imitarla.

Regole ricavate da Neon:

- **Unit**: una responsabilità per unit, nome a punti (`Area.Sottoarea.Nome`), intestazione di licenza, `{$I File.inc}` subito dopo `unit`, poi `interface` / `uses` / `implementation`. Le direttive `{$IFDEF}` iniziano a colonna 0.
- **Indentazione**: 2 spazi, `begin` su riga propria, una riga vuota tra metodi, righe lunghe spezzate sugli argomenti.
- **Nomi**: classi `TNome`, eccezioni `ENome`, interfacce `INome`, campi `FNome`, parametri `ANome`, variabili locali `LNome`, costanti per i messaggi `SNome`, `Result` per il valore di ritorno. Nomi interi e descrittivi, niente abbreviazioni (`LArrayLength`, non `len2`).
- **Firme**: parametri `const` per stringhe e record, `Assigned()` per i controlli su nil, `class function ... static` per le utility senza stato, `overload` esplicito, generics dove evitano duplicazioni.
- **Commenti**: documentazione XML (`/// <summary>`, `/// <remarks>`) sui tipi e sui metodi pubblici; commento breve `//` solo per il *perché* di un punto non ovvio.
- **Errori**: eccezioni dedicate (`raise ENomeException.Create(SMessaggio)`), niente `Exit` silenziosi che nascondono un errore.
- **Visibilità**: `private`/`protected`/`public` esplicite, dati privati accessibili via metodi o property.

### Codice esistente

Il codice storico usa `snake_case` e tipi/funzioni in minuscolo (`P_SetupLevel`, `lumpinfo_t`, `mobj_t`). **Non** rinominare in massa né riformattare: rende illeggibile il diff e la sincronizzazione con il progetto originale. Lo stile Neon vale per il codice nuovo e per le unit riscritte; dentro una funzione storica modificata si mantiene la coerenza locale, ma le funzioni e le classi nuove seguono Neon.

## Principi SOLID

Applicare ai moduli nuovi o riscritti, con buon senso nei percorsi critici per le prestazioni (renderer, thinker, blockmap):

- **S** — una classe/unit, una ragione di cambiare (caricamento dati, rendering, I/O, script e audio non vanno mescolati).
- **O** — estendere con interfacce, strategie o registrazione di classi invece di aggiungere `case`/`if` su tipo nel codice esistente.
- **L** — le classi derivate non restringono i contratti della base (precondizioni, eccezioni, valori ammessi).
- **I** — interfacce piccole e mirate (come `IDynamicMap`, `IDynamicList` in Neon), non una interfaccia "dio".
- **D** — dipendere da interfacce, passare le dipendenze dal costruttore; niente nuove variabili globali o `uses` circolari. I globali del motore (`gamemode`, `devparm`, `lumpinfo`…) restano, ma i moduli nuovi non devono dipendere direttamente da loro: riceverli come parametri.

## Classi e dependency injection (issue #45)

Il codice nuovo o riscritto è **a classi, con le dipendenze iniettate**; lo schema è quello di `Libs\` (interfaccia, engine, client che la riceve dal costruttore, provider/factory).

- Le dipendenze arrivano dal costruttore come **interfacce piccole**; niente `uses` verso unit concrete per ottenere un servizio, niente nuove variabili globali.
- **Composition root**: un solo posto (per il motore `DelphiDoom.Engine.Composition`, per le librerie la loro `*.Factory`/`*.Provider`) conosce le classi concrete e le assembla. Il resto conosce solo le interfacce.
- Si sceglie tra due implementazioni (32/64 bit, DLL/in-process, finto nei test) **iniettando una strategia**, non con `{$IFDEF}` sparsi.
- Ogni classe ha test con un **finto** al posto delle dipendenze (nessun WAD, finestra, audio, rete).
- I globali storici si leggono solo nel composition root o nel codice storico; le classi nuove li ricevono come parametri.

## Una classe per unit

- Ogni unit nuova o riscritta contiene **una sola classe** (o un solo record/interfaccia principale). Il nome dell'unit deriva dal tipo: `TWadReader` → `DelphiDoom.Wad.Reader`.
- Nelle unit nuove i nomi sono a punti con prefisso `DelphiDoom.<Area>.` (come `Neon.Core.*`), non `snake_case`.
- Nella stessa unit possono stare solo i tipi di supporto usati esclusivamente da quella classe (un `enum`, un `record` di parametri, un'eccezione propria). Eccezioni e tipi condivisi vanno in una unit `*.Types`.
- Interfaccia e implementazione in unit separate quando esistono più implementazioni o quando serve sostituire la dipendenza nei test.
- **Non aggiungere classi alle unit storiche enormi** (`Common\d_delphi.pas`, `Libs\PascalScript\ps_runtime.pas`…): creare un'unit nuova e farla usare dal chiamante.
- Le unit storiche con più classi non si spezzano in massa; si separano solo quando la classe viene riscritta.

## Test

- Framework: **DUnitX**, come in `delphi-neon\Tests`. Una fixture (`[TestFixture]`) per ogni unit, una unit di test per ogni classe: `DelphiDoom.Tests.<Area>.<Classe>`, classe `TTest<Classe>`.
- Struttura: cartella `Tests\` alla radice con il progetto console `DelphiDoom.Tests.dpr/.dproj`, `Tests\Source` (una unit per fixture) e `Tests\Data` (file di input). Attributi come in Neon: `[TestFixture]`, `[Category('…')]`, `[Setup]`/`[TearDown]`, `[Test]`, `[TestCase('nome', 'a,b')]`, `Assert.AreEqual`.
- Codice nuovo o riscritto: ogni classe ha i suoi test. Ogni bug corretto in codice testabile (parsing, conversioni di nomi e stringhe, tabelle, formati WAD/savegame) ha un test di regressione che fallisce prima della correzione.
- Test deterministici e isolati: nessun WAD commerciale, nessuna finestra, DirectX, audio o rete, nessun `sleep`. Dati minimi in `Tests\Data` o costruiti in memoria; ogni test crea e libera le proprie risorse (`Setup`/`TearDown`) e non dipende dall'ordine.
- Ciò che richiede il motore completo (caricamento di un livello, rendering, demo) non si copre con DUnitX: si prova avviando il gioco come descritto in "Build e prove" e si controllano `DATA\LOGS` ed eventuale `crash.txt`.
- Prima di ogni commit: compilare (`Tools\build.bat all`) ed eseguire la suite quando esiste. Descrizioni dei test e commenti di business in italiano, identificatori in inglese.

## Regole Unicode (XE11)

`string`, `Char` e `PChar` sono Unicode (2 byte). Il motore tratta come byte molti dati: per questi usare i tipi a 8 bit.

- Dati binari o testo a 8 bit (lump, WAD, savegame, cheat, script, log, MIDI, ACS, librerie C): `AnsiString`, `AnsiChar`, `PAnsiChar`. Mai `string` letta/scritta con `Move`, `BlockRead`, `BlockWrite` o puntatori.
- Aritmetica su puntatori: `PChar + n` avanza di 2 byte per elemento. Usare `PAnsiChar` o `PByte`.
- Dimensioni dei buffer di caratteri: `Length(buf)` (caratteri), non `SizeOf(buf)` (byte), quando l'API conta caratteri.
- API Windows: le versioni `W` vogliono `PChar`; Winsock, `GetProcAddress`, `WinExec`, le librerie C vogliono `PAnsiChar` (convertire con `PAnsiChar(AnsiString(s))`).
- Costruzione di caratteri da interi: `AnsiChar(x and $FF)`; `Chr(x)` con `x > 255` non tronca più.
- `CreateProcess` può scrivere nel buffer della riga di comando: passare una copia scrivibile (`UniqueString`).
- Formattazione numerica: `FormatSettings.DecimalSeparator`, non le vecchie globali.

## 32 e 64 bit (issue #40)

L'obiettivo è che ogni progetto compili e funzioni sia a Win32 sia a Win64; Win64 compila per tutti i progetti e i giochi software girano (issue #44, vedi "Build e prove"). Nel codice nuovo:

- **Mai** `Integer`/`Cardinal` per contenere un puntatore o un handle: `NativeInt`/`NativeUInt`/`PtrUInt`, o un puntatore tipizzato.
- **Mai** assembler inline (`asm`) né `{$L file.obj}`: Pascal puro; l'`asm` storico si sostituisce con Pascal e test di parità (#41), gli `.obj` OMF spariscono con le riscritture (#42).
- Record dei formati su disco (savegame, WAD, lump) senza puntatori e con `SizeOf` coperto da un test: devono essere uguali a 32 e 64 bit.
- `Extended` a 64 bit vale 8 byte: dove serve una precisione scrivere `Double` in modo esplicito; l'ambiente in virgola mobile (`Set8087CW`) sta dietro una classe, non nel codice che lo usa.
- Le DLL `DD*.dll` devono avere la stessa bitness dell'eseguibile.
- **Trappole trovate nel porting a 64 bit (issue #44)**: (1) `integer(puntatore)` e `longword(puntatore)` troncano senza errore né avviso: la differenza tra due puntatori si scrive con `NativeInt`/`NativeUInt` (il test con `-statehash` e i golden li trova, l'accesso al puntatore tronco è una violazione di accesso con indirizzo `FFFFFFFF........`); `mobj_t.special1/special2` sono `NativeInt` perché Heretic e Hexen ci mettono dei puntatori. (2) Un indice senza segno meno uno (`segs[sub.firstline - 1]`) a 32 bit vale -1, a 64 bit 4294967295: usare `dec(puntatore)`. (3) **Ordine di valutazione**: il compilatore a 32 bit valuta gli argomenti di una chiamata da destra a sinistra, quello a 64 bit da sinistra a destra: `P_SpawnMobj(x + P_Random.., y + P_Random.., ..)` dà posizioni diverse e fa divergere la partita; con più chiamate che consumano il generatore casuale in argomenti diversi si scrive con variabili locali nell'ordine di Win32 (destra-sinistra); `P_Random - P_Random` e `a + b + c` hanno lo stesso ordine nei due compilatori. (4) I record delle API di Windows con puntatori devono avere la dimensione del C (`DDSURFACEDESC2` 136 byte a 64 bit): `DirectX.pas` ha un riempimento sotto `{$IFDEF CPUX64}`, coperto da `Tests\DelphiDoom.Tests.Win64`. (5) A 64 bit le eccezioni in virgola mobile sono quelle dell'unità SSE: `Set8087CW` non basta, i `.dpr` dei giochi chiamano `SetExceptionMask(exAllArithmeticExceptions)` sotto `{$IFDEF CPUX64}`. (6) `d_delphi` usa le unit di `Libs\MathCore` solo a 64 bit: un `.dpr` che usa `d_delphi` senza il percorso di `Libs\MathCore` le elenca sotto `{$IFNDEF CPUX86}` (come `Libs\Ddc\ddc.dpr`).

**Test a 64 bit (issue #44 e #43)**: `Tools\build.bat tests Release Win64` compila 91 progetti di test su 96 (i 5 che dipendono da `Common\d_delphi.pas(795)`, `E2100`, sono `Common`, `AsmParity`, `EngineSystem`, `Hud`, `InfoTables`) e li esegue: 12332 test, 53 falliti (il resto passa; i 16 errori di `Acs` sono il file di dati assente nel worktree, anche a 32 bit). A 32 bit nessun fallimento. Gli exe a 64 bit stanno in `bin\Win64\Tests` e cercano i dati con `..\..\Tests\Data` dalla cartella dell'exe: `build.bat` copia `Tests\Data` in `bin\Tests\Data` (copia con `robocopy`, mai giunzioni o link simbolici). **Trappole viste nei test**: `Assert.AreEqual` con `Length(array)` (`NativeInt` a 64 bit) e un `Integer` non deduce `T`: scrivere `AreEqual<Integer>`; l'**ordine di valutazione degli argomenti e degli operandi non e' definito** e dcc64 lo sceglie diverso da dcc32 (a 32 bit i parametri in pila da sinistra e poi quelli in registro da destra): un test con piu' estrazioni casuali in una chiamata o in una espressione deve metterle in istruzioni separate (nell'ordine di Win32, per non cambiare i golden); un record sullo stack non e' azzerato; i puntatori del vecchio codice copiato nei test passano per `NativeInt`; con argomenti interi `System.Math` sceglie l'overload `Single` di `ArcTan2` e `Tan`; `-abv` su un `Cardinal` e' negativo a 64 bit; `Sin`, `Sqrt`, `Power` non cambiano. **Parita' con l'x87**: dove il golden e' stato fatto con il codice a 32 bit che teneva gli intermedi in `Extended` (80 bit, arrotondamento doppio) o in `Single` con intermedi a 64 bit, a 64 bit il risultato differisce nell'ultimo bit: `TExtendedQuotient` (`Tests\Source\DelphiDoom.Tests.Support.ExtendedQuotient.pas`) riproduce il quotiente intero/`Double` a 32 bit; `TFixedMath.Mul64` e `TRacingMath.Distance` sono esatti con interi. **Ancora a 64 bit** (da non nascondere con `[Ignore]`): `Font` (3), `Greed` (7: tabelle `Tan`/`Sin` e piani inclinati), `IdLib.Math` (1: `InvSqrt64`), `IdLib.Text` (1: il lexer legge un reale con 2 ULP di scarto), `Imaging` (1: `WallScale`), `Keen` (1: AdLib in `Extended`), `MathCore` (2: `DivideEx` e `FloatDivide` dipendono dal doppio arrotondamento della FPU), `Models` (1: un vertice delle unioni MD2, `Single` con intermedi a 64 bit), `ScriptHost` (7: la macchina virtuale di PascalScript a 64 bit non esegue le procedure di evento), `VoxelEditor` (15), `XcomDebriefing` (2), `XcomSave` (3), `XcomStrategy` (9: testi di `Double` con un ULP di scarto). Fuori da `Libs\` e da questo giro: `Libs\OpenGl\Legacy` (`gl_lightmaps`, `gl_render`, `gl_tex` usano `integer(puntatore)`) e `Libs\PascalScript\ps_runtime.pas` (`Longint(Ptr)`).

## Aree ancora aperte

- Circa 800 warning di conversione tra `string`, `AnsiString` e `ShortString` (W1057/W1058), firmato/senza segno (W1024) e `Char` negli insiemi (W1050): sistemarli file per file con cast espliciti, non sopprimerli; l'elenco per file è in `logs\REPORT_WARNING.md`. I warning dei cast sugli angoli (W1024) vanno provati con `-timedemo`.
- **Tutto a classi, anche il percorso caldo (issue #185, decisione del 2026-11-12)**: i renderer software e OpenGL, i thinker, la logica di gioco e i savegame non sono più "storici per scelta"; il piano a fasi (strumenti di parità, freddo, logica in un mondo solo, renderer, chiusura) e le regole del percorso caldo (nessuna chiamata virtuale o a interfaccia per colonna, span, pixel, seg o thinker; prestazioni entro il 5% misurate a coppie; un passo che non rispetta parità o prestazioni si annulla) sono in `docs\PIANO_TUTTO_A_CLASSI.md`.
- **Win64, resto da fare (issue #44, 2026-11-13)**: (a) *fotogrammi*: a 64 bit l'aritmetica in virgola mobile è SSE a 64 bit di mantissa 53, a 32 bit è x87 a 64: dove un `round()` cade quasi su metà (`R_MapPlane`: `round(dviewsin * slope)`, `R_ScaleFromGlobalAngle_DBL`, e i calcoli con `float`/`Single`) un pixel o due di un fotogramma rara cambiano (Doom: 11 demo su 21, 1 o 2 pixel su 3-5 fotogrammi di circa 2000-5000; Heretic: 8 su 9; Hexen e Strife uguali in modo 8; Hexen con 1 pixel in modo 32). Lo stato (impronta per tic) è sempre uguale. Per eliminarli servirebbe emulare la precisione estesa nei punti del renderer; non fatto. (b) i salvataggi a 64 bit non sono provati: i record dei salvataggi di Heretic/Hexen/Strife contengono puntatori (`mobj_t`, `player_t`) e `special1/special2` ora sono 8 byte (la serializzazione a tipi `st_integer` ne scrive 4: da verificare), e i `mobj_t11x` dei vecchi formati hanno layout da 32 bit; (c) `I_InitGraphics` con DirectDraw ora crea le superfici, ma i giochi OpenGL, Radix32, SpeedHaste32, Launcher, DD_IDE e DD_Tools non sono stati avviati a 64 bit; `SUC_GetHandle` restituisce un `Integer` (un HWND sta in 32 bit ma non è un `NativeInt`).
- Tracce `-devparm` temporanee dei passi del caricamento del livello di Doom (`TLevelLoader.Trace`, accese da `TDoomLevelRules.TracesSteps`).
- Codice morto (issue #163): tolte 95 routine globali, 17 metodi, 11 variabili e 138 unit inutili dalle clausole `uses` (circa 3830 righe). Restano `P_CheckVisibility` di `p_sight` (direttive incrociate), costanti e tipi senza riferimenti e 44 clausole `uses` con direttive: vedi `docs\PENDING_ISSUES.md` (#163). Per cercarne altro: una routine globale è morta solo se il suo nome non compare in nessun `.pas`, `.dpr`, `.inc` o `.dfm` di nessun progetto (giochi, `ddc_*`, Launcher, DD_IDE, Keen, tutti i `Tests\*`), stringhe comprese (PascalScript, `C_AddCmd`, `DEH_AddAction`).
- Heretic: il crash intermittente (#162) non si riproduce: 93 avvii/uscite senza crash né blocchi (vedi `docs\PENDING_ISSUES.md`, #162); resta aperta solo la chiusura motivata dell'issue.



`Libs\Radix` (issue #169, fetta F2 di **Rad-X**) traduce `RADIX.DAT` (Radix - beyond the void) in un WAD in memoria come il `Radix2WAD_Game` del fork. **Il traduttore e' completo**: 2534 lump su 2534 (2.0 shareware) e 2456 su 2456 (1.0) identici al **vecchio** traduttore (harness `Tools\Verifica\169` sulla copia di `Reference\Rad-X` con le correzioni di `Reference\_analisi\radx_crash.md`, `RadixDiff.exe`), byte per byte e nello stesso ordine, `RADIXINF` compreso. `IRadixContainer` (`NSRes:Radix`), `IRadixPaletteBuilder`, `IRadixTranslator` che esegue una lista di `IRadixPart` (una classe per unit: palette, texture, livelli, flat, schermate, font piccolo, grandi e del terminale, `TRN_MENU`, sprite, musica, cabina, suoni, testi), `TRadixFactory` (`CreateTranslator(TRadixLumpNames)`: i nomi `Original` del fork o quelli `Doom` che il motore legge); patch e WAD in memoria da `Libs\GameData`. Test in `Tests\DelphiDoom.Tests.Radix` (255). Win32 e `Double`; Win64 non provato; i dati 1.1 non ci sono. **Collegato al motore**: `Radix\Radix32.dpr` (`Tools\build.bat Radix\Radix32`, define `DOOM;RADIX`, `_GAME = 'Radix'`, unit di `Doom\`) con `IEngineWadConverter` (`Base\DelphiDoom.Engine.Wad.Converter.Intf.pas`; `W_AddFile` di un `.DAT` chiede al convertitore `TEngineRadixDataConverter`, dato da `ComposeEngine` sotto `{$IFDEF RADIX}`), `TGameAliases` (Radix prende Doom in ogni area tranne Iwad, nuova area `Script`), `igRadix` in `TIwadGames`, `D_AddSystemWAD` che legge `<_GAME>32.swd` (per Radix `Radix32.swd`, copia di `Reference\Rad-X\WADSRC\SYS.wad`). **Ripresa della #169 (2026-11-12)**: piano a tappe dal censimento delle 98 unit del fork (in `Libs\Radix\CLAUDE.md`); classi nuove in `Libs\Radix` (`TRadixEditions`: edizione dal CRC-32; `TRadixLumpAliases`: i nomi di RADIX.DAT da `RADIXINF`; `TRadixMapInfoReader` e `TRadixSlopePlanes`: il lump `RMAP` dei livelli e i piani delle pendenze); lato motore `ComposeRadix` (`Base\DelphiDoom.Engine.Radix.*`), `W_ConfigureAliases` (`IEngineLumpAliases`, generica e inerte per gli altri giochi) e `TRadixLevelRules`; la cartella `Radix\` ha il codice di gioco (`radix_version`, `radix_fonts`, `mn_font`, `radix_map_extra`, e le copie `m_menu` e `st_stuff` che schermano quelle di `Doom\`); rami `{$IFDEF RADIX}` in `hu_stuff`, `am_map`, `st_lib`, `d_main`. **A runtime** (Radix32, RADIX.DAT 2.0 shareware, renderer software): arriva senza `I_Error` alla pagina del titolo e ai menu con le immagini di RADIX.DAT (edizione riconosciuta dal CRC); il menu e' quello di Doom vestito da Radix, non quello del fork. Con `-warp 1 1` il livello si carica fino in fondo (nodi, `RMAP`, cose, precache) e si ferma su `Z_CheckHeap(): Block 1303...`: la zona e' rovinata gia' durante `R_Init` con i dati di Radix (difetto precedente, da trovare). **Il gioco non e' giocabile**: 7 unit del fork su 98 riportate (4 in parte); mancano `mobj_t`/`player_t`, volo, HUD, `radix_actions`, attori, armi, salvataggi (vedi "Stato del gioco" in `Libs\Radix\CLAUDE.md`). Mars3D e' fuori (nessun dato). Gli altri otto eseguibili compilano come prima (`Tools\build.bat giochi`). Le correzioni dei difetti Unicode del fork (`TDStrings.GetTextStr`, `fprintf`, `TWadWriter.AddString`, `GetTempPath`) sono gia nel motore principale. Dettagli: `Libs\Radix\CLAUDE.md`. **Aggiornamento (corruzione della zone)**: il difetto di `Z_CheckHeap` era nelle regioni di colore (`R_InitTranslationTables` leggeva 24 lump dopo `CR_START` ma `Radix32.swd` ne ha 11): corretto con `TColorRegionLumps` (`Libs\Palette`); `Radix32 -warp 1 1` carica E1M1 e si ferma al primo disegno della barra di stato (`STlib_updateBinIcon(): y - ST_Y < 0`).
