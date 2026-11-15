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
| 1 freddo | **in corso** (censimento di chiusura e resto: par. 12; 80 unit su 181 usavano già classi). **Fetta 1a fatta** (#185, 2026-11-13, la fetta di prova): `hu_stuff` 2026 -> 1172 righe e `hu_lib` 761 -> 68 sono facciate sopra `Libs\Hud` (18 unit, 15 classi, 2453 righe) e `Base\DelphiDoom.Engine.Hud.*` (4 unit, 864 righe) + `ComposeHud`; 168 test (4940 righe di test, di cui 1308 di copia del vecchio codice per la parita'), copertura 100% della libreria; 88 confronti su 88 uguali ai golden, 18 su 18 uguali con configurazione diversa (`drawfps`, mirino, vista ridotta), dieci eseguibili compilati con meno avvisi di prima. Stima, costi e raccomandazioni per le altre fette: rapporto della fetta e `Libs\Hud\CLAUDE.md`. **Fetta 1b codice e test fatti** (#185, 2026-11-13: `sc_tokens`, `sc_consts`, `sc_params`, `sc_states`, `info_common`, `info_fnd`, `info_rnd`, `info_export`, `deh_base`; vedi il censimento qui sotto; verifica a runtime: `Tools\Verifica\185\Fetta-1b.txt`) |
| 1d (nel piano 1c) i_* | **fatta** (#185, 2026-11-13): censimento nel paragrafo qui sotto; Libs\EngineSystem (20 unit, 19 classi, 2357 righe) + Base\DelphiDoom.Engine.System.* (2 unit) + facciate; 116 test, copertura 93%; dieci eseguibili, quattro ddc_*, Launcher, DD_IDE e DD_Tools compilano (un avviso in meno per eseguibile); verifica a runtime a carico dell'agente di verifica (Tools\Verifica\185\Fetta-1d.txt) |
| 1 freddo, **fetta 1e** (avanzi meccanici di `Base\`) | **fatta** (#185, 2026-11-13). Censimento delle 15 unit (3833 righe, quasi tutto tipi e dati): **trasformate** `mt_utils` (1347 -> 764 righe, facciata sopra `TWorkerJobRunner`, `TWorkerMemoryRunner`, `TWorkerTaskScheduler` di `Libs\Threading`), `c_utils` (219 -> 69, `TConsoleUtilityCommands` in `Libs\Console`) e `d_notifications` (129 -> 100, `TDeferredNotifications` in `Libs\Video`); **gia' facciate o delegate** a classi dalle ondate precedenti: `c_cmds` (registro e interprete di `Libs\Console`), `c_con` (tiene 4 variabili; la console e' `TEngineConsoleScreen`), `nd_main` (i nodi sono `Libs\Nodes`; restano i tipi dei record GL e `gld_GetGLVertexes` che chiama `TNodesGlParser`); **restano storiche, solo tipi o dati**: `doomtype` (costanti e due funzioni `smallintwarp`), `doomdata` (record dei lump WAD, packed: formato su disco), `d_ticcmd` e `d_event` (`ticcmd_t`, `event_t`: record di rete, demo e salvataggi, non cambiano di un byte), `d_think` (`think_t` e `thinker_t`: puntatori a funzione salvati grezzi da `p_saveg`, regola dei thinker), `d_net_h` (costanti), `d_net` (due variabili e una stringa), `tables` (tabelle seno, tangente, arcotangente: percorso caldo, restano costanti accedute per indice, stesso costo; `SlopeDiv`/`AngleToSlope` sono funzioni pure di una riga, usate dal renderer), `vx_base` (il registro che i renderer leggono per ogni voxel: vedi `docs\PENDING_ISSUES.md`). Nuovo: 36 test in `Libs\Threading` (82 in tutto, copertura 97%), 10 in `Libs\Console` (185, 96%), 7 in `Libs\Video` (75, 98%); parita' sul vecchio codice copiato in `Tests\Source\DelphiDoom.Tests.Threading.Legacy.pas` e nel test di `UtilityCommands`. Verifica di runtime e confronti con i fili accesi: `Tools\Verifica\185\Fetta-1e.txt` (da fare da un agente di verifica) |
| 1 freddo, **chiusura** (`f_wipe`, `s_sound`, `am_map`, censimento di tutto il resto) | **censimento fatto, tre famiglie toccate** (#185, 2026-11-14; par. 12). `f_wipe` 354 -> 260 righe sopra `TImagingMeltWipe` (`Libs\Imaging`, riusata ed estesa con `StartOnBuffers`); `s_sound` 2297 -> 2135 con `TSfxAttenuation`, `TSfxChannelPicker`, `TExternalMusicNames` (`Libs\Audio`, 404 righe nuove); `am_map` 2315 -> 2263 con `TAutomapLineRasterizer` (`Libs\Automap`, 201 righe). Test: Imaging 216 -> 220, Audio 301 -> 341, Automap 65 -> 72, con le copie del vecchio codice (`OldWipe`, `OldSound`, `OldMusicNames`, `OldLine`, 812 righe) e parita' su scenari casuali; copertura Imaging 98%, Audio 99%, Automap 100%, le cinque unit nuove o estese 100%. Build: dieci giochi con 382/381/382/332/305/255/200/150/413/340 avvisi (base 383/382/383/333/305/255/200/150/414/341: uno in meno dove e' sparito `S_GetListFromAlias`), zero nel codice nuovo; strumenti (`ddc_*` 381/304/199/412, Launcher 9, DD_IDE 24, DD_Tools 0) e `Doom32`/`Strife32` a Win64 compilano. Golden: sugli eseguibili di `0046420a` solo `d1_demo1` a 8 e a 32 bit, UGUALE (stato e fotogrammi); il resto del corpus non e' stato eseguito da chi ha scritto il codice (sei agenti in coda sul lock dei giochi, circa mezz'ora per voce): la verifica passa al responsabile sul ramo unito. **Non verificato a runtime**: l'automap aperta (nessuna chiave di configurazione la apre e l'input e' chiuso), il wipe degli eseguibili OpenGL, la musica mp3 esterna, le voci di Strife con tutti i canali occupati; misura a coppie non fatta (macchina occupata): i punti dove guardare sono `S_UpdateSounds` (una chiamata statica per canale e per tic) e il wipe (un `Advance` per fotogramma) |
| 2 logica | **in corso** (#185, 2026-11-14): progetto nel par. 10; fatti 2a, 2e-1, 2c-1 (`p_map`), 2c-2, 2c-3 e 2c-4 (`p_mobj` e `p_map`: il testo che resta del gioco ha la ragione scritta nel par. 11.5) 2f-1 (`p_user`: par. 11.6) e 2f-2 (`p_inter`: par. 11.7); stato, verifica e prossimi sottosistemi nel par. 11.0 e 13 |
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

### 11.0 Riepilogo del giro del 2026-11-14 e prossimi sottosistemi

Stato sul ramo `worktree-agent-af54720ab9045a4f7` dopo l'unione di `master` (`a5a1ea6b`: Rad-X #169, #110, #120, #175, #194).

| Passo | Cosa | Copie prima -> dopo (righe) | Golden per passo (ridotto, 8 bit) |
|---|---|---|---|
| 2a | `TEngineWorld`, `TThinkerList` (`Libs\Thinkers`), `IGameContext` esteso | `p_tick` 362 -> 353 (era gia' in copia unica) | 4 voci su 4 UGUALI |
| 2e-1 | `p_scroll`, `p_ceilng`, `p_genlin`, `p_floor` (Doom e Strife) in copia unica | 6740 -> 2940 (+ `Heretic\p_floor` 411 che resta) | 4 su 4 UGUALI |
| fase 1 | `f_wipe`, regole di `s_sound`, linee di `am_map` (par. 12) | 4966 -> 4658 | 4 su 4 a 8 bit, Doom e Strife a 32 bit UGUALI |
| 2c-1 | `p_map` in copia unica, `TMapGameRules` per gioco | 14079 -> 7769 | 12 su 12 UGUALI |
| 2c-2 | `p_mobj` in copia unica (parziale: 18 routine su 52), `TMobjGameRules` | 11673 -> 10349 | 12 su 12 UGUALI |
| 2c-3, 2c-4 | il resto di `p_mobj` e di `p_map` (par. 11.4 e 11.5) | solo 2c-4: `p_mobj` (con regole e unit nuove) 10588 -> 10403 (-185), `p_map` (con le regole) 7418 -> 7356 (-62) | 4 su 4 UGUALI a ogni tappa, corpus intero 44 su 44 a 8 bit e 27 su 27 a 32 bit |

**Verifica finale sul ramo unito** (eseguibili compilati dopo `git merge master`):

- Build Release Win32: dieci eseguibili, errori 0, avvisi 382/381/382/332/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32; base 383/382/383/333/305/255/200/150/414/341). Doom32 e Strife32 Release Win64 compilano (405 e 441 avvisi; non avviati).
- **Corpus intero dei golden: 44 voci su 44 UGUALI a 8 bit** (Doom 21, Heretic 9, Hexen 8, Strife 6: stato per tic e fotogrammi) e **27 su 27 UGUALI a 32 bit** (Doom 21, Strife 6). Cartella di lavoro `C:\ddparity_185` (non `C:\ddparity`, in uso da un altro lavoro nello stesso momento); le due voci di Freedoom che possono dipendere dal percorso (`a_f2_map10`, `f2_demo2`) sono risultate UGUALI anche li'.
- Suite a Win32: Thinkers 352/352, Imaging 220/220, Audio 341/341, Automap 72/72, Console 369/369, DynLights 39/39, Net 244/244. Copertura misurata con DelphiCodeCoverage: `Libs\Thinkers` 98% (1414 righe su 1438, 44 unit; `TThinkerList` 99%); Imaging 98%, Audio 99%, Automap 100% (misurate nel ramo della fase 1).
- Radix32 `-devparm -nomusic -nosound -warp 1 1` (RADIX.DAT 2.0 shareware): carica E1M1 (precache di texture, sprite e suoni), vivo dopo 40 secondi, nessun `crash.txt` ne' `I_Error`. Non guardato a schermo.
- **Misura a coppie: NON conclusiva** (da rifare a macchina scarica; nessun passo e' dichiarato entro il 5%). Doom32 `demo1`, 8 bit, 5 coppie, eseguibile di `c57fbf77` contro quello finale: (a) dopo 2c-1: vecchio mediana 235, nuovo 231 (mediane -1,70%, minimi -3,85%), rifiutata per dispersione del vecchio 3,85% e CPU al 50%; (b) finale: vecchio minimo 195 mediana 210, nuovo minimo 199 mediana 199 (mediane -5,24%, minimi +2,05%), rifiutata per dispersione del vecchio 23,08% e CPU al 48-72%. Il "nuovo" finale contiene anche le unioni di `master`. Gli eseguibili sono in `C:\ddref185` (`Doom32.exe` di partenza, `fin\Doom\Doom32.exe`).
- **Test DUnitX**: le classi nuove di libreria hanno i loro test (lista dei thinker, scorrimenti, soffitti, pavimenti, wipe, attenuazione e canali, nomi mp3, linee dell'automap). Non hanno test di unita', e la loro prova sono i golden e la prova meccanica sul testo: `TEngineWorld`, gli adattatori `Engine.Ceiling.Thinker`, `Engine.Floor.Thinker`, `Engine.Generalized.Rules`, `TEngineImagingRandom` e le unit delle regole `TMapGameRules`/`TMobjGameRules` (testo del gioco spostato, legato ai record del motore).
- **Non verificato**: salvataggi (non toccati, non provati), rete, avvio dei giochi OpenGL, di SpeedHaste32 e di qualsiasi eseguibile Win64, suite a Win64 dopo l'unione, rami che il corpus non esercita (elencati nei par. 11.1-11.3 e 12).
- **Passi annullati**: nessuno. Il commit `1134d540` (tappa A di `p_map`) da solo ha un difetto di risoluzione di `P_ThingsInSameZ` in Doom, corretto da `d37a3575`: non va usato come punto di bisezione.

**Prossimi sottosistemi (ordine; aggiornato dalla 2c-3: l'elenco valido e' nel par. 13)**:

1. **Resto di `p_mobj`**: `P_ZMovement` (quattro versioni con lo stesso lavoro in ordine diverso nel ramo del pavimento: serve una demo per gioco che lo eserciti prima di riordinare), `P_SpawnPlayer`, `P_SpawnMapThing` (da appoggiare a `ILevelThingRules`, che c'e' gia'), i tre `P_SpawnMissile*`, `P_SpawnPuff`, `P_HitFloor`, `P_NightmareRespawn`, `P_SetMobjStateNF`.
2. **Resto di `p_map`**: `P_CheckForPushSpecial`, `PIT_ChangeSector`, la coda di contatto di `PIT_CheckThing`.
3. **`p_user`** (35 routine: 5 uguali, 12 parametriche, 18 proprie), stessa forma (`TUserGameRules`).
4. **`p_inter`** (39: 5, 16, 18) e il nucleo comune di **`p_enemy`** (381 routine, 344 proprie: solo `P_LookForPlayers`, `P_Move`, `P_NewChaseDir`, `A_Chase` e simili; il resto e' un gruppo di azioni per gioco in `Libs\Actions`) e di **`p_pspr`**.
5. **`p_spec`** (50: 19 uguali, 19 parametriche) e **`p_switch`**, con `Libs\Specials`.
6. Thinker rimasti: `Heretic\p_floor`, le tre facciate di `p_plats` e `p_lights`, `p_telept`, `p_doors`; `udmf_ceilng`/`udmf_floor` come secondo profilo di `TCeilingMachine`/`TFloorMachine`.
7. **Stadio 2 dello stato** (par. 10.3) e `g_game`/salvataggi (2h): solo quando `p_saveg`/`sv_save` saranno liberi.

Per ogni passo: `Confronta-Copie.ps1 -Unit <unit>` per la tabella, prova meccanica (`Prova-Common.ps1`), `Verifica-Ridotta.ps1` a ogni tappa, corpus intero una volta sul ramo unito, misura a coppie a macchina scarica.

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

### 11.2 Passo 2c-1: `p_map` in copia unica (ramo `worktree-agent-af54720ab9045a4f7`, 2026-11-14)

Tre commit, uno per tappa (`1134d540` routine uguali e parametriche piccole, `d37a3575` `PIT_CheckLine*`, `P_TryMove`, `P_ThingsInSameZ`, `16d21f20` `PTR_ShootTraverse`, testa di `PIT_CheckThing`, prova meccanica), piu' quello dei documenti. Nessuna tappa annullata.

**Forma.** `Base\p_map.pas` e' l'unica copia: stessa API per i chiamanti, nessun `{$IFDEF}` di gioco (restano i quattro `{$IFDEF FPC}` storici), le variabili globali `tm*`, `floatok`, `spechit`, `linetarget`... dove erano. Cio' che cambia per gioco e' **strategia calda** (par. 10.4): `TMapGameRules`, classe `sealed` di soli metodi `class ... static` (`inline` quelli di una riga) e costanti, nella unit `DelphiDoom.Engine.World.MapRules.pas` che esiste con lo stesso nome in `Doom\`, `Heretic\`, `Hexen\`, `Strife\` ed e' scelta dal percorso del progetto (`Radix32` e `SpeedHaste32` prendono quella di `Doom\`; `p_map` non aveva rami `RADIX`/`SPEED`). Nessuna chiamata virtuale ne' a interfaccia. I tipi e i campi che cambiano per gioco (`mobjtype_t`, `flags2`, `MF_SKULLFLY`, `MF_TELEPORT`, `MF_PICKUP`, `floorpic`, `special1`, `SPAC_*`/`ULAC_*`...) si nominano solo li'. Una differenza che e' un dato e' una costante della classe (8: `SlopesVersion`, `TeleportSetsZ`, `SkyHackPuffInCompatibility`, `NoSpecHitFlags`, `PushesLinesWhenBlocked`, `DropoffHeight`, `JumpDownMargin`, `SlideStepMargin`); le altre sono 49 metodi. Dove il blocco di un gioco e' lungo (linee che bloccano, contatto tra cose, cosa colpita da un colpo) la regola e' il **testo vecchio alla lettera** dentro un metodo che da' il valore con cui la routine prosegue. Le routine che ha un gioco solo stanno nella stessa unit, esportate con il nome di prima; le liste dei settori toccati da una cosa (Boom: `msecnode_t` esiste solo in Doom e Strife) stanno in `Base\p_secnodes.pas`, che solo quei progetti compilano.

**Righe.** Prima: Doom 3581, Heretic 3166, Hexen 3904, Strife 3428 (14079). Dopo: `Base\p_map.pas` 2778, `Base\p_secnodes.pas` 355, unit delle regole Doom 1105, Heretic 916, Hexen 1555, Strife 1060 (7769 in tutto; in ogni unit delle regole circa 135 righe sono la dichiarazione documentata della classe).

**Tabella di confronto** (`Tools\Verifica\185\Confronta-Copie.ps1 -Unit p_map`: 49 routine, 13 uguali, 26 parametriche, 10 proprie; la lettera dice quali copie erano uguali tra loro, il numero le righe) **e decisione**:

| Routine | Doom | Heretic | Hexen | Strife | Diff | Decisione |
|---|---|---|---|---|---:|---|
| `P_CheckForPushSpecial` | A10 | B10 | C10 | B10 | 8 | *propria* per gioco (10 righe; in Hexen altro campo dei flag e altre costanti di attivazione): unit del gioco |
| `PIT_StompThing` | A74 | B73 | B73 | C77 | 2 | unica; regola `CanStomp` |
| `P_TeleportMove` | A85 | B85 | B85 | C86 | 13 | unica; `PointInSector`, `TeleportSetsZ`, `MarkJustAppeared` |
| `PIT_CheckLine` | A133 | B132 | C125 | D139 | 29 | unica; il blocco di chi non e' un proiettile e' `CheckLineBlocking` (testo del gioco), `BlastedHitsWall` |
| `PIT_CheckLineTM` | A142 | B142 | C133 | D131 | 32 | unica; `CheckLineBlockingTM`, `BlastedHitsWall` |
| `P_ThingsInSameZ` | A52 | B40 | B40 | B40 | 23 | unica: testo di Doom con `KeepsOldSameZ` (falso negli altri giochi) |
| `P_ThingHeightOffsZ`, `P_ThingsInSameZ206` | - | A7, A34 | A7, A34 | A7, A34 | 0 | assorbite da `P_ThingsInSameZ` (erano i suoi due rami scritti a parte) |
| `P_BloodType` | A35 | - | - | - | 0 | *propria* di Doom, esportata dalla unit di Doom con `bloodtype_t` e `p_confcoloredblood` |
| `PIT_CheckThing` | A336 | B308 | C501 | D270 | 232 | **a meta'**: la testa (108 righe, uguale nei quattro salvo `SlopesVersion`) e' unica; il contatto e' `CheckThingContact` del gioco, testo vecchio alla lettera (Doom 228 righe, Heretic 201, Hexen 393, Strife 163) |
| `P_CheckPosition` | A126 | B129 | C137 | D131 | 15 | unica; `PointInSector`, `BeginCheckPosition`, `NoClipSkipsThings`, `NoClipSkipsLines`, `ClearBlockingThing`, `SlopesVersion` |
| `P_FakeZMovement` | A69 | B68 | B68 | - | 5 | unica; `IsSkullFlying`, `FlightBobs`, `HasLowGravity` (in Strife compila e nessuno la chiama) |
| `PIT_CheckOnmobjZ` | A39 | A39 | A39 | - | 0 | *uguale*: spostata |
| `P_CheckOnmobj` | A78 | B78 | B78 | - | 8 | unica; `PointInSector` |
| `P_TryMove` | A220 | B216 | C262 | D232 | 61 | unica; `StepsOnBlockingThing`, `PushesLinesWhenBlocked`, `IgnoresCeilingFit`, `FlightBlocked`, `StepTooHighOnFoot`, `IgnoresStepHeight`, `MissileStepTooHigh`, `DropoffHeight`, `JumpDownMargin`, `IgnoresDropoff`, `CannotLeaveFloorPic`, `StoreFloorPic`, `UpdateFloorClip`, `NoSpecHitFlags`, `CrossSpecialLine`, `BlastedHitsWall` |
| `P_ThingHeightClip` | A26 | A26 | B29 | A26 | 3 | unica; `StoreFloorPic`, `SnapsToFloor` |
| `P_HitSlideLine`, `P_SlideMove` | A49, A104 | = | = | = | 0 | *uguali*: spostate |
| `PTR_SlideTraverse` | A76 | B78 | B78 | C77 | 2 | unica; `SlideStepMargin`; tolte le due assegnazioni a `secondslidefrac`/`secondslideline` di Heretic e Hexen (mai lette) |
| `PTR_AimTraverse` | A121 | A121 | B127 | A121 | 5 | unica; `SkipsAimAt` |
| `PTR_ShootTraverse` | A238 | B236 | C243 | D269 | 40 | unica; `SkyHackPuffInCompatibility`, `SpawnWallPuff`, `ShootSpecialLine`, `ShotPassesThrough`, `ShotHitsThing` (testo del gioco) |
| `P_AimLineAttack` | A33 | A33 | A33 | B36 | 4 | unica; `AimOriginZ`, `NoTargetSlope` |
| `P_LineAttack` | A21 | B23 | C33 | D25 | 16 | unica; `AttackOriginZ`, `LineAttackFlags`, `LineAttackMissed` |
| `PTR_UseTraverse` | A36 | B33 | C68 | D36 | 61 | unica; `UseBlockedByWall`, `UseNonSpecialLine`, `UseSpecialLine` |
| `PTR_UseThingTraverse`, `P_UseLines` | A56, A29 | = | = | = | 0 | *uguali*: spostate |
| `PIT_RadiusAttack` | A104 | B104 | C119 | D112 | 18 | unica; `IsConcussionProof`, `OutOfBlast`, `BlastDamage` |
| `P_RadiusAttack` | A34 | A34 | B37 | C43 | 6 | unica, firma con i due parametri di Hexen resi facoltativi (`distance = 0`, `dmsource = true`); `SetBlastExtent`, `AfterRadiusAttack` |
| `P_RadiusAttackEx` | A34 | A34 | A34 | B43 | 6 | unica; `AfterRadiusAttack` |
| `PIT_RadiusAttackPlayer`, `P_RadiusAttackPlayer` | A86, A35 | = | = | = | 0 | *uguali*: spostate |
| `PIT_ChangeSector` | A132 | B76 | C98 | D112 | 54 | *propria* per gioco (quattro varianti diverse dall'inizio alla fine: cadaveri, oggetti caduti, sangue, uscite): unit del gioco |
| `P_DoChangeSector` | A51 | B12 | B12 | A51 | 27 | unica; `ChangeSectorByThingList` (Doom e Strife: `P_ChangeSectorNodes` di `p_secnodes` fuori dal modo di compatibilita') |
| `P_ChangeSector` | A17 | B17 | C17 | A17 | 2 | unica; `SlopesVersion` |
| `P_SectorJumpOverhead` | A21 | B29 | C27 | A21 | 10 | unica, firma di Heretic e Hexen (`p: Pplayer_t = nil`) per tutti; `HasFlightPower` |
| `P_AddSecnode`, `P_DelSecnode`, `PIT_GetSectors`, `P_CreateSecNodeList` | A43, A38, A39, A77 | - | - | = | 0 | *uguali* in Doom e Strife: `Base\p_secnodes.pas` con `sector_list` |
| `P_TestMobjLocation` | A21 | A21 | A21 | B15 | 6 | unica; `SuspendPickup`, `RestorePickup` |
| `P_PointInSectorVanilla`, `P_PointInSector` | A18, A7 | - | - | - | 0 | *proprie* di Doom: unit di Doom |
| `PIT_ThrustStompThing`, `PIT_ThrustSpike`, `PTR_PuzzleItemTraverse`, `P_UsePuzzleItem`, `PTR_BounceTraverse`, `P_BounceWall` | - | - | A30, A33, A71, A16, A50, A40 | - | 0 | *proprie* di Hexen: unit di Hexen (con `PuffSpawned`, `BlockingMobj`) |
| `P_CheckPositionZ` | - | - | - | A75 | 0 | *propria* di Strife: unit di Strife (con `blockingline`) |

In copia unica: 37 routine su 49 (31 in `Base\p_map.pas`, 4 in `Base\p_secnodes.pas`, 2 assorbite), contando `PIT_CheckThing` per la sola testa. Restano *proprie* e perche': `P_CheckForPushSpecial` e `PIT_ChangeSector` (una per gioco: le differenze sono tutto il corpo, una regola che le contenesse sarebbe la routine stessa), il contatto di `PIT_CheckThing` (le quattro code hanno pezzi in comune, i proiettili e le cose spinte, ma intrecciati a rami del gioco con estrazioni casuali: unificarli vuol dire riordinare del testo che le demo coprono solo in parte), e le dieci routine di un gioco solo.

**Chiamanti toccati** (solo una unit in piu' nella `uses`): `Base\m_defs.pas` (Doom: `p_confcoloredblood`), `Base\p_maputl.pas` (`p_secnodes` per Doom e Strife, le regole per `blockingline` di Strife), `Doom\g_game.pas`, `Doom\m_menu.pas`, `Radix\m_menu.pas`, `Doom\p_mobj.pas`, `Hexen\a_action.pas`, `Hexen\p_mobj.pas`, `Hexen\p_pspr.pas`, `Hexen\p_user.pas`, `Strife\p_mobj.pas`; i 14 `.dpr` che elencano `p_map`.

**Riuso.** Riusati senza toccarli: `Base\p_maputl.pas` (iteratori della blockmap, `P_PathTraverse`, aperture), `p_sight`, `p_slopes`, `p_3dfloors`, `p_gravity`, lo schema "stesso nome di unit in ogni cartella di gioco" del par. 10.4. Guardati e non adatti: `Libs\Blockmap` (costruisce e legge la blockmap come dati: gli iteratori sugli oggetti del motore sono in `p_maputl`), `Libs\MathCore` (gia' usata attraverso `m_fixed`/`tables`), `ILevelGameRules`/`T<Gioco>LevelRules` e `IGameContext` (interfacce: strategia fredda, non entrano in un ciclo per cella della blockmap). **Nuovo e perche'**: `TMapGameRules` nelle quattro cartelle (non esisteva una strategia calda: le regole esistenti sono interfacce o profili di dati dei thinker); `Base\p_secnodes.pas` (il codice dei secnode era in `p_map` e non puo' stare nella copia unica perche' Heretic e Hexen non hanno i tipi; e' codice storico spostato, per questo ha il nome storico); `Tools\Verifica\185\Prova-PMap.ps1`.

**Differenze dal vecchio** (nessuna voluta nel comportamento): (1) `P_RadiusAttack` e `P_SectorJumpOverhead` hanno in ogni gioco la firma piu' larga, con i parametri in piu' facoltativi; (2) variabili della sezione `implementation` passate all'interfaccia di `Base\p_map.pas` perche' le leggono le regole (`tmflags`, `bestslidefrac`, `bestslideline`, `slidemo`, `shootthing`, `shootz`, `la_damage`, `crushchange`, `nofit`; `tmbbox` lo era gia' in Doom e Strife) e funzioni ora esportate (`P_ThingsInSameZ`, `P_ThingHeightClip`, `PIT_CheckThing`); (3) in Hexen `topslope`/`bottomslope` della mira non sono piu' le variabili omonime di `p_sight` ma quelle di `p_map` (ogni uso le inizializza prima di leggerle e i due usi non si intrecciano: `PTR_AimTraverse` non chiama nulla che controlli la vista); (4) le assegnazioni mai lette a `secondslidefrac`/`secondslideline` tolte da `PTR_SlideTraverse`; (5) nelle routine con una regola una condizione senza effetti puo' essere valutata in un altro ordine (elenco nella prova meccanica); l'ordine delle estrazioni casuali non cambia in nessuna copia; (6) in Strife compilano `P_FakeZMovement`, `PIT_CheckOnmobjZ`, `P_CheckOnmobj` (nessuno le chiama). **Difetto introdotto e corretto nel giro**: nella tappa A `PIT_CheckThing` di Doom, spostata intera nella unit di Doom, chiamava `P_ThingsInSameZ` e il nome si risolveva nella variante degli altri giochi rimasta in `Base\p_map.pas` (diversa dalla 2.07 in poi quando nessuna delle due cose ha `MF2_EX_ONMOBJ`); `d1_demo1` non lo vede (demo vecchia). Corretto nella tappa B unificando `P_ThingsInSameZ`; da li' le unit delle regole hanno le `uses` nell'ordine delle vecchie `p_map` con `p_map` per ultima, e un controllo della risoluzione dei nomi (ogni identificatore usato nelle unit nuove, cercato nelle unit usate prima e dopo) non trova altri casi.

**Verifica.**

- Build `Tools\build.bat giochi Release`: 10 su 10, errori 0, avvisi 382/381/382/332/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32: uguali al limite dato); i quattro giochi software ricompilati dopo ogni tappa con gli stessi numeri. `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife` Release: errori 0, avvisi 381/304/199/412. `Doom32` e `Strife32` Release Win64: errori 0, avvisi 405 e 441 (406 e 442 al passo 2e-1).
- Test: `DelphiDoom.Tests.Thinkers` 352 su 352 prima di cominciare (ramo unito). Il passo non aggiunge test DUnitX: `p_map` e' legata ai record del motore, la prova e' il golden e la prova meccanica.
- Golden a 8 bit (`Verifica-Ridotta.ps1` dopo ogni tappa, poi `Confronta-Golden.ps1` voce per voce, cartella `C:\ddparity_185`), 12 voci su 44 con lo stato finale, tutte UGUALI: Doom `d1_demo1`, `d1_demo3`, `a_f2_map07`; Heretic `a_h_e1m1`, `a_h_e1m3`, `a_h_e1m8`; Hexen `a_x_map01_f`, `a_x_map02_m`, `a_x_map03_f`; Strife `a_s_map32`, `a_s_map33`, `a_s_map34`. Le altre 32 voci e la misura a coppie (`Misura-Coppie.ps1`) **non fatte** (lock dei giochi conteso; eseguibili finali di Doom32 e Heretic32 in `C:\ddref185\s2c\`).
- **Prova meccanica** (`Tools\Verifica\185\Prova-PMap.ps1`): per ogni gioco ricostruisce ogni routine della vecchia `p_map` dalla copia unica, sostituendo ogni chiamata a `TMapGameRules` con il corpo della regola di quel gioco (tabella scritta a mano nello script; i corpi lunghi letti dalla unit del gioco), e la confronta col testo vecchio preso da `git show 7bcb9a13` tolti commenti, spazi e maiuscole. 153 routine (Doom 40, Heretic 35, Hexen 41, Strife 37): **108 UGUALI**, **34 uguali dopo una riscrittura dichiarata** nella tabella con il suo perche' (il settore letto una volta invece del sottosettore letto tre volte; il parametro facoltativo in piu'; una condizione senza effetti spostata; lo sbuffo sui muri del cielo scritto con due uscite; il ramo dei secnode in `p_secnodes`; le parentesi in piu' di Heretic; le assegnazioni mai lette), **11 non testuali** (l'equivalenza e' un ragionamento scritto nello script: `P_ThingsInSameZ` con le due routine assorbite in Heretic, Hexen e Strife; `PTR_UseTraverse` e `P_SectorJumpOverhead` di Hexen), **0 diverse**. Limite: la tabella prova che lo scheletro unico piu' le sostituzioni da' il testo vecchio; che il corpo delle regole scritte a mano (quelle di una riga) sia la sostituzione della tabella e' una rilettura, non un confronto automatico.

**Rami che le dodici demo non esercitano di sicuro** (prova: testo spostato e prova meccanica): gioco in rete (mira che salta i compagni in Hexen), 3D floor e pendenze, oggetti puzzle e rimbalzi di Hexen, cose scagliate (`MF2_BLASTED`), lampi e spiriti di Hexen nel contatto, volo e pavimenti obbligati, spettrali e Mauler di Strife, vetri rotti dalle esplosioni di Strife, sangue colorato e proiettili che trapassano (MBF21) di Doom, `P_RadiusAttackEx`, `P_RadiusAttackPlayer`, schiacciamento con le liste dei settori nei casi limite, nodi originali di Doom fuori da `d1_demo1`/`d1_demo3`.

**Non verificato.** Misura a coppie; corpus intero (32 voci); modo a 32 bit (il passo non disegna); `Radix32`, `SpeedHaste32`, i quattro giochi OpenGL e i `ddc_*` compilati ma non avviati; Win64 compilato e non avviato; salvataggi (non toccati, non provati); se il compilatore espande davvero in linea i metodi `inline` di `TMapGameRules` dentro `p_map` (le due unit si usano a vicenda dalla sezione `implementation`: dipende dall'ordine di compilazione; il comportamento non cambia, il costo si vede con la misura a coppie).

**Resta** (passi successivi): il contatto di `PIT_CheckThing` e `PIT_ChangeSector` per gioco; le variabili `tm*` sono ancora globali (stadio 1 del par. 10.3: vanno nel contesto del mondo con `p_mobj`, passo 2c-2); `p_secnodes` e' codice storico spostato, non una classe.

### 11.3 Passo 2c-2: `p_mobj` in copia unica (ramo `worktree-agent-af54720ab9045a4f7`, 2026-11-14)

Tre commit, uno per tappa (`15cf1b88` stato, rimozione, rinascita degli oggetti e missili piccoli; `deec971e` `P_XYMovement`, `P_MobjThinker`, prova meccanica; `615c37db` `P_SpawnMobj`), piu' quello dei documenti. Nessuna tappa annullata. **Il passo e' parziale**: 9 routine restano del gioco (vedi "Resta proprio").

**Forma.** La stessa di `p_map` (par. 11.2). `Base\p_mobj.pas` e' l'unica `p_mobj`: stessa API, nessun `{$IFDEF}` di gioco, `P_MobjThinker` e' una procedura sola con quel nome (l'indirizzo che `p_tick`, i salvataggi e le altre unit confrontano); `mobj_t` e i record salvati non sono toccati. Cio' che cambia per gioco e' **strategia calda**: `TMobjGameRules`, classe `sealed` di soli metodi `class ... static` e costanti, nella unit `DelphiDoom.Engine.World.MobjRules.pas` che esiste con lo stesso nome in `Doom\`, `Heretic\`, `Hexen\`, `Strife\` (sono le vecchie `p_mobj.pas` rinominate con `git mv`: il testo che resta del gioco non e' stato toccato; `Radix32` e `SpeedHaste32` prendono quella di `Doom\`; `p_mobj` non aveva rami `RADIX`/`SPEED`). Nessuna chiamata virtuale ne' a interfaccia. Le regole sono 57 metodi e 4 costanti (`SeekerNeedsSpeed`, `NoFrictionFlags`, `CyclesStatesWhileNoTics`, `MonstersRespawn`). Tre regole servivano gia' a `p_map` e **non sono duplicate**: `TMapGameRules.PointInSector`, `SlopesVersion` (la versione da cui i missili che strisciano partono dal pavimento della sorgente: stesso numero per gioco) e `IsSkullFlying`. Una routine che e' tutta di un gioco ma ha lo stesso nome nei quattro (`P_SpawnPuff`, `P_HitFloor`...) e' un **metodo delle regole con il testo del gioco**, e `Base\p_mobj.pas` ha la routine con quel nome che lo chiama: nessun chiamante cambia. Le routine che ha un gioco solo (o tre) restano nella unit delle regole, esportate con il nome di prima.

**Righe.** Prima: Doom 2626, Heretic 2845, Hexen 3449, Strife 2753 (11673). Dopo: `Base\p_mobj.pas` 1327, unit delle regole Doom 1905, Heretic 2161, Hexen 2886, Strife 2070 (10349 in tutto; in ogni unit delle regole circa 130 righe sono la dichiarazione documentata della classe). Il calo e' piccolo perche' il grosso del testo (`P_ZMovement`, `P_SpawnMapThing`, `P_SpawnPlayer`, `P_HitFloor`, i missili) resta del gioco.

**Tabella di confronto** (`Tools\Verifica\185\Confronta-Copie.ps1 -Unit p_mobj`: 52 routine, 4 uguali, 32 parametriche, 16 proprie; lettera = copie uguali tra loro, numero = righe) **e decisione**:

| Routine | Doom | Heretic | Hexen | Strife | Diff | Decisione |
|---|---|---|---|---|---:|---|
| `P_DoSetMobjState`, `P_SetMobjState` | A49, A4 | B44 | C43 | D49 | 38 | unica: il ciclo e' `P_DoSetMobjState` di Doom (ora esportata), `P_SetMobjState` la chiama con `true` in ogni gioco; regola `KeepPreviousState` |
| `P_SetMobjStateNF` | A4 | B20 | B20 | - | 18 | *propria* (metodo `SetMobjStateNF`): in Doom e' il ciclo senza azioni, in Heretic e Hexen un solo stato; Strife ora la compila (nessuno la chiama) |
| `P_ExplodeMissile` | A17 | B23 | C21 | D15 | 14 | unica; `DeathState`, `RandomizeExplosionTics`, `ExplosionSound` |
| `P_XYMovement` | A214 | B247 | C356 | D216 | 215 | unica (testa, vento, mezze mosse, attrito); la mossa bloccata e' `BlockedMove`, **testo del gioco alla lettera** (Doom 58 righe, Heretic 62, Hexen 168 con `SkyExplode`, Strife 82); `StoppedBeforeMoving`, `SectorWind`, `HasWindThrust`, `HalvesBackwardMoves`, `NoFrictionFlags`, `AirborneFriction`, `FallsFree`, `StopWalking`, `ApplyFriction` |
| `P_ZMovement` | A214 | B220 | C273 | D197 | 215 | ***propria*** per gioco (unit delle regole) |
| `P_NightmareRespawn` | A76 | B74 | - | C77 | 27 | *propria* (metodo `NightmareRespawn`; vuoto in Hexen) |
| `P_MobjThinker` | A117 | B117 | C87 | D100 | 68 | unica (mossa, fase z, stati, rinascita dei mostri); la fase z e' `ZPhase`, testo del gioco (Doom 68 righe, Heretic 66, Hexen 54, Strife 32); `ClearJustAppeared`, `BeginThink`, `AfterXYMovement`, `StandsStill`, `BeforeStateCycle`, `CyclesStatesWhileNoTics`, `MonstersRespawn`, `RespawnTime`, `NeverRespawns`; riuso di `TMapGameRules.IsSkullFlying` |
| `P_SpawnMobj` | A186 | B185 | C187 | D195 | 31 | unica; `InitGameFields`, `InitBob`, `HasReactionTime`, `InitStateMemory`, `SpawnedOnFloor`, `RandomFloatHeight`, `SpawnZIsHeight`, `FootClipOnMidOrSlope`, `FootClipOnFloor`, `FloatSpawnZ` |
| `P_RemoveMobj` | A41 | B33 | C33 | D57 | 20 | unica; `BeforeRemove` (la coda degli oggetti, o le liste di Hexen), `ReleaseSectorList` |
| `P_RespawnSpecials` | A59 | B62 | - | C59 | 10 | unica (Hexen la compila e non la chiama); `ItemRespawnWaits`, `SpawnItemFog`, `SpawnHeightOfType`, riuso di `TMapGameRules.PointInSector` |
| `P_SpawnPlayer` | A132 | B125 | C160 | D149 | 71 | *propria* (metodo `SpawnPlayer`) |
| `P_SpawnMapThing` | A302 | B283 | C322 | D282 | 157 | *propria* (metodo `SpawnMapThing`) |
| `P_SpawnPuff` | A17 | B19 | C22 | D13 | 25 | *propria* (metodo `SpawnPuff`) |
| `P_SpawnBlood` | A24 | B24 | - | C23 | 17 | *propria*, esportata dalla unit del gioco |
| `P_SpawnGreenBlood`, `P_SpawnBlueBlood` | A21, A21 | - | - | B21, B21 | 6, 6 | *proprie*, esportate dalla unit del gioco |
| `P_CheckMissileSpawn` | A30 | B21 | C15 | D16 | 24 | unica; `RandomizeSpawnTics`, `HalvesMissileStepByDivision` |
| `P_SpawnMissile` | A54 | B80 | C70 | D58 | 48 | *propria* (metodo `SpawnMissile`) |
| `P_SpawnMissileXYZ` | A80 | B86 | C64 | D80 | 41 | *propria* (metodo `SpawnMissileXYZ`) |
| `P_SpawnMissileAngleZSpeed` | A47 | B53 | C46 | D47 | 12 | unica; `SaveRandom`, `RestoreRandom`, `MissileSeeSound`, riuso di `TMapGameRules.SlopesVersion` |
| `P_SpawnMissileAngleZ` | A5 | A5 | A5 | A5 | 0 | *uguale*: una copia |
| `P_SpawnPlayerMissile` | A82 | B83 | C91 | D62 | 59 | *propria* (metodo `SpawnPlayerMissile`) |
| `P_SeekerMissile` | A55 | A55 | B55 | A55 | 19 | unica; `SeekerTarget`, `SeekerSpeed`, `SeekerNeedsSpeed` |
| `P_GetThingFloorType` | A4 | A4 | B11 | A4 | 8 | unica; `TerrainFloorPic` |
| `P_HitFloor` | A104 | B72 | C117 | D100 | 96 | *propria* (metodo `HitFloor`) |
| `CmdSpawnMobj`, `CmdSummon` | A66, A58 | A66, B60 | B66, C58 | A66, A58 | 4, 6 | uniche; `ConsoleSpawnForbidden`, `IsFloatHeightName`, `FloatSpawnZ`, `SummonerRadius`, `SpawnHeightOfType` |
| `MObj_Init`, `MObj_ShutDown`, `P_FindMobjFromKey` | A6, A4, A18 | = | = | = | 0 | *uguali*: una copia |
| `P_FloorBounceMissile`, `P_BlasterMobjThinker`, `P_BloodSplatter`, `P_RipperBlood`, `P_SpawnMissileAngle`, `P_SPMAngle` | - | A5, A65, A14, A14, A49, A46 | B73, B92, B14, B13, B46, B53 | - | 58, 34, 6, 9, 44, 21 | *proprie* di Heretic e di Hexen: unit del gioco (non confrontate tra i due in questo passo) |
| `P_MonsterFallingDamage`, `P_PlayerLandedOnThing`, `P_InsertMobjIntoTIDList`, `P_RemoveMobjFromTIDList`, `P_FindMobjFromTID` (2), `P_BloodSplatter2`, `P_SpawnMissileAngleSpeed`, `P_SPMAngleXYZ`, `P_SpawnKoraxMissile` | - | - | A | - | 0 | *proprie* di Hexen: unit di Hexen |
| `P_CreateTIDList` | - | - | A30 | - | 0 | *propria* di Hexen (metodo `CreateTIDList`, vuoto negli altri); il nome resta in `Base\p_mobj.pas` perche' `Hexen\sv_save.pas`, che non si tocca, lo chiama e lo trova in `p_mobj` |
| `P_SpawnSparkPuff`, `P_SpawnFacingMissile`, `P_SpawnMortar`, `P_GetTerrainType` | - | - | - | A | 0 | *proprie* di Strife: unit di Strife |

In copia unica: 18 routine su 52 (le 4 uguali e 14 parametriche, contando `P_XYMovement` e `P_MobjThinker` per lo scheletro). **Resta proprio e perche'**: (1) `P_ZMovement`: le quattro versioni fanno le stesse cose in un ordine diverso proprio nel ramo "ha toccato il pavimento" (schizzi, stato di schianto, rimbalzo del teschio, danno da caduta, esplosione del missile) e l'ordine decide stato e suoni: unificarla e' riordinare testo che le demo coprono solo in parte; (2) `P_SpawnPlayer` e `P_SpawnMapThing`: scheletro comune ma campi del giocatore, classi, numeri degli oggetti e filtri diversi a ogni blocco, con estrazioni casuali; **non affrontate per tempo**, non perche' impossibili; (3) `P_SpawnMissile`, `P_SpawnMissileXYZ`, `P_SpawnPlayerMissile`: Doom, Heretic e Strife hanno lo stesso scheletro, Hexen un altro (altra distanza, altro risultato quando il missile esplode subito): con la forma "una routine e le regole" servirebbe una regola grande quanto la routine; (4) `P_SpawnPuff`, `P_SpawnBlood` e simili, `P_HitFloor`, `P_NightmareRespawn`: corte o fatte quasi solo di tipi, stati e suoni del gioco, con estrazioni casuali il cui ordine non va toccato; (5) le routine di un gioco solo.

**Chiamanti toccati** (solo `DelphiDoom.Engine.World.MobjRules` in piu' nella `uses`, subito dopo `p_mobj`): `Base\DelphiDoom.Engine.Acs.Host.pas`, `Base\p_common.pas`, `Base\udmf_mobj.pas`, `Base\udmf_spec.pas`, `Base\udmf_telept.pas`, `Base\udmf_things.pas`, `Doom\d_main.pas` (`spawnmask`), le quattro `DelphiDoom.Engine.World.MapRules.pas`, `Heretic\p_enemy.pas`, `p_pspr.pas`, `p_user.pas`, `Hexen\a_action.pas`, `p_enemy.pas`, `p_inter.pas`, `p_pspr.pas`, `p_things.pas`, `p_user.pas`, `Strife\p_enemy.pas`, `p_pspr.pas`; i 14 `.dpr` che elencano `p_mobj`. `p_saveg` e `sv_save` non toccati.

**Riuso.** Riusati: lo schema di 2c-1 (stesso nome di unit in ogni cartella, classe `sealed` statica), `TMapGameRules` (tre regole), `Prova-PMap.ps1` (il suo motore e' ora `Prova-Common.ps1`, comune ai due script; `Prova-PMap.ps1` da' lo stesso esito di prima, 108/34/11/0). Guardati e non adatti: `TEngineTeleportFogSpawner` (interfaccia a istanza: per la nebbia degli oggetti che rinascono basta la regola `SpawnItemFog`), `IGameContext` e `ILevelThingRules` (interfacce, strategia fredda; `P_SpawnMapThing` resta del gioco). **Nuovo e perche'**: `TMobjGameRules` nelle quattro cartelle (le regole di `p_mobj` nominano campi e tipi che `TMapGameRules` non conosce; metterle nella stessa classe avrebbe fatto di `MapRules` una unit di 3000 righe); `Prova-Common.ps1` e `Prova-PMobj.ps1`.

**Differenze dal vecchio** (nessuna voluta nel comportamento): (1) `P_SetMobjState` passa da `P_DoSetMobjState` anche in Heretic, Hexen e Strife (una chiamata in piu' per cambio di stato, come Doom da sempre); (2) `P_MobjThinker` chiama `ZPhase` (una chiamata statica in piu' per oggetto e per tic) e `P_XYMovement` chiama le sue regole: il costo si vede solo con la misura a coppie; (3) `Base\p_mobj.pas` esporta in ogni gioco anche `P_DoSetMobjState`, `P_SetMobjStateNF`, `P_RespawnSpecials`, `P_CreateTIDList`, `ITEMQUESIZE`, `itemrespawnque`, `itemrespawntime` (prima nella sezione `implementation`: ora le scrive la regola `BeforeRemove`); nessun'altra unit dichiara quei nomi; (4) nelle routine unificate qualche assegnazione indipendente o condizione senza effetti e' in un altro ordine (elenco nella prova meccanica: 18 riscritture dichiarate); **l'ordine delle estrazioni casuali non cambia in nessuna copia**; (5) `summon` di Heretic guardava `MF2_SPAWNFLOAT` prima di `MF_EX_SPAWNFLOAT` e `P_RespawnSpecials` il contrario: la regola `SpawnHeightOfType` e' una sola (i due rami danno lo stesso valore); (6) in Hexen `P_SpawnMissileAngleZSpeed` non controlla piu' che `P_SpawnMobj` dia nil (non lo da' mai). **Trappole incontrate**: un metodo delle regole chiamato `AirFriction` nascondeva la costante `AIRFRICTION` di Strife (errore di compilazione: rinominato `AirborneFriction`; un controllo cerca ora ogni nome di membro usato senza qualifica nelle unit delle regole: nessuno); `d_player` e `r_defs` sono passati alla `uses` dell'interfaccia delle unit delle regole e l'ordine della `uses` di `Base\p_mobj.pas` e' nuovo: un controllo della risoluzione dei nomi (ogni identificatore, la unit che lo dichiarava con la `uses` vecchia e con la nuova) trova solo `ANG1`, `ANG45`, `ANGLETOFINESHIFT`, dichiarate uguali in `tables` e in `DelphiDoom.MathCore.Types`.

**Verifica.**

- Build Release Win32, errori 0, avvisi 382/381/382/332/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32: uguali al limite dato; i dieci progetti compilati uno per uno, non con `build.bat giochi`); i quattro giochi software ricompilati dopo ogni tappa con gli stessi numeri. `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife`: errori 0, avvisi 381/304/199/412. `Doom32` e `Strife32` Release Win64: errori 0, avvisi 405 e 441.
- Golden a 8 bit (`Verifica-Ridotta.ps1` dopo ogni tappa, poi `Confronta-Golden.ps1` voce per voce, cartella `C:\ddparity_185`), 12 voci su 44 con lo stato finale, tutte UGUALI: Doom `d1_demo1`, `d1_demo3`, `a_f2_map07`; Heretic `a_h_e1m1`, `a_h_e1m3`, `a_h_e1m8`; Hexen `a_x_map01_f`, `a_x_map02_m`, `a_x_map03_f`; Strife `a_s_map32`, `a_s_map33`, `a_s_map34`. Le altre 32 voci e la misura a coppie **non fatte** (eseguibili finali di Doom32 e Heretic32 in `C:\ddref185\s2d\`).
- **Prova meccanica** (`Tools\Verifica\185\Prova-PMobj.ps1`, contro `git show d1852422:<Gioco>/p_mobj.pas`): 140 routine (Doom 31, Heretic 34, Hexen 42, Strife 33): **121 UGUALI** (comprese quelle rimaste del gioco, il cui testo deve essere il vecchio con la sola intestazione cambiata), **18 uguali dopo una riscrittura dichiarata** con il suo perche', **1 non testuale** (`P_SeekerMissile` di Hexen), **0 diverse**. La prova ha trovato la differenza del punto (5) sopra prima dei golden. Limite: come per `p_map`, che il corpo delle regole di una riga sia la sostituzione scritta nella tabella e' una rilettura.
- Test DUnitX: nessuno aggiunto e nessuno eseguito (il passo non tocca librerie; `p_mobj` e' legata ai record del motore).

**Rami che le dodici demo non esercitano di sicuro** (prova: testo spostato e prova meccanica): rinascita di oggetti e mostri (deathmatch 2, nightmare), `spawnmobj` e `summon`, missili che seguono un bersaglio e missili che strisciano, riflessione dei missili e sfere dello stregone di Hexen, vento dei settori, volo, scale, attrito su pendenza, 3D floor nella nascita degli oggetti, dondolio, `P_SetMobjStateNF`, la lista dei TID dopo un caricamento, gioco in rete.

**Non verificato.** Misura a coppie; corpus intero (32 voci); modo a 32 bit (il passo non disegna); `Radix32`, `SpeedHaste32`, i giochi OpenGL e i `ddc_*` compilati ma non avviati; Win64 compilato e non avviato; salvataggi (non toccati, non provati); `docs\FACCIATE.md` nomina `Doom\p_mobj` solo nelle tabelle dei chiamanti di un censimento vecchio (come `Doom\p_map`): non aggiornate.

**Resta** (passi successivi): le nove routine *proprie* con lo stesso nome nei quattro giochi, `P_ZMovement` per prima; il confronto tra le sei routine comuni a Heretic e Hexen; le variabili globali di `p_mobj` (`iquehead`, `iquetail`, la coda) nel contesto del mondo (stadio 1 del par. 10.3).

### 11.4 Passo 2c-3: il resto di `p_mobj` (ramo `worktree-agent-a7b1d1c38249f9d8b`, 2026-11-14)

Quattro commit, uno per tappa (`944c10d5` `P_NightmareRespawn`, `7f0a2dd4` `P_ZMovement`, `bd28a83a` `P_SpawnMissile` e `P_SpawnMissileXYZ`, `07ee6bd9` `P_SpawnPlayer`), piu' quello dei documenti. **Un tentativo annullato** su `p_map` (vedi sotto). Il passo e' **parziale**: resta `P_SpawnMapThing` e le routine elencate in "Resta".

**Forma.** Due forme, entrambe con regole del gioco nella `TMobjGameRules` che c'era gia' (stesso nome di unit in ogni cartella, classe `sealed` di metodi statici, nessuna chiamata virtuale ne' a interfaccia):

1. *Scheletro in `Base\p_mobj.pas`*, per le routine che i quattro giochi compilano: **`P_ZMovement`**. Lo scheletro e' la sequenza comune (scala, altezza, galleggiamento, pavimento o gravita', soffitto) e chiama sette regole: `ZPrelude`, `AfterZAdjust`, `ZFloat`, `ZHitFloor`, `ZGravity`, `CeilingLimit`, `ZHitCeiling` (e la costante `LadderStopMomz`). **Il ramo del pavimento (`ZHitFloor`) e' una regola intera con il testo vecchio alla lettera**: l'ordine di schizzi, stato di schianto, rimbalzo, danno da caduta ed esplosione e' diverso in ogni gioco e non e' stato toccato (le estrazioni casuali e i suoni escono nello stesso ordine; lo provano la prova meccanica e i golden). Le variabili locali che la vecchia routine passava da una fase all'altra (`player`) sono lette dove servono: sono letture pure.
2. *Unit di Doom, Heretic e Strife*, per le routine che Hexen non ha o fa in un altro modo (il suo progetto non le compila e il suo metodo resta dov'era): `Base\DelphiDoom.Engine.World.Respawner.pas` (`TMobjRespawner.Respawn`: `P_NightmareRespawn`; regole `RespawnOldFog`, `RespawnFogFloor`, `RespawnSpawnZ`, `RespawnInherit`), `...MissileSpawner.pas` (`TMobjMissileSpawner`: `P_SpawnMissile` con le regole `MissileOrigin` e `FuzzyAim`, e `P_SpawnMissileXYZ` **senza regole nuove**: bastano `TMapGameRules.SlopesVersion`, `MissileSeeSound`, `SaveRandom` e `RestoreRandom` che c'erano) e `...PlayerSpawner.pas` (`TMobjPlayerSpawner.Spawn`: `P_SpawnPlayer`; regole `PlayerTranslation`, `ResetBreath`, `FinishPlayerSpawn`). Stesso schema di `p_secnodes` (una unit che solo alcuni progetti compilano): i metodi `NightmareRespawn`, `SpawnMissile`, `SpawnMissileXYZ` e `SpawnPlayer` delle regole di quei tre giochi sono ora una riga che chiama la classe; quelli di Hexen sono il testo di prima. Aggiunte a 11 `.dpr` (Doom32, GLDoom32, ddc_doom, Radix32, SpeedHaste32, Heretic32, GLHeretic32, ddc_heretic, Strife32, GLStrife32, ddc_strife).

**Righe.** Prima: `Base\p_mobj.pas` 1327, regole Doom 1905, Heretic 2161, Hexen 2886, Strife 2070 (10349). Dopo: `Base\p_mobj.pas` 1381, unit nuove 119 + 188 + 177 (484), regole Doom 1789, Heretic 2039, Hexen 2939, Strife 1956 (10588). **Il totale sale di 239 righe**: la logica duplicata sparisce (`P_ZMovement` da quattro copie a uno scheletro di 50 righe piu' i pezzi, `P_NightmareRespawn`, `P_SpawnMissile`, `P_SpawnMissileXYZ` e `P_SpawnPlayer` da tre copie a una) ma ogni regola ha la sua dichiarazione documentata, il suo riquadro e la sua intestazione, e le 28 regole nuove per gioco sono quasi tutte testo spostato. Il guadagno e' nelle routine con lo stesso nome che non esistono piu' in copie parallele (cinque), non nel conteggio delle righe.

**Tabella di confronto e decisione** (le copie confrontate con `cmp.ps1`-equivalente sul testo normalizzato: tolti commenti, spazi e maiuscole; "diff" = righe diverse tra due copie):

| Routine | Giochi | Decisione |
|---|---|---|
| `P_NightmareRespawn` | Doom, Heretic, Strife (Hexen: regola vuota) | **unica** (`TMobjRespawner`): le tre copie facevano le stesse cose nello stesso ordine; differivano per il fumo vecchio (Doom dalla 1.22 usa `mobj.z`), la quota del fumo nuovo (Strife `ONFLOORZ`), la quota di nascita (Heretic guarda anche `MF2_SPAWNFLOAT`) e i flag ereditati (Strife ha sei flag di partenza, gli altri il trasferimento dell'amicizia) |
| `P_ZMovement` | tutti e quattro | **scheletro + sette regole** (sopra): le quattro versioni hanno lo stesso scheletro e fasi diverse |
| `P_SpawnMissileXYZ` | Doom, Heretic, Strife (diff 2, 12, 12) | **unica**, nessuna regola nuova; Hexen (diff 41-47) ha un'altra routine |
| `P_SpawnMissile` | Doom, Heretic, Strife (diff 8, 32, 34) | **unica** con due regole (la quota di partenza e il suono; l'errore di mira su un bersaglio invisibile: Strife ha anche `MF_MVIS`); Hexen (diff 42-48) e' un'altra |
| `P_SpawnPlayer` | Doom, Heretic, Strife (diff 18, 19, 21) | **unica** con tre regole; Hexen (diff 61-71: classi, colori, `P_SpawnPlayer` che chiama l'ACS) resta del gioco |
| `P_SpawnPlayerMissile` | tutti (diff 39-59) | *propria*: sono quattro routine con lo stesso nome ma diverse per scheletro (la mira e le armi cambiano: Strife 48 righe, Doom e Heretic 71, Hexen 82) |
| `P_SpawnMapThing` | tutti (diff 57-157) | *propria*, **non affrontata**: vedi "Resta" |
| `P_HitFloor` | tutti (Doom/Strife diff 8, Doom/Heretic 30, Hexen 96) | *propria*: la coppia Doom/Strife e' quasi uguale (il tipo di terreno e un controllo di versione), ma Heretic e Hexen no: una unita' a due giochi sola non toglie il nome in comune e non e' stata fatta |
| `P_SpawnPuff` | tutti (diff 10-25, 9-22 righe) | *propria*: routine di 9-22 righe fatte di tipi, stati e suoni; una regola sarebbe la routine |
| `P_SetMobjStateNF` | Doom, Heretic, Hexen (Strife non la usa) | *propria*, gia' un metodo delle regole: il ciclo senza azioni di Doom contro lo stato unico di Heretic e Hexen |
| le sei routine comuni a Heretic e Hexen (`P_FloorBounceMissile` 5/61, `P_BlasterMobjThinker` 63/85, `P_BloodSplatter` 12/12, `P_RipperBlood` 14/13, `P_SpawnMissileAngle` 46/44, `P_SPMAngle` 41/46) | Heretic, Hexen | **confrontate: non uguali** (diff 58, 34, 6, 9, 44, 21): Hexen aggiunge classi di armi, ghiaccio, tipi di missile propri. Restano proprie, con la regione scritta qui |

Contando i metodi delle regole e le routine con lo stesso nome nei quattro giochi, dopo il passo **non sono piu' duplicate** `P_NightmareRespawn`, `P_ZMovement`, `P_SpawnMissile`, `P_SpawnMissileXYZ`, `P_SpawnPlayer` (e le 18 del passo 2c-2). **Sono duplicate con una ragione scritta**: `P_SpawnMapThing`, `P_SpawnPlayerMissile`, `P_HitFloor`, `P_SpawnPuff`, `P_SetMobjStateNF`, `P_SpawnBlood`/`P_SpawnGreenBlood`/`P_SpawnBlueBlood` (Doom e Strife, 21 righe, diff 6: restano proprie per le tre insieme), le sei di Heretic e Hexen, e i metodi Hexen di `NightmareRespawn`, `SpawnPlayer`, `SpawnMissile`, `SpawnMissileXYZ`.

**`p_map`: un tentativo annullato.** `P_CheckForPushSpecial` (10 righe per gioco, differenze: il campo dei flag e la costante di attivazione) era un profilo di dati: si e' provata una versione unica in `Base\p_map.pas` con una regola `TouchActivation`. **Annullata prima del commit**: `P_ActivateLine` e' di `udmf_spec` in Doom, Heretic e Strife e di `p_spec` in Hexen (altra firma di unit), quindi la copia unica avrebbe dovuto nominare un'unit diversa per gioco, cioe' un `{$IFDEF}` o una regola che e' la routine stessa. Resta nelle unit delle regole. `PIT_ChangeSector` e la coda di contatto di `PIT_CheckThing` non sono stati toccati (par. 11.2).

**Riuso.** Riusati senza toccarli: `TMobjGameRules` (la classe e lo schema "stesso nome di unit in ogni cartella"), `TMapGameRules` (`PointInSector`, `SlopesVersion`), le regole `MissileSeeSound`, `SaveRandom`, `RestoreRandom`, `Prova-Common.ps1` e `Prova-PMobj.ps1` (estesi con le espansioni delle nuove routine), `p_secnodes` come modello di unit per tre giochi. Guardati e non adatti: `ILevelThingRules` e `IGameContext` (interfacce: strategia fredda; qui il costo non e' per cella della blockmap ma `P_ZMovement` si chiama per ogni cosa in movimento a ogni tic), `TEngineTeleportFogSpawner`, `TPlaneMover` di `Libs\Thinkers` (sono thinker di settori), `Libs\Radix.Physics.*` (regole pure della fisica di Rad-X: non agganciate qui, vedi sotto). **Nuovo e perche'**: tre unit per tre giochi (`Respawner`, `MissileSpawner`, `PlayerSpawner`: non esisteva un equivalente, e Hexen non puo' compilarle perche' non ha `sfx_telept`, `MT_TFOG` con quella firma ne' lo stesso scheletro di mira) e 28 regole per gioco (le sette di `P_ZMovement` per quattro giochi, quattro di `P_NightmareRespawn` e tre di `P_SpawnPlayer` per tre, due di `P_SpawnMissile` per tre).

**Differenze dal vecchio** (nessuna voluta nel comportamento): (1) `P_ZMovement`, `P_NightmareRespawn`, `P_SpawnMissile`, `P_SpawnMissileXYZ` e `P_SpawnPlayer` costano una chiamata statica in piu' per ogni regola (sette per `P_ZMovement`, che e' la sola nel ciclo per cosa: `AfterZAdjust` e' vuota in tre giochi e, non essendo `inline`, resta una chiamata; il costo si vede solo con la misura a coppie); (2) in Heretic e Strife il settore e' letto una volta (`TMapGameRules.PointInSector`) dove la vecchia copia teneva il sottosettore e leggeva il campo `sector`: nessun effetto; (3) la routine `P_ZMovement` non e' piu' una procedura di ogni unit delle regole ma e' esportata da `Base\p_mobj.pas`, e Hexen non la esporta piu' dalla sua interfaccia (nessun altro la chiamava); (4) in Strife `PlayerTranslation` e' di tipo `LongWord` (il campo `flags` di Strife e' `LongWord`: un avviso W1024 in piu' altrimenti). **Radix**: la firma di nessuna delle routine dell'elenco di `Libs\Radix\CLAUDE.md` ("Aggancio della fisica dopo la #185") e' cambiata (`P_DamageMobj`, `P_XYMovement`, `P_TryMove`, `P_SectorJumpOverhead`, `PIT_CheckThing`...); `P_ZMovement` e' passata da una procedura di `Doom\DelphiDoom.Engine.World.MobjRules.pas` a `Base\p_mobj.pas` con le fasi nelle regole `ZHitFloor` e `ZHitCeiling`, che sono il punto 6 dell'elenco. **Trappole incontrate**: `Base\p_mobj.pas` ha il nome `P_MobjThinker` due volte (interfaccia e implementazione) e una ricerca di testo ha inserito lo scheletro nell'interfaccia (errore di compilazione al primo giro); `Base\p_local.pas` ha `PVIEWHEIGHT` condizionale a `HERETIC`: la unit nuova lo prende dal progetto giusto perche' e' compilata per ogni gioco; `TMapGameRules.PointInSector` e' `inline` e la unit che lo chiama deve avere `r_main` nelle `uses` (Heretic e Strife: H2443).

**Verifica.**

- Build Release Win32: dieci eseguibili, errori 0, avvisi Doom32 381, Radix32 381, SpeedHaste32 381, GLDoom32 331, Heretic32 305, GLHeretic32 255, Hexen32 200, GLHexen32 150, Strife32 413, GLStrife32 340 (tutti nel limite dato: 381/381/381/332/305/255/200/150/413/340 — Doom32 381, Radix32 381; i dieci compilati uno per uno, non con `build.bat giochi`). `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife`: errori 0, avvisi 380/304/199/412. Doom32 e Strife32 Release Win64: errori 0, avvisi 416 e 453, **uguali alla base** (nessun avviso nelle unit di `p_mobj`: il confronto dei log per file con la build di `master` da' le stesse 67 unit e lo stesso totale 416 per Doom32; il 405/441 scritto nel par. 11.0 era un conto vecchio).
- Golden a 8 bit, `Verifica-Ridotta.ps1` dopo ogni tappa (4 voci su 4 UGUALI a ogni tappa, cartella `C:\ddparity_slice185`). **Corpus intero** una volta sul ramo finale (cartella `C:\ddparity_slice185`): **44 voci su 44 UGUALE a 8 bit** (Doom 21, Heretic 9, Hexen 8, Strife 6: stato per tic e fotogrammi) e **27 su 27 UGUALE a 32 bit** (Doom 21, Strife 6); le due voci di Freedoom sono risultate UGUALI anche qui. Radix32 `-devparm -nomusic -nosound -warp 1 1` (`Prova-Radix.ps1`): carica E1M1 (immagine 624x361, 86 colori), nessun `crash.txt`; il processo e' stato fermato dallo strumento dopo il tempo limite (nessuna uscita guidata).
- **Prova meccanica** (`Tools\Verifica\185\Prova-PMobj.ps1`, contro `git show d1852422:<Gioco>/p_mobj.pas`): 140 routine (Doom 31, Heretic 34, Hexen 42, Strife 33): **111 UGUALI**, **28 uguali dopo una riscrittura dichiarata**, **1 non testuale** (`P_SeekerMissile` di Hexen), **0 diverse**. Le uguali sono 10 meno di prima (121 al passo 2c-2) perche' dieci routine passano da "metodo con il testo vecchio" a "scheletro piu' regole" e hanno ora una riscrittura dichiarata (locali spostate, `i` e `z` passate alla regola che le usa, settore letto una volta, `result := nil` di Heretic). `Prova-PMap.ps1`: 153 routine, 108 / 34 / 11 / 0, **come prima** (`p_map` non e' cambiato).
- Test DUnitX: nessuno aggiunto: le tre unit nuove e le regole sono legate ai record del motore e agli stati globali (giocatori, settori, zone memory); la loro prova sono i golden e la prova meccanica. Una copertura a livello di classe vuole il mondo finto dello stadio 2 (par. 13).
- **Misura a coppie**: **NON conclusiva**: `Misura-Coppie.ps1`, Doom32 `demo1`, Win32 modo 8, 7 coppie, vecchio = `afeb6f87` (`C:\ddref_slice185`) contro nuovo finale: minimi 192 e 193 (**+0,52%**), mediane 249 e 221 (-11,24%), rifiutata dallo strumento (dispersione del vecchio 103%, CPU al 71% per altri agenti). Nessun "entro il 5%" dichiarato; l'unico segnale e' che i minimi coincidono entro lo 0,5%.

**Rami che i golden non esercitano di sicuro** (prova: testo spostato e prova meccanica): rinascita dei mostri (`-respawn`, nightmare), missili con fumo e con errore di mira su un bersaglio invisibile (Strife con `MF_MVIS`), missili `FLOORHUGGER` e `CEILINGHUGGER` (`P_SpawnMissileXYZ`), apparizione dei giocatori in deathmatch (chiavi in Heretic, carte in Doom, quest flag in Strife), UDMF con gravita' e salute del giocatore, scale (`laddertics`), volo, schianto del ghiaccio e dei vasi di Hexen, fuoco del minotauro, sfere dello stregone, soffitto di cielo con i missili (`MT_BLOODYSKULL`), rimbalzo sul soffitto.

**Non verificato.** Salvataggi (non toccati, non provati); rete; gioco OpenGL, SpeedHaste32 e ogni eseguibile Win64 (compilati, non avviati); suite DUnitX (nessuna toccata: `Libs\` non e' cambiato); la misura a coppie come verdetto "entro il 5%" (vedi sopra).

**Resta** (par. 13, fetta 1): `P_SpawnMapThing` (258/240/277/243 righe: otto blocchi di gioco intrecciati, con estrazioni casuali e uscite anticipate; serve prima una demo in piu' per gioco con deathmatch e difficolta' alta), `P_SpawnPlayerMissile`, `P_HitFloor`, `P_SpawnPuff` e il sangue, i metodi di Hexen, `PIT_ChangeSector`, il contatto di `PIT_CheckThing`, le variabili globali di `p_mobj` (stadio 1 del par. 10.3).

### 11.5 Passo 2c-4: il resto di `p_mobj` e di `p_map` (ramo `worktree-agent-a7cc44081d60b526f`, 2026-11-14)

Cinque commit di codice, uno per tappa (`a1b80dbc` A, `8ae4d843` B, `bf0ef59c` D, `4d30b7d4` E, `28b876d2` F; la tappa C e' una **non tappa**: le sei routine comuni a Heretic e Hexen sono state riconfrontate e restano proprie, vedi sotto), piu' quello dei documenti. **Nessuna tappa annullata.** Dopo ogni tappa: build dei giochi toccati, prova meccanica, `Verifica-Ridotta.ps1` (4 voci su 4 UGUALI a 8 bit, cartella `C:\ddparity_slice185b`).

**Forma.** Quella di 2c-3: le differenze dei giochi sono **regole** di `TMobjGameRules` / `TMapGameRules` (classi `sealed` di metodi statici, stesso nome di unit in ogni cartella di gioco, nessuna chiamata virtuale ne' a interfaccia); lo scheletro comune sta in una unit di `Base\` che compilano solo i giochi che lo usano (stesso schema di `Respawner`, `MissileSpawner`, `PlayerSpawner`) oppure in `Base\p_map.pas` / `Base\p_mobj.pas` quando lo compilano tutti e quattro. Il testo che resta del gioco e' quello vecchio alla lettera.

| Tappa | Routine | Giochi | Dove | Regole nuove |
|---|---|---|---|---|
| A | `P_SpawnMapThing` | Doom, Heretic, Strife (867 righe in tre copie -> scheletro di 230 + 195 di regole) | `Base\DelphiDoom.Engine.World.MapThingSpawner.pas` (`TMobjMapThingSpawner.Spawn`) | `MapThingPrologue`, `IgnoresMapThing`, `SpawnStartSpot`, `ExcludedByNetOptions`, `SkipsMonster`, `KeepsMapThingOff`, `MapThingFlags`, `CountItem` (la quota e' `SpawnHeightOfType` e il settore `TMapGameRules.PointInSector`, che c'erano) |
| B | `P_HitFloor` | Doom, Strife | `Base\DelphiDoom.Engine.World.HitFloor.pas` (`TMobjHitFloor.Hit`) | `HitFloorIgnoredByVersion`, `NukageSplashZ`, `NukageSplashSound` |
| B | `P_SetMobjStateNF` | Heretic, Hexen (le due copie erano identiche) | `Base\p_mobj.pas` (`P_SetMobjStateOnce`) | nessuna |
| D | `PIT_ChangeSector` | tutti e quattro | `Base\p_map.pas` | `IsCrushedBody`, `CrunchBody`, `IsDroppedItem`, `CrushBlood`, costante `CrushDamage` |
| E | coda di contatto di `PIT_CheckThing` (i due blocchi che spingono una cosa e la raccolta) | tutti e quattro | `Base\p_map.pas` (`P_PushByContact`, `P_ContactPickup`) | `CanBePushed`, `QuarterMomentum`, `PicksUpOnContact` |
| F | `P_SpawnPlayerMissile` | Doom, Strife | `Base\DelphiDoom.Engine.World.PlayerMissileSpawner.pas` (`TMobjPlayerMissileSpawner.Spawn`) | `AimWithoutTarget`, `AfterAim`, `AdjustMissileZ` (il suono e' `MissileSeeSound`, che c'era) |

**Tabella di confronto delle routine rimaste e decisione** (le copie confrontate sul testo; "diff" = righe diverse):

| Routine | Giochi | Decisione e ragione |
|---|---|---|
| `P_SpawnMapThing` | Hexen | *propria*: scheletro diverso (classi dei giocatori e flag di creazione propri `MTF_GSINGLE`, `classFlags`, cose dormienti, galleggiamento `FLOATBOB`, TID, angolo e `RMAP`): 322 righe di cui meno di un terzo uguali alle altre tre |
| `P_SpawnPlayerMissile` | Heretic (83 righe), Hexen (91) | *proprie*: Heretic toglie `FOOTCLIPSIZE`, fa partire il suono con una routine propria (suono a caso) e dopo la nascita muove il missile di un ottavo (`MT_BLASTERFX1`) o di meta' e prova `P_TryMove`, con il risultato in una variabile globale; Hexen ha le quote dei fulmini (`MT_LIGHTNING_FLOOR` e `CEILING`), `floorclip`, i missili veloci `MT_MWAND_MISSILE` e `MT_CFLAME_MISSILE` e gli spostamenti con `_SHR3`/`_SHR1` (per i negativi diversi da `div`): una regola sarebbe grande quanto la routine |
| `P_HitFloor` | Heretic (72), Hexen (117) | *proprie*: ordine dei controlli diverso (l'altezza del pavimento prima del ponte), nessun controllo di `heightsec` ne' della modalita' di compatibilita', nessun filtro `allowterrainsplashes` e nessun nukage in Heretic; Hexen ha i suoi terreni |
| `P_SpawnPuff` | tutti (13-22 righe) | *propria*: quattro righe di scheletro (z casuale, spawn, stato di pugno) e tutto il resto sono tipi, suoni e tic del gioco (`MT_PUFF`, `PuffType` con il suono, `MT_STRIFEPUFF` con `PLAYERMELEERANGE`) |
| `P_SpawnBlood` | Doom e Heretic **identiche** (24 righe, cambia solo `const` nella firma), Strife (23) | *propria* (lasciata, **candidata** a una prossima fetta: Doom + Heretic in una unit, con Strife che ha tre differenze di dato: tipo `MT_BLOOD_DEATH`, nessun accorciamento dei tic, intervalli di danno 7/10/13): un passo di sole venti righe in due giochi non e' stato fatto in questo giro per non rifare la verifica |
| `P_SpawnGreenBlood`, `P_SpawnBlueBlood` | Doom, Strife | *proprie*: gli stati si scelgono con `P_SetMobjRelativeState(th, n)` in Doom e con nomi di stato in Strife |
| `P_BloodSplatter`, `P_RipperBlood` | Heretic, Hexen (12 e 14 righe) | *proprie*: velocita' diverse (512 e 1024, `FRACUNIT * 2` e `3 * FRACUNIT`), `MF_NOGRAVITY` e `P_Random and 3` contro `P_Random mod 3` (**due comportamenti che differiscono davvero**: non si unificano senza cambiare le demo) |
| `P_SpawnMissileAngle`, `P_SPMAngle` | Heretic, Hexen | *proprie*: tabelle delle quote (altri tipi), `FOOTCLIPSIZE` contro `floorclip`, `lookdir` sempre contro `zaxisshift` |
| `P_FloorBounceMissile`, `P_BlasterMobjThinker` | Heretic (5, 63), Hexen (61, 85) | *proprie*: Hexen aggiunge classi di armi, ghiaccio e tipi di missile propri |
| `P_CheckForPushSpecial` | tutti | **riprovato e lasciato**: `P_ActivateLine` e' di `udmf_spec` in Doom, Heretic e Strife e di `p_spec` in Hexen, le costanti sono `ULAC_*` o `SPAC_*` e il campo dei flag e' `flags5_ex` o `flags2`: una forma senza `{$IFDEF}` vuole quattro regole (condizione di spinta, condizione di impatto, due attivazioni) e una regola che inoltra la chiamata: sono piu' righe della routine (10) |
| `CheckThingContact` (il resto) | tutti | *proprio*: le regole di specie, i missili, i rimbalzi e i flag (`MF_EX_*`, `MF2_*`) sono di ogni gioco; si sono estratti solo i blocchi identici (tappa E) |

**Righe.** Famiglia `p_mobj` (unit di `Base\`, regole, tre unit di 2c-3 e le tre nuove): 10588 -> **10403** (-185): `Base\p_mobj.pas` 1381 -> 1414, regole Doom 1789 -> 1489, Heretic 2039 -> 1852, Hexen 2939 -> 2923, Strife 1956 -> 1661, unit nuove 580 (304 + 162 + 114). Famiglia `p_map`: 7418 -> **7356** (-62): `Base\p_map.pas` 2778 -> 2907, regole Doom 1106 -> 1058, Heretic 917 -> 869, Hexen 1556 -> 1509, Strife 1061 -> 1013. Il calo e' piccolo come in 2c-3: ogni regola ha la sua dichiarazione documentata; il guadagno e' nelle routine che non esistono piu' in copie parallele.

**Routine con lo stesso nome in due giochi o piu': stato dopo 2c-4.** *Non piu' duplicate*: `P_SpawnMapThing` (Doom, Heretic, Strife), `P_HitFloor` (Doom, Strife), `P_SpawnPlayerMissile` (Doom, Strife), `P_SetMobjStateNF` (Heretic, Hexen), `PIT_ChangeSector` (tutti), i blocchi di spinta e di raccolta di `PIT_CheckThing` (tutti). *Duplicate con la ragione scritta nella tabella qui sopra*: `P_SpawnMapThing` di Hexen, `P_SpawnPlayerMissile` e `P_HitFloor` di Heretic e Hexen, `P_SpawnPuff`, le tre del sangue, le sei di Heretic e Hexen, `P_CheckForPushSpecial`, il resto di `CheckThingContact`, e i metodi di Hexen di `NightmareRespawn`, `SpawnPlayer`, `SpawnMissile`, `SpawnMissileXYZ` (par. 11.4).

**Prova meccanica.** `Prova-PMobj.ps1` (contro `git show d1852422:<Gioco>/p_mobj.pas`): 140 routine, **0 diverse** (le uguali e le dichiarate sono nel registro dell'esecuzione; le riscritture nuove dichiarate sono: `P_SpawnMapThing` (il settore letto una volta, `result := nil` in testa, le uscite di Heretic nella forma lunga, la bandiera amica di Strife messa prima di STAND e ALLY: bit indipendenti), `P_SpawnPlayerMissile` (la variabile `ver` passa alla regola, Strife legge la velocita' una volta)). `Prova-PMap.ps1` (contro `7bcb9a13`): 153 routine, **0 diverse**; `PIT_ChangeSector` e `PIT_CheckThing` sono dichiarate (le variabili locali passano alle regole e alle due funzioni nuove). Strumenti estesi: `Prova-Common.ps1` ha l'opzione `|map=nome` (coppie di sostituzioni nel corpo di una regola, per le regole che tornano un valore invece di uscire) e `-Maps`; `Prova-PMap.ps1` ha `-Extra M = Base\p_map.pas`. Limite di sempre: che il corpo delle regole di una riga sia la sostituzione scritta nella tabella e' una rilettura.

**Riuso.** Riusati senza toccarli: `TMobjGameRules` e `TMapGameRules` (schema, costanti e metodi `inline`), `SpawnHeightOfType` e `TMapGameRules.PointInSector` per la quota e il settore di `P_SpawnMapThing` (le due regole davano gia' lo stesso valore del vecchio testo: provato dalla tabella), `MissileSeeSound` per `P_SpawnPlayerMissile`, `P_DoSetMobjState`, lo schema delle tre unit di 2c-3 (`PlayerSpawner`...), `Prova-Common.ps1`, `Prova-PMobj.ps1`, `Prova-PMap.ps1`. Guardati e non adatti: `ILevelThingRules` (interfaccia: strategia fredda; `P_SpawnMapThing` e' fredda per cosa ma i filtri di gioco e le estrazioni casuali stanno nello scheletro), `TEngineTeleportFogSpawner`, `Libs\Thinkers` (nessuno di questi pezzi e' un thinker di settore). **Nuovo e perche'**: tre unit di `Base\` per due o tre giochi ciascuna (non esisteva un equivalente e Hexen/Heretic non possono compilarle: classi, flag e passi diversi), 14 regole nuove di `TMobjGameRules` e 8 di `TMapGameRules` per gioco (testo spostato, quasi tutte di una o due righe).

**Differenze dal vecchio** (nessuna voluta nel comportamento): (1) `P_PushByContact` e `P_ContactPickup` costano una chiamata statica in piu' per ogni contatto che arriva alla coda di `PIT_CheckThing` (il caldo di `p_map`: vedi la misura a coppie); `P_SpawnMapThing`, `P_HitFloor`, `P_SpawnPlayerMissile`, `PIT_ChangeSector` costano le chiamate delle regole (livello, tic del giocatore, settore che si muove); (2) in Heretic e Strife il settore di `P_SpawnMapThing` e' letto una volta (`PointInSector`), nessun effetto; (3) la bandiera amica di Strife e' messa nel punto in cui la mettono Doom e Heretic (prima dei parametri musicali, e prima di STAND e ALLY): bit indipendenti; (4) `Base\p_mobj.pas` esporta anche `P_SetMobjStateOnce`, `Base\p_map.pas` anche `PIT_ChangeSector` (prima era della unit delle regole), `P_PushByContact` e `P_ContactPickup`; `DelphiDoom.Engine.World.MapRules` non esporta piu' `PIT_ChangeSector` (i due chiamanti, `p_map` e `p_secnodes`, la trovano in `p_map`). **Radix**: nessuna firma delle tredici del paragrafo "Aggancio della fisica dopo la #185" di `Libs\Radix\CLAUDE.md` e' cambiata (`P_DamageMobj`, `P_XYMovement`, `P_TryMove`, `P_SectorJumpOverhead`, `PIT_CheckThing`, `P_ZMovement`...); `PIT_CheckThing` ha la stessa firma e la sua coda chiama `P_PushByContact` e `P_ContactPickup`: il punto 4 dell'elenco (contatto con le cose) va ora nelle regole `CheckThingContact`, `CanBePushed` e `PicksUpOnContact` di `Doom\DelphiDoom.Engine.World.MapRules.pas`; `PIT_ChangeSector` e' passata in `Base\p_map.pas` con `CrunchBody` e `CrushBlood`. **Trappole incontrate**: (a) un identificatore usato in una regola che un solo gioco compila non si puo' lasciare in uno scheletro condiviso anche se "non si raggiunge" (Strife non ha `totalitems` ne' `MF_COUNTITEM`: `CountItem` e' una regola e non una costante); (b) una procedura con un parametro o una variabile `result` non compila: le regole che tornano un valore sono funzioni e `exit` diventa `result := true`; (c) `@(@('a','b'))` in PowerShell e' un array piatto di due stringhe, non una coppia (`@(,@(...))` per una sola coppia nelle mappe della prova).

**Verifica.**

- Build Release Win32, errori 0, avvisi Doom32 381, Radix32 381, SpeedHaste32 381, GLDoom32 331, Heretic32 305, GLHeretic32 255, Hexen32 200, GLHexen32 150, Strife32 413, GLStrife32 340 (tutti nel limite dato; i dieci compilati **uno per uno**, non con `build.bat giochi`, dopo l'ultimo commit di codice); `ddc_doom`, `ddc_heretic`, `ddc_hexen`, `ddc_strife`: errori 0, avvisi 380/304/199/412. `Doom32` e `Strife32` Release Win64: errori 0, avvisi 416 e 453, **uguali alla base**.
- Golden a 8 bit, `Verifica-Ridotta.ps1` dopo ognuna delle cinque tappe (A, B, D, E, F): **4 voci su 4 UGUALI ogni volta** (Doom `d1_demo1`, Heretic `a_h_e1m1`, Hexen `a_x_map01_f`, Strife `a_s_map32`; cartella `C:\ddparity_slice185b`). **Corpus intero** una volta sul ramo con tutti i passi (eseguibili di Win32 Release compilati dopo l'ultimo commit di codice): **44 voci su 44 UGUALI a 8 bit** (Doom 21, Heretic 9, Hexen 8, Strife 6: stato per tic e fotogrammi) e **27 su 27 UGUALI a 32 bit** (Doom 21, Strife 6). Anche le due voci di Freedoom (`a_f2_map10`, `f2_demo2`) sono UGUALI nella cartella di lavoro nuova.
- **Prova meccanica**: `Prova-PMobj.ps1` (contro `git show d1852422:<Gioco>/p_mobj.pas`): 140 routine, **106 UGUALI, 33 uguali dopo una riscrittura dichiarata, 1 non testuale** (`P_SeekerMissile` di Hexen, come prima), **0 diverse**. `Prova-PMap.ps1` (contro `7bcb9a13`): 153 routine, **101 UGUALI, 41 dichiarate, 11 non testuali** (come prima: le stesse di 2c-1), **0 diverse**.
- **Controllo della risoluzione dei nomi** delle tre unit nuove di `Base\` (la `uses` e' in un ordine diverso da quella della unit delle regole da cui il testo e' venuto): per ogni identificatore usato dal codice e dichiarato da due o piu' unit in scena, il vincitore con la `uses` nuova e con la vecchia; gli unici che cambiano sono campi di record (`_type`, `health`, `x`, `z`, `speed`, `sector`, `angle`, `id`, `info`, `tid`, che non si risolvono per unit) e le costanti uguali `ANG1`, `ANG45`, `ANGLETOFINESHIFT` (dichiarate allo stesso valore in `tables` e in `DelphiDoom.MathCore.Types`): nessuna variabile o routine cambia significato (`deathmatch`, `netgame`, `gameskill`, `nomonsters`, `totalkills`, `totalitems`, `allowterrainsplashes`, `linetarget`, `zaxisshift` hanno un solo vincitore).
- **Radix32** (`Tools\Verifica\169\Prova-Radix.ps1 -Arguments '-data <cartella con RADIX.DAT 2.0 e Radix32.swd> -devparm -nomusic -nosound -warp 1 1'`): carica E1M1 (finestra 1920x1080, immagine con 90 colori), vivo dopo 40 secondi, nessun `crash.txt`, nessuna finestra di errore (il processo e' fermato dallo strumento al tempo limite). Non guardato a schermo. Un primo tentativo con una cartella dati inesistente ha dato la finestra di errore dell'avvio: era la cartella, non il codice.
- **Misura a coppie: NON conclusiva** (`Tools\Misura-Coppie.ps1` chiamata per le quattro combinazioni di `Misura-Giro.ps1`, che con un worktree cerca i WAD nel `bin` sbagliato: passato `-DataRoot` del repository principale). Doom32 `demo1`, 7 coppie, vecchio = Doom32 di `05ceff5f` (`C:\ddref_slice185b`) contro il nuovo finale; **lo strumento rifiuta ogni misura** (dispersione del vecchio 33-105%, altri agenti sulla macchina, CPU al 50-79%): Win32 modo 8 minimi -0,96% e mediane -6,19%; Win32 modo 32 minimi -1,46%, mediane -8,36%; Win64 modo 8 minimi +7,77%, mediane +2,21% (rifatta con 9 coppie: minimi **+0,96%**, mediane +1,64%, ancora rifiutata); Win64 modo 32 minimi +12,32%, mediane -9,92%. Nessun "entro il 5%" dichiarato. I punti da guardare a macchina scarica: la coda di `PIT_CheckThing` (`P_PushByContact` e `P_ContactPickup`, una chiamata in piu' per ogni coppia di cose che arriva in fondo) e `P_ZMovement`.
- Test DUnitX: **nessuna suite eseguita**: `Libs\` e `Tests\` non sono toccati (le unit nuove e le regole sono legate ai record del motore; la loro prova sono i golden e la prova meccanica).
- **Non verificato**: salvataggi (non toccati, non provati), rete, deathmatch, difficolta' 4-5 e `-nomonsters` (il corpus non li esercita; per loro la prova e' la tabella di confronto e il controllo dei nomi), UDMF con gravita' e salute, `P_HitFloor` fuori dal corpus (i quattro terreni), apparizione delle cose di Heretic con le liste (`P_AddMaceSpot`, spot dei boss, suoni ambientali: in E1M1 di Heretic ci sono i suoni ambientali, le mazze solo nelle mappe dell'episodio), rinascita dei mostri; giochi OpenGL, SpeedHaste32 e ogni eseguibile Win64 compilati e non avviati.

**Resta** (par. 13, riga 1 chiusa): le routine "duplicate con ragione" di questa tabella; le variabili globali di `p_mobj` (`iquehead`, `iquetail`, la coda) nel contesto del mondo (stadio 1 del par. 10.3, fetta 8); i test di unita' delle unit delle regole (richiedono il mondo finto della fetta 8). Prossima fetta della fase 2: **`p_user`** (par. 13.1 riga 2).

### 11.6 Passo 2f-1: `p_user` (ramo `worktree-agent-a33357092270d4118`, 2026-11-15)

`Base\p_user.pas` e' l'unica unit `p_user` per i quattro giochi; la differenza dei giochi e' la strategia calda `TUserGameRules` (classe `sealed` di metodi statici in `<Gioco>\DelphiDoom.Engine.World.UserRules.pas`). Da 6382 a 5402 righe (-980): 1364 in `Base\`, 4038 nelle quattro `UserRules`.

- **Copia unica per tutti**: `P_Thrust`, `P_CalcHeight`, `P_CalcHeight205`, `P_SlopesCalcHeight`, `P_MovePlayer`.
- **Doom, Heretic, Strife**: `P_DeathThink`, `P_PlayerThink` (`PlayerThinker`, `PlayerColormap`).
- **Doom e Strife**: `P_GetMoveFactor`, `A_PlayerBreath`, `P_AngleTarget`, `P_PlayerFaceMobj` (`PlayerExtras`).
- **Heretic e Hexen**: `P_PlayerNextArtifact`, `P_GetPlayerNum`, `P_PlayerRemoveArtifact` (`PlayerArtifacts`).
- **Restano duplicate** (record e regole di gioco diversi): `P_PlayerThink` e `P_DeathThink` di Hexen, il movimento a comando (`MoveByCommand`), il volo di Heretic e Hexen (`AfterMove`, candidato a una fetta futura), `P_UseArtifact`, `P_PlayerUseArtifact`, `P_ArtiTele`.

Verifica: golden 44/44 a 8 bit e 27/27 a 32 bit UGUALI, `Prova-PUser.ps1` 0 diverse; misura a coppie non conclusiva (macchina carica), da rifare.

### 11.7 Passo 2f-2: `p_inter` (ramo `worktree-agent-a0caca430f9e3d1ff`, partito da `5348560dc`, 2026-11-15)

**Forma.** Come `p_user` (par. 11.6): `Base\p_inter.pas` e' l'unica `p_inter`; cio' che un gioco fa di diverso sta in `TInterGameRules`, classe `sealed` di metodi statici (nessun metodo virtuale, nessuna interfaccia) della unit `DelphiDoom.Engine.World.InterRules`, che esiste **con lo stesso nome in `Doom\`, `Heretic\`, `Hexen\` e `Strife\`** e si sceglie dal percorso del progetto (Radix32 e SpeedHaste32 prendono quella di `Doom\`). Le esportazioni di un solo gioco (`P_GiveAmmo`, `P_GiveCard`, `P_GiveMana`, `P_MorphPlayer`, gli artefatti...) e le tabelle (`maxammo`, `clipammo`, `p_maxhealth`, `ArmorIncrement`...) restano in quella unit; i chiamanti che le usano hanno la unit in piu' nella `uses` subito dopo `p_inter` (34 file, ognuno `1 0` nel diff). Le firme delle routine pubbliche non sono cambiate (`P_DamageMobj`, `P_TouchSpecialThing`, `P_GivePower`, `P_KillMobj` di Strife, `P_GiveArmor`...).

**Passi** (un commit ciascuno, `refs #185`; dopo ognuno `Verifica-Ridotta.ps1` 4 su 4 UGUALE, dieci giochi con gli avvisi della base):

| Passo | Commit | Cosa |
|---|---|---|
| 2f-2a | `6de86a6fe` | cablaggio: il vecchio `p_inter` di ogni gioco diventa `InterRules` (`TouchSpecialThing` e `DamageMobj` come metodi), `Base\p_inter.pas` inoltra; `P_CmdSuicide` (uguale nei quattro) e' la prima copia unica; i 14 `.dpr` e i chiamanti |
| 2f-2b | `368728136` | la famiglia di Heretic e Hexen: `Base\DelphiDoom.Engine.World.SpecialRespawn.pas` (`P_HideSpecialThing`, `A_RestoreArtifact`, `A_RestoreSpecialThing1` con la regola `RepositionSpecial` per la mazza di Heretic, `A_RestoreSpecialThing2`), `...MinotaurSlam.pas` (`P_MinotaurSlam`, `MinotaurSlamDice` 6 o 4), `P_AutoUseHealth` in `...PlayerArtifacts.pas` (accanto a `P_PlayerRemoveArtifact`) |
| 2f-2c | `47bd6106b` | `P_GiveBody` in `Base\p_inter.pas` (regola `MaxPlayerHealth`; `OwnsGiveBody` per il medico e la stamina di Strife); `Base\DelphiDoom.Engine.World.PickupGivers.pas`: `P_GiveArmor` (Doom, Heretic, Strife: `AllowsNegativeArmor`) e `P_SpawnDroppedMobj` (Doom e Heretic: `NeedsCompatibility`, `DroppedScatterVersion`) |
| 2f-2d | `5b907d4eb` | `P_DamageFlagFilter` in `Base\p_inter.pas`: il blocco del danno da congelamento e da fiamma, identico (626 caratteri) nei quattro `P_DamageMobj` |

**Tabella delle 39 routine** (`Confronta-Copie.ps1 -Unit p_inter`; `Prova-PInter.ps1` contro `5348560dc`: nessuna DIVERSA):

| Routine | Giochi | Dove ora | Ragione |
|---|---|---|---|
| `P_CmdSuicide` | 4 | `Base\p_inter.pas` | uguale |
| `P_GiveBody` | 4 | `Base\p_inter.pas` | parametrica: solo il massimo (`MaxPlayerHealth`: spawnhealth; Heretic col pollo `p_maxchickenhealth`; Hexen `P_MaxPlayerHealth`); Strife resta il metodo `GiveBody` (stamina, medico, `mo` puo' essere `nil`) |
| `P_GiveArmor` | Doom, Heretic, Strife | `PickupGivers` | Doom e Heretic uguali; Strife aggiunge l'armatura negativa. Hexen **non** la compila: `player.armorpoints` e' un array (un'armatura per tipo) e la firma e' un'altra, resta propria |
| `P_SpawnDroppedMobj` | Doom, Heretic | `PickupGivers` | parametrica: il test di compatibilita' (`G_NeedsCompatibilityMode` contro la variabile `compatibilitymode`) e la versione dello scatto (117 o 207) sono regole. Hexen resta propria: le sue cose non hanno `MF_DROPPED` (c'e' `MF2_DROPPED`) e non scattano. Strife non la ha |
| `P_HideSpecialThing`, `A_RestoreArtifact`, `A_RestoreSpecialThing1/2` | Heretic, Hexen | `SpecialRespawn` | uguali (la mazza di Heretic e' la regola `RepositionSpecial`) |
| `P_MinotaurSlam` | Heretic, Hexen | `MinotaurSlam` | parametrica: i dadi del danno |
| `P_AutoUseHealth` | Heretic, Hexen | `PlayerArtifacts` | uguale (conserva il difetto: il ramo "urne e fiaschette" toglie le urne dallo slot delle fiaschette, `normalSlot`) |
| `P_DamageMobj` | 4 | regola `DamageMobj` + `P_DamageFlagFilter` (Base) | propria con ragione: l'ordine dei controlli (Hexen: `NODAMAGE`, congelamento, poi `health <= 0` con effetti sul cadavere di ghiaccio, poi invulnerabilita' e `MF2_DORMANT`), la spinta (arma che non spinge: motosega, fiamma, guanto; le costanti di Heretic, il bastone potenziato, `MF2_NODMGTHRUST`), `_SHR1(damage)` in Doom, Heretic e Hexen contro `damage div 2` in Strife (diversi per i valori negativi: non si dichiarano equivalenti), le armature (`div 3`/`div 2`; Heretic `div 2` e `div 2 + div 4`; Hexen per tipo con `savedPercent`), l'uso automatico dell'inventario, la morte (Strife: bruciatura e disintegrazione; Heretic: morte di fuoco, `special1`) e il passaggio a "inseguire" (Heretic: boss, stregone; Strife: alleati) |
| `P_KillMobj` | 4 | regola (nel `Base` niente) | propria con ragione: frag (Heretic conta -1 l'auto-frag e fa il super pollo; Strife scrive il messaggio), il bottino dell'inventario e il finale di Strife, la tabella dei drop per tipo e il dialogo, i ponti e il minotauro di Hexen, `gibhealth`, e il test `target.tics - P_Random and 3` di Hexen (precedenza sbagliata, conservata). Resta identico solo il fondo (spawn del drop a pavimento, con la quota del terzo piano), **non** estratto: in Hexen chiama la sua `P_SpawnDroppedMobj` |
| `P_TouchSpecialThing` | 4 | regola `TouchSpecialThing` | propria con ragione: la `case` degli sprite e' una tabella di dati del gioco (oggetti, messaggi, suoni); la testa e la coda cambiano (portata in basso 8 o 32 unita', Strife danneggia chi tocca uno spettro, respawn in deathmatch con `MF_DROPPED` di `flags` o di `flags2`, `P_ExecuteActorSpecial` o `P_ExecuteLineSpecial`, il lampo di palette di Hexen, i messaggi e le missioni di Strife) |
| `P_GiveAmmo`, `P_GiveAmmoAutoSwitch`, `P_GiveWeapon`, `P_GivePower`, `P_GiveCard`, `P_GiveKey` | per gioco | regole (resta propria) | i record non sono quelli: `weaponowned` intero o booleano, armi "sorelle" e livello due delle armi, `wpnlev1info`, i poteri di ogni gioco, la chiave come booleano o maschera di bit (`P_GiveCard` e' una procedura in Doom e una funzione in Strife) |
| `P_GiveArtifact`, `P_SetDormantArtifact`, `P_SetMessage` | Heretic, Hexen | proprie | parametriche ma con un'altra struttura: gli artefatti di Hexen hanno la classe e il conteggio per tipo (38 e 20 righe diverse); `P_SetMessage` scrive il globale `ultimatemsg` in Heretic e il campo del giocatore (`ultimateMessage`, `messageTics`, giallo) in Hexen |
| solo Heretic: `P_TouchWhirlwind`, `P_ChickenMorph`, `P_ChickenMorphPlayer`, `P_AutoUseChaosDevice` | Heretic | proprie | non c'e' un equivalente |
| solo Hexen: `P_GiveMana`, `P_MaxPlayerHealth`, `P_MorphPlayer`, `P_MorphMonster`, `P_ActiveMinotaur`, `P_TryPickupWeapon`, `P_TryPickupWeaponPiece`, `P_TryPickupArtifact`, `P_FallingDamage`, `P_PoisonPlayer`, `P_PoisonDamage`, `P_SetYellowMessage`, `P_ClearMessage` | Hexen | proprie | idem |

**Riuso, esteso, creato.** *Riusato*: lo schema del passo 2f-1 (`TUserGameRules`, unit di famiglia in `Base\`), `PlayerArtifacts`, `Prova-Common.ps1` e `Confronta-Copie.ps1`. *Esteso*: `Base\DelphiDoom.Engine.World.PlayerArtifacts.pas` (`P_AutoUseHealth`), `Prova-Common.ps1` non toccato. *Creato*: `Base\p_inter.pas`, `...PickupGivers.pas`, `...SpecialRespawn.pas`, `...MinotaurSlam.pas` (non c'era un equivalente: erano copie in due o tre giochi), le quattro `InterRules`, `Tools\Verifica\185\Prova-PInter.ps1`.

**Righe** (famiglia `p_inter`, con `PlayerArtifacts`): 7502 -> **7373** (-129): `p_inter` 1265 + 1849 + 2685 + 1569 = 7368 prima; ora `Base\p_inter.pas` 224, `PickupGivers` 111, `SpecialRespawn` 109, `MinotaurSlam` 60, `InterRules` Doom 1167, Heretic 1581, Hexen 2438, Strife 1471 (le regole tengono la documentazione e le dichiarazioni di ogni metodo); `PlayerArtifacts` 134 -> 212. Il guadagno vero e' nelle routine che non esistono piu' in due o tre copie; `P_DamageMobj`, `P_KillMobj` e `P_TouchSpecialThing` (circa 2900 righe in tutto) sono dati e ordine di controllo di ogni gioco e restano propri.

**Differenze dal vecchio.** Nessuna voluta nel comportamento. Costo: `P_TouchSpecialThing` e `P_DamageMobj` hanno una chiamata statica in piu' (inoltro), `P_DamageMobj` una per `P_DamageFlagFilter`, `P_GiveBody` due (`GiveBodyUpTo` e la regola); nessuna e' per pixel, per thinker o per colonna. Difetti conservati: `normalSlot` di `P_AutoUseHealth` (Heretic e Hexen), `target.tics - P_Random and 3` di Hexen, il commento "mo.health NOT set" di `P_GiveBody` di Strife (il codice resta com'era).

**Aggancio di Radix.** `P_DamageMobj` e' il punto 1 (scala del danno alla navetta) e il punto 3 della fisica (`Libs\Radix\CLAUDE.md`): ora sono nel metodo `TInterGameRules.DamageMobj` di `Doom\DelphiDoom.Engine.World.InterRules.pas` (subito dopo `player := target.player`); la firma di `P_DamageMobj` (in `Base\p_inter.pas`) non e' cambiata.

**Verifica.**

- Build Release Win32 dei dieci giochi (uno per uno, dopo l'ultimo commit di codice): errori 0, avvisi 381/381/385/331/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32), **uguali alla base** misurata sul commit di partenza (stesse righe di `warning` divise per due). `Tools\build.bat strumenti Release`: 13 su 13 (`ddc_*` compresi). Doom32 e Strife32 Release Win64 compilano (416 e 453 avvisi, nessuno nelle unit nuove; la base a 64 bit non e' stata rimisurata). `Tools\build.bat strati`: 0 violazioni nuove.
- Golden (cartella `C:\ddparity`, eseguibili del ramo finale): **corpus intero 44 voci su 44 UGUALE a 8 bit** (Doom 21, Heretic 9, Hexen 8, Strife 6) e **27 su 27 UGUALE a 32 bit** (Doom e Strife); `Verifica-Ridotta.ps1` 4 su 4 UGUALE dopo ognuno dei quattro passi.
- Prova meccanica `Prova-PInter.ps1` (contro `5348560dc`): Doom 12 routine, Heretic 24, Hexen 31, Strife 10; **nessuna DIVERSA**; le dichiarate sono `P_GiveArmor` (il ramo dell'armatura negativa) e `P_DamageMobj` (il filtro dei flag), le non testuali sono `P_GiveBody` di Doom, Heretic e Hexen (`GiveBodyUpTo` e' il vecchio testo con il massimo come parametro; la ragione e' nello script).
- Radix32 (`Tools\Verifica\169\Prova-Radix.ps1`, RADIX.DAT 2.0, `-devparm -nomusic -nosound -warp 1 1`): carica E1M1 fino alla precache (92 colori nella schermata), nessun `I_Error` ne' `crash.txt`; il processo non esce alla chiusura della finestra entro il tempo dato e lo strumento lo termina (`STILL RUNNING: killed`, non confrontato con la partenza: non c'e' un Radix32 di `5348560dc`). SpeedHaste32 (`SPEEDH.JCL` e una copia di `Doom32.swd` come `Speed32.swd`): la gara parte (`GO!`, tic 209), 311 colori, nessun `I_Error`, stesse note sull'uscita.
- **Misura a coppie: NON conclusiva** (`Tools\Misura-Coppie.ps1`, Doom32 `demo1` 5026 gametic, 7 coppie, Win32; vecchio = Doom32 di `5348560dc` in `C:\ddref_inter`): modo 8 vecchio minimo 203 mediana 252, nuovo minimo 223 mediana 286 (mediane +13,49%, minimi +9,85%), rifiutata per dispersione del vecchio 35,96%; modo 32 vecchio minimo 253 mediana 261, nuovo minimo 247 mediana 262 (mediane +0,38%, minimi -2,37%), rifiutata per dispersione 12,65%. Il codice toccato (pickup, danno, kill) non e' per pixel: da rifare a macchina scarica; Win64 non misurato (nessun vecchio compilato a 64 bit).
- **Non verificato**: salvataggi, rete, deathmatch (`P_SpawnDroppedMobj`, `RepositionSpecial`, `P_HideSpecialThing` si esercitano solo li' e nelle partite con respawn), difficolta' 4-5, artefatti e morfosi (il corpus di Heretic e Hexen ha poche demo), `P_GiveBody` di Strife con il medico, nessun test DUnitX scritto (le unit sono legate ai record del motore: la loro prova e' la prova meccanica sul testo e i golden), Win64 a runtime, i giochi OpenGL, Radix32 e SpeedHaste32 giocati con la tastiera.

**Resta** (par. 13, riga 3 chiusa): le routine "proprie con ragione" della tabella; `P_SpawnDroppedMobj` e `P_GiveArmor` di Hexen (proprie: giocatore e flag diversi); il fondo di `P_KillMobj` (lo spawn del drop) (identico in Doom, Heretic e Hexen, non estratto per la `P_SpawnDroppedMobj` di Hexen). Prossima fetta: `p_pspr` (riga 4).

### 11.8 Passo 2f-3: `p_pspr` (ramo `worktree-agent-a4cd9bb97986b85ba`, partito da `4232a8e03`, 2026-11-15)

**Forma.** Come `p_user` e `p_inter` (par. 11.6 e 11.7): `Base\p_pspr.pas` e' l'unica `p_pspr` per i quattro giochi (Radix32 e SpeedHaste32 compilano la stessa); cio' che un gioco fa di diverso sta nella strategia calda `TPspriteGameRules` (classe `sealed` di metodi statici, nessun metodo virtuale ne' interfaccia) della unit `DelphiDoom.Engine.World.PspriteRules`, che esiste **con lo stesso nome in `Doom\`, `Heretic\`, `Hexen\` e `Strife\`** (Radix32 e SpeedHaste32 prendono quella di `Doom\`) ed e' il vecchio `p_pspr` del gioco senza le routine spostate. Le armi e le `A_*` che i `states[]` di `info` puntano restano in quella unit; i chiamanti che le usano (`info`, `deh_main`, `DelphiDoom.Engine.Dehacked.Applier`, le regole di `p_inter`, `p_user`, `p_enemy`...: 26 file: una riga in piu' nel diff, due in `TableExport.Weapons`, che la nomina per Heretic e per Hexen) hanno la unit in piu' subito dopo `p_pspr`. Le firme pubbliche e le `A_*` registrate non cambiano; i puntatori a funzione degli stati restano gli indirizzi delle stesse routine, e i salvataggi non li scrivono: `p_saveg` (Doom, Heretic, Strife) e `sv_save` (Hexen) salvano `psprites[].state` come indice in `states[]` (`pDiff` e `@states[...]`).

**Passi** (un commit ciascuno, `refs #185`; dopo ognuno `Verifica-Ridotta.ps1` 4 su 4 UGUALE a 8 bit, dieci giochi con gli avvisi della base):

| Passo | Commit | Cosa |
|---|---|---|
| 2f-3a | `8be0f1606` | cablaggio: il vecchio `p_pspr` di ogni gioco diventa `PspriteRules`; `Base\p_pspr.pas` con `P_SetPsprite`, `A_Light0`, `P_SetupPsprites` (uguali nei quattro), `P_MovePsprites` (regola `AfterMovePsprites`: il mirino di Strife) e le costanti `WEAPONTOP`, `WEAPONBOTTOM`, `LOWERSPEED`, `RAISESPEED`, `PSPR_CYCLE_LIMIT` (uguali nei quattro, ora esportate), `FF_FULLBRIGHT`, `FF_FRAMEMASK`; i 14 `.dpr` e 26 chiamanti |
| 2f-3b | `c0f243a71` | `P_DropWeapon`, `A_ReFire`, `A_Lower`, `A_Raise` in `Base\p_pspr.pas` con le regole `DropWeaponState`, `RaisedState`, `StaysLowered`, `AfterLowered`, `CheckSupplies`; `P_FireWeapon` esportata dalle regole di Doom, Heretic e Strife; `Prova-PPspr.ps1` |

**Tabella delle 142 routine** (`Confronta-Copie.ps1 -Unit p_pspr`; `Prova-PPspr.ps1` contro `4232a8e03`: nessuna DIVERSA):

| Routine | Giochi | Dove ora | Ragione |
|---|---|---|---|
| `P_SetPsprite`, `P_SetupPsprites`, `A_Light0` | 4 | `Base\p_pspr.pas` | uguali (`P_SetupPsprites` chiama `P_BringUpWeapon` delle regole, che ora e' esportata) |
| `P_MovePsprites` | 4 | `Base\p_pspr.pas` | parametrica: solo Strife aggiunge il mirino (`sx` di `ps_targleft` e `ps_targright` dalla precisione), regola `AfterMovePsprites` (vuota negli altri) |
| `P_DropWeapon` | 4 | `Base\p_pspr.pas` | parametrica: cambia solo lo stato di discesa (`weaponinfo`; Heretic per livello 1 o 2 di potere; Hexen per classe), regola `DropWeaponState` |
| `A_ReFire` | 4 | `Base\p_pspr.pas` | parametrica: Hexen controlla il mana (`P_CheckMana`) invece delle munizioni, regola `CheckSupplies` |
| `A_Lower` | 4 | `Base\p_pspr.pas` | parametrica: Heretic e Hexen abbassano l'arma di colpo se il giocatore e' pollo o maiale (`StaysLowered`), Doom sceglie l'arma di mbf21 prima di alzare la nuova (`AfterLowered`) |
| `A_Raise` | 4 | `Base\p_pspr.pas` | parametrica: lo stato a cui va l'arma alzata (`RaisedState`; Hexen: l'ascia del guerriero con il mana) |
| `A_Light1`, `A_Light2` | Doom, Strife | restano nelle regole | uguali, ma sono quattro righe l'una: una unit di famiglia in `Base\` sarebbe piu' lunga delle due copie (e un'altra riga in 8 `.dpr`) |
| `P_BringUpWeapon` | 4 | proprie | 13 righe diverse: il suono della motosega e la scelta mbf21 (Doom), i suoni e gli stati dell'arma di Strife (fiamma, balestra elettrica, sigillo), i livelli di Heretic, la classe di Hexen |
| `P_CheckAmmo`, `P_CheckMana` (Hexen), `P_SubtractAmmo` (Doom) | per gioco | proprie | l'ordine di scelta dell'arma, le munizioni e il mana sono dati e record di ogni gioco (82 righe diverse) |
| `P_FireWeapon`, `A_WeaponReady` | 4 | proprie | l'attacco dell'arma e lo stato di pronto (23 righe diverse: il pollo e il becco di Heretic, il mana e il fulmine di Hexen, la fiamma e il fucile di Strife) |
| `A_CheckReload`, `A_GunFlash`, `A_Punch`, `A_FireMissile`, `P_GunShot` | Doom, Strife | proprie | parametriche con 2-18 righe diverse (il lampo come thinker, il pugno con la stamina, il razzo come missile di Strife): spostare il testo non toglierebbe nulla |
| le altre 107 `A_*` e `P_*` (armi di Doom, Heretic, Hexen e Strife) | 1 | proprie | non c'e' un equivalente |

**Riuso, esteso, creato.** *Riusato*: lo schema dei passi 2f-1 e 2f-2 (`T<X>GameRules` in `<Gioco>\DelphiDoom.Engine.World.<X>Rules.pas`, unit scelta dal percorso del progetto), `Prova-Common.ps1` e `Confronta-Copie.ps1`. *Esteso*: nulla in `Libs\` (non esisteva un equivalente: le armi sono record e codice di ogni gioco). *Creato*: `Base\p_pspr.pas`, le quattro `PspriteRules` (il vecchio `p_pspr` con `git mv`) e `Tools\Verifica\185\Prova-PPspr.ps1` (le sostituzioni per `P_DropWeapon`, `A_Lower` e `A_Raise` sono dichiarate nella tabella dello script).

**Righe** (famiglia `p_pspr`): 7280 -> **6760** (-520): prima 1195 + 2130 + 2694 + 1261; ora `Base\p_pspr.pas` 355, `PspriteRules` Doom 983, Heretic 1915, Hexen 2466, Strife 1041. Il guadagno vero e' nelle otto routine che non esistono piu' in quattro copie e nelle costanti; il resto (circa 6200 righe) sono armi di ogni gioco.

**Differenze dal vecchio.** Nessuna voluta nel comportamento. Costo: `P_MovePsprites`, `A_Lower`, `A_Raise`, `A_ReFire` e `P_DropWeapon` hanno una o due chiamate statiche in piu' (le regole), nessuna per pixel, colonna o thinker. Le costanti `WEAPONTOP`, `WEAPONBOTTOM`, `LOWERSPEED`, `RAISESPEED`, `PSPR_CYCLE_LIMIT` sono ora esportate da `p_pspr` (Radix ne ha una copia locale dello stesso valore in `radix_weapons`: va bene, il nome locale vince). Difetto conservato: l'errore di battitura "pendinfweapon" nel messaggio di `P_SetPsprite`. Nota: il vecchio `P_DropWeapon` di Hexen non aveva il punto e virgola prima di `end`; la routine unificata lo ha (nessun effetto, la prova meccanica lo dichiara).

**Aggancio di Radix e Speed.** Radix32 e SpeedHaste32 compilano `Base\p_pspr.pas` e le `PspriteRules` di `Doom\`; `radix_weapons` agganciava `P_CheckAmmo` e `P_BringUpWeapon` (ora nella unit delle regole, che ha in piu' nella `uses`): le firme non sono cambiate.

**Verifica.**

- Build Release Win32 dei dieci giochi (`Tools\build.bat giochi Release`, dopo l'ultimo commit di codice): errori 0, avvisi 381/381/385/331/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32), **uguali alla base** (l'ultimo passo, 2f-2). `Tools\build.bat strumenti Release`: 13 su 13 (`ddc_*` compresi). Doom32 e Strife32 Release Win64 compilano (416 e 453 avvisi, uguali a quelli del passo 2f-2). `Tools\build.bat strati`: 0 violazioni nuove (8 eccezioni dichiarate).
- Golden (cartella `C:\ddparity`, eseguibili del ramo finale): **corpus intero 44 voci su 44 UGUALE a 8 bit** (Doom 21, Heretic 9, Hexen 8, Strife 6) e **27 su 27 UGUALE a 32 bit** (Doom e Strife); `Verifica-Ridotta.ps1` 4 su 4 UGUALE sia sugli eseguibili del solo passo 2f-3a (rifatta a fine lavoro sulla copia fatta subito dopo la sua build: il primo tentativo in background non aveva lasciato il log) sia su quelli dei due passi.
- Prova meccanica `Prova-PPspr.ps1` (contro `4232a8e03`): Doom 31 routine (28 UGUALE, 3 DICHIARATA), Heretic 55 (52 e 3), Hexen 67 (64 e 3), Strife 32 (29 e 3); **nessuna DIVERSA**; le dichiarate sono `P_DropWeapon`, `A_Lower` e `A_Raise` (la regola da' il valore o il ramo, la routine lo passa a `P_SetPsprite`).
- Radix32 (`Tools\Verifica\169\Prova-Radix.ps1`, RADIX.DAT 2.0, `-data <bin\Radix> -devparm -nomusic -nosound -warp 1 1`): carica E1M1 (90 colori nella schermata), nessun `I_Error` ne' `crash.txt`; il processo non esce alla chiusura della finestra entro il tempo dato e lo strumento lo termina (`STILL RUNNING: killed`, come nel passo 2f-2). SpeedHaste32 (`-warp 1 1`, `SPEEDH.JCL`): la gara parte (312 colori), nessun `I_Error`, stessa nota sull'uscita. Senza `-warp` SpeedHaste32 si ferma su `W_GetNumForName(): CREDIT not found!` alla pagina del titolo: non e' stato confrontato con un SpeedHaste32 vecchio; il lump e' letto dalla pagina del titolo (codice che il passo non tocca) e i dati di prova non lo hanno.
- **Misura a coppie: NON conclusiva** (`Tools\Misura-Giro.ps1`, Doom32 `demo1`, 7 coppie; vecchio = Doom32 di `4232a8e03` in un worktree detached, Win32 e Win64): tutte e quattro le combinazioni rifiutate dallo strumento per dispersione del vecchio (14%-35%, CPU occupata da altro). Numeri indicativi, mediane e minimi del nuovo contro il vecchio: Win32 modo 8 -6,72% e +6,84%; Win32 modo 32 +5,14% e +1,98%; Win64 modo 8 +0,00% e -1,04%; Win64 modo 32 +8,50% e -3,37%. Il codice toccato (azioni delle armi) non e' per pixel ne' per thinker: da rifare a macchina scarica.
- **Non verificato**: salvataggi (le armi in mano si rimettono a posto da `P_SetupPsprites` al caricamento: non provato), rete, giocatore pollo o maiale (`StaysLowered`) e armi di livello 2 fuori da cio' che le demo del corpus esercitano (Heretic e Hexen hanno poche demo), la scelta dell'arma di mbf21 (`AfterLowered`, difficolta' e `-complevel` di Doom), il mirino di Strife a video (il corpus di Strife a 8 bit lo copre per lo stato, non per il suono), nessun test DUnitX scritto (le unit sono legate ai record del motore: la prova e' la prova meccanica sul testo e i golden), Win64 a runtime, i giochi OpenGL, Radix32 e SpeedHaste32 giocati con la tastiera.

**Resta** (par. 13, riga 4 chiusa): le routine "proprie con ragione" della tabella (armi, `P_BringUpWeapon`, `P_CheckAmmo`, `P_FireWeapon`, `A_WeaponReady`); la famiglia `A_Light1`/`A_Light2` di Doom e Strife se un giorno servisse una unit comune. Prossima fetta: `p_enemy` (riga 5: `P_LookForPlayers`, `P_Move`, `P_NewChaseDir`, `A_Chase`, `A_Look`).


### 11.9 Passo 2f-4: `p_enemy` (ramo `worktree-agent-a70b5ec51a08af0ce`, partito da `06d774591`, 2026-11-15)

**Forma.** Come 11.6-11.8: `Base\p_enemy.pas` e' l'unica `p_enemy` per i quattro giochi (Radix32 e SpeedHaste32 compilano quella e le `EnemyRules` di `Doom\`); cio' che un gioco fa di diverso sta nella strategia calda `TEnemyGameRules` (classe `sealed` di metodi statici, nessun metodo virtuale ne' interfaccia) della unit `DelphiDoom.Engine.World.EnemyRules`, con lo stesso nome in `Doom\`, `Heretic\`, `Hexen\`, `Strife\`: e' il vecchio `p_enemy` del gioco (`git mv`) senza le routine spostate. Le `A_*` degli stati restano li' (firme e indirizzi invariati: i puntatori a funzione dei `states[]` non cambiano, `Libs\Actions`, ACTORDEF e script non si toccano); i 54 chiamanti hanno la unit delle regole subito dopo `p_enemy`. Unit di famiglia in `Base\`: `DelphiDoom.Engine.World.EnemyMoveSpecials` (`TEnemyMoveSpecials.UseHitLines`: il ciclo sulle linee colpite da `P_Move`, uguale in Doom, Heretic e Strife, elencata solo nei loro `.dpr`: Hexen attiva le linee con un'altra `P_ActivateLine` e non la compila).

**Passi** (un commit ciascuno, `refs #185`; dopo ognuno `Verifica-Ridotta.ps1` 4 su 4 UGUALE a 8 bit, dieci giochi con gli avvisi della base):

| Passo | Commit | Cosa |
|---|---|---|
| 2f-4a | `f1212bc49` | cablaggio: il vecchio `p_enemy` diventa `EnemyRules`; in `Base\p_enemy.pas` `P_RecursiveSound`, `P_NoiseAlert`, `P_MeleeRange`, `P_TryWalk`, `P_LookForTargets` (uguali nei quattro, con la variabile di unit `soundtarget`); `P_LookForPlayers` esportata dalle regole; i 14 `.dpr` e i chiamanti |
| 2f-4b | `adfca33a3` | `P_Move`, `P_NewChaseDir`, `dirtype_t`, `opposite` (esportata: la usa `P_NewRandomDir` di Strife), `diags`; regole `Move`, `UseSpecialLines`, `ClearFloating`, `NoTarget`, `CanBackAway`, `FleesMeleeWeapon`; `EnemyMoveSpecials`; `Prova-PEnemy.ps1` |
| 2f-4c | `30b2a95aa` | `A_FaceTarget` con la regola `BlurAim` |

**Tabella delle routine** (`Confronta-Copie.ps1 -Unit p_enemy`; `Prova-PEnemy.ps1` contro `06d774591`: nessuna DIVERSA; Doom 73 routine (71 UGUALE, 2 DICHIARATA), Heretic 101 (99, 1, 1 NON TESTUALE), Hexen 169 (168, 1), Strife 113 (111, 2)):

| Routine | Giochi | Dove ora | Ragione |
|---|---|---|---|
| `P_RecursiveSound`, `P_NoiseAlert`, `P_MeleeRange`, `P_TryWalk`, `P_LookForTargets` | 4 | `Base\p_enemy.pas` | uguali |
| `P_Move` | Doom, Heretic, Strife | `Base\p_enemy.pas` (`P_MoveDefault`) | parametrica: il terreno di Strife (`ClearFloating`), il ciclo delle linee (`UseSpecialLines`), il testo dell'errore (`WeirdMoveDirMessage`: Doom `actor->movedir`, gli altri `actor.movedir`, **conservato per gioco**). Doom calcola `ret1` e `ret2` in istruzioni separate apposta (la seconda chiamata non deve saltare): il ciclo e' stato spostato com'e', non riscritto con `or` |
| `P_Move` | Hexen | metodo `Move` delle regole (`OwnsMove`) | blasted (`MF2_BLASTED`), `SPAC_USE` e `good` che basta una linea: un'altra semantica. `P_Move` di Base sceglie tra regola e `P_MoveDefault` con un `if` su costante (nessun avviso nuovo: con `exit` dentro l'`if` il compilatore segnalava un `result` non usato) |
| `P_NewChaseDir` | 4 | `Base\p_enemy.pas` | parametrica: bersaglio nullo (`NoTarget`: Strife torna allo stato di partenza), chi puo' arretrare (`CanBackAway`: solo Doom esclude il teschio), arma che fa fuggire (`FleesMeleeWeapon`: tabella di Doom/Strife, di Heretic per livello di potere, di Hexen per classe) |
| `A_FaceTarget` | 4 | `Base\p_enemy.pas` | parametrica: lo sfocamento della mira (`BlurAim`). `P_Random - P_Random` resta nella stessa espressione (stesso ordine in dcc32 e dcc64) |
| `P_LookForPlayers` | 4 | proprie | 54 righe diverse: `continueafterplayerdeath` (Doom), invisibilita' e minotauro (Heretic, Hexen), alleati (Strife); `lastlook` si limita con `and 3` in Doom/Heretic e con `mod MAXPLAYERS` in Hexen/Strife (`lastlook` arriva anche dai salvataggi: le due espressioni non sono equivalenti fuori da 0..3, non si uniscono) |
| `A_Look`, `P_DoChase`, `A_Chase` | per gioco | proprie | cane di Doom, scelta del suono di avvistamento (inline in Doom e Strife, `A_SeeSound1` in Heretic e Hexen), alleati e soglia di Strife, `gameskill` e frequenza dei suoni attivi diversi; `A_Chase` di Hexen e' lunga 113 righe e non passa da `P_DoChase`: uno scheletro unico avrebbe regole che sono quasi tutto il corpo |
| `P_CheckMeleeRange` | 4 | proprie | quattro forme (raggio e z di Doom con `MF3_EX_MELEECHECKZ`, ordine della vista e della z di Heretic, Hexen, `3 * height div 2` di Strife) |
| `P_CheckMissileRange` | 4 | proprie | Doom = Heretic (a meno di un commento); Hexen calcola la distanza in unita' intere (`FixedInt(d) - 64` contro `FixedInt(d - 64 * FRACUNIT)`: equivalenti solo se `FixedInt` e' uno shift aritmetico, **non verificato**); Strife ha acolito, tetti 150 e 120 e il predicato rovesciato. Una famiglia per la sola coppia Doom/Heretic aggiungerebbe righe |
| `A_Pain`, `A_Fall`, `P_Massacre` | per gioco | proprie | `A_Pain` e' una riga fuori da Strife (suoni dei Pesti), `A_Fall` ha 8 righe, `P_Massacre` torna `integer` in Hexen e cambia filtro in ogni gioco |
| le altre azioni (boss, Heretic, Hexen, Strife) | 1 | proprie | non c'e' un equivalente |

**Riuso, esteso, creato.** *Riusato*: lo schema di 11.6-11.8, `Prova-Common.ps1` (con `-Extra` per il testo della unit di famiglia), `Confronta-Copie.ps1`. *Esteso*: nulla in `Libs\` (le azioni dei mostri sono codice e record di ogni gioco). *Creato*: `Base\p_enemy.pas`, `Base\DelphiDoom.Engine.World.EnemyMoveSpecials.pas`, le quattro `EnemyRules` (il vecchio `p_enemy`), `Tools\Verifica\185\Prova-PEnemy.ps1`.

**Righe** (famiglia `p_enemy`): 18139 -> **17365** (-774): prima 3392 + 3563 + 6637 + 4547; ora `Base\p_enemy.pas` 538, `EnemyMoveSpecials` 78, `EnemyRules` Doom 3031, Heretic 3199, Hexen 6351, Strife 4168. Il guadagno vero e' in `P_Move`, `P_NewChaseDir`, `A_FaceTarget` e nelle cinque routine uguali, che non esistono piu' in quattro copie; il resto sono azioni di ogni gioco.

**Differenze dal vecchio.** Nessuna voluta nel comportamento. Costo: `P_Move` ha una chiamata in piu' (`P_MoveDefault`) e `P_Move`, `P_NewChaseDir` e `A_FaceTarget` hanno 1-3 chiamate statiche alle regole (le `class const` come `OwnsMove` spariscono in compilazione): per mostro e per tic, nessuna per pixel o colonna. Il testo dell'errore di `P_Move` di Heretic e Strife resta `actor.movedir` (non unificato col `->` di Doom).

**Verifica.**

- Build Release Win32 dei dieci giochi (`Tools\build.bat giochi Release`, dopo l'ultimo commit di codice): errori 0, avvisi 381/381/385/331/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32), **uguali alla base** (2f-3). `strumenti Release`: 13 su 13. Doom32 e Strife32 Release Win64 compilano (416 e 453 avvisi, uguali). `Tools\build.bat strati`: 0 violazioni nuove (8 eccezioni dichiarate).
- Golden (cartella `C:\ddparity`, eseguibili del ramo finale): **corpus intero 44 su 44 UGUALE a 8 bit** e **27 su 27 UGUALE a 32 bit** (Doom e Strife); `Verifica-Ridotta.ps1` 4 su 4 UGUALE dopo ciascuno dei tre passi.
- Prova meccanica `Prova-PEnemy.ps1` (contro `06d774591`): nessuna DIVERSA (vedi sopra).
- Radix32 (`Prova-Radix.ps1`, RADIX.DAT, `-warp 1 1`): carica E1M1 (80 colori), nessun `crash.txt`, `Doom32_stderr.txt` senza errori; SpeedHaste32 (`-warp 1 1`, `SPEEDH.JCL`): la gara parte (341 colori), stesso esito. Il processo non esce alla chiusura e lo strumento lo termina (`STILL RUNNING: killed`, come nei passi 2f-2 e 2f-3).
- **Misura a coppie: NON conclusiva** (`Misura-Coppie.ps1`, Doom32 `demo1`, 7 coppie, vecchio = Doom32 di `06d774591` in un worktree detached). `Misura-Giro.ps1` cerca i dati in `<radice>\bin\Doom`, che in un worktree non esiste: ho chiamato `Misura-Coppie.ps1` con `-DataRoot` sulla `bin` del repository principale. Win32 modo 8: mediane -0,88%, minimi +1,85%; modo 32: mediane +17,79%, minimi +9,33%; entrambe **rifiutate dallo strumento** (dispersione del vecchio 15% e 34%, `dcc64` e `MSBuild` di altri agenti in esecuzione). Win64 non misurato (nel worktree il Doom32 Win64 era stato rimosso dalla build successiva di Strife32). Il codice toccato (`P_Move`, `P_NewChaseDir`, `A_FaceTarget`, per mostro e per tic) non e' per pixel ne' per colonna: da rifare a macchina scarica.
- **Non verificato**: il ramo `MF2_BLASTED` e `SPAC_USE` di `P_Move` di Hexen e `NoTarget` di Strife (nessuna demo del corpus li esercita di sicuro), il livello 2 del potere di Heretic in `FleesMeleeWeapon`, salvataggi, rete, Win64 a runtime, i giochi OpenGL, Radix32 e SpeedHaste32 giocati con la tastiera, nessun test DUnitX scritto (le unit sono legate ai record del motore: la prova e' la prova meccanica sul testo e i golden).

**Resta** (par. 13, riga 5 chiusa): le routine "proprie con ragione" della tabella. Prossima fetta: `p_spec` e `p_switch` (riga 6).


### 11.10 Passo 2g: `p_spec` e `p_switch` (ramo `worktree-agent-a57431419c2cd8ef4`, partito da `aecc33fcd`, 2026-11-15)

**Forma.** `Base\p_spec.pas` e `Base\p_switch.pas` sono uniche per i quattro giochi (Radix32 e SpeedHaste32 compilano quelle di `Base\` e le unit di `Doom\`). Diversamente dalle fette 2f, qui la unit ha **piu' pezzi per gioco**, perche' l'interfaccia del vecchio `p_spec` era soprattutto tipi: i record dei thinker salvati (`plat_t`, `vldoor_t`, `ceiling_t`, `floormove_t`, `friction_t`, `pusher_t`, i `*_t115` e `*_t206` dei vecchi formati, `slidedoor_t` di Strife) e gli enum con i nomi nudi (`up`, `down`, `open`, `close`, `normal`, `top`, `middle`, `bottom`), che cambiano membri per gioco.

| Unit | Dove | Contenuto |
|---|---|---|
| `p_spec_h` | `Doom\`, `Heretic\`, `Hexen\`, `Strife\` (stesso nome) | il testo dei tipi, costanti e variabili dell'interfaccia del vecchio `p_spec`, alla lettera (come `p_pspr_h`) |
| `DelphiDoom.Engine.World.SpecRules` | idem | il vecchio `p_spec` (`git mv`) senza le routine spostate, piu' `TSpecGameRules` (classe `sealed` di metodi statici, nessuna chiamata virtuale ne' a interfaccia) |
| `DelphiDoom.Engine.World.SwitchRules` | idem | il vecchio `p_switch` (`git mv`) senza `buttonlist` e `P_StartButton` |
| `p_spec`, `p_switch` | `Base\` | le routine uguali o parametriche (tabella sotto) |
| `DelphiDoom.Engine.World.FrictionPushers` | `Base\` | `T_Friction`, `T_Pusher`, `P_SpawnFriction`, `P_SpawnPushers`, `P_GetPushThing` (517 righe uguali in Doom e Strife; compilata solo da Doom, Strife, Radix e Speed) |
| `DelphiDoom.Engine.World.SectorSearch` | `Base\` | le ricerche nei settori che hanno solo Doom e Strife (identiche): `P_FindNextLowestFloor`, `P_FindNextLowestCeiling`, `P_FindNextHighestCeiling`, `P_FindShortestTextureAround`, `P_FindShortestUpperAround`, `P_FindModelFloorSector`, `P_FindModelCeilingSector`, `P_FindLineFromLineTag2`, `P_SectorActive`; il `getSector` di Doom e Strife (con il controllo su `sidenum`) e' privato qui |

**Chiamanti.** Nei consumatori `p_spec` diventa `p_spec_h`, [regole se servono], `p_spec` **nella stessa posizione** (un nome nudo di enum come `top` o `open` non cambia unit risolta: l'ordine delle `uses` decide); le regole (`SpecRules`, `SwitchRules`) e le unit di famiglia solo dove il file nomina una routine che esportano. `Base\DelphiDoom.Engine.Ceiling.Thinker` (compilata anche da Heretic) include `SectorSearch` sotto `{$IFNDEF HERETIC}`, come gia' faceva per `P_SectorActive`. I 14 `.dpr` elencano `p_spec_h`, `p_spec`, `SpecRules`, `SwitchRules` (gli 8 di Doom e Strife anche le due unit di famiglia). I file di `Tools\Verifica\149..154` e `harness` (che hanno `p_spec` nelle `uses`) non sono toccati: nessun progetto del repository li compila.

**Passi** (un commit ciascuno, `refs #185`; dopo ognuno `Verifica-Ridotta.ps1` 4 su 4 UGUALE a 8 bit):

| Passo | Commit | Cosa |
|---|---|---|
| 2g-a | `3a5f3aff8` | cablaggio: `p_spec` -> `SpecRules` + `p_spec_h` (script che spezza interfaccia e tipi), 79 chiamanti, 14 `.dpr`; `Base\p_spec` con `getSide` e `P_FindLowestFloorSurrounding` |
| 2g-b | `c9172e8cd` | le utilita' dei settori con `TSpecGameRules`; `Prova-PSpec.ps1` |
| 2g-c | `49bdd49fc` | `FrictionPushers` e `SectorSearch` (Doom e Strife) |
| 2g-d | `a5d9dc00c` | `p_switch`: `buttonlist` e `P_StartButton` in Base; `SwitchRules` |

**Regole (`TSpecGameRules`).** Sono le differenze dei dati, scritte nella stessa forma `if ... then result := ... else result := ...` del vecchio testo, cosi' che la prova meccanica le ricostruisca alla lettera:

| Regola | Doom | Heretic | Hexen | Strife |
|---|---|---|---|---|
| `TwoSidedByFlag` (`twoSided`: flag o secondo lato) | `G_PlayingEngineVersion <= VERSION115` | vera | falsa | falsa |
| `NextSectorCompatible` (`getNextSector`) | `<= VERSION115` | vera | vera | `G_NeedsCompatibilityMode` |
| `HighestFloorStart` | `> VERSION115` (-32000 o -500) | `>= VERSION207` | `>= VERSION207` | -32000 |
| `LowestCeilingStart` | `> VERSION115` (32000 o `MAXINT`) | `> VERSION207` | `MAXINT` | 32000 |
| `HighestCeilingStart` | `> VERSION115` (-32000 o 0) | `> VERSION114` | `> VERSION141` | -32000 |
| `AdjoiningSectorsLimit` (`P_FindNextHighestFloor`) | 20 se `G_NeedsCompatibilityMode`, altrimenti 64 | idem | idem | 64 |
| `LineSectorTag` (`P_FindSectorFromLineTag`, `...Tag2`) | `line.tag` | `line.tag` | `line.arg1` | `line.tag` |

**Tabella delle routine** (`Confronta-Copie.ps1 -Unit p_spec`; `Prova-PSpec.ps1` contro `aecc33fcd`: **nessuna DIVERSA**; Doom 39 routine di `p_spec` (30 UGUALE, 5 DICHIARATA, 4 NON TESTUALE), Heretic 21 (13, 4, 4), Hexen 22 (15, 4, 3), Strife 37 (29, 4, 4); `p_switch`: tutte UGUALE):

| Routine | Giochi | Dove ora | Ragione |
|---|---|---|---|
| `getSide`, `P_FindLowestFloorSurrounding`, `twoSidedS` | 4 (`twoSidedS` Doom e Strife) | `Base\p_spec.pas` | uguali (`twoSidedS` di Doom senza `;` finale) |
| `twoSided`, `getNextSector` | 4 | `Base\p_spec.pas` | parametriche: `TwoSidedByFlag` e `NextSectorCompatible`. La forma e' diversa dal vecchio (rami scambiati; Heretic e Hexen sono la forma di Doom con `oldcompatibility` sempre vera): NON TESTUALE, l'equivalenza e' scritta in `Prova-PSpec.ps1` |
| `P_FindHighestFloorSurrounding`, `P_FindLowest/HighestCeilingSurrounding`, `P_FindNextHighestFloor` | 4 | `Base\p_spec.pas` | parametriche: la soglia di versione e il limite dei settori adiacenti (DICHIARATA) |
| `P_FindSectorFromLineTag`, `P_FindSectorFromLineTag2` | Doom, Heretic, Strife (la seconda anche Hexen) | `Base\p_spec.pas` | il tag e' letto una volta con `LineSectorTag` prima del ciclo (stessa condizione a ogni giro). `P_FindSectorFromLineTag` esiste ora anche in Hexen, dove non e' mai chiamata |
| `MAX_ADJOINING_SECTORS` | 4 (64 ovunque) | `Base\p_spec.pas` | costante uguale |
| friction e pusher (8 routine) | Doom, Strife | `FrictionPushers` | uguali (517 righe). `T_Friction` e `T_Pusher` restano definite **una sola volta**: `p_saveg` ne confronta e assegna l'indirizzo, e le vede da `uses` |
| ricerche nei settori (9 routine + `getSector`) | Doom, Strife | `SectorSearch` | uguali |
| `P_FindShortestTextureAround` | Heretic | `SpecRules` | propria: `twoSided` (flag) al posto di `twoSidedS` |
| `getSector` | Heretic | `SpecRules` | propria: senza il controllo `sidenum >= 0` (quella di Doom e Strife torna `nil`); non unificata per non cambiare il comportamento su una mappa con `ML_TWOSIDED` senza secondo lato |
| `P_InitPicAnims` | Doom, Strife (uguali), Heretic (diversa) | `SpecRules` | duplicata con ragione: Heretic ha tabella fissa e flat diversi; Doom e Strife tengono `anims`, `lastanim` e le tabelle fisse nella unit, che `P_UpdateSpecials` legge: portarla in Base vuol dire spostare i dati e le due routine insieme (fetta dei dati, 2i) |
| `P_CrossSpecialLinePtr`, `P_ShootSpecialLine`, `P_PlayerInSpecialSector`, `P_UpdateSpecials`, `P_SpawnSpecials` | per gioco | `SpecRules` | proprie: i grandi `case` degli special (1002/407/1341, 161/33/167, 143/91/72/127, 100/101/32/97, 277/209/107/269 righe nei quattro giochi). Spezzarli in regole sposterebbe solo il testo: ogni ramo e' uno special di quel gioco (Doom e Strife linee generalizzate e Boom, Heretic vento e correnti, Hexen script e ACS). `P_CrossSpecialLine*` ha `bossaction` in Doom e non negli altri (firma diversa) |
| `P_CanUnlockGenDoor`, `P_CheckTag`, `P_MobjInSpecialSector` | Doom (le prime due Strife, diversa) | `SpecRules` | proprie |
| `P_ExecuteLineSpecial`, `P_ActivateLine`, `EVH_*`, `CheckedLockedDoor`, `P_FindSectorFromTag*`, `P_PlayerOnSpecialFlat`, `P_FindLine` | Hexen | `SpecRules` | esistono solo in Hexen (ACS e special estesi) |
| `P_InitLava`, `EV_DoDonut` | Heretic (`P_InitLava` anche Hexen) | `SpecRules` | proprie |
| `P_StartButton`, `buttonlist` | 4 | `Base\p_switch.pas` | uguali; `P_StartButton` era privata e ora e' esportata (la usano le `SwitchRules`) |
| `P_ChangeSwitchTexture` | 4 | `SwitchRules` | quattro forme: Doom e Heretic differiscono solo per il suono (`sfx_swtchn` e l'uscita, o `sfx_switch`), Hexen prende suono e origine da `alphSwitchList`, Strife ha i vetri, i suoni per interruttore e la trasmittente delle miniere. Una regola `SwitchSound` per la sola coppia Doom/Heretic toglierebbe 55 righe ma obbligherebbe `switchlist` e `numswitches` (privati in tre giochi) a diventare pubblici: rimandata |
| `P_UseSpecialLine` | Doom, Heretic, Strife | `SwitchRules` | proprie: grandi `case` (1113/303/1372 righe), firma diversa in Strife |
| `P_InitSwitchList`, `P_SpawnBrokenGlass`, `P_MoveWall` | per gioco | `SwitchRules` | proprie |

**`Libs\Specials`.** Non usata: il registro (`ISpecialRegistry`) e' collegato solo a `P_ExecuteLineSpecial` di UDMF (`Base\udmf_spec.pas`, per i giochi che non sono Hexen) con gestori `reference to function`. I grandi `case` di `P_CrossSpecialLinePtr`, `P_ShootSpecialLine` e `P_UseSpecialLine` sono chiamati a ogni linea attraversata, colpita o usata e leggono i campi dei record del motore: trasformarli in gestori registrati vorrebbe dire una chiamata di chiusura per linea e riscrivere 3000 righe per gioco. Non fatto; il registro resta com'e'.

**Riuso, esteso, creato.** *Riusato*: lo schema di 11.6-11.9 (regole statiche per gioco, `p_pspr_h` come precedente per la unit dei tipi), `Prova-Common.ps1`, `Confronta-Copie.ps1`, `Verifica-Ridotta.ps1`. *Esteso*: nulla in `Libs\` (`Libs\Thinkers` e `p_scroll`, `p_ceilng`, `p_genlin`, `p_floor` di Base erano gia' in copia unica e usano le stesse routine, solo con le `uses` aggiornate). *Creato*: `Base\p_spec.pas`, `Base\p_switch.pas`, `FrictionPushers`, `SectorSearch`, le quattro `p_spec_h`, `SpecRules` e `SwitchRules` (il vecchio testo), `Tools\Verifica\185\Prova-PSpec.ps1`.

**Righe** (righe non vuote, `p_spec` + `p_switch`): 14766 -> **13678** (-1088): prima 3866 + 1153 (Doom), 1802 + 478 (Heretic), 1538 + 194 (Hexen), 3997 + 1738 (Strife); ora `Base\p_spec.pas` 372, `p_switch.pas` 81, `FrictionPushers` 566, `SectorSearch` 454, `p_spec_h` 534 + 370 + 292 + 580, `SpecRules` 2243 + 1281 + 1108 + 2343, `SwitchRules` 1126 + 451 + 166 + 1711. Il guadagno e' nelle 517 righe di friction e pusher e nelle nove ricerche in due copie, nelle quindici routine di `p_spec` che erano quattro copie e in `P_StartButton`; i tipi (1776 righe) sono solo spostati.

**Differenze dal vecchio.** Nessuna voluta nel comportamento. Costo: ogni utilita' dei settori con una soglia (`P_FindHighestFloorSurrounding`, le due dei soffitti, `getNextSector`, `twoSided`, `P_FindNextHighestFloor`, i due `P_FindSectorFromLineTag*`) ha una chiamata statica in piu' alla regola (una `class function` con un solo confronto, per evento di un settore o di una linea, nessuna per pixel, colonna o thinker); `P_FindSectorFromLineTag*` legge il tag una volta prima del ciclo (stessa condizione). Hexen ha ora anche `P_FindSectorFromLineTag`, `twoSidedS` e le altre utilita' di Base che non usa (il linker le scarta se non chiamate).

**Verifica.**

- Build Release Win32 dei dieci giochi (`Tools\build.bat giochi Release`, dopo l'ultimo commit di codice): errori 0, avvisi 381/381/385/331/305/255/200/150/413/340 (Doom32, Radix32, SpeedHaste32, GLDoom32, Heretic32, GLHeretic32, Hexen32, GLHexen32, Strife32, GLStrife32), **uguali alla base**. `strumenti Release`: 14 su 14. Doom32 e Strife32 Release Win64 compilano (416 e 453 avvisi, uguali). `Tools\build.bat strati`: 0 violazioni nuove (8 eccezioni dichiarate).
- Prova meccanica `Prova-PSpec.ps1` (contro `aecc33fcd`): nessuna DIVERSA.
- `Verifica-Ridotta.ps1`: 4 su 4 UGUALE a 8 bit dopo ciascuno dei quattro passi.
- Layout dei salvataggi (`Tools\Verifica\40\Prova-Layout.ps1 -Game Doom,Strife`, 32 e 64 bit contro i golden `Tests\Data\SaveLayout`): uscita 0 (i record dei thinker hanno cambiato unit, non campi).
- Golden (cartella `C:\ddparity`, eseguibili del ramo finale): **corpus intero 44 su 44 UGUALE a 8 bit** e **44 su 44 UGUALE a 32 bit** (`Confronta-Golden.ps1 -Modes 8` e `-Modes 32`, senza filtri).
- Radix32 (`Tools\Verifica\169\Prova-Radix.ps1`, `RADIX.DAT`, `-warp 1 1`): carica E1M1 (90 colori), nessun `crash.txt`, `Doom32_stderr.txt` senza `I_Error` (solo gli avvisi `P_InitSwitchList(): Unknown texture` e `Disk busy lump not found!`, non confrontati con la base); SpeedHaste32 (`SPEEDH.JCL`, `-warp 1 1`): la gara parte (350 colori), nessun `crash.txt`. Il processo non esce alla chiusura e lo strumento lo termina (`STILL RUNNING: killed`, come nei passi 2f).
- **Misura a coppie**: **NON conclusiva** (`Misura-Coppie.ps1`, Doom32 `demo1`, 7 coppie, vecchio = Doom32 di `aecc33fcd` estratto con `git archive` in `C:\ddmisura185\base` e compilato a parte; `-DataRoot` sulla `bin` del repository principale perche' `Misura-Giro.ps1` cerca i dati in `<radice>\bin\Doom`, che in un worktree non esiste). Win32 modo 8: mediane +0,50%, minimi +0,00%; modo 32: mediane +3,93%, minimi +5,56%; entrambe **rifiutate dallo strumento** (dispersione del vecchio 29,90% e 32,54%, macchina occupata da altri agenti: CPU 24,7% dopo l'esecuzione a 32 bit). Win64 non misurato. Il codice toccato (utilita' dei settori e special) e' per evento di settore o di linea, non per pixel, colonna o thinker: da rifare a macchina scarica.
- **Non verificato**: il ramo delle demo vecchie (`G_PlayingEngineVersion <= VERSION115`) per `twoSided`, `getNextSector` e le soglie, non esercitato dal corpus; i pusher e la friction di Doom e Strife (le demo del corpus non hanno sempre special di quel tipo); salvataggi veri; Win64 a runtime oltre il layout; i giochi OpenGL; Radix32 e SpeedHaste32 giocati con la tastiera; nessun test DUnitX scritto (le unit sono legate ai record del motore: la prova e' la prova meccanica sul testo e i golden).

**Resta** (par. 13, riga 6 chiusa): le routine "proprie con ragione" della tabella (i grandi `case`, `P_InitPicAnims` con i suoi dati, `P_ChangeSwitchTexture`). Prossima fetta: **i thinker rimasti** (riga 7: `Heretic\p_floor`, `p_plats`, `p_lights`, `p_telept`, `p_doors`, `udmf_ceilng`, `udmf_floor`).

## 12. Fase 1: censimento di chiusura (#185, 2026-11-14)

Fatto prima di scrivere codice, su `c4ce14f1`, leggendo per intero la sezione `implementation` di ogni unit. Le routine sono divise in **delega** (una o poche righe verso un oggetto di `Libs\` o di `Base\DelphiDoom.Engine.*`, piu' il controllo "non configurato"), **logica** (cicli, calcoli, stato in globali della unit) e **dati**. Le righe tra parentesi sono righe di corpo, contate dalla firma all'`end`.

### 12.1 Tabella

| Unit | Righe | Delega | Logica propria | Decisione |
|---|---:|---|---|---|
| `f_wipe` | 354 | nessuna | `wipe_initMelt` (59) e `wipe_doMelt` (71): il melt; il resto e' lettura dello schermo e buffer | **a classi ora** (fatto, 12.2): `TImagingMeltWipe` c'era gia' in `Libs\Imaging`, non collegata per il costo delle copie |
| `i_startup` | 422 | nessuna | form VCL `TStartUpConsoleForm` (gia' una classe, con il suo `.dfm`) e 13 `SUC_*` da 4-16 righe sulla form; logica vera solo `SUC_Outproc` (54: toglie `#8`/`#10` e risincronizza il Memo con `TStdoutBuffer` di `Libs\EngineSystem`) | **resta storica**: e' gia' una classe VCL con una facciata di chiamate, e il testo e' gia' di `TStdoutBuffer`. `SUC_Outproc` in una classe vuol dire un finto del Memo per 54 righe: **rimandata** (mezza giornata) con la finestra |
| `i_main` | 202 | `I_ConfigureWindowInput` | `WindowProc` (51) e `DoomMain` (47): `RegisterClass`, `CreateWindowEx`, messaggi di Windows | **rimandata** (1-2 giorni): `Libs\GameHost` ha `TGameHostWinWindow`, ma il suo `CLAUDE.md` dice che la finestra del motore non e' quella; la copia gemella sta in `Libs\OpenGl\Legacy\gl_main.pas` (fuori dal perimetro di questo giro) e le due vanno unite insieme; nessun golden copre fuoco, riduzione a icona e schermo intero |
| `i_mainwindow` | 118 | nessuna | tre routine da 8-11 righe su `GetClientRect`/`GetWindowRect`; il resto e' `hMainWnd` e due costanti | **resta storica**: dati e tre chiamate a Windows; segue `i_main` |
| `s_sound` | 2297 | 14 routine (113): player degli effetti, musica, cache della musica esterna | 35 routine (circa 1290): regole pure (`S_AdjustSoundParams` 103, `S_GetChannel` 80, variazione del pitch, lista dei nomi mp3 con `S_GetListFromAlias`), colla sui record del motore (`S_StartSoundAtVolume` 150, `S_StartVoiceAtVolume` 104, `S_UpdateSounds` 79, `S_DoChangeMusic` 151), tabelle per gioco (`S_DefaultMusicForMap` 71, `S_Init` 68), comandi di console | **a classi ora le regole pure** (fatto, 12.2); **resta nella facciata** la colla su `mobj_t`, `sfxinfo_t`, `musicinfo_t`, `players` (cambia per gioco con una ventina di direttive: e' materia delle regole per gioco, fase 2); `S_DefaultMusicForMap` e' una tabella per gioco |
| `sounds` | 522 | 2 (alias di SNDINFO, `Libs\ActorDef`) | 6 routine (340): registro di `S_sfx`/`S_music` (`S_GetSoundNumForName` 168 con quattro rami di gioco, liste casuali, `S_GetMusicNumForName`) | **rimandata** (1 giorno): il registro scrive le tabelle `S_sfx`/`S_music` dei giochi (`sounddata.pas`, fetta 2i "una sola forma di dati per gioco"); farlo ora vuol dire un adattatore per tabella e per gioco che la 2i rifarebbe |
| `s_pk3sounds` | 188 | 1 | `S_AddFileName` (37: regola del nome a 8 caratteri) e `W_InitPK3Sounds` (43: gia' sopra `TWadWriter`, `TSha1`, `ITempFiles`) | **resta storica**: 80 righe quasi tutte chiamate a classi; la regola del nome va con `sounds` |
| `w_wad` | 1249 | 16 routine (149): directory, finder, lettore, testo, CRC | 15 routine (459): `W_AddFile` 110, `W_RuntimeLoad` 114, `W_Reload` 46, `W_InitMultipleFiles` 47, `W_CacheLumpNum` 23, `W_SyncLumpInfo` 30 e sei lettori di `lumpinfo[]` | **resta storica**: la logica rimasta tiene `lumpinfo[]` e `lumpcache[]`, che `Libs\Wad\CLAUDE.md` lascia al motore per scelta (la cache vive nella zone memory e `W_CacheLumpNum` ha 51 file chiamanti, anche sul percorso di ogni fotogramma); `TLumpCache` esiste ed e' scollegata per questo. Trovati e non toccati: `filelength` senza chiamanti, la condizione rovesciata su `rtllist` (riga 924) |
| `w_sprite` | 513 | 3 | `W_TextureAsPatch` (127), `W_CacheSpriteNum` (105), `W_CacheSpriteNumUntranslated` (58); `TSpriteLumpCache` e' gia' una classe | **rimandata** (1 giorno): `W_TextureAsPatch` e' pura e va in `Libs\Imaging` estendendo `TImagingPatchWriter` (oggi: altezza massima 255, nessuno spezzamento a 128); il corpus non la esercita (sprite PNG esterni) |
| `w_pak` | 347 | 15 su 16 | `PAK_DirectoryArray` (11) | **resta storica**: gia' facciata |
| `w_utils` | 207 | 2 | cinque comandi di console (88) | **rimandata** (mezza giornata): lo schema e' `TConsoleUtilityCommands` di `Libs\Console` (fetta 1e); tre `printf` hanno meno argomenti del formato (righe 108, 133, 135): difetto da decidere se conservare |
| `w_wadreader`, `w_wadwriter` | 273, 202 | tutto | nessuna (`TWadReader`, `TWadWriter` sono classi sopra `IWadSource`/`IWadBuilder`) | **restano**: gia' classi |
| `z_zone` | 515 | 17 (150) | tre comandi (52) | **resta storica**: gia' facciata di `TZoneAllocator` |
| `i_video` | 772 | 7 (47) | fredda: `I_InitGraphics` 60, `I_ChangeFullScreen` 73, `I_FindWindowSize`, Alt-Tab (244 in tutto); calda: `I_BlitBuffer` 89 e le due `I_FinishUpdate8_64*` (la conversione da 8 a 32 bit del fotogramma, in fili), `I_SetPalette64` | **rimandata** con `v_video` (stessa fetta "presentazione del fotogramma"): la parte fredda e' regia sopra classi che ci sono gia' (`IDisplayModeCatalog`, `IEngineFramePresenter`, `IEngineDisplayResolution`); la parte calda converte ogni fotogramma a 8 bit |
| `v_data` | 196 | - | una routine di 6 righe (`V_ReadPalette`) | **resta storica**: dati |
| `v_displaymode` | 186 | 2 | `V_SetDisplayMode` (27) e `V_DoSetDisplayMode` (35: chiude e riapre venti sottosistemi) | **resta storica** per ora: la seconda e' la regia del cambio di modo e tocca `r_*` (fuori dal perimetro); alla riga 133 `nwidth := MAXHEIGHT` scrive la larghezza al posto dell'altezza (difetto, non toccato) |
| `am_map` | 2315 | 11 (63): finestra, zoom, segni, rotazione, ritaglio sono `Libs\Automap` | fredda 12 routine (775): `AM_Init` 339 (forme e cheat), `AM_Responder` 172; calda 10 routine (744): Bresenham, griglia, muri, giocatori, cose, sfondo | **a classi ora il Bresenham** (fatto, 12.2); **rimandato** il resto (3-4 giorni): 62 direttive di gioco nei cicli (colori, flag, tipi di linea): servono le regole per gioco della fase 2 |
| `am_textured` | 925 | nessuna (usa `TAutomapRotation`, `TAutomapTransform`) | calda 8 routine (600): riempimento a scanline dei sottosettori, quattro `AM_DrawSeg*` per pixel | **rimandata** (2-3 giorni, regole del caldo): legge `flats`, colormap e settori come il renderer dei piani; va con la fetta 3e |
| `v_video` | 5739 | 6 routine (52) | fredda circa 420 righe, calda circa 4000: vedi 12.3 | **non fatta in questo giro**: censimento per famiglia e proposta di fette in 12.3 |

`d_*` in `Base\` (`d_event`, `d_ticcmd`, `d_think`, `d_net`, `d_net_h`, `d_notifications`): gia' decise dalla fetta 1e (par. 8).

### 12.2 Fatto in questo giro

- **`f_wipe`** (354 -> 260 righe). **Riuso**: `TImagingMeltWipe` (`Libs\Imaging`, c'era dalla #77 con i test sui golden del vecchio codice). **Esteso** con `StartOnBuffers` (stessi calcoli, puntatori ai buffer del motore: non era collegata per la copia di `screen32` a ogni fotogramma) e reso `sealed`. **Nuovo**: `TEngineImagingRandom` (`Base\`, 47 righe: `IImagingRandom` sopra `IGameRandom.NextUnpredictable`; non c'era un adattatore perche' il melt non era collegato). `wipe_Configure` in `ComposeImaging`, senza configurazione `I_Error`. Una chiamata a interfaccia per fotogramma del wipe; i cicli per colonna e per pixel sono dentro la classe, su puntatori. Le posizioni delle colonne non stanno piu' nella zone memory.
- **`s_sound`** (2297 -> 2135). **Nuovo in `Libs\Audio`**, perche' non c'era un equivalente (`TSfxPlayer.FindChannelToReplace` sceglie tra le 32 voci del dispositivo, non tra i canali del gioco per origine e priorita'; `TQ3Listener` e `TQ3ChannelPool` sono le regole di Quake III, con altre formule): `TSfxAttenuation` (distanza, clipping, separazione, volume, pitch), `TSfxChannelPicker` (la scelta del canale come decisione senza effetti), `TExternalMusicNames` (la lista dei nomi mp3 e gli alias). Classi `sealed` di funzioni statiche, senza interfacce: si chiamano per ogni suono che parte e per ogni canale a ogni tic; `R_PointToAngle2` e `finesine` arrivano una volta in un record di regole.
- **`am_map`** (2315 -> 2263): `TAutomapLineRasterizer` (`Libs\Automap`, `sealed`, statica: `Draw8`/`Draw32`; la profondita' si sceglie una volta per linea, non per pixel come faceva `PUTDOT`).

Test, copertura e golden: par. 8.

### 12.3 `v_video`: censimento per famiglia e proposta di fette

91 routine (con overload, varianti `_MT`/`_thr` e doppioni per OpenGL), 90 direttive di compilazione. Chiamanti contati per file.

| Famiglia | Varianti | Righe | Chiamanti | Quando gira |
|---|---:|---:|---|---|
| configurazione (`V_ConfigureGamma`, `V_ConfigureDrawTextures`, `V_ConfigureFlatShrink`, `V_ShrinkFlatTo64x64`) | 6 | 52 | composition root | avvio: gia' delega |
| `V_Preserve*`, `V_NeedsPreserve`, `V_CalcPreserveTables` | 11 | 125 | 4 | per chiamata dentro il disegno |
| `V_Init`, `V_ReInit`, `V_ShutDown`, `V_ScreensSize`, `V_GetScreenWidth/Height` | 6 | 134 | 4-18 | avvio e cambio di modo |
| palette (`V_SetPalette`, `V_CalcColorMapPalette`, `V_InitDefaultPalette`) | 3 | 100 | 22 | a ogni cambio di palette (anche i lampi) |
| `V_FindAproxColorIndex` (+ `Excluding`) | 2 | 74 | 15 | costruzione delle tabelle |
| `V_CopyCustomScreen` | 3 | 86 | 2 | immagini intere a richiesta |
| `V_CopyRect` (8, 32, `_MT`, fili) | 7 | 955 | 14 | ogni fotogramma (barra di stato, finale, console) |
| `V_CopyAddRect` | 1 | 97 | 1 | console aperta |
| `V_CopyRectTransparent` | 7 | 435 | 12 | ogni fotogramma (menu, barra) |
| `V_CopyRectTransparentEx` | 7 | 325 | 5 | menu |
| `V_ShadeBackground` / `V_ShadeScreen` | 2 | 122 | 5 | menu |
| `V_CopyScreenTransparent` | 3 | 74 | 1 | bordo della vista |
| `V_CopyRawDataToScreen`, `V_RemoveTransparency` | 2 | 51 | 1 | a richiesta |
| `V_DrawPatch` | 5 | 385 | 29 | ogni fotogramma (HUD, barra, menu) |
| `V_DrawPatchTransparent` | 8 | 683 | 3 | ogni fotogramma |
| `V_DrawPatchZoomed` | 3 | 223 | 4 | automap, menu |
| `V_DrawPatchFlipped` | 1 | 57 | 2 | finale |
| `V_ScaleBuffer8`, `V_DrawPatchFullScreenTMP*` | 7 | 115 | 5 | intermezzo e finale |
| `V_PageDrawer` | 2 | 90 | 11 | pagine a schermo intero |
| `V_TileScreen8` | 1 | 85 | 3 | testo del finale |
| `V_FullScreenStretch`, `V_StatusBarStretch` | 4 | 206 | 7 + 2 | finale, intermezzo, barra di Doom |

Proposta, dal freddo al caldo (ogni fetta: golden a 8 e a 32 bit, piu' il confronto `-ExtraIni` con `screenblocks` ridotto per bordo e barra; le fette calde anche misura a coppie):

1. **Palette e colori** (circa 175 righe, fredda): `V_SetPalette`, `V_CalcColorMapPalette`, `V_InitDefaultPalette` e `V_FindAproxColorIndex` su `Libs\Palette` (`IColorMatcher` c'e' gia': lo usa `TEngineImagingColorIndex`) e sul `IPaletteConverter` di `Libs\Video`. Mezza giornata. Rischio: il gamma nei lampi (i golden lo coprono: i fotogrammi cambiano palette).
2. **Schermi e misure** (circa 260 righe, fredda): `V_Init`/`V_ReInit`/`V_ShutDown`, `V_ScreensSize` e le tabelle `V_Preserve*` in una classe `sealed` di `Libs\Video` (le `V_Preserve*` si chiamano per patch: funzioni statiche su tabelle, mai un'interfaccia); `Base\DelphiDoom.Engine.Video.Screens` esiste gia' ed e' il posto dell'adattatore. 1 giorno.
3. **Patch** (circa 1350 righe, calda): `V_DrawPatch*` in disegnatori `sealed` per profondita' (8 o 32 bit) e variante (opaca, trasparente, ingrandita, rovesciata), scelti una volta per chiamata come oggi; il ciclo per colonna resta su puntatori. Riuso: la lettura dei post e' di `Libs\Imaging` (`TImagingPatchReader`), ma **senza** copie in `TBytes`: serve la variante a puntatori, come per il melt. 3 giorni con misura; le varianti OpenGL (`gld_*`) restano rami della facciata.
4. **Rettangoli** (circa 1900 righe, calda): `V_CopyRect*` e le trasparenti; le sette varianti di ogni famiglia differiscono per profondita' e per i fili: un solo ciclo per profondita' (metodo statico o include). 3 giorni con misura. E' la fetta con piu' duplicazione da togliere.
5. **Pagine e stiramenti** (circa 500 righe, tiepida): `V_PageDrawer`, `V_FullScreenStretch`, `V_StatusBarStretch`, `V_TileScreen8`, `V_ScaleBuffer8`. 1 giorno; i golden coprono titolo e intermezzo.
6. Con la 3 e la 4: `I_BlitBuffer` e `I_FinishUpdate8_64*` di `i_video` (la conversione del fotogramma), con le regole del caldo.

Stima per `v_video` + `i_video`: 9-10 giorni di agente, a macchina scarica per le misure.

### 12.4 Cosa resta della fase 1

| Voce | Stima |
|---|---|
| `v_video` e `i_video` (12.3) | 9-10 giorni |
| `am_map` (forme, tasti, colori, muri, giocatori, cose, griglia) e `am_textured` | 5-7 giorni, dopo le regole per gioco della fase 2 |
| `sounds`, regola dei nomi di `s_pk3sounds`, colla di `s_sound` | 2 giorni, con la fetta 2i |
| `w_sprite` (`W_TextureAsPatch` in `Libs\Imaging`) | 1 giorno |
| `w_utils` (comandi di console in `Libs\Console`) | mezza giornata |
| `i_main` + `i_mainwindow` + `i_startup` (finestra e schermata di avvio, insieme a `gl_main`) | 2-3 giorni |
| restano storiche per decisione | `w_wad` (cache e directory del motore), `w_pak`, `w_wadreader`, `w_wadwriter`, `z_zone`, `v_data`, `v_displaymode`, i tipi `d_*` |

## 13. Fette successive della #185: elenco ordinato (2026-11-14, dopo la 2c-4)

Ordine di esecuzione consigliato; ogni ondata di agenti ne prende una. Le stime sono giorni di agente (una fetta di `Libs\` costa 35-50 minuti di sviluppo e 1-2 ore di verifica quando il lock dei giochi e' conteso: i giorni qui contano la lettura delle copie, la forma delle regole e le prove, non la sola scrittura). Le righe sono quelle dei file attuali (Doom/Heretic/Hexen/Strife). **Regola di ogni fetta**: tabella di confronto con `Confronta-Copie.ps1`, regole per gioco con il testo vecchio alla lettera, prova meccanica (`Prova-Common.ps1`), `Verifica-Ridotta.ps1` a ogni passo, corpus intero una volta, build dei dieci giochi, Doom32 e Strife32 a Win64, misura a coppie a macchina scarica.

### 13.1 Fase 2 (logica), nell'ordine

| # | Fetta | Righe oggi | Stima | Rischi e note |
|---|---|---|---|---|
| 1 | ~~**2c-4**: il resto di `p_mobj` e `p_map`~~ **fatta** (par. 11.5, 2026-11-14): `P_SpawnMapThing` (Doom, Heretic, Strife), `P_HitFloor` e `P_SpawnPlayerMissile` (Doom, Strife), `PIT_ChangeSector` e la coda di contatto di `PIT_CheckThing` (tutti), `P_SetMobjStateNF` di Heretic e Hexen; il resto e' proprio con la ragione scritta | - | - | `P_CheckForPushSpecial` riprovato e lasciato (par. 11.5). Resta aperta solo la misura a coppie a macchina scarica |
| 2 | ~~**2f-1 `p_user`** (`TUserGameRules`)~~ **fatta** (par. 11.6, 2026-11-15): `Base\p_user.pas` per i quattro giochi (6382 -> 5402 righe), `P_Thrust`, `P_CalcHeight` e famiglia, `P_MovePlayer` (tutti), `P_DeathThink` e `P_PlayerThink` (Doom, Heretic, Strife; Hexen proprie con la ragione scritta), unit di famiglia `PlayerExtras`, `PlayerThinker`, `PlayerColormap`, `PlayerArtifacts` | - | - | Restano duplicate con ragione: `P_UseArtifact`, `P_PlayerUseArtifact`, `P_ArtiTele`, il volo di Heretic e Hexen (candidato). Misura a coppie: vedi par. 11.6 |
| 3 | ~~**2f-2 `p_inter`**~~ **fatta** (par. 11.7, 2026-11-15): `Base\p_inter.pas` (`P_CmdSuicide`, `P_GiveBody`, `P_DamageFlagFilter`) con `TInterGameRules` per gioco, `PickupGivers` (`P_GiveArmor`, `P_SpawnDroppedMobj`), `SpecialRespawn`, `MinotaurSlam` e `P_AutoUseHealth` in `PlayerArtifacts`; `P_DamageMobj`, `P_KillMobj` e `P_TouchSpecialThing` restano propri con la ragione scritta | - | - | I punti 1 e 3 di Rad-X stanno ora nel metodo `DamageMobj` di `Doom\DelphiDoom.Engine.World.InterRules.pas` (firma di `P_DamageMobj` invariata). Prossima: `p_pspr` (riga 4) |
| 4 | ~~**2f-3 `p_pspr`**~~ **fatta** (par. 11.8, 2026-11-15): `Base\p_pspr.pas` per i quattro giochi (7280 -> 6760 righe): `P_SetPsprite`, `P_SetupPsprites`, `P_MovePsprites`, `A_Light0`, `P_DropWeapon`, `A_ReFire`, `A_Lower`, `A_Raise` con `TPspriteGameRules` (`PspriteRules` per gioco) | - | - | Restano proprie con la ragione scritta: `P_BringUpWeapon`, `P_CheckAmmo`, `P_FireWeapon`, `A_WeaponReady` e le armi di ogni gioco. Misura a coppie non conclusiva (par. 11.8). Prossima: `p_enemy` (riga 5) |
| 5 | ~~**2f-4 `p_enemy`**~~ **fatta** (par. 11.9, 2026-11-15): `Base\p_enemy.pas` per i quattro giochi (18139 -> 17365 righe con le unit nuove): `P_RecursiveSound`, `P_NoiseAlert`, `P_MeleeRange`, `P_TryWalk`, `P_LookForTargets`, `P_Move` (Hexen ha la propria), `P_NewChaseDir`, `A_FaceTarget` con `TEnemyGameRules` (`EnemyRules` per gioco) | - | - | Restano proprie con la ragione scritta: `P_LookForPlayers`, `A_Look`, `P_DoChase`, `A_Chase`, `P_CheckMeleeRange`, `P_CheckMissileRange`, `A_Pain`, `A_Fall`, `P_Massacre` e le azioni di ogni mostro e gioco. Prossima: `p_spec` e `p_switch` (riga 6) |
| 6 | ~~**2g `p_spec` e `p_switch`** con `Libs\Specials`~~ **fatta** (par. 11.10, 2026-11-15): `Base\p_spec.pas` e `Base\p_switch.pas` per i quattro giochi (14766 -> 13678 righe non vuote con le unit nuove): le utilita' dei settori con `TSpecGameRules`, `FrictionPushers` e `SectorSearch` (Doom e Strife) in `Base\`, i tipi in `p_spec_h` per gioco, il vecchio testo in `SpecRules` e `SwitchRules` | - | - | Restano proprie con la ragione scritta: i grandi `case` (`P_CrossSpecialLinePtr`, `P_ShootSpecialLine`, `P_PlayerInSpecialSector`, `P_UpdateSpecials`, `P_SpawnSpecials`, `P_UseSpecialLine`), `P_InitPicAnims`, `P_ChangeSwitchTexture`, le routine di Hexen (ACS). `Libs\Specials` non usata (par. 11.10). Prossima: i thinker rimasti (riga 7) |
| 7 | **Thinker rimasti** (par. 10.6, 2e-1 finita) | `Heretic\p_floor` 411; `p_plats` 272/256/279; `p_lights` 387/382/404; `p_telept` 460/246/463; `p_doors` 394/286/1335; `udmf_ceilng`, `udmf_floor` | 3-4 | `Libs\Thinkers` ha gia' i profili e gli adattatori; `p_doors` di Strife e' tre volte quello di Doom (dialoghi, porte che chiedono una chiave); i record dei thinker non si toccano (salvataggi) |
| 8 | **Stadio 2 dello stato** (par. 10.3) per i globali che i salvataggi non scrivono (`tm*`, `spechit`, le variabili di `p_mobj`) | circa 120 globali | 2 | il punto piu' pericoloso e' `@thinkercap`; si fa solo per cio' che `p_saveg`/`sv_save` non toccano; il resto con la 9 |
| 9 | **2h `g_game`** (sessione, demo, rete) e salvataggi (`Libs\Serializer`) | 3894/3632/2439/3505; `p_saveg`, `sv_save` | 5-6 | **bloccata finche' i salvataggi non sono liberi**; il rischio piu' alto di tutta la fase 2: demo, rete e salvataggi byte per byte; serve un corpus di salvataggi vecchi che si caricano |
| 10 | **2b** (`p_maputl`, `p_sight`, `p_slopes`, `p_3dfloors` come servizi del mondo) | gia' in copia unica | 1 | pura forma: il mondo li espone; si fa quando i chiamanti sono gia' sul mondo |
| 11 | **2i, 2j**: tabelle `info*`/`sounddata` e menu, barre di stato, intermissioni, finali | `info*` 175000 righe (dati); `m_menu`, `st_*`, `wi_*`, `f_finale` quadruplicati | 3 + 4-5 | le tabelle sono dati: generatore e prova di uguaglianza; il resto e' freddo ma quadruplicato |

### 13.2 Fase 1 (il freddo rimasto; dettagli e stime nel par. 12.3 e 12.4)

| # | Fetta | Stima | Note |
|---|---|---|---|
| 1 | `w_utils` (comandi di console in `Libs\Console`) | mezza giornata | tre `printf` con meno argomenti del formato: decidere se conservare |
| 2 | `w_sprite` (`W_TextureAsPatch` in `Libs\Imaging`) | 1 | pura; il corpus non la esercita (sprite PNG esterni) |
| 3 | `v_video` fette 1 e 2 (palette, schermi e misure) | 1,5 | fredda; i lampi di palette li coprono i golden |
| 4 | `sounds`, regola dei nomi di `s_pk3sounds`, colla di `s_sound`, con la 2i | 2 | scrive le tabelle `S_sfx`/`S_music` |
| 5 | `i_main`, `i_mainwindow`, `i_startup` con `gl_main` | 2-3 | finestra: nessun golden copre fuoco, icona e schermo intero |
| 6 | `v_video` fette 3-5 (patch, rettangoli, pagine) e `i_video` (blit) | 7-8 | caldo: misura a coppie; varianti OpenGL restano rami della facciata |
| 7 | `am_map` (dopo le regole per gioco) e `am_textured` | 5-7 | 62 direttive di gioco nei cicli; `am_textured` va con la 3e |

### 13.3 Fasi 3, 4, 5

| Fase | Contenuto | Stima | Note |
|---|---|---|---|
| 3 | renderer software, fette 3a-3i (par. 4) | 20-30 | rischio alto; prima 3a (vista) e 3b (dati), poi per ordine di costo crescente; a 64 bit i fotogrammi differiscono gia' di 1-2 pixel su pochi fotogrammi (par. "Aree ancora aperte" di `CLAUDE.md`): la parita' del renderer si misura a 32 bit |
| 4 | renderer OpenGL (#177) | in corso | in parallelo, con il suo registratore delle chiamate |
| 5 | chiusura: cancellare le facciate senza chiamanti, `Common\d_delphi.pas`, togliere la sezione "codice storico per scelta" di `CLAUDE.md`, Win64 per il motore | 5-8 | dopo la fase 2 |

### 13.4 Fuori elenco, da non dimenticare

- **La misura a coppie formale** (entro il 5% con minimo e mediana) non e' ancora stata chiusa da nessuna fetta della fase 2: va rifatta a macchina scarica con `Tools\Misura-Giro.ps1` quando nessun altro agente gira.
- **Radix** (aggiornato dalla 2c-4): il contatto con le cose (punto 4) sta ora in `CheckThingContact`, `CanBePushed` e `PicksUpOnContact` di `Doom\DelphiDoom.Engine.World.MapRules.pas` (le due funzioni `P_PushByContact` e `P_ContactPickup` sono in `Base\p_map.pas`), lo schiacciamento dei settori in `CrunchBody` e `CrushBlood` (`PIT_ChangeSector` e' in `Base\p_map.pas`); nessuna firma delle tredici e' cambiata. La fisica (tredici punti di aggancio, `Libs\Radix\CLAUDE.md`) aspetta `p_user` e `p_inter` (fatti: i punti 1 e 3 stanno ora nel metodo `DamageMobj` di `Doom\DelphiDoom.Engine.World.InterRules.pas`, par. 11.7); con la 2c-3 `P_ZMovement` e' in `Base\p_mobj.pas` e il punto 6 (rimbalzo su pavimento e soffitto) va nelle regole `ZHitFloor` e `ZHitCeiling` di `Doom\DelphiDoom.Engine.World.MobjRules.pas`.
- **Test di unita'** delle unit delle regole: restano provate dai golden e dalla prova meccanica; una copertura a livello di classe richiede un mondo finto (`TEngineWorld` con record in memoria), che la fetta 8 rende possibile.
