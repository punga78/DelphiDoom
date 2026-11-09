# Libs\MapInfo - come collegarla al motore (issue #69)

La libreria non è collegata: `Base\p_umapinfo.pas` è com'era. Questo file dice cosa fare per collegarla.

## 1. Unit da aggiungere ai `.dpr` (Doom32, GLDoom32, Heretic32, GLHeretic32, Strife32, GLStrife32 e `ddc_*` se linkano `p_umapinfo`)

```
DelphiDoom.MapInfo.Types          in 'Libs\MapInfo\DelphiDoom.MapInfo.Types.pas',
DelphiDoom.MapInfo.Intf           in 'Libs\MapInfo\DelphiDoom.MapInfo.Intf.pas',
DelphiDoom.MapInfo.TextPreparer   in 'Libs\MapInfo\DelphiDoom.MapInfo.TextPreparer.pas',
DelphiDoom.MapInfo.Parser         in 'Libs\MapInfo\DelphiDoom.MapInfo.Parser.pas',
DelphiDoom.MapInfo.Merger         in 'Libs\MapInfo\DelphiDoom.MapInfo.Merger.pas',
DelphiDoom.MapInfo.Catalog        in 'Libs\MapInfo\DelphiDoom.MapInfo.Catalog.pas',
DelphiDoom.MapInfo.BossActionRule in 'Libs\MapInfo\DelphiDoom.MapInfo.BossActionRule.pas',
DelphiDoom.MapInfo.Loader         in 'Libs\MapInfo\DelphiDoom.MapInfo.Loader.pas',
DelphiDoom.MapInfo.Factory        in 'Libs\MapInfo\DelphiDoom.MapInfo.Factory.pas',
```

Dipende da `Libs\Scanner` (`DelphiDoom.Scanner.Strings`, `DelphiDoom.Scanner.Scanner`, già nei `.dpr`) e da `Libs\Logging` (`Logging.Intf`, `Logging.Types`). Nessun `uses` di unit storiche.

Riga per `Tools\build.bat` (lista `TESTS`): `Tests\DelphiDoom.Tests.MapInfo`

## 2. Cosa sostituisce cosa

| Vecchio (`Base\p_umapinfo.pas`) | Nuovo |
|---|---|
| `U_ParseMapInfo(is_default, lumpname)` | `IMapInfoLoader.Load(lumpname, is_default)` |
| `U_FreeMapInfo` | `IMapInfoCatalog.ClearMaps` (come prima, i default restano) |
| `u_mapinfo.maps[i]`, `.mapcount` | `catalog.GetMap(i)`, `catalog.MapCount` |
| `default_mapinfo.maps[i]`, `.mapcount` | `catalog.GetDefault(i)`, `catalog.DefaultCount` |
| ricerca per nome in `G_LookupMapinfo` (`g_game.pas`) | `catalog.IndexOfMap(name)` poi `GetMap`, poi `IndexOfDefault`/`GetDefault` |
| `U_DoParseMapInfoLump`, `ParseMapEntry`, `U_ParseStandardProperty`, `U_ParseMultiString`, `ParseLumpName` | `TMapInfoParser` (`IMapInfoParser.Parse`) |
| `U_Preproccessor` | `TMapInfoTextPreparer.Prepare` (la chiama il parser) |
| `UpdateMapEntry` + logica di fusione di `U_DoParseMapInfoLump` | `TMapInfoMerger.Update` + `TMapInfoCatalog.AddParsed` |
| `mapentry_t`, `bossaction_t`, `ubigstring_t`, `ulumpname_t` | `TMapInfoEntry` (stringhe vere), `TMapInfoBossAction` |
| `ubigstringtostring(x)` | non serve più: `InterText` e `InterTextSecret` sono `string` |
| `S_UMAPINFO`, `S_UMAPDEF` | restano nel motore (nomi dei lump passati a `Load`) |

Campi: `mapname`→`MapName`, `levelname`→`LevelName`, `mlabel`→`MapLabel`, `intertext`→`InterText`, `intertextsecret`→`InterTextSecret`, `levelpic`→`LevelPic`, `nextmap`→`NextMap`, `nextsecret`→`NextSecret`, `music`/`musicnum`→`Music`/`MusicNumber`, `skytexture(2)`→`SkyTexture(2)`, `endpic`, `exitpic`, `enterpic`→`EndPic`, `ExitPic`, `EnterPic`, `interbackdrop`→`InterBackdrop`, `intermusic(num)`→`InterMusic`/`InterMusicNumber`, `partime`→`ParTime` (già in tic), `nointermission`, `lightning`, `nojump`, `nocrouch` → `NoIntermission`, `Lightning`, `NoJump`, `NoCrouch`, `numbossactions`/`bossactions`→`BossActions` (array) e `BossActionsCleared` (era `numbossactions = -1`).

## 3. Composition root (`DelphiDoom.Engine.Composition`)

Servono questi adattatori nel motore (unit `DelphiDoom.Engine.MapInfo.*`, una per classe), tutti sottili:

- `IMapNameValidator` → `G_ValidateMapName(name, nil, nil)`
- `IMapLumpCatalog` → `W_CheckNumForName(name) >= 0`
- `IMapMusicResolver` → `S_GetMusicNumForName(name)`
- `IMapActorResolver` → il ciclo su `ActorNames[]` (confronto in maiuscolo) e, se non trova, `Info_GetMobjNumForName(name)`; la libreria passa il nome già in maiuscolo
- `IMapEpisodeSink` → `M_ClearEpisodes` / `M_AddEpisode(mapname, pic, text, key)`. **Strife non lo passa (nil)**: `episode` diventa una proprietà sconosciuta, come con `{$IFNDEF STRIFE}`
- `IMapBossActionRule` → `TMapInfoFactory.CreateTaggedBossActionRule([11, 51, 52, 124])` per Doom, `[11, 51, 52, 105]` per Heretic, `CreateOpenBossActionRule` per Strife. Niente `{$IFDEF}` nella libreria: la scelta del gioco è del composition root
- `IMapInfoTextSource` → `WadLumpTexts(name)`: ciclo su `W_NumLumps` con `char8tostring(W_GetNameForNum(i)) = name` e `W_TextLumpNum(i)`; `PakTexts(name)`: `PAK_StringIterator(name, proc)` con una procedura semplice (`stringparmproc_t` non è un metodo) che accumula in una variabile di unit prima di restituire l'array
- `IMapInfoTextFilter` → `SC_Preprocess(text, false)` (il filtro deve restare quello del motore: gestisce `#define`, `#include`...)
- `ILog` → quello già usato per gli altri script (`TEngineScannerLog` o `ILog` di `I_ConfigureLog`)

```
catalog := TMapInfoFactory.CreateCatalog(services.Music);
parser  := TMapInfoFactory.CreateParser(services, log);
loader  := TMapInfoFactory.CreateLoader(textSource, textFilter, parser, catalog);
```

`d_main.pas` (Doom, Heretic, Strife) oggi chiama `U_ParseMapInfo(False, 'UMAPINFO')`: diventa `loader.Load('UMAPINFO', False)`. La chiamata con `is_default = True` (`UMAPDEF`) non esiste nel motore: la libreria la supporta (e i test la coprono) ma nessuno la usa.

## 4. Cosa si può cancellare dopo il collegamento

Tutto `Base\p_umapinfo.pas` (905 righe) tranne le due costanti dei nomi dei lump, che si spostano nel composition root. Anche `p_uactornames` resta, serve all'adattatore degli attori.
I consumatori da riscrivere (cercare `u_mapinfo`, `default_mapinfo`, `Pmapentry_t`, `ubigstringtostring`): `Doom|Heretic|Strife\g_game.pas` (`G_LookupMapinfo` ritorna un puntatore), `Doom\wi_stuff.pas`, e i moduli che leggono `gamemapinfo`. Proposta: tenere un `TMapInfoEntry` (per valore) più un flag di validità, oppure un puntatore a una copia sul heap.

## 5. Come sono stati ottenuti i golden

`Tests\Data\MapInfo\{doom,heretic,strife}.golden.txt` sono stati scritti dal **vero** `Base\p_umapinfo.pas`, compilato fuori dal motore con `dcc32` per i tre giochi (`-DDOOM`, `-DHERETIC`, `-DSTRIFE`), insieme ai veri `Common\d_delphi.pas` e `Base\sc_engine.pas` (la facciata sopra `Libs\Scanner`, già verificata contro il vecchio `TScriptEngine`). Le unit del motore da cui `p_umapinfo` dipende sono sostituite da *stub* in una cartella messa prima nel percorso di ricerca (fuori dal repository, harness temporaneo):

- `g_game.G_ValidateMapName`: stessa regola della libreria di prova (MAPxx 01..99, ExMy 1..8/1..9), `sounds.S_GetMusicNumForName`: numero calcolato dal nome, `w_wad.W_CheckNumForName`: esiste se inizia con `D_`, `info_common.Info_GetMobjNumForName` e `p_uactornames.ActorNames`: tre nomi piccoli, `sc_utils.SC_Preprocess`: identità, `m_menu`: scrive su una stringa le chiamate a `M_ClearEpisodes`/`M_AddEpisode`, `i_system.I_Warning`: scrive su una stringa, `z_zone` su `ReallocMem`, `w_wad`/`w_pak`: lump e voci PAK finti.
- il programma legge `Tests\Data\MapInfo\cases.txt` (65 casi), esegue ogni caso con `U_ParseMapInfo` e scarica `u_mapinfo`, `default_mapinfo`, gli avvisi e le chiamate sugli episodi.

Affidabilità: alta per il parser, la fusione e il caricatore (è il codice vero, non una copia). I test usano gli stessi stub *riscritti* (`DelphiDoom.Tests.MapInfo.Fakes`): se uno stub e il suo finto divergono, il test fallirebbe. Non è coperto: i veri `G_ValidateMapName` (Doom ha `not len in [4,5]`), `S_GetMusicNumForName`, `Info_GetMobjNumForName` (accetta anche numeri e `-1`), l'ordine di `ActorNames`, i caratteri sopra 127 (corpus solo ASCII) e un `SC_Preprocess` vero (direttive `#`).

Per rigenerarli: ricostruire l'harness (programma console che usa `p_umapinfo` e gli stub sopra), compilare con `-DDOOM|HERETIC|STRIFE -U<stub>;Common;Base;Libs\Scanner;Libs\Logging -I<radice>` ed eseguirlo su `cases.txt`.

## 6. Differenze volute dal vecchio

1. **`stringtoubigstring` aveva due difetti, non copiati**: perdeva l'ultimo carattere di `intertext`/`intertextsecret` (`"You have won."` diventava `You have won`) e tagliava a 1022 caratteri; inoltre `intertext = clear` (che scrive `-`, un solo carattere) diventava vuoto, cioè non impostato. Ora il testo è intero e `clear` resta `-`. Il test di parità applica al nuovo valore la stessa trasformazione del vecchio record (`OldInterText`) per confrontarlo con il golden. Effetto collaterale: nella fusione con i default un testo di un solo carattere ora conta come "detto".
2. Gli avvisi vanno a un `ILog` (nel golden sono il testo passato a `I_Warning`, identico).
3. Il parser non conosce giochi: `{$IFDEF DOOM/HERETIC}` e `{$IFNDEF STRIFE}` sono strategie iniettate.

## 7. Difetti del vecchio conservati

- Un map entry viene unito al default **nella stessa posizione** della lista, non a quello con lo stesso nome (test `defaults_index_mismatch`).
- `nextsecret` non viene mai unito ai default (`UpdateMapEntry` non lo copia).
- Un entry per una mappa già presente **sostituisce** quella vecchia, senza fonderla.
- Il preprocessore lascia `*/` nel testo dopo un commento a blocco.
- Una `map` troncata a fine testo produce una mappa chiamata `MAP` (la parola precedente rimasta in `_String`).
- `levelname`/`label` tagliati a 255 caratteri (erano `string[255]`); nome della mappa a 8.
- `MUSIC`/`INTERMUSIC` di un lump inesistente azzera nome e numero (la mappa resta).

## 8. Rischi

- Il motore usa puntatori a `mapentry_t` (`gamemapinfo`): passando a record per valore il codice che li modifica va controllato (nessuno dovrebbe scriverli).
- `UMAPDEF` non è mai caricato dal motore: la parte dei default è provata solo dai test.
- `SC_Preprocess` ha effetti collaterali sul motore (`#CVARFORCE`...): il filtro va chiamato come oggi, una volta per testo.
- Il file `cases.txt` usa fine riga LF; `Tests\Data\MapInfo\.gitattributes` imposta `-text` perché git non li converta.
