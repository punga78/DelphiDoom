# Libs\Decl

Gestore delle dichiarazioni di id Tech 4 (Doom 3): tipi registrati, lettura a richiesta, `table`, `skin`, `material` (file `.mtr`, issue #102), `entityDef` con `inherit`, `pda`. Issue #100, parte della #94.

Il testo di riferimento (contratto per i tipi delle altre issue, riuso, differenze dal C++, difetti trovati, cosa resta) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 30 (nome a punti `DelphiDoom.Decl.*`), una classe per unit (le 13 del materiale sono `DelphiDoom.Decl.Material.*`). Non hanno chiamanti nel motore.
- Interfacce: `IDeclManager`, `IDeclFinder`, `IDeclRegistry`, `IDeclHost`, `IDecl`, `IDeclBase`, `IDeclType`, `IDeclSource`, e per i dati `IDeclTable`, `IDeclSkin`, `IDeclMaterial` e `IMaterialRegisters` (materiale e registri delle espressioni), `IDeclEntityDef`, `IDeclPda`, `IDeclEmail`, `IDeclVideo`, `IDeclAudio`.
- Licenza: GPL v3 con i termini aggiuntivi di Doom 3 nelle unit portate dal suo codice ("Based on the Doom 3 GPL Source Code", intestazione di ogni unit); GPL v2 o successiva per `Source.Intf`, `Source.Memory` e `Factory`.

## Uso

```pascal
LSource := TDeclMemorySource.Create;            // o un IDeclSource sopra il file system del gioco
LSource.Add('skins/a.skin', 'skin one { model "m" "mat/a" "mat/b" }');
LManager := TDeclFactory.CreateStandardManager(LSource, LLog);   // tipi di Doom 3 e cartelle standard
if Supports(LManager.FindType(DECL_SKIN, 'one'), IDeclSkin, LSkin) then
  ...                                           // il file e' gia' letto, la dichiarazione si interpreta qui
```

Un tipo nuovo: una classe che deriva da `TDecl` e `Registry.RegisterDeclType(...)`, vedi il contratto in CLAUDE.md.

## Materiali (`.mtr`, issue #102)

`TDeclStandardTypes` registra `material` con `TDeclMaterial`; i dati si leggono con `Supports(Decl, IDeclMaterial, M)` e i registri delle espressioni con `Supports(Decl, IMaterialRegisters, R)`. Le immagini sono nominate (testo canonico del programma d'immagine, `Libs\Imaging`), mai caricate.

```pascal
if Supports(LManager.FindType(DECL_MATERIAL, 'textures/test/wall'), IDeclMaterial, LMaterial) then
begin
  LStage := LMaterial.GetStage(0);              // TMaterialStage: blend, colori, matrice, immagine nominata
  LSort := LMaterial.GetSort;                   // come idMaterial::GetSort
  LRegisters.EvaluateRegisters(LValues, LInput); // registri a un tempo e a parametri dati (TMaterialEvaluationInput)
end;
```

Opzioni (`TMaterialOptions`: `image_ignoreHighQuality`, `ARBFragmentProgramAvailable`, `r_useConstantMaterials`, e `FixConstantRegisters` che corregge un difetto del C++) si passano a `TDeclStandardTypes.RegisterTypes(Registry, ASkip, Options)`. `RegisterPlaceholderMaterial` rimette il segnaposto di prima (un `TDecl` che salta il testo).

## Prova

- Progetto di test `Tests\DelphiDoom.Tests.Decl`: `Tools\build.bat DelphiDoom.Tests.Decl Release`. 301 test (201 del gestore e dei materiali, 100 degli shader di Quake III), copertura 97% (ogni unit sopra il 90%). Parita' con il vero C++ in `Tests\Data\Decl` ([README dei dati](../../Tests/Data/Decl/README.md)).

## Legami

- Sopra `Libs\IdLib` (`TIdLexer`, `TIdHashIndex`, `TIdMd5`, `TIdStrings`, `TIdMath`) e `Libs\Scanner` (`TIdDict`).
- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

## Shader di Quake III (issue #119, prima fetta)

Il tipo `shader` (`TDeclQ3Shader`, `DelphiDoom.Decl.Q3Shader.*`) legge i file `scripts/*.shader` di Quake III come `tr_shader.c`: `ParseShader`, `ParseStage`, `ParseTexMod`, `ParseDeform`, `ParseSkyParms`, `ParseSort`, `ParseSurfaceParm`, `ParseVector`, `ParseWaveForm` e la parte di dati di `FinishShader`. I **dati**, non il disegno: le immagini si nominano e non si caricano; onde, `tcMod` e deformazioni sono dati, non si calcolano ancora (restano di #119).

```pascal
TQ3ShaderRegistration.RegisterType(Manager.GetRegistry, []);   // il tipo (numero DECL_Q3SHADER = 30)
TQ3ShaderRegistration.RegisterFolder(Manager.GetRegistry);     // legge scripts/*.shader
if Supports(Manager.FindType(DECL_Q3SHADER, 'textures/foo/bar'), IDeclQ3Shader, LShader) then
  for LIndex := 0 to LShader.GetStageCount - 1 do
    LImage := LShader.GetStage(LIndex).Bundle.ImageNames[0];
```

Non e' registrato da `TDeclStandardTypes` (aggiungerebbe il numero 30 ai tipi di Doom 3): un gioco di Quake III lo registra da se'. La sintassi di un `.shader` non e' quella di Doom 3 (nessuna parola di tipo, parole separate da blank, `//` e `/* */`, righe che contano): il file lo trova `TQ3ShaderFileScanner` (`IDeclFileScanner`, una strategia per tipo che il manager usa al posto del lexer di idLib) e lo shader lo legge `TQ3ShaderTokenizer` (`COM_ParseExt`). Dettagli, difetti del C e differenze: [CLAUDE.md](CLAUDE.md).
