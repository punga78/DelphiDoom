# Censimento di `Libs\` e `Base\`: che cosa è id Tech e come ricavarne un framework

Analisi fatta il 2026-11-13, **senza spostare nulla**. Serve a decidere come organizzare le cartelle in modo che un secondo gioco (non Doom) usi il framework senza portarsi dietro il motore di id.

## 1. Metodo e limiti

- Per ogni `.pas` (esclusi `Tests\`, `Tools\`, `Reference\`, `bin\`, `dcu\` e le cartelle `Shim`) si leggono le clausole `uses` (interface e implementation), commenti e stringhe tolti, e ogni nome di unit si attribuisce alla cartella che la contiene. Area = `Base`, `Common`, una cartella di gioco, o `Libs\<Nome>` (`Libs\OpenGl` diviso nelle sue sottocartelle `Binding`, `Legacy`, `Recorder`).
- **Nomi duplicati**: 42 nomi di unit compaiono in più cartelle (22 uguali in `Doom`, `Heretic`, `Hexen` e `Strife`, 9 in tre giochi, e così via). I quattro giochi id sono trattati come un solo insieme; 4 `uses` restano ambigui (2 in `Base`, 2 in `OpenGl\Legacy`) e non sono attribuiti. Una prima versione senza questa cura dava dipendenze false da `Strife` e un ciclo con `Mp3`: gli shim (`Libs\Mp3\Shim`, `Libs\Script\Shim`) hanno nomi presi da `Base`.
- **Non distinti**: i `uses` dentro `{$IFDEF}` (`Base` usa `Radix` e `Speed` solo a certe condizioni: è composizione condizionale, non dipendenza di base).
- Due assi: l'**accoppiamento** è calcolato dai `uses`; il **dominio** (id Tech, formato, piattaforma, gioco) è assegnato a mano dalle descrizioni dell'indice di `CLAUDE.md` e dalle `README.md` di ogni libreria. Dalle dipendenze sole non si vede cosa è "di id": `Wad`, `Nodes`, `Udmf`, `Info`, `Thinkers` non dipendono da nulla di storico e sono comunque di dominio id Tech 1.

Numeri: 105 cartelle di `Libs\` (2261 `.pas`), `Base\` 404 unit e 164329 righe, `Common\` 3 file (22905 righe al momento del censimento, di cui `DirectX.pas` 16004, cancellato con la #189, e `d_delphi.pas` 6805), `Doom`, `Heretic`, `Hexen` e `Strife` 45, 38, 43 e 45 unit (81781, 77800, 128674 e 108655 righe).

## 2. Fatti emersi

1. **Le librerie sono pulite.** Su 105, solo 5 dipendono da codice fuori da `Libs\`: `ScriptHost` (28 unit di `Base`, 11 dei giochi id), `OpenGl\Legacy` (54 di `Base`, 11 dei giochi id), `Ddc` (4 e 3), `Mp3` (1 di `Base`, 1 di `Common`) e `PascalScript` (1 di `Common`). Tutto il resto dipende solo da altre librerie o da nulla.
2. **Il nucleo condiviso esiste già ed è dimostrato.** Chiusura transitiva delle librerie usate dai consumatori non-id (`OpenXcom`, `Keen`, `Greed`, `Speed`, `Libs\Xcom*`, `Keen`, `Greed`, `Racing`, `GameHost`, `War`) contro quelle usate dal lato id (`Base`, `Common`, i quattro giochi, `Radix`):
   - **usate da entrambi (23)**: Audio, Clock, CommandLine, GameData, Input, Logging, M2m, MathCore, Midi, Mikmod, Mp3, Ogg, OpenGlBinding, Palette, Platform, Png, Scanner, Sndfile, Sound, Speed, Video, Wad, Zlib;
   - **solo non-id (23)**: GameHost, Greed, Keen, Opl, Racing, War, Yaml e le 16 `Xcom*` (XcomMod, XcomFormats, XcomSave, XcomSurface, XcomUi, XcomEngine, XcomAudio, XcomMenu, XcomGeoscape, XcomBasescape, XcomStrategy, XcomBattle, XcomBattlescape, XcomBattleStates, XcomDebriefing, XcomUfopaedia);
   - **solo id (50)**: Acs, Actions, ActorDef, Automap, Blockmap, Configuration, Console, Ddc, Definitions, Dehacked, DynLights, Endoom, EngineSystem, GameState, GlAutomap, GlLevel, GlMath, GlScene, GlTexture, Glbsp, Hud, IdTech, Imaging, Info, Iwad, Jpeg, MapInfo, Models, MusInfo, Net, Nodes, Obituary, OpenGl\Legacy, Parity, PascalScript, Radix, Renderer, Screenshot, ScriptHost, Serializer, Specials, TableExport, Texture, TextureDefs, Thinkers, Threading, Udmf, Voxel, Xmi, Zone;
   - **non raggiunte (11)**: Collision, Geometry, IdLib (porte di id Tech 4, senza chiamanti), Ide, ToolsCore, EndoomEditor, Font, FontEditor, VoxelEditor (strumenti), Script (la DLL `DDScript`, caricata a runtime) e OpenGlBinding\Recorder.
3. **`GameHost` poggia sul framework giusto.** Dipende solo da `Logging` e da `OpenGlBinding` (`dglOpenGL`, una sola unit): il binding di OpenGL è generico, il renderer storico (`OpenGl\Legacy`, 39000 righe, 54 unit di `Base`) no. La cartella `Libs\OpenGl` però mette le due cose insieme.
4. **Tre cicli veri tra librerie** (Delphi li tollera con i `uses` di `implementation`, ma sono difetti di stratificazione):
   - `PascalScript` ↔ `ScriptHost` ↔ `Ddc` (`ps_dll`, `ps_import` stanno in `ScriptHost` e sono usate dal nucleo);
   - `Sndfile` ↔ `Sound` (`Sound` usa `delphidoom.sndfile.intf`, `Sndfile` usa `delphidoom.sound.factory`): **ciclo rotto (issue #222)**: il punto d'incontro e' `DelphiDoom.Sndfile.Factory.Intf` (`ISndfileFactory`); `Sndfile` non cita piu' nessuna unit di `Sound`, la dipendenza va solo da `Sound` a `Sndfile` (prova: `Tools\Verifica\222\Controlla-Cicli.ps1`);
   - `XcomStrategy` ↔ `XcomGeoscape` ↔ `XcomBasescape` (interfacce e simulazione del Geoscape stanno nel Geoscape, quelle della strategia nella Strategy). **Rotto (#223)**: `IXcomGeoscapeSimulation` scende in `XcomStrategy.Simulation.Intf`, `TXcomFunding` e `IXcomBasescapeNavigator` in `XcomGeoscape` (`Funding`, `BaseNavigator.Intf`): ordine `XcomStrategy` < `XcomGeoscape` < `XcomBasescape`, controllo `Tools\Verifica\223\Controlla-Cicli.ps1`.
5. **`Base\` è il motore id Tech 1 più la sua colla.** `r_*` 70 unit (64568 righe) e `p_*` 34 (27857) sono il nucleo di gioco e di rendering; `DelphiDoom.Engine.*` sono 212 unit (30454 righe) di adattatori che collegano le librerie ai globali storici (composition root); poi `v_*`, `udmf_*`, `i_*`, `m_*`, `am_*`, `w_*`, `s_*`, `po_*`, `info_*`, `hu_*`, `deh_*`, `sc_*`. Tutto id per costruzione.
6. **I quattro giochi id sono una grande duplicazione**: circa 400000 righe in `Doom`, `Heretic`, `Hexen` e `Strife` con 22 nomi di unit identici in tutti e quattro. Non è un tema del framework in sé (è la #185, "tutto a classi"), ma è il motivo per cui "lato id" pesa tanto.
7. **`Common\`** ha `d_delphi.pas` (shim storico della RTL di Delphi 7, 6805 righe) e `DirectX.pas` (16004, cancellato con la #189: non lo usava piu' nessuno se non `i_video` e il dispositivo audio).

## 3. Classificazione di `Libs\` (dominio assegnato a mano)

| Dominio | Librerie | Note |
|---|---|---|
| **Fondazione** (nessun legame con un gioco) | Logging, Platform, Clock, Threading, Zlib, Yaml, MathCore*, Configuration*, CommandLine | *miste: vedi sotto |
| **Formati e codec** | Png, Jpeg, Ogg, Mp3, Sndfile, Sound, Mikmod, Xmi, M2m, Midi, Opl, Imaging, Palette*, Wad*, Texture | `Wad` è anche il VFS generico (WAD, PAK, ZIP, cartelle) |
| **Servizi di runtime** | Audio, Input, Video*, Console*, Screenshot, Scanner, Serializer, Zone | `Zone` e `Serializer` sono i servizi di id Tech 1 (zone memory, savegame) |
| **Piattaforma di gioco** | GameHost, OpenGlBinding | già framework: l'esempio da seguire |
| **Scripting** | PascalScript, Script, ScriptHost, Ddc | `ScriptHost` e `Ddc` sono motore, non libreria (28 e 4 unit di `Base`) |
| **id Tech 1** | Acs, Actions, ActorDef, Automap, Blockmap, Definitions, Dehacked, DynLights, Endoom, Glbsp, Hud, Info, Iwad, MapInfo, MusInfo, Net, Nodes, Obituary, Renderer, Specials, TableExport, TextureDefs, Thinkers, Udmf, Voxel, Models, GlAutomap, GlLevel, GlMath, GlScene, GlTexture, OpenGl\Legacy, EngineSystem, GameState, GameData, IdTech, Parity, Radix | `GameData` e `Speed` sono dei fork id (Mars3D, Rad-X, Speed Haste) |
| **id Tech 3 e 4 (porte)** | IdLib, Collision, Geometry | nessun chiamante nel motore |
| **Giochi non id** | Keen, Greed, War, Racing, 16 `Xcom*` | su `GameHost` e nucleo, senza `Base` |
| **Strumenti** | Ide, ToolsCore, EndoomEditor, Font, FontEditor, VoxelEditor | |

Librerie **miste** da guardare una per una (la parte generica va separata da quella di Doom): ~~`MathCore`~~ (separata nella prima fetta della #225: `GameMath`, vedi "Esito della #225"), `Wad`, `Palette`, `Video`, `Input`, `Console`, `Audio`, `Configuration`.

## 4. Strati proposti

Una unit usa solo gli strati sotto di sé (chi sta a destra del `|` non dipende da chi sta a sinistra):

```
L0 Fondazione   Logging Platform Clock Threading Zlib Yaml MathCore(generico) GameMath(id Tech 1, L0) Configuration(formato) CommandLine
L1 Formati      Png Jpeg Ogg Mp3 Sndfile+Sound Mikmod Xmi M2m Midi Opl Imaging Palette Wad(VFS) Texture
L2 Servizi      Audio Input Video Console Screenshot Scanner Serializer
L3 Piattaforma  GameHost OpenGlBinding           (Scripting: PascalScript Script Ddc, opzionale)
-----------------------------------------------------------------------------------------------
Moduli          IdTech1 (Base + le librerie id)   IdTech3/4 (porte)   Giochi (Xcom* Keen Greed War Racing)   Strumenti
```

I moduli dipendono dagli strati, mai il contrario né tra loro. Oggi la regola è già rispettata da quasi tutte le librerie (fatto 1); mancano i quattro difetti del punto 5.

**Aggiornamento #228**: AudioMix (L2 Servizi, solo RTL) e' il mixing software comune a XcomAudio, War e Greed (lista di voci con lucchetto, strategie di voce e di ricampionamento, saturazione a 16 bit; i campioni dei tre giochi sono rimasti identici byte per byte; seconda fetta: sintetizzatore MIDI `TPcmMidiSynth` spostato da XcomAudio e `TPcmLevelMeter` di picco/RMS al posto di due cicli duplicati in Xcom e Greed); vedi Libs\AudioMix\CLAUDE.md.

## 5. Che cosa correggere prima di muovere cartelle

1. **Dividere `Libs\OpenGl`** (fatto, #220): `Libs\OpenGlBinding` (`dglOpenGL` e il registratore, strato L3) e `Libs\OpenGl\Legacy` (renderer, modulo id Tech 1). Costo basso: `GameHost` usa una sola unit.
2. **Portare `ScriptHost` e `Ddc` sul lato motore** o separare in `ScriptHost` ciò che è generico (registro delle funzioni, serializzatore) da ciò che usa `Base` (28 unit). Rompe anche il primo ciclo (con `ps_dll` e `ps_import` nel nucleo).
3. **Rompere gli altri due cicli**: `Sndfile`↔`Sound` (spostare il punto di incontro in una `*.Intf`) e `XcomGeoscape`↔`XcomBasescape`↔`XcomStrategy` (estrarre le interfacce condivise).
4. **Togliere `Common` dal nucleo**: fatto con la #224 (vedi "Esito della #224").
5. **Dividere le librerie miste** (§3) quando ci si lavora sopra, non in massa.

## 6. Come organizzare le cartelle: due strade

**A. Alberi nuovi** (`git mv` meccanico, zero modifiche al codice, come nella #170 e nella #172):

```
Framework\Core, Formats, Services, Host, Scripting
IdTech1\ (Base, Libs id Tech 1, Doom, Heretic, Hexen, Strife, Radix, Speed)
IdTech4\ (IdLib, Collision, Geometry)
Games\    (Xcom\ Keen\ Greed\ War\ Racing\)
Tools\    (Ide, ToolsCore, EndoomEditor, Font*, VoxelEditor, DD_*)
```

Costo misurato: 123 dei 130 `.dproj` citano `Libs` in `DCC_UnitSearchPath` (242 righe da riscrivere), la tabella di `Tools\build.bat` (5 righe), 101 `README.md` e 101 `CLAUDE.md` di libreria, l'indice di `CLAUDE.md`, `Tests\*.dproj` e 19 script di `Tools\*.ps1` che citano `Libs\`. Fatto meccanico, da verificare con eseguibili identici in dimensione come nella #170. **Prima si fanno le correzioni del §5**, altrimenti si sposta un difetto.

**B. `Libs\` resta piatta, gli strati vanno in un manifesto con un controllo automatico.** Un file `Libs\STRATI.md` (o un `.psd1`) assegna ogni libreria a uno strato o a un modulo, e uno script (stile `Tools\Verifica\*`, derivato da quello usato per questo censimento) fallisce se una libreria usa uno strato più alto o un modulo. Costo molto più basso, niente `.dproj` da toccare, e i difetti del §5 diventano la lista dei "fuori regola". Si possono poi spostare le cartelle in un secondo tempo, con la regola già verificata.

**Raccomandazione**: B subito (con le correzioni 1 e 3 del §5) e A come secondo passo, a fette, quando il controllo è verde. Non è una scelta irreversibile: B è il prerequisito di A.

## 6. Librerie arrivate dopo il censimento (aggiornamento issue #229, 2026-11-13)

Sei cartelle di `Libs\` sono nate dopo l'analisi dei punti 1-5 (che resta com'e'): non sono nei numeri di sopra. Classificazione per dominio e strato, dalle `uses` e dalle descrizioni dell'indice di `CLAUDE.md`; nessuna e' raggiunta dal motore o dai giochi non id (**non cambiano** le liste "usate da entrambi / solo id / non raggiunte" del punto 2, salvo `Cinematic` e `Flic` sotto).

| Libreria | Dominio | Strato | Dipende da | Note |
|---|---|---|---|---|
| `Flic` (nuova, #229) | Formati e codec | L1 Formati | solo la RTL | decoder FLI/FLC spostato da `XcomFormats` (era `TXcomFlcDecoder`); usata da `XcomFormats` (adattatore) e `Cinematic`; `TGreedFliDecoder` resta separato, con motivo, in `Libs\Flic\CLAUDE.md` |
| `Cinematic` (#114, #199) | Formati e codec (RoQ di id Tech 3/4 e FLIC) | L1 Formati | `Flic`, `IdLib`, `Imaging` | **violazione di strato risolta**: prima dipendeva da `XcomFormats` (una libreria di un gioco); ora no. Il RoQ e' di dominio id Tech 3/4, il FLIC e' generico: se cresce, il FLIC puo' stare nella sola `Flic` |
| `Compression` (#98) | Formati e codec (compressori `idCompressor`) | L1 Formati (porta id Tech 4) | `IdLib` | senza chiamanti; accanto a `Zlib` ma con algoritmi propri di id |
| `MapFile` (#106) | id Tech 4 (porta) | Modulo IdTech3/4 | `Geometry`, `IdLib`, `MathCore`, `Scanner` | file `.map`; senza chiamanti |
| `Decl` (#100, #102, #119) | id Tech 4 (porta) | Modulo IdTech3/4 | `IdLib`, `Imaging`, `Scanner` | gestore delle dichiarazioni; senza chiamanti |
| `Gui` (#111, #125) | id Tech 3 (porta) | Modulo IdTech3/4 | `IdLib`, `Scanner` | menu `.menu` di Team Arena e font `.dat`; nessun disegno, nessun input |
| `BotAi` (#123, #124) | id Tech 3 (porta) | Modulo IdTech3/4 | `IdLib`, `Scanner` | chat dei bot di botlib; senza chiamanti |

Da fare e non fatto qui: `Libs\Aas` (#122) e `AudioMix` (#228) erano in lavorazione in altri rami quando questa sezione e' stata scritta e non sono classificate; le sei librerie sopra non hanno cicli con le altre. **Duplicazioni viste in questo giro** (da unificare nelle fette seguenti della #229 o in altre issue): lettore ILBM (`XcomFormats.TXcomLbmReader` e `Keen.Shape`), lettore di byte (otto copie, fetta 2 della #229), decoder FLI (`Flic` e `Greed.FliDecoder`: differiscono nei byte, vedi `Libs\Flic\CLAUDE.md`).

## 7. Controllo automatico degli strati (issue #219, 2026-11-14)

La strada B del punto 6 e' fatta: manifesto `Libs\Strati.psd1` (spiegato in `Libs\STRATI.md`) e controllo `Tools\Verifica\219\Controlla-Strati.ps1` (prova: `Prova-Controlla-Strati.ps1` su 18 casi di `Tests\Data\Strati`; `Tools\build.bat strati` esegue entrambi). Lo script estende il metodo del punto 1 (nomi duplicati, cartelle `Shim`, `uses` sotto `{$IFDEF}` dichiarati a parte) e ne chiude i difetti noti in un elenco di eccezioni con motivo e issue che le toglie.

**Stato reale sul repository** (3972 `.pas`, 133 aree, 10153 `uses` verso unit del repository di cui 378 sotto `{$IFDEF}`, 444 archi tra aree, 11 usi ambigui ma ammessi, 6 usi risolti da una `Shim`):

| Strato o modulo | Aree | File |
|---|---|---|
| L0 Fondazione | 11 | 236 |
| L1 Formati e codec | 18 | 397 |
| L2 Servizi di runtime | 9 | 277 |
| L3 Piattaforma e scripting | 6 | 130 |
| modulo IdTech1 | 48 (8 cartelle di prodotto, 40 librerie) | 1248 |
| modulo IdTech4 | 8 | 409 |
| modulo Giochi | 23 (3 cartelle di prodotto, 20 librerie) | 1100 |
| modulo Strumenti | 10 (3 cartelle di prodotto, 7 librerie) | 175 |

**Violazioni nuove: 0. Eccezioni dichiarate: 9** (tutte coppie di aree, nessun ciclo; erano 14 prima della #221): #224 2 (`Common` da `PascalScript` e `ScriptHost`), #225 4 (`Console` -> `GameState`, `Palette` -> `Video`, `Greed` e `Libs\Greed` -> `Net`; `Palette` -> `Video` tolta dalla seconda fetta della #225), #226 1 (`Speed` -> `Racing`), #229 1 (`Opl` -> `XcomFormats`). I cicli `Sndfile`-`Sound` (#222) e `XcomStrategy`-`XcomGeoscape`-`XcomBasescape` (#223) non ci sono piu'; non servono eccezioni per #220 (`OpenGlBinding` e `OpenGl\Legacy` sono gia' aree distinte).

**Che cosa ha mostrato che il censimento non diceva**: (1) `IdLib` e `Geometry` (nessuna dipendenza) sono ormai la base di `MathCore`, `Scanner`, `Wad`, `Imaging`, `Audio`, `Console`, `Net`, `Models`: nel manifesto stanno in L0, non nel modulo id Tech 4; con loro `Cinematic` e `Compression` sono L1 e `Models` L2. (2) Le librerie miste con un uso fuori regola sono `Console`, `Palette`, `Net` (non era nell'elenco di #225: va aggiunta), `Opl` e la cartella `Speed` (due programmi insieme). (3) `Mp3` nasconde con la `Shim` unit di `Base` e `Common` (6 usi; quella di `Script` non nasconde nessun uso): non sono archi, ma restano il contenuto di #224. (4) `ScriptHost` usa 30 unit di `Base` (il censimento ne contava 28) e 9 dei giochi id; `Ddc` 4 e 3. **Corretto dalla #221 (2026-11-14)**: vedi "Esito della #221" sotto.

Regola d'uso dalla #226 in poi: spostare una cartella (o correggere un difetto) si fa con il controllo verde; quando un'eccezione diventa stantia (uscita 2) la si toglie nello stesso commit.

### Esito della #221 (2026-11-14): `ScriptHost` e `Ddc` separati dal motore, ciclo con `PascalScript` rotto

- **Generico** (resta in `Libs\ScriptHost`, strato L3, nessun `uses` verso `Base` ne' i giochi): registro delle funzioni, variabili, eventi, serializzatore, catalogo delle classi, costanti, overlay, sezioni del mondo con i loro gateway (interfacce), e da `ps_import` le classi `TDoomCompiler` (`DelphiDoom.ScriptHost.Compiler`), `TDoomExec` (`.Exec`) e `TPSDoomRuntimeClassImporter` (`.ClassImporter`), piu' l'intestazione dei compilati (`.Compiled`).
- **Collegamento al motore di id Tech 1**: nuova `Libs\ScriptEngine` (modulo `IdTech1`): `ps_main`, `ps_import` (ora solo la facciata `PS_Configure*` e le tabelle di PS_GAME e PS_OVERLAY), `psi_game`, `psi_globals`, `psi_map`, `psi_overlay`, `psi_system`, il manager degli script (`DelphiDoom.ScriptEngine.Manager`, ex `DelphiDoom.ScriptHost.Manager`) e `dd_compiler` (ex `Libs\Ddc`: l'implementazione delle DLL `ddc_<gioco>`). Le classi del motore che rispondono alla libreria restano in `Base\DelphiDoom.Engine.Script.*` e `ComposeScriptHost` le assembla come prima.
- **Ciclo**: il nucleo (`Libs\PascalScript`) non conteneva piu' di tre unit che puntavano fuori: `uPSR_dll` (usa `ps_dll`), `uPSC_dll` e `uPSDisassembly` (usa `TDoomExec`) non erano usate dal nucleo ma solo dal collegamento; sono passate a `Libs\ScriptHost` con `git mv`, senza toccare il codice di terzi. `ps_import` usava `ddc_base` solo per la versione dei compilati: ora `DDCVERSION = SCRIPT_COMPILED_VERSION` (`Compiled`) e `ddc_base` non e' piu' usato dal collegamento.
- **Eccezioni tolte** da `Libs\Strati.psd1`: `ScriptHost -> Base` (30 unit), `ScriptHost -> GiochiId` (9), `Ddc -> Base` (4), `Ddc -> GiochiId` (3), il ciclo `PascalScript <-> ScriptHost <-> Ddc` e, come conseguenza, `Ddc -> Common` (#224). Le due di #224 (`PascalScript -> Common`, `ScriptHost -> Common`) le ha tolte la #224: vedi "Esito della #224".
## Esito della #224 (2026-11-15)

- `Libs\PascalScript`, `Libs\ScriptHost` e `Libs\Mp3` non usano piu' nulla di `Common` ne' di `Base`. **PascalScript e ScriptHost**: `d_delphi` non serviva (la sola funzione usata, `CharPos`, e' gia' sostituita da `ps_utils.PSCharPos`; `TDoomCompiler.unitnames`, mai letta, e' una `TStringList` al posto di `TDStringList`); `Doom32.inc` e' sostituito da `Libs\PascalScript\PascalScriptCodegen.inc` (solo gli interruttori di generazione del codice; lo usa anche `ddc_base`). **Mp3**: `TMp3Source` (`Libs\Mp3\Decoder\mp3_Source.pas`) al posto di `TDStream`, `FreeAndNil`, `TByteArray` e `Sleep` dalla RTL, `I_Error` e' `raise Exception.Create(...)` come nello shim (nel motore prima chiudeva il programma: sono il `TBitReserve` che non si crea e il guasto del dispositivo d'uscita, percorsi mai visti), `Mp3Codegen.inc` al posto di `Doom32.inc`. Cancellate `Libs\Mp3\Shim` (3 unit) e `Libs\Script\Shim` (2 file). Eccezioni tolte da `Libs\Strati.psd1`: 2 (da 10 a 8); usi risolti da una cartella `Shim`: da 6 a 0; violazioni nuove: 0.

## Esito della #225, prima fetta: `MathCore` diviso (2026-11-15)

- **Taglio**: nuova libreria `Libs\GameMath` (strato **L0**, riga in `Aree` di `Libs\Strati.psd1`) con le 19 unit di id Tech 1 di `MathCore`, spostate con `git mv` e **non rinominate** (restano `DelphiDoom.MathCore.*`: nessun `uses` cambia): `Types`, `FixedMath`, `Trigonometry`, le cinque `Table*` trigonometriche, `BoundingBox`, `VectorMath`, `X87Double`, `PixelBatch`, e il generatore casuale di Doom con `Intf`, `GameRandom`, `TableRandom`, `TableSysRandom`, `SystemEntropySource`, `StringHashTable`, `Factory`. In `MathCore` restano le parti generiche: `Crc32`, `TableCrc32`, `Sha1`, `IntegerStack`, `IntegerQueue`, `MemoryFill`, `SoftExtended`, `Float.*` (id Tech 4), `Patch.*` (Quake III).
- **Perche' L0 e non il modulo `IdTech1`**: la virgola fissa la usano anche Greed, Racing e Keen (modulo `Giochi`), che non possono usare un modulo. **Perche' questi file**: `Types` e' usata solo da unit di id Tech 1 e `GameRandom` usa `Trigonometry`; tenere `Intf`/`GameRandom` in `MathCore` avrebbe fatto un ciclo tra le due librerie. `GameMath` usa `MathCore`, mai il contrario (controllo degli strati: 0 violazioni nuove, nessuna eccezione nuova).
- **Percorsi**: 41 `.dpr` (elenchi `in`), 30 `.dproj` (`DCC_UnitSearchPath` con `..\Libs\GameMath`) e gli script di `Tools\Verifica` con `Libs\MathCore` nel percorso sono aggiornati; il progetto di test `DelphiDoom.Tests.MathCore` resta uno (dividerlo e' lavoro successivo).
- **Resta della #225**: `Wad`, `Console` (eccezione verso `GameState`), `Audio`, `Configuration`, l'eccezione `Greed` -> `Net` (`Net` e' mista; quella `Pmove` -> `Net` e' stata tolta nella #237: le unit `Net.Q3.*` sono in `Libs\NetQ3`) e, senza eccezioni, la parte di Doom di `Video` (`ScreenSizeResolver`, `MemoryStallHack`, `DeferredNotifications`) e di `Palette` (vedi la seconda fetta qui sotto).

## Esito della #225, seconda fetta: `Palette`, `Video`, `Input` (2026-11-15)

- **Taglio minimo**: `IPaletteConverter` (palette di gioco a 256 colori RGB, con gamma, in `$00RRGGBB`) e `TPaletteConverter` stavano in `Video` (L2) ed erano l'unica unit di `Video` che `Palette` (L1) usava (`Factory` e `Unpacker`): sono passati a `Libs\Palette` come `DelphiDoom.Palette.Intf` (l'interfaccia, stesso GUID) e `DelphiDoom.Palette.Converter` (`git mv` dell'unit, stesso corpo; unica unit rinominata). `Video` ora usa `Palette` (`Video.Intf`, `Video.Services`, `Video.Factory`); `TVideoFactory.CreatePaletteConverter` e `IVideoServices.Palette` restano, quindi i chiamanti del motore non cambiano. Eccezione `Palette` -> `Video` di `Libs\Strati.psd1` tolta (le dichiarate passano da 8 a 7).
- **Perche' non altro**: `Input` e' gia' generica (dispositivi di tastiera, mouse e joystick e le loro interfacce; la usano anche Keen e Greed, modulo `Giochi`, e il suo strato L2 le e' consentito): la parte di Doom e' solo `TInputPoller` (eventi verso `D_PostEvent`), che usa solo le interfacce della libreria, e la tabella dei tasti sta nel motore (`Base\DelphiDoom.Engine.Input.KeyMap`): niente da spostare. `Video` dopo lo spostamento e' usata solo dal motore id Tech 1 (e dal test di Keen; i `DCC_UnitSearchPath` di Greed, Keen, Xcom e War la nominano senza usarla nei sorgenti di prodotto), ma non ha eccezioni e dividerla (`ScreenSizeResolver` e `MemoryStallHack` di Doom da catalogo dei modi, metriche e limiti generici) vuole un taglio di `Video.Intf` che adesso non serve a nessuno strato: resta aperta, senza eccezione.
- **`Palette`, parte di Doom (non separata)**: `PlayerTranslations.*`, `TranslationBlood`, `ColorRegionLumps`, `Profiles`, `LightTables`, `PrecalcTables`, `GammaData`, `GamePalettes` sono di id Tech 1, ma i soli utenti sono `Base` e i giochi id, `Radix`, `Speed`, `GameData` (modulo `IdTech1`) e `Font`, `FontEditor`, `VoxelEditor` (`Strumenti`): nessuno strato basso ne' modulo `Giochi` le usa, quindi uno spostamento non toglie nessuna dipendenza e avrebbe toccato decine di `.dpr`; resta per quando un gioco non id vorra' solo `Builder`, `ColorMatcher` e `Converter`.
- **Percorsi**: 16 `.dpr` (elenco `in`) e 14 `.dproj` (`..\Libs\Palette` nel `DCC_UnitSearchPath` dove c'era `..\Libs\Video`: Greed32, Keen32, Xcom32, Warcraft32 e i test di Greed, Keen, Video e Xcom*).

## Esito della #225, terza fetta: `Console`, `Wad`, `Configuration` (2026-11-15)

- **`Console`: eccezione verso `GameState` risolta.** `Console` usava `IGameContext` solo per un dato: `IsNetGame` (in `TConsoleVariableCommands.CanSet`: in rete una variabile si cambia solo se `camNetwork`). Ora `TConsoleFactory.CreateVariableCommands` e `TConsoleVariableCommands` ricevono `TConsoleNetGameQuery` (`reference to function: Boolean`, in `DelphiDoom.Console.Types`) al posto dell'interfaccia; `ComposeConsole` passa `function: Boolean begin Result := AGame.IsNetGame end` (una riga in `Base\DelphiDoom.Engine.Composition.pas`, nessuna unit nuova, nessun `.dpr` cambia). Stessa risposta a ogni chiamata (la funzione legge il gioco quando serve). Eccezione `Console` -> `GameState` tolta da `Libs\Strati.psd1` (da 7 a 6 dichiarate). Il meccanismo di Doom (cheat, `TEngineConsoleScreen`) e' gia' nel motore (`Base\DelphiDoom.Engine.Console.*`) e i profili id Tech 4 e Quake III sono unit `*.IdTech4.*`/`*.Q3.*` separate nella stessa cartella: niente altro da dividere senza togliere dipendenze.
- **`Wad`: non separata, senza eccezione.** Le due metà sono la directory dei lump di id Tech 1 (`Directory`, `Source.*`, `Name`, `LumpCache`, `Indicators`, `Pak.*`, usate da `Base\w_*` e dai `.dpr` dei giochi) e il file system per percorso di id Tech 4/Quake III (`Fs.*`, `Zip.Intf`, usate da `Decl`, `Models`, `Console.Q3`, `Audio` e dai test). Ma `Wad` e' in **L1** e usa solo `IdLib` (**L0**): ogni consumatore (strati L2, moduli `IdTech1`, `IdTech4`, `Strumenti`) e' gia' ammesso, quindi uno spostamento di `Fs.*` non toglie nessuna dipendenza e non c'e' nessuna eccezione da chiudere; costerebbe `DDWad.dpr`, il progetto di test (363 test, 94% di copertura), 8 progetti di test consumatori e i `DCC_UnitSearchPath`, e il file `DelphiDoom.Wad.Fs.*` ha le sue regole di dominio id (cartelle di gioco, `fs_*path`). Si fa se un gioco fuori da id Tech vorra' i soli formati PAK/ZIP.
- **`Configuration`: non separata.** E' gia' tutta generica: `Format`, `Document`, `Writer`, `Values`, `Table`, `TableStore`, `Item` non nominano il motore (la tabella lega i nomi a un `IConfigurationValueAccess` dato dal composition root; le voci di Doom stanno in `Base\m_defs` e `DelphiDoom.Engine.Configuration.*`). Le sole costanti di Doom sono l'intestazione `[Delphi Doom ver 2.07]` e le versioni accettate in `Configuration.Types`, usate dal formato; non ha dipendenze (L0) e nessun consumatore fuori dal motore: separare non toglie niente.
- **Resta della #225**: `Audio` (un altro agente, #228), le eccezioni `Pmove` -> `Net` e `Greed` -> `Net` (`Net` e' mista: trasporto, protocollo dei ticcmd di Doom e tipi di Quake III), e senza eccezioni la parte di Doom di `Video` e `Palette` e la divisione di `Wad` (vedi sopra).
