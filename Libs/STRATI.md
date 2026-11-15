# Strati delle librerie (issue #219)

Ogni cartella di `Libs\` (e `Base`, `Common`, le cartelle dei giochi e dei programmi) sta in **uno strato** o in **un modulo**.
Il dato letto dallo script e' `Libs\Strati.psd1`; questo file ne spiega le regole. Analisi di partenza: `docs\FRAMEWORK_CENSIMENTO.md`.

## Regola

- Uno **strato** (`L0` ... `L3`) puo' usare solo strati **uguali o piu' bassi**. Non usa mai un modulo.
- Un **modulo** puo' usare ogni strato, se stesso e i moduli che dichiara in `Ammessi` (oggi solo `Strumenti` -> `IdTech1`). I moduli non si usano tra loro.
- Dentro uno stesso strato le librerie si usano liberamente, ma **non devono formare cicli**; dentro un modulo anche i cicli sono ammessi (`Base` e le sue librerie sono un solo corpo).

| Strato | Titolo | Aree (`Libs\` salvo dove scritto) |
|---|---|---|
| `L0` | Fondazione | Bytes Clock CommandLine Configuration GameMath Geometry IdLib Logging MathCore Platform Threading Yaml Zlib |
| `L1` | Formati e codec | Cinematic Compression Flic Imaging Jpeg M2m Midi Mikmod Mp3 Ogg Opl Palette Png Sndfile Sound Texture Wad Xmi |
| `L2` | Servizi di runtime | Audio AudioMix Console Input Models Scanner Screenshot Serializer Video |
| `L3` | Piattaforma e scripting | GameHost OpenGlBinding OpenGlBinding\Recorder PascalScript Script ScriptHost Ddc |
| `IdTech1` (modulo) | id Tech 1 | `Base`, `Common`, `Doom`, `Heretic`, `Hexen`, `Strife`, `Radix`, `Speed` (cartelle) e le librerie `Acs` ... `Zone` (49 aree, con `ScriptEngine`) |
| `IdTech4` (modulo) | Porte di id Tech 3 e 4 | Aas BotAi Collision Decl DoomScript Gui MapFile NetQ3 Pmove Qvm |
| `Giochi` (modulo) | Giochi non id | Keen Greed War Racing, le 16 `Xcom*`, e le cartelle `Keen`, `Greed`, `OpenXcom` |
| `Strumenti` (modulo) | Strumenti | Ide ToolsCore EndoomEditor Font FontEditor VoxelEditor Launcher e le cartelle `DD_IDE`, `DD_Tools`, `Launcher` |

Differenze dal censimento (`docs\FRAMEWORK_CENSIMENTO.md`), motivate dai `uses` di oggi:

- `IdLib` e `Geometry` stanno in **L0**: non hanno nessuna dipendenza e li usano `MathCore`, `Scanner`, `Wad`, `Imaging`, `Audio`, `Console`, `Net` e `Models` (nel censimento erano porte senza chiamanti).
- `MathCore` e' stata divisa (#225, prima fetta): la parte generica (CRC, SHA-1, `Float.*`, `Patch.*`) resta in `MathCore`, la matematica di id Tech 1 (virgola fissa, tabelle, generatore casuale di Doom, `X87Double`) e' in `GameMath`, **L0 e non modulo** perche' la usano anche `Greed`, `Racing` e `Keen` (modulo `Giochi`). Le unit hanno ancora il nome `DelphiDoom.MathCore.*`. `GameMath` usa `MathCore`, mai il contrario.
- `Palette` e' in **L1** e non usa piu' `Video` (L2): `IPaletteConverter` e `TPaletteConverter` (gamma e impacchettamento in `$00RRGGBB`, nessuna dipendenza dal video) sono passati da `Video` a `Palette` come `DelphiDoom.Palette.Intf` e `DelphiDoom.Palette.Converter` (#225, seconda fetta); `Video` usa `Palette`. `Input` e `Video` non hanno altro da separare dal censimento: vedi `docs\FRAMEWORK_CENSIMENTO.md`.
- `Cinematic` e `Compression` stanno in **L1** (formati; il censimento li dava gia' come L1 Formati), `Models` in **L2** (formato dei modelli, usa `Scanner`; lo usa `Qvm`).
- `Libs\OpenGl` e' stato diviso (#220): `Libs\OpenGlBinding` (L3: `dglOpenGL.pas` e il registratore di chiamate in `Recorder`, usati da `GameHost`) e `Libs\OpenGl\Legacy` (modulo `IdTech1`, il renderer di Doom).
- `ScriptHost` e `Ddc` sono in L3 (scripting generico) e **non usano piu' il motore** (#221): il collegamento a id Tech 1 e' `Libs\ScriptEngine` (modulo `IdTech1`).

## Come si usa

```
powershell -File Tools\Verifica\219\Controlla-Strati.ps1 [-Riepilogo] [-Dettaglio] [-Grafo]
Tools\build.bat strati            # prova dello script sui casi di Tests\Data\Strati + controllo del repository
powershell -File Tools\Verifica\219\Prova-Controlla-Strati.ps1 [-Caso <nome>]
```

Uscita **0**: nessuna violazione nuova e nessuna eccezione da aggiornare. **1**: violazione nuova (uso di uno strato piu' alto o di un modulo non ammesso, ciclo nuovo, eccezione superata, area non assegnata); l'elenco dice file, unit usata, area e strato di partenza e di arrivo (e la condizione `{$IFDEF}` se c'e'). **2**: solo eccezioni stantie (il difetto e' stato corretto: togliere o ridurre la voce). `-Riepilogo` stampa i numeri per strato, `-Dettaglio` elenca ogni uso coperto da un'eccezione, `-Grafo` gli archi tra aree.

### Come si aggiunge una libreria

1. Creare `Libs\<Nome>` con le sue unit (una cartella = una area; le sottocartelle appartengono alla cartella).
2. Aggiungere una riga a `Aree` in `Libs\Strati.psd1`: `'Libs\<Nome>' = '<strato o modulo>'`. Scegliere il **piu' basso** strato che contiene le sue dipendenze (si vede con `-Grafo`); una libreria di un gioco o di id Tech va nel modulo corrispondente. Senza la riga il controllo fallisce con `AREA NON ASSEGNATA`.
3. Eseguire `Tools\build.bat strati`. Se la libreria usa uno strato piu' alto non si aggiunge un'eccezione: si sposta la dipendenza (un'interfaccia piccola nello strato basso, iniettata) o si cambia strato.
4. Una cartella di prodotto fuori da `Libs\` (un nuovo gioco) si aggiunge alla stessa tabella con il suo modulo.

### Eccezioni

Le eccezioni stanno in `Eccezioni` e dichiarano i **difetti noti**: `Da`, `A`, `Massimo` (numero di unit di arrivo distinte coperte), `Issue` (la issue che la toglie) e `Motivo`; oppure un `Ciclo`. Un uso fuori regola coperto e' "eccezione nota"; oltre `Massimo` e' una violazione nuova; senza piu' usi (o con meno unit) l'eccezione e' stantia e va tolta o ridotta insieme alla correzione. Oggi: 6 (tutte coppie, nessun ciclo; quelle di #224, `Palette` -> `Video` e `Console` -> `GameState` sono state tolte): #225 (`Greed` -> `Net`, piu' `Pmove` -> `Net`), #226 (`Speed` -> `Racing`), (la #229 `Opl` -> `XcomFormats` e' stata tolta: il contratto dell'archivio CAT sta in `Libs\Bytes`, L0).

## Metodo e limiti

- Si leggono i `uses` di interface e implementation di ogni `.pas` (commenti e stringhe tolti; `Tests`, `Tools`, `Reference`, `bin`, `dcu` esclusi). Non si leggono i `.dpr`, ne' gli `.inc`.
- **Nomi duplicati** (42 nomi in piu' cartelle): vince l'area del file (compresa la sua cartella `Shim`); le cartelle in `Gruppi` (i quattro giochi id) contano come una; se restano piu' aree e almeno una e' ammessa l'uso e' "ambiguo" (conteggiato, nessun arco), altrimenti e' una violazione. Una cartella `Shim` dentro una libreria sarebbe visibile solo a lei e il riepilogo ne conta a parte gli usi; oggi non ce ne sono (la #224 ha cancellato `Libs\Mp3\Shim` e `Libs\Script\Shim`).
- **`{$IFDEF}`**: gli `uses` sotto una condizione contano come gli altri (composizione condizionale) ma sono marcati con la condizione e contati a parte (378 su 10153 oggi).
- **Cicli**: componenti fortemente connesse del grafo tra aree, senza gli archi dentro uno stesso modulo e senza quelli gia' violazioni.
