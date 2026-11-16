# Games\Greed

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Port in classi di **xGreed**, il source port Delphi di Jim Valavanis (2020-2022; licenza: vedi sotto, **non risolta**) di **"In Pursuit of Greed"** (Softdisk / Channel 7, 1996, motore "Raven 3D", disegno di John Carmack). Sorgenti originali in `Reference\xGreed` (non si modificano); issue #175.

Non e' un gioco del motore Doom: ha il suo eseguibile (`Games\Greed\Greed32.dpr`, composition root `Games\Greed\DelphiDoom.Greed.Composition.pas`, `Tools\build.bat Games\Greed\Greed32`, output `bin\Greed`) e **non tocca** `ComposeEngine` ne' `TIdTechGeneration`. Riusa `Framework\Video` (`IPaletteConverter`), `Framework\Png` (`TPngClient`), `Framework\Platform` (`IFileStore`) e `Framework\MathCore` (`TCrc32`).

## Licenza: stato esatto (2026-11-14) — NON risolta

Cosa dice il sorgente che abbiamo (`Reference\xGreed`, 45 file `.pas`, verificato file per file):

- **Non c'e' un file di licenza** (`LICENSE`, `COPYING`) e il `README.md` di xGreed non nomina nessuna licenza.
- **10 unit hanno il testo della GPL v2 o successiva** ("License applies to this source file", copyright 2020-2022 Jim Valavanis): `IdTech1\Base\g_delphi`, `g_fixlump`, `i_main`, `i_video`, `i_windows`, `m_crc32`, `m_screenshot`, `scriptengine`, `Games\Greed\m_defs`, `Games\Greed\r_interpolate`. Sono il codice scritto da Valavanis per il port (finestra, video, configurazione, interpolazione, correzione dei lump).
- **Le 28 unit del gioco in `Games\Greed\`, `LaunchXG\main` e `xGreed.dpr` non hanno nessun testo di licenza**: `Games\Greed\raven`, `utils`, `spawn`, `sprites`, `event`, `display`, `menu`, `intro`, `net`, `modplay`, `playfli`, `constant`, `protos_h`, `timer`, `d_disk`, `d_font`, `d_ints`, `d_ints_h`, `d_misc`, `d_video`, `r_conten`, `r_plane`, `r_public`, `r_public_h`, `r_refdef`, `r_render`, `r_spans`, `r_walls`. Hanno solo l'intestazione "xGreed (C) 2020-2022 by Jim Valavanis / Raven 3D Engine (C) 1996 by Softdisk Publishing / Original Design: John Carmack of id Software / Enhancements by: Robert Morgan of Channel 7, Todd Lewis e John Bianca of Softdisk Publishing, Carlos Hasan". E' un avviso di copyright, non una licenza.
- Di terzi: `IdTech1\Base\bass.pas` (BASS di Un4seen, licenza proprietaria: non usato, sostituito da `Framework\Mikmod` e dal mixer), `IdTech1\Base\DirectX.pas` (JEDI), `IdTech1\Base\pngimage.pas`, `FASTMM4`, `zlib` (nessuno e' portato).

Cosa ne segue per questa libreria:

- Quasi tutto `Games\Greed` e' il port delle 28 unit del gioco **senza licenza** (logica, renderer, HUD, menu, rete). Le intestazioni delle nostre unit dicono "Port of xGreed (Jim Valavanis, GPL v2 or later)": **per quelle unit il sorgente non lo dice**. E' vero solo per cio' che viene dalle 10 unit con il testo della GPL (`Settings*` da `m_defs`, `LumpFixes`/`PstCorrection` da `g_fixlump`, `Render.SpriteInterpolator` da `r_interpolate`, `ScriptScanner` da `scriptengine`).
- **Cosa manca**: una dichiarazione di chi ha i diritti sul codice Raven 3D del gioco (Softdisk Publishing o chi ne ha rilevato i diritti; Channel 7 / Robert Morgan per la parte sua) che lo metta sotto la GPL v2 o successiva o sotto una licenza compatibile, e la conferma di Jim Valavanis che la sua traduzione in Pascal di quelle unit e' sotto la stessa licenza. Senza, la distribuzione di `Games\Greed` e di `Greed32` come GPL non ha un fondamento scritto.
- **Cercato in rete il 2026-11-14, senza trovare una licenza**: una discussione pubblica (forum Duke4.net, dicembre 2014) riferisce che il sorgente originale e un port per Windows incompiuto furono pubblicati sul sito dello sviluppatore, e nella stessa discussione la licenza dei dati e' detta "da chiarire"; le pagine di xGreed (SourceForge) non dichiarano una licenza per il codice del gioco. Queste sono notizie di seconda mano, non verificate sul sorgente originale, che non e' in `Reference`.
- I dati del gioco (`GREED.BLO`, musiche, filmati) sono proprietari e **non sono nel repository** (ci sono solo i numeri dei golden); `DelphiDoom.Greed.PstCorrection` e' la copia dei 10463 byte di `pst_corrected` di `g_fixlump.pas` (unit con la GPL).
- **Non e' una cosa che il codice puo' risolvere**: va chiesto agli autori (decisione dell'utente). Fino ad allora la libreria resta nel repository come lavoro di port con questa avvertenza.
## Stato: fette G0-G4 (issue #175; l'elenco completo e lo stato sono sopra e in CLAUDE.md)

| Fetta | Fatto | Dove |
|---|---|---|
| G0 | struttura, tipi packed con `SizeOf` coperto, eccezioni, fixed 16.16 | `Types`, `Intf`, `Factory`, `LittleEndian` |
| G1 | `IGreedArchive`: il contenitore `GREED.BLO` (intestazione da 10 byte, tabella da 12, nomi C), lump per nome e per indice, correzione dei dati | `BloArchive`, `LumpFixes`, `PstCorrection` |
| G2 | la mappa: 18 piani da 4096 byte, caricamento dal lump o dal file `.LAY` | `Map`, `MapReader`, `MapLoader`, `FolderFiles` |
| G3 | palette VGA e decodifica di immagini, flat, muri e sprite verso un buffer a 8 bit | `Palette`, `PictureDecoder`, `FlatDecoder`, `WallDecoder`, `SpriteDecoder`, `LumpClassifier` |
| G5 | effetti sonori e musica senza BASS (dettagli in CLAUDE.md) | `Sound.Intf`, `TrigTables`, `SoundGeometry`, `SoundEffects`, `Music`, `SongSelector`, `SoundVolumes`, `AudioDevice` |
| G6 | aritmetica in virgola fissa | `FixedMath` |
| G7 | salvataggi: `player_t` packed, directory dei nomi | `SaveTypes`, `Save.Intf`, `SaveGames`, `SaveFolder` |
| G8 | le 42 impostazioni di `m_defs`, file `xGreed.ini` | `Settings.Intf`, `Settings`, `SettingsStore` |
| G9 | il mondo: piani, flag, porte, spawn, pendenze, altezza di pavimento e soffitto | `World.Intf`, `World`, `Slopes`, `Terrain` |
| G10 (primo pezzo) | regole del giocatore: cura, danno, punteggio, nuova partita | `Player.Intf`, `PlayerRules` |
| G10 (secondo pezzo) | liste di sprite e ascensori, ascensori, movimento del giocatore, morte dei sprite | `Actor.Types`, `LinkedPool`, `Elevator.Intf`, `ElevatorRules`, `PlayerMovement`, `SpriteDeath` |
| G11 | renderer a fotogramma di Raven 3D (muri, scalini, pavimenti e soffitti inclinati, cielo, porte, sprite, trasparenze, interpolazione), parita' sui pixel con l'originale su 699 fotogrammi | `Render.Types`, `Render.Tables`, `Render.State`, `Render.WallRenderer`, `Render.PlaneRenderer`, `Render.ContentRenderer`, `Render.SpanDrawer`, `Render.SpanSorter`, `Render.SpriteInterpolator`, `Render.FrameRenderer`, `Render.Assets.Intf`, `Render.ArchiveAssets`, `Random` |
| G10 (porte) | le porte della mappa e `CheckDoors` | `Door.Intf`, `DoorSpawner`, `DoorRules` |
| G12 (parziale) | ciclo di gioco a 70 tic, finestra GDI e vista in prima persona a 640x400 (`-topdown` per la vista dall'alto): `Greed32 -play` | `Frame.Intf`, `GameLoop`, `TopDownRenderer`, `MovementHost`, `Games\Greed\DelphiDoom.Greed.HostWindow` (sulla finestra di `Framework\GameHost`), `AutoPlayInput` |
| G4 | prova visiva: `Greed32 -data <cartella> [-list] [-map N] [-lump nome] [-png file]` | `PngEncoder`, `MapRenderer`, `PngExporter`, `Games\Greed\` |

**Stato (2026-11-12)**: tutte le unit di xGreed sono portate (censimento in [CLAUDE.md](CLAUDE.md)) e `Greed32` senza argomenti, con `GREED.BLO` accanto all'eseguibile, e' il gioco: titoli, menu, briefing, livelli, finali, salva e carica. Fette oltre la G4 (ognuna con parita' sull'originale): G5 audio (`SoundEffects`, `Music`, `PcmMixer`), G6 `FixedMath`, G7 salvataggi, G8 impostazioni, G9 mondo, G10 logica (`Spawner`, `SpriteLogic`, `PlayerControl`, `PlayerWeapons`, `ItemRules`, `SwitchRules`, `LevelRules`, `CheatCodes`, `Events`, `MapSession`), G11 renderer, HUD (`Canvas`, `Font`, `Hud`...), menu (`Menu*`), filmati (`FliDecoder`, `FliPlayer`), introduzione (`Intro`, `Briefing`, `EndGame`), `TGreedGame` e `TGreedApplication`. **Non fatto**: `RearView` (rendering), rete, demo registrate, joystick e mouse, Win64.

## Mappa nome Pascal originale -> classe

| Originale (`Reference\xGreed`) | Delphi |
|---|---|
| `fileinfo_t`, `lumpinfo_t` (`d_disk.pas:30-47`) | `TGreedFileInfo`, `TGreedLumpInfo` (packed, 10 e 12 byte) |
| `CA_InitFile`, `CA_CheckNamedNum`, `CA_GetNamedNum`, `CA_LumpLen`, `CA_CacheLump`, `CA_ReadLump` | `TGreedBloArchive` (`IGreedArchive`: `IndexOf`, `RequireIndexOf`, `GetLumpSize`, `ReadLump`, `ReadLumpRaw`) |
| `FixLump`, `pst_corrected` (`g_fixlump.pas`) | `TGreedLumpFixes` (`IGreedLumpFixes`), `GREED_PST_CORRECTED` |
| `CA_CachePalette` | `TGreedPalette.FromLump` |
| `DoLoadMapData` (`utils.pas:450-491`) | `TGreedMapReader`, `TGreedMap` (18 piani, `TGreedPlane`) |
| `LoadNewMap` (la ricerca del lump `map` + n + 1 e il file con `-file`) | `TGreedMapLoader` |
| `pic_t` (`d_video.pas`), `VI_DrawPicSolid/MaskedPic` | `TGreedPictureDecoder` |
| `MapRow` (`r_spans.pas`, flat 64x64) | `TGreedFlatDecoder` |
| `LoadTextures` (`utils.pas`, colonne dei muri) | `TGreedWallDecoder` |
| `scalepic_t`, `DrawSprite`, `ScaleMaskedPost` (`r_spans.pas`) | `TGreedSpriteDecoder` |
| i gruppi `startsprites`/`endsprites`... (`r_public.pas:176-182`) | `TGreedLumpClassifier` |
| `m_screenshot`, `pngimage` | `TGreedPngEncoder` sopra `Framework\Png` |

## Formati (dall'originale e dai dati delle demo)

- **BLO**: `fileinfo_t` {numlumps: smallint; infotableofs: integer; infotablesize: integer} (10 byte) all'inizio; i lump; la tabella (`numlumps` entrate `lumpinfo_t` {filepos: integer; size: LongWord; nameofs: smallint; compress: smallint}, poi i nomi come stringhe C) in fondo. `nameofs` conta in byte dall'inizio della tabella, 0 = lump senza nome. La ricerca per nome non distingue maiuscole e da' il **primo** lump (nella demo 1.016 `slugs.lvl`, `cats.lvl` e `inner.lvl` compaiono due volte). **`compress` e' 0 in ogni lump di entrambe le demo e l'originale non lo legge mai**: la libreria lo conserva (`GetLumpInfo`) e non lo interpreta.
- **Palette**: lump `palette`, 768 byte, valori VGA a 6 bit; il gioco li moltiplica per 4 in un byte (un valore oltre 63 avvolge, difetto conservato).
- **Immagine** (`pic_t`): 4 word (larghezza, altezza, origine x, origine y) e `larghezza * altezza` pixel riga per riga; 0 e' trasparente nelle immagini mascherate.
- **Flat**: 4096 byte, 64x64, il pixel (x, y) a `y * 64 + x`.
- **Muro**: il primo byte e' l'altezza divisa per 4; dopo 65 word (130 byte) ci sono 64 colonne di `altezza` byte, dall'alto in basso (`base[size * x + y]`).
- **Sprite** (`scalepic_t`): left offset e larghezza (2 word), una word per colonna con la posizione del suo "post" nel lump (0 = colonna vuota); un post ha le altezze cima e base (2 byte) e `cima - base` pixel dall'alto in basso; lo 0 non si disegna. Le altezze si contano dalla base dello sprite in su.
- **Mappa**: 18 piani da 4096 byte (64x64, tile (x, y) a `y * 64 + x`) uno dopo l'altro: northwall, northflags, westwall, westflags, floorpic, floorflags, ceilingpic, ceilingflags, floorheight, ceilingheight, floordef, floordefflags, ceilingdef, ceilingdefflags, maplights, mapeffects, mapsprites, mapslopes. Il lump di una mappa e' quello che segue il lump `map` di tante posizioni quant'e' il numero della mappa piu' uno (`CA_GetNamedNum('map') + map + 1`) e puo' avere dopo i piani altri byte (lo script: `Trailer`). **Nelle demo i lump delle mappe sono vuoti**: la demo 2.0 ha `LEVEL1.LAY`...`LEVEL4.LAY` (73728 byte, i soli piani) accanto a `GREED.BLO` e il lump si chiama come il file; la demo 1.016 ha `*.LVL` da 143360 byte (un altro layout, **non letto**: `TGreedMapLoader` rifiuta un file che non abbia 73728 byte).

## Parita'

I golden di `Tests\Data\Greed` vengono dal **codice originale** di xGreed compilato in un harness fuori dal repository (`Tools\Verifica\175\GreedGolden.dpr`: usa `d_disk.pas` e `g_fixlump.pas` originali, e per muri e sprite le formule di `LoadTextures` e di `ScaleMaskedPost`, la seconda copiata alla lettera; per i piani `DoLoadMapData` su `fread`; vedi `Tests\Data\README.md`), sulle due demo (`Reference\_dati\greed`: `demo1016\GREED.BLO`, 6.915.530 byte, e `demo20gus\GREEDEMO.20\GREED.BLO`, 7.452.270 byte): per ogni lump nome, posizione, dimensione, `compress`, CRC32 dei byte letti e primo lump con quel nome (3191 e 3007 righe); CRC32 della palette; per ogni immagine, muro, flat e sprite larghezza, altezza e CRC32 dei pixel decodificati (137 immagini, 231 muri, 152 flat, 1024 sprite nella 1.016; 142, 246, 176 e 890 nella 2.0); CRC32 dei 18 piani delle quattro mappe `.LAY`. La libreria da' gli stessi valori: **zero differenze**. I test sui dati veri li cercano in `DELPHIDOOM_GREED_DATA` o in `Reference\_dati\greed` sopra l'eseguibile e si saltano se mancano.

## Dati del gioco completo (`full\GREED.BLO`, 2026-11-09)

Il `GREED.BLO` del gioco completo (19.726.074 byte, forniti dall'utente: `Reference\_dati\MANIFEST.md`) ha 2332 lump e **le 32 mappe dentro l'archivio** (lump `level1.lay` ... `for8play.lay` dopo il marcatore `map`, 73728 byte ciascuno: nessun file `.LAY` accanto). Il golden `Tests\Data\Greed\blo_full.golden.txt` (3911 righe, solo numeri) e' del codice originale (`GreedGolden.dpr` ora scrive anche le righe `B`: `LoadNewMap` con il `seek` al lump e i 18 `fread`): la libreria dà **zero differenze** su tabella e byte di tutti i lump (CRC32 dopo `FixLump`), primo lump per nome, palette, 262 muri, 232 flat, 370 sprite, 136 immagini, classificazione dei lump e 576 piani (32 mappe x 18). `Greed32 -data <cartella> -map N -png` esporta tutte le 32 mappe; `-play N -autoplay` le percorre (vista dall'alto).

- Un'immagine a schermo intero (`credits3`, `redchars`...) **e' seguita da un lump di 768 byte che e' la sua palette** (`2328` `credits3` 64008 byte, `2329` 768 byte): con la palette del gioco i colori del logo sono rumore, con la sua sono giusti. `Greed32 -lump` usa sempre la palette del gioco (non scelta dalla libreria: da gestire nel renderer).
- Nello shareware le immagini che il gioco compone con `backdrop` sono in `pic_t` a 8 bit senza maschera; i nomi stanno solo sui lump di testa di ogni gruppo (`backdrop`, `statbar1`, `gun2`, `missile`...), gli altri sono per posizione.
- Il `GREED.EXE` del gioco completo e' la versione CD-ROM (`nocdromcheck` per saltare il controllo, filmati `MOVIES\*.FLI` cercati su `A:`); girato in DOSBox e, compilato dal sorgente con Delphi 11 (`Reference\_dati\xgreed_build`), con questi stessi dati: menu, introduzione e livello 1 (`Tools\Verifica\175\LEGGIMI.md`).

## Differenze volute dal vecchio codice

- Un lump senza dati (marcatori come `startsprites`, e le mappe vuote delle demo) si legge come un array vuoto: l'originale faceva `malloc(0)` e dava `MS_Error` (`CA_CacheLump`).
- Un archivio guasto e' `EGreedDataException` all'apertura (tabella oltre la fine del file, nome fuori dalla tabella o senza terminatore, lump oltre la fine): l'originale leggeva quello che c'era.
- Non portati perche' difettosi e senza chiamanti utili: `CA_LumpName` (non avanza mai sulla stringa: ciclo infinito, e indicizza `infotable` come se fosse un array di `lumpinfo_t`), `CA_LumpAsText` e `CA_FileAsText` (`fread(@result[1], ...)` su una `string` UTF-16: dati corrotti).
- `FindBLOFile` (percorsi di Dos, `-blo`, unita' CD-ROM) non e' portato: la cartella dei dati si da' al programma (`-data`).

## Difetti conservati

- `CA_CachePalette`: i valori della palette sopra 63 avvolgono nel byte.
- La correzione `FixLump` si applica a `ReadLump` (come `CA_CacheLump`) e non a `ReadLumpRaw` (come `CA_ReadLump`). **Provata sui dati veri del gioco completo** (le demo non hanno quel lump): il lump 770 di `GREED.BLO` ha 10463 byte con CRC32 `48818333` e `ReadLump` dà gli stessi byte del `CA_CacheLump` originale (CRC32 `6336b14e`); la tabella e' provata anche con voci di prova e `GREED_PST_CORRECTED` ha i byte dell'originale.
- I fix che `LoadNewMap` fa sulle tabelle dopo la lettura (`floordef`/`ceilingdef` a 0 diventano 56) sono del gioco, non del file: non sono fatti da `TGreedMapReader`.

## Da collegare / da fare

Stato dopo la chiusura della #175 (2026-11-14, dettagli e numeri in `CLAUDE.md`, sezione "Chiusura della #175"): specchietto (`RearView`), mouse, joystick (estensione: xGreed non lo legge), partite registrate (formato nuovo `GRDM`: nell'originale la registrazione e' un resto senza effetto), rete (portata dal commento di `net.pas`, che in xGreed e' vuoto), salva/carica confrontati con l'originale e Win64 sono fatti.

Resta: la licenza (sopra); l'HUD dei frag e i menu di rete; lo specchietto sul giocatore nemico in rete; `DrawHolo`; la mappa dei tasti configurabile (`ckeys`, `bt_*`); la misura delle prestazioni di `MoveSprites` su una macchina scarica; la demo 1.016 ha mappe a 35 piani che il gioco non legge. Non verificato: l'ascolto dell'audio, un joystick vero, la rete tra macchine diverse, `Greed32` a 64 bit in finestra.
