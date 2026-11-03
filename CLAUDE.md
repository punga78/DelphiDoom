# DelphiDoom — istruzioni per Claude

Informazioni specifiche di questo repository. Le regole generali (commit, issue, lingua, MCP) sono nel CLAUDE.md globale.

## Progetto

Source port di Doom, Heretic, Hexen e Strife in Delphi (versione software e OpenGL), più Launcher, DD_IDE (editor degli script) e i compilatori `ddc*`.
Il target di sviluppo è **Delphi 11 (XE11), Win32**. Il codice nasce per Delphi 7: non si mantiene più la compatibilità con Delphi 7 nelle parti toccate.

- Cartelle di gioco: `Doom`, `Heretic`, `Hexen`, `Strife`; codice condiviso in `Base`, `Common`, `SCRIPT`, `OPENGL`, `AUDIOLIB`, `MP3LIB`, `XMILIB`, `TEXLIB`, `C_LIB`.
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

La DLL è un progetto `DDxxx.dpr/.dproj` alla radice (output in `bin\Libs`) che esporta `DDxxxCreate(out A: I<Lib>): Integer`. Test in `Tests\Source`, progetto `Tests\DelphiDoom.Tests.dproj` (`build.bat tests`, eseguibile in `bin\Tests`).
Il motore non è ancora collegato a `Libs\Zlib`: `TEXLIB\t_png.pas` (`CompressZLIB`/`DecompressZLIB`) e `ZLIB\z_files.pas` usano ancora il codice storico.

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
- **Non aggiungere classi alle unit storiche enormi** (`Common\d_delphi.pas`, `SCRIPT\ps_runtime.pas`, `XMILIB\xmi_core.pas`…): creare un'unit nuova e farla usare dal chiamante.
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
