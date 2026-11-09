# Libs\Dehacked: come collegarla al motore (issue #68, parte della #45)

La libreria legge una patch DEHACKED/BEX e ne fa un **modello neutro**: `IDehackedPatch` con le sezioni nell'ordine del file (`TDehackedSection`: tipo, riga, intestazione, riferimento, campi `TDehackedEntry` gia' tipizzati). **Non tocca nessuna tabella del motore**: l'applicazione (le `case` su `mobjinfo`, `states`, armi, munizioni, stringhe, suoni) resta in `deh_main.pas` di ogni gioco, in una funzione nuova che legge il modello. Stampa e salvataggio delle impostazioni correnti (`DEH_CurrentSettings`, i CSV) non sono cambiati.

## Unit da aggiungere ai `.dpr` dei giochi (e a quelli dei `ddc_*` se linkano `deh_main`)

Le unit di `Libs\Logging` ci sono gia'. Aggiungere, con il percorso `Libs\Dehacked\`:

```
DelphiDoom.Dehacked.Types, .Strings, .Text, .Section, .Intf, .Patch, .LineSource, .FieldTable,
.FlagSet, .FlagSets, .FieldReader, .FieldKinds, .GameData, .Data.Doom, .Data.Heretic, .Data.Hexen,
.Data.Strife, .Reader.Base, .Reader.Thing, .Reader.Frame, .Reader.Weapon, .Reader.Ammo,
.Reader.Sound, .Reader.Misc, .Reader.Pars, .Reader.Text, .Reader.Pointer, .Reader.Marker,
.Reader.Lines, .Profile, .Parser, .Games, .Factory      (tutte con prefisso DelphiDoom.Dehacked.)
```

Nessuna usa unit del motore (solo `System.*` e `DelphiDoom.Logging.*`). Le quattro `Data.*` sono linkate tutte da `TDehackedGames`; sono tabelle di nomi, pesano pochi KB.

## Composition root

In `DelphiDoom.Engine.Composition` (`ComposeEngine`), dopo la creazione dell'`ILog`:

```pascal
D_ConfigureDehacked(TDehackedFactory.CreateParser(TDehackedGame.dgDoom, LLog));  // dgHeretic, dgHexen, dgStrife nei rispettivi
```

`TDehackedFactory.CreateParser(AGame, ALog)` assembla il profilo del gioco (`TDehackedGames.CreateProfile`): quali blocchi esistono (Hexen non ha `AMMO` ne' `[PARS]`, Strife nemmeno `[PARS]`; Heretic ha le armi a livelli, Hexen le armi per classe e `[MUSIC]` con le parentesi), le tabelle dei campi nell'ordine delle vecchie `*_tokens`, le liste dei flag, il numero di armi e di munizioni, i limiti dei par. Il gioco e' quello di `_GAME` come per `P_ConfigureUdmf`. `ALog` puo' essere nil (niente avvisi). In `deh_main.pas` una variabile di unita' `deh_parser: IDehackedParser` (nel solo punto di ingresso, come `P_ConfigureUdmf`), `I_Error` se non e' stata configurata.

## Cosa sostituisce cosa

| Vecchio | Nuovo |
|---|---|
| `DEH_NextLine` (`deh_base`) | `TDehackedLineSource.Next` (interno al parser) |
| `DEH_ParseText(testo)` | `deh_parser.Parse(testo)` poi `DEH_Apply(patch)` |
| `DEH_Parse(TDStringList)` (ogni `deh_main`) | `deh_parser.ParseLines(righe)` poi `DEH_Apply(patch)`; `DEH_ParseFile` chiama quello |
| `DEH_ParseLumpName`, `DEH_ParseLumpNames`, `DEH_ParseLumpNum`, `DEH_ParseFile` | restano (leggono lump e file) e arrivano a `DEH_ParseText` |
| `DEH_StringToCString`, `DEH_CStringToString`, `DEH_StringValue` | `TDehackedText.StringToCString` / `.CStringToString` / `.StringValue` (stesso codice) |
| `DEH_FixedOrFloat` | `TDehackedStrings.FixedOrFloat`; il modello porta gia' il valore in `Entry.Fixed` |
| i campi `mobj_tokens`, `*_flags*`, `state_tokens`, `weapon_tokens`, `ammo_tokens`, `sound_tokens`, `misc_tokens` + gli hash | per il parse non servono piu'; servono ancora a `DEH_CurrentSettings` e ai CSV (si possono rimpiazzare con `TDehacked<Gioco>Data.Build` in un passo successivo) |
| `TDEHStringsHashTable` | da cancellare dopo il collegamento se nessun'altra unit la usa (il grep al momento non ne trova) |
| `DEH_AmmoType`, `DEH_WeaponType`, `DEH_PlayerClass`, la tabella delle azioni e il suo hash | restano: risolvono nomi, e' compito del motore |

## `DEH_Apply(patch)`: cosa deve fare, sezione per sezione

Lo stato che il vecchio `DEH_Parse` teneva e che ora tiene `DEH_Apply`: `deh_initialstates` (= `numstates` all'inizio e dopo ogni `SUBMITNEWSTATES`), la copia `code_ptrs` delle azioni, `did_max_soulsphere` (per sezione Misc), `ismbf21`. Le righe di modello sono nell'ordine del file e vanno applicate in quell'ordine. Le intestazioni che il parser non puo' controllare (servono le tabelle) arrivano nel modello e vanno controllate con **gli stessi avvisi di prima**:

* **`dskThing`** — `Reference.IsNew`: `Info_GetNewMobjInfo` + `Info_SetMobjName(n, Reference.Name)` (con le tracce `devparm` di prima); altrimenti `n := Reference.Number`, se `(n <= 0) or (n > nummobjtypes)` avviso `Wrong think number = %d` e sezione saltata; poi `dec(n)`. Per ogni `Entry` si usa `Entry.Field` (indice canonico nella tabella del gioco, lo stesso di prima: gli alias gia' ridotti) con la stessa `case` di prima, ma con i valori gia' pronti: `Number` (numeri), `Text` (nomi: `S_GetSoundNumForName(Text)`, `Info_GetMobjNumForName(Text)`, `Info_SetMobjName`, `R_GetBloodTranslationIdForName`, `strupper(Text)` per translation, obituary), `Fixed` (campi in virgola fissa), `HasFlags`/`Flags` (se `HasFlags` si assegna il campo, altrimenti il campo non cambia), `StateRef` per gli stati (`srPlain` = `Number`, `srNew` = `Number + deh_initialstates`, `srOriginal` = `Number`). RENDERSTYLE e GENDER: se `Number >= 0` e' l'indice (con i soliti avvisi di intervallo) altrimenti `R_Get...ForName(Text)`. INHERITSFROM uguale alla cosa stessa vale -1. Strife: NAME2 copia i caratteri in `name2`. Alla fine di ogni cosa: `Section.ExtraFlags` bit 0 -> `flags_ex or MF_EX_TRANSPARENT`, bit 1 -> `flags2_ex or MF2_EX_FRIEND`, bit 2 -> `flags3_ex or MF3_EX_BOUNCE` (il bit 3, touchy, non faceva nulla; Strife non ha mai i bit extra: il flag e' sempre 0). Se un `Entry.Mbf21` e' presente `ismbf21 := true`. `P_ResolveMBF21Flags` sempre alla fine.
* **`dskFrame`** — `IsNew`: `state_no := Number + deh_initialstates` e `while numstates <= state_no do Info_GetNewState`; altrimenti `Number >= 0` e' lo stato, se e' negativo si cerca `statenames.IndexOfToken(Reference.Name)` e se manca avviso `Wrong state number = %s` (con `Name`) e sezione saltata; poi `SC_FillStateNames`. Campi: sprite `Info_GetSpriteNumForName(Text)`; `Bright` -> `FF_FULLBRIGHT + Number`; NEXT FRAME: `srOriginal` -> `Number`, `srNew` -> `deh_initialstates + Number`, altrimenti nome in `statenames` se c'e', altrimenti `deh_initialstates + Number` se la sezione e' nuova, altrimenti `Number`; azione: se `Number >= 0` e' l'indice (`< dehnumactions` altrimenti avviso), se no cerca `ActionName` con `DEH_SearchActionFromHash` (e poi il ciclo `name`/`A_name`; la vecchia ricerca per hash usava il testo intero, provare prima `Entry.Text` poi `ActionName`), trovata: libera/crea `params` con `SC_FixParenthesisLevel(ActionArguments)` se `ActionArguments <> ''`, non trovata: avviso `Unknown action function = "%s" in state %d`; OWNER `Info_AddStateOwner`; ARGSn con il bit `ARGn_DEFINED`; alla fine `mbf21bits <> 0` -> `ismbf21`.
* **`dskWeapon`** — `Reference.Number >= 0` e' l'arma; se e' -1 `DEH_WeaponType(Reference.Name)` e, se manca, avviso `Wrong weapon number = %s`. Hexen: `Reference.QualifierNumber` o, se -1, `DEH_PlayerClass(Qualifier)` e' la classe. Campi: AMMO TYPE/MANA TYPE se `Number < 0` `DEH_AmmoType(Text)` e avviso `After %s keyword found invalid ammo %s (Weapon number = %d)`; stati come sopra; AMMO PER SHOT imposta anche `WIF_ENABLEAPS`; Heretic: il campo LEVEL (1 o 2, gia' controllato) sceglie `wpnlev1info`/`wpnlev2info` e `WeaponAmmoUsePL1/2` per le righe che seguono (come `weapon_level` di prima, parte da 1 a ogni Weapon).
* **`dskAmmo`** (`maxammo`, `clipammo`; il numero e' gia' controllato), **`dskMisc`** (campi per indice; MAX HEALTH imposta anche `p_maxsoulsphere` se prima non c'e' stato MAX SOULSPHERE nella stessa sezione; i valori sono gia' controllati), **`dskPars`** (`Numbers`: episodio, mappa, tempo oppure mappa, tempo: `pars[]`/`cpars[]`).
* **`dskSound`** — `Reference.Name` che comincia con una cifra e' un numero (`Reference.Number`, -1 se non lo e'): se `(n < 0) or (n >= numsfx)` avvisi `Wrong sound number = %s` e (se `>= numsfx`) `New sounds can only specified in things definition!`, sezione saltata; altrimenti nome: `S_GetSoundNumForName(Name)` (vedi i rischi). Poi singularity/priority/name.
* **`dskSprites`** — chiave numerica nell'intervallo -> indice e nome preso dalla tabella, altrimenti il nome (4 caratteri, altrimenti avviso `Sprite name with %d characters = %s`), poi la ricerca come prima e `Can not find sprite = %s`; il valore (`Text`) e' gia' di 4 caratteri.
* **`dskStrings`** — `Key` = nome della stringa; `deh_strings._array[j].pstr^ := TDehackedText.CStringToString(Text)`. **`dskText`** — `OldText`/`NewText`: come prima (`StringValue` dei testi, ricerca nelle stringhe, poi nella musica, poi negli sprite se `OldLength = 4` e `NewLength = 4`) e avviso `Can not find setable text "%s" - should be changed to "%s"`.
* **`dskMusic`**/**`dskSounds`** — `Number >= 1` e `< nummusic`/`numsfx`: per indice; altrimenti ricerca per nome/mappa con i prefissi `D_` (Doom, Strife), `MUS_` (Heretic, Hexen) per la musica e `DS` per i suoni (nel blocco `Text` il prefisso `D_` e' per tutti). Hexen: `Entry.Cleared` = il vecchio codice azzerava il nome di `S_music[music_idx]` con un `music_idx` vecchio (di un giro prima, o spazzatura): qui si azzera quello della riga precedente della stessa sezione, se c'e', altrimenti niente.
* **`dskCodePointers`** — `Numbers[0]` stato, `Number >= 0` indice di azione, altrimenti `Text` (poi `ActionName`) come per i frame. **`dskPointer`** — `Reference.Number` e' il frame da modificare, `Entry.Number` quello da cui copiare: se `0 <= v < numstates` `v < deh_initialstates` -> `code_ptrs[v]`, se no `states[v].action`; altrimenti avviso `Invalid state number "%s" while parsing CODEP FRAME`.
* **`dskSubmitNewStates`** — rifare `code_ptrs` da `states[].action` e `deh_initialstates := numstates`. **`dskCheat`** — niente (come prima).
* `IDehackedPatch.DoomVersion`, `.PatchFormat`, `.HasSignature` sono nuovi: il vecchio codice non guardava l'intestazione; se si vuole rifiutare una versione non supportata e' una scelta del motore.

## Cosa si puo' cancellare dopo il collegamento

Da `deh_main.pas` di ogni gioco: tutto il corpo di `DEH_Parse` (circa 1600 righe) e le variabili locali relative; da `deh_base.pas`: `DEH_NextLine`, `DEH_FixedOrFloat`, le tre conversioni di stringhe, `TDEHStringsHashTable`, `dehstringhash`; i `*_hash` e le `uses` che servivano solo al parse. Restano `DEH_CurrentSettings`, i CSV, le azioni, `DEH_Init`/`DEH_ShutDown`.

## `Tools\build.bat`

Aggiungere alla lista `TESTS` (riga 38): `Tests\DelphiDoom.Tests.Dehacked`.

## Come sono stati ottenuti i golden

Vedi `Tests\Data\Dehacked\README.md`. In breve: un harness temporaneo (non committato) compila il **vecchio** `DEH_Parse` dentro il motore di ciascun gioco (stesso elenco di unit del `<Gioco>32.dpr`, nessuna finestra), lo fa girare su ogni patch di `Tests\Data\Dehacked\*.deh` e scrive le righe del dump di `DEH_CurrentSettings` che sono cambiate piu' i messaggi di `I_Warning`. Affidabilita': alta per cio' che il dump mostra (campi numerici, flag, virgola fissa, stati, armi, munizioni, Misc, par, le stringhe cambiate); `TDumpApplier` nei test fa le veci del motore e spiega le stesse righe con i valori del modello. Non coperto dai golden: nomi risolti dal motore, cose e stati nuovi, armi degli altri giochi, `Sound` (il dump non mostra singularity/priority), azioni.

## Differenze volute dal vecchio codice

* Il parser non applica nulla: un'intestazione che il motore trova non valida (cosa fuori dalla tabella, stato per nome che non c'e', arma per nome, suono) non scarta il blocco nel parser; il motore avvisa e **salta la sezione**. Il vecchio codice, scartando l'intestazione, rileggeva i campi come intestazioni (con possibili avvisi in piu', ad esempio `Ammo type = 1` letto come blocco `AMMO`). Gli avvisi di questi casi escono dopo quelli del parser.
* Gli avvisi "(Think number = %d)" di una cosa nuova, "(State number = %d)" di un frame nuovo e "(Weapon/Sound number = %d)" di un riferimento per nome mostrano il numero come scritto (o -1), non quello che il motore avrebbe dato.
* Il controllo del nome dello sprite a sinistra dell'uguale (`Sprite name with %d characters = %s` per la chiave) e' del motore; il controllo del nome nuovo e' del parser.
* Nuovo: `DoomVersion`, `PatchFormat`, `HasSignature`; hexen: `Entry.Cleared` al posto del vecchio `music_idx` stantio.
* La riga `Weapon` in Hexen con numero ma senza classe e' scartata dal parser (come prima), `Weapon` con nome e' risolto dal motore.

## Difetti del vecchio codice conservati

* Il ciclo principale guardava solo `i < s.Count`: una riga restituita da una sezione (campo sconosciuto) nell'**ultima riga** del testo non e' piu' riletta come intestazione (`SUBMITNEWSTATES` come ultima riga dopo una sezione e' ignorato).
* `Text`: il corpo e' letto con `DEH_NextLine(..., false)` che dopo un commento torna a saltare le righe vuote e a tagliare; se le righe sono meno del previsto il testo nuovo comincia con un a capo.
* Tutta la riga e' in maiuscolo (anche i testi delle stringhe, `TEXT`, gli obituary).
* Hexen: il blocco `MAX MANA` non e' mai stato letto (la parola della riga e' tagliata al primo spazio e non puo' valere `'MAX MANA'`): la libreria non lo registra; il valore si imposta con il campo `Max Mana` di Misc.
* `Misc`: un valore negativo termina la sezione e la riga e' riletta come intestazione.
* `atoi` con `Val`: `12abc` non e' un numero (vale il valore di default del campo, -1 per quasi tutti, 0 per ammo e suoni), `0x`, `$`, `#` sono accettati.
* Un campo di flag con nomi che non conosce non cambia il campo; i flag dal 28 al 31 di BITS non sono flag ma bit extra.

## Difetti del vecchio codice **non** conservati (nella libreria)

* `Sound <nome inesistente>`: il vecchio parser andava in access violation (`S_sfx[-1]`): la libreria produce il blocco con `Reference.Name`; l'applicazione deve controllare `S_GetSoundNumForName`.

## Rischi

* I golden vengono dal motore compilato oggi: se il motore cambia (nuovi campi, nuovi flag) vanno rifatti con l'harness; le tabelle `TDehacked<Gioco>Data` sono generate da `deh_main.pas` di ciascun gioco (script usato: estrae le `X_tokens.Add('...')`) e vanno tenute allineate finche' esistono anche le vecchie liste.
* Non c'e' un golden per le armi di Heretic (livelli), Hexen (classi) e Strife: coperte solo da prove scritte a mano sul codice vecchio (`TestWeaponDiHereticHaIlLivello`, `TestWeaponDiHexenHaLaClasse`).
* Le `Reference.Number` di Thing/Frame/Weapon sono come nel file (le cose partono da 1): l'applicazione deve fare il `dec` come prima.
* `ILog` e' quello del motore: gli avvisi arrivano con il prefisso `I_Warning: ` e `printf`, come prima.
