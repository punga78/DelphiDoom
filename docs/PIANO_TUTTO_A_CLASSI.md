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
