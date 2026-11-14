# Piano: tutto a classi, anche il percorso caldo

Issue #185. Decisione dell'utente del 2026-11-12: **tutto il codice storico del motore diventa a classi, compreso il percorso caldo** (renderer software e OpenGL, thinker, logica di gioco, salvataggi). Sostituisce la regola "codice storico per scelta" di `CLAUDE.md` e di `docs\PENDING_ISSUES.md`. Restano valide le quattro regole del 2026-11-07: compatibilità byte per byte (salvataggi, demo, rete), copertura almeno al 90% per libreria, prestazioni entro il 5% sui percorsi caldi, ordine dal freddo al caldo.

Questo documento è il piano. Lo stato delle singole fette va scritto qui man mano; il dettaglio di ogni libreria resta nel suo `Libs\<Nome>\CLAUDE.md`.

## 1. Fotografia (2026-11-12, `master` `142d954e`)

I numeri sono conteggi di righe e ricerche nel testo, non una lettura unit per unit.

### `Base\`

| Famiglia | Unit | Righe | Unit che usano già classi | Natura |
|---|---:|---:|---:|---|
| `r_*` renderer software | 70 | 64.542 | 21 | caldo |
| file `.inc` (cicli del renderer) | 73 | 28.380 | - | caldo |
| `p_*` logica di gioco | 34 | 27.853 | 15 | deterministico |
| `v_*` video | 3 | 6.121 | 2 | tiepido |
| `i_*` sistema | 13 | 5.072 | 8 | freddo |
| `udmf_*` | 9 | 4.766 | 6 | deterministico |
| `m_*` | 8 | 4.726 | 6 | freddo |
| `am_*` automap | 2 | 3.240 | 2 | tiepido |
| `w_*` | 7 | 2.836 | 6 | freddo |
| `hu_*` | 2 | 2.787 | 0 | freddo |
| `s_*` | 2 | 2.485 | 2 | freddo |
| `po_man` | 1 | 1.925 | 1 | deterministico |
| `sc_*`, `info_*`, `deh_*`, `mt_*`, `d_*`, `z_*`, `c_*`, altre | 30 | 10.403 | 11 | freddo |
| **Totale storico** | **181** | **136.756** (+28.380 di `.inc`) | **80** | |
| `DelphiDoom.Engine.*` (già a classi) | 187 | 27.744 | | |

Le quattro unit più grandi fanno 30.000 righe: `p_common` (12.495), `r_clipper` (7.132), `v_video` (5.739), `r_segs2` (4.790). Unit con assembler: 2 in `r_*`, 1 in `p_*`, 1 in `m_*`.

### Cartelle dei giochi

| Cartella | Unit | Righe | Di cui tabelle `info*` | Logica `p_*` | Menu `m_*` | `g_*` | Salvataggi `sv_*` |
|---|---:|---:|---:|---:|---:|---:|---:|
| `Doom\` | 45 | 81.779 | 25.939 | 27.814 | 7.465 | 3.801 | 348 |
| `Heretic\` | 38 | 77.798 | 29.701 | 23.156 | 7.315 | 3.609 | 349 |
| `Hexen\` | 43 | 128.672 | 71.360 | 26.041 | 7.409 | 3.150 | 3.161 |
| `Strife\` | 45 | 108.653 | 47.931 | 32.975 | 8.067 | 3.480 | 357 |
| **Totale** | **171** | **396.902** | 174.931 | 109.986 | 30.256 | 14.040 | 4.215 |

Quasi metà delle righe sono tabelle di dati (`info`, `sounddata`): non sono logica e non vanno "trasformate", vanno lette da una sorgente unica. La logica vera (`p_*`, `g_*`, `m_*`, barre di stato, intermissioni) è in gran parte **la stessa copiata quattro volte con differenze**: è il debito più grande del repository. `Common\` ha altre 22.809 righe in due unit (`d_delphi` e l'include).

### I due ostacoli veri

1. **Le variabili globali.** Una classe che legge e scrive `viewx`, `dc_source`, `players[]`, `leveltime` è una procedura con un altro nome. La trasformazione conta solo se lo stato entra in oggetti.
2. **La quadruplicazione.** Portare a classi quattro copie quasi uguali quadruplica il lavoro e conserva il difetto. Ogni sottosistema della logica va fatto **una volta**, con le differenze dei giochi come regole iniettate (lo schema di `ILevelLoader` e `TDoomLevelRules`, issue #142).

## 2. Regole

Valgono le regole di `CLAUDE.md` (una classe per unit, stile Neon, dipendenze dal costruttore, composition root, niente globali nuovi, niente `asm` nuovo). In più, per questo piano:

### 2.1 Stato in oggetti di contesto

- **`TViewContext`** (renderer): punto di vista, angoli, tabelle dipendenti dalla vista, clip, contatori del fotogramma. Vive per un fotogramma o per una vista.
- **`TColumnContext` e `TSpanContext`**: ciò che oggi sono `dc_*` e `ds_*`. Sono `record` o classi `sealed` senza metodi virtuali, passati per riferimento.
- **`TWorld`** (logica): lista dei thinker, mappa (settori, linee, blockmap, reject), giocatori, generatore casuale, `leveltime`. Un solo proprietario dello stato deterministico.
- **`TGameSession`**: ciò che sopravvive tra i livelli (skill, episodio, inventario tra mappe, statistiche).
- I globali storici restano come **alias verso il contesto** finché l'ultimo lettore non è migrato; si cancellano a fine fetta, non prima. Nessuna fetta lascia due copie dello stesso stato.

### 2.2 Percorso caldo a classi senza pagare

"A classi" nel percorso caldo significa stato negli oggetti e codice in metodi; **non** significa chiamate virtuali per elemento.

- **Nessuna chiamata virtuale né a interfaccia per colonna, span, pixel, seg, visplane o thinker.** Le interfacce si attraversano una volta per fotogramma, per vista o per lotto.
- Le classi dei cicli interni sono `sealed`, con metodi `static` o non virtuali, `inline` dove il compilatore lo consente. La scelta del disegnatore (8 o 32 bit, dettaglio, trasparenza, luce) si fa **una volta** prima del ciclo, come oggi con i puntatori a procedura; un riferimento a metodo costa come un puntatore a procedura.
- I 73 `.inc` restano il modo di generare le varianti dei cicli: diventano corpi di metodi, non spariscono per forza. Ridurli è un obiettivo secondario.
- I thinker diventano oggetti con un metodo `Think` **non virtuale per tipo**, chiamato attraverso la tabella che c'è già (un puntatore a metodo per thinker): stessa forma e stesso costo di oggi. Lo schema esiste già per luci, porte, piattaforme e teletrasporti (`Libs\Thinkers`).
- L'assembler rimasto (4 unit) si sostituisce con Pascal e test di parità, come per `Libs\MathCore` (issue #41).
- Regola imparata dalla #177: **un passo che non rispetta parità o prestazioni si annulla**, non si aggiusta in corsa.

### 2.3 Compatibilità

- **Salvataggi**: i record su disco non cambiano di un byte. Gli oggetti si serializzano attraverso adattatori che scrivono i record di oggi (`Libs\Serializer`); ogni record ha un test su `SizeOf` e un salvataggio vecchio di prova per gioco.
- **Demo e rete**: il generatore casuale e l'ordine di esecuzione dei thinker non cambiano. È ciò che gli strumenti di parità della fase 0 verificano.

## 3. Fase 0: strumenti di parità (prima di tutto il resto)

Oggi le demo dicono solo "è arrivata in fondo con lo stesso numero di gametic". Per toccare logica e renderer serve molto di più.

| Strumento | Cosa fa | Uso |
|---|---|---|
| **Impronta dello stato per tic** (`-statehash file`) | a ogni tic scrive un hash di: posizioni, momenti, salute, stato e tic di ogni mobj nell'ordine dei thinker; settori (altezze, luce, special); giocatori; indici del generatore casuale | parità della logica al bit: prima differenza = tic e oggetto |
| **Impronta del fotogramma** (`-framehash file`) | hash del buffer a 8 e a 32 bit a fine fotogramma, con input chiuso e orologio della demo | parità del renderer software al pixel |
| **Registratore GL** (c'è già, `Libs\OpenGl\Recorder`) | flusso delle chiamate OpenGL | parità del renderer OpenGL |
| **Corpus di demo** | per ogni gioco: le demo interne più due o tre registrate apposta (mostri, porte, ascensori, acqua, 3D floor, pendenze, poliobj, ACS per Hexen, dialoghi per Strife) | copertura dei rami che le demo interne non toccano |
| **Misura a coppie** (`Tools\Misura-Coppie.ps1`) | alterna vecchio e nuovo, N coppie, riporta minimo, mediana e dispersione; rifiuta la misura se la dispersione del vecchio supera il margine da provare | prestazioni affidabili (la #177 ha mostrato dispersioni del 40% a macchina carica) |
| **Golden** | le impronte del codice di partenza, per gioco e per demo, nel repository (compresse, `-text`) | ogni agente confronta con lo stesso riferimento |

Regole degli strumenti: sotto opzione da riga di comando, inerti quando spenti (le tre demo di Doom32 devono dare ancora 5026, 3836 e 2134 gametic), input chiuso durante la registrazione, due esecuzioni dello stesso eseguibile devono dare impronte uguali (rumore zero dimostrato prima di usarli).

**Criterio di uscita della fase 0**: golden registrati per i quattro giochi (software) e per i quattro OpenGL; rumore zero dimostrato; una modifica finta (un tic di ritardo su una porta) viene vista dallo strumento.

## 4. Fasi

Ogni fetta: classi nuove in `Libs\<Area>` (logica pura, testabile) o `Base\DelphiDoom.Engine.<Area>.*` (legata ai record del motore), facciata storica che delega finché ha chiamanti, test DUnitX con finti, parità con lo strumento della fase 0, build di tutti gli eseguibili, zero avvisi nel codice nuovo.

### Fase 1: finire il freddo (circa 35.000 righe di `Base\`)

Rischio basso. Parallelizzabile per famiglia, in buona parte con un modello più piccolo.

| Fetta | Unit | Righe | Destinazione |
|---|---|---:|---|
| 1a | `hu_stuff`, `hu_lib` | 2.787 | `Libs\Hud` (modello dei messaggi e dei widget), disegno in `Engine.Hud.*` (**fatta**, #185, vedi par. 8) |
| 1b | `m_defs`, `m_misc`, `m_argv`, `m_base`, `m_cheat`, `m_rnd`, `m_fixed`, `m_smartpointerlist` | 4.726 | `Libs\Configuration`, `Libs\CommandLine`, `Libs\MathCore` |
| 1c | `i_system`, `i_main`, `i_mainwindow`, `i_io`, `i_tmp`, `i_threads`, `i_startup`, `i_crashlog`, `i_net`, `i_midi*`, `i_mikplay` | 5.072 | `Libs\Platform`, `Libs\Threading`, `Libs\Audio`, `Engine.Startup.*` |
| 1d | `v_video`, `v_data`, `v_displaymode`, `i_video`, `f_wipe` | circa 7.000 | `Libs\Video`, `Engine.Video.*` (attenzione: `v_video` ha i blit usati a ogni fotogramma: tiepido) |
| 1e | `w_*`, `z_zone`, `s_sound`, `s_pk3sounds`, `sounds` | circa 6.400 | completare `Libs\Wad`, `Libs\Zone`, `Libs\Audio` |
| 1f | `sc_*`, `info_*`, `deh_base`, `d_*`, `c_*`, `mt_utils`, `nd_main`, `vx_base`, `tables`, `doomdata`, `doomtype` | circa 7.000 | `Libs\Scanner`, `Libs\ActorDef`, `Libs\Dehacked`, `Libs\Net`, `Libs\Console`; i tipi restano tipi |
| 1g | `am_map`, `am_textured` | 3.240 | completare `Libs\Automap` (il disegno software per pixel segue le regole del caldo) |

Criterio: tre demo per gioco con impronta dello stato e del fotogramma uguali ai golden.

### Fase 2: la logica di gioco in un mondo solo (circa 35.000 righe di `Base\` e circa 110.000 nei giochi)

Rischio medio. È la fase che riduce davvero il codice. Ordine dal basso verso l'alto:

| Fetta | Contenuto | Note |
|---|---|---|
| 2a | `TWorld` e i contenitori: lista dei thinker, mobj come oggetti con il record di oggi come stato, giocatori | prima solo l'involucro: nessun comportamento cambia |
| 2b | mappa e geometria: `p_maputl`, `p_sight`, `p_slopes`, `p_3dfloors`, blockmap e reject come servizi del mondo | lettura pura: facile da provare |
| 2c | movimento e collisioni: `p_map`, `p_mobj` dei quattro giochi → una implementazione, regole per gioco | il cuore della quadruplicazione |
| 2d | `p_common` (12.495 righe: azioni comuni e funzioni di ACTORDEF) → registro delle azioni (`Libs\Actions` c'è già) | spezzare per gruppi di azioni |
| 2e | thinker rimasti (pavimenti, soffitti, ascensori, scorrimenti, `udmf_*`, `po_man`) sullo schema di `Libs\Thinkers` | uno per volta, con il suo adattatore di salvataggio |
| 2f | nemici e armi: `p_enemy`, `p_pspr`, `p_inter`, `p_user` dei quattro giochi | regole per gioco; ACS (Hexen) e dialoghi (Strife) restano moduli propri |
| 2g | special delle linee e dei settori: `p_spec`, `p_switch`, `p_doors`... (`Libs\Specials` c'è già) | |
| 2h | `g_game`, `p_tick`, `p_setup`, `p_saveg`/`sv_save`: ciclo, demo, salvataggi sopra `TWorld` e `TGameSession` | i salvataggi restano byte per byte |
| 2i | tabelle `info*` e `sounddata` (175.000 righe): una sola forma di dati per gioco, caricata all'avvio | non è logica: generatore e test di uguaglianza con le tabelle di oggi |
| 2j | menu, barre di stato, intermissioni, finali (`m_menu`, `st_*`, `sb_*`, `wi_*`, `in_*`, `f_finale`) | freddo, ma quadruplicato |

Criterio: impronta dello stato per tic uguale ai golden su tutto il corpus, per tutti e quattro i giochi, a ogni fetta; salvataggi vecchi che si caricano; `-timedemo` entro il 5%.

### Fase 3: renderer software (circa 93.000 righe con i `.inc`)

Rischio alto. Parte dopo la fase 0 e dopo che la #177 ha chiuso le fette 9 e 10 (stesso metodo, stessa regola di costo).

| Fetta | Contenuto |
|---|---|
| 3a | `TViewContext`: stato della vista fuori dai globali (`r_main`, `r_camera`, `r_aspect`, `r_scale`) |
| 3b | dati e cache: `r_data`, `r_cache_*`, `r_colormaps`, `r_hires`, `r_precalc` (in parte già in `Libs\Renderer`) |
| 3c | BSP e clip: `r_bsp`, `r_clipper` (7.132 righe), `r_cliputils`, `r_subsectors` |
| 3d | muri: `r_segs`, `r_segs2`, `r_wall8`, `r_wall32` e i loro `.inc` |
| 3e | piani: `r_plane`, `r_visplanes`, `r_span*`, `r_flat*`, `r_slopes`, `r_ripple` |
| 3f | colonne: `r_column`, `r_col_*`, `r_batchcolumn`, `r_tallcolumn`, `r_draw*` (disegnatori come classi `sealed`, scelta una volta per vista) |
| 3g | oggetti: `r_things`, `r_sprite`, `r_voxels`, `r_dynlights`, `r_softlights`, `r_vislight` |
| 3h | cielo, 3D floor, effetti: `r_sky`, `r_3dfloors`, `r_fake3d`, `r_earthquake`, `r_depthbuffer`, `r_zbuffer` |
| 3i | fili: i lavori paralleli del renderer sopra `Libs\Threading` |

Criterio: impronta del fotogramma uguale ai golden a 8 e a 32 bit, in ogni dettaglio video del corpus; `-timedemo` a coppie entro il 5% (minimo e mediana); le fette che non lo rispettano si annullano e si riprogettano.

### Fase 4: renderer OpenGL

È la #177 (piano in `docs\OPENGL_PIANO.md`): restano le fette 10, 6, 7, 11, 12 e il residuo della 4. Va avanti in parallelo alle fasi 0 e 1.

### Fase 5: chiusura

- Cancellare le facciate senza chiamanti (`docs\FACCIATE.md`) e i globali rimasti come alias.
- `Common\d_delphi.pas` (parte delle 22.809 righe di `Common\`): ciò che ha un equivalente nella RTL o in `Libs\` si sostituisce; il resto in unit piccole.
- Aggiornare `CLAUDE.md`: togliere la sezione "codice storico per scelta".
- Win64 (#40, #43, #44) diventa praticabile solo a questo punto per il motore; conviene pianificarlo dopo la fase 2.

## 5. Ordine e parallelismo

1. **Fase 0** (un agente, modello grande): senza gli strumenti non si parte.
2. **Fase 1** in parallelo per famiglia (fino a quattro agenti, modello medio; un modello piccolo per le fette più meccaniche), e **fase 4** in parallelo (un agente, modello grande).
3. **Fase 2** in sequenza per fetta (le fette toccano gli stessi file dei quattro giochi: al massimo due agenti, su fette senza file comuni).
4. **Fase 3** in sequenza, una fetta alla volta, **a macchina scarica per le misure**.
5. **Fase 5**.

Vincoli di macchina emersi finora: disco C: quasi pieno (ogni worktree con le build occupa circa 1 GB), misure di prestazioni inaffidabili con più agenti che compilano, crediti dell'API. Per le fasi 2 e 3 è meglio pochi agenti lunghi che molti in parallelo.

## 6. Verifica di ogni merge

| Cosa tocca | Verifica |
|---|---|
| freddo (fase 1) | build di tutti gli eseguibili, suite della libreria e copertura al 90%, corpus con impronte uguali ai golden |
| logica (fase 2) | come sopra, più impronta dello stato su tutto il corpus dei quattro giochi, salvataggi vecchi, `-timedemo` |
| renderer (fasi 3 e 4) | come sopra, più impronta del fotogramma o flusso GL, misura a coppie a macchina scarica |

Un merge non passa se un golden cambia senza che sia dichiarato e motivato (un difetto dell'originale corretto apposta va in un commit a parte, con il golden nuovo e la spiegazione).

## 7. Rischi dichiarati

- **Il 5% potrebbe non reggere** in qualche ciclo interno anche con metodi non virtuali (`Self` in più, meno registri liberi a 32 bit). In quel caso il ciclo resta un metodo `static` di classe che riceve il contesto per riferimento: è ancora "a classi", ma senza `Self`. È la valvola prevista, da usare caso per caso con i numeri.
- **Le differenze tra i quattro giochi** in `p_*` potrebbero essere più profonde di quanto appare: la fetta 2c parte con un confronto riga per riga delle quattro copie, e l'esito decide quante regole per gioco servono.
- **Il corpus di demo** non coprirà tutto: i rami non esercitati vanno elencati a ogni fetta (come ha fatto la #177) e coperti da test di unità.
- **Dimensione**: tra `Base\` e i giochi sono circa 530.000 righe, di cui circa 175.000 sono tabelle. È un lavoro di molte settimane di agenti; il piano è fatto per fermarsi a ogni fetta con il repository verde.

## 8. Stato

| Fase | Stato |
|---|---|
| 0 strumenti di parità | **fatta** (issue #185, 2026-11-12): `Libs\Parity`, `Tools\Verifica\185`, `Tools\Misura-Coppie.ps1`, `docs\PARITA_MOTORE.md`; golden per Doom, Heretic, Hexen e Strife (software, 8 e 32 bit) in `Tests\Data\Parity` (44 demo, 11,7 MB), 88 confronti su 88 uguali in una sessione nuova, quattro modifiche finte viste, costo a strumenti spenti nel rumore (+0,00%). Mancano per il renderer (fase 3): pixel-parity degli eseguibili OpenGL con questi strumenti (c'e' il registratore GL), 3D floor e poliobj nel corpus, dettagli video oltre 640x480 a 8 e 32 bit |
| 1 freddo | **in corso** (80 unit su 181 usavano già classi). **Fetta 1a fatta** (#185, 2026-11-13, la fetta di prova): `hu_stuff` 2026 -> 1172 righe e `hu_lib` 761 -> 68 sono facciate sopra `Libs\Hud` (18 unit, 15 classi, 2453 righe) e `Base\DelphiDoom.Engine.Hud.*` (4 unit, 864 righe) + `ComposeHud`; 168 test (4940 righe di test, di cui 1308 di copia del vecchio codice per la parita'), copertura 100% della libreria; 88 confronti su 88 uguali ai golden, 18 su 18 uguali con configurazione diversa (`drawfps`, mirino, vista ridotta), dieci eseguibili compilati con meno avvisi di prima. Stima, costi e raccomandazioni per le altre fette: rapporto della fetta e `Libs\Hud\CLAUDE.md`. **Fetta 1b codice e test fatti** (#185, 2026-11-13: `sc_tokens`, `sc_consts`, `sc_params`, `sc_states`, `info_common`, `info_fnd`, `info_rnd`, `info_export`, `deh_base`; vedi il censimento qui sotto; verifica a runtime: `Tools\Verifica\185\Fetta-1b.txt`) |
| 1d (nel piano 1c) i_* | **fatta** (#185, 2026-11-13): censimento nel paragrafo qui sotto; Libs\EngineSystem (20 unit, 19 classi, 2357 righe) + Base\DelphiDoom.Engine.System.* (2 unit) + facciate; 116 test, copertura 93%; dieci eseguibili, quattro ddc_*, Launcher, DD_IDE e DD_Tools compilano (un avviso in meno per eseguibile); verifica a runtime a carico dell'agente di verifica (Tools\Verifica\185\Fetta-1d.txt) |
| 1 freddo, **fetta 1e** (avanzi meccanici di `Base\`) | **fatta** (#185, 2026-11-13). Censimento delle 15 unit (3833 righe, quasi tutto tipi e dati): **trasformate** `mt_utils` (1347 -> 764 righe, facciata sopra `TWorkerJobRunner`, `TWorkerMemoryRunner`, `TWorkerTaskScheduler` di `Libs\Threading`), `c_utils` (219 -> 69, `TConsoleUtilityCommands` in `Libs\Console`) e `d_notifications` (129 -> 100, `TDeferredNotifications` in `Libs\Video`); **gia' facciate o delegate** a classi dalle ondate precedenti: `c_cmds` (registro e interprete di `Libs\Console`), `c_con` (tiene 4 variabili; la console e' `TEngineConsoleScreen`), `nd_main` (i nodi sono `Libs\Nodes`; restano i tipi dei record GL e `gld_GetGLVertexes` che chiama `TNodesGlParser`); **restano storiche, solo tipi o dati**: `doomtype` (costanti e due funzioni `smallintwarp`), `doomdata` (record dei lump WAD, packed: formato su disco), `d_ticcmd` e `d_event` (`ticcmd_t`, `event_t`: record di rete, demo e salvataggi, non cambiano di un byte), `d_think` (`think_t` e `thinker_t`: puntatori a funzione salvati grezzi da `p_saveg`, regola dei thinker), `d_net_h` (costanti), `d_net` (due variabili e una stringa), `tables` (tabelle seno, tangente, arcotangente: percorso caldo, restano costanti accedute per indice, stesso costo; `SlopeDiv`/`AngleToSlope` sono funzioni pure di una riga, usate dal renderer), `vx_base` (il registro che i renderer leggono per ogni voxel: vedi `docs\PENDING_ISSUES.md`). Nuovo: 36 test in `Libs\Threading` (82 in tutto, copertura 97%), 10 in `Libs\Console` (185, 96%), 7 in `Libs\Video` (75, 98%); parita' sul vecchio codice copiato in `Tests\Source\DelphiDoom.Tests.Threading.Legacy.pas` e nel test di `UtilityCommands`. Verifica di runtime e confronti con i fili accesi: `Tools\Verifica\185\Fetta-1e.txt` (da fare da un agente di verifica) |
| 2 logica | da fare (thinker di luci, porte, piattaforme, teletrasporti già a classi in `Libs\Thinkers`) |
| 3 renderer software | da fare (`Libs\Renderer` ha le prime fette fredde) |
| 4 renderer OpenGL | in corso (#177: fatte 0-5 in parte, 8, 9) |
| 5 chiusura | da fare |

### Fetta 1b: `sc_*`, `info_*`, `deh_base` (censimento e stato)

Censimento prima del lavoro (`63a151cc`, 4926 righe in nove unit). `sc_tokens` (161): `TTokenList` (classe sopra `TDStringList`, usata da `statenames` e dalle liste `*_tokens` dei quattro `deh_main`) e `SC_EvalueateIntToken` (solo `p_common`). `sc_consts` (326): tabella hash di costanti (usata da `dd_compiler`, `DelphiDoom.Engine.Scanner.ActorVariables`, `info_common`) e circa 150 righe di dati in `SC_InitConsts`. `sc_params` (998): `TCustomParamList` (gia' classe, letta a ogni azione con parametri da `p_common`, dagli applicatori DEH e da `info_h` dei quattro giochi) e `SC_EvalString`. `sc_states` (358): lettura del lump `STATEDEF`, lista `statenames` e `P_GetStateFromName*` (solo `p_common`). `info_common` (1160): ricerche sulle tabelle (numero, nome, alias, ereditarieta', stati, sprite), gruppi MBF21, crescita delle tabelle, proprietari degli stati; `info_fnd` (126) e `info_rnd` (243) idem; `info_export` (233): gia' una facciata con scrittore iniettato, restavano il salvataggio e i comandi. `deh_base` (1321): gia' facciata dell'applicatore e degli scrittori, restavano il salvataggio (sette volte), i nomi dei file, `DEH_CStringToString`/`DEH_StringValue` (copie di `TDehackedText`) e le regole dei prefissi dei tipi. Le tabelle `info*` per gioco (`Doom\info.pas` ecc.) sono fuori dalla fetta e restano dati.

Esito: facciate 4926 -> 3369 righe (-1557); librerie nuove 2577 righe (`Libs\Info` 12 unit, `TScannerTokenEntry`, `TScannerConstTable`, `TActorDefParamList`/`ParamText`/`ParamString`/`ParamList.Intf`, `TDehackedFileNames`, `TDehackedTokenName`, `TTableExportSaver` con la sua `Intf`); adattatori nel motore 15 unit, 1414 righe (`DelphiDoom.Engine.Info.*`, `ActorDef.ParamRandom`, `ActorDef.MissingEvaluator`, `TableExport.Output`) e `ComposeInfoTables`; test: `Tests\DelphiDoom.Tests.InfoTables` (83 test, 8205 righe di test con le copie del vecchio codice; copertura delle classi nuove da 91,8% a 100%, `Libs\Info` 96%). I dieci eseguibili, i quattro `ddc_*`, `ddc`, `Launcher`, `DD_IDE` e `DD_Tools` compilano; avvisi dei giochi 384/334/306/256/201/151/415/342/383/384 (prima 387/337/309/259/204/154/418/345/386/387), zero nel codice nuovo. **Non fatto da chi ha scritto il codice** (cambio di processo): golden, confronti con `-ExtraIni` e con `-ExtraArgs`, misura a coppie, demo e avvii: comandi in `Tools\Verifica\185\Fetta-1b.txt`. Dettagli per libreria: `Libs\Info\CLAUDE.md` e i paragrafi "Fetta 1b" di `Libs\Scanner`, `Libs\ActorDef`, `Libs\Dehacked`, `Libs\TableExport`.

### Fetta 1d: censimento e costi (i_*)

Censimento (master cb5a45e3, 3224 righe in nove unit): **8 delle 13 unit i_* usavano gia' classi** e la logica procedurale rimasta era poca. i_threads (216 righe) e i_tmp (130) sono gia' facciate sottili sopra Libs\Threading e Libs\Platform: restano storiche (TDThread e' gia' una classe, ThreadInc/ThreadSet un Interlocked; i fili del renderer le usano). i_system (1232 righe) era gia' per l'80% una riga su una libreria (clock, piattaforma, input, log); la logica vera era I_Destroy (sequenza di uscita), I_Error (guardia, ordine), I_DetectCPU e il resto era chiamate a Windows (PeekMessage, PostMessage, GetSystemMetrics, ShellExecuteA caricata a mano). i_io (259) aveva il buffer dello stdout e i nomi dei log; i_net (155) il parsing della riga di comando; i_mikplay (258) una classe travestita da routine con un flag; i_midi (319) lo smistamento tra due player; i_midi_legacy (417) un player MCI con una finestra nascosta e variabili globali; i_crashlog (238) il filtro delle eccezioni. Dipendenti da Windows e quindi in adattatori: MCI e la finestra di notifica, WriteFile/IsBadReadPtr/SetUnhandledExceptionFilter, InvalidateRect.

**Costi.** Righe delle facciate (prima -> dopo): `i_net` 155 -> 124, `i_io` 259 -> 221, `i_crashlog` 238 -> 64, `i_mikplay` 258 -> 214, `i_midi_legacy` 417 -> 252, `i_midi` 319 -> 334 (la scelta dei player esce, entra il collegamento), `i_system` 1232 -> 1212; `i_threads` e `i_tmp` invariate. In totale le sette unit passano da 2878 a 2421 righe; `Libs\EngineSystem` e' di 2357 righe in 20 unit (19 classi e i tipi), `Base\DelphiDoom.Engine.System.*` di 238 in 2 unit, i test di 4009 righe (881 di copie del vecchio codice) con 116 test e 8 scenari casuali di parita' vecchio/nuovo. Il guadagno in righe non c'e' (la fetta era quasi tutta gia' delegata e ogni routine storica ha il suo riquadro di commento): il guadagno e' la parita' provata, le classi sostituibili nei test (sequenza di uscita, errori, MCI, crash) e i difetti trovati.

**Difetti trovati nel vecchio codice**: TDStringList.Put di d_delphi ignora l'indice 0 (la prima riga dello stdout non cresce mai: conservato, da correggere a parte); -net o -dup con argomento vuoto leggevano una stringa nil (violazione di accesso); la notifica di fine canzone del player legacy con la lista vuota dava un errore; ShutDown del player legacy lasciava un puntatore a una lista liberata; strutture MCI non inizializzate.

## 9. Fetta 1c: la famiglia `m_*` (#185, 2026-11-13)

(Nella tabella del par. 4 e' la riga "1b": i nomi delle fette sono stati assegnati dopo il piano; qui si usa quello del lavoro.)

### Censimento (a `63a151cc`)

Conteggi di occorrenze nel codice di `Base`, `Common`, giochi, `Radix`, `Speed`, `Launcher`, `DD_IDE`, `DD_Tools`, `Libs\ScriptHost`, `Libs\OpenGl`, `Libs\Ddc`.

| Unit | Righe | Stato a `63a151cc` | Chiamanti e globali | Decisione |
|---|---:|---|---|---|
| `m_defs` | 2546 | dati: `defaults[]` di `default_t` (nome, puntatore al globale, `oldlocation`, chi puo' cambiarla, tre valori di partenza, tipo), 233/224/220/235 voci per Doom/Heretic/Hexen/Strife (19 gruppi, 125 interi, 118 booleani, 17 testi nel sorgente, con i rami OpenGL); lettori: `TEngineDefaults`, `TEngineConsoleVariable(Source)`, `TEngineScriptConsole`, che leggevano e **scrivevano** l'array (la forzatura spostava `location` sul valore di partenza) | puntatori a globali di circa 40 unit | **a classi**: righe e tabella in `Libs\Configuration`, accesso al globale dato dal composition root; l'array resta la dichiarazione delle voci, letto una volta |
| `m_argv` | 244 | facciata sopra `Libs\CommandLine` (#150); `M_InitArgv` (raccolta di `ParamStr`, file `Doom32.cmd`, CD-ROM) ancora nel motore | `M_CheckParm` 347, `myargv` 153, `myargc` 190, `M_SaveFileName` 69 | **a classi** `M_InitArgv` (`TCommandLineStartup` + `IProgramEnvironment`); la facciata e `myargv`/`myargc` restano per i chiamanti procedurali |
| `m_cheat` | 152 | `cht_CheckCheat`/`cht_GetParam` gia' sopra `TCheatSequence`; `get_cheatseq_string` (219 occorrenze, 86 con `0`) codice proprio | 7 file | **a classi** la lettura (`TCheatSequenceReader.FromChars/FromString`); `cht_*` restano (legate a `cheatseq_t` dei giochi) |
| `m_rnd` | 212 | facciata sopra `IGameRandom` di `Libs\MathCore` (#75, #150) | `P_Random` 931, `N_Random` 119, `M_Random` 18 | **storica** (vedi sotto): e' gia' una classe; parita' su 10 milioni di chiamate |
| `m_fixed` | 798 | `asm` a 32 bit, `TFixedMath` a 64 | `FixedMul` 843, `FixedDiv` 153, altre 300 | **storica** (vedi sotto) |
| `m_misc` | 50 | solo variabili (formato degli screenshot, testi dei booleani) | `screenshotformat` 59, `yesnoStrings` 22 | resta: sono le variabili lette dalla tabella delle impostazioni e dal menu |
| `m_base` | 52 | solo costanti (`_GAME`, `APPNAME`, `DEFARGVFILENAME`, `WINCLASSNAME`, rami `RADIX`/`SPEED`) | `_GAME` 364 in 203 file | resta: costanti di compilazione, nessuna logica |
| `m_smartpointerlist` | 174 | gia' una classe (`TSmartPointerList`) in una unit sua | `p_mobjlist` (hash dei mobj), `Libs\OpenGl\Legacy\mdl_dllmodel` (fuori dai limiti di questa fetta) | resta: spostarla in una libreria cambierebbe solo il nome (e toccherebbe `Libs\OpenGl`); la sua `Clear` sottrae a `memoryusage` di `d_delphi` gli elementi e non la capacita' (difetto del solo contatore del comando `mem`, conservato) |

**Ordine seguito**: `m_defs` (il disegno che regge la fetta: tabella a classi con l'accesso al globale iniettato, la parita' piu' ampia), `m_cheat` e `m_argv` (confini chiari, la libreria c'era gia'), poi le decisioni su `m_rnd`/`m_fixed` con una misura, e per ultime le unit che restano (`m_misc`, `m_base`, `m_smartpointerlist`) con il motivo.

### Disegno della tabella

`Libs\Configuration` (nessun `uses` verso il motore): `IConfigurationValueAccess` (il piccolo oggetto che porta al globale: lo da' il composition root), `IConfigurationItem`/`TConfigurationItem` (una riga: nome, tipo, chi puo' cambiarla, valori di partenza, valore visto da file e console, valore vero, `ResetToDefault`, `Force*`: la prima forzatura chiude la riga e sposta il valore di prima nei valori di partenza, come faceva lo spostamento di `location`), `IConfigurationTable`/`TConfigurationTable` (l'ordine del file; la prima riga con un nome), `IConfigurationTableStore`/`TConfigurationTableStore` (i passi di `M_LoadDefaults`/`M_SaveDefaults`/`M_SetDefault`/`M_ForceDefault*` che non dipendono dal motore; `IConfigurationResetSink` per i messaggi e la console del reset). Motore: `TEngineConfigurationGlobal` (accesso su un puntatore), `TEngineConfigurationTable.Build` (le righe dai dati di `m_defs`, chiamata da `ComposeEngine`), `TEngineDefaults` (file, riga di comando, messaggi, `G_SetKeyboardMode` e skill dopo il caricamento), `TEngineConsoleVariable(Source)` e `TEngineScriptConsole` sulle righe. Nessuno scrive piu' l'array: tolto il campo `oldlocation` (276 righe).

### `m_rnd` e `m_fixed`: le misure

- **`m_fixed`**: provata una sola volta la versione Pascal anche a 32 bit (corpi di `TFixedMath` al posto dell'`asm`, `Tools\Verifica\185\Fetta-1c-m_fixed-pascal.patch`), Doom32 `-timedemo demo1` a 32 bit, 8 coppie: vecchio minimo 255 mediana 264,5 dispersione **46,27%**; nuovo minimo 265 mediana 273,5 dispersione 26,04%; mediane +3,40%, minimi +3,92%. Lo strumento ha **rifiutato** la misura (dispersione del vecchio oltre il 3%: l'altro agente compilava e misurava in parallelo). Senza una misura valida `m_fixed` **resta storica** (la tendenza, +3-4%, e il fatto che `Int64 * Int64` a 32 bit e' una chiamata a `_llmul` e la divisione a `_lldiv` dicono che e' al limite del 5%). Da rifare a macchina scarica (comando in `Tools\Verifica\185\Fetta-1c.txt`).
- **`m_rnd`**: e' gia' a classi (`TGameRandom` dietro `IGameRandom`, una chiamata a interfaccia per numero dalla #75, entro il golden da allora); renderla un metodo statico di una classe `sealed` sarebbe un'ottimizzazione, non una conversione, e senza misura valida non si tocca. Parita' nuova: `DelphiDoom.Tests.MathCore.RandomParity`, 10 milioni di chiamate (5 semi, `P/M/N/Sys/C_Random`, `P_RandomFromSeed`, salva e ripristina, seme dei mostri, azzeramento) contro la copia di `m_rnd` prima della #75: valori e cinque indici uguali dopo ogni chiamata.

### Esito (codice, 2026-11-13; la verifica pesante la fa un agente separato)

- Righe: `m_defs` 2546 -> 2274, `m_argv` 244 -> 200, `m_cheat` 152 -> 155, `TEngineDefaults` 382 -> 278, `TEngineScriptConsole` 193 -> 120; nuove 787 in `Libs\Configuration` (4 unit nuove + aggiunte a `Intf`, `Types`, `Factory`), 162 in `Libs\CommandLine`, 33 in `Libs\Console`, 265 di adattatori in `Base`.
- Test: Configuration 34 -> 58 (copertura 99%, le unit nuove 100%), CommandLine 102 -> 108 (100%), Console 175 -> 178 (96%), MathCore 122 -> 123 (98%); parita' vecchio/nuovo nello stesso eseguibile per tabella (300 tabelle casuali x 120 operazioni con confronto di ogni variabile, del file scritto e dei messaggi a ogni passo, piu' 300 file completi), `M_InitArgv` (2000 scenari, riga di comando e sequenza delle domande all'ambiente), `get_cheatseq_string` (40000 sequenze), `m_rnd` (10 milioni di chiamate). Una modifica finta (la forzatura che non chiude la riga) e' vista dalla parita' al passo 82 del primo scenario.
- Build: dieci eseguibili con 387/337/309/259/204/154/418/345/386/387 avvisi (uguali a prima), `ddc_*` 386/308/203/417 (uguali al riferimento compilato nello stesso modo), Launcher 9, DD_IDE 24, DD_Tools 0 (uguali); zero avvisi nel codice nuovo.
- **Non eseguito per il cambio di processo** (lo fa l'agente di verifica, comandi in `Tools\Verifica\185\Fetta-1c.txt`): golden (88 confronti), confronti `-ExtraIni`, confronto dei file `.ini` scritti (`Confronta-Ini.ps1`, scritto senza poterlo eseguire), riga di comando e file di risposta a runtime, `-timedemo`, avvii, misura a coppie.

## 10. Fase 2: progetto (#185, 2026-11-14)

Scritto prima di toccare il codice. Lo stato reale di ogni passo e' nel paragrafo 11.

**Regola del riuso (utente, 2026-11-14)**: si riusa cio' che esiste e lo si estende con sole aggiunte; niente classi parallele. Per la fase 2 la base e': `Libs\Thinkers` (luci, porte, piattaforme, `TPlaneMover`, profili per gioco), `Libs\Actions`, `Libs\Specials`, `Libs\GameState` (`IGameContext`), `Libs\Info`, `Libs\Blockmap`, `Libs\MathCore` (`IGameRandom`, fixed), `Libs\Serializer`, `ILevelLoader`/`ILevelGameRules`/`TDoomLevelRules` e gli adattatori `Base\DelphiDoom.Engine.*` (`Plane.*`, `Plat.*`, `Door.*`, `Light.*`, `Teleport.*`, `GameContext`). Ogni cosa nuova va motivata nel paragrafo 11 ("non esisteva un equivalente perche'...").

### 10.1 Fotografia della quadruplicazione (`c57fbf77`)

Righe diverse tra le copie (`diff` riga per riga, intestazioni comprese):

| Unit | Doom | Heretic | Hexen | Strife | Doom/Strife | Doom/Heretic | Heretic/Hexen |
|---|---:|---:|---:|---:|---:|---:|---:|
| `p_scroll` | 416 | - | - | 416 | 2 | - | - |
| `p_plats` | 272 | 256 | - | 279 | 11 | 76 | - |
| `p_lights` | 387 | 382 | - | 404 | 21 | 37 | - |
| `p_ceilng` | 428 | 335 | - | 452 | 36 | 127 | - |
| `p_genlin` | 1452 | - | - | 1431 | 63 | - | - |
| `p_telept` | 460 | 246 | - | 463 | 61 | 398 | - |
| `p_floor` | 930 | 411 | - | 880 | 192 | 637 | - |
| `p_doors` | 394 | 286 | - | 1335 | 1075 | 188 | - |
| `p_map` | 3581 | 3166 | 3904 | 3428 | 1033 | 813 | 1194 |
| `p_mobj` | 2626 | 2845 | 3449 | 2753 | 943 | 1187 | 2660 |
| `p_user` | 1093 | 1468 | 2305 | 1513 | 696 | 955 | 1503 |
| `p_inter` | 1265 | 1847 | 2682 | 1568 | 1361 | 1394 | 2691 |
| `p_pspr` | 1195 | 2126 | 2691 | 1260 | 927 | 1873 | 2903 |
| `p_enemy` | 3391 | 3562 | 6635 | 4545 | 4154 | 3279 | 5929 |
| `p_spec` | 4333 | 2041 | 1771 | 4496 | 1839 | 3036 | 1734 |
| `p_switch` | 1312 | 550 | 224 | 1956 | 1104 | 952 | 380 |
| `g_game` | 3801 | 3609 | 2416 | 3480 | 1725 | 1076 | 2261 |

Tre gruppi: (1) **quasi uguali** (`p_scroll`, `p_plats`, `p_lights`, `p_ceilng`, `p_genlin`, `p_telept` e `p_floor` di Doom e Strife): una implementazione e un profilo di dati; (2) **stesso scheletro con differenze locali** (`p_map`, `p_mobj`, `p_user`): una implementazione con regole per gioco; (3) **contenuto diverso** (`p_enemy`, `p_pspr`, `p_inter`: le azioni dei mostri e delle armi sono di ogni gioco): si unifica solo il nucleo comune (`P_LookForPlayers`, `P_Move`, `P_NewChaseDir`, `A_Chase`...), il resto resta nel gioco come gruppo di azioni (`Libs\Actions`). `Base\` ha gia' in copia unica `p_tick`, `p_maputl`, `p_sight`, `p_slopes`, `p_3dfloors`, `p_common`, `p_setup` (con `{$IFDEF}` di gioco).

### 10.2 Contesti

- **Il mondo** (`TEngineWorld`, `Base\DelphiDoom.Engine.World.pas`, `sealed`, nessun metodo virtuale): lo stato deterministico del livello. Non esiste oggi un equivalente (lo stato e' nei globali di `p_tick`, `p_setup`, `d_player`, `g_game`); e' composto da parti che **esistono gia'** dove possibile:
  - `Thinkers`: la lista dei thinker (capo della lista doppia, aggiungi, rimuovi pigro, giro del tic). La logica pura della lista entra in **`Libs\Thinkers`** (`DelphiDoom.Thinkers.List`: e' la libreria dei thinker; nessuna libreria nuova), sopra un nodo con il layout di `thinker_t`, provata con nodi finti.
  - `Time`: `leveltime`, congelamento (`isgamefreezed`, `isgamesuspended`), `TimerGame` di Hexen.
  - `Map`: vertici, seg, settori, sottosettori, nodi, linee, lati, blockmap, `blocklinks`, reject (oggi i globali di `p_setup`, riempiti da `TLevelLoader`: il mondo li riceve dal caricatore che c'e').
  - `Players`: `players[]`, `playeringame[]`.
  - `Random`: l'`IGameRandom` di `ComposeMathCore` (gia' una classe: il mondo lo riceve dal costruttore).
- **La sessione**: non una classe nuova accanto a `IGameContext`, ma **`IGameContext` esteso** (`Libs\GameState`, sole aggiunte: skill, episodio, mappa, `deathmatch`, giocatore della console, totali) e `TEngineGameContext` che lo implementa. `TGameSession` del piano e' questo.
- Il mondo nasce in `DelphiDoom.Engine.Composition` (`ComposeWorld`) e arriva alle facciate con `P_ConfigureWorld`; senza configurazione `I_Error`. Le classi nuove lo ricevono dal costruttore.

### 10.3 Proprieta' dello stato: come un globale diventa del contesto

Delphi non ha alias verso un campo (`var leveltime: integer absolute World.FLevelTime` da' `E2088 Variable name expected`: provato con dcc32). Quindi ogni globale passa per tre stadi, **senza mai avere due copie dello stato**:

1. **Riferimento.** Il contesto espone un puntatore tipizzato alla memoria storica (`World.Time.LevelTime` legge un `PInteger`); le classi nuove usano solo il contesto, il codice storico continua a leggere il globale. Nei test il puntatore va a memoria del test.
2. **Inversione.** Quando tutti gli scrittori fuori dai salvataggi passano dal contesto, la memoria entra nel contesto e il nome storico diventa una funzione `inline` senza parametri (`function leveltime: integer; inline;`): i lettori si ricompilano senza toccarli. Per i globali di cui si prende l'indirizzo (`@thinkercap`, circa 170 occorrenze in 36 unit) i lettori vanno migrati prima: una funzione non ha l'indirizzo della variabile e il confronto `think <> @thinkercap` compilerebbe con un altro significato. E' il punto piu' pericoloso: ricerca completa, mai una funzione omonima.
3. **Cancellazione.** Il nome storico sparisce con l'ultimo lettore (fase 5).

**Vincolo di questo giro**: `p_saveg`/`sv_save` non si toccano (li ha un altro lavoro, #40) e scrivono direttamente `leveltime`, `thinkercap`, `players[]`, settori e linee. Tutto cio' che i salvataggi scrivono **resta allo stadio 1** fino alla fetta 2h.

### 10.4 Regole per gioco: tre forme, nessun `{$IFDEF}` nel codice comune

| Forma | Quando | Esiste gia' |
|---|---|---|
| **Profilo** (record di costanti e interruttori, scelto una volta) | la differenza e' un dato: velocita', suono, quale tipo schiaccia | `TPlatProfile`/`TPlatGames`, `TDoorProfile`/`TDoorProfiles`, `TPlaneMoveRules`/`TPlaneRules`, `TLightGames`: i profili nuovi si aggiungono a `Libs\Thinkers` con lo stesso schema |
| **Strategia fredda** (interfaccia per gioco, data dal composition root) | codice diverso chiamato poche volte per tic o per livello | `ILevelGameRules`, `ILevelGeometryRules`, `ILevelThingRules` e le classi `T<Gioco>LevelRules`: le regole nuove sono **metodi o interfacce aggiunti a queste classi**, non una seconda gerarchia |
| **Strategia calda** (classe `sealed` di soli metodi `class ... static`, **stesso nome di unit in ogni cartella di gioco**, risolta dal percorso del progetto) | codice diverso dentro un ciclo per thinker o per cella della blockmap (`PIT_CheckThing`, `P_XYMovement`) | e' cio' che sono oggi le quattro `p_map.pas`: la unit del gioco si riduce alle sole routine *proprie* |

La strategia calda e' una scelta fatta a compilazione dal progetto: nessuna chiamata virtuale ne' a interfaccia, il compilatore puo' fare `inline`. I tipi che cambiano per gioco (`mobjtype_t`, i campi di `mobj_t`, `ceiling_e`...) si nominano **solo** nella unit del gioco. Dove la scelta e' a runtime (versione della demo, `compatibilitymode`) si usa una tabella di puntatori a procedura riempita una volta.

### 10.5 Thinker e salvataggi

I thinker restano record nella zone memory con il puntatore a funzione che `p_saveg` conosce (`T_MoveCeiling`, `T_Scroll`...): la funzione storica resta come guscio che chiama il codice comune. Nessun campo cambia posto o dimensione. Se un passo ha bisogno di cambiare un record salvato, **si ferma e si riporta**.

### 10.6 Ordine dei sottosistemi

| Passo | Contenuto | Forma delle regole | Prova |
|---|---|---|---|
| 2a | involucro: `TEngineWorld`, lista dei thinker e giro del tic (`p_tick`), tempo; `IGameContext` esteso | nessuna | golden 8 bit dei quattro giochi; misura a coppie (il giro dei thinker e' caldo); test della lista con nodi finti |
| 2e-1 | thinker quasi uguali: `p_scroll`, `p_ceilng`, `p_floor`, `p_genlin` (poi il resto di `p_plats`, `p_lights`, `p_doors`, `p_telept`), estendendo `Libs\Thinkers` e `Engine.Plane.*` | profilo | golden; parita' vecchio/nuovo nei test (`Tests\DelphiDoom.Tests.Thinkers`, schema di `OldPlanes`/`OldPlats`/`OldDoors`) |
| 2c-1 | `p_map`: confronto delle quattro copie routine per routine, poi una implementazione | strategia calda | golden; misura a coppie |
| 2c-2 | `p_mobj` | strategia calda | golden; misura |
| 2f | `p_user`, nucleo comune di `p_inter`, `p_enemy`, `p_pspr` | strategia calda + gruppi di azioni per gioco (`Libs\Actions`) | golden; misura |
| 2g | `p_spec`, `p_switch` | profilo + registro (`Libs\Specials`) | golden |
| 2b | `p_maputl`, `p_sight`, `p_slopes` come servizi del mondo (sono gia' in copia unica) | - | golden; misura |
| 2h | `g_game`, sessione, salvataggi (`Libs\Serializer`) | strategia fredda | **bloccato in questo giro** (salvataggi) |
| 2i, 2j | tabelle `info*` (`Libs\Info`), menu e barre di stato | dati | fuori da questo giro |

### 10.7 Protocollo di ogni passo

1. **Ricerca dell'esistente** (`Libs\*`, `Base\DelphiDoom.Engine.*`, `docs\FRAMEWORK_CENSIMENTO.md`, `docs\ANALISI_DUPLICATI.md`) e **tabella di confronto** delle copie, routine per routine: *uguale* (testo identico tolti commenti e spazi), *parametrica* (poche righe diverse: profilo o regola), *propria* (resta nel gioco).
2. Codice: la logica pura in una libreria che c'e' gia' (test DUnitX con finti, copertura almeno 90%); cio' che e' legato ai record del motore in `Base\DelphiDoom.Engine.<Area>.*` o nella unit storica unificata (la prova e' il golden); le unit storiche restano facciate con la stessa API finche' hanno chiamanti.
3. **Verifica**: dieci giochi piu' Radix32 e SpeedHaste32 compilano con avvisi non aumentati (base: 383/382/383/333/305/255/200/150/414/341); Doom32 e Strife32 a Win64; `Confronta-Golden.ps1 -Modes 8` sui quattro giochi (44 voci) UGUALE, e `-Modes 32` per Doom e Strife se il passo disegna; `Misura-Coppie.ps1` vecchio contro nuovo entro il 5%.
4. Un commit per passo. Un passo che non rispetta parita' o prestazioni si annulla (`git revert`) e si scrive qui perche'.
5. I rami che il corpus non esercita (rete, difficolta' 4-5, 3D floor, poliobj, dialoghi) si elencano nel passo: per quelli la prova e' la tabella di confronto (codice spostato senza modifiche) o il test di unita', non il golden.

## 11. Fase 2: stato dei passi

(aggiornato a ogni passo)

### 2a: involucro del mondo (2026-11-14)

**Migrato.** La lista dei thinker e il giro del tic non sono piu' codice di `Base\p_tick.pas`:

- `Libs\Thinkers\DelphiDoom.Thinkers.List.pas` (`TThinkerList`, `sealed`, nessun metodo virtuale): `Clear` (`P_InitThinkers`), `Add` (`P_AddThinker`), `Remove` (`P_RemoveThinker`, rimozione pigra con il marcatore), `IsRemoved` (`P_ThinkerIsRemoved`, `class ... static`), `Run` e `RunFrozen` (i due rami di `P_RunThinkers`). Lavora su `TThinkerNode` (prev, next, funzione: il layout di `thinker_t`) e sul capo dato dal costruttore; cio' che e' del motore arriva una volta come puntatori a procedura (`TThinkerListHooks`: `Cleared`, `Added`, `Removed`, `Release`, `RunsWhenFrozen`). Nel giro: confronto col marcatore, chiamata del thinker, `next` letto dopo la chiamata, come prima; nessuna interfaccia.
- `Base\DelphiDoom.Engine.World.pas` (`TEngineWorld`, `sealed`; l'unico metodo virtuale e' il `Destroy` ereditato): possiede la `TThinkerList` sul capo `thinkercap` (stadio 1: la memoria resta il globale che `p_saveg`/`sv_save` usano), il tempo come riferimenti tipizzati (`TEngineWorldTime`: `LevelTime`, `IsFrozen`, `IsSuspended`, `TimerGame` che e' `nil` fuori da Hexen) e l'`IGameRandom` di `ComposeEngine`. Le procedure date alla lista stanno in questa unit: `mobjlist.Clear/Add/Remove` per i thinker con `P_MobjThinker`, `Z_Free`, e il filtro del ramo congelato (giocatore o `MF3_EX_NOTIMEFREEZE`). `RunThinkers` sceglie il ramo da `IsFrozen^`.
- `ComposeWorld` in `DelphiDoom.Engine.Composition` (dopo `ComposeMathCore`) crea il mondo e lo da' a `p_tick` con `P_ConfigureWorld`; `p_tick` lo possiede e lo libera in `finalization`. `P_WorldTime` (facciata) da' gli indirizzi dei globali del tempo: l'`{$IFDEF HEXEN}` di `TimerGame` resta nella facciata storica.
- `p_tick.pas` (362 -> 353 righe) resta la facciata con la stessa API: `P_InitThinkers` e `P_Ticker` passano da `P_World` (controllo "non configurato" con `I_Error`, una volta per livello e una per tic); `P_AddThinker` e `P_RemoveThinker` usano il riferimento senza controllo (non si puo' aggiungere un thinker prima di `P_InitThinkers`, che controlla; `ComposeEngine` e' la prima istruzione dei `.dpr`). `P_Ticker` resta in `p_tick`. Le unit nuove sono nei 14 `.dpr` che elencano `p_tick` (dieci giochi con Radix32 e SpeedHaste32, quattro `ddc_*`).
- **Sessione**: `IGameContext` (`Libs\GameState`) ha in piu' `Skill`, `Episode`, `Map`, `Deathmatch`, `ConsolePlayer`, `MaxPlayers` (interi), implementati da `TEngineGameContext`. Strife non ha `gameepisode`: `Episode` da' 1 (un `{$IFDEF STRIFE}` nell'adattatore). I finti di `IGameContext` aggiornati: `Tests.Console.Fakes`, `Tests.DynLights.Fakes`, `Tests.Net.Fakes`.

**Riuso.** Riusati: `Libs\Thinkers` (la lista e' una unit della libreria, nessuna libreria nuova), `IGameRandom` di `Libs\MathCore`, lo schema `P_Configure*`/`Compose*`/`I_Error`, lo schema dei test `Old*` di `Tests\DelphiDoom.Tests.Thinkers`. Estesi: `IGameContext` e `TEngineGameContext` (sei metodi), `ComposeEngine`. Nuovi: `TThinkerList` (non esisteva una lista dei thinker fuori da `p_tick`: `TMobjList` di `p_mobjlist` e' l'indice per chiave dei soli mobj e resta com'e') e `TEngineWorld` (non esisteva un proprietario dello stato del livello: par. 10.2); `ScriptHost.World.*` e' la vista degli script su settori e linee, non lo stato.

**Differenze dal vecchio.** Nessuna voluta nel comportamento. Costo: `Z_Free`, la notifica a `mobjlist` e il filtro del ramo congelato passano da un puntatore a procedura (una chiamata indiretta per aggiunta, rimozione e liberazione, non per thinker nel giro normale); `P_AddThinker` chiama ora la notifica anche per i thinker che non sono mobj (il confronto con `P_MobjThinker` e' dentro la procedura).

**Verifica.**

- Build `Tools\build.bat giochi Release`: 10 su 10, errori 0, avvisi 383/382/383/333/305/255/200/150/414/341 (uguali alla base), nessuno nelle unit nuove. `Doom32` e `Strife32` Release Win64 compilano.
- Test: `DelphiDoom.Tests.Thinkers` 283 su 283 a Win32 e a Win64 (27 nuovi in `Tests\Source\DelphiDoom.Tests.Thinkers.List.pas`: forma del nodo, argomenti nil, ordine, rimozione pigra, thinker che aggiungono o rimuovono se stessi, il successivo o il precedente, ramo congelato, e la parita' con il vecchio codice copiato in `DelphiDoom.Tests.Thinkers.OldList.pas` su 400 scenari casuali da 40 tic e 8 da 1500 tic: stesse chiamate, stesse notifiche, stesse liberazioni, stessa lista in avanti e all'indietro dopo ogni tic). Copertura di `DelphiDoom.Thinkers.List` con `Tools\Copertura.ps1 -Test Thinkers`: 70 righe su 71 (99%; la riga non coperta e' il corpo del marcatore, che non si chiama mai). Suite dei finti toccati: Console 369/369, DynLights 39/39, Net 244/244.
- Golden: verifica ridotta, 4 voci su 44 UGUALI (`d1_demo1`, `a_h_e1m1`, `a_x_map01_f`, `a_s_map32` a 8 bit, fatta dal coordinatore prima del commit `45cafc18`); corpus intero e misura a coppie da fare sul ramo unito. Il giro completo `Confronta-Golden.ps1 -Modes 8` e' stato lanciato due volte e non e' arrivato in fondo: la prima volta 11 voci di Doom UGUALI, poi la cartella di lavoro e' stata cancellata (spazio su disco); la seconda e' stata fermata a richiesta (lock dei giochi conteso). Nessuna differenza osservata.
- Misura a coppie (`Misura-Coppie.ps1`): **non fatta** (macchina occupata dalle build degli altri lavori).

**Non verificato.** `TEngineWorld` non ha test di unita' (legge `mobjlist`, `Z_Free`, `P_MobjThinker`: la sua prova e' il golden, per ora ridotto); il ramo congelato nel motore (il corpus non congela il gioco: la prova e' il test di parita' della lista); salvataggi e caricamenti (non toccati, non provati); giochi OpenGL, Radix32 e SpeedHaste32 compilati ma non avviati; Win64 non avviato; `ddc_doom` e `ddc_hexen` compilano (avvisi 382 e 199, base non misurata); `ddc_heretic` e `ddc_strife` non ricompilati.

### 11.1 Passo 2e-1: thinker quasi uguali (ramo `worktree-agent-ab3c8727792294d50`, 2026-11-14)

Un commit per unit. Schema: logica pura in `Libs\Thinkers` (classi `sealed` di soli metodi `class ... static`, profilo per gioco, tipi neutri), cio' che dipende dai record del gioco in un adattatore `Base\DelphiDoom.Engine.<Area>.Thinker` (l'unico posto con `{$IFDEF}` di gioco, come `Engine.Plat.Thinker`), facciata storica in copia unica in `Base\` senza `{$IFDEF}`. Record dei thinker, puntatori a funzione e firme invariati (`p_saveg` non toccato).

| Unit | Copie prima (righe) | Dopo | Classi nuove (`Libs\Thinkers`) | Adattatore del motore | Test nuovi | Golden 8 bit |
|---|---|---|---|---|---:|---|
| `p_scroll` | Doom 416, Strife 416 | `Base\p_scroll.pas` 376 | `TScrollStep`, `TScrollSpawner` | nessuno (record uguali) | 21 | parziale: d1_demo1, d1_demo2, d1_demo3 UGUALI; il resto da fare |
| `p_ceilng` | Doom 428, Heretic 335, Strife 452 | `Base\p_ceilng.pas` 310 | `TCeilingMachine`, `TCeilingGames` (+ `Ceiling.Types`) | `Engine.Ceiling.Thinker`; `Engine.Plane.Services` esteso (`P_ConfigureCeilings`) | 26 | da fare |
| `p_genlin` | Doom 1452, Strife 1431 | `Base\p_genlin.pas` 1449 | nessuna (testo spostato) | `Engine.Generalized.Rules`; riuso di `Engine.Door.Kinds` | 0 | da fare |
| `p_floor` | Doom 930, Strife 880 (Heretic 411: resta) | `Base\p_floor.pas` 805 | `TFloorMachine`, `TFloorGames` (+ `Floor.Types`) | `Engine.Floor.Thinker`; `Engine.Plane.Services` esteso (`P_ConfigureFloors`) | 22 | da fare |

Righe delle copie: 6740 prima, 2940 dopo piu' Heretic `p_floor` 411 (totale 3351); codice nuovo in `Libs\Thinkers` e negli adattatori: 1563 righe (intestazioni e documentazione XML comprese), test 3626 righe.

**Tabelle di confronto (routine per routine).**

- `p_scroll` (Doom/Strife): `T_Scroll`, `P_AddScroller`, `P_AddWallScroller`, `P_SpawnScrollers` tutte *uguali* (le due unit differivano solo nell'intestazione).
- `p_ceilng` (Doom/Heretic/Strife): `P_AddActiveCeiling`, `EV_CeilingCrushStop` *uguali*; `P_RemoveActiveCeiling` *parametrica* (`ceilingdata` o `specialdata`); `P_ActivateInStasisCeiling` *parametrica* (in Heretic era una procedura non esportata: ora e' la stessa funzione, il risultato non conta per il profilo); `T_MoveCeiling` *uguale* tra Doom e Strife, *parametrica* con Heretic (stesso codice ristretto ai suoi cinque generi, suono `sfx_dormov`, niente campi dei cambiatori di Boom); `EV_DoCeiling` *parametrica*: quattro interruttori (`TCeilingProfile`: velocita' dello schiacciatore rapido x2 o x4, `crushAndRaise` che schiaccia o no, `lowerAndCrush` di Strife che schiaccia e arriva al pavimento, risveglio dalla stasi che conta come "fatto") piu' il controllo del settore occupato (`P_SectorActive` o `specialdata`).
- `p_genlin` (Doom/Strife): `EV_DoGenFloor`, `EV_DoGenCeiling`, `EV_DoGenLift`, `EV_DoGenCrusher` *uguali*; `EV_DoGenStairs` *parametrica* (il passo prima o dopo il controllo del settore occupato: solo le vecchie demo di Doom); `EV_DoGenLockedDoor`, `EV_DoGenDoor` *parametriche* (nomi dei generi `gen*`/`vld_gen*`, suoni di apertura e chiusura); le costanti MBF21 `DEATH_MASK`/`KILL_MONSTERS_MASK` erano solo in Doom (restano: le usa il suo `p_spec`).
- `p_floor` (Doom/Strife/Heretic): `T_MovePlane` *parametrica* (regole di `TPlaneRules`); `T_MoveFloor` *uguale* tra Doom e Strife, *propria* in Heretic (`specialdata`, suono di arresto solo per i gradini, nessun blocco delle scale); `T_MoveElevator`, `EV_DoChange`, `EV_DoElevator` *uguali* tra Doom e Strife, assenti in Heretic; `EV_DoFloor` *parametrica* tra Doom e Strife (`turboLower` senza gli 8 in piu', `raiseFloor64` e `raiseFloor512AndChange` solo in Strife, `raiseToTexture` con il ramo delle vecchie versioni solo in Doom), *propria* in Heretic (ricerca del modello di `lowerAndChange` scritta a mano, niente `oldspecial`); `EV_BuildStairs` *parametrica* tra Doom e Strife (in Strife: tag del primo settore azzerato, primo gradino lasciato di genere 0 e senza schiacciamento, `buildDown16`; in Doom lo schiacciamento dipende dalla versione), *propria* in Heretic (firma `(line, step)`); `EV_DoDonut` *parametrica* (Doom ha in piu' il donut delle versioni fino alla 1.15; quello nuovo e' *uguale*).

**Riusato**: `TPlaneMover`/`TPlaneRules`/`PlaneMove` (il passo), `TPlatGame` e `TPlatGames.TryFromName` con `TGameAliases` (il gioco del profilo: nessun secondo elenco di giochi), `DoorKindFromNeutral` di `Engine.Door.Kinds` (generi delle porte generalizzate), `TFixedMath` e le tabelle di `Libs\MathCore`, `ComposePlanes` e `Engine.Plane.Services` (estesi con sole aggiunte), `TFakePlaneHost`/`TestNumberIn` dei test. **Nuovo e perche'**: le classi `Scroll.*`, `Ceiling.*`, `Floor.*` (nessuna classe esistente decideva cosa segue un passo di soffitto o pavimento ne' i valori di `EV_DoCeiling`/`EV_DoFloor`: `TPlaneMover` e' solo il passo, `TPlatMachine` e `TDoorRunner` sono piattaforme e porte); gli adattatori `Engine.Ceiling.Thinker`, `Engine.Floor.Thinker`, `Engine.Generalized.Rules` (gli adattatori esistenti convertono `plattype_e` e `vldoor_e`, non `ceiling_e`, `floor_e`, `stair_e`). Niente host a interfaccia nuovi: la facciata chiama metodi statici e fa lei suoni e rimozioni.

**Verifica**: dieci giochi Release Win32 con gli avvisi della base (383/382/383/333/305/255/200/150/414/341) dopo ogni unit; `strumenti` Release 13 su 13; Doom32 e Strife32 Win64 compilano (406 e 442 avvisi); `DelphiDoom.Tests.Thinkers` 256 -> 325 test, verdi a Win32 e a Win64; prova per mutazione sul soffitto (velocita' rallentata + 1: 4 test rossi). **Golden non conclusi**: il lock globale delle esecuzioni era occupato da altri lavori; fatte solo 3 voci di Doom con il solo `p_scroll` (UGUALI) e 1 di Heretic (`a_h_e1m1`) con lo stato finale dei quattro commit (UGUALE). Le altre 40 voci, e quindi la conferma di `p_ceilng`, `p_genlin` e `p_floor` nel motore, si fanno sul ramo unito (eseguibili dello stato finale conservati in `C:\ddparB2e\exe\floor`). **Non misurato**: le prestazioni a coppie (macchina occupata: da fare sul ramo unito).

**Rami che il corpus non esercita di sicuro** (la prova e' il test di parita' col vecchio codice o il testo spostato): scorrimenti di Boom con settore di controllo e accelerazione, trasporto sott'acqua; schiacciatori silenziosi e generalizzati, cambiatori di soffitto e di pavimento, stasi e risveglio dei soffitti; scale `turbo16` e `buildDown16`, donut, ascensori, `raiseToTexture`, `lowerAndChange`, i rami delle versioni di Doom fino alla 1.15 (pavimenti, scale, donut vecchio); tutte le linee generalizzate (`p_genlin`: nessun test di unita', solo testo spostato e golden).

**Resta**: `Heretic\p_floor.pas` (da portare su `TFloorMachine`: serve `raiseBuildStep` e il modello di `lowerAndChange` di Heretic nel profilo); il residuo di `p_plats`, `p_lights` (tre facciate quasi uguali) e `p_telept` non toccato; `Base\udmf_ceilng.pas` e `Base\udmf_floor.pas` ripetono la **struttura** di `p_ceilng`/`p_floor` (elenco degli attivi, tic su/giu', `case` dei generi, stasi) con altri generi (`CLEV_*`, `FLEV_*`), altro elenco (`hactiveceilings`) e le sequenze sonore: non unificati (non banale: i generi e i suoni sono diversi; la via e' un secondo profilo di `TCeilingMachine`/`TFloorMachine`).