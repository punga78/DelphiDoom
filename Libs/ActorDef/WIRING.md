# Libs\ActorDef - come collegarla al motore (issue #67, parte della #45)

La libreria legge il testo di ACTORDEF e DECORATE (e SNDINFO) e ne fa un modello neutro
(`TActorDefActor`, `TActorDefWeapon`, `TActorDefThinker`, `TActorDefState`) che dà, appena ogni cosa
finisce, a dei sink. Non conosce il motore: dipende solo da `Libs\Logging` e `Libs\Scanner`.
Il collegamento non è stato fatto (non era compito di questo lavoro): qui sotto c'è cosa serve.

## 1. Unit da aggiungere ai `.dpr`

Servono in tutti i progetti che oggi compilano `sc_actordef`: `Doom32`, `GLDoom32`, `Heretic32`,
`GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32`, `ddc_doom`, `ddc_heretic`, `ddc_hexen`,
`ddc_strife`. `DelphiDoom.Logging.*` e `DelphiDoom.Scanner.Strings/Scanner/Text` ci sono già. Righe:

```
  DelphiDoom.ActorDef.Types in 'Libs\ActorDef\DelphiDoom.ActorDef.Types.pas',
  DelphiDoom.ActorDef.Intf in 'Libs\ActorDef\DelphiDoom.ActorDef.Intf.pas',
  DelphiDoom.ActorDef.Profiles in 'Libs\ActorDef\DelphiDoom.ActorDef.Profiles.pas',
  DelphiDoom.ActorDef.Text in 'Libs\ActorDef\DelphiDoom.ActorDef.Text.pas',
  DelphiDoom.ActorDef.LabelMatcher in 'Libs\ActorDef\DelphiDoom.ActorDef.LabelMatcher.pas',
  DelphiDoom.ActorDef.StateOwner in 'Libs\ActorDef\DelphiDoom.ActorDef.StateOwner.pas',
  DelphiDoom.ActorDef.ActorStateOwner in 'Libs\ActorDef\DelphiDoom.ActorDef.ActorStateOwner.pas',
  DelphiDoom.ActorDef.WeaponStateOwner in 'Libs\ActorDef\DelphiDoom.ActorDef.WeaponStateOwner.pas',
  DelphiDoom.ActorDef.FlagEditor in 'Libs\ActorDef\DelphiDoom.ActorDef.FlagEditor.pas',
  DelphiDoom.ActorDef.FlagReader in 'Libs\ActorDef\DelphiDoom.ActorDef.FlagReader.pas',
  DelphiDoom.ActorDef.StateReader in 'Libs\ActorDef\DelphiDoom.ActorDef.StateReader.pas',
  DelphiDoom.ActorDef.ActorReader in 'Libs\ActorDef\DelphiDoom.ActorDef.ActorReader.pas',
  DelphiDoom.ActorDef.WeaponReader in 'Libs\ActorDef\DelphiDoom.ActorDef.WeaponReader.pas',
  DelphiDoom.ActorDef.DocumentReader in 'Libs\ActorDef\DelphiDoom.ActorDef.DocumentReader.pas',
  DelphiDoom.ActorDef.Parser in 'Libs\ActorDef\DelphiDoom.ActorDef.Parser.pas',
  DelphiDoom.ActorDef.GotoResolver in 'Libs\ActorDef\DelphiDoom.ActorDef.GotoResolver.pas',
  DelphiDoom.ActorDef.SoundAliases in 'Libs\ActorDef\DelphiDoom.ActorDef.SoundAliases.pas',
  DelphiDoom.ActorDef.SoundInfoParser in 'Libs\ActorDef\DelphiDoom.ActorDef.SoundInfoParser.pas',
  DelphiDoom.ActorDef.DehWriter in 'Libs\ActorDef\DelphiDoom.ActorDef.DehWriter.pas',
  DelphiDoom.ActorDef.DehSink in 'Libs\ActorDef\DelphiDoom.ActorDef.DehSink.pas',
  DelphiDoom.ActorDef.Factory in 'Libs\ActorDef\DelphiDoom.ActorDef.Factory.pas',
```

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`:
` Tests\DelphiDoom.Tests.ActorDef`

## 2. Cosa sostituisce cosa in `Base\sc_actordef.pas`

| Funzione storica | Sostituita da |
|---|---|
| `SC_ParseActordefLump(text)` | `IActorDefParser.Parse(text)`; il `SC_Preprocess(text, false)` di prima lo fa l'adattatore `IActorDefTextPreprocessor` (`Process` = `SC_Preprocess(text, false)`). Il testo deve avere i fine riga CR LF (come lo dà il preprocessore): con solo LF `GetStringEOLUnchanged` mangia la riga dopo, come nel vecchio |
| `SC_DoParseActordefLump` (3000 righe, `TActordefScriptEngine`, tutte le `Match*`, `RemoveFlag`, `ParseState`, `ResolveGoto`, `SubmitParsedData`, `SubmitWeaponParsedData`, `DoParseActorAlias`, `DoParseInlineScript`, `DoDEHParse*`) | `TActorDefDocumentReader` (+ `ActorReader`, `WeaponReader`, `StateReader`, `FlagReader`, `FlagEditor`, `GotoResolver`, `DehWriter`); si cancella |
| `SC_ParseActordefLumps` | resta nel motore (raccoglie i lump `ACTORDEF`/`DECORATE` con `W_*` e `PAK_StringIterator`, ha `SUC_*`): cambia solo la chiamata per ogni testo, che va al parser |
| `SC_ParseSndInfoLumps` | il motore raccoglie i testi come prima (testo dei lump, poi quelli dei PAK già preprocessati, separati da CR LF) e chiama `TActorDefFactory.ParseSoundInfo(profilo, testo, tabella, ascoltatore)` |
| `SC_SoundAlias(snd)` | `IActorDefSoundResolver.Resolve(snd)`; `SC_SoundAlias` resta come facciata per `sounds.pas` |
| `fixsndaliasstr` | `TActorDefSoundAliases.Normalize` (class function) |
| `soundaliases: TDStringList` (creata in `SC_Init`) | `IActorDefSoundAliasTable` creata da `TActorDefFactory.CreateSoundAliases(log)` |
| `SC_GetActordefDeclaration`, `SC_GetWeapondefDeclaration` | fuori compito: restano |
| `SC_Init`, `SC_ShutDown` | restano (comandi di console, costanti, valutatore); cambia solo la creazione di `soundaliases` |
| `decorate_as_actordef` | resta (variabile del `.ini`) |

`SC_SubmitThinker` (`sc_thinker.pas`) resta com'è: `IActorDefThinkerSink.SubmitThinker` lo chiama con i campi del
`TActorDefThinker`, e lui riscrive il thinker come testo e chiama `SC_ParseActordefLump`, cioè di nuovo
`Parse`: il parser non tiene stato tra due chiamate (ogni `Parse` ha il suo lettore), quindi la rientranza va bene
(prova: `TestAThinkerCanBeParsedWhileAnotherTextIsBeingParsed`).

## 3. Il composition root

Va creato in `ComposeEngine` (o in una `TEngineActorDefServices` come `TEngineWadServices`), dopo `I_ConfigureLog`:

```
profile := TActorDefProfiles.ForGame(<DOOM|HERETIC|HEXEN|STRIFE>);          // il gioco di _GAME
aliases := TActorDefFactory.CreateSoundAliases(log);                        // IActorDefSoundAliasTable
catalog := TEngineActorDefCatalog.Create;                                   // da scrivere, vedi sotto
sink    := TActorDefFactory.CreateDehSink(profile, catalog, catalog, aliases,
             TEngineDehConsumer.Create, log);                               // DEH_ParseText
parser  := TActorDefFactory.CreateParser(profile, log, catalog, catalog, catalog, sink,
             TEngineThinkerSink.Create, TEngineScriptSink.Create,
             TEngineActorDefPreprocessor.Create);
```

Classi del motore da scrivere (una per unit, `Base\DelphiDoom.Engine.ActorDef.*.pas`):

* `TEngineActorDefCatalog` implementa 4 interfacce:
  * `IActorDefFlagCatalog.Flags(c)`: `mobj_flags`, `mobj_flags2` (solo Heretic e Hexen), `mobj_flags_ex`,
    `mobj_flags2_ex` ... `mobj_flags6_ex` e `weapon_flags_mbf21` (categoria `Weapon`), come array di stringhe;
  * `IActorDefNameCatalog`: `DEH_WeaponType`, `DEH_AmmoType`, `DEH_PlayerClass` (Hexen), per il render style
    `renderstyle_tokens[Ord(R_GetRenderstyleForName(nome))]`, per il genere `GENDERINFO[Ord(R_GetGenderForName(nome))].name`;
  * `IActorDefActorCatalog`: `Find` = `Info_GetMobjNumForName` più la copia di `mobjinfo[idx]` in un `TActorDefActor`
    (è il blocco `if idx >= 0 then begin pinf := ...` di `SC_DoParseActordefLump`: le flag come testo con prefisso `MF_`,
    gli stati come `ACTORDEF_ORIGINAL_STATE_MARKER + stato`, i suoni con `itoa`, `dropitem`/`missiletype` con `itoa`,
    `renderstyle` e `gender` con `itoa(Ord(...))`, i float divisi per `FRACUNIT`); in più `Name` = `mobjinfo[idx].name` e
    `DoomedNum`. Il parser usa solo i campi che il vecchio blocco copiava (l'elenco è in `TActorDefActorReader.CopyFromBase`);
    `NameOf` = `Info_GetMobjName`; `AddAlias` = `Info_AddMobjNameAlias`;
  * `IActorDefStateCatalog` sopra `statenames` (`IndexOfToken`, `Add`).
* `TEngineDehConsumer`: `ParseText` = `DEH_ParseText`.
* `TEngineThinkerSink`: converte in `rtl_thinker_t` e chiama `SC_SubmitThinker` (i nomi e gli script sono già di 255 caratteri al massimo).
* `TEngineScriptSink`: `AddSourceScript` = `PS_AddSourceScript`; `AddExternalScript` = `PS_AddSourceScript(nome, PAK_ReadFileAsString(file), tipo)`;
  `AddCompiledScript` = `PS_AddCompiledScript`; `ParseDehFile` = `DEH_ParseText(PAK_ReadFileAsString(file))`;
  `ParseAllDehFiles` = `DEH_ParseText(PAK_ReadAllFilesAsString(file))`; il tipo `Global`/`Normal` è `pst_global`/`pst_normal`.
* `TEngineActorDefPreprocessor`: `Process` = `SC_Preprocess(text, false)`.
* Solo Hexen, `IActorDefSoundInfoListener`: `SongForMap(id, nome)`: `if id < nummusic then S_music[id].name := nome`;
  `AliasDeclared(nome, valore)`: `for j := 1 to Ord(DO_NUMSFX) - 1 do if strupper(S_sfx[j].tagname) = nome then S_sfx[j].name := valore`.

L'ordine delle chiamate conta: il sink applica ogni attore subito (`DEH_ParseText`), perché l'attore dopo può ereditare da
quello (e da `statenames`). Per questo il parser non produce una lista ma chiama i sink man mano.

## 4. Cosa si può cancellare dopo il collegamento

* In `sc_actordef.pas`: `TActordefScriptEngine`, le `MatchFlag*`, `SC_DoParseActordefLump`, `SC_ParseActordefLump`,
  `SC_DoRetrieveSndInfo`/`SC_RetrieveSndInfo`, il corpo di `SC_ParseSndInfoLumps` (resta la raccolta dei testi),
  `SC_SoundAlias`, `fixsndaliasstr`, `MAXSTATES`, `ORIGINALSTATEMARKER`.
* `Base\rtl_types.pas`: `rtl_mobjinfo_t`, `rtl_weaponinfo_t`, `rtl_state_t` e le costanti `RTL_ST_*`/`RTL_WT_*` (le usa solo `sc_actordef`; va tolta anche la
  `uses` di `rtl_types` nei `.dpr`); se non resta altro, l'unit.
* `rtl_thinker_t` di `sc_thinker.pas` si può sostituire con `TActorDefThinker`.
* Nessun `{$IFDEF}` di gioco resta nel parser: stanno nei profili (`TActorDefProfiles`).

## 5. Come sono stati ottenuti i golden

Il vecchio `Base\sc_actordef.pas` non si compila fuori dal motore (scrive in `mobjinfo`, `statenames`, `DEH_ParseText`).
Si è fatto un **harness temporaneo** (fuori dal repository, non committato) che compila il motore intero di ogni gioco
(un `.dpr` generato da `Doom32.dpr`, `Heretic32.dpr`, `Hexen32.dpr`, `Strife32.dpr`, con gli stessi define) ma con una copia
patchata di `sc_actordef.pas` e con un `main` che fa `ComposeEngine`, `Z_Init`, `PAK_InitFileSystem`, `Info_Init(true)`,
`Info_InitStateOwners`, `SC_DefaultStatedefLump`, `DEH_Init` e poi legge un testo. La copia patchata fa solo questo:

1. `DEH_ParseText(res)` scrive il testo nel transcript (`@ DEH-BEGIN ... @ DEH-END`) **e poi lo esegue davvero** (con l'uscita
   del log silenziata: i suoi avvisi sono del motore), così un attore dopo può ereditare da quello definito prima;
2. ogni domanda alle tabelle del motore passa da un involucro che la scrive in `*.engine.txt`: `Info_GetMobjNumForName`
   (con tutto il record dell'attore, ottenuto dal blocco di copia estratto in una procedura), `Info_GetMobjName`,
   `Info_AddMobjNameAlias`, `statenames.IndexOfToken`/`Add`, `DEH_WeaponType`/`AmmoType`/`PlayerClass`, render style e genere;
3. thinker, script e file DEH (`SC_SubmitThinker`, `PS_Add*`, `PAK_Read*`) non si eseguono: si scrive l'evento;
4. `SC_Preprocess` è saltato (il testo dei casi è già pronto, con CR LF).

L'uscita del log del motore (`I_Warning`) passa da un `ILog` di `Libs\Logging` che scrive nel transcript; i test usano lo stesso `TLog`.

I file in `Tests\Data\ActorDef\<Gioco>\`:
`*.in.txt` (il testo, generato da un modello comune con `Imp`/`Golem`/`Centaur`/`Zombie` come base, e armi/munizioni del gioco),
`*.snd.txt` (SNDINFO, opzionale), `*.golden.txt` (il transcript del vecchio parser: avvisi, patch DEH, thinker, script,
alias dei suoni, canzoni di Hexen) e `*.engine.txt` (le risposte delle tabelle, in ordine), `vocab.txt` (le liste di flag del gioco
e `nummusic` per Hexen). `TReplayEngine` risponde alla libreria con le **stesse risposte nello stesso ordine** e dà errore
se la libreria chiede altro o meno: quindi il confronto riguarda anche le domande, non solo il testo. 60 testi comuni per i 4 giochi più 1 solo per Doom
(`too_many_states`), più 58-60 mutanti per gioco (`fuzz_*`: righe e parole tolte, ripetute, scambiate, sostituite, testo troncato; seme fisso).
Se si cambia il vecchio comportamento di proposito, si rifà il golden con l'harness.

Affidabilità: alta. I golden sono l'uscita reale del vecchio codice (compilato con le tabelle vere dei giochi), non una trascrizione.
Limiti: la verifica vale per i testi del corpus e per ~600 mutanti provati (solo 58-60 per gioco restano nel repository, i
rimanenti uguali); il vecchio codice è indefinito (scrive fuori dall'array) su alcuni mutanti e quelli sono stati scartati.

## 6. Differenze volute (difetti del vecchio codice che non si copiano)

* Gli stati di una definizione partono puliti. Il vecchio `m_states` non si azzerava per un WEAPON e non si azzerava `has_goto`/`gotostr_*`
  nelle caselle riusate: un'arma dopo un attore ereditava i goto non risolti dell'attore.
* Un ACTOR o un WEAPON il cui testo finisce nell'intestazione non prende gli stati dell'attore prima (il vecchio `numstates` non era azzerato:
  scriveva stati con sprite vuoto). Test: `TestAnActorCutInItsHeadHasNoStatesOfTheActorBefore`.
* `Loop`, `Goto` (e la chiusura di un attore senza `Stop`) prima di qualsiasi stato: il vecchio scriveva in `m_states[-1]` (memoria corrotta, spesso
  un blocco del programma); la libreria li ignora.
* SNDINFO di Hexen, `$MAP 0 nome`: il vecchio usava il numero di mappa della riga prima (variabile non inizializzata); la libreria non fa nulla.
* Le tracce `devparm` (il testo dei lump e delle patch stampato a video) non ci sono.
* Non si copiano nel modello `infighting_group`, `projectile_group`, `splash_group` e `mbf21bits` (il vecchio li copiava dall'attore ereditato e non li usava).

## 7. Difetti del vecchio codice che si conservano (il golden li contiene)

* `-FLAG` toglie una flag solo se nella lista c'è con il prefisso `MF_...` (quelle ereditate): una aggiunta come `+SOLID` resta.
* Dopo `FAST` all'inizio dell'azione si perde l'ultimo carattere (`FAST A_Chase` dà `A_Chas`).
* Le flag delle armi si cercano nella lista delle flag degli attori (un numero uguale a quello delle flag delle armi).
* `FASTSPEED` scrive `normalspeed`; `DEH_WeaponType`/`AmmoType` (motore) aggiungono il prefisso in fondo.
* Dopo un `THINKER` la parola che chiude la lista di opzioni si perde: un secondo `THINKER` attaccato al primo non si legge come tale.
* `Goto ::spawn` non vale, `HEAL` non è un'etichetta raggiungibile con `Altro::Heal`, `a=b` in `ACTORALIAS` dà i nomi `a`, ` `, `b`,
  `nome = valore` in SNDINFO dà il valore `= valore`, i nomi dei thinker e dei loro script sono di 255 caratteri al massimo.
* `GetStringEOLUnchanged` (dello scanner) mangia la riga dopo con un testo con solo LF.

## 8. Rischi

* `TEngineActorDefCatalog.Find` deve dare gli stessi valori che il vecchio blocco di copia (il test non può controllarlo: il motore
  vero non c'è nei test); la prova è avviare un gioco con attori ereditati e confrontare `PrintActordef` prima e dopo.
* Il profilo è un record di booleani, non una strategia con codice: se un gioco nuovo ha altre differenze si aggiunge un campo.
* `TReplayEngine` fallisce se la libreria fa una domanda in più: un cambiamento che aggiunge una `Find` o una `IndexOfToken` rompe i test
  anche se il risultato è giusto (voluto: le domande al motore sono parte del comportamento).
* La libreria non usa Win64-incompatibili (`Integer` per puntatori, `asm`, `.obj`); il test di Win64 non è stato fatto perché oggi il progetto è solo Win32.
