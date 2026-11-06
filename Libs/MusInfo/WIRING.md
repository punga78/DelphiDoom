# Libs\MusInfo - come collegarla al motore (issue #72, parte della #45)

La libreria legge il testo del lump MUSINFO e ne fa un catalogo neutro: per ogni coppia (mappa, id del music changer) il nome e il numero della musica. Non conosce il motore: dipende solo da `Libs\Logging` e `Libs\Scanner`. Il collegamento non e' stato fatto: `Base\p_musinfo.pas` e' com'era. Qui sotto cosa serve.

## 0. Cosa c'e' (e cosa no) in `p_musinfo.pas` e `p_sounds.pas`

- `Base\p_musinfo.pas`: **portata** la sola parte di lettura (`musinfo_t`, `P_AddMusInfo`, `P_InitMusInfo`, `P_FindMusinfoMusic`, righe 170-311). **Non portata** `A_MusicChanger`: e' un'azione di gioco (usa `mobj`, settore, giocatore della console, parametri custom dell'attore, `S_ChangeMusic`, `P_GetLevelInfo`) e resta com'e'; chiama solo `P_FindMusinfoMusic` e `S_DefaultMusicForMap`.
- `Base\p_sounds.pas`: **non portata, non c'e' nulla da portare**. Non contiene sequenze (SNDSEQ) ne' tabelle di suoni dei livelli ne' parsing: sono le azioni `A_SeeSound`, `A_PainSound`, `A_AttackSound`, `A_MeleeSound`, `A_DeathSound`, `A_ActiveSound`, `A_RipSound` (e le varianti `*1`) che leggono i campi di `actor.info` e i flag `MF_EX_*` e chiamano `S_StartSound`/`P_RandomSound`/`S_UnlinkSound`. E' logica di gioco sullo stato dei mobj, senza testi da leggere. Il parsing dei suoni (SNDINFO, alias) e' gia' in `Libs\ActorDef` (`TActorDefSoundInfoParser`). SNDSEQ, nel motore, non c'e'.

## 1. Unit da aggiungere ai `.dpr`

Servono in ogni progetto che compila `p_musinfo`: `Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32`, `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife`. `DelphiDoom.Logging.*` e `DelphiDoom.Scanner.Strings/Scanner` ci sono gia'. Righe:

```
  DelphiDoom.MusInfo.Types in 'Libs\MusInfo\DelphiDoom.MusInfo.Types.pas',
  DelphiDoom.MusInfo.Intf in 'Libs\MusInfo\DelphiDoom.MusInfo.Intf.pas',
  DelphiDoom.MusInfo.Parser in 'Libs\MusInfo\DelphiDoom.MusInfo.Parser.pas',
  DelphiDoom.MusInfo.Catalog in 'Libs\MusInfo\DelphiDoom.MusInfo.Catalog.pas',
  DelphiDoom.MusInfo.Loader in 'Libs\MusInfo\DelphiDoom.MusInfo.Loader.pas',
  DelphiDoom.MusInfo.Factory in 'Libs\MusInfo\DelphiDoom.MusInfo.Factory.pas',
```

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`: ` Tests\DelphiDoom.Tests.MusInfo`

## 2. Cosa sostituisce cosa in `Base\p_musinfo.pas`

| Vecchio | Nuovo |
|---|---|
| `P_InitMusInfo` | `IMusInfoLoader.Load` (la chiama `P_Init` in `p_setup.pas`, riga 2052) |
| `P_AddMusInfo` | `IMusInfoCatalog.Add` (chiamata dal loader) |
| `P_FindMusinfoMusic(id, mapname)` | `IMusInfoCatalog.Find(id, mapname)`; `P_FindMusinfoMusic` resta come facciata di una riga per `A_MusicChanger` |
| `musinfo`, `nummusinfo`, `musinfo_t`, `MAXMUSINFO` | dentro `TMusInfoCatalog` (`MUSINFO_MAX_ENTRIES`, `TMusInfoEntry`) |
| lettura con `TScriptEngine` (`P_InitMusInfo`) | `TMusInfoParser.Parse` |
| `W_CheckNumForName(S_MUSINFO_LUMP)` + `W_TextLumpNum` | `IMusInfoTextSource.TryGetText` |
| `MUSICCHANGER_HI - MUSICCHANGER_LO` | `MUSINFO_MAX_MUSIC_ID` (64) |

Restano nel motore: `S_MUSINFO_PARAM`, `S_MUSINFO_LUMP`, `MUSICCHANGER_LO/HI/MUSICCHANGER` (usati da `p_mobj.pas` di Doom, Heretic e Hexen) e `A_MusicChanger`. Se si cambia `MUSICCHANGER_HI`, aggiornare `MUSINFO_MAX_MUSIC_ID` (64 = HI - LO); oppure far passare il limite al parser (oggi e' una costante).

## 3. Composition root (`DelphiDoom.Engine.Composition`)

Adattatori nel motore, tutti sottili (una unit per classe, `DelphiDoom.Engine.MusInfo.*`):

- `IMusInfoMusicResolver.MusicNumberFor(AUpperName)` = `S_GetMusicNumForName(AUpperName)`. **Ha la stessa firma di `IMapMusicResolver`**: `TEngineMapInfoServices` (`Base\DelphiDoom.Engine.MapInfo.Services.pas`) puo' implementare anche `IMusInfoMusicResolver` senza un metodo nuovo; per Hexen, che non ha UMAPINFO, serve una classe a parte (e' una funzione di una riga).
- `IMusInfoTextSource.TryGetText(AUpperName, out AText)`: `lump := W_CheckNumForName(AUpperName); Result := lump >= 0; if Result then AText := W_TextLumpNum(lump)`. Il testo e' quello grezzo, **senza** `SC_Preprocess` (come prima).
- `ILog`: lo stesso gia' dato agli altri script (`TEngineScannerLog`).

```
log     := TEngineScannerLog.Create;           // o l'ILog di I_ConfigureLog
catalog := TMusInfoFactory.CreateCatalog(musicResolver, log);
parser  := TMusInfoFactory.CreateParser(log);
loader  := TMusInfoFactory.CreateLoader(textSource, parser, catalog);
```

`p_musinfo` riceve `catalog` e `loader` da una `P_ConfigureMusInfo(ACatalog, ALoader)` chiamata da `ComposeEngine` (come le altre `*_Configure`); `P_InitMusInfo` diventa `loader.Load` e `P_FindMusinfoMusic` diventa `Result := catalog.Find(id, mapname)`. Senza configurazione, `I_Error` come le altre.

## 4. Cosa si cancella dopo il collegamento

Da `Base\p_musinfo.pas`: `MAXMUSINFO`, `musinfo_t`, `Pmusinfo_t`, `musinfo_tArray`, `nummusinfo`, `musinfo`, `P_AddMusInfo` e il corpo di `P_InitMusInfo` (circa 130 righe); e dall'`uses` `sc_engine` e `w_wad` se non servono ad altro (`A_MusicChanger` usa `stringtochar8` di `w_wad`).

## 5. Differenze dal vecchio codice

Il parser e il catalogo danno gli stessi risultati del vecchio su 36 casi (`Tests\Data\MusInfo`, vedi il README li'). Differenze volute o difetti non copiati:

1. **Nome di musica sopra 8 caratteri**: il vecchio `stringtochar8` chiamava `I_Error` e fermava il gioco. Ora un avviso (`Music name "X" is too long, maximum size is 8 characters`) e la voce e' saltata; la lettura continua.
2. **Piu' di 1024 voci**: il messaggio di avviso del vecchio passava una stringa a un `%d` (`... of map "%d"`), cioe' `FmtStr` sollevava `EConvertError` dentro `P_InitMusInfo` (il gioco cadeva). Ora l'avviso e' scritto bene (`More than 1025 musinfo entries found, ignoring mus "D_X" of map "MAP01"`), la voce e' scartata e si va avanti. Una voce con mappa e id gia' presenti si sostituisce anche a catalogo pieno (come prima).
3. **Ordine degli avvisi**: il vecchio chiamava `S_GetMusicNumForName` (che puo' scrivere un avviso) mentre leggeva, voce per voce; ora il parser legge tutto il testo e il catalogo risolve i numeri dopo. Cambia solo l'ordine tra gli avvisi di lettura e quelli del resolver, non il loro contenuto. Il resolver riceve il nome gia' **in maiuscolo** (prima lo riceveva com'era scritto; `S_GetMusicNumForName` mette comunque in maiuscolo).
4. **Il nome nei messaggi**: l'avviso di catalogo pieno usa il nome in maiuscolo.
5. Il catalogo non e' piu' globale: due `Load` aggiungono allo stesso catalogo (come due `P_InitMusInfo`); per ripartire da zero c'e' `Clear` (il vecchio non lo aveva: `P_InitMusInfo` e' chiamata una volta sola, da `P_Init`).

Difetti del vecchio **conservati** (coperti dai golden):

- Un token che non e' un nome di mappa e' sempre letto come id, e la parola dopo come nome: `MAP01 1 D_A D_B D_C` da' un avviso su `D_B` e consuma `D_C`.
- A fine testo senza il nome (`MAP01 7`) lo scanner avvisa (`MustGetString: Missing string`) ma la parola corrente resta l'id, che diventa il nome: la voce `(MAP01, 7, "7")` viene aggiunta con numero -1.
- Un nome vuoto (`""`) e un token vuoto dopo una mappa fermano la lettura di tutto il resto del testo.
- Un id con `-0x` (es. `-0x1`) e' negativo, quindi non valido; `0X14` e `x15` sono accettati da `Val` (20 e 21); `5.0`, `1e1`, `0x` e `99999999999` non sono numeri validi. La libreria usa `Val` e lo stesso ripiego (`0x`, `-0x`, `#`) dell'`atoi` storico, quindi legge gli stessi valori.
- I caratteri 128-159 dei nomi passano dal scanner (`TScriptScanner`) e possono diventare `?`: e' un difetto dello scanner, non di questa libreria.
- Il numero di una musica sconosciuta e' -1 e la voce c'e' lo stesso: `Find` da' -1 per una voce senza musica come per una voce assente (`A_MusicChanger` guarda `musnumber > 0`).

## 6. Rischi

- **`Find` in `A_MusicChanger`**: oggi `P_FindMusinfoMusic` fa `stringtochar8(strupper(mapname))`, che ferma il gioco se il nome e' lungo piu' di 8 caratteri; `catalog.Find` no (non trova niente). Nessun caso reale (i nomi di mappa del motore sono di 4-5 caratteri).
- **Test e golden vengono da stub**: `S_GetMusicNumForName` vero non e' provato (accetta numeri, `0` per il nome vuoto) e nemmeno un lump MUSINFO letto da un WAD. Dopo il collegamento provare una mappa con un MUSINFO vero (musica cambiata dal music changer, `-devparm` per gli avvisi).
- **Hexen**: `P_InitMusInfo` e' chiamata anche li' (`p_setup.pas` e' condiviso, Hexen ha il suo `p_mobj`): il resolver e' `S_GetMusicNumForName` di Hexen; `A_MusicChanger` resta com'e'.
- La libreria tiene `TMusInfoEntry.MusicNumber`: se i numeri delle musiche cambiano dopo il `Load` (per esempio dopo un caricamento di `DEHACKED` o di nuovi suoni), il numero della voce resta quello di allora, come nel vecchio codice (il numero era calcolato in `P_AddMusInfo`).
