# RUN — issue #83 (Libs\Midi): cosa eseguire

Codice scritto **senza compilatore**: niente è stato compilato né eseguito. Ordine consigliato.

## 1. Compilare i test e la libreria (da questo worktree)

```
Tools\build.bat Tests\DelphiDoom.Tests.Midi
```
Il `.dproj` ha il percorso di DUnitX come gli altri (`..\..\Skema\...`): da un worktree serve `DCC_UnitSearchPath` con la cartella di DUnitX.
Leggere `logs\DelphiDoom.Tests.Midi.log` (righe `error`). Atteso: 0 errori.
Eseguire `bin\Tests\DelphiDoom.Tests.Midi.exe`: **senza** `Tests\Data\Midi\stream.golden.txt` i tre test di parità passano con `Assert.Pass`; gli altri (circa 50: lettore m2m con le opzioni, loader, sequencer, volume, feeder) devono essere verdi. Se un test del sequencer fallisce, è l'aritmetica a mano dei valori attesi (tempo 500000 = `$0107A120` con il flag, 85 eventi per blocco da 1024 byte, blocco da 11 tick a 96 ppq e 500000 us) o un errore del codice: leggere il caso.

Anche `Tools\build.bat Tests\DelphiDoom.Tests.M2m` (il lettore ha il parametro nuovo `AOptions`, il comportamento senza opzioni non deve cambiare: 0 differenze, stessi test verdi).

## 2. Golden dal VECCHIO codice

```
Tools\Verifica\83\Build.bat
bin\Tools\Verifica\DumpOldMidi.exe Tests\Data\Midi\stream.golden.txt <cartella bin con Doom, Heretic, Hexen, Strife> bin\Tools\Verifica\midi83
```
Il secondo argomento (la `bin\` del repository principale, dove stanno i WAD) e il terzo (dove scrivere i `.bin` dei blocchi, uno per canzone e protocollo) sono facoltativi. Log di compilazione: `logs\DumpOldMidi.log`.
Il programma contiene il testo del vecchio `TMidi` (`OldMidiNew.pas`, fatto da `old_i_midi_new.txt` = `Base\i_midi_new.pas` del commit precedente con fuori solo il dispositivo) e la logica MUS del vecchio `TMusMusicBackend`. **Rimandare a me** `Tests\Data\Midi\stream.golden.txt` e il log.
Righe per ogni canzone: `<nome>/looped`, `/tempo`, `/once` (protocolli di `TMidiProtocol`), `<nome>/legacy-tempo` (informativa: i byte che il vecchio dava davvero col puntatore sbagliato; i test non la leggono), e per i WAD anche `wad:<file>:<lump>#n/mus`.

Cosa deve risultare: `looped` e `once` **identici byte per byte** al nuovo (impronta `fnv`); `tempo` identica al nuovo (il vecchio con il puntatore corretto); `legacy-tempo` diversa da `tempo` (se uguale il difetto del puntatore non c'è, e la nota in `CLAUDE.md` va tolta). Righe `ERROR` per `bad_header` e `no_end_of_track` (nuovo: `Load` dà false). Nella riga `short_loop/looped` e simili si vede il delta che avvolge dopo il giro (`$FFFFFFxx` nel primo evento del blocco dopo la fine): è il difetto conservato.

## 3. Rieseguire i test con i golden

Con `Tests\Data\Midi\stream.golden.txt` presente (e i WAD in `..\..\bin\<Gioco>` relativi al `.exe`, o copiati/collegati nel worktree) rieseguire `DelphiDoom.Tests.Midi.exe`: i tre test `...Parity` devono dare 0 differenze (il messaggio mostra `expected`/`got`). Mandarmi gli esiti.

## 4. Build dei giochi

`Tools\build.bat all` (12 `.dpr` hanno le 8 unit nuove; `Composition` chiama `I_ConfigureMidiStream`). Poi i quattro giochi fino al livello senza `I_Error` né `crash.txt`.

## 5. Ascolto (una persona)

Musica nei quattro giochi con `snd_uselegacymidiplayer` 0 (player interno: **usa la libreria**), 1 (MCI, invariato) e 2 (MIDI convertito in MUS: lo stream MUS usa `TMidiVolume` e `TMidiEventFeeder`), con pausa e ripresa e cambio di volume dal menu; Hexen ha i brani in MIDI. I punti «non provati» della #59 (file MIDI con MCI, XMI, pausa/ripresa) restano da provare.
Con `snd_uselegacymidiplayer = 0` verificare in particolare: il brano parte, ricomincia alla fine (il vecchio player internamente non azzerava il tempo al giro: se non ricominciava già prima, resta uguale), il volume del menu cambia, `-nomusic`.

## Il difetto del giro del brano (`MIDI_LEGACY_LOOP`)

Il vecchio `TMidi` non azzerava il tempo del brano quando questo ricominciava (fine del giro, o `Rewind`): il primo evento dopo il giro aveva come ritardo «il suo tempo meno il tempo della fine», che avvolge a `$FFFFFFxx` tick. All'ascolto: il brano è giusto la prima volta e al secondo giro parte con un ritardo enorme (silenzio) o con eventi fuori tempo; si vede nel golden come primo evento di un blocco dopo la fine con delta `$FFFFFFxx` (righe `looped`/`tempo` dei brani brevi, es. `short_loop`).

Il difetto è sotto **`MIDI_LEGACY_LOOP`**, definito in `Libs\Midi\DelphiDoom.Midi.inc` (riga `{$DEFINE MIDI_LEGACY_LOOP}`, attiva per ora: parità byte per byte con il vecchio codice e con i golden). **Togliendo la riga il codice è corretto**: il tempo riparte da zero a ogni ricomincio. Da togliere dopo che l'utente ha capito il difetto (previsto lunedì 2026-11-09).

Come provare le due configurazioni:
- **Con il define (default)**: i passi 1-3 sopra. Test dipendenti dal difetto: `DovrebbeConservareIlDeltaCheAvvolgeDopoIlGiro` e i tre di parità con il golden.
- **Senza il define**: commentare/cancellare la riga `{$DEFINE MIDI_LEGACY_LOOP}` nel `.inc` e ricompilare `Tests\DelphiDoom.Tests.Midi` (anche con `Tools\build.bat Tests\DelphiDoom.Tests.Midi`; i `.dcu` vecchi vanno rifatti: `clean` o cancellare `dcu\Tests\Midi`). Il progetto compila anche così. Atteso: i tre test di parità passano con `Assert.Pass` (il golden è del vecchio codice, dopo il giro differisce per costruzione) e al posto del test del delta che avvolge girano `DovrebbeAzzerareIlTempoAlGiro`, `DovrebbeDareIlTempoDelPrimoEventoDopoIlGiro` e `DovrebbeAzzerareIlTempoConIlRewind` (delta zero o pari al tempo del primo evento). Tutti gli altri test sono uguali nelle due configurazioni.

L'altro difetto (evento scritto 192 byte oltre il posto giusto dopo il tempo inserito) **non** è sotto il define: ciò che il vecchio lasciava nei byte in mezzo dipendeva dal contenuto precedente del buffer, che un blocco della libreria non ha. I byte del vecchio sono nelle righe `/legacy-tempo` del golden, solo informative.

## Rischi di compilazione previsti

- `Libs\Midi\DelphiDoom.Midi.StreamSequencer.pas`: aritmetica `Cardinal` (cast espliciti messi dove Delphi promuove a `Int64`); `case ... else` con solo un commento.
- `Base\DelphiDoom.Engine.Midi.StreamPlayer.pas`: `MidiProc` stdcall con `DWORD_PTR`; `midiStreamOpen(@FStream, @FDeviceID, ...)`; `MIDIPROPTIMEDIV` passato come `@LTimeDivision` a `PBYTE` (come faceva il vecchio); uso di `I_DevWarning` con `Args`.
- `Base\i_midi_new.pas`: `FreeAndNil` è quello di `d_delphi` (`var Obj`); `TFile.Read`.
- `Tests\Source\DelphiDoom.Tests.Midi.*`: `Assert.WillRaise` con metodi anonimi, array dinamici concatenati con `+` (`Parity`), tipi `UInt64` letterali (`Scenarios`).
- `Tools\Verifica\83\OldMidiNew.pas`: `Inc(PByte(pmeEvent), ...)` (cast di variabile come lvalue); il vecchio codice usa `Windows`/`MMSystem` senza prefisso ma qui sono qualificati solo nella `uses`.
