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
| 1 freddo | **in corso** (80 unit su 181 usavano già classi). **Fetta 1a fatta** (#185, 2026-11-13, la fetta di prova): `hu_stuff` 2026 -> 1172 righe e `hu_lib` 761 -> 68 sono facciate sopra `Libs\Hud` (18 unit, 15 classi, 2453 righe) e `Base\DelphiDoom.Engine.Hud.*` (4 unit, 864 righe) + `ComposeHud`; 168 test (4940 righe di test, di cui 1308 di copia del vecchio codice per la parita'), copertura 100% della libreria; 88 confronti su 88 uguali ai golden, 18 su 18 uguali con configurazione diversa (`drawfps`, mirino, vista ridotta), dieci eseguibili compilati con meno avvisi di prima. Stima, costi e raccomandazioni per le altre fette: rapporto della fetta e `Libs\Hud\CLAUDE.md` |
| 1d (nel piano 1c) i_* | **fatta** (#185, 2026-11-13): censimento nel paragrafo qui sotto; Libs\EngineSystem (20 unit, 19 classi, 2357 righe) + Base\DelphiDoom.Engine.System.* (2 unit) + facciate; 116 test, copertura 93%; dieci eseguibili, quattro ddc_*, Launcher, DD_IDE e DD_Tools compilano (un avviso in meno per eseguibile); verifica a runtime a carico dell'agente di verifica (Tools\Verifica\185\Fetta-1d.txt) |
| 2 logica | da fare (thinker di luci, porte, piattaforme, teletrasporti già a classi in `Libs\Thinkers`) |
| 3 renderer software | da fare (`Libs\Renderer` ha le prime fette fredde) |
| 4 renderer OpenGL | in corso (#177: fatte 0-5 in parte, 8, 9) |
| 5 chiusura | da fare |

### Fetta 1d: censimento e costi (i_*)

Censimento (master cb5a45e3, 3224 righe in nove unit): **8 delle 13 unit i_* usavano gia' classi** e la logica procedurale rimasta era poca. i_threads (216 righe) e i_tmp (130) sono gia' facciate sottili sopra Libs\Threading e Libs\Platform: restano storiche (TDThread e' gia' una classe, ThreadInc/ThreadSet un Interlocked; i fili del renderer le usano). i_system (1232 righe) era gia' per l'80% una riga su una libreria (clock, piattaforma, input, log); la logica vera era I_Destroy (sequenza di uscita), I_Error (guardia, ordine), I_DetectCPU e il resto era chiamate a Windows (PeekMessage, PostMessage, GetSystemMetrics, ShellExecuteA caricata a mano). i_io (259) aveva il buffer dello stdout e i nomi dei log; i_net (155) il parsing della riga di comando; i_mikplay (258) una classe travestita da routine con un flag; i_midi (319) lo smistamento tra due player; i_midi_legacy (417) un player MCI con una finestra nascosta e variabili globali; i_crashlog (238) il filtro delle eccezioni. Dipendenti da Windows e quindi in adattatori: MCI e la finestra di notifica, WriteFile/IsBadReadPtr/SetUnhandledExceptionFilter, InvalidateRect.

**Costi.** Righe delle facciate (prima -> dopo): `i_net` 155 -> 124, `i_io` 259 -> 221, `i_crashlog` 238 -> 64, `i_mikplay` 258 -> 214, `i_midi_legacy` 417 -> 252, `i_midi` 319 -> 334 (la scelta dei player esce, entra il collegamento), `i_system` 1232 -> 1212; `i_threads` e `i_tmp` invariate. In totale le sette unit passano da 2878 a 2421 righe; `Libs\EngineSystem` e' di 2357 righe in 20 unit (19 classi e i tipi), `Base\DelphiDoom.Engine.System.*` di 238 in 2 unit, i test di 4009 righe (881 di copie del vecchio codice) con 116 test e 8 scenari casuali di parita' vecchio/nuovo. Il guadagno in righe non c'e' (la fetta era quasi tutta gia' delegata e ogni routine storica ha il suo riquadro di commento): il guadagno e' la parita' provata, le classi sostituibili nei test (sequenza di uscita, errori, MCI, crash) e i difetti trovati.

**Difetti trovati nel vecchio codice**: TDStringList.Put di d_delphi ignora l'indice 0 (la prima riga dello stdout non cresce mai: conservato, da correggere a parte); -net o -dup con argomento vuoto leggevano una stringa nil (violazione di accesso); la notifica di fine canzone del player legacy con la lista vuota dava un errore; ShutDown del player legacy lasciava un puntatore a una lista liberata; strutture MCI non inizializzate.
