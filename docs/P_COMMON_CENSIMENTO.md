# `p_common`: censimento e fette (#185, fase 2d, voce A13 dell'inventario)

Tornata grande "185b", ondata 11, partita da `5adaf6fb9` (2026-11-17). Decisione dell'utente (2026-11-17): `IdTech1\Base\p_common.pas` si affronta **a fette**; questo documento e' la prima parte (censimento) e il resoconto delle fette fatte. Nessun gioco avviato: la parita' e' sul testo vecchio copiato nei test DUnitX e sulle dimensioni delle routine dai `.map` di Release Win32.

## 1. Numeri (corretti rispetto all'inventario)

| Misura | Valore | Nota |
|---|---|---|
| Righe del file | 12.505 | interface `1..2410`, implementation `2411..12505` |
| Intestazioni `procedure`/`function` a colonna 0 | 649 | **315 dichiarazioni** nell'interface (piu' qualche duplicato di commento) **+ 334 implementazioni**: le "649 routine" dell'inventario sono il conteggio delle intestazioni, non delle routine |
| Routine realmente implementate | **334** | 7.707 righe di corpi (dalla riga di intestazione al `end;` a colonna 0); il resto e' commento, intestazioni di separazione, `const` e dichiarazioni |
| Routine con 4..7 righe | 90 | quasi tutte `A_Set*`/`A_UnSet*`/`A_Random*Sound`; fino a 15 righe: 169; oltre 40 righe: 39 |
| Righe `{$IF...}` nel file | **108** (non 99) | 1 nell'interface, 5 nelle clausole `uses`/`const`/`var`, **102 dentro 23 routine** (le altre 311 non hanno nessun `{$IF}` di gioco) |
| Classi | 0 | tutto e' procedura libera; le tabelle `FloatBobOffsets` e le costanti `MF_MBF21_*`, `SIXF_*`, `CMF_*`, `RMVF_*`, `SPF_*`, `FTF_*`, `AMF_*`, `SF_*`, `CSP_*` sono nell'interface |

Le 23 routine con `{$IF}` di gioco, per simbolo: i quattro flag MBF21 (`P_ResolveMBF21Flags` 8 righe di `{$IF}`, `P_SetMBF21Flags`, `P_UnSetMBF21Flags`, `P_CheckMBF21Flags` 18 ciascuna: `DOOM`, `DOOM_OR_HERETIC`, `HERETIC_OR_HEXEN`, `HEXEN`, `STRIFE`), `InitSpawnedItem`, `A_CStaffMissileSlither`, `A_DropItem`, `A_Detonate` (`HEXEN`), `A_ChangeFlag`, `A_CheckFlag`, `P_CheckFlag` (`HERETIC_OR_HEXEN`), `P_RaiseActor` (4 simboli), `A_HealThing` (`DOOM`), `A_SetPushable`, `A_UnSetPushable`, `P_CheckCustomMeleeRange`, `P_CopyFriendliness`, `P_TransferFriendliness`, `P_GetPlayerMeleeRange` (`STRIFE`/`DOOM_OR_STRIFE`), `A_WeaponMeleeAttack`, `A_ConsumeAmmo`, `A_CheckAmmo`, `A_GunFlashTo` (le armi, per gioco).

## 2. Come e' raggiunta una routine (il criterio calda/fredda)

La taglia delle routine non decide nulla: decide **da dove si arriva**.

- **Calda**: ogni `A_*` e' un puntatore a codice nella tabella `states[]` (o nel registro `IdTech1\Actions`) e gira **a ogni ingresso in uno stato di un mobj o di uno psprite**, quindi per mobj e per tic; idem ogni helper `P_*` chiamato da loro o da `p_mobj`, `p_enemy`, `p_map`, `p_user` e dalle unit `*Rules` (`P_CheckStateArgs`/`P_CheckStateParams` sono la prima riga di quasi ogni azione con parametri; `P_TicsFromState`, `P_FloatSpeed`, `P_FaceMobj`, `P_ThrustMobj`, `P_NearestPlayer`, le tre `P_*Immune`, `P_GetPlayerMeleeRange`, `P_RandomSound`, `P_BulletSlope`; `P_SetMBF21Flags`, `P_UnSetMBF21Flags` e `P_CheckMBF21Flags` sono dietro `A_AddFlags`, `A_RemoveFlags` e `A_JumpIfFlagsSet`, che sono azioni di stato). `P_CheckFlag` e' chiamata dall'espressione `CheckFlag` di ACTORDEF in `DelphiDoom.Engine.Scanner.ActorFunctions` (valutata a ogni chiamata di un'azione con espressione) e da `A_CheckFlag`: calda.
- **Fredda** (una volta per livello o per avvio): in tutto il file ce ne sono **due**: `P_ResolveMBF21Flags` (la chiamano i quattro `DelphiDoom.Engine.Dehacked.Applier` una volta per `mobjinfo` con `mbf21bits` diversi da 0, quando si applica la patch) e `P_ConfigureConsole`/`P_Console` (collegamento, gia' iniettato dal composition root).
- `PlayerToId` e' chiamata anche da `p_obituaries` (fredda) ma pure da `p_playertrace` e da due azioni: calda.

## 3. Che cosa copre gia' il registro `IdTech1\Actions`

Il registro (`IActionRegistry`, `TActionRegistry`, `ComposeDehacked`) risolve **nome -> puntatore** e il puntatore -> nome per le azioni, al posto di `deh_actions[]`. **Non contiene i corpi**: le 334 routine restano tutte qui. Le `A_*` sono registrate dai quattro `deh_main.pas` con `DEH_AddAction(@A_Nome, 'A_Nome(parametri)')` (i conteggi "reg4" del censimento: 4 `deh_main` che citano il nome) e dalle tabelle `info`; fanno eccezione tre azioni che un gioco non registra: `A_SetNoDamage`, `A_UnSetNoDamage`, `A_LineEffect` (registrate in 3 giochi su 4; non e' compito di questa tornata decidere se e' voluto). Quindi **nessun gruppo di `p_common` e' gia' coperto dal registro**, salvo la registrazione per nome.

## 4. Gruppi, routine, calda o fredda, `{$IF}`, chiamanti

Le colonne: **Rout.** = routine, **Righe** = righe dei corpi, **IF** = routine con `{$IF}` di gioco, **Reg.** = registrate dai `deh_main`.

| Gruppo | Rout. | Righe | IF | Classe | Chiamanti oltre ai `deh_main`/tabelle | Note |
|---|---:|---:|---:|---|---|---|
| Salti e `GoTo` condizionati (`A_GoTo*`, `A_JumpIf*` su parametro custom, mappa, mondo, bersaglio, `A_Jump`, `A_RandomJump`, `A_RandomGoto`, `A_WeaponJump`) | 79 | 1.529 | 0 | calda | nessuno (solo `deh_main`/`info`) | corpi di 14-36 righe quasi uguali tra loro (confronto `Strings`/`Integer`/`Float` x Map/World x Equal/Less/Greater); tutti con `P_CheckStateParams` |
| Parametri custom, mappa, mondo, variabili utente (`A_Set/Add/Subtract[Target/Master/Tracer]CustomParam`, `A_SetMap*`, `A_SetWorld*`, `A_SetUser*`) | 20 | 256 | 0 | calda | nessuno | |
| Suono (`A_CustomSound*`, `A_Random*Sound`, `A_Playsound`, `A_StopSound`, `P_RandomSound`, `A_WeaponSound`) | 20 | 227 | 0 | calda | `P_RandomSound`: `EnemyRules`, `MobjRules`, `p_extra`, `p_sounds` | |
| MBF21: flag (`P_ResolveMBF21Flags`, `P_Set/UnSet/CheckMBF21Flags`, `A_AddFlags`, `A_RemoveFlags`, `A_JumpIfFlagsSet`) | 6 | 799 | 4 | **`P_ResolveMBF21Flags` fredda**, il resto calda | `P_ResolveMBF21Flags`: i quattro `Dehacked.Applier` | `P_Set/UnSet/CheckMBF21Flags` ripetono tre volte la stessa tabella bit -> flag; **fetta 1** |
| Flag per nome (`A_ChangeFlag`, `A_CheckFlag`, `P_CheckFlag`) | 3 | 367 | 3 | calda | `P_CheckFlag`: `ActorFunctions` | tre copie della stessa ricerca del nome nelle liste `mobj_flags*` |
| Spawn e proiettili (`P_CustomMissile`, `A_CustomMissile`, `A_RandomMissile`, `A_SpawnItem*`, `InitSpawnedItem`, `A_SpawnObject`, `A_MonsterProjectile`, `A_WeaponProjectile`, `A_SeekerMissile`, `A_MissileAttack`...) | 15 | 725 | 2 | calda | `A_SpawnItem`, `A_SpawnItemEx`: `p_map`, `radix_codepointers` | `InitSpawnedItem` 164 righe con `HEXEN` |
| Attacchi (`A_CustomMeleeAttack`, `A_CustomComboAttack`, `A_BasicAttack`, `P_DoAttack`, `A_Monster*Attack`, `A_Weapon*Attack`, `A_Scratch`) | 10 | 376 | 2 | calda | nessuno | |
| Danno, morte, rimozione, guarigione (`A_Damage*`, `A_Kill*`, `A_Remove*`, `A_Raise*`, `A_HealThing`, `P_HealCorpse`, `A_RadiusDamage`, `A_Detonate`, vita) | 35 | 650 | 3 | calda | `A_Detonate`, `A_Stop`...: `info` | `P_RaiseActor` 74 righe con 4 simboli |
| Armi del giocatore (`A_ConsumeAmmo`, `A_CheckAmmo`, `A_RefireTo`, `A_GunFlashTo`, `A_Delayfire`, `P_GetPlayerMeleeRange`...) | 8 | 251 | 4 | calda | `P_GetPlayerMeleeRange`, `A_ConsumeAmmo`: `PspriteRules` | per gioco: hanno gia' la `PspriteRules` accanto |
| Dissolvenza e aspetto (`A_Fade*`, `Do_Fade*`, `A_SetTranslucent`, `A_SetRenderStyle`, `A_*Sprite*`, `A_GlowLight`, `A_Ghost*`, `A_SetScale`...) | 28 | 358 | 0 | calda | `A_FadeOut20`, `A_GhostOff`: `info` | |
| Movimento e orientamento (`A_Thrust*`, `A_Turn*`, `A_Wander`, `A_Weave`, `A_Tracer2`, `A_ChangeVelocity`, `A_MatchTargetZ`, `A_TraceNearestPlayer`, `P_ThrustMobj`, `P_FloatSpeed`, `P_FaceMobj`, `P_RandomChaseDir`...) | 26 | 622 | 0 | calda | `P_ThrustMobj`: 8 unit (`EnemyRules`, `MobjRules`, `PspriteRules`, `SpecRules`, `UserRules`, `p_mobj`, `a_action`, `udmf_spec`); `P_FloatSpeed`: `EnemyRules`, `MobjRules`, `p_enemy`, `p_map`; `P_FaceMobj`: `EnemyRules`, `PspriteRules`, `p_mobj` | usano `FloatBobOffsets` e `finesine` |
| Ricerca di bersagli, vista, allarme (`A_CheckSight*`, `A_CheckRange`, `A_Seek/Find/ClearTracer`, `P_RoughTargetSearch`, `P_CheckFov`, `A_AlertMonsters`, `P_RecursiveSoundEx`, `A_MonsterRefire`, `P_NearestPlayer`, `A_*EarthQuake`, `A_CheckFloor`) | 21 | 591 | 0 | calda | `P_NearestPlayer`: `EnemyRules` | usano blockmap e `P_CheckSight` |
| Puntatori, parametri degli stati, argomenti, tempi (`P_CheckStateParams`, `P_CheckStateArgs`, `A_SetArg*`, `A_CountdownArg`, `A_SetSpecial`, `A_SetTics`, `P_TicsFromState`, `A_RearrangePointers`, `A_TransferPointer`, `A_Set*Mass`, `A_Stop`, `A_SetDropItem*`, `A_DropItem`, `P_ActorTarget`, `A_LineEffect`, `A_ConsoleCommand`, `P_ConfigureConsole`) | 28 | 706 | 1 | calda (salvo `P_ConfigureConsole`/`P_Console`: collegamento) | `P_CheckStateParams`: `p_extra`, `p_simpledialog`, `ps_main`, `psi_overlay`, `radix_codepointers`; `P_CheckStateArgs`: `MissingEvaluator`, `info_common`, `sc_params`; `P_TicsFromState`: `p_mobj`, `p_pspr`; `P_ActorTarget`: `Script.Actors` | `P_CheckState*` hanno anche chiamanti freddi (lettura degli stati) ma la prima riga di quasi ogni azione e' una loro chiamata: calde |
| Amicizia, gruppi MBF21, immunita' (`P_CopyFriendliness`, `P_TransferFriendliness`, `A_Set*Group`, `P_InfightingImmune`, `P_ProjectileImmune`, `P_SplashImmune`, `A_Set/UnSetMonsterInfight`, `PlayerToId`) | 11 | 116 | 2 | calda | `P_InfightingImmune`: `InterRules`; `P_ProjectileImmune`: `MapRules`; `P_SplashImmune`: `p_map`; `PlayerToId`: `p_obituaries`, `p_playertrace` | |
| Bit di stato a 4 righe (`A_SetSolid`, `A_SetFloat`, `A_Set*Bounce`, `A_SetFrightened`, `A_SetNoDamage`, `A_Blocking`, `A_DoRunScripts`, `A_Set*Pushable`, `A_Set*Interactive`, `A_SetPainChance`) | 22 | 101 | 2 (`A_SetPushable`, `A_UnSetPushable`) | calda | nessuno | |
| Mira (`P_DoBulletSlope`, `P_BulletSlope`) | 2 | 33 | 0 | calda | `P_BulletSlope`: `EnemyRules`, `PspriteRules`, `p_aaptr` | |
| **Totale** | **334** | **7.707** | **23** | | | |

Il conteggio per routine con chiamanti, dei quali si e' certi, sta nel testo sopra; le 28 funzioni non `A_*` senza chiamanti fuori da `p_common` (`P_DoBulletSlope`, `P_CustomMissile`, `InitSpawnedItem`, `Do_FadeOut`, `Do_FadeIn`, `P_RandomChaseDir`, `P_SetHealth`, `P_DoDamage`, `P_DoRemoveThing`, `P_TransferFriendliness`, `P_CopyFriendliness`, `P_RaiseActor`, `P_DoAttack`, `P_RecursiveSoundEx`, `P_NoiseAlertEx`, `P_LocalEarthQuake`, `P_CheckCustomMeleeRange`, `P_CheckFov`, `RoughBlockCheck`, `P_RoughTargetSearch`, `PIT_HealCheck`, `P_HealCorpse`, `P_SeekerMissileEx`, `P_SetMBF21Flags`, `P_UnSetMBF21Flags`, `P_CheckMBF21Flags`, `P_SetPspritePtr`, `P_Console`) sono helper delle `A_*` e sono dichiarati nell'interface senza bisogno.

## 5. Perche' le `A_*` non si migrano in questa tornata (il vincolo che decide)

Una `A_*` e' un indirizzo dentro `states[]` e nei registri dei quattro giochi. Per metterla in una classe a **costo zero** ci sono due strade, e nessuna e' "metodo statico nella stessa unit e chiamanti invariati":

- **A. Metodo statico + procedura libera che lo chiama** (la facciata): ogni `A_*` guadagna una chiamata in piu' e cambia dimensione. Con la regola "nessuna routine calda cambia dimensione" e' esclusa.
- **B. Registrare direttamente `@TClasse.Metodo`** (un `class procedure ... static` ha la firma di una procedura semplice e il suo indirizzo e' lo stesso tipo di puntatore): costo zero, ma cambiano **tutti i punti di registrazione**: `DEH_AddAction(@A_Nome, ...)` nei quattro `deh_main.pas` (circa 1.900 chiamate), i riferimenti nelle assegnazioni `states[...].action.acp1 := @A_Nome` di `info.pas`, `radix_codepointers` e ogni chiamata diretta di `A_*` da altre unit. Non e' una "facciata con chiamanti invariati": e' la migrazione di ogni chiamante, **da fare solo con una decisione dell'utente** (e con la prova di un esempio: il tipo `actionf_t` accetta `@TClasse.Metodo`?).

Il costo di B e' per l'80% meccanico (sostituzione per nome nei quattro `deh_main` e nelle tabelle) ma il rischio e' alto e **non si puo' provare senza avviare i giochi** (`-deh`, ACTORDEF, demo del corpus): in questa tornata e' vietato. Quindi **le 311 routine senza `{$IF}` di gioco e le 23 con `{$IF}` non si migrano ora**; il motivo e' scritto qui e in A13.

## 6. Fette fatte

### Fetta 1: `P_ResolveMBF21Flags` in `TMbf21Flags` (fredda, parita' su 3 profili di gioco)

Tag `ondata11-185b-2`. `P_ResolveMBF21Flags` (120 righe, 8 `{$IF}`: la chiamano i quattro `Dehacked.Applier` una volta per tipo di cosa con bit MBF21) traduce i 19 bit di `mbf21bits` nei flag del motore. La logica e' ora `TMbf21Flags.Resolve` (`DelphiDoom.Actions.Mbf21Flags`, `IdTech1\Actions`): una sola procedura con le **maschere del gioco** in un record (`TMbf21Masks`: 0 dove il gioco non ha il flag, e mettere in `or` una maschera 0 non cambia nulla, quindi nessun `{$IF}` nel codice nuovo) e i cinque flag in `TMbf21FlagWords`; non usa `p_mobj_h` ne' `info_h`, quindi il progetto di test non ha bisogno di shim. Le costanti `MF_MBF21_*` (i 19 bit della specifica) sono passate dall'interface di `p_common` alla nuova unit (nessun'altra unit le usava). `P_ResolveMBF21Flags` resta in `p_common` come facciata (stessa firma, stessi chiamanti) con la costante `MBF21_MASKS` per gioco, che tiene i `{$IFDEF}` storici in un punto solo.

- **Dimensioni dai `.map` di Release Win32** (base `5adaf6fb9` costruita a freddo, `Confronta-Dimensioni-Tutte.ps1` su tutte le routine dei quattro giochi software): `P_ResolveMBF21Flags` Doom 380 -> 104 byte, Heretic e Hexen 296 -> 116, Strife 288 -> 116; `TMbf21Flags.Resolve` e' nuova (256 byte, la stessa nei quattro giochi). **Nessun'altra routine cambia dimensione** (una sola riga "diversa" per gioco). Fredda: il limite era +16 byte, il saldo e' in meno (Doom 360, Heretic e Hexen 372, Strife 372 byte in totale).
- **Test**: 9 in `Tests\Source\DelphiDoom.Tests.Actions.Mbf21Flags.pas` (suite Actions da 36 a 45): le 2^19 combinazioni dei bit (con i bit oltre il 19-esimo a caso, che non devono contare) x 2 giri di flag di partenza a caso x 3 profili (Doom, Heretic e Hexen, Strife; Heretic e Hexen sono uguali in questa routine) contro il **vecchio testo copiato** con i `{$IFDEF}` resi parametri; piu' i casi singoli (nessun bit, `LOGRAV` che spegne solo la gravita', il `RIP` in `flags2` o in `flags4_ex`, le maschere assenti) e i valori delle 19 costanti.
- **Non verificato a runtime**: nessuna patch DEHACKED con `MBF21 Bits` applicata in un gioco (vietato avviarli in questa tornata); la parita' e' sul testo e sulle dimensioni. Da provare, a macchina libera, con una patch di prova (`-deh`) che ponga `MBF21 Bits` su un mostro e un confronto dei dump (`DEH_SaveCurrentSettings`) vecchio/nuovo.

## 7. Ordine proposto delle fette (per il seguito)

1. **Fatta**: `P_ResolveMBF21Flags` (unica routine fredda con logica).
2. **Decisione dell'utente su A/B** (par. 5): senza, nessuna `A_*` si sposta. Se B: prima la prova che `@TClasse.Metodo` entra in `actionf_t`/`DEH_AddAction` e i quattro `deh_main` si trasformano con uno strumento (stile `Tools\Verifica\245\Migra-Sessione.ps1`).
3. Dopo B, gruppi **senza `{$IF}` e senza dipendenze dal mondo**, dai piu' semplici: bit di stato a 4 righe (20 routine), dissolvenza e aspetto (28), suono (20), parametri custom (20), salti e `GoTo` (79; poi un solo ciclo condiviso per i confronti Equal/Less/Greater, che e' cambio di dimensione: **fetta di logica**, non meccanica).
4. Poi i gruppi che toccano il mondo senza `{$IF}`: movimento (26), ricerca (21), danno e morte senza `{$IF}`.
5. Per ultimi i gruppi con `{$IF}` (armi, flag, spawn con `HEXEN`, `P_RaiseActor`), con una strategia per gioco nelle unit `DelphiDoom.Engine.World.*` come le `*Rules`; i tre `P_Set/UnSet/CheckMBF21Flags` e le tre ricerche per nome (`P_CheckFlag`, `A_CheckFlag`, `A_ChangeFlag`) si riducono a una tabella condivisa **solo dopo** la misura delle dimensioni e a macchina libera (sono calde).
6. Le costanti dell'interface (`SIXF_*`, `CMF_*`, ...) e `FloatBobOffsets` si spostano con la loro famiglia, non prima: nessun codice da guadagnare, solo `uses` da cambiare in 15 unit.
