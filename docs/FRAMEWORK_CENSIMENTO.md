# Censimento di `Libs\` e `Base\`: che cosa è id Tech e come ricavarne un framework

Analisi fatta il 2026-11-13, **senza spostare nulla**. Serve a decidere come organizzare le cartelle in modo che un secondo gioco (non Doom) usi il framework senza portarsi dietro il motore di id.

## 1. Metodo e limiti

- Per ogni `.pas` (esclusi `Tests\`, `Tools\`, `Reference\`, `bin\`, `dcu\` e le cartelle `Shim`) si leggono le clausole `uses` (interface e implementation), commenti e stringhe tolti, e ogni nome di unit si attribuisce alla cartella che la contiene. Area = `Base`, `Common`, una cartella di gioco, o `Libs\<Nome>` (`Libs\OpenGl` diviso nelle sue sottocartelle `Binding`, `Legacy`, `Recorder`).
- **Nomi duplicati**: 42 nomi di unit compaiono in più cartelle (22 uguali in `Doom`, `Heretic`, `Hexen` e `Strife`, 9 in tre giochi, e così via). I quattro giochi id sono trattati come un solo insieme; 4 `uses` restano ambigui (2 in `Base`, 2 in `OpenGl\Legacy`) e non sono attribuiti. Una prima versione senza questa cura dava dipendenze false da `Strife` e un ciclo con `Mp3`: gli shim (`Libs\Mp3\Shim`, `Libs\Script\Shim`) hanno nomi presi da `Base`.
- **Non distinti**: i `uses` dentro `{$IFDEF}` (`Base` usa `Radix` e `Speed` solo a certe condizioni: è composizione condizionale, non dipendenza di base).
- Due assi: l'**accoppiamento** è calcolato dai `uses`; il **dominio** (id Tech, formato, piattaforma, gioco) è assegnato a mano dalle descrizioni dell'indice di `CLAUDE.md` e dalle `README.md` di ogni libreria. Dalle dipendenze sole non si vede cosa è "di id": `Wad`, `Nodes`, `Udmf`, `Info`, `Thinkers` non dipendono da nulla di storico e sono comunque di dominio id Tech 1.

Numeri: 105 cartelle di `Libs\` (2261 `.pas`), `Base\` 404 unit e 164329 righe, `Common\` 3 file (22905 righe, di cui `DirectX.pas` 16004 e `d_delphi.pas` 6805), `Doom`, `Heretic`, `Hexen` e `Strife` 45, 38, 43 e 45 unit (81781, 77800, 128674 e 108655 righe).

## 2. Fatti emersi

1. **Le librerie sono pulite.** Su 105, solo 5 dipendono da codice fuori da `Libs\`: `ScriptHost` (28 unit di `Base`, 11 dei giochi id), `OpenGl\Legacy` (54 di `Base`, 11 dei giochi id), `Ddc` (4 e 3), `Mp3` (1 di `Base`, 1 di `Common`) e `PascalScript` (1 di `Common`). Tutto il resto dipende solo da altre librerie o da nulla.
2. **Il nucleo condiviso esiste già ed è dimostrato.** Chiusura transitiva delle librerie usate dai consumatori non-id (`OpenXcom`, `Keen`, `Greed`, `Speed`, `Libs\Xcom*`, `Keen`, `Greed`, `Racing`, `GameHost`, `War`) contro quelle usate dal lato id (`Base`, `Common`, i quattro giochi, `Radix`):
   - **usate da entrambi (23)**: Audio, Clock, CommandLine, GameData, Input, Logging, M2m, MathCore, Midi, Mikmod, Mp3, Ogg, OpenGl\Binding, Palette, Platform, Png, Scanner, Sndfile, Sound, Speed, Video, Wad, Zlib;
   - **solo non-id (23)**: GameHost, Greed, Keen, Opl, Racing, War, Yaml e le 16 `Xcom*` (XcomMod, XcomFormats, XcomSave, XcomSurface, XcomUi, XcomEngine, XcomAudio, XcomMenu, XcomGeoscape, XcomBasescape, XcomStrategy, XcomBattle, XcomBattlescape, XcomBattleStates, XcomDebriefing, XcomUfopaedia);
   - **solo id (50)**: Acs, Actions, ActorDef, Automap, Blockmap, Configuration, Console, Ddc, Definitions, Dehacked, DynLights, Endoom, EngineSystem, GameState, GlAutomap, GlLevel, GlMath, GlScene, GlTexture, Glbsp, Hud, IdTech, Imaging, Info, Iwad, Jpeg, MapInfo, Models, MusInfo, Net, Nodes, Obituary, OpenGl\Legacy, Parity, PascalScript, Radix, Renderer, Screenshot, ScriptHost, Serializer, Specials, TableExport, Texture, TextureDefs, Thinkers, Threading, Udmf, Voxel, Xmi, Zone;
   - **non raggiunte (11)**: Collision, Geometry, IdLib (porte di id Tech 4, senza chiamanti), Ide, ToolsCore, EndoomEditor, Font, FontEditor, VoxelEditor (strumenti), Script (la DLL `DDScript`, caricata a runtime) e OpenGl\Recorder.
3. **`GameHost` poggia sul framework giusto.** Dipende solo da `Logging` e da `OpenGl\Binding` (`dglOpenGL`, una sola unit): il binding di OpenGL è generico, il renderer storico (`OpenGl\Legacy`, 39000 righe, 54 unit di `Base`) no. La cartella `Libs\OpenGl` però mette le due cose insieme.
4. **Tre cicli veri tra librerie** (Delphi li tollera con i `uses` di `implementation`, ma sono difetti di stratificazione):
   - `PascalScript` ↔ `ScriptHost` ↔ `Ddc` (`ps_dll`, `ps_import` stanno in `ScriptHost` e sono usate dal nucleo);
   - `Sndfile` ↔ `Sound` (`Sound` usa `delphidoom.sndfile.intf`, `Sndfile` usa `delphidoom.sound.factory`): **ciclo rotto (issue #222)**: il punto d'incontro e' `DelphiDoom.Sndfile.Factory.Intf` (`ISndfileFactory`); `Sndfile` non cita piu' nessuna unit di `Sound`, la dipendenza va solo da `Sound` a `Sndfile` (prova: `Tools\Verifica\222\Controlla-Cicli.ps1`);
   - `XcomStrategy` ↔ `XcomGeoscape` ↔ `XcomBasescape` (interfacce e simulazione del Geoscape stanno nel Geoscape, quelle della strategia nella Strategy). **Rotto (#223)**: `IXcomGeoscapeSimulation` scende in `XcomStrategy.Simulation.Intf`, `TXcomFunding` e `IXcomBasescapeNavigator` in `XcomGeoscape` (`Funding`, `BaseNavigator.Intf`): ordine `XcomStrategy` < `XcomGeoscape` < `XcomBasescape`, controllo `Tools\Verifica\223\Controlla-Cicli.ps1`.
5. **`Base\` è il motore id Tech 1 più la sua colla.** `r_*` 70 unit (64568 righe) e `p_*` 34 (27857) sono il nucleo di gioco e di rendering; `DelphiDoom.Engine.*` sono 212 unit (30454 righe) di adattatori che collegano le librerie ai globali storici (composition root); poi `v_*`, `udmf_*`, `i_*`, `m_*`, `am_*`, `w_*`, `s_*`, `po_*`, `info_*`, `hu_*`, `deh_*`, `sc_*`. Tutto id per costruzione.
6. **I quattro giochi id sono una grande duplicazione**: circa 400000 righe in `Doom`, `Heretic`, `Hexen` e `Strife` con 22 nomi di unit identici in tutti e quattro. Non è un tema del framework in sé (è la #185, "tutto a classi"), ma è il motivo per cui "lato id" pesa tanto.
7. **`Common\`** ha `d_delphi.pas` (shim storico della RTL di Delphi 7, 6805 righe) e `DirectX.pas` (16004): usati da `PascalScript` e `Mp3`, e quindi dal nucleo.

## 3. Classificazione di `Libs\` (dominio assegnato a mano)

| Dominio | Librerie | Note |
|---|---|---|
| **Fondazione** (nessun legame con un gioco) | Logging, Platform, Clock, Threading, Zlib, Yaml, MathCore*, Configuration*, CommandLine | *miste: vedi sotto |
| **Formati e codec** | Png, Jpeg, Ogg, Mp3, Sndfile, Sound, Mikmod, Xmi, M2m, Midi, Opl, Imaging, Palette*, Wad*, Texture | `Wad` è anche il VFS generico (WAD, PAK, ZIP, cartelle) |
| **Servizi di runtime** | Audio, Input, Video*, Console*, Screenshot, Scanner, Serializer, Zone | `Zone` e `Serializer` sono i servizi di id Tech 1 (zone memory, savegame) |
| **Piattaforma di gioco** | GameHost, OpenGl\Binding | già framework: l'esempio da seguire |
| **Scripting** | PascalScript, Script, ScriptHost, Ddc | `ScriptHost` e `Ddc` sono motore, non libreria (28 e 4 unit di `Base`) |
| **id Tech 1** | Acs, Actions, ActorDef, Automap, Blockmap, Definitions, Dehacked, DynLights, Endoom, Glbsp, Hud, Info, Iwad, MapInfo, MusInfo, Net, Nodes, Obituary, Renderer, Specials, TableExport, TextureDefs, Thinkers, Udmf, Voxel, Models, GlAutomap, GlLevel, GlMath, GlScene, GlTexture, OpenGl\Legacy, EngineSystem, GameState, GameData, IdTech, Parity, Radix | `GameData` e `Speed` sono dei fork id (Mars3D, Rad-X, Speed Haste) |
| **id Tech 3 e 4 (porte)** | IdLib, Collision, Geometry | nessun chiamante nel motore |
| **Giochi non id** | Keen, Greed, War, Racing, 16 `Xcom*` | su `GameHost` e nucleo, senza `Base` |
| **Strumenti** | Ide, ToolsCore, EndoomEditor, Font, FontEditor, VoxelEditor | |

Librerie **miste** da guardare una per una (la parte generica va separata da quella di Doom): `MathCore` (23553 righe: fixed point e tabelle di Doom accanto a hash e CRC), `Wad`, `Palette`, `Video`, `Input`, `Console`, `Audio`, `Configuration`.

## 4. Strati proposti

Una unit usa solo gli strati sotto di sé (chi sta a destra del `|` non dipende da chi sta a sinistra):

```
L0 Fondazione   Logging Platform Clock Threading Zlib Yaml MathCore(generico) Configuration(formato) CommandLine
L1 Formati      Png Jpeg Ogg Mp3 Sndfile+Sound Mikmod Xmi M2m Midi Opl Imaging Palette Wad(VFS) Texture
L2 Servizi      Audio Input Video Console Screenshot Scanner Serializer
L3 Piattaforma  GameHost OpenGl\Binding           (Scripting: PascalScript Script Ddc, opzionale)
-----------------------------------------------------------------------------------------------
Moduli          IdTech1 (Base + le librerie id)   IdTech3/4 (porte)   Giochi (Xcom* Keen Greed War Racing)   Strumenti
```

I moduli dipendono dagli strati, mai il contrario né tra loro. Oggi la regola è già rispettata da quasi tutte le librerie (fatto 1); mancano i quattro difetti del punto 5.

**Aggiornamento #228**: AudioMix (L2 Servizi, solo RTL) e' il mixing software comune a XcomAudio, War e Greed (lista di voci con lucchetto, strategie di voce e di ricampionamento, saturazione a 16 bit; i campioni dei tre giochi sono rimasti identici byte per byte; il sintetizzatore MIDI e' la seconda fetta); vedi Libs\AudioMix\CLAUDE.md.

## 5. Che cosa correggere prima di muovere cartelle

1. **Dividere `Libs\OpenGl`**: `Binding` (una unit, strato L3) e `Legacy` (renderer, modulo id Tech 1). Costo basso: `GameHost` usa una sola unit.
2. **Portare `ScriptHost` e `Ddc` sul lato motore** o separare in `ScriptHost` ciò che è generico (registro delle funzioni, serializzatore) da ciò che usa `Base` (28 unit). Rompe anche il primo ciclo (con `ps_dll` e `ps_import` nel nucleo).
3. **Rompere gli altri due cicli**: `Sndfile`↔`Sound` (spostare il punto di incontro in una `*.Intf`) e `XcomGeoscape`↔`XcomBasescape`↔`XcomStrategy` (estrarre le interfacce condivise).
4. **Togliere `Common` dal nucleo**: `PascalScript` e `Mp3` usano 1 unit ciascuno (`d_delphi` o `Doom32.inc`); `Doom32.inc` ridotto sta già negli shim.
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
