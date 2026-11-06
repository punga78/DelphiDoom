# DelphiDoom — istruzioni per Claude

Informazioni specifiche di questo repository. Le regole generali (commit, issue, lingua, MCP) sono nel CLAUDE.md globale.

## Progetto

Source port di Doom, Heretic, Hexen e Strife in Delphi (versione software e OpenGL), più Launcher, DD_IDE (editor degli script) e i compilatori `ddc*`.
Il target di sviluppo è **Delphi 11 (XE11), Win32**. Il codice nasce per Delphi 7: non si mantiene più la compatibilità con Delphi 7 nelle parti toccate.

- Cartelle di gioco: `Doom`, `Heretic`, `Hexen`, `Strife`; codice condiviso in `Base`, `Common`, `SCRIPT`, `OPENGL`, `TEXLIB`. Nel repository non c'è più codice C: libsndfile, libvorbis, libflac e il runtime `C_LIB` sono stati cancellati (restano nella storia di git, ultimo commit che li contiene: `a449cacd`).
- Un `.dpr` + `.dproj` per ogni eseguibile (`Doom32`, `GLDoom32`, `Heretic32`, …). I define di gioco (`DOOM`, `HERETIC`, `HEXEN`, `STRIFE`, `OPENGL`) stanno nei `.dproj`.

## Build e prove

```
build.bat                     # Doom32, Release
build.bat all                 # tutti i progetti (giochi + strumenti)
build.bat giochi | strumenti  # gruppi
build.bat Heretic32 Debug     # un progetto
build.bat all Release clean   # cancella prima la cartella dcu
```

- Output: `bin\Doom|Heretic|Hexen|Strife` (giochi), `bin\Tools` (DD_IDE, ddc, DLL), `bin` (Launcher); `.dcu` in `dcu\`; log in `logs\<progetto>.log`. Tutte queste cartelle sono ignorate da git.
- Delphi è installato **in una VM** che legge il progetto da una cartella condivisa. Conseguenze: i file possono risultare bloccati (`Device or resource busy`) o letti con dimensione vecchia (errori di "fine file" su sorgenti integri); `build.bat` elenca i file prima di compilare per aggiornare la cache. Se un file è bloccato non ritentare in ciclo: chiedere di sospendere la VM.
- Per leggere i risultati di una build usare `logs\*.log` (righe `error`), non gli output a video.
- Prove a runtime: i WAD stanno in `bin\<Gioco>` (`DOOM1.WAD`, `FREEDOOM2.WAD`, `HERETIC1.WAD`, `HEXEN.WAD`, `STRIFE0.WAD`) insieme ai `*32.swd`. Log in `bin\<Gioco>\DATA\LOGS\` (`*_stderr.txt`, `*_stdout.txt`). Con `-devparm` si vedono le tracce di caricamento; in caso di crash `crash.txt` (unit `Base\i_crashlog.pas`) e il file `.map` accanto all'exe permettono di risalire all'indirizzo.
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

La DLL è un progetto `DDxxx.dpr/.dproj` dentro la cartella della libreria, `Libs\<Lib>\` (output in `bin\Libs`; per compilarla `build.bat Libs\<Lib>\DDxxx`) che esporta `DDxxxCreate(out A: I<Lib>): Integer`. Test in `Tests\Source`, progetto `Tests\DelphiDoom.Tests.dproj` (`build.bat tests`, eseguibile in `bin\Tests`).
Librerie già estratte (sorgenti in `Libs\<Lib>`, DLL in `bin\Libs`, un progetto di test per libreria in `Tests\`): `Zlib` (`DDZlib`), `Jpeg` (`DDJpeg`), `Mp3` (`DDMp3`), `Xmi` (`DDXmi`), `Sndfile` (`DDSndfile`), `Mikmod` (`DDMikmod`), `Glbsp` (`DDGlbsp`), `Png` (`DDPng`), `Script` (`DDScript`), più `M2m` (convertitore MIDI→MUS), `Ogg` (contenitore Ogg) e `Wad` (lettura e scrittura di WAD, PAK, ZIP e cartelle, issue #46; ha la DLL `DDWad`, il motore non la usa). Ogni libreria ha il proprio progetto di test (`DelphiDoom.Tests` per zlib, poi `DelphiDoom.Tests.Jpeg`, …) perché le unit di libreria possono avere lo stesso nome (gli shim di `d_delphi`) o simboli C in conflitto, e non vanno linkate nello stesso eseguibile.

`Png` non contiene uno zlib proprio: `DDPngCreate` riceve un `IZlib` dal chiamante (zlib in-process o `DDZlib.dll`). `Glbsp` è il port in Pascal di glBSP 2.24 (i sorgenti C 2.24 sono nella storia di git, prima del commit che chiude la #2): `TGlbspWadBuilder` legge un WAD da flusso, costruisce i nodi di ogni livello (`Level.Loader` → `Level.Analyzer` → `Node.Builder`/`Node.Partitioner` → `Level.Writer`, più `Blockmap.Builder` e `Reject.Builder`) e scrive il risultato; `TGlbspEngine` lo espone dietro `IGlbsp` (un'uscita `.gwa` contiene solo i lump nuovi). La compressione del formato ZDBSP usa `TZlibProvider`. I test confrontano l'uscita con quella dell'eseguibile 2.24 (`Tests\Data\README.md`). `Script` è una fetta verticale di PascalScript (compilare, eseguire, funzioni host, globali): l'analisi di cosa resta nel motore è in `Libs\Script\README.md`.

Il motore usa già `Libs\Zlib` senza DLL: `TZlibProvider` (`DelphiDoom.Zlib.Provider`) dà a `TEXLIB\t_png.pas` e a `ZLIB\z_files.pas` un `TZlibClient` sopra `TZlibEngine` linkato nell'eseguibile; per usare `DDZlib.dll` basta `TZlibProvider.Use`. `TZlibEngine` usa `System.ZLib` della RTL di Delphi (nessun `.obj`): `GetVersion` risponde `System.ZLib`. Lo stesso schema vale per `Xmi` (`TXmiProvider`, usato da `Base\i_music.pas`): il convertitore XMI/CMF→MIDI è scritto in Pascal in `Libs\Xmi\DelphiDoom.Xmi.*` (`TXmiConverter`), senza form né stato globale; il SOP viene riconosciuto ma non convertito. Idem per `Jpeg` (`TJpegProvider`, usato da `TEXLIB\t_jpeg.pas` tramite `TJpegBitmapBuilder`; `JPEGLIB\jpg_*.pas` restano come implementazione dietro `TJpegEngine`). Per `Mp3` il provider dà l'`IMp3` che crea un decoder per brano (`TMp3Provider`); la riproduzione sta in `Base\DelphiDoom.Audio.Mp3Player.pas` (waveOut + thread) usata da `Base\i_mp3.pas`. La DLL decodifica solo MPEG-1/2 layer III: i layer I e II del vecchio player sono stati tolti. Per `Sndfile` il provider (`TSndfileProvider`) serve `TSoundConverter` (`Base\DelphiDoom.Audio.SoundConverter.pas`), usato da `Base\DelphiDoom.Audio.SoundLibrary.pas` per portare OGG/FLAC/VOC/AU in WAV a 16 bit; il motore è `Libs\Sound` (vedi sotto). Per `Mikmod` il provider (`TMikModProvider`) dà a `Base\i_mikplay.pas` il `TMikModClient` sopra `TTrackerMikModEngine`: il lettore di moduli è scritto in Pascal (`Libs\Mikmod\DelphiDoom.Tracker.*`) e suona MOD, S3M, XM e IT. I loader (`Loader.ProTracker/S3m/Xm/It`) producono un `TTrackerModule`; `TTrackerPlayer` legge righe e tick, `TTrackerChannel` applica note ed effetti, `TTrackerNoteEnvelopes` gli inviluppi e il fade out, `TTrackerGhostPool` le note IT che continuano in sottofondo (NNA, DCT, DCA), `TTrackerMixer` somma le voci e `TTrackerWaveOut` le scrive con waveOut in un thread; `Base\DelphiDoom.Audio.ModuleDetector.pas` dice a `Base\i_music.pas` se un lump è un modulo. Il vecchio codice (MikWin, Micromod, libs3m, i lettori di XM e IT) è stato cancellato; non sono fatti gli effetti IT S70–S76 e i filtri. `Tools\prova-tracker.bat` ascolta i brani di prova (`Tools\Tracker\MakeTestSongs.py`) o un modulo indicato. Per `Png` il provider (`TPngProvider`, che comprime con l'`IZlib` di `TZlibProvider`) serve `TEXLIB\t_png.pas`, ridotto ai due gestori di texture (`TPNGTextureManager`, `TPNGSpriteTextureManager`), e `TPngFileWriter` (`TEXLIB\DelphiDoom.Texture.PngFileWriter.pas`) per gli screenshot e l'export dello z-buffer, che ora è in scala di grigi a 8 bit. Per `M2m` il provider (`TM2mProvider`) serve `I_MidToMus` di `Base\i_music.pas` (percorso `snd_uselegacymidiplayer = 2`): `TMidiReader` legge il file, `TMidiTrackMerger` unisce le tracce di un tipo 1 e `TMidiToMusConverter` scrive il MUS; riproduce byte per byte l'uscita del vecchio `libm2m` in C (anche i suoi difetti, ad esempio i ritardi troncati a 14 bit), verificata su 403 file prima di cancellarlo. Per `Ogg` le classi di `Libs\Ogg` (`TOggBitPacker`, `TOggCrc`, `TOggPageReader`, `TOggStream`, `TOggSync`) sono il port di libogg 1.3.x e usano le strutture con lo stesso layout del C (`DelphiDoom.Ogg.Types`: allineamento 8, long e puntatori a 32 bit); Il guscio `libogg.pas` che esponeva le funzioni `_ogg_*` / `_oggpack_*` al C è sparito con il C; `Libs\Ogg` ora serve il decoder Vorbis di `Libs\Sound`. Il confronto con il C (pagine di 120 canzoni casuali, anche corrotte, e 300 sequenze di bit) è stato fatto prima di cancellarlo; `oggpackB_*` (ordine MSb) non è portato perché nessun sorgente lo usa. Per `Glbsp` il provider (`TGlbspProvider`) serve `Base\nd_main.pas` (`ND_RunGlbsp`): non c'è più alcun eseguibile incorporato. `Script` è spezzata nelle issue #18–#23 (la #10 è il contenitore).

`Libs\Wad` (issue #46, primo passo) è la libreria a classi che sostituirà `Base\w_wad.pas` e le unit `w_*`; **il motore la usa per la directory dei lump**: `Base\w_wad.pas` crea un `IWadDirectory` (`wad_directory`), apre ogni file con `TWadFileSource`/`TSingleFileSource` sopra gli stream del motore (`Base\DelphiDoom.Wad.DStreamAdapter.pas`, `TDStream` visto come `TStream`) e rifà `lumpinfo[]` da lì con `W_SyncLumpInfo`; `lumpinfo[]` è una vista di sola lettura (nessuno la scrive), la ricerca per nome (`W_CheckNumForName*`) e i flag dei marcatori vengono dal `IWadFinder`; anche i byte dei lump passano dalla libreria (`W_ReadLump` chiama `ILumpReader.ReadLumpInto`, che legge dalla sorgente dritto nel buffer, senza copie; un file aggiunto con `~` è un `TReloadableWadSource` che non tiene il file aperto) mentre la cache resta lo zone memory del motore (`lumpcache[]`, `PU_*`; decisione: la cache è del motore). `lumpinfo[]` non è più visibile fuori da `w_wad.pas`: gli altri moduli usano `W_GetNameForNum`, `W_LumpLength`, `W_LumpFlags` e `W_LumpIsNamed`. `Base\w_wadreader.pas` (`TWadReader`) e `Base\w_wadwriter.pas` (`TWadWriter`) sono facciate con la vecchia API sopra `TWadFactory.OpenPath` e `IWadBuilder`: il WAD che scrive ha il layout della libreria (dati allineati a 4 byte, directory in fondo), non quello di prima (directory subito dopo l'intestazione, senza allineamento), quindi i file di cache `pk3sounds_<sha1>.wad`, `voxelsprite_<sha1>.wad`, `pk3tex_*`/`pk3flat_*` si rigenerano una volta; un nome di lump può avere qualsiasi byte tranne #0 (1–8 caratteri). Anche `Base\w_pak.pas` (il file system PAK: PAK Quake, PK3/PK4, WAD2/WAD3 e WAD con `PK3ENTRY`/`HI_START`/`TX_START`) legge le directory dei contenitori con la libreria (`TWadFactory.OpenPath`, `TWad2FileSource` per WAD2/WAD3) e apre ogni voce con `TPakEntryReader` (`Base\DelphiDoom.Pak.EntryReader.pas`: legge tutti i byte della voce e non va mai oltre la sua fine); restano in `w_pak.pas` le regole del motore sui percorsi (nomi corti, cartelle preferite, un file su disco vince sul PAK, hash dei nomi). Lo ZIP lo legge `System.Zip` e `ZLIB\z_files.pas` non esiste più. **Composition root del motore**: `DelphiDoom.Engine.Composition` (`ComposeEngine`, chiamata come primo passo dal programma di ogni gioco, dopo `I_InstallCrashLogger`, e dal `begin` dei `ddc_*`) crea `TEngineWadServices` (`Base\DelphiDoom.Engine.Wad.Services.pas`, unico punto del motore che conosce `TWadFactory`, i sorgenti e gli adattatori) e lo dà, come `IEngineWadServices` (`DelphiDoom.Engine.Wad.Intf`), a `W_Configure`, `TWadReader.Configure`, `TWadWriter.Configure` e `PAK_Configure`; senza di essa quelle unit danno un `I_Error`. `w_wad`, `w_wadreader`, `w_wadwriter` e `w_pak` non usano più classi concrete della libreria. Le funzioni `W_*` restano l'API del motore (circa mille chiamanti): non si migrano una per una. Contratto in `DelphiDoom.Wad.Intf`: `IWadSource` (una sorgente di lump: `TWadFileSource` per IWAD/PWAD/DWAD, `TPakFileSource` per i PAK Quake, `TZipFileSource` per i PK3, `TFolderSource`, `TSingleFileSource`), `IWadDirectory` (le sorgenti una dopo l'altra, `Truncate` per il reload; vince l'ultimo lump con lo stesso nome), `IWadFinder` (`CheckNumForName` con i flag `TYPE_FLOOR/SPRITE/PATCH/VOXEL/HIRES` delle coppie `F_START`/`F_END`..., `CheckFirstNumForName`, ricerca in un intervallo), `ILumpReader`, `ILumpCache` (livelli `Static` e `Cache`, `Purge`), `IWadBuilder` (crea e modifica WAD; dati allineati a 4 byte, nomi maiuscoli di 1–8 caratteri). `TWadDirectory` implementa directory, finder e reader; `TWadFactory` è l'unico punto che conosce le classi concrete (`OpenPath` riconosce WAD, PAK, ZIP e cartelle dal contenuto). `DelphiDoom.Wad.Level.Types` ha i record dei lump di livello (THINGS, LINEDEFS, SIDEDEFS, VERTEXES, SEGS, SSECTORS, NODES, SECTORS, anche Hexen) packed e senza puntatori, con `SizeOf` coperto da test. Le interfacce di `DelphiDoom.Wad.Intf` usano tipi gestiti (`TBytes`, `string`); per la DLL ci sono interfacce a buffer e interi in `DelphiDoom.Wad.Dll.Intf` (`IWadDll`, `IWadDllSource`, `IWadDllDirectory`, `IWadDllBuilder`, `stdcall`, testi UTF-8 con buffer del chiamante e protocollo "nil per chiedere la lunghezza", codici `WADDLL_*`, nessuna eccezione oltre il confine). `DDWad.dll` (`Libs\Wad\DDWad.dpr`, `build.bat Libs\Wad\DDWad`, esporta `DDWadCreate`) è fatta da `TWadDllEngine` e dagli adattatori `Dll.SourceAdapter`/`DirectoryAdapter`/`BuilderAdapter`; `TWadDllClient` (`Dll.Client`, con `ClientSource`/`ClientDirectory`/`ClientBuilder`) la espone con le interfacce della libreria (`IWadSource`, `IWadDirectory`, `IWadFinder`, `ILumpReader`, `IWadBuilder`), `TWadDllLoader` la carica. Le sorgenti e le directory di un client lavorano insieme, non con quelle delle classi della libreria; ogni oggetto della DLL (e i temporanei, come finder e lettore ottenuti da una directory) va rilasciato prima di scaricarla. Il motore non usa la DLL (le sue sorgenti sono stream di `TDStream`, che non attraversano il confine): è per strumenti e per il server MCP (#47). `IWadDirectory.ReplaceSource` serve al reload (`~file`, `W_Reload`) e a `W_RuntimeLoad` quando lo stesso WAD viene caricato di nuovo. Test in `Tests\DelphiDoom.Tests.Wad` (109, di cui 24 sulla DLL, anche quella vera in `bin\Libs`); quelli sui WAD reali leggono `bin\<Gioco>` e si saltano se mancano.

`Libs\Sound` è il sostituto in Pascal di libsndfile, libvorbis e libflac (issue #32, #30, #31) e **da questa versione è il motore usato dal gioco**: `TSndfileProvider.Client` crea `TSoundFactory.CreateEngine` (i progetti dei giochi non linkano più `Libs\Sndfile\Native`, libogg, libvorbis, libflac). Anche la DLL `DDSndfile` esporta `TSoundFactory.CreateEngine`. Implementa lo stesso contratto `ISndfile` (`DelphiDoom.Sndfile.Intf`). Architettura con dependency injection: `ISoundFormat` (un contenitore: `Decode(bytes) → TSoundSamples`; `SNDFILE_ERR_UNRECOGNISED_FORMAT` se non è il suo), `TSoundEngine` (riceve la lista dei formati dal costruttore e prova uno dopo l'altro; salta un tag ID3v2 davanti a un FLAC), `TSoundFactory` (unico punto che conosce i formati), `TSoundFile` (`ISoundFile` sopra i campioni decodificati; conversioni a short/int/double in `TSoundConvert`), `TSoundPcmReader` (PCM/float/µ-law/A-law condiviso), `TSoundByteReader` (lettura sequenziale con `Overrun`). Formati fatti: WAV (PCM, float, µ-law, A-law, EXTENSIBLE, RIFX, MS/IMA ADPCM, GSM 6.10, G.721/G.723), AIFF/AIFC (anche IMA ADPCM, GSM, DWVW), AU, VOC, AVR, HTK, W64, RF64, CAF (PCM), SVX, IRCAM, MAT4, MAT5, WVE, MPC2K, PAF, SDS, XI, FLAC (`Codec.Flac`), Ogg Vorbis (`Codec.Vorbis`, `Vorbis.*`, sopra le classi di `Libs\Ogg`). **Non portati**: ALAC (dentro CAF), PVF, NIST, DWD, TXW, REX2 (in C falliscono sempre o servono dati di prova che non abbiamo), Vorbis con floor di tipo 0, FLAC/Speex/PCM dentro Ogg, tutta la scrittura. I test sono in `Tests\DelphiDoom.Tests.Sndfile` (`DelphiDoom.Tests.Sound.Parity`): aprono i byte di prova con il motore Pascal e confrontano con le risposte che libsndfile (C) aveva dato (`Tests\Data\sound_golden.txt`, vedi `Tests\Data\README.md`): una impronta a 64 bit per ogni scenario (info, letture a pezzi di 1, 7 e 4096 frame con `ReadShort/ReadInt/ReadDouble`, `Seek`, fine del suono), calcolata con `DelphiDoom.Tests.Sound.Digest`; i file di prova sono costruiti in memoria (`Tests\Source\DelphiDoom.Tests.Sound.*File.pas`; per Vorbis intestazioni fatte a mano e pacchetti casuali, perché l'encoder del C va in access violation). Regole di libsndfile da rispettare: float/double → intero con `lrint` senza scala né clipping (in 16 bit si tronca, in 32 bit dà `$80000000`; Ogg Vorbis moltiplica per 32767 / 2^31, `TSoundSamples.FullScaleFloats`); dati interi tenuti allineati a sinistra; oltre la fine il buffer viene azzerato; in una lettura parziale la coda si azzera solo se dopo i dati c'è almeno un frame (`ExtraItems`/`Tail`); `pcm_init` ricalcola la lunghezza dei dati e il byte di pad di un chunk dispari non conta. Difetti di libsndfile che il Pascal non copia: in PAF a 24 bit e SDS l'ultimo pacchetto letto dopo un `Seek` o a cavallo di due letture viene azzerato; il FLAC danneggiato perde l'ultimo frame se letto in un colpo solo attraverso un resync.

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
- **Non aggiungere classi alle unit storiche enormi** (`Common\d_delphi.pas`, `SCRIPT\ps_runtime.pas`…): creare un'unit nuova e farla usare dal chiamante.
- Le unit storiche con più classi non si spezzano in massa; si separano solo quando la classe viene riscritta.

## Test

- Framework: **DUnitX**, come in `delphi-neon\Tests`. Una fixture (`[TestFixture]`) per ogni unit, una unit di test per ogni classe: `DelphiDoom.Tests.<Area>.<Classe>`, classe `TTest<Classe>`.
- Struttura: cartella `Tests\` alla radice con il progetto console `DelphiDoom.Tests.dpr/.dproj`, `Tests\Source` (una unit per fixture) e `Tests\Data` (file di input). Attributi come in Neon: `[TestFixture]`, `[Category('…')]`, `[Setup]`/`[TearDown]`, `[Test]`, `[TestCase('nome', 'a,b')]`, `Assert.AreEqual`.
- Codice nuovo o riscritto: ogni classe ha i suoi test. Ogni bug corretto in codice testabile (parsing, conversioni di nomi e stringhe, tabelle, formati WAD/savegame) ha un test di regressione che fallisce prima della correzione.
- Test deterministici e isolati: nessun WAD commerciale, nessuna finestra, DirectX, audio o rete, nessun `sleep`. Dati minimi in `Tests\Data` o costruiti in memoria; ogni test crea e libera le proprie risorse (`Setup`/`TearDown`) e non dipende dall'ordine.
- Ciò che richiede il motore completo (caricamento di un livello, rendering, demo) non si copre con DUnitX: si prova avviando il gioco come descritto in "Build e prove" e si controllano `DATA\LOGS` ed eventuale `crash.txt`.
- Prima di ogni commit: compilare (`build.bat all`) ed eseguire la suite quando esiste. Descrizioni dei test e commenti di business in italiano, identificatori in inglese.

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

L'obiettivo è che ogni progetto compili e funzioni sia a Win32 sia a Win64; oggi esiste solo Win32 (issue #41–#44). Nel codice nuovo:

- **Mai** `Integer`/`Cardinal` per contenere un puntatore o un handle: `NativeInt`/`NativeUInt`/`PtrUInt`, o un puntatore tipizzato.
- **Mai** assembler inline (`asm`) né `{$L file.obj}`: Pascal puro; l'`asm` storico si sostituisce con Pascal e test di parità (#41), gli `.obj` OMF spariscono con le riscritture (#42).
- Record dei formati su disco (savegame, WAD, lump) senza puntatori e con `SizeOf` coperto da un test: devono essere uguali a 32 e 64 bit.
- `Extended` a 64 bit vale 8 byte: dove serve una precisione scrivere `Double` in modo esplicito; l'ambiente in virgola mobile (`Set8087CW`) sta dietro una classe, non nel codice che lo usa.
- Le DLL `DD*.dll` devono avere la stessa bitness dell'eseguibile.

## Aree ancora aperte

- Circa 900 warning di conversione tra `string`, `AnsiString` e `ShortString` (W1057/W1058) e `Char` negli insiemi (W1050): sistemarli file per file con cast espliciti, non sopprimerli.
- Tracce `-devparm` temporanee in `Doom\p_setup.pas` (`P_SetupLevel`) e `Base\nd_main.pas` (`ND_GetNodes`).
- Heretic: crash intermittente a runtime da indagare con `crash.txt`.
