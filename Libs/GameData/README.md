# Libs\GameData - la parte comune dei fork di DelphiDoom e come si aggiunge un gioco (issue #166)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

`Libs\GameData` è la parte comune di Mars3D, Rad-X e Speed (fork di DelphiDoom dello stesso autore, che restano id Tech 1):
quello che i tre fork avevano scritto tre volte. Sta sotto `Libs\Speed` (e sotto le librerie dei due fork che verranno).
Analisi completa dei tre fork: `Reference\_analisi\mars3d-radx-speed.md` (cartella ignorata da git) e `INTEGRAZIONE_GIOCHI.md`.

## 1. Che cosa c'è (fetta F0)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.GameData.Types` | `EGameDataException`, `TGamePatchHeader` (8 byte, `packed`), `TGamePatchOptions` (le tre varianti dei fork) e le costanti |
| `DelphiDoom.GameData.Intf` | `IGamePatchBuilder` e `IGameWadComposer` |
| `DelphiDoom.GameData.PatchBuilder` | `TGamePatchBuilder`: il costruttore di patch (`MARS_CreateDoomPatch`, `RX_CreateDoomPatch`, `SH_CreateDoomPatch` e le varianti da lump) |
| `DelphiDoom.GameData.WadComposer` | `TGameWadComposer`: il `TWadWriter` dei fork (`AddData`, `AddString`, `AddSeparator`) sopra `IWadBuilder` di `Libs\Wad` |
| `DelphiDoom.GameData.Factory` | `TGameDataFactory`, l'unico punto che conosce le classi |
| `DelphiDoom.GameData.Aliases` | `TGameAliases`: il profilo che un gioco prende in prestito (vedi sotto) |

**Le tre copie del costruttore di patch** (`mars_patch`, `radix_patch`, `speed_patch`) sono uguali tranne tre cose, ora in
`TGamePatchOptions`: il pixel che è un buco quando la patch non è solida (Mars 0, Rad-X 254, Speed 255) e l'intervallo della
palette in cui si cerca il colore più vicino (Mars e Speed 16..239, Rad-X 0..255). Le operazioni sono:
`FromColumns` (immagine a colonne, con o senza offset), `FromRows` (immagine a righe), `FromPalettedRows` (con la palette
VGA a 6 bit del file, i colori vanno alla palette del gioco), `FromPalettedRowsWithBackground` (la variante "opaca" di Rad-X)
e `SkyFromColumns`. Il colore più vicino lo dà `IColorMatcher` di `Libs\Palette`.

**Verifica**: `Tests\Data\GameData\patch.golden.txt` (1300 righe) ha lunghezza e impronta FNV-1a delle patch che le **tre copie
vecchie** hanno dato su 50 immagini sintetiche (10 misure per 5 contenuti, `TGameDataScenarios`, la stessa unit compilata dall'harness
e dai test), per ogni operazione e per i tre giochi: la libreria dà gli stessi byte, nessuna differenza. L'harness è fuori dal
repository (le tre unit originali di `Reference\` compilate insieme alle loro dipendenze). Test: `Tests\DelphiDoom.Tests.GameData`
(37; copertura 97%).

**Differenze volute dal vecchio**: un'immagine più corta di larghezza x altezza, un'altezza oltre 255 (una colonna non può avere
più di 255 pixel: il vecchio scriveva byte sbagliati) e una palette più corta di 768 byte danno `EGameDataException` (il vecchio leggeva
oltre il buffer); la libreria non scrive mai oltre un buffer. Un nome di lump non valido (più di 8 caratteri, vuoto) è un
`EGameDataException` e non un `I_Error`. I lump di testo hanno un byte per carattere (il vecchio `TWadWriter.AddString` scriveva
`SizeOf(char)` byte: 2 in Delphi 11, un difetto Unicode che i fork non avevano in Delphi 7).

## 2. Il meccanismo di profilo per un gioco nuovo (fetta F1)

### Come il motore sceglie oggi il profilo

`m_base.pas` dà a ogni eseguibile la costante `_GAME` ('Doom', 'Heretic', 'Hexen', 'Strife', dai define `DOOM`, `HERETIC`, ...). Il
composition root (`DelphiDoom.Engine.Composition`) la passa a una `TryFromName` per libreria, che dà il profilo o dice che non c'è
(allora `I_Error`: un nome sconosciuto non ricade mai su un altro gioco in silenzio):

| Libreria | Punto della scelta |
|---|---|
| Dehacked | `TDehackedGames.TryFromName` |
| Udmf | `TUdmfGames.TryFromName` |
| Luci, piattaforme, porte (Thinkers) | `TLightGames`, `TPlatGames`, `TDoorProfiles.TryGameFromName` |
| ActorDef | `TActorDefProfiles.TryFromName` |
| TableExport | `TExportProfiles.TryFromName` |
| Iwad | `TIwadGames.TryFromName` |
| Definitions (terreno) | `TDefGame` scelto da `TERRAIN_GAME` in `r_data.pas` (`{$IFDEF}`, non dal composition root) |
| Caricamento del livello | `ComposeLevelRules` crea la classe `*Rules` del gioco (`TDoomLevelRules`, ...) con `{$IFDEF}` |
| `Libs\IdTech` | `TIdTechFactory.CreateEngine(generazione, nome, versione)`: dà già nome e versione di qualsiasi fork (id Tech 1) |

### Che cosa è stato fatto

Un gioco che è un fork di Doom ha le regole di Doom quasi dappertutto; aggiungere un `{$IFDEF SPEED}` in ogni libreria sarebbe
il contrario di ciò che dice CLAUDE.md. Quindi:

* **`TGameAliases.ProfileOf(gioco, area)`** (`DelphiDoom.GameData.Aliases`): una sola tabella, nella libreria comune, dice quale
  profilo usa un gioco in ogni area (`TGameProfileArea`: Dehacked, Udmf, Lights, Platforms, Doors, ActorDef, TableExport, Iwad). I
  quattro giochi del motore e un nome sconosciuto restano se stessi (quindi un nome sbagliato continua a dare l'errore della
  libreria). **Speed** prende il profilo di **Doom** in tutte le aree **tranne Iwad**: soffitti, pavimenti, piattaforme, porte,
  luci e formato delle mappe sono quelli di Doom; Dehacked, ActorDef e TableExport sono un prestito **provvisorio** (le tabelle di
  mobj, stati e armi di Speed sono sue: quando ci sono, ognuna di queste tre aree avrà il profilo `Speed` vero e la riga della
  tabella sparisce); l'IWAD non si presta, perché i dati di Speed sono un `.JCL` e non un WAD di Doom.
* **`DelphiDoom.Engine.Composition`** chiama `TGameAliases.ProfileOf(_GAME, <area>)` dove prima passava `_GAME` alle otto `TryFromName`
  (otto righe e il `uses`): per i quattro giochi esistenti il nome è lo stesso, quindi nessun cambiamento di comportamento.
  Le unit sono state aggiunte ai dodici `.dpr` che usano il composition root (otto giochi e quattro `ddc_*`).
* Test in `Tests\DelphiDoom.Tests.GameData` (`DelphiDoom.Tests.GameData.Aliases`, 9 casi): i quattro giochi invariati, il profilo
  di Doom per Speed, nessun prestito per l'Iwad, maiuscole, nome sconosciuto invariato.

Verifica fatta: `Tools\build.bat Doom32 Release`, `Hexen32`, `GLHeretic32` e `ddc_strife` compilano; **non** provato a runtime (gli otto
eseguibili non sono stati avviati: la scelta dei profili è la stessa per i quattro giochi).

### Che cosa resta per aggiungere un gioco (Speed, e poi Mars e Rad-X)

1. **`m_base.pas`**: `_GAME = 'Speed'` con `{$IFDEF SPEED}` (insieme a `DOOM`, come il fork: gli eseguibili `GLSpeed32`
   definiscono `DOOM;OPENGL;SPEED`), e `APPNAME`/`WINCLASSNAME` dai nomi dei fork. Non è stato fatto: senza un eseguibile
   `GLSpeed32` non ha effetto.
2. **Iwad**: un profilo `Speed` in `TIwadGames` (il file dei dati è `SPEEDH.JCL`; `DelphiDoom.Iwad.Games` oggi ha solo i quattro giochi con
   IWAD di Doom). L'identificazione del `.JCL` la può fare `TSpeedContainer` (la firma `$DF73B489` in fondo al file).
3. **Livello** (`ComposeLevelRules`): una classe `TSpeedLevelRules` (`ILevelGameRules`, `ILevelGeometryRules`, `ILevelThingRules`) come
   `Doom\DelphiDoom.Engine.Level.DoomRules.pas`, perché Speed ha cose, tag e statistiche suoi (i livelli sono corse). Oggi la scelta è
   per `{$IFDEF}` dentro `ComposeLevelRules`: anche lì un `case` sul nome del gioco, preso da `TGameAliases`, sostituirebbe gli `{$IFDEF}`.
4. **Mobj e giocatore**: `mobj_t` e `player_t` di Speed hanno altri campi (`carid`, `tiredistance[0..3]: double`, ...): serve la tabella dei
   campi di `Libs\Serializer` per il gioco e, finché i thinker restano record nella zone memory, una cartella `Speed\` con le unit
   diverse da `Doom\` (fetta S5).
5. **Definitions** (`TERRAIN_GAME`): Speed ha il terreno di Doom, quindi `TDefGame.Doom`.

Il resto (`Libs\Speed`) è nel suo `README.md`.
