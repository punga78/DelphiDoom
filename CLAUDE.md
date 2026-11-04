# DelphiDoom — istruzioni per Claude

Informazioni specifiche di questo repository. Le regole generali (commit, issue, lingua, MCP) sono nel CLAUDE.md globale.

## Progetto

Source port di Doom, Heretic, Hexen e Strife in Delphi (versione software e OpenGL), più Launcher, DD_IDE (editor degli script) e i compilatori `ddc*`.
Il target di sviluppo è **Delphi 11 (XE11), Win32**. Il codice nasce per Delphi 7: non si mantiene più la compatibilità con Delphi 7 nelle parti toccate.

- Cartelle di gioco: `Doom`, `Heretic`, `Hexen`, `Strife`; codice condiviso in `Base`, `Common`, `SCRIPT`, `OPENGL`, `AUDIOLIB`, `TEXLIB`, `C_LIB`.
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
Librerie già estratte (sorgenti in `Libs\<Lib>`, DLL in `bin\Libs`, un progetto di test per libreria in `Tests\`): `Zlib` (`DDZlib`), `Jpeg` (`DDJpeg`), `Mp3` (`DDMp3`), `Xmi` (`DDXmi`), `Sndfile` (`DDSndfile`), `Mikmod` (`DDMikmod`), `Glbsp` (`DDGlbsp`), `Png` (`DDPng`), `Script` (`DDScript`). Ogni libreria ha il proprio progetto di test (`DelphiDoom.Tests` per zlib, poi `DelphiDoom.Tests.Jpeg`, …) perché le unit di libreria possono avere lo stesso nome (gli shim di `d_delphi`) o simboli C in conflitto, e non vanno linkate nello stesso eseguibile.

`Png` non contiene uno zlib proprio: `DDPngCreate` riceve un `IZlib` dal chiamante (zlib in-process o `DDZlib.dll`). `Glbsp` è il port in Pascal di glBSP 2.24 (i sorgenti C 2.24 sono nella storia di git, prima del commit che chiude la #2): `TGlbspWadBuilder` legge un WAD da flusso, costruisce i nodi di ogni livello (`Level.Loader` → `Level.Analyzer` → `Node.Builder`/`Node.Partitioner` → `Level.Writer`, più `Blockmap.Builder` e `Reject.Builder`) e scrive il risultato; `TGlbspEngine` lo espone dietro `IGlbsp` (un'uscita `.gwa` contiene solo i lump nuovi). La compressione del formato ZDBSP usa `TZlibProvider`. I test confrontano l'uscita con quella dell'eseguibile 2.24 (`Tests\Data\README.md`). `Script` è una fetta verticale di PascalScript (compilare, eseguire, funzioni host, globali): l'analisi di cosa resta nel motore è in `Libs\Script\README.md`.

Il motore usa già `Libs\Zlib` senza DLL: `TZlibProvider` (`DelphiDoom.Zlib.Provider`) dà a `TEXLIB\t_png.pas` e a `ZLIB\z_files.pas` un `TZlibClient` sopra `TZlibEngine` linkato nell'eseguibile; per usare `DDZlib.dll` basta `TZlibProvider.Use`. Gli `.obj` di zlib stanno in `Libs\Zlib`. Lo stesso schema vale per `Xmi` (`TXmiProvider`, usato da `Base\i_music.pas`): il convertitore XMI/CMF→MIDI è scritto in Pascal in `Libs\Xmi\DelphiDoom.Xmi.*` (`TXmiConverter`), senza form né stato globale; il SOP viene riconosciuto ma non convertito. Idem per `Jpeg` (`TJpegProvider`, usato da `TEXLIB\t_jpeg.pas` tramite `TJpegBitmapBuilder`; `JPEGLIB\jpg_*.pas` restano come implementazione dietro `TJpegEngine`). Per `Mp3` il provider dà l'`IMp3` che crea un decoder per brano (`TMp3Provider`); la riproduzione sta in `Base\DelphiDoom.Audio.Mp3Player.pas` (waveOut + thread) usata da `Base\i_mp3.pas`. La DLL decodifica solo MPEG-1/2 layer III: i layer I e II del vecchio player sono stati tolti. Per `Sndfile` il provider (`TSndfileProvider`) serve `TSoundConverter` (`Base\DelphiDoom.Audio.SoundConverter.pas`), usato da `AUDIOLIB\audiolib.pas` per portare OGG/FLAC/VOC/AU in WAV a 16 bit; gli `.obj` di libsndfile (`AUDIOLIB\libsndfile\obj`) li linka `DelphiDoom.Sndfile.Native`. Per `Mikmod` il provider (`TMikModProvider`) dà a `Base\i_mikplay.pas` il `TMikModClient`; `Base\mikmod.pas` (binding della MikWin.dll incorporata) resta come implementazione dietro `TMikModEngine`, e `MIKWIN\` conserva i sorgenti C della DLL. Per `Png` il provider (`TPngProvider`, che comprime con l'`IZlib` di `TZlibProvider`) serve `TEXLIB\t_png.pas`, ridotto ai due gestori di texture (`TPNGTextureManager`, `TPNGSpriteTextureManager`), e `TPngFileWriter` (`TEXLIB\DelphiDoom.Texture.PngFileWriter.pas`) per gli screenshot e l'export dello z-buffer, che ora è in scala di grigi a 8 bit. Per `Glbsp` il provider (`TGlbspProvider`) serve `Base\nd_main.pas` (`ND_RunGlbsp`): non c'è più alcun eseguibile incorporato. `Script` è spezzata nelle issue #18–#23 (la #10 è il contenitore).

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

## Una classe per unit

- Ogni unit nuova o riscritta contiene **una sola classe** (o un solo record/interfaccia principale). Il nome dell'unit deriva dal tipo: `TWadReader` → `DelphiDoom.Wad.Reader`.
- Nelle unit nuove i nomi sono a punti con prefisso `DelphiDoom.<Area>.` (come `Neon.Core.*`), non `snake_case`.
- Nella stessa unit possono stare solo i tipi di supporto usati esclusivamente da quella classe (un `enum`, un `record` di parametri, un'eccezione propria). Eccezioni e tipi condivisi vanno in una unit `*.Types`.
- Interfaccia e implementazione in unit separate quando esistono più implementazioni o quando serve sostituire la dipendenza nei test.
- **Non aggiungere classi alle unit storiche enormi** (`Common\d_delphi.pas`, `SCRIPT\ps_runtime.pas`, `Base\mikmod.pas`…): creare un'unit nuova e farla usare dal chiamante.
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

## Aree ancora aperte

- Circa 900 warning di conversione tra `string`, `AnsiString` e `ShortString` (W1057/W1058) e `Char` negli insiemi (W1050): sistemarli file per file con cast espliciti, non sopprimerli.
- Tracce `-devparm` temporanee in `Doom\p_setup.pas` (`P_SetupLevel`) e `Base\nd_main.pas` (`ND_GetNodes`).
- Heretic: crash intermittente a runtime da indagare con `crash.txt`.
