# DD_IDE: analisi e ristrutturazione a classi (issue #45)

DD_IDE e l'editor degli script di DelphiDoom: un'applicazione VCL separata (`DD_IDE.dpr`, uscita `bin\Tools\DD_IDE.exe`).
Non fa parte dei giochi e non e usata dai `ddc_*`. Compila e disassembla gli script con le DLL `ddc_<gioco>.dll`
(le stesse che usa `ddc.exe`, tramite `SCRIPT\ddc_base.pas`). SynEdit (`DD_IDE\SynEdit`, 39 file) e di terze parti e non e stato toccato.

## 1. Com'era (commit `abc9da77`)

27 unit in `DD_IDE\` (11107 righe, di cui 7 form, 9 frame con `.dfm`), piu SynEdit.

| Gruppo | Unit (righe) | Cosa faceva |
|---|---|---|
| Finestra principale | `main` (1255) | progetto aperto, salvataggio, domande, schede degli editor, albero, messaggi, cambio gioco, pk3; piu di 30 gestori di eventi che mescolavano VCL, file e regole |
| Progetto e file | `ide_project` (724), `ide_baseframe` (376) | `TIDEProject`, `TIDEProjectItem`, `TBaseEditorObject`: caricamento/salvataggio, copia datata, formato `.ddide`, rinomina, pk3; la base **conosceva i frame** (`TFrame_ProjectManager`, `TFrame_ScriptEditor`) |
| Annulla | `ide_undo` (648), `ide_binary` (629) | pile di file temporanei compressi; `SaveUndo` non e mai chiamato da nessuno (annulla e rifai non fanno mai nulla) |
| Editor di script | `frm_scripteditor` (1119) | SynEdit, compilazione (`CompileCmd`: parole chiave, messaggi, posizione dell'errore, salvataggio del codice), eventi, hint dei parametri (`scpParamsExecute`, `GenerateParameterHintList`), ricerca e sostituzione con 11 variabili globali |
| Project manager | `frm_projectmanager` (188) | albero e casella del gioco |
| Pannelli della libreria | `frm_constants`, `variables`, `types`, `actordef`, `unitfunctions` (413-438 ciascuno), `frm_classes`, `sprites`, `states`, `mobjinfo` (416-504) | ognuno leggeva la DLL, tagliava il csv, filtrava, ordinava e teneva un SynEdit per l'esempio (7 copie della stessa sottoclasse che scrive file in `consts\`, `vars\`...) |
| Dialoghi | `frm_SearchText`, `frm_ReplaceText`, `frm_ConfirmReplace`, `frm_GotoLine`, `frm_message` | cronologia della ricerca (10 voci) dentro la form |
| Varie | `ide_utils` (292), `ide_defs` (168), `ide_tmpfiles` (79), `ide_version` (58), `ide_zipfile` (549), `frm_states_new` (439, non nel progetto) | `LogOutput` con la variabile globale `outproc`; `ide_defs` e `ide_tmpfiles` non hanno chiamanti |

### Stato globale, singleton, dipendenze

- Variabili globali di logica: `outproc` (`ide_utils`), 11 `gb*`/`gs*` della ricerca (`frm_scripteditor`), 4 opzioni e la tabella di `ide_defs`,
  `tempfiles` (`ide_tmpfiles`), `inst`/`localload` (`ddc_base`). In piu `Form1`, `PageSetupDlg`, `ScriptPrintPreviewDlg`, `ConfirmReplaceDialog` (VCL).
- Accessi a sistema sparsi: `ChDir` (cambia la cartella del processo quando si apre o si salva un progetto: da li dipendono i percorsi relativi),
  `Screen.Cursor` in molti punti, `MessageBox`, `Clipboard`, `FileExists`/`TFileStream` dentro i metodi dei documenti, `ParamStr(0)` per le cartelle degli esempi.
- `uses` circolari: 2 cicli passanti per `ide_baseframe` (`ide_baseframe` -> `frm_projectmanager`/`frm_scripteditor` -> `ide_baseframe`/`ide_project` -> `ide_baseframe`).
- Nessun test.

### Logica dentro i form (cio che si poteva provare senza finestre)

Formato `.ddide`, ricerca per percorso (relativo, assoluto, nome), rinomina, copia datata, pk3, lettura dei messaggi del compilatore e posizione dell'errore,
elenco degli eventi e testo da inserire, hint dei parametri, cronologia della ricerca, opzioni di ricerca, csv di mobjinfo/stati/sprite, filtri, ordinamenti,
traduzione dei campi degli stati, sprite per attore (visita della catena degli stati), cartelle degli esempi.

### Difetti trovati nel vecchio codice

| Difetto | Esito |
|---|---|
| Le DLL `ddc_*` si bloccavano in `LoadLibrary` (`DD_InitDoomEngine` girava prima di `ComposeEngine`): DD_IDE e `ddc.exe` restavano appesi al primo uso | **corretto** (commit `294ec885`), provato a runtime |
| Aprire un progetto lo riportava a Doom (`project.Game := 'doom'` dopo la lettura) | **corretto**, test `DovrebbeAprireIlProgettoDellaRigaDiComandoConIlSuoGioco`, provato a runtime (la casella mostra Heretic) |
| Il progetto sulla riga di comando era ignorato con un solo argomento (`ParamCount > 1`) | **corretto**, stesso test, provato a runtime |
| "Compila e salva" scriveva due byte per carattere (`SizeOf(Char)`): il file `.ddout` non era quello di `ddc.exe` | **corretto**, test `DovrebbeScrivereUnSoloByteInFileNonDue` e confronto byte per byte con `ddc.exe` |
| `ddc_base` allocava `clen` byte per `clen` caratteri a due byte (scrittura oltre il blocco, compilazione e disassemblato) | **corretto** (`SizeOf(Char)` nei buffer) |
| Posizione dell'errore con testo senza `[Error]` leggeva prima del primo carattere della stringa | **corretto**, test |
| `StrToInt` su valori non numerici dei csv alzava un'eccezione nei pannelli degli stati | ora il valore e scritto come sconosciuto, test |
| Una riga vuota nel file di progetto crea un elemento "none" senza nome | **conservato** (golden dal vecchio codice) |
| I pannelli con la lista ordinata partono ordinati solo se hanno gia una finestra: all'avvio (form non ancora visibile) la lista e nell'ordine della DLL | ora e sempre ordinata (il pannello delle funzioni parte ordinato per unita, come il codice voleva) |
| Con una scheda aperta, rinominare un file lascia nell'albero il testo digitato invece del percorso del progetto | **conservato** (test) |
| `Pos` e ordinamenti dei vecchi pannelli: l'esadecimale `$10` non e un numero per `Val` su un Double | **conservato** (golden) |

## 2. Com'e adesso

```
DD_IDE\                              (28 unit, 4762 righe: form sottili + adattatori Windows)
  main.pas, frm_*.pas                form e frame: solo disegno, chiamano i presenter
  DelphiDoom.Ide.Win.*               IIdeFileSystem, IIdeClock, IIdeBusy, IIdeClipboard, IIdeMessageDialogs,
                                     IIdeFileDialogs, IIdePCodeDialog, IIdeArchive (zip), IIdeScriptCompiler/IIdeGameLibrary (ddc_*.dll)
  DelphiDoom.Ide.Vcl.*               TIdeExampleSynEdit, TIdeListPanel, TIdeTreePanel (codice comune dei pannelli)
  DelphiDoom.Ide.Composition         TIdeServices: l'unico punto che conosce le classi concrete
Libs\Ide\                            (40 unit, 4658 righe, senza VCL)
  Types, Messages, Intf, Views.Intf  tipi, testi dei messaggi, contratti
  Document, ProjectItem, Project, ProjectFormat, UndoHistory, UncountedObject, Pk3Builder, ItemKinds, Games, Text
  CompileCommand, CompilerMessages, PCodeFile, EventSnippets, ParameterHints, SearchHistory, SearchSettings, SearchPlan
  Csv, Outline, RowSorter, FieldFormatter, LibraryTable, NameValueTable, ActorDefFunctionTable, UnitFunctionTable,
  StateTables, StateCatalog, MobjinfoCatalog, ClassCatalog, SpriteCatalog, ExampleStore, ProjectOutline, MessageLog
  MainPresenter, ScriptEditorPresenter
Tests\DelphiDoom.Tests.Ide           (33 unit di test, 264 test) + Tests\Data\Ide
```

Schema: `IIde...` piccoli in `Libs\Ide`, implementazioni di sistema in `DD_IDE\DelphiDoom.Ide.Win.*`, un presenter per finestra con la sua interfaccia di vista
(`IIdeMainView`, `IIdeScriptEditorView`; il project manager segue il progetto come `IIdeDocumentObserver`). Le form non hanno costruttori con parametri
(le crea il DFM): ricevono i servizi con `Configure(TIdeServices)` dal programma (`DD_IDE.dpr`), che e il composition root.

### Numeri prima e dopo

| | Prima | Dopo |
|---|---|---|
| Unit in `DD_IDE\` (senza SynEdit) | 27 (11107 righe) | 28 (4762 righe) + 40 in `Libs\Ide` (4658 righe) |
| `main.pas` | 1255 righe | 680 righe |
| Variabili globali di logica | 19 (1 + 11 + 4 + 1 + 2) | 0 in `Libs\Ide` e nelle form; restano `inst`/`localload` del trasporto verso le DLL (`ddc_base`, usato anche da `ddc.exe`) e le variabili standard delle form VCL |
| `uses` circolari | 2 cicli | 0 |
| Test | 0 | 264 |
| Classi duplicate (esempi dei pannelli) | 7 sottoclassi di TSynEdit | 1 (`TIdeExampleSynEdit`) |

`ddc_base.pas` e passato da 840 a 390 righe: le funzioni che leggevano e tagliavano i csv per DD_IDE sono nei modelli di `Libs\Ide`.
Restano solo il trasporto verso le DLL (compila, disassembla, liste, funzioni delle unit): il comando `ddc.exe` e le DLL non sono cambiati.

## 3. Fette

1. `294ec885` correzione delle DLL `ddc_*` (blocco al caricamento).
2. `c20bc19e` documento, progetto, pk3, compilazione, messaggi del compilatore, file del codice compilato.
3. `f17e676f` modelli dei pannelli (csv, liste, alberi, ordinamento), hint, ricerca, esempi.
4. `fa6f9bbf` presenter della finestra principale e dell'editor di script, con finti nei test.
5. `5cb75b24` le form diventano sottili, composition root, cancellazione del codice vecchio.

## 4. Come si prova

- `build.bat Tests\DelphiDoom.Tests.Ide` e poi `bin\Tests\DelphiDoom.Tests.Ide.exe`.
- I golden (`Tests\Data\Ide\Projects`, `Compiler`, `Library`) sono stati prodotti dal **vecchio** codice linkando `ide_project` e i frame vecchi in un
  programma di prova (non nel repository: chiamava `TIDEProject`, `ddc_base` e i frame `TFrame_*` con le DLL vere di `bin\Tools`), prima di cambiare i sorgenti.
  Le righe `.msgs.txt` e i `.ddout` sono quelli delle DLL vere; per i pannelli ci sono le righe delle DLL (`Library\<gioco>.*.txt`) e
  le impronte FNV-1a di liste e alberi dei vecchi frame.
- Per compilare i test dal worktree il percorso relativo di DUnitX non si risolve: serve una giunzione
  `...\.claude\worktrees\Skema` -> `C:\Progetti\Skema` (o `DCC_UnitSearchPath`), poi `build.bat Tests\DelphiDoom.Tests.Ide`.
- A runtime (solo con `Tools\Esegui-gioco.ps1`, una sola esecuzione per volta): aprire un progetto con `DD_IDE.exe <file.ddide>`, doppio clic su uno script,
  pulsante di compilazione, "Browse Library".

## 5. Cosa resta nei form e perche

- Disegno e componenti VCL (alberi, liste, SynEdit, pulsanti, menu, dialoghi di stampa e anteprima di SynEdit).
- Nell'editor: la ricerca dell'evento nello script con l'evidenziatore di SynEdit (`TSynDDScriptSyn`, e SynEdit) e l'esecuzione della ricerca/sostituzione (`SearchReplace` di SynEdit);
  le opzioni e il piano sono nel presenter e nella libreria.
- `frm_PageSetup`, `frm_PrintPreview` (dentro `SynEdit\`), `frm_GotoLine`, `frm_ConfirmReplace`, `frm_message`: dialoghi senza regole.
- `ide_zipfile` (writer zip) e `ide_version` (versione dal file `.exe`) restano come implementazioni dietro `IIdeArchive` e `VersionText`.
- Le classi di `DelphiDoom.Ide.Win.Services` (orologio, cursore, appunti, domande) sono quattro in una unit: sono adattatori di poche righe.
