# Dati di prova di Libs\Definitions

I file `*.cases.txt` e `terrain.names.txt` sono scritti a mano (issue #71): comprendono commenti, righe vuote, parole mancanti o sbagliate, numeri non validi, nomi lunghi, fine del testo a metà riga, i limiti di 128 animazioni e 512 frame.

I file `*.golden.txt` sono l'effetto del **vecchio** codice, copiato alla lettera in un harness temporaneo (non e' nel repository) e fatto girare su ogni caso:

| Golden | Vecchio codice | Cosa contiene |
|---|---|---|
| `animdefs.golden.txt` | `P_InitFTAnims` di `Base\p_animdefs.pas` | per ogni caso: avvisi (`W`), errore (`E`), animazioni (`A`), frame (`F indice tics-impacchettati`), liste dei flat e delle texture animate (`LF`, `LT`) |
| `switches.doom.golden.txt`, `switches.strife.golden.txt` | `P_InitSwitchList` di `Doom\p_switch.pas` e `Strife\p_switch.pas` | avvisi, voci lette dal lump o dalla tabella fissa (`R nome1\|nome2\|episodio\|suono`), coppie scelte (`S tex1 tex2 nome1 nome2`) |
| `terrain.<gioco>.golden.txt` | `P_TerrainTypeForName` di `<Gioco>\p_terrain.pas` | `nome<TAB>numero` con i numeri FLOOR_* di quel gioco |
| `switchtables.<gioco>.golden.txt` | le tabelle di `<Gioco>\p_switch.pas` | `nome1\|nome2\|episodio\|costante-del-suono`, **generato da uno script dai sorgenti** (regex sulle righe `(name1: ...)`), non dall'harness: Heretic e Hexen non hanno altro modo di essere confrontate |

Come sono stati fatti i primi tre (l'harness e' temporaneo):

1. un programma `DefHarness.dpr` compilato con `dcc32` che usa le unit vere `Libs\Scanner` e `Libs\Logging` (l'ex `TScriptEngine` di `Base\sc_engine.pas` e' una facciata sopra `TScriptScanner`: l'harness ne ha una copia identica), con il corpo di `P_InitFTAnims`, della parte di lettura/scelta di `P_InitSwitchList` (Doom e Strife) e di `P_TerrainTypeForName` **copiato alla lettera**, e al posto del motore dei finti: `W_CheckNumForName`, `R_FlatNumForName`, `R_CheckTextureNumForName`, `R_TextureNumForName` (il numero di un nome e' la sua posizione in una lista, senza distinguere le maiuscole), `I_Warning` e `I_Error` (che solleva un'eccezione);
2. le tabelle fisse (`fixedalphSwitchList` di Doom e Strife, `terraintypedefs` dei quattro giochi) sono estratte dai sorgenti con uno script e incluse tali e quali (nei terreni le costanti `FLOOR_*` hanno un prefisso per gioco, con i valori di `Base\p_local.pas` e dei `p_terrain.pas`);
3. prima di ogni caso di ANIMDEFS le tabelle `AnimDefs` e `FrameDefs` sono azzerate (un processo nuovo: nel motore partono azzerate, e uno slot ancora mai usato e' un flat);
4. gli avvisi sono quelli passati a `ILog.Warning`, con `\r` e `\n` scritti per esteso e i caratteri fuori da 32..126 come `\xNNNN`.

**Formato dei casi.**

- `animdefs.cases.txt`: `@flats` e `@textures` danno i nomi che esistono (il numero e' la posizione, da 0); `@@@ nome` apre un caso; il testo segue riga per riga (`@crlf` le chiude con CR LF); `@gen N F` aggiunge N animazioni di flat con F frame.
- `switches.cases.txt`: `@textures` (o `@textures @fixed`: tutti i nomi della tabella fissa del gioco), `@missing` toglie dei nomi, `@episode N` e' l'episodio massimo (3 per Doom, 2 per Strife), `@nolump` usa la tabella fissa invece del lump, `entry nome1 nome2 episodio [suono]` scrive una voce del lump (20 byte per Doom, 24 per Strife con il suono; `-` e' il nome vuoto; i nomi sono scritti in 9 byte), `hex ..` scrive byte grezzi. Con la stessa riga `hex` il lump di Strife risulta sfasato: e' voluto, il vecchio codice dava un esito deterministico anche su quello.

**Non confrontato con l'harness**: le tabelle degli interruttori di Heretic e Hexen (dello script, vedi sopra: la loro scelta e' nel motore); i nomi dei suoni (sono costanti del motore). Test di `Tests\Source\DelphiDoom.Tests.Definitions.Parity.pas`.
