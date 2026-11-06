# Libs\DynLights - come collegarla al motore (issue #69)

La libreria non è collegata: `Base\r_dynlights.pas` è com'era. Questo file dice cosa fare per collegarla.

## 1. Unit da aggiungere ai `.dpr` (tutti gli eseguibili che linkano `r_dynlights`: Doom, Heretic, Hexen, Strife, software e OpenGL)

```
DelphiDoom.DynLights.Types        in 'Libs\DynLights\DelphiDoom.DynLights.Types.pas',
DelphiDoom.DynLights.Intf         in 'Libs\DynLights\DelphiDoom.DynLights.Intf.pas',
DelphiDoom.DynLights.Tokens       in 'Libs\DynLights\DelphiDoom.DynLights.Tokens.pas',
DelphiDoom.DynLights.Registry     in 'Libs\DynLights\DelphiDoom.DynLights.Registry.pas',
DelphiDoom.DynLights.FixedMath    in 'Libs\DynLights\DelphiDoom.DynLights.FixedMath.pas',
DelphiDoom.DynLights.Animator     in 'Libs\DynLights\DelphiDoom.DynLights.Animator.pas',
DelphiDoom.DynLights.StateBinder  in 'Libs\DynLights\DelphiDoom.DynLights.StateBinder.pas',
DelphiDoom.DynLights.Parser       in 'Libs\DynLights\DelphiDoom.DynLights.Parser.pas',
DelphiDoom.DynLights.Loader       in 'Libs\DynLights\DelphiDoom.DynLights.Loader.pas',
DelphiDoom.DynLights.Factory      in 'Libs\DynLights\DelphiDoom.DynLights.Factory.pas',
```

Dipende da `Libs\Scanner` (`Scanner.Strings`, `Scanner.Scanner`), `Libs\Logging` (`Logging.Intf`, `Logging.Types`) e `Libs\GameState` (`GameState.Intf`, per la modalità sviluppatore). Nessun `uses` di unit storiche.

Riga per `build.bat` (lista `TESTS`): `Tests\DelphiDoom.Tests.DynLights`

## 2. Cosa sostituisce cosa

| Vecchio (`Base\r_dynlights.pas`) | Nuovo |
|---|---|
| `GLDLight` (`name`, `lighttype`, `r1..b2`, `colorinterval`, `colorchance`, `size1/2`, `interval`, `chance`, `offsetx1..z2`, `randomoffset`, `randomseed`) | `TDynLightDefinition` (`Name`, `Kind`, `R1..B2`, `ColorInterval`, `ColorChance`, `Size1/2`, `Interval`, `Chance`, `OffsetX1..Z2`, `RandomOffset`, `RandomSeed`) |
| `GLDlightType` (`GLDL_POINT/FLICKER/PULSE`) | `TDynLightKind` (`Point`, `Flicker`, `Pulse`) |
| `validcount`, `renderinfo` dentro `GLDLight` | stato privato di `TDynLightAnimator` |
| `GLDRenderLight` / `PGLDRenderLight` | `TDynLightRender`, **restituito per valore** |
| `R_InitDynamicLights` | `registry.Clear; present := loader.Load(gldefs_as_lightdef)` (e `lightdeflumppresent := lightdeflumppresent or present`) |
| `R_DynamicLightsDone` | `registry.Clear; animator.Reset`; il rilascio di `dlbuffer` resta al motore |
| `R_AddDynamicLight(l)` | `registry.Add(def)` (maiuscolo e 32 caratteri come prima) |
| `R_FindDynamicLight(name)` | `registry.Find(name)` |
| `R_GetDynamicLight(i)` | `animator.GetRender(i, leveltime)` |
| `SC_ParceDynamicLight(text)`, `SC_DoParceDynamicLight`, `SC_ParceDynamicLights` | `TDynLightParser.Parse`, `TDynLightLoader.Load` |
| `R_GrowDynlightsArray`, `dlightslist`, `numdlights`, `realnumdlights` | spariscono (lista dentro il registro) |
| `lightrnd` | variabile dell'adattatore di `IDynLightRandom` |
| `tokens` (`TTokenList`) | `TDynLightTokens.Classify` |

Restano nel motore (rendering, non sono compito della libreria): `lightdeflumppresent`, `gldefs_as_lightdef`, `dlsortitem_t`, `dlbuffer`, `numdlitems`, `realdlitems`, `DLIGHTSDRAWRANGE`. Conviene spostarli in un'unit del renderer.

## 3. Composition root

Adattatori nel motore (`DelphiDoom.Engine.DynLights.*`, una unit per classe):

- `IDynLightRandom.NextByte` → `C_Random(lightrnd)` (la variabile `lightrnd` vive nell'adattatore, come la `lightrnd` di `r_dynlights`)
- `IDynLightObjectResolver` → `Info_GetMobjNumForName(name)` (accetta già `-1`, vuoto e numeri)
- `IDynLightSpriteResolver` → `Info_CheckSpriteNumForName(name)` (la libreria gli passa sempre 4 lettere maiuscole)
- `IDynLightStateTable` (sopra `states[]`): `StateCount = numstates`; `SpriteOf(j) = states[j].sprite`; `FrameOf(j) = states[j].frame and FF_FRAMEMASK`; `StatesOfObject(m)`: `N := Info_GetStatesForMobjInfo(m)`, copia in un `TArray<Integer>`, `N.Free` (`m < 0` dà lista vuota); `HasLights(j) = states[j].dlights <> nil`; `CreateLights(j) = T2DNumberList.Create`; `RemoveLightsOfObject(j, m)`: `for k := Count - 1 downto 0 do if dlights[k].num1 = m then dlights.Delete(k)`; `AddLight(j, m, l) = dlights.Add(m, l)`. Questo codice è esattamente quello che oggi sta nel ciclo di `SC_DoParceDynamicLight`
- `IGameContext` → `TEngineGameContext` (già creato da `ComposeEngine`); con `devparm` il testo viene elencato
- `IDynLightTextFilter` → `SC_Preprocess(text, false)`
- `IDynLightTextSource`: `WadLumpTexts(name)`: ciclo su `W_NumLumps` con `char8tostring(W_GetNameForNum(i)) = name` e `W_TextLumpNum(i)` (**un testo per lump, nessuna concatenazione**, diverso da UMAPINFO); `PakTexts(name)`: `PAK_StringIterator(name, proc)` con una procedura semplice che accumula in una variabile di unit
- `ILog` → quello degli script (`TEngineScannerLog`). Gli avvisi arrivano con i loro `#13#10` come prima
- coefficiente: `MAP_COEFF` per le build OpenGL, `1` per il software (al posto di `{$IFDEF OPENGL} / MAP_COEFF`)

```
registry := TDynLightFactory.CreateRegistry;
binder   := TDynLightFactory.CreateBinder(stateTable);
parser   := TDynLightFactory.CreateParser(services, log, coefficient);
loader   := TDynLightFactory.CreateLoader(textSource, textFilter, parser);
animator := TDynLightFactory.CreateAnimator(registry, random);
```

Il messaggio `printf('SC_ParceDynamicLights: Parsing LIGHTDEF lumps.')` di `R_InitDynamicLights` (solo OpenGL) resta nel motore, prima di `loader.Load`.

## 4. Cosa si può cancellare dopo il collegamento

`Base\r_dynlights.pas` quasi per intero (resta la parte del renderer: `dlsortitem_t`, `dlbuffer`...). Consumatori da riscrivere (cercare `GLDLight`, `PGLDRenderLight`, `R_GetDynamicLight`, `R_FindDynamicLight`, `R_AddDynamicLight`, `lightdeflumppresent`): `Base\r_softlights.pas`, `Base\r_things.pas`, `Base\r_main.pas`, `OPENGL\gl_lightmaps.pas`, `gl_render.pas`, `gl_shadows.pas`, `Doom|Heretic\*` che inizializzano le luci.

## 5. Come sono stati ottenuti i golden

`Tests\Data\DynLights\{opengl,software}.golden.txt` sono stati scritti dal **vero** `Base\r_dynlights.pas`, compilato fuori dal motore con `dcc32` (`-DOPENGL` e senza), insieme ai veri `Common\d_delphi.pas`, `Base\m_fixed.pas` (con il suo `FixedDiv` in assembler), `m_stack`, `sc_engine` e `sc_tokens`. Due differenze rispetto al sorgente del repository, entrambe additive e documentate:

- la copia compilata ha **due funzioni aggiunte in fondo** (`HarnessCount`, `HarnessLight`) per leggere `dlightslist`/`numdlights`, che sono privati; nient'altro è cambiato
- le unit del motore da cui dipende sono *stub* (fuori dal repository): `m_rnd.C_Random` (`(n * 37 + 11) and 255`, con `n` che riparte da 0 a ogni caso), `p_tick.leveltime`, `d_main.devparm`, `gl_defs.MAP_COEFF = 128.0`, `i_system` (scrive gli avvisi su una stringa), `w_wad`/`w_pak` finti, `info` con **12 stati** finti e `info_common` con 4 mostri e 5 sprite (`Info_GetStatesForMobjInfo` dà gli stati di ogni mostro).
- il programma legge `Tests\Data\DynLights\cases.txt` (66 casi), esegue ogni caso con `R_InitDynamicLights` e scarica: output di `printf` (elenco con `devparm`), avvisi, `lightdeflumppresent`, ogni campo di ogni luce (float come bit esadecimali), `R_FindDynamicLight`, la lista di ogni stato, e l'animazione `R_GetDynamicLight` di ogni luce a una serie di `leveltime` (anche 32768, 65536, 5000000 e negativi per l'overflow dei 32 bit).

Affidabilità: alta. La parità è sui bit dei float, quindi anche l'aritmetica `Single`/`Extended` dell'animazione è confrontata. Non è coperto: il vero `Info_*` e il vero `states[]` (gli stub hanno nomi e stati propri; il codice di associazione è provato con questi), `C_Random` vero (il test usa una sequenza propria), un `SC_Preprocess` vero (direttive `#`), e le build a 64 bit (l'`Extended` diventa `Double`: i bit possono differire in casi limite).

Per rigenerarli: ricostruire l'harness (programma console che usa `r_dynlights` con le due funzioni aggiunte e gli stub sopra), compilare con `-DOPENGL` e senza, ed eseguirlo su `cases.txt`.

## 6. Differenze volute dal vecchio

1. `R_GetDynamicLight` restituiva un puntatore al `renderinfo` dentro la luce; ora `GetRender` restituisce un record per valore (il valore calcolato resta nell'animatore per la chiamata dopo, come prima).
2. Lo stato di animazione (`validcount`, `renderinfo`) non sta più dentro la definizione: dopo `registry.Clear` e un nuovo caricamento serve `animator.Reset`.
3. L'associazione luce/stati è nella libreria (`TDynLightStateBinder`) sopra l'interfaccia `IDynLightStateTable`: il codice è lo stesso, ma non conosce `states[]`.
4. Il parser non conosce `{$IFDEF OPENGL}`: il coefficiente è un parametro.
5. Il banner `SC_ParceDynamicLights: Parsing LIGHTDEF lumps.` non è della libreria (nei golden è tolto dall'uscita).

## 7. Difetti del vecchio conservati

- **L'ultima luce di un testo è persa** se dopo le sue proprietà non c'è nessuna parola (la luce si aggiunge quando si legge la parola che la chiude): un GLDEFS con solo luci e nessun `object` perde l'ultima (test `light_at_eof_dropped`). È il difetto più probabile da correggere.
- I nomi di luce oltre 32 caratteri vengono tagliati, ma `R_FindDynamicLight` confronta il nome intero: una luce con un nome lungo non si trova (test `long_name`).
- `object` è riconosciuta solo se la riga inizia con `OBJECT` seguita da uno spazio: con una tabulazione no. Lo stesso per `frame`.
- Un `object` sconosciuto lascia il numero negativo: le righe `frame` seguenti si legano a **qualsiasi** stato (proprietario -1).
- Il numero di riga dell'avviso "Unknown object" parte da 0, gli altri da 1.
- Se una parola manca (`MustGetString` fallisce) resta quella di prima: `frame TROOA light` cerca la luce `LIGHT`.
- `objectsfound` si accende con qualsiasi parola `OBJECT` del testo, anche dentro una luce o tra virgolette.
- Il parser usa uno scanner solo per le due passate: i livelli di parentesi della prima restano nella seconda.
- I seed casuali: la prima chiamata di `C_Random` è il byte alto.

## 8. Rischi

- `R_GetDynamicLight` è nel percorso caldo del renderer (una chiamata per luce visibile a ogni fotogramma): `GetRender` copia la definizione (un record con una stringa) a ogni chiamata. Se pesa, cacheare le definizioni nell'animatore o aggiungere un accesso per riferimento al registro.
- Chi usava il puntatore ritornato da `R_GetDynamicLight` (`gl_lightmaps`, `r_softlights`...) va riscritto sul valore.
- L'adattatore di `IDynLightStateTable` deve liberare la lista di `Info_GetStatesForMobjInfo` a ogni chiamata (come faceva il vecchio codice con `N.Free`).
- `SC_Preprocess` ha effetti collaterali (`#CVARFORCE`...): il filtro va chiamato come oggi, una volta per testo.
- `Tests\Data\DynLights\.gitattributes` imposta `-text`: i golden e `cases.txt` sono LF.
