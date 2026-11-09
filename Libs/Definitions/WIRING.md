# Libs\Definitions - come collegarla al motore (issue #71, parte della #45)

La libreria legge ANIMDEFS, la tabella degli interruttori (lump SWITCHES di BOOM e tabelle compilate dei quattro giochi) e la tabella del terreno dei flat, e ne fa dei modelli neutri. Non conosce il motore: dipende solo da `Libs\Logging` e `Libs\Scanner` (`Strings`, `Scanner`, `Text`). **Il collegamento non e' stato fatto**: `Base\p_animdefs.pas`, `<Gioco>\p_switch.pas` e `<Gioco>\p_terrain.pas` sono com'erano. Qui sotto cosa serve.

## 1. Unit da aggiungere ai `.dpr`

Servono in tutti i progetti che compilano `p_animdefs`, `p_switch` o `p_terrain` (`Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32`). `DelphiDoom.Logging.*` e `DelphiDoom.Scanner.Strings/Scanner/Text` ci sono gia'.

```
  DelphiDoom.Definitions.Types in 'Libs\Definitions\DelphiDoom.Definitions.Types.pas',
  DelphiDoom.Definitions.Intf in 'Libs\Definitions\DelphiDoom.Definitions.Intf.pas',
  DelphiDoom.Definitions.AnimDefsParser in 'Libs\Definitions\DelphiDoom.Definitions.AnimDefsParser.pas',
  DelphiDoom.Definitions.SwitchLumpReader in 'Libs\Definitions\DelphiDoom.Definitions.SwitchLumpReader.pas',
  DelphiDoom.Definitions.SwitchSelector in 'Libs\Definitions\DelphiDoom.Definitions.SwitchSelector.pas',
  DelphiDoom.Definitions.SwitchTables in 'Libs\Definitions\DelphiDoom.Definitions.SwitchTables.pas',
  DelphiDoom.Definitions.TerrainTable in 'Libs\Definitions\DelphiDoom.Definitions.TerrainTable.pas',
  DelphiDoom.Definitions.TerrainTables in 'Libs\Definitions\DelphiDoom.Definitions.TerrainTables.pas',
  DelphiDoom.Definitions.Factory in 'Libs\Definitions\DelphiDoom.Definitions.Factory.pas',
```

Riga per `Tools\build.bat` (lista `TESTS`): ` Tests\DelphiDoom.Tests.Definitions`. Test: 75 (parita' con il vecchio codice su ANIMDEFS, interruttori di Doom e Strife, terreno dei quattro giochi, tabelle; classi con finti).

## 2. Cosa sostituisce cosa

| Vecchio | Nuovo |
|---|---|
| `P_InitFTAnims` (lettura del testo, `Base\p_animdefs.pas`) | `TDefinitionsFactory.CreateAnimDefsParser(catalogo, log).Parse(testo)` -> `TArray<TDefAnimation>` |
| `AnimDefs[]`, `FrameDefs[]` (con `index` e `tics` gia' risolti) | il motore le riempie dal modello (sotto) |
| lettura di `SWITCHES` in `P_InitSwitchList` di Doom e Strife (record `wad_switchlist_t`, `Z_Malloc`) | `CreateSwitchLumpReader(AHasSound)` (`False` Doom, `True` Strife) -> `TArray<TDefSwitchPair>` |
| tabelle `fixedalphSwitchList` (Doom, Strife) e `alphSwitchList` (Heretic, Hexen) | `CreateSwitchTable(TDefGame)` |
| ciclo di scelta di Doom e Strife (episodio, `R_CheckTextureNumForName`, `I_Warning`) | `CreateSwitchSelector(texturelookup, log).Select(tabella, episodioMassimo)` -> `TArray<TDefResolvedSwitch>` |
| `terraintypedefs[]` e `P_TerrainTypeForName` dei quattro giochi | `CreateTerrainTable(TDefGame).KindForName(nome)` -> `TDefTerrainKind` |

### ANIMDEFS

Il motore resta padrone di `animatedflatslist`, `animatedtextureslist`, `AnimDefs`, `FrameDefs`, `P_AnimateSurfaces`. `P_InitFTAnims` diventa:

```
animlump := W_CheckNumForName('ANIMDEFS'); if animlump < 0 then exit;
animatedflatslist.Clear; animatedtextureslist.Clear;
try
  anims := parser.Parse(W_TextLumpNum(animlump));     // il parser fa SC_RemoveLineQuotes
except
  on E: EDefinitionsException do I_Error(E.Message);   // i testi sono quelli di prima
end;
for ogni anim in anims:
  base := se Kind = Flat  then R_FlatNumForName(anim.Name) else R_TextureNumForName(anim.Name);
  per ogni offset in anim.AnimatedOffsets: la lista del tipo .Add(base + offset);   // flat o texture
  ad._type := Kind; ad.index := base; ad.startFrameDef := fd;
  per ogni frame in anim.Frames:
    FrameDefs[fd].index := base + frame.PicNumber - 1;
    FrameDefs[fd].tics  := frame.PackedTics;      // <-- il formato del vecchio codice
    inc(fd);
  ad.endFrameDef := fd - 1; ad.currentFrameDef := ad.endFrameDef; ad.tics := 1;
```

Le due liste restano nell'ordine di prima (base, poi ogni riga `pic`, animazione per animazione). I limiti 128 e 512 sono costanti della libreria (`DEFINITIONS_MAX_ANIMATIONS`, `DEFINITIONS_MAX_FRAMES`) perche' il vecchio codice li aveva negli array; il motore puo' passare ad array dinamici e, se vuole, alzarli: basta cambiare le due costanti (i test `gen_*` dei golden provano proprio quei limiti).

### Interruttori

- **Doom e Strife**: `lump := W_CheckNumForName('SWITCHES')`; se c'e' `bytes := W_CacheLumpNum -> TBytes` e `table := reader.Read(bytes)`, altrimenti `table := CreateSwitchTable(game)`; `pairs := selector.Select(table, episodio)` con `episodio` di prima (Doom: 2 se `registered` o `retail`, 3 se `commercial`, altrimenti 1; Strife: 2 se `isregistered`, altrimenti 1). Poi `switchlist[2*i] := pairs[i].Texture1`, `switchlist[2*i+1] := pairs[i].Texture2`, `numswitches := Length(pairs)`, `switchlist[...] := -1`. La suoneria di Strife (`switchlist_t.sound`) oggi non la legge nessuno dopo `P_InitSwitchList`; se serve: dal lump `pairs[i].Pair.Sound`, dalla tabella fissa `Pair.SoundName` (`'sfx_bglass'`, ...) tradotto dal motore nel suo `Ord(sfx_...)`.
- **Heretic e Hexen**: la scelta **non e' nella libreria** (e' di tre righe e diversa: Heretic prende solo `episode = 0` e usa `R_TextureNumForName` che da' errore, Hexen non filtra e tiene i `-1` di `R_CheckTextureNumForName`; il terminatore e' `soundID = -1`). Usano solo `CreateSwitchTable(Heretic|Hexen)`; in Hexen `SoundName` e' `'SFX_SWITCH1'`, `'SFX_VALVE_TURN'`, `'SFX_SWITCH2'`, `'SFX_ROPE_PULL'` (il motore sa il numero).
- `P_StartButton`, `P_ChangeSwitchTexture`, `P_UseSpecialLine`, i thinker e `buttonlist` **non sono toccati**.

### Terreno

`P_TerrainTypeForName(flatname)` diventa `TerrainKindToFloor(table.KindForName(flatname))` dove la traduzione e' una tabella del motore dai nomi neutri ai suoi `FLOOR_*` (**i numeri cambiano per gioco**: Doom e Strife `Solid 0, Water 1, Lava 2, Sludge 3, Nukage 4`; Heretic `0..3` senza Nukage; Hexen `Solid 0, Ice 1, (Liquid 2 non usato), Water 3, Lava 4, Sludge 5`). La tabella (`IDefTerrainTable`) si crea una volta nel composition root. `P_GetTerrainType` di Strife e i commenti di `r_data.pas` (`flat.terraintype := P_TerrainTypeForName(...)`) restano chiamanti.

**Stato attuale (issue #136)**: i quattro `p_terrain.pas` sono stati cancellati. La tabella non ha stato e non passa piu' dal composition root: `R_FlatTerrainType` di `Base\r_data.pas` chiama `TTerrainTables.KindForName(gioco, nome)` (statica, scorre la lista del gioco senza crearla) e traduce con `TERRAIN_FLOORS`; i `FLOOR_*` di Doom e Strife e `allowterrainsplashes` sono in `Base\p_local.pas`, `P_GetTerrainType` di Strife in `Strife\p_mobj.pas` (legge `flats[].terraintype`).

## 3. Composition root (`DelphiDoom.Engine.Composition`)

Adattatori sottili nel motore (una unit per classe, `DelphiDoom.Engine.Definitions.*`):

- `IDefAnimNameCatalog`: `HasFlat(nome)` = `W_CheckNumForName(nome) <> -1` (come il vecchio codice: basta un lump con quel nome, poi `R_FlatNumForName` lo cerca tra i flat); `HasTexture(nome)` = `R_CheckTextureNumForName(nome) <> -1`.
- `IDefTextureLookup`: `CheckTextureNumForName(nome)` = `R_CheckTextureNumForName(nome)`.
- `ILog`: quello di `I_ConfigureLog` (gli avvisi sono quelli di `I_Warning`, con il testo e i `#13#10` di prima).
- `TDefGame` dal gioco compilato (nessun `{$IFDEF}` nella libreria: il motore sceglie `TDefGame.Doom/Heretic/Hexen/Strife`).

## 4. Dopo il collegamento si cancella

- da `Base\p_animdefs.pas`: il corpo di `P_InitFTAnims` oltre il riempimento delle tabelle, le costanti `SCI_*`, `ANIM_SCRIPT_NAME` resta;
- da `Doom\p_switch.pas`, `Strife\p_switch.pas`: `wad_switchlist_t` e relativi array, `fixedalphSwitchList`, `alphSwitchList`, la lettura e il ciclo di scelta;
- da `Heretic\p_switch.pas`, `Hexen\p_switch.pas`: `alphSwitchList` (la tabella passa alla libreria);
- da tutti i `p_terrain.pas`: `terraintypedefs` e il ciclo (resta la traduzione `TDefTerrainKind` -> `FLOOR_*`; da Heretic anche i commenti `P_TerrainTypeForNum`).

## 5. Differenze dal vecchio codice

Nessuna di comportamento sulle stesse entrate (sono confrontate con i golden). Voluto e da sapere:

- Una voce `SoundName` per Hexen e Strife al posto di `Ord(SFX_...)`: i numeri non possono stare in una libreria che non conosce `sounddata`.
- `P_InitFTAnims` dava `I_Error` a meta' della lettura (con le liste gia' riempite); la libreria alza `EDefinitionsException` con lo stesso testo e **non restituisce nulla**. Chi la chiama gira l'eccezione a `I_Error`: il risultato e' lo stesso perche' il gioco si ferma.
- La libreria dice "una animazione ignorata" non tenendola nel modello (i frame, le liste e il conteggio dei frame non la vedono), come il vecchio codice.
- Il nome di una voce del lump SWITCHES e' convertito da `AnsiString` (come l'assegnazione di un `array of AnsiChar` a una `string`): i byte sopra 127 dipendono dalla tabella dei caratteri della macchina, come prima.

## 6. Difetti del vecchio codice conservati (e perche')

- **`tics` sopra 255 e' "random"**: `FrameDefs[].tics` e' un solo intero e `P_AnimateSurfaces` lo legge come casuale se e' maggiore di 255 (alto = minimo, byte 1 = intervallo). `PackedTics` lo riproduce (`tics 300` dara' 300, e il motore lo vedra' come random); un `rand 10 5` da' un intervallo di 0 o negativo. Per correggerlo servirebbe un campo in piu' in `FrameDefs`.
- **Tipo sconosciuto**: una parola diversa da `flat` e `texture` e' un avviso e l'animazione prende il tipo che aveva *lo slot* nella tabella (flat se mai usato, quello dell'animazione ignorata che lo occupava). Il parser lo riproduce (`LSlotKind`).
- **Una riga `pic` con parola sbagliata dopo il numero** (`pic 2 foo 9`) mette comunque la base nelle liste delle immagini animate (`AnimatedOffsets`) ma non fa un frame.
- **Numero mancante o sbagliato**: gli avvisi dello scanner e il valore intero che resta quello della lettura precedente (e' lo scanner, non la libreria).
- Il terminatore di una tabella SWITCHES e' il primo con episodio -1 o con un nome vuoto; un episodio negativo diverso da -1 (es. -2) passa il filtro `<= massimo`. Il lump e' letto per intero e il selettore si ferma.
- Hexen: `R_CheckTextureNumForName` senza filtro lascia `-1` nella lista degli interruttori e il `-1` e' anche il suo terminatore: una texture mancante tronca la lista. Non e' nella libreria (vedi sopra) e resta cosi' finche' non si riscrive quel ciclo.

## 7. Non portato

- **TERRAIN**: il motore non legge alcun lump `TERRAIN` (solo la tabella compilata), quindi non c'e' un parser da portare: `TTerrainTable` e' la tabella e la ricerca. Un parser di `TERRAIN` sarebbe una funzione nuova, non un portare.
- **BEX / DEHACKED per gli interruttori**: nessuna sezione di BEX tocca gli interruttori nel motore. Il lump `SWITCHES` e' il solo formato letto.
- `P_AnimateSurfaces`, `P_StartButton`, `P_ChangeSwitchTexture`, `P_UseSpecialLine`: runtime e thinker, restano nel motore (issue #45: non si astraggono i thinker per via dei savegame).
- La scelta delle voci di Heretic e Hexen (vedi 2).

## 8. Rischi

1. **Le costanti dei suoni**: se si usa la suoneria di Strife o di Hexen, serve una tabella `SoundName` -> `Ord(sfx_...)` nel motore; un nome non tradotto non viene segnalato dalla libreria. Oggi nessuno legge `switchlist_t.sound`/`soundID` dopo l'init: verificarlo prima di toglierli.
2. **Il numero di un flat**: la libreria chiede `HasFlat` (un lump con quel nome) e il motore poi `R_FlatNumForName`: se esiste un lump ma non e' un flat, `R_FlatNumForName` da' errore come prima. Il motore deve chiamarlo solo per le animazioni che la libreria ha tenuto, nell'ordine in cui le restituisce.
3. **`PackedTics` va usato cosi' com'e'** nel riempire `FrameDefs[].tics`, altrimenti cambia l'animazione dei flat con `rand` o con tics > 255.
4. **Hexen e `ISwitchSelector`**: non usarlo per Hexen/Heretic come se fosse la stessa cosa (il filtro e' diverso, vedi 2).
5. **Strife**: il lump con la suoneria e' di 24 byte; un lump di un altro gioco (20 byte) letto con `AHasSound = True` da' voci sfasate. E' la scelta del gioco al composition root.
