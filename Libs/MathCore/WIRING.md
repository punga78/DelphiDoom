# Libs\MathCore - come collegarla al motore (issue #75, parte della #45)

La libreria dà in classi le parti pure e senza stato di `Base\m_fixed.pas`, `tables.pas` (tabelle trigonometriche e
funzioni degli angoli), `m_vectors.pas`, `m_bbox.pas`, `m_rnd.pas`, `m_stack.pas`, `m_hash.pas`, `m_crc32.pas` e `m_sha1.pas`.
Non conosce il motore: dipende solo da `System.*`. La parità con il vecchio codice è provata da 101 test
(`Tests\DelphiDoom.Tests.MathCore`, golden in `Tests\Data\MathCore`, vedi il suo `README.md`).
**Il collegamento non è stato fatto** (non era compito di questo lavoro): qui sotto c'è cosa conviene collegare e cosa no.

## 1. Cosa conviene collegare

| Parte | Collegare? | Perché |
|---|---|---|
| `TGameRandom` (`m_rnd`) | **Sì**, come facciata | lo stato (`rndindex`, `prndindex`, `nrndindex`, `sysrndindex`, `sysrndseed`) esce dai globali; le funzioni `M_Random`/`P_Random`/`N_Random`/`I_Random`/`Sys_Random`/`C_Random`/`P_RandomFromSeed`/`M_ClearRandom`/`P_SaveRandom`/`P_RestoreRandom`/`P_RandomHitscan*` restano l'API del motore (circa 940 chiamate in 58 file) e delegano a un `IGameRandom` |
| `TSha1`, `TCrc32` (`m_sha1`, `m_crc32`) | **Sì** | non sono nei percorsi caldi, il vecchio SHA-1 aveva `asm` (bloccava il 64 bit), la lettura di file/lump resta nel motore |
| `TStringHashTable` (`m_hash`) | **Sì** | la tabella da 64K voci non è più un global di unit; usata da `p_setup`/`r_data`/`s_pk3sounds`/`vx_voxelsprite` |
| `TIntegerStack`, `TIntegerQueue` (`m_stack`) | **Sì, se serve** | i soli usi sono il `stack` di `m_rnd` e `M_PushValue`/`M_PopValue`; con `TGameRandom` il primo sparisce |
| `TBoundingBoxMath` (`m_bbox`) | **Sì, come inline** | sono due funzioni di quattro righe: la facciata storica resta (le caselle sono `Pfixed_tArray` dentro i record del motore) |
| `TVectorMath` (`m_vectors`) | **Sì, con calma** | `p_slopes`, `r_dynlights`, `p_setup` e `p_mobj` (Doom, Heretic, Strife) la usano; non è un percorso critico. Le firme cambiano da puntatori a `const`/`var`: chiamanti da adattare uno a uno |
| Tabelle (`finesine`, `finetangent`, `tantoangle*`, `fixedsine`) | **No, per ora** | vedi sotto |
| `TFixedMath` (`FixedMul`, `FixedDiv`, ...) | **No nei percorsi caldi** | vedi sotto |

## 2. Cosa NON collegare, e perché

### 2.1 Aritmetica a virgola fissa (`FixedMul`, `FixedDiv`, `FixedMulShl*`, `FixedMulDiv*`...)

`FixedMul` e `FixedDiv` sono chiamate decine di migliaia di volte per fotogramma nel renderer, nel movimento e nelle collisioni.
Il motore deve continuare a chiamare **funzioni libere, non metodi virtuali o interfacce**. `TFixedMath` è fatta di
`class function ... static; inline` (nessuna chiamata virtuale) ed è pensata per il **codice nuovo e i test**. Per il motore:

- tenere `m_fixed.pas` com'è finché c'è `asm` solo per ragioni di 32 bit; quando si fa il 64 bit (#41) **sostituire il corpo
  delle funzioni storiche** con le versioni Pascal di `TFixedMath` (stesso testo, `inline`), non i chiamanti: `function FixedMul(const a, b: fixed_t): fixed_t; inline; begin Result := TFixedMath.Mul(a, b); end;`
  (un `inline` di una funzione storica che chiama un `inline` della libreria si espande fino al chiamante, a patto che la unit
  della libreria sia nella `uses` di `m_fixed`);
- le versioni a virgola mobile (`FixedDivEx`, `FixedMulEx`, `FixedSqrt`, `FixedMul64`, `FloatDiv`...) sono poco usate: collegabili senza rischio;
- `FixedDiv2`, `FixedDiv_fast` e `FixedDivLW` ora **sollevano `EMathCoreException`** dove prima c'era l'eccezione del processore (stessa
  condizione: divisore zero o quoziente fuori da 32 bit); nessun chiamante legale cambia;
- prima di sostituire misurare con una demo (`-timedemo`) a 32 bit: un `inline` che non si espande costa una chiamata in più per ogni `FixedMul`.

### 2.2 Tabelle trigonometriche

Le tabelle sono costanti in `DelphiDoom.MathCore.Table*` (`FINE_SINE_TABLE`, ...) e `TTrigonometry` le legge con metodi **senza controllo
dell'indice**. Il motore oggi le legge come `finesine[...]`/`finecosine[...]` (puntatori inizializzati da `R_Init` in `r_main.pas`) in
molti punti caldi (`r_*`, `p_*`, `am_*`): tenere quelle variabili. Se un giorno si vuole una sola copia dei dati, `finesine` può diventare
`@FINE_SINE_TABLE` (stesso contenuto, stessa impronta nei test) senza toccare i chiamanti. Le funzioni degli angoli
(`SlopeDiv`, `SlopeDivEx`, `FixedToAngle`, `AngleToFixed`, `DegToSlope`) sono collegabili come facciate.
`fixedsine`/`fixedcosine` servono alla automappa (`am_textured`).

### 2.3 Cosa non è stato portato

- `m_crc32`: `GetCRC32(file)` e `GetLumpCRC32(lump)` (leggono un file e uno zone memory) restano al motore e usano `TCrc32.Update` sui byte;
  la libreria dà solo il calcolo. Idem per `HextW`/`HextL` (vedi `TCrc32.ToHex`).
- `m_hash`: `M_HashIndex`/`M_HashUpdate` restano come facciate sull'oggetto.
- `m_stack`: `M_PushValue`/`M_PopValue` (una pila globale con `I_DevError`) restano al motore: la libreria ha la classe, non il global.
- `m_rnd`: `I_Random` usa il generatore di Delphi (`Random`) e `Randomize` all'avvio: dietro `IEntropySource`, nel motore basta `TMathCoreFactory.CreateGameRandom`.
- `m_vectors`: nessuna parte esclusa.
- `r_precalc.pas` e le altre tabelle calcolate all'avvio (es. `slopedivs`, `viewangletox`, `xtoviewangle`): **non** sono costanti pure (dipendono da risoluzione e FOV): fuori da questa libreria.

## 3. Come collegare `TGameRandom` (la parte che conviene davvero)

Il composition root (`DelphiDoom.Engine.Composition`) crea `TMathCoreFactory.CreateGameRandom` (o con un `IEntropySource` finto) e lo dà a
`M_ConfigureRandom` (nuova, in `m_rnd.pas`), che lo tiene in una variabile di unit. Poi:

```pascal
function P_Random: integer;
begin
  Result := game_random.NextPlay;   // interfaccia: una chiamata indiretta, costo trascurabile rispetto a una demo
end;
```

Gli indici che oggi si leggono e scrivono direttamente (8 file: `info_rnd`, `p_setup`, `Doom|Heretic|Strife|Hexen\g_game`, `Hexen\g_demo`: savegame, demo e rete) passano alle proprietà `PlayIndex`, `MenuIndex`,
`NonCompatibleIndex`, `SystemIndex`, `SystemSeed`. Controllare che nessun codice dipenda dal fatto che `P_Random` sia una funzione libera
con indirizzo fisso (es. puntatori a funzione).
La serie dei numeri è la stessa del vecchio: **le demo e i savegame esistenti restano compatibili** (provato dai golden su 600 numeri per serie,
20050 per `Sys_Random`, e dal test di save/restore).

## 4. Unit da aggiungere ai `.dpr`

Dipende da cosa si collega. Per il solo random, SHA-1, CRC e hash (tutti i progetti di gioco e i `ddc_*` che oggi hanno `m_rnd`, `m_sha1`, `m_crc32`, `m_hash`):

```
  DelphiDoom.MathCore.Types in 'Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in 'Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableRandom in 'Libs\MathCore\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in 'Libs\MathCore\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in 'Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.TableFineSine in 'Libs\MathCore\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in 'Libs\MathCore\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in 'Libs\MathCore\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in 'Libs\MathCore\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in 'Libs\MathCore\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.FixedMath in 'Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.Trigonometry in 'Libs\MathCore\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.IntegerStack in 'Libs\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.GameRandom in 'Libs\MathCore\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in 'Libs\MathCore\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in 'Libs\MathCore\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in 'Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in 'Libs\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in 'Libs\MathCore\DelphiDoom.MathCore.Factory.pas',
```

(GameRandom usa Trigonometry per gli angoli hitscan e Trigonometry usa FixedMath e le cinque tabelle trigonometriche; per TVectorMath, TBoundingBoxMath e TIntegerQueue aggiungere
DelphiDoom.MathCore.VectorMath, .BoundingBox, .IntegerQueue.) Le unit di tabella sono grandi (la più grande, TableFixedSine, ha 81920 voci, circa 0,3 MB): compilano in meno di un secondo, ma finché
il vecchio 	ables.pas resta nel motore i dati trigonometrici sono due volte nell'eseguibile. Per questo il collegamento del solo random porta con sé le tabelle (via Trigonometry): si può evitare spostando
P_RandomHitscanAngle/Slope nel motore (restano nella facciata di m_rnd, che già usa 	ables) o sostituendo inesine & co. con @FINE_SINE_TABLE.

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`:
` Tests\DelphiDoom.Tests.MathCore`

## 5. Rischi

- **Determinismo a 64 bit**: le funzioni a virgola mobile (`FixedDivEx`, `FixedSqrt`, `FixedMul64`, `FloatDiv`, `FloatMul`, e i vettori) sono identiche bit per bit
  **a 32 bit** (provato); a 64 bit `Extended` vale `Double` e l'arrotondamento può differire all'ultimo bit in rari casi. Per il resto la libreria è in interi.
- **`TVectorMath`**: `Single` con espressioni in `Extended` a 32 bit; a 64 bit (SSE, `Single` puro) i bit possono cambiare. I golden sono a 32 bit.
- I test `TestFixture` leggono `..\..\Tests\Data\MathCore` rispetto a `bin\Tests`.

## 6. Stato dopo la issue #133 (fase 2, ondata 1)

- `m_hash.pas`, `m_bbox.pas` e `m_vectors.pas` sono cancellate: `r_data` riceve l'`IStringHashTable` da `ComposeMathCore` con `R_ConfigureNameHash`, `p_setup` chiama `TBoundingBoxMath`, le costanti delle bbox sono `BOX_TOP`, `BOX_BOTTOM`, `BOX_LEFT`, `BOX_RIGHT` di `DelphiDoom.MathCore.Types` (stessi valori di `BOXTOP`...), e i chiamanti dei vettori usano `TVec2`/`TVec3` con `TVectorMath`.
- Il CRC di un file è `TCrc32.CalculateStream` (dalla posizione dello stream alla fine, letto a pezzi di 64 KB): la libreria continua a non aprire file né lump. Il CRC di un lump lo calcola il motore (`W_LumpCRC32` in `w_wad`, `ND_LumpCRC32` in `nd_main`).
- Restano `m_sha1.pas` e `m_crc32.pas`, ridotte a una funzione ciascuna per `vx_voxelsprite` e `p_udmf`, file di altri lavori della stessa ondata.
- `Tests\DelphiDoom.Tests.MathCore.dproj` in Debug compila con `DCC_Inlining=off`: le funzioni `inline` (virgola fissa, bbox, tabelle) vengono chiamate e la copertura le vede (dall'86% al 98%); in Release i test le provano espanse.
