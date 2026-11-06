# Libs\TextureDefs - come collegarla al motore (issue #73, parte della #45)

La libreria legge le **definizioni** delle texture e dei flat e ne fa un modello neutro; non compone pixel, non
tocca zone memory, cache, `textures[]` o `flats[]`. Non conosce il motore: dipende solo da `Libs\Logging` e
`Libs\Scanner` (solo `FlatInfoParser`). Il collegamento non è stato fatto: qui sotto c'è cosa serve.

| Origine nel motore | Classe della libreria | Modello |
|---|---|---|
| `PNAMES` (`R_InitTextures`) | `TTextureDefsPatchNamesReader` | `TArray<string>` (maiuscoli, senza spazi ai lati) |
| `TEXTURE1/2/3` (`R_InitTextures`) | `TTextureDefsTextureLumpReader(format)` | `TTextureDefsTexture` (nome, L, A, masked, patch con origine, indice in PNAMES e nome) |
| `TEXTURE0` (`R_InitTextures`, dopo `R_InitPK3Textures`) | `TTextureDefsPk3Reader(format)` | `TTextureDefsTexture` con un patch il cui nome è quello della texture |
| i tre sopra insieme | `TTextureDefsLoader` (`ITextureDefsLoader.Load`) | `TTextureDefsSet` (PNAMES + texture nell'ordine del motore) |
| `FLATINFO` (`R_ParseFlatInfoText`) | `TTextureDefsFlatInfoParser` | `TArray<TTextureDefsFlatSize>` (indice del flat, nome, codice) |
| `R_FlatSizeFromSize` | `TTextureDefsFlatSizes.CodeFromSize` / `SizeFromCode` | codici `FLAT_SIZE_64 .. FLAT_SIZE_4096` (= `FS64x64 .. FS4096x4096`) |

Il layout dei lump è una strategia: `TTextureDefsFormat.Standard` (Doom, Heretic, Hexen: intestazione 22 byte,
patch 10) o `Strife` (18 e 6, nel motore `{$IFDEF STRIFE}` di `r_defs.pas`). Si sceglie in un solo punto con
`TTextureDefsFactory.CreateLoader(sorgente, formato)`; i record packed hanno `SizeOf` coperto da test.

## 1. Unit da aggiungere ai `.dpr`

Servono a tutti i progetti che compilano `r_data` e `r_flatinfo`: `Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`,
`Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32` (i `ddc_*` non usano `r_data`). `DelphiDoom.Logging.*` e
`DelphiDoom.Scanner.Strings/Scanner` ci sono già.

```
  DelphiDoom.TextureDefs.Types in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Types.pas',
  DelphiDoom.TextureDefs.Intf in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Intf.pas',
  DelphiDoom.TextureDefs.Names in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Names.pas',
  DelphiDoom.TextureDefs.FlatSizes in 'Libs\TextureDefs\DelphiDoom.TextureDefs.FlatSizes.pas',
  DelphiDoom.TextureDefs.PatchNamesReader in 'Libs\TextureDefs\DelphiDoom.TextureDefs.PatchNamesReader.pas',
  DelphiDoom.TextureDefs.TextureLumpReader in 'Libs\TextureDefs\DelphiDoom.TextureDefs.TextureLumpReader.pas',
  DelphiDoom.TextureDefs.Pk3Reader in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Pk3Reader.pas',
  DelphiDoom.TextureDefs.FlatInfoParser in 'Libs\TextureDefs\DelphiDoom.TextureDefs.FlatInfoParser.pas',
  DelphiDoom.TextureDefs.Loader in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Loader.pas',
  DelphiDoom.TextureDefs.Factory in 'Libs\TextureDefs\DelphiDoom.TextureDefs.Factory.pas',
```

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`: ` Tests\DelphiDoom.Tests.TextureDefs`

## 2. Adattatori del motore (da scrivere, in `Base\`)

- `TEngineTextureLumpSource` (`ITextureDefsLumpSource`): `TryReadLump(nome)` = `W_CheckNumForName(nome)`; se `-1` dà
  `False`, altrimenti copia i byte del lump (`W_LumpLength` + `W_ReadLump` in un `TBytes`; niente zone memory: il
  modello non tiene puntatori ai byte). Vince il lump con quel nome, come prima.
- `TEngineFlatCatalog` (`ITextureDefsFlatCatalog`): `LastIndexOf(nome)` = il ciclo di `R_ParseFlatInfoText`
  (`for i := numflats - 1 downto 0 do if nome = char8tostring(flats[i].name)`), `-1` se manca.
- Il formato (`Standard`/`Strife`) lo sceglie `ComposeEngine` (o il punto che crea il loader) con un `{$IFDEF STRIFE}`
  solo lì.

## 3. `R_InitTextures` (`Base\r_data.pas`): cosa sostituisce cosa

Il modello è **separato dalla sua applicazione**: la libreria dà il modello, il motore costruisce gli array globali.

1. **Lettura.** Le ~80 righe che leggono PNAMES, TEXTURE1/2/3 e il `maptexture_t` di ogni texture diventano
   `LSet := TextureDefsLoader.Load(False)`. `R_InitTexturesOld` (già dentro un `{$IFDEF}`) si cancella.
2. **PNAMES -> lump.** Per ogni `LSet.PatchNames[k]` il motore calcola `patchlookup[k]` come prima
   (`W_CheckNumForName(nome, TYPE_PATCH or TYPE_SPRITE)`, poi senza tipo; avvisi `I_DevWarning`/`I_Warning`; per Strife
   solo se `teaser = 0`; negli altri giochi `NULLA0` come ripiego). La libreria non lo fa perché dipende dai lump e
   dai giochi. Gli avvisi restano uno per voce di PNAMES, anche se nessuna texture la usa.
3. **Applicazione.** Per ogni `LSet.Textures[i]`: `textures[i] := malloc(SizeOf(texture_t) + SizeOf(texpatch_t) *
   (patchcount - 1))`, `texture.name := stringtochar8(Name)`, `width`/`height`/`patchcount`, `texture32 := nil`
   (software); per ogni patch `originx`/`originy` e `patch := patchlookup[PatchIndex]`; `-1` -> `I_Error('R_InitTextures():
   Missing patch in texture %s')` come prima. Poi `texturecolumnlump/ofs`, `texturewidth`, `textureheight = Height *
   FRACUNIT`, `texturecolumnheight = max(Height, 128)`, `texturecolumnheightfrac`: invariati.
4. **PK3.** `R_InitPK3Textures` chiama `R_CheckTextureNumForName`, che legge `textures[]`/`numtextures`: **va chiamata
   dopo il punto 3**, come oggi. Se dà `True`, il motore legge `TEXTURE0` con `TTextureDefsFactory.CreatePk3Reader(formato).Read(byte)`
   (oppure rifà `Load(True)` e scarta le prime), e per ogni texture applica come sopra con una differenza: il patch si
   cerca con `W_CheckNumForName(Patches[0].PatchName, TYPE_PATCH)` e `-1` **non** è un errore (come prima).
   `realloc` degli array con `numtextures0`, `numtextures := numtextures + numtextures0`.
5. `R_GenerateLookup`, `texturetranslation`: invariati.

Resta nel motore, non portato: `R_GenerateLookup`, `R_GenerateComposite`, `R_DrawColumnInCache*`, `R_GetColumn` e ogni
cache; `R_NameForSideTexture`, `R_TextureNumForName` e simili (ricerche sugli array globali).

## 4. `R_ParseFlatInfoLumps` (`Base\r_flatinfo.pas`)

`R_RetrieveFlatInfo` e la raccolta dei testi (lump `FLATINFO`, `PAK_StringIterator`) restano. `R_ParseFlatInfoText(text)`
diventa:

```
for LEntry in TextureDefsFlatInfoParser.Parse(text, FlatCatalog) do
  flats[LEntry.FlatIndex].size := LEntry.SizeCode;
```

con il parser creato da `TTextureDefsFactory.CreateFlatInfoParser(log)` (il log è l'`ILog` del motore: gli avvisi
sono gli stessi testi di `I_Warning`, con CR LF finale). `R_FlatSizeFromSize` resta come facciata su
`TTextureDefsFlatSizes.CodeFromSize`; le costanti `FS64x64..FS4096x4096` hanno gli stessi valori di `FLAT_SIZE_*`.
Non portati: `R_ShrinkFlatTo64x64` e i tipi `flatNxN_t` (lavorano sui pixel), `dsscale_t`/`ds_scale`.

## 5. `Base\r_pk3textures.pas`: nota importante

Nonostante l'issue, **il motore non legge un lump `TEXTURES` testuale** (formato ZDoom): le "texture del PK3" sono le
immagini sciolte in `textures/` che `R_InitPK3Textures` converte in patch (`R_TextureAsPatch`) e flat
(`R_TextureAsFlat`), scrive in due WAD di cache (`pk3tex_*.wad`, `pk3flat_*.wad`) e descrive con un lump **binario**
`TEXTURE0`/`PNAMES0` (stesso formato di TEXTUREx, una voce da 32 byte per texture, un solo patch, senza directory di
offset). Di tutto questo la libreria legge solo `TEXTURE0` (`TTextureDefsPk3Reader`). **Non portati** (dipendono da
`PTexture`, palette, thread `MT_Iterate`, `TWadWriter`, hash e file di cache): `R_AddTextureFileName`,
`R_TextureAsPatch`, `R_TextureAsFlat`, `Hash`, e la scrittura di `TEXTURE0`/`PNAMES0`. Un lump `TEXTURES` testuale non
esiste nel motore: se servirà, è una nuova classe con la stessa interfaccia `ITextureDefsPk3Reader`.

## 6. Differenze volute dal vecchio codice

- Il vecchio controllava solo `offset > maxoff`: con `offset = maxoff` leggeva oltre il lump. Ora **ogni texture deve
  stare per intero nel lump** (intestazione e tutti i patch): se no `ETextureDefsException` (`BadDirectory`), che
  `R_InitTextures` gira a `I_Error('R_InitTextures(): bad texture directory')`.
- Un `patchcount` negativo, un conteggio di texture o di nomi che non entra nel lump, un lump più corto di 4 byte: errore
  (prima byte a caso o crash). Un indice di patch fuori da PNAMES: `BadPatchIndex` (prima `patchlookup[...]` fuori limiti).
- PNAMES mancante o TEXTURE1 mancante: `MissingLump` (prima l'errore di `W_CacheLumpName`/`W_GetNumForName`).
- Il modello non contiene `-1` per un patch non trovato: la risoluzione resta al motore (punto 2).

Difetti **conservati** (verificati dai golden): il nome di una texture non è tagliato e si ferma al primo byte 0 (8 byte
senza terminatore sono validi); `TEXTURE0` ignora l'indice del patch e il `patchcount` dell'intestazione (sempre 1);
in `FLATINFO` un flat sconosciuto salta solo quella parola (un `SIZE 128` che segue è letto come due parole
sconosciute); un flat senza `SIZE` restituisce la parola; `SIZE` senza numero valido riusa l'ultimo intero letto dallo
scanner; una dimensione fuori da 128..4096 è 64x64; un flat nominato due volte compare due volte (vince l'ultimo); il
catalogo cerca dall'ultimo flat.

## 7. Test

`Tests\DelphiDoom.Tests.TextureDefs` (95 test): record su disco, nomi, PNAMES, TEXTUREx (Standard e Strife), TEXTURE0,
FLATINFO, loader, factory e parità con il vecchio codice (`Tests\Data\TextureDefs`, vedi il suo README). I test sui WAD
reali (`bin\Doom\DOOM1.WAD`, `FREEDOOM2.WAD`, `bin\Heretic\HERETIC1.WAD`, `bin\Hexen\HEXEN.WAD`, `bin\Strife\STRIFE0.WAD`) si
saltano se il WAD manca.
