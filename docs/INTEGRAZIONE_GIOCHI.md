# Integrazione dei progetti di `Reference\` nel sistema a classi

Sintesi di quattro analisi in sola lettura (nessuna build, nessun gioco avviato). I rapporti completi, con tabelle file per file e righe,
sono in `Reference\_analisi\` (cartella ignorata da git): `mars3d-radx-speed.md`, `strumenti-ddfont-ddvoxel-endedit.md`,
`xgreed-keen.md`, `openxcom.md`. Doom 3 e Quake 3 sono già stati portati (`Libs\IdLib`, `Libs\Collision`, `Libs\Geometry`).
OpenArena contiene solo dati di riferimento per Quake 3 (`MANIFESTO.md`): nessuna analisi di codice.

## Quadro d'insieme

| Progetto | Che cos'è | Natura | Strategia | Lavoro stimato | Rischio principale |
|---|---|---|---|---|---|
| Mars3D, Rad-X, Speed | tre fork di DelphiDoom (sparatutto, sparatutto spaziale, corse) | stesso motore id Tech 1, dati e regole diversi | stesso motore, una cartella di gioco ciascuno, profili iniettati | circa 36 giorni in tutto (comune 2, Mars 8, Speed 12, Radix 14) | dati originali assenti, layout di `mobj_t`/`player_t` diversi |
| DD_FONT, DD_VOXEL, ENDEDIT | strumenti VCL dello stesso autore | strumenti, non giochi | una sola applicazione `DD_Tools` con tre moduli, come `Libs\Ide` | ENDEDIT circa 2 giorni, poi Font, voxel (XL) | Lanczos di Graphics32, macro PascalScript con classi |
| xGreed | port Delphi di Greed (motore Raven) | già Delphi, 33 mila righe | eseguibile separato che riusa le `Libs\` | 13 fette, circa 10-12 giorni (G0-G4 fatte, #175) | BASS, DirectDraw, `.obj`, licenza Raven |
| Keen Dreams | sorgenti C id Software 1991 (DOS 16 bit) | C con 4.194 righe di asm | eseguibile separato `Keen32` | 13 fette, circa 20-25 giorni | asm a 16 bit, wraparound, dati proprietari |
| OpenXcom | clone di UFO/TFTD in C++ (152 mila righe, SDL, yaml-cpp) | C++ non id Tech | eseguibile separato `OpenXcom32` | molti mesi (Battlescape per ultimo) | licenza GPL v3, yaml-cpp, dati originali |

Regola comune: **solo Mars3D, Rad-X e Speed sono id Tech 1** e stanno nel motore attuale. Tutti gli altri non vanno aggiunti a `TIdTechGeneration`
né a `ComposeEngine`: hanno un composition root proprio e condividono le `Libs\` generiche.

## Cosa del sistema è generico e cosa è specifico di Doom

Riusabile da qualunque progetto: `Clock`, `Logging`, `Platform`, `CommandLine`, `Configuration`, `Screenshot`, `Png`, `Zlib`, `Jpeg`,
`MathCore` (`TCrc32`, `TFixedMath`), `Input` (i dispositivi: la mappa dei tasti è di Doom), `Palette`, `Video`, `Imaging`, `Sound`/`Sndfile`/`Mikmod`/`Midi`/`Audio`
(i dispositivi e i decoder; il mixer di giochi non Doom va riscritto), `Scanner` (testi), `Threading`, `Console`.

Specifico di Doom (non si riusa fuori dai fork): `Wad` (regole di lump e marcatori), `Zone`, `Thinkers`, `Blockmap`, `Nodes`, `Udmf`, `Acs`, `Specials`,
`Dehacked`, `ActorDef`, `MapInfo`, `Serializer` dei record, `Net`, `Renderer`, e `ComposeEngine`.

## 1. Mars3D, Rad-X, Speed (fork di DelphiDoom)

**Fatti.** Fork di 2.05-2.06 (il repository è 2.07), GPL v2+. Restano id Tech 1 e compilano con `DOOM`. Rad-X e Speed differiscono per meno di 3,5 mila righe
su 251 mila: la differenza è quasi solo la data del fork. Le librerie vecchie (AUDIOLIB, MIKWIN, JPEGLIB, MP3LIB, ZLIB, C_LIB) sono già sostituite da `Libs\*`.
Il codice nuovo è per gioco: Mars 27 unit (12 mila righe), Radix 36 (32 mila), Speed 30 (12 mila), più 4-8 unit in `Base\`, `Libs\OpenGl\Legacy\`, `Libs\ScriptHost\`.

**Che cosa è nuovo.**
- Un traduttore dei dati originali (`mars.mad`, `radix.dat`, `speedh.jcl`) in un WAD in memoria.
- Le regole di gioco, con `mobj_t` e `player_t` diversi da Doom (quindi anche savegame e tabelle di `Libs\Serializer`).
- Rendering o formati propri: sott'acqua, ANM/FLC e vetro rotto in Mars; trigger e azioni (`radix_actions`, 2.866 righe), campi di forza, texture `.RADIX32` in Radix; fisica e IA delle auto, percorsi, mappe a tessere, modelli I3D, `r_soft3d` in Speed.

**Come integrarli.**
1. Stesso motore, cartelle `Mars\`, `Radix\`, `Speed\` e cinque eseguibili (`Mars32`, `GLMars32`, `Radix32`, `GLRadix32`, `GLSpeed32`).
2. Si portano **solo le differenze rispetto a `Doom\` attuale**, non le circa 110 unit derivate dei fork.
3. I giochi si distinguono con profili iniettati (`_GAME = 'Mars'|'Radix'|'Speed'`), non con nuovi `{$IFDEF}`: alias al profilo Doom nelle 11 librerie a profilo
   (Dehacked, Udmf, Iwad, ActorDef, TableExport, Definitions, Thinkers…) e un `*Rules` per gioco nel caricamento del livello. `Libs\IdTech` resta `IdTech1`; basta un costruttore con nome e versione.
4. Soffitti, pavimenti, piattaforme, luci e teletrasporti sono quasi identici a Doom: riusano il profilo Doom di `Libs\Thinkers`.
5. Da estendere: `Libs\Wad` (contenitori `NSRes:Radix` e JCL; il `.mad` di Mars si apre già come WAD), `Libs\Texture` (decoder `.RADIX32`), `Libs\Models` (I3D), `Libs\Serializer` (tabelle per gioco).
6. Librerie nuove: `Libs\GameData` (comune; il costruttore di patch esiste in tre copie nei fork), `Libs\Mars`, `Libs\Animation`, `Libs\Radix`, `Libs\RadixLogic`, `Libs\Speed`, `Libs\Racing`.

**Ordine.** Comune F0-F4 (circa 2 giorni), Mars M1-M7 (8), Speed S1-S6 (12, con `r_soft3d` opzionale perché Speed è solo OpenGL), Radix R1-R7 (14).

**Rischi.** I campi `packed array of char` dei record originali diventano 2 byte in Delphi 11 (5 punti in Radix, 1 in Speed, 1 in Mars): vanno in `AnsiChar`.
Speed ha `double` nel `mobj_t` e fisica con x87 contro SSE (determinismo); i buffer da 16 e 64 MB pesano a Win32. `m_compress` (due blocchi `asm`) sembra inutilizzata.

**Verifica.** Parità byte per byte di traduttori e lettori di contenitore contro il vecchio codice; demo e savegame identici; `-timedemo` dei giochi esistenti invariato; copertura almeno 90%; prestazioni entro +5%.
**I dati originali non sono nel repository né in `bin\`**: senza di essi la parità dei traduttori non si prova (resta "non verificata").

**Stato (issue #166, 2026-11-09).** Fatte F0 (`Libs\GameData`: costruttore di patch unico per i tre fork e WAD in memoria, parità sulle tre copie vecchie), F1 (`TGameAliases`: Speed prende il profilo di Doom in tutte le aree tranne Iwad; `ComposeEngine` lo usa; il resto per aggiungere un gioco è in `Libs\GameData\README.md`), S1 e S2 (`Libs\Speed`: contenitore `SPEEDH.JCL` e traduttore in un WAD, parità su 1664 righe di lump dello shareware vero e su un gioco sintetico). Fatta S3 (issue #168: `DelphiDoom.Models.I3d.*` in `Libs\Models`, parser, correzioni e disegno su `II3dRenderTarget`; parità sui 50 modelli dello shareware, adattatore OpenGL del motore non ancora scritto). Fatta S4 (issue #168: `Libs\Racing`, auto, fisica, IA, percorso, giri, classifica, griglia e tabelle dei tempi di `speed_cars`, `speed_path`, `speed_race`, `speed_score`, `speed_particles`, `speed_championship`; il `double` del `mobj_t` resta in un `TRacingCarState` che il gioco copia da e verso l'oggetto; parità con il vecchio codice compilato in un harness a partire dai sorgenti originali, 0 differenze su 111 righe di scenari, 187 test; compila a 64 bit, la parità è solo a 32). Iniziata S5: la cartella `Speed\` ha `Speed32` (`Tools\build.bat Speed\Speed32`, programma di prova senza finestra né motore che traduce `SPEEDH.JCL` e fa correre le auto del computer sui lump veri dello shareware, E1M1 ed E1M2, senza errori e senza riferimento dal vecchio gioco). Non fatte: F2-F4 (profili veri per Mars e Rad-X, `.dpr` dei cinque eseguibili, Launcher e DD_IDE), il resto di S5 (il gioco: `mobj_t`/`player_t`, azioni, HUD, menu, record su disco, savegame, `m_base`/`TSpeedLevelRules`/profilo Iwad, adattatore OpenGL dei modelli), S6 (`r_soft3d`), e tutto Mars3D e Rad-X.

## 2. DD_FONT, DD_VOXEL, ENDEDIT (strumenti)

**Fatti.** Delphi 7 con la VCL, GPL v2+, versioni 1.0.1.12, 1.7 e 1.0.1.9. Codice proprio: ENDEDIT circa 5.700 righe, DD_FONT circa 6.000, DD_VOXEL circa 26.000. Molte terze parti (FastMM4, Graphics32 circa 55 mila righe, SynEdit, PascalScript, dglOpenGL, pngimage, zlib con `.obj`).
Infrastruttura triplicata (`ee_`, `ff_`, `vxe_`): undo con flussi compressi, file recenti, impostazioni, scrittore e lettore di WAD e ZIP.

**Già presente.** ENDEDIT è quasi tutto in `Libs\Endoom` (stesso formato da 4.000 byte, 16 colori, renderer; attenzione al parametro del blink, invertito). I formati voxel in lettura (DDVOX, KVX, VOX, DDMESH) sono in `Libs\Voxel` (nel vecchio codice copiati 3-4 volte). Undo, WAD, PNG e thread sono coperti da `TIdeUndoHistory`, `Libs\Wad`, `Libs\Png`, `Libs\Threading`.

**Mancante.**
- ENDEDIT: modello modificabile (`DelphiDoom.Endoom.Screen`), strumenti di disegno, conversione immagine→testo (5 metodi), Lanczos (`DelphiDoom.Imaging.Resampler`, per eliminare Graphics32).
- DD_FONT: rasterizzazione del testo (GDI, da mettere dietro `IFontRasterizer`), `DelphiDoom.Imaging.PatchWriter`, le 6 palette di gioco (`DelphiDoom.Palette.GamePalettes`, servono anche a DD_VOXEL).
- DD_VOXEL: tutte le scritture (DDVOX, DDMESH con ottimizzatore dei quad, slab6), quantizzatore octree, editing del cubo, rotazione, sprite multi-angolo, macro PascalScript.

**Come integrarli.** Una sola applicazione `DD_Tools`, separata da `DD_IDE`, con tre moduli (Endoom, Font, Voxel), ciascuno con presenter, interfaccia di vista e form sottile (come `Libs\Ide`); composition root `DelphiDoom.Tools.Composition`; servizi Windows (GDI, dialoghi, clipboard, OpenGL) in `DD_Tools\DelphiDoom.Tools.Win.*`.
Nuova `Libs\ToolsCore` per il codice triplicato (undo generico su `TBytes`, file recenti, impostazioni, avanzamento, backup, `IArchiveWriter`) e nuova `Libs\Font`.
Percorso minimo di valore: ToolsCore → palette → `PatchWriter` → `Endoom.Screen` → modulo Endoom (circa 2 giorni), poi Font, scrittori voxel, editing, editor voxel (XL).

**Problemi.** 64 bit e Unicode: `char8_t = array of char` diventa 16 byte e rompe `filelump_t`; `ZipCRC32` calcola su `string`; `integer(p)` per i puntatori; asm in `xDIB` e `vxe_rotate`; `.obj` OMF; overflow di `Integer` nel Perlin.

**Decisioni aperte (7).** Licenza del TTF "DooM" incorporato ("FREEWARE… not for comercial use": non è GPL); sorte dell'export LDD (circa 5.000 righe di LEGO: consiglio di lasciarlo fuori); parità del Lanczos; macro con classi (`Libs\Script` ha deciso di non fare il ponte verso `TPSRuntimeClassImporter`, #19: serve un adattatore o funzioni piane); decoder GIF/PPM; spostare `IIdeArchive` e `TIdeUndoHistory` in `ToolsCore` (tocca DD_IDE e i suoi 264 test); destino dei repository SourceForge.
**Da verificare:** che la tabella DOSFONT di ENDEDIT coincida con quella dei `*32.swd` (golden).

**Stato DD_FONT (issue #167, 2026-11-09).** Fatto: Libs\Font (modello, rasterizzatore dietro interfaccia, colorizzazione, Perlin, esportazione, WAD), TGamePalettes in Libs\Palette, TImagingPatchWriter in Libs\Imaging, Libs\FontEditor (presenter e viste) e il modulo Font di DD_Tools (finestra, servizi Windows, composition root); parità con il vecchio codice su 360 esportazioni, 360 testi, 40 griglie, 40 patch, 1000 valori di Perlin, 16,7 milioni di grigi e 6 WAD (Tests\Data\README.md). Il TTF DooM incorporato non e stato portato (licenza non GPL: decisione 1 ancora aperta). Il difetto dello stretch del vecchio (ogni pixel non nero a 255 quando il massimo e sotto 255) e il grigio in Extended sono conservati; il caricamento del progetto dalla riga di comando non viene piu azzerato. Resta DD_VOXEL (fette 8-13 della tabella del rapporto) e ENDVIEW.

## 3. xGreed

**Fatti.** Port Delphi di "In Pursuit of Greed" (motore Raven 3D): 29.007 righe in `Greed\`, 4.265 proprie in `Base\`, più terze parti (`DirectX.pas` 16.017, `pngimage` 5.329, BASS, zlib con 12 `.obj`). Mondo a griglia 64x64 con fixed 16.16, mappa di 18 piani da 4096 byte (`utils.pas:450-491`), renderer a 8 bit con conversione a 32 bit via DirectDraw. Dati in `GREED.BLO` (intestazione da 10 byte, tabella lump da 12 byte, `d_disk.pas:30-47`). Salvataggio: un solo `player_t` packed senza puntatori. Gli `asm` sono pochi e hanno già l'alternativa Int64.

**Licenza.** Intestazioni GPL v2+, ma il codice Raven è (c) Softdisk 1996 e non c'è un LICENSE: **da chiarire con l'autore**. BASS è incompatibile con una distribuzione GPL.

**Riuso.** `Png`, `Zlib`, `Screenshot`, `MathCore`, `Input`, `Clock`, `Palette`/`Video`, `Configuration`/`CommandLine`; effetti con `Sndfile`+`Audio`, **musica con `Libs\Mikmod` al posto di BASS** (il loader S3M esiste; nessuna parità bit a bit, solo a orecchio).
**Nuovo:** `IGreedArchive` per il BLO (`Libs\Wad` ha regole Doom e non va bene), `IFramePresenter` per il blit, `ITickScheduler`, `Libs\Greed`, `Libs\GreedRender`, `Libs\Fli`.

**Come integrarlo.** Eseguibile separato, già Delphi: portarlo a classi con DI e togliere BASS e DirectDraw. 13 fette G0-G12 (circa 10-12 giorni); le più grosse G10 (mondo e logica, XL) e G11 (renderer e FLI, L+M). Verifica con golden dal vecchio codice: lump, piani, `renderbuffer` per pose fisse, stato dopo N tic, byte del salvataggio.
**Dati necessari (non nel repository):** `GREED.BLO`, `SONG*.S3M`, opzionalmente `MOVIES\*.FLI`. Da verificare: layout fine di walls, sprite e flat del BLO, uso del campo `compress`, formato dei lump sonori, multiplayer.

**Stato (issue #175, fette G0-G4 fatte).** `Libs\Greed` + `Greed\Greed32` (eseguibile a parte, composition root `Greed\DelphiDoom.Greed.Composition.pas`): archivio `GREED.BLO` (`IGreedArchive`), correzione `pst`, mappa a 18 piani (`TGreedMap`, `TGreedMapLoader`: lump o file `.LAY` delle demo), palette e decoder di immagini, flat, muri e sprite, e `Greed32 -data <cartella> [-list] [-map N] [-lump nome] [-png file]` che salva mappe e immagini come PNG (solo prova visiva). Verifica: golden del **codice originale** compilato in un harness (`Tools\Verifica\175\GreedGolden.dpr`, `Tests\Data\Greed`) sulle demo 1.016 e 2.0, zero differenze; 169 test, copertura 100%. **Chiarito dai dati veri:** il campo `compress` e' 0 in ogni lump di entrambe le demo (l'originale non lo legge); walls, sprite, flat e immagini hanno i layout descritti in `Libs\Greed\README.md`; nelle demo i lump delle mappe sono vuoti e le mappe sono file `LEVELn.LAY` da 73728 byte (demo 2.0) o `*.LVL` da 143360 byte (demo 1.016: altro layout, non letto). **Ancora da fare:** G5-G12 (effetti e musica, `TFixedMath`, salvataggi, configurazione, mondo e logica, renderer e FLI, `IFramePresenter`, Win64); ancora aperti la licenza del codice Raven e BASS (non usato dalle fette fatte), il formato dei lump sonori e il multiplayer.

## 4. Keen Dreams

**Fatti.** Sorgenti C id Software 1991 per Borland C 2.0 (DOS, 16 bit, large model), GPL v2+: 31.102 righe, di cui 4.194 di asm più asm inline. Dati di gioco proprietari; i `static\*.KDR` sono inclusi e redistribuibili.
Motore a manager `id_*` (`mm`, `ca`, `vw`, `rf`, `in`, `sd`, `us`); tile 16x16 su 3 piani con coordinate `unsigned` a 16 bit in cui il wraparound fa parte del comportamento; 213 `statetype`; grafica EGA planare con sprite pre-shiftati.
Formati: `KDREAMS.EGA/MAP/AUD`, mappa = Huffman poi RLEW (`id_ca.c:309,524,1436`). Il salvataggio scrive `gamestate`, i piani e gli `objtype` grezzi con puntatori (`kd_demo.c:199-300`): serve un formato nuovo.

**Riuso.** `Input`, `Clock`, `Platform`, `Audio`/`Sound` (digitalizzati), `Palette`/`Video`. **Nuovo:** Huffman e RLEW, `IKeenChunkSource`, framebuffer EGA, tile map e sprite manager, `ID_US`; l'AdLib richiede un emulatore OPL2 che oggi non esiste (`Libs\Opl`, lo stesso che serve a OpenXcom). `ID_MM` non si porta.

**Come integrarlo.** Eseguibile separato `Keen32` con `Libs\Keen` e composition root proprio; **non** estendere `TIdTechGeneration` (Keen non è id Tech 1). Traduzione con l'agente `c-to-delphi-translator`. Trappole: `int`/`unsigned` a 16 bit, puntatori far, tabelle di stati con puntatori a funzione, asm. **`bcc32c` non compila l'asm a 16 bit**: gli oracoli vanno scritti a mano in C o presi da DOSBox.
Fette K0-K12 (circa 20-25 giorni); giocabile senza AdLib in circa 12 giorni (K0-K9); le più pesanti K6 (sprite e scroll), K8 (gioco a classi), K10 (OPL2), tutte XL.
**Stato (issue #165): K0-K7 fatte, il motore dei livelli di K8 e le azioni degli stati (K8b)** in `Libs\Keen` e `Keen\Keen32` (Huffman, RLEW, file a chunk, mappe, tile, EGA planare → pixel, PNG della mappa; memoria video EGA, `ID_VW`, `ID_RF` con scroll, animazioni e sprite; input e demo; oggetti, stati, clipping, scansione del piano info e ciclo dei frame di `kd_play.c`, tabella dei 213 stati generata dal C), 608 test (copertura 93%): parità con `kdgold.exe` sui dati shareware 1.13 per K0-K4, e per K5-K6 la schermata dopo ogni scroll uguale alla mappa intera sui 18 livelli veri; K8b: le 67 funzioni think/contact/react di `kd_keen.c`, `kd_act1.c` e `kd_act2.c` e i `Spawn*` (giocatore, scatola dei punti, nemici) a classi dietro `TKeenGameActions`, **uguali all'originale** (harness C compilato con Open Watcom a 16 bit ed eseguito in DOSBox, 1980 scenari, `Tools\Verifica\165`; fuori dal confronto `ScoreThink`/`FixScoreBox`, i `Spawn*` e la fisica); K9: l'altoparlante del PC e il gestore dei suoni con la priorita' (`TKeenPcSpeaker`, `TKeenSoundManager`; nessuna musica in Keen Dreams); restano K10 (AdLib, serve un emulatore OPL2), K11-K12 (ID_US, salvataggi, schermate). Dettagli in `Libs\Keen\README.md`.
**Dati mancanti:** `KDREAMS.EGA`, `KDREAMS.MAP`, `KDREAMS.AUD` (e `KDREAMS.CMP`), coerenti con i `static\*.KDR` (versione 1.93 EGA).

## 5. OpenXcom

**Fatti.** Clone di UFO: Enemy Unknown e Terror from the Deep in C++11 con SDL 1.2, yaml-cpp, SDL_mixer e SDL_gfx. Circa 152.400 righe in `src\` (più 6.900 di `lodepng`) e 105 file `.rul` YAML (circa 29.900 righe). Per sottosistema: Engine 33.315, Battlescape 32.078, Savegame 24.048, Mod 16.472, Geoscape 14.148, Basescape 13.213, Menu 9.093, Interface 6.767, Ufopaedia 3.232.
Ciclo a stati (`Game::run`, `Game.cpp:143`), rendering software a 8 bit con palette (`Surface`, shader template di blit), regole YAML (`Mod::loadFile`, `Mod.cpp:1145`), salvataggi in YAML più un convertitore dei binari originali. Formati originali semplici e in sola lettura: PCK/TAB, SCR, SPK, BDY, DAT, `.CAT`, MAP (`BattlescapeGenerator.cpp:1560`), RMP (`:1694`), MCD, `WORLD.DAT`, FLC.

**Licenza.** GPL v3 o successiva (`fmopl` LGPL 2.1, `lodepng` zlib) contro GPL v2+ del repository: **decisione dell'utente prima di scrivere derivati**.

**Riuso.** Diretto: `Clock`, `Logging`, `Platform`, `CommandLine`, `Screenshot`, decoder audio, `Png`/`Zlib`/`Jpeg`, dispositivi di `Input`. Parziale: `Video` (palette a 6 bit), `Imaging`/`Palette`, `Audio` (il mixer va riscritto), `Wad` (solo come idea per i `.CAT`), `Input` (mappa tasti di Doom).
Non riusabili: `Scanner` per il YAML, `Configuration`, `Console`, `Net`, `Zone`, `Thinkers`, `Renderer`.
**Nuove:** Yaml, XcomFormats, XcomSurface, XcomMod, XcomSave, XcomUi, Geoscape/Basescape/Battlescape, Opl, Flic.

**Come integrarlo.** Eseguibile separato `OpenXcom32.dpr`, non un quinto gioco del motore. Traduzione: classi con interfacce al posto di SDL, `TObjectList` e dizionari ordinati al posto di `std::map`, `IYamlNode` al posto di `YAML::Node`; gli shader di blit diventano procedure specializzate. Trappole: `char` con segno nell'intestazione dei `.MAP`, `float` nel globo, `std::sort` non stabile, ordine osservabile di `std::map`/`std::set`.
**Verifica.** Compilare tutto il C++ con `bcc32c` non è realistico (mancano yaml-cpp, SDL è in `.lib` MSVC, nessun `cl`/`g++`/`clang`/`cmake`). Fattibile: un harness fuori dal repository sulle foglie pure (loader PCK/SCR/SPK/BDY, palette, MAP/RMP, RNG) con un `SDL_Surface` finto. La logica tattica richiede scenari registrati da una build originale.
**Dati:** `bin\UFO` e `bin\TFTD` contengono solo un `README.txt`: servono i file originali dell'utente, esclusi dal repository.
**Stato (issue #176): prima fetta fatta** in `Libs\XcomFormats` e `OpenXcom\Xcom32`: PCK/TAB, DAT, SCR, SPK, BDY, `PALETTES.DAT`, CAT, MAP (con il `char` con segno), RMP, MCD, `WORLD.DAT` e `LOFTEMPS.DAT` come classi, un programma che salva PNG (sprite, schermi, un piano di mappa con i nodi), 196 test (copertura 99%) con parità sul C++ di OpenXcom compilato con g++ MinGW (3600 righe di golden su file pseudo casuali, 0 differenze in Win32 e Win64). Non provato su dati veri (non sono sul PC). Il codice deriva da OpenXcom (GPL v3 o successiva): la licenza dell'opera resta da decidere (`Libs\XcomFormats\README.md`). Resta: `Libs\Yaml`, `XcomSurface` (`Surface8`) e `Opl`, stati e UI, `XcomMod`, salvataggi, Geoscape, Basescape, Battlescape.
**Prima fetta proposta:** leggere palette, uno SCR, un PCK/TAB e un MAP con i nodi RMP, e salvarli come PNG con `Libs\Png` (niente YAML, SDL né finestra). Poi Yaml (L-XL), Surface8 e Opl (L), stati e UI (L), Mod (XL), audio (M), salvataggi (XL), Basescape e Geoscape (XL ciascuno), Battlescape (XL x2-3, il più rischioso, per ultimo).

## Librerie nuove condivise tra più progetti

- `Libs\Opl` (emulatore OPL2/AdLib): Keen Dreams, OpenXcom; già presente `fmopl` (LGPL) in OpenXcom.
- `Libs\Flic` (animazioni FLI/FLC): xGreed, Mars3D (FLC), OpenXcom (FLC).
- `Libs\GameData` (costruttore di patch e di WAD in memoria): Mars3D, Radix, Speed, DD_FONT, DD_VOXEL (`PatchWriter`).
- Archivi non-WAD (`IGreedArchive`, contenitori `.CAT`, `NSRes`, JCL): un'interfaccia comune sopra le regole di `Libs\Wad`.
- `Libs\ToolsCore` (undo, file recenti, impostazioni): DD_FONT, DD_VOXEL, ENDEDIT e, a conti fatti, DD_IDE.
- Palette di gioco (`DelphiDoom.Palette.GamePalettes`): DD_FONT, DD_VOXEL, Keen (EGA), OpenXcom.

## Fetta 0 di ogni progetto: l'originale come prova di riferimento

Prima di scrivere una riga, per ogni progetto con i dati disponibili si compila e si esegue **l'originale** di `Reference\` e se ne conserva la prova:

1. **Dati:** trovare i dati originali (vedi elenco nelle decisioni) e verificarli (dimensione, hash, versione).
2. **Compilare l'originale in una copia** (mai dentro `Reference\`, che resta intatta): fork Delphi e xGreed con `C:\Strumenti\delphi-build.cmd` (Delphi 11, Win32; i vecchi `.dof`/`.dpr` di Delphi 7 possono richiedere correzioni minime, da elencare), Keen con un compilatore DOS (Borland C 2.0 o equivalente) e DOSBox, OpenXcom con CMake e SDL, se disponibili.
3. **Eseguire e registrare la prova:** screenshot, un percorso fisso (livello, mappa, demo registrata se il gioco le ha), i file scritti (salvataggi, log), tempi di avvio. Per i fork di DelphiDoom, anche un `-timedemo` o una demo se esiste.
4. **Rapporto:** cosa compila e cosa no (con gli errori), cosa gira, cosa manca (dati, compilatore, DLL), e cosa si può congelare come *golden* per la parità futura (dump dei lump tradotti, byte dei salvataggi, impronte dello schermo).

Esito: ogni progetto ha uno stato *compila/gira/prova registrata* oppure *bloccato da: …*. Un progetto senza dati resta fermo alla fetta 0 e non si passa alla fetta 1.

## Ordine consigliato

1. **ENDEDIT in `Libs\Endoom` + `DD_Tools`** (circa 2 giorni, valore immediato, quasi tutto già nelle librerie).
2. **Mars3D** (8 giorni, dopo la fetta comune): è il fork più vicino al motore attuale e dimostra il meccanismo dei profili.
3. **Speed e Radix** (12 e 14 giorni) solo dopo aver visto Mars funzionare.
4. **xGreed** (10-12 giorni): già Delphi, riuso alto, e produce `Libs\Fli` e l'archivio non-WAD.
5. **Keen Dreams** (20-25 giorni) e **OpenXcom** (mesi): progetti a sé, da affrontare solo con i dati originali sul PC.

## Decisioni da prendere prima di iniziare

1. **Dati originali:** quali sono sul PC (Mars `mars.mad`, Radix `radix.dat`, Speed `speedh.jcl`, `GREED.BLO`, `KDREAMS.*`, UFO/TFTD). Senza, nessuna parità dei traduttori.
2. **Licenze:** GPL v3 di OpenXcom contro GPL v2+; Raven/Softdisk e BASS in xGreed; TTF "DooM" di DD_FONT.
3. **Perimetro:** tutti e tre i fork o solo Mars; `r_soft3d` di Speed sì o no; export LDD di DD_VOXEL fuori.
4. **Nomi degli eseguibili** e politica degli alias ai profili Doom nelle 11 librerie a profilo.
5. **Macro dei voxel:** adattatore PascalScript in-process oppure funzioni piane (si perde la compatibilità con gli script esistenti).

## Risultati della fetta 0 (2026-11-08/09)

Rapporti completi in `Reference\_analisi\fetta0.md`, `openxcom_build.md` e `keen_build.md`; dati e strumenti scaricati in `Reference\_dati\` (registro con URL, byte, SHA-256 e licenza in `MANIFEST.md`; cartella ignorata da git).

| Progetto | Compila | Gira | Dati | Stato |
|---|---|---|---|---|
| ENDEDIT, ENDVIEW | sì (9 avvisi) | sì, 15 s, screenshot | non servono | prova registrata |
| DD_FONT | sì | difetto reale dell'originale: `GetTempPath(SizeOf(buf), buf)` passa byte per un buffer di caratteri (`ff_tmp.pas:66`, uguale in `i_tmp.pas:111` dei fork) | non servono | con `Length(buf)` parte |
| DD_VOXEL | sì (61 avvisi) | sì (senza argomenti) | non servono | un controllo di nil mancante in `UpdateEnable` |
| Mars3D | sì (797 avvisi) | si ferma su "Locate data file" | `MARS.MAD`: solo gioco completo, non scaricato | bloccato dai dati |
| Rad-X | sì (circa 620 avvisi) | esce con access violation in FastMM4 | `RADIX.DAT` 2.0 shareware ottenuto (CRC riconosciuto) | da indagare |
| Speed | sì (593 avvisi) | legge `SPEEDH.JCL`, poi `stringtochar8(): length of WALL... > 8` (ANSI letto come UTF-16) | shareware ottenuto | difetto Unicode del port |
| xGreed | sì (128 avvisi) | la demo 2.0 carica e resta viva; la 1.016 no; schermo DirectDraw non catturabile | demo ottenute, `bass.dll` ottenuto | prova parziale |
| Keen Dreams | sì, con Open Watcom v2 (17 `.c`, 4 `.asm` convertiti in MASM, 27 file corretti) | sì in DOSBox con i dati 1.13: titolo, pannello, mappa del mondo identica all'originale | shareware 1.13; `MAPHEAD`/`MAPDICT` estratti dall'EXE con un unpacker LZEXE | con riferimenti (`kdgold.exe`: CRC dei piani, `pictable`, tile8, `tileinfo`) |
| OpenXcom | sì, con MinGW-w64 portatile (3 correzioni alla copia, yaml-cpp 0.7.0, SDL_gfx 2.0.26) | si ferma con "No X-COM installations found", come il nightly ufficiale | solo commerciali (Steam/GOG) | compilato, senza dati |

Fatti di rilievo per le fette 1:
- **Difetti trovati negli originali** (da non ereditare nel port): `GetTempPath` con byte al posto di caratteri nei fork e in DD_FONT; testo ANSI letto come UTF-16 in `stringtochar8` di Speed; date di build e log troncati nei fork per la stessa causa.
- **Mars3D e Rad-X**: servono acquisti (`MARS.MAD`; Radix completo) per andare oltre; per Rad-X la versione shareware 2.0 si legge ma l'originale si ferma su un crash da indagare.
- **Keen**: sorgente 1.93 e dati shareware 1.13 coincidono per grafica e audio; le mappe 1.13 richiedono `MAPHEAD`/`MAPDICT` estratti dall'EXE.
- **OpenXcom**: l'originale compila in circa 3 minuti con la toolchain portatile; senza dati UFO/TFTD non si va oltre il controllo dei file.
- Il rapporto elenca ancora cosa serve all'utente: giocare Keen e Greed a mano, decidere su Mars (acquisto), dati commerciali per UFO/TFTD.
