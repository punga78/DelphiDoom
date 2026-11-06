# Dati di prova di Libs\Console

Issue #76. I file `*.golden.txt` sono l'effetto del **vecchio** codice (`Base\c_cmds.pas`, `Base\m_cheat.pas`,
`Cmd_Set`/`Cmd_Get`/`Cmd_TypeOf` di `Base\m_misc.pas`, `C_ExecCommandFile`/`C_ExecCommands` di `Base\c_con.pas`)
su un corpus di righe. `Tests\Source\DelphiDoom.Tests.Console.Golden.pas` fa girare la libreria sullo stesso
corpus e confronta riga per riga.

| File | Contenuto |
|---|---|
| `commands.txt` | una riga = un input di `C_ExecuteCmd`. `@net 0\|1` cambia la partita (singola / in rete), `@text ...` prova `C_ExecCommands`; `\t \s \r \n \\` sono escape (`\s` serve per gli spazi in coda, che gli editor tolgono) |
| `commands.golden.txt` | per ogni riga: il testo scritto (con `printf` e `I_Warning`, nell'ordine, `[warn]` davanti agli avvisi; `\n` = CR LF), il risultato (`=> True/False`) e, se cambia, lo stato delle variabili |
| `scripts\*.con` | file per `exec`: righe, commenti, file che ne chiama un altro, ricorsione diretta e indiretta, vuoto, CR LF. Nel golden il percorso della cartella e' `<DIR>` |
| `cheats.txt` | sequenze di `st_stuff.pas` (byte rimescolati) e righe `feed` / `more` con i tasti battuti (`\xNN` per un tasto qualunque) |
| `cheats.golden.txt` | per ogni tasto: il byte, `U` (sconosciuto), `P` (in corso) o `A` (completo, con tra `[]` i byte rimasti in `cht.p`, cioe' il parametro) |

Variabili e comandi registrati sono gli stessi nell'harness e nel test: variabili `fraglimit` (intero, solo
partita singola), `skill` (intero, sempre), `showfps` (booleano, sempre), `autorun` (booleano, solo rete),
`playername` (testo, sempre), `version` e `screenwidth` (sola lettura); comandi `echo, say`, `dir, ls`,
`multi1 , multi2,multi3`, `'  spaced  '`, `''`, `a,,b`, `,lead`, `trail,`, `MixedCase` (stampano `nome<p1|p2>`),
piu' `get`, `set`, `typeof`, `cmdlist, list, listcmds`, `exec, execcommandfile`, `printf, write, writeln`.

## Come sono stati fatti (l'harness non e' nel repository, e' temporaneo)

1. `ConsoleHarness.dpr` (fuori dal repository) compila con `dcc32` le unit **originali** `Common\d_delphi.pas`,
   `Base\c_cmds.pas` e `Base\m_cheat.pas`; `i_system` e' un finto con `I_Error` (eccezione) e `I_Warning`
   (scrive con `printf`, cosi' l'ordine con il resto del testo e' quello vero); `outproc` raccoglie il testo;
2. `Cmd_Set`, `Cmd_Get`, `Cmd_TypeOf` (`m_misc`), `C_ExecCommandFile` e `C_ExecCommands` (`c_con`) sono copiate
   **identiche** nell'harness (le due unit originali tirano dentro tutto il motore), con una tabella `defaults`
   di sette voci al posto di quella del gioco;
3. `commands.txt` e `cheats.txt` sono letti dall'harness, che scrive i `*.golden.txt`. Le sequenze dei cheat passano
   da `get_cheatseq_string` e `cht_CheckCheat` originali; il parametro e' letto direttamente da `cht.p`.

## Differenze volute dal vecchio codice

- **Limite di 300 comandi** (`MAXCMDS`, poi `I_Error`): tolto. I nomi non sono piu' `string[255]`.
- **Un nome registrato due volte**: il vecchio array teneva entrambe le voci e la ricerca binaria ne trovava una
  qualunque (dopo un quicksort non stabile); ora vince l'ultima e il nome e' contato una volta (nell'elenco e nel totale).
- **Un comando senza gestore** (`nil`): il vecchio `C_AddCmd` lo accettava e `C_ExecuteCmd` cadeva in un access violation;
  ora e' `EConsoleException`.
- **`list` senza maschera**: ordine di registrazione se nessuno aveva ancora cercato un comando, ordinato dopo; ora e' sempre ordinato.
- **Coda dei comandi** (`C_AddCommand`): un comando chiesto durante l'esecuzione degli altri non andava perso solo per caso
  (il vecchio ciclo faceva `Clear` alla fine); ora resta in coda per la chiamata successiva.
- **Tasto oltre 255** in `cht_CheckCheat`: il vecchio leggeva `cheat_xlate_table[Ord(key)]` fuori dai limiti; ora e' letto
  come `$FF` (non fa mai parte di un cheat). Non e' nel golden perche' e' comportamento indefinito nel vecchio.
- **`get_cheatseq_string` senza il segno di fine `$FF`**: il vecchio leggeva fuori dall'array; ora `EConsoleException`.
- **Parametro del cheat**: `Param` da' un carattere per byte con lo stesso codice; il vecchio `string(cht.p)` passava dalla
  tabella dei caratteri del sistema (uguale fino a `$7F`, diversa sopra: `$80` diventava `€`). Chi lo usa legge cifre.
- **Completamento con TAB**: nel vecchio non esisteva (`c_con.pas` non gestisce TAB); `TConsoleCompleter` e
  `TConsoleInputLine.Complete` sono nuovi, hanno solo test unitari.

## Difetti del vecchio conservati (sono nel golden)

- `splitstring_ch` taglia al primo spazio: con uno spazio **davanti** alla riga il nome e' vuoto e la riga finisce
  nel ramo `get`/`set` (`"  echo   a"` non esegue `echo`); senza spazi il nome non e' ripulito (`"echo\tx"` e' un nome sconosciuto).
- Il comando che non esiste con un nome solo e' `get nome`, con un valore e' `set nome valore`, e il nome arriva a
  `get`/`set` **in maiuscolo** (`fraglimit` scrive `FRAGLIMIT=0`, `version 2` avvisa `... readonly variable: VERSION`).
- `get nome*` e `set nome*` senza corrispondenze non dicono niente (niente "Unknown ...").
- `typeof` senza nome scrive l'uso **e anche** `Unknown variable: `.
- Un numero non valido in `set` scrive 0 (`atoi`): `1.5`, `0xZZ`, `99999999999`, `2147483648` danno 0; `0x10`, `-0x10`, `#12`, `$ff` sono validi.
- Il filtro dei nomi con `*` (`C_GetMachingList`): ogni pezzo e' cercato dall'inizio del nome (`a*a` non trova mai niente,
  `e*o` trova `execcommandfile`) e la fine del nome non e' controllata.
- Un tasto sbagliato di un cheat azzera l'avanzamento senza riprovare lo stesso tasto come primo (`iiddqd` non funziona).
- Dopo l'ultimo tasto di un cheat con parametro, i byte del parametro restano in `cht.p` (e `Param`) fino al tasto seguente.
- `exec` nel corpus: la ricorsione e' rifiutata con un avviso, il file chiamato per ultimo continua a girare.
