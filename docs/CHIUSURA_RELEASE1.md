# Chiusura della Release 1

Documento di lavoro per chiudere la Release 1 (`refs #185`). Scritto il 2026-11-19 contro `master` `67537a5e3` (ondata 13). **Nulla di quanto scritto qui e' stato pubblicato su GitHub**: i testi dei commenti sono pronti da incollare; le chiusure le fa l'utente.
La misura e' preparata, non eseguita: `Tools\Misura-Finale.ps1` (vedi par. 1.3). Gli `<SEGNAPOSTO>` si riempiono dal rapporto `docs\MISURA_FINALE_<data>.md` che lo script scrive.

Indice: 1. Congelamento (prima e dopo la misura) - 2. Schede delle 15 issue - 3. Tabella finale - 4. Divergenze trovate tra documenti e codice - 5. Segnaposto dei commenti.

## 1. Congelamento

### 1.1 Cosa deve essere vero PRIMA della misura (e come controllarlo)

La misura vale solo se il codice e' fermo e la macchina e' scarica. `Tools\Misura-Finale.ps1` ripete i controlli 1-8 da solo e si ferma (codice 2, nessuna azione) se uno manca; `-DryRun` li stampa senza fare nulla.

| # | Condizione | Comando di controllo |
|---|---|---|
| 1 | Si e' nel checkout principale, su `master`, albero pulito (nessun file modificato o non tracciato) | `git rev-parse --abbrev-ref HEAD` (deve dare `master`) e `git status --porcelain` (vuoto) |
| 2 | `master` e' pubblicato: HEAD uguale a `origin/master` | `git fetch origin master` poi `git rev-list --left-right --count HEAD...origin/master` (deve dare `0 0`) |
| 3 | Nessun ramo di agente con lavoro non unito, nessun altro worktree attivo | `git branch --no-merged master` (vuoto) e `git worktree list` (solo la radice) |
| 4 | Nessun altro `claude` attivo e nessun agente che compili | `Get-Process claude -ErrorAction SilentlyContinue` (nessuno, a parte la sessione che lancia lo script se non si usa `-IgnoraClaude`) |
| 5 | Nessun `act_runner` (Gitea/GitHub Actions): **al momento della stesura ce n'e' uno in esecuzione sulla macchina (PID 6152)**; va fermato prima e riavviato dopo | `Get-Process act_runner -ErrorAction SilentlyContinue` (nessuno); fermarlo come servizio o come processo, dopo aver controllato che non abbia lavori in corso |
| 6 | Nessun compilatore, gioco o test in esecuzione; nessun Doom32 orfano | `Get-Process dcc32,dcc64,msbuild,bds,Doom32,GLDoom32,Heretic32,Hexen32,Strife32 -ErrorAction SilentlyContinue` (nessuno) |
| 7 | CPU libera (media sotto il 10%), niente scansione antivirus, niente Windows Update, scheda di alimentazione "Prestazioni elevate", nessun browser o IDE aperto con compilazioni in corso | `Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'"` (ripetere 3 volte) |
| 8 | Spazio libero su C: di almeno 6 GB (tre worktree da circa 0,2 GB piu' `dcu` e `bin`: 3-5 GB; al momento della stesura erano liberi circa 10 GB) e cartelle `C:\ddold`, `C:\ddoldgl`, `C:\ddnewgl` assenti | `Get-PSDrive C` e `Test-Path C:\ddold,C:\ddoldgl,C:\ddnewgl` (tutti `False`) |
| 9 | I WAD sono in `bin\Doom` (`DOOM1.WAD`, `FREEDOOM2.WAD`) e Delphi 11 e' installato | `Test-Path bin\Doom\DOOM1.WAD` e `Test-Path "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"` |
| 10 | La verifica standard del ramo e' verde sul `master` che si misura: dieci giochi, `ddc_*` e strumenti compilano (avvisi non saliti), suite verdi, tre demo di Doom32 (5026/3836/2134 gametic), avvio senza crash, golden 44/44 a 8 e a 32 bit (circa 45 minuti) | `powershell -NoProfile -File Tools\Verifica\185\Verifica-Ramo.ps1 -Root C:\Progetti\DelphiDoom` (esce con 0) |
| 11 | Win64: i giochi software compilano e il corpus e' uguale ai golden a Win64 | `Tools\build.bat giochi Release Win64` e `powershell -NoProfile -File Tools\Verifica\40\Confronta-Bitness.ps1` (uso nella testata dello script) |
| 12 | Layout dei salvataggi uguale ai golden e tra 32 e 64 bit; prove dei salvataggi dopo `ondata8-245-5` (dichiarate non fatte in `docs\INVENTARIO_NON_MIGRATO.md`, C18) | `powershell -NoProfile -File Tools\Verifica\40\Prova-Layout.ps1` (senza `-Update`) e `Tools\Verifica\40\Prova-Salvataggi.ps1` |
| 13 | Flusso OpenGL vecchio contro nuovo UGUALE sul `master` aggregato: **non e' stato rieseguito dopo le ultime unioni** (commento della #177: "dopo due blocchi di Windows con probabile driver grafico VMware i giochi OpenGL si eseguono solo uno alla volta sotto controllo") | per ogni gioco: `powershell -NoProfile -File Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom` (poi `GLHeretic`, `GLHexen`, `GLStrife`; con `-Lights`, `-Models`, `-Voxels` per le varianti); impronte: `Tools\Verifica\opengl\Impronte.ps1` |
| 14 | `strati` senza violazioni nuove (provato oggi su questo ramo: 0 violazioni nuove, 1 eccezione dichiarata) | `Tools\build.bat strati` (esce con 0) |
| 15 | I ganci del registratore applicano al `master` che si misura (`hook-gl.patch`: provato oggi, applica) e al vecchio OpenGL (`hook-gl.pre-glcontext.patch` su `4282c434d`: provato oggi su un worktree, applica; `Misura-Finale.ps1` lo ripete dopo aver creato i worktree) | `git apply --check Tools\Verifica\opengl\hook-gl.patch` |
| 16 | Divergenze del par. 4 lette; quelle che cambiano il significato dei numeri (n. 12) corrette nei documenti prima del rapporto | par. 4 di questo file |
| 17 | Nessun commit su `master` dopo il controllo 2 fino alla fine della misura (qualunque commit rende il rapporto "non del master pubblicato") | - |

Regola: se un controllo della tabella fallisce dopo l'inizio della misura, la misura si butta (il rapporto parziale e' marcato `IN CORSO`/`INCOMPLETO`).

### 1.2 Avvertenze sulla misura

- **Il giro OpenGL puo' bloccare Windows** (storia della #177: due schermate blu, driver grafico della VM). Per questo lo script esegue prima il software e poi l'OpenGL, **riscrive il rapporto dopo ogni passo** (`IN CORSO`) e lascia i giochi uno alla volta (lock globale di `Tools\Esegui-gioco.ps1`). Dopo un blocco il rapporto parziale e i log `logs\MisuraFinale_*.log` restano; i worktree `C:\ddold*` vanno tolti a mano (`git worktree remove --force <cartella>`, poi `git worktree prune`).
- Il registratore OpenGL e' solo Win32 e il GL e' quello software della VM (se la macchina e' una VM): i numeri dell'OpenGL valgono come rapporto vecchio/nuovo, non come prestazione assoluta.
- Per non toccare `master` con le patch di `Compila.ps1` (che applica e toglie `hook-gl.patch` e costruisce con `DCC_Define=GLRECORD`) lo script costruisce i due GLDoom32 in due worktree separati (`C:\ddoldgl`, `C:\ddnewgl`); Doom32 nuovo si costruisce in `master` con `clean`.
- **Lanciarlo da un terminale normale** (PowerShell o `cmd`), non da una chiamata di strumento di Claude Code in primo piano: dura da 1,5 a 4 ore e li' un comando viene interrotto dopo 10 minuti. Il controllo "nessun altro processo claude" scatta per ogni processo di nome `claude*` (nel prova a secco di oggi: 4, le sessioni aperte): chiuderle, oppure `-IgnoraClaude` sapendo che la misura e' a rischio.
- **Il vecchio OpenGL `4282c434d` e' precedente a `TEngineGlContext`**: `hook-gl.pre226.patch` (che modifica `Libs\OpenGl\Legacy\DelphiDoom.Engine.GlContext.pas`) **non applica** a quel commit (provato con `git apply --check` su un worktree vero). `Compila.ps1 -Which Old` ora sceglie da solo `hook-gl.pre-glcontext.patch` (nuovo, e' il `hook-gl.patch` del 2026-11-15, commit `f1865b58a`, che applica a `4282c434d` e usa le stesse funzioni di `HarnessGl.pas`). `Misura-Finale.ps1` fa `git apply --check` delle due patch subito dopo aver creato i worktree: se una non applica salta la parte OpenGL (avviso nel rapporto, uscita 2) e prosegue col software, invece di fallire dopo le build.
- Una combinazione che da' errore (gioco morto, timeout, nessun numero) e' registrata come `errore` e ripetuta una volta, **non** come "oltre il 5%".
- Misura software: `demo1` come nelle misure precedenti. Per la seconda demo (`demo3`) rilanciare con `-Demo demo3 -SaltaGl` (il rapporto prende un nome nuovo, `MISURA_FINALE_<data>_2.md`). Un rapporto del giro precedente lasciato non tracciato in `docs\` non sporca `master` per il controllo 1; se invece lo si committa, va anche pubblicato (controllo 2) prima di rilanciare.
- Non misurati dallo script: Heretic, Hexen, Strife, Radix32, SpeedHaste32 (opzione `-Game` di `Tools\Misura-Coppie.ps1`); `m_fixed` in Pascal (voce A8 dell'inventario: `Tools\Verifica\185\Fetta-1c-m_fixed-pascal.patch` da rimisurare a macchina scarica); `MoveSprites` di Greed (`Tools\Verifica\175-sprites\Compila.ps1 -Misura 31`, #175 punto 6). Quest'ultimo si lancia **dopo** Misura-Finale, nella stessa condizione di macchina scarica.

### 1.3 Il comando

```
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1 -DryRun     (controlla e stampa il piano: esce con 0 solo se le precondizioni sono tutte vere)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1              (la misura; da 1,5 a 4 ore, lasciare la macchina ferma)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1 -VecchioSw c6c8903c -VecchioGl 4282c434d -Coppie 9 -Demo demo1 -DemoGl demo3 -SecondiGl 450 -CoppieGl 5
```

Codici di uscita: 0 tutte entro il 5%; 1 almeno una oltre il 5%; 3 almeno una non affidabile (o in errore) dopo il secondo tentativo; 2 precondizione o passo fallito, o parte OpenGL saltata (il rapporto e' marcato `INCOMPLETO`). Il vecchio e' `c6c8903c` (software, prima della fetta `p_user`: stesso riferimento delle misure del 2026-11-16) e `4282c434d` (OpenGL, come le misure della #177).

### 1.4 Cosa fare DOPO la misura (in ordine)

1. **Leggere** `docs\MISURA_FINALE_<data>.md`. Verdetto software: ogni riga "entro il 5%" con dispersione del vecchio sotto il 3%. Se una combinazione e' "oltre il 5%": **non si chiude nulla**; si cerca la tornata colpevole con `git bisect` sui tag (par. 1.5) e si annulla il passo (regola della #185). Se "non affidabile" anche dopo il secondo tentativo: ripetere piu' tardi a macchina scarica, o dichiarare la misura "indicativa" come hanno fatto i commenti del 2026-11-16 (non vale come "entro il 5%").
2. **Committare il rapporto** (nessun codice): messaggio `docs(185): misura finale della Release 1` con `refs #185` e il tempo come da regola (XS `@25m`).
3. **Pubblicare i commenti** sulle issue (par. 2), sostituendo `<NUMERO MISURA SW>` e `<NUMERO MISURA GL>` con i paragrafi "Testi pronti per i commenti" del rapporto (li produce lo script con i numeri veri). Ordine: prima le figlie (#244, #245, #246, #247, #248, #249, #250), poi #177, #185, #40, #175, #203, #157, #206. Esempio: `gh issue comment 244 --repo punga78/DelphiDoom --body-file <file>`.
4. **Chiudere** le issue della tabella del par. 3 (colonna "chiudibile"): `gh issue close <n> --repo punga78/DelphiDoom --comment "<testo>"`. Le decisioni "chiudibile con motivazione" spettano all'utente (par. 3).
5. **Aggiornare `docs\`**: `CLAUDE.md` di radice (riga di stato: "Release 1 chiusa il <data>", misura, e le correzioni del par. 4), `docs\PIANO_TUTTO_A_CLASSI.md` par. 13.4 (la misura a coppie e' chiusa: oggi dice di no) e par. 8, `docs\INVENTARIO_NON_MIGRATO.md` par. 4.2 (riga "Prestazioni") e par. 5 (decisioni prese), `docs\PARITA_MOTORE.md` par. 4 (risultato della misura finale), `docs\PENDING_ISSUES.md` (togliere le voci chiuse; spostare le restanti in Release 2), `docs\PROVE_A_MANO.md` (resta, e' la lista della #239). Aprire una issue "Release 2: residuo della #185" con R2 + MC non fatte (o aggiungerle alla #252).
6. **Tag di release** `v1.0.0` (proposto), annotato, sul commit che contiene il rapporto: `git tag -a v1.0.0 -m "Release 1: tutto a classi, Win32 e Win64, OpenGL in classi, misura finale entro il 5%"` poi `git push origin master --tags` (lo fa l'utente). I tag `ondata*` restano (servono al bisect).
7. **Riavviare** `act_runner` e togliere i residui: `git worktree list` deve mostrare solo la radice; `C:\ddparity` si lascia (e' la cartella di lavoro dei golden).

### 1.5 Se la misura da' "oltre il 5%": dove cercare

I tag per il bisect (da `git tag -l`): `ondata-notte-244-1`, `ondata-notte-245-1..4`, `ondata-notte-246-1..7`, `ondata-notte-247-1..6`, `ondata-notte-177v-1..3`, poi `ondata2` ... `ondata13` per fetta (`-185`, `-244`, `-245`, `-246`, `-247`, `-177`, `-40`). Ultima misura buona: `cb99f3ff1` (2026-11-16, software entro +0,83%, OpenGL entro +2,3% sui minimi). Il comando di una singola coppia: `Tools\Misura-Coppie.ps1 -Vecchio <exe> -Nuovo <exe> -Demo demo1 -Coppie 9 -Modo 8`. Punti da guardare dichiarati nelle issue: coda di `PIT_CheckThing` (#185), `FracXStep` dal record e confronto per riga di `IndexCount` (#246), le routine `MT` di `r_sprite` e `R_RenderSegLoop` (#247).

## 2. Schede delle 15 issue

Legenda: **Stato** = cosa e' fatto (tag e paragrafi del piano `docs\PIANO_TUTTO_A_CLASSI.md`); **Manca**; **Dall'utente**; **Testo** = commento pronto (senza accenti, come i commenti precedenti).
I tag di ogni famiglia si leggono con `git tag -l 'ondata*-<numero>*'`.

### #40 Compilazione a 32 e 64 bit di tutto il progetto

- **Stato.** Le sotto-issue #41, #42, #43 e #44 sono chiuse. `Tools\build.bat all Release` compila 33 progetti su 33 a Win32 e a Win64 (10 DLL, 10 giochi, 13 strumenti); corpus intero dei golden 44/44 a 8 e a 32 bit per Win32 e per Win64 (stato e fotogrammi); salvataggi 32/64 incrociati uguali (`docs\SALVATAGGI_32_64.md`, `Tools\Verifica\40`); crash.txt a Win64 e `TFixedMath.Mul64` esatto; 12 scenari di virgola mobile uguali tra Win32 e Win64; nessun `{$L}`, l'asm resta a doppia versione `{$IFDEF CPUX86}` e in `ps_runtime`. Tag: `ondata2-40-1..5`, `ondata7-40-1..3` (e l'unione `6ca9b502`). Misura 2026-11-16 (`cb99f3ff1`, demo1, 9 coppie): quattro combinazioni entro +0,83%, dispersione sotto il 3% (commento sulla #40).
- **Manca.** Formati vecchi dei salvataggi (nessun file per provarli); audio, schermo intero, scheda grafica vera, DPI, rete a 64 bit (stanno in #239); flusso GL a Win64 non rieseguito; punti del renderer non coperti dal corpus (`r_fake3d`, `r_voxels`, `r_intrpl`, `fov`: provati con gli scenari `Tests\Data\Fp40`, escono uguali).
- **Dall'utente.** Le prove a mano (#239); accettare che i residui sopra vivano in #239 e #251.
- **Testo (chiusura, dopo la misura).**

```
Chiudo la #40: le quattro sotto-issue (#41, #42, #43, #44) sono chiuse e la condizione "fatto quando" e' soddisfatta sul master <SHA MASTER>.

- build.bat all Release a Win32 e a Win64: 33 progetti su 33.
- Corpus dei golden 44/44 a 8 e 32 bit, a Win32 e a Win64 (stato e fotogrammi); salvataggi 32/64 incrociati uguali; suite verdi su entrambe le piattaforme.
- Misura finale a macchina scarica: <NUMERO MISURA SW>

Non provati e passati ad altre issue: audio, schermo intero, scheda grafica vera, DPI e rete a 64 bit (#239); formati vecchi dei salvataggi (nessun file di prova, #251). Rapporto: docs\MISURA_FINALE_<DATA>.md.
```

### #157 Integrazione dei progetti di Reference: analisi, fetta 0 e piano

- **Stato.** Analisi in `docs\INTEGRAZIONE_REFERENCE.md` (aggiornata 2026-11-17) e `docs\INTEGRAZIONE_GIOCHI.md`; fetta 0 eseguita (progetti compilati e provati dove i dati bastano); le decisioni di licenza sono prese (2026-11-17, `docs\LICENZE.md`: tutto GPL v2 o successive, xGreed GPL v2 con nota di provenienza, Doom 3 e OpenXcom GPL v3 o successive, mai distribuiti SoundFont war1, TTF "DooM" e dati di Mars3D). Integrazioni: ENDEDIT, DD_FONT, DD_VOXEL fatte; Keen completata; xGreed giocabile; war1 molto avanzata; Radix e Speed in corso; OpenXcom molto avanzata; Mars3D non iniziata (nessun dato). Tag: `ondata8-157-1`, `ondata10-157-1`.
- **Manca.** Dati originali (Mars, Radix completo, Greed completo, UFO/TFTD per le prove piene); verifica giuridica delle licenze (non fatta da un avvocato: `docs\LICENZE_DA_VERIFICARE.md`); decisione sul perimetro dei fork (solo Mars? r_soft3d di Speed? LDD di DD_VOXEL?).
- **Dall'utente.** Confermare che l'issue era "analisi e piano" e si chiude; i residui continuano nelle issue dei singoli giochi (#169, #175, #251, #253).
- **Testo (chiusura con motivazione).**

```
Chiudo la #157: era l'analisi e il piano di integrazione, e quelli sono fatti.

- Quadro e ordine in docs\INTEGRAZIONE_REFERENCE.md (stato di 14 progetti) e docs\INTEGRAZIONE_GIOCHI.md; fetta 0 eseguita.
- Decisioni di licenza prese il 2026-11-17 e registrate in docs\LICENZE.md.
- Integrati: ENDEDIT, DD_FONT, DD_VOXEL, Keen Dreams (#165), xGreed (#175), Speed (#168), OpenXcom (#176), Rad-X (#169), war1 (#203).

Restano fuori, con la loro issue: dati mancanti (Mars3D, Radix/Greed completi) e residui senza oracolo, dati o licenza in #251; war1 in #253; verifica giuridica delle licenze in docs\LICENZE_DA_VERIFICARE.md.
```

### #175 xGreed: Greed32

- **Stato.** G0-G12 uniti: `Greed32` e' il gioco in finestra (menu, mondo, HUD, audio, filmati, intro, briefing, finali), parita' con l'originale a zero differenze (renderer 699 fotogrammi, mondo 155 partite per 3000 tic, `SpawnSprite` 5106 casi, IA, armi, HUD, menu, FLI, RearView, mouse, rete su `INetTransport`, salva e carica byte per byte); Win64 per build e suite; Greed 1269 test (copertura 100%). Tag: `ondata9-175-1..3`. Licenza: decisa il 2026-11-17 (GPL v2 con nota di provenienza, `docs\LICENZE.md`).
- **Manca.** (6) Misura a coppie di `MoveSprites` a macchina scarica (rapporto 1,008 a 31 coppie ma rifiutata per dispersione 29%): `powershell -NoProfile -File Tools\Verifica\175-sprites\Compila.ps1 -Misura 31` dopo Misura-Finale; (11) il commento del 2026-11-16 dice "serve una decisione" sulla licenza: la decisione e' stata presa il 2026-11-17, il commento va aggiornato. Non provati: Greed32 a Win64 in finestra, joystick vero, rete tra macchine, audio non ascoltato (#239).
- **Dall'utente.** Lanciare la misura di `MoveSprites`; confermare che la licenza e' chiusa.
- **Testo (chiusura, dopo la misura di MoveSprites).**

```
Chiudo la #175: Greed32 e' il gioco, con parita' a zero differenze sull'originale (renderer, mondo, IA, armi, HUD, menu, FLI, RearView, salvataggi) e 1269 test.

- Punto 6 (prestazioni di MoveSprites): misura a macchina scarica, 31 coppie: <NUMERO MISURA MOVESPRITES>.
- Punto 11 (licenza): decisa il 2026-11-17 (GPL v2 con nota di provenienza, docs\LICENZE.md).

Restano nella #239: Greed32 a 64 bit in finestra, joystick vero, rete tra due macchine, ascolto dell'audio.
```

### #177 Far sparire OPENGL

- **Stato.** La cartella `OPENGL` non esiste piu'. Fette 0-12 unite in classi `sealed` o semplici senza interfacce per elemento: registratore delle chiamate GL (criterio di parita'), voxel, MODELDEF, buffer di texture (`Framework`/`IdTech1\GlTexture`), carving e preprocessore del livello (`GlLevel`), automap (`GlAutomap`), scena (`GlScene`: lista di disegno, flat, muri, sprite, disegno, modelli, voxel, luci, lightmap, nebbia), contesto (`GlContext`) e facciate. Parita': flusso GL UGUALE vecchio/nuovo su 11 scenari (Freedoom 2, Doom 1, Heretic, Hexen, Strife, con automap, luci, modelli, voxel), 57 mappe UGUALI con `Impronte.ps1`; `Tests.OpenGl` 209 a Win32 e Win64; GL* compilano a Win64. Misura 2026-11-16 (`GLDoom32`, demo3): senza pacchetto minimi +0,2%, con luci +0,4%, modelli -0,4%, voxel +2,3% sui minimi (dispersione sotto il 3%). Tag: `ondata2-177-1..6`, `ondata3-177-1..4`, `ondata6-177-1..2`, `ondata8-177-1..2`, `ondata9-177-1..6`, `ondata-notte-177v-1..3`. Figlie aperte: #248, #249, #250.
- **Manca.** Cancellare `IdTech1\OpenGl\Legacy` (gl_render, gl_main, gl_tex, gl_sky, gl_setup, gl_slopes...: dipende dal "un solo eseguibile" della #252: `{$IFDEF OPENGL}` in 44 unit di `IdTech1\Base`, `docs\OPENGL_PIANO.md`); flusso GL sul master aggregato da rieseguire (par. 1.1, n. 13); prove con scheda grafica vera (#239); GL a Win64 col registratore.
- **Dall'utente.** Accettare che il "far sparire" completo sia la #252 (Release 2) e chiudere la #177 con le sue fette fatte; le prove a mano.
- **Testo (chiusura con motivazione).**

```
Chiudo la #177 con le sue figlie (#248, #249, #250): la parte portabile e' fatta e provata.

- OPENGL non esiste piu'; scena, voxel, modelli, luci dinamiche, lightmap, automap, contesto e nebbia sono classi; i gld_* tengono la firma.
- Parita': flusso delle chiamate GL UGUALE vecchio/nuovo su <N> scenari al master <SHA MASTER>, 57 mappe UGUALI, Tests.OpenGl 209 a Win32 e Win64.
- Misura finale (GLDoom32, demo3, GL software della VM): <NUMERO MISURA GL>

Resta per la Release 2 (#252): cancellare IdTech1\OpenGl\Legacy insieme ai {$IFDEF OPENGL} (un solo eseguibile per gioco). Per la #239: finestra, schermo intero, Alt+Tab, cambio di modo, vsync e DPI con una scheda grafica vera.
```

### #185 Tutto a classi, anche il percorso caldo

- **Stato.** Fase 0 (strumenti di parita') fatta: corpus 44 demo, golden, misura a coppie. Fase 1: freddo fatto (`hu_*`, `sc_*`, `info_*`, `i_*`, `m_*`, `w_*`, `s_*`, `deh_*`, `d_*`, `am_*`, `v_video`, `i_video` in classi; figlie #241-#243 chiuse). Fase 2: logica in un mondo solo: `p_user`, `p_inter`, `p_pspr`, `p_enemy`, `p_spec`, `p_switch`, thinker, `p_map` (`TMapCheck` a costo zero), `g_game` (`TGameSession`, `TTickState`), salvataggi che leggono dal mondo; le routine "duplicate con ragione" (1476 + `p_common` 332 + `d_main` 252 + menu/finali/barre 46.000 righe + `p_tick`/`p_3dfloors`/... 86 + `w_wad`/`s_sound`/`hu_stuff` + `p_doors`/`p_extra`/`udmf_*`/`po_man` 230) sono metodi statici di classi `sealed` nella stessa unit, costo zero provato dai `.map` (ondate 11-12). Fase 3: 27 unit del renderer software + colonne + tabella `R_SetRenderingFunctions` (ondata 12). Fase 4: #177. Fase 5: codice morto e avvisi (ondata 13: -17 routine, circa 200 clausole `uses`, 373 cast); `A36`/`A37` fatte; test delle regole (`Tests.Rules*`, 127 test). Inventario `docs\INVENTARIO_NON_MIGRATO.md`: 87 voci (26 MF, 22 MC, 33 CM, 6 R2). Tag: `ondata9-185-1..3`, `ondata10-185-1..6`, `ondata11-185a/b/c`, `ondata11b-185d/m/p`, `ondata12b-185f/w`, `ondata12c-185t/v`, `ondata13-185p/t`.
- **Manca.** Le spunte di fase 1, 2, 3, 4 e 5 non sono tutte soddisfatte alla lettera: restano dati (tabelle `info`/`sounddata`, circa 184.900 righe: A27), salvataggi (C10, 10.300 righe), `d_delphi` (A35), i ritorni per frame di `r_main` (E9), `V_PageDrawer`/`V_TileScreen8`/`I_FinishUpdate8_64` (D1, D4), `R_RenderSegLoop` (E3), le 6 voci R2 (`{$IFDEF OPENGL}`, lavori paralleli del renderer, finestra e avvio); copertura al 90% non misurata; prestazioni delle tornate dopo il 2026-11-16 da chiudere con la misura finale.
- **Dall'utente.** Le cinque decisioni del par. 5 dell'inventario (in particolare: le routine "duplicate con ragione" si considerano migrate a metodi statici, salvataggi e tabelle in Release 2, unit senza figlia in Release 2) e la scelta di chiudere #185 con il residuo in una issue "Release 2".
- **Testo (chiusura con motivazione).**

```
Chiudo la #185 per la Release 1: il lavoro a classi del motore e' fatto dove si poteva provare, e il residuo e' elencato e passa alla Release 2.

Fatto (inventario: docs\INVENTARIO_NON_MIGRATO.md, 87 voci; piano: docs\PIANO_TUTTO_A_CLASSI.md par. 11-13):
- fase 0 strumenti di parita'; fase 1 freddo; fase 2 logica di gioco in un mondo solo e routine di ogni gioco come metodi statici di classi sealed nella stessa unit (costo zero provato dai .map); fase 3 renderer software a metodi statici (27 unit); fase 4 OpenGL (#177); fase 5 codice morto e avvisi.
- Verifica sul master <SHA MASTER>: corpus 44/44 a 8 e 32 bit, Win32 e Win64; layout dei salvataggi uguale; giochi e strumenti compilano con avvisi non saliti; Tests.Rules 127/127.
- Misura a coppie a macchina scarica (vecchio c6c8903c): <NUMERO MISURA SW>

Residuo per la Release 2 (nuova issue "Release 2: residuo della #185"): tabelle info/sounddata (A27), salvataggi (C10), d_delphi (A35), finestra e avvio (A1), {$IFDEF OPENGL} e un solo eseguibile (#252), lavori paralleli del renderer (E19), le voci MC non fatte. Copertura al 90% per libreria: non misurata in questo giro.
```

### #203 War1: portare Warcraft Orcs & Humans (indice)

- **Stato.** Tutte le figlie sono chiuse: #190-#202 e #238 (le caselle del corpo dell'issue sono ancora tutte vuote). `Warcraft32` giocabile con finestra, effetti e salvataggio (`Games\War\CLAUDE.Warcraft32.md`); 3533 fotogrammi uguali al C vero a Win32 e Win64; parita' `docs\PARITA_WAR.md`. Tag: `ondata7-203-1`, `ondata-war-audio-1`. Aperta la #253 (Release 2, problemi del gioco e riferimenti) e i residui in #251.
- **Manca.** Sintetizzatore SoundFont (licenza non dichiarata, decisione 2026-11-17: non si distribuisce), scena di download, mappe dungeon senza oracolo, partite con seme; prove a mano: ascolto (#198) e FLIC in finestra (#199) in #239.
- **Dall'utente.** Confermare la chiusura dell'indice e spuntare le caselle (o accettare un commento al posto).
- **Testo (chiusura).**

```
Chiudo l'indice #203: tutte le sue issue sono chiuse (#190-#202, #238) e Warcraft32 e' giocabile (finestra, effetti, salvataggio), con parita' sul C vero (3533 fotogrammi, Win32 e Win64, docs\PARITA_WAR.md).

Continuano fuori dalla Release 1: problemi del gioco e riferimenti (#253), residui senza oracolo o licenza (#251: musica con SoundFont, mappe dungeon, scena di download), ascolto e filmati in finestra (#239).
```

### #206 Contenitore difficolta': DIFFICILE

- **Stato.** Elenca 22 issue; 17 sono chiuse. Aperte: #40, #175, #177, #185 (schede sopra) e #47 (server MCP: fuori dalla Release 1, esclusa da priorita' nota).
- **Manca.** Chiusura delle quattro precedenti; decisione su #47.
- **Dall'utente.** Se #47 esce dal contenitore (resta aperta da sola) si puo' chiudere.
- **Testo (chiusura, dopo #40, #175, #177, #185).**

```
Chiudo il contenitore #206: delle 22 issue elencate 21 sono chiuse. Resta aperta la #47 (server MCP per creare un gioco): non fa parte della Release 1 e continua da sola.
```

### #239 Prove a mano

- **Stato.** Lista di controllo scritta in `docs\PROVE_A_MANO.md` (per programma, comando, criterio, log) e le liste delle fette 7 della #177 (contesto GL) nei commenti. Tag: `ondata11-239-1`. Nessuna prova fatta: servono orecchie, occhi, tastiera, joystick, scheda grafica vera, IDE.
- **Manca.** Tutto: audio (#189, #198, #169, #175), finestra e schermo intero (#189, #40, #232, #199), tastiera/mouse/joystick (#169, #175), IDE (#235), OpenGL con scheda vera (lista della #250).
- **Dall'utente.** Tutto: e' per definizione lavoro dell'utente.
- **Testo (aggiornamento, non chiusura).**

```
Aggiornamento alla chiusura della Release 1 (master <SHA MASTER>): la lista e' completa in docs\PROVE_A_MANO.md (30 minuti per le prove piu' importanti, 2 ore per le altre, mezza giornata per tutte). Nulla e' ancora stato provato a mano. L'issue resta aperta e passa alla Release 2; le uniche prove che dipendono da codice nuovo sono quelle dell'OpenGL (contesto, schermo intero, Alt+Tab, vsync, DPI) elencate nel commento sulla fetta 7 della #177.
```

### #244 #185 stadio 2: p_map (tm*, spechit) nel mondo

- **Stato.** Analisi: nel mondo costa il 55-60% nel punto piu' caldo (sonda `PIT_CheckLine`); lo stato di `p_map` e' in classi a costo zero: `TMapCheck`, `TMapSlide`, `TMapAim`, `TMapUse`, `TMapBlast` dentro `p_map.pas` (deroga motivata, par. 11.16 del piano); 38 routine della stessa dimensione nel `.map`. Misura a macchina scarica del 2026-11-16 entro il 5% (il prerequisito dell'issue). Inventario: B1-B4 tutte CM. Tag: `ondata-notte-244-1`, `ondata3-244-1..4`, `ondata5-244-1..4`.
- **Manca.** Niente: la decisione e' B1-B2 (stato in classi, callback `PIT_*` con contesto esplicito non fatto: cambia `ltraverse_t`). Strumenti `Prova-PMap.ps1`/`Prova-PMobj.ps1` obsoleti (B4, CM).
- **Dall'utente.** Confermare la motivazione.
- **Testo (chiusura, dopo la misura).**

```
Chiudo la #244. Lo stato di p_map (tm*, spechit, scorrimento, tiro, uso, esplosioni) e' in classi sealed dentro p_map.pas a costo zero provato dal .map (38 routine di uguale dimensione); portarlo nel mondo (TEngineWorld) costerebbe il 55-60% nel punto piu' caldo (sonda PIT_CheckLine, par. 11.13-11.16 del piano) e le callback PIT_* con contesto cambierebbero il contratto di ltraverse_t: non si fa. Inventario B1-B4: tutte chiuse con motivazione.

Prerequisito dell'issue (misura a coppie a macchina scarica): <NUMERO MISURA SW>
```

### #245 #185 g_game, bodyque e totali di livello

- **Stato.** Fatto in otto tornate: `bodyque` e totali di livello nel mondo (`TBodyQueue`, `TLevelTotals`: non erano nei salvataggi, il piano sbagliava), `TActiveSlots`, `TSaveGameHeader`/`TSaveGameVersions`/`TSaveGameSessionBlock`, `IdTech1\Demo` (codec delle demo), `TNewGameLimits`/`TSkillSpeed`, `TPlayerRespawn`/`TLevelExit`, `TGameSession` (`class var` incapsulati: 1521 sostituzioni), `TTickState` (`leveltime`, `thinkercap`), `G_DoReborn` di Hexen, scalari di sessione. Layout dei salvataggi uguale ai golden e tra 32 e 64 bit; corpus 88/88. Difetto conservato `EnemyCorpses` corretto con test (`ondata11-185c-2`). Tag: `ondata-notte-245-1..4`, `ondata2..8-245-*`, `ondata10-185-1`.
- **Manca.** Voci CM (regia di `G_Ticker`, `G_BuildTiccmd`, `G_DoCompleted`, ...); C10 salvataggi (`p_saveg`/`sv_save`, 10.300 righe) in Release 2; `players[]`, `leveltime`, `thinkercap`, `gametic` come campi di `TEngineWorld` (C11: +1 load in 91/72/38 unit); verifiche pendenti C18 (prova dei salvataggi dopo `ondata8-245-5`, demo di Hexen e Strife da riregistrare, caricamento incrociato `f2_map02` a 64 bit che scrisse un file vuoto una volta).
- **Dall'utente.** Decisioni 3 e 4 del par. 5 dell'inventario (salvataggi e tabelle in Release 2).
- **Testo (chiusura con motivazione).**

```
Chiudo la #245 per la Release 1. Fatto: bodyque e totali nel mondo, liste attive, intestazione e blocco di sessione dei salvataggi, codec delle demo (IdTech1\Demo), TGameSession e TTickState, G_DoReborn di Hexen e il resto delle voci MF dell'inventario; layout dei salvataggi uguale ai golden e tra 32 e 64 bit, corpus 88/88 UGUALE sul master <SHA MASTER>.

Non fatto, con la ragione nell'inventario (voci C1-C18): regia di G_Ticker, G_BuildTiccmd e G_DoCompleted (nulla da estrarre), players[]/leveltime/thinkercap/gametic come campi del mondo (+1 load in 91/72/38 unit), P_Archive/P_UnArchive e i salvataggi (C10: Release 2, i formati vecchi non hanno file di prova). Misura a coppie a macchina scarica: <NUMERO MISURA SW>
```

### #246 #185 fase 1 calda: v_video 3-5, i_video, am_map

- **Stato.** Quattro/cinque tornate: schermi e misure di `v_video`, cicli delle patch a 8 e 32 bit, copie dei rettangoli, `TVideoBlitSlices`, `TVideoModeChanger`, forme e regole dell'automap per gioco (`TAutomapGameRules`), `TAutomapKeys`, golden dell'automap (12/12 UGUALE), `TVideoTileGrid`/`TVideoPageLayout`, e (ondata 11b) menu, finali, intermissioni e barre di stato come metodi statici (18 unit, circa 46.000 righe). Corpus 44/44 a 8 e 32 bit, Win64 uguale, flusso GL UGUALE. Tag: `ondata-notte-246-1..7`, `ondata2-246-1..6`, `ondata3-246-1..5`, `ondata6-246-1`, `ondata11b-185m-1..7`.
- **Manca.** D1 `V_PageDrawer`/`V_TileScreen8`, D2 copie con console aperta, D4 conversione 8->32 bit (`I_FinishUpdate8_64*`), D8 golden dell'automap non raggiunti (teleporter, colori degli altri giocatori, mappa 15 di Strife); D5 in Release 2. Prestazioni delle tornate: da chiudere con la misura finale (mai misurate a macchina scarica prima del 2026-11-16, e dopo no).
- **Dall'utente.** Decidere D1, D2, D4 (MC) e D8 (MF): migrare o chiudere con motivazione.
- **Testo (chiusura con motivazione, dopo la misura).**

```
Chiudo la #246 per la Release 1: cicli caldi di v_video e i_video, automap (regole per gioco, tasti, golden 12/12), pagine, menu, finali, intermissioni e barre di stato sono classi o metodi statici su puntatori, senza chiamate virtuali per pixel e a costo di codice zero o minore provato dai .map. Corpus 44/44 a 8 e 32 bit UGUALE, Win64 uguale, flusso GL UGUALE sul master <SHA MASTER>.

Misura a coppie a macchina scarica: <NUMERO MISURA SW>

Residuo, nell'inventario (docs\INVENTARIO_NON_MIGRATO.md par. 3.3): V_PageDrawer/V_TileScreen8 (D1), copie con console (D2), conversione 8->32 bit del fotogramma (D4), golden dell'automap per teleporter e mappa 15 di Strife (D8); i rami {$IFDEF OPENGL} (D5) sono nella #252.
```

### #247 #185 fasi 3-5: renderer software, OpenGL e chiusura

- **Stato.** Censimento della fase 3 (par. 13.5 del piano): il renderer software e gia' in copia unica in `Base` (71 unit `r_*`). Fatte: fette fredde (sprite, griglia dei subsector, intervalli dei lump, texture mapping, profili per gioco, PK3, monitor, vista, sorter), `R_SetRenderingFunctions` come tabella generata (r_main da 19648 a 14740 byte), colonne, span, fuzz, nebbia di Hexen, MT degli sprite e `R_MapPlane` come metodi statici (par. 13.6-13.8) e, nell'ondata 12 (par. 13.9), 27 unit di `Base` (circa 640 routine) come classi `sealed`: nessuna routine cambia dimensione, 777-784 su 781-787 uguali byte per byte, 2 con due istruzioni adiacenti scambiate. `TColumnContext` annullato (E17). Tests.Renderer 178/178. Tag: `ondata-notte-247-1..6`, `ondata2-247-6`, `ondata3..5-247-*`, `ondata12a-247-1`.
- **Manca.** Voci MC non fatte (E1 BSP, E5 `r_slopes`/`r_3dfloors` interni, E6 oggetti, E9 `r_main` e `TViewContext`, E11-E13), E7/E10/E14 (freddo), E3/E4/E15-E17 CM, E18-E19 in R2; golden e misura a coppie dopo l'ondata 12 da rifare (dichiarato nel par. 13.9).
- **Dall'utente.** Decidere le voci MC (migrare o chiudere), poi chiudere.
- **Testo (chiusura con motivazione, dopo la misura).**

```
Chiudo la #247 per la Release 1. Il renderer software e' in copia unica in Base (71 unit r_*) e il caldo e' a metodi statici di classi sealed nella stessa unit (colonne, span, fuzz, nebbia, MT, R_MapPlane, 27 unit nell'ondata 12), senza chiamate virtuali per colonna, span, pixel o seg; R_SetRenderingFunctions e' una tabella di dati generata. Costo provato dai .map e dal disassemblato: nessuna routine cambia dimensione; corpus 44/44 a 8 e 32 bit UGUALE e Win64 uguale ai golden sul master <SHA MASTER>; Tests.Renderer 178/178.

Misura a coppie a macchina scarica: <NUMERO MISURA SW>

Residuo nell'inventario (par. 3.4): BSP (E1), r_slopes e r_3dfloors interni (E5), oggetti e sprite (E6), r_main e la vista (E9), i punti CM (E3, E4, E15-E17), e per la Release 2 i {$IFDEF OPENGL} (E18) e i lavori paralleli del renderer (E19).
```

### #248 #177 fetta 12: facciate di gl_render e gl_main

- **Stato.** Fette 12 e 7 parziali unite: `TEngineGlContext`, `TEngineGlFrameEnder`, `TEngineGlInitializer`/`VSync`/`2dMode`/`PaletteTints`/`ExtensionList`, `TEngineGlSceneFrame`, `TEngineGlHudPainter`, `TEngineGlSceneFog`, `TEngineGlLevelPreprocessor`; firme `gld_*` invariate; flusso GL UGUALE su 11 scenari; `Tests.OpenGl` 209. `gl_render` e `gl_main` restano in `IdTech1\OpenGl\Legacy` (inventario F1: 1338 e 791 righe).
- **Manca.** Ridurre `gl_render` e `gl_main` a facciate e cancellare `Legacy`: dipende dal "un solo eseguibile" (#252).
- **Dall'utente.** Accettare che la cancellazione sia nella #252.
- **Testo (chiusura con motivazione).**

```
Chiudo la #248 con la #177: le classi della fetta 12 (contesto WGL, fine fotogramma, inizializzazione, vsync, modo 2D, tinte, estensioni, cornice di scena, HUD, nebbia, preprocessore del livello) sono unite e i gld_* tengono la firma; flusso GL UGUALE vecchio/nuovo sul master <SHA MASTER>, Tests.OpenGl 209 a Win32 e Win64. Misura: <NUMERO MISURA GL>

Resta per la Release 2 (#252): ridurre gl_render e gl_main a facciate e cancellare IdTech1\OpenGl\Legacy insieme ai {$IFDEF OPENGL}.
```

### #249 #177 luci dinamiche: gld_SortDlights e gld_DrawDLights

- **Stato.** `TEngineGlSceneLightSorter` e `TEngineGlSceneLightPainter` uniti; pacchetti di prova CC0 in `Tests\Data\LightsGl` (6 luci per gioco) con `-Lights` di `Confronta.ps1` e `Misura-Gl.ps1`; flusso GL UGUALE su 8 scenari (fino a 3.906.906 righe, 11.700 dischi, 600 ombre); misura 2026-11-16: luci +0,4%/-0,4%, dispersione sotto il 3%.
- **Manca.** Una scena di Strife con luci (nel flusso le luci di Strife sono 0: la parita' prova solo che a buffer vuoto non cambia nulla), `sectorlight`, pixel a schermo con scheda vera (#239).
- **Dall'utente.** Accettare che Strife con luci non abbia oracolo oggi (nessun GLDEFS di Strife con luci nei dati).
- **Testo (chiusura con motivazione, dopo la misura).**

```
Chiudo la #249: gld_SortDlights e gld_DrawDLights sono TEngineGlSceneLightSorter e TEngineGlSceneLightPainter (classi semplici, nessuna interfaccia ne chiamate virtuali per elemento); flusso GL UGUALE vecchio/nuovo su 8 scenari con luci e ombre al master <SHA MASTER>. Misura (variante con luci, GLDoom32, demo3): <NUMERO MISURA GL>

Non provato: Strife con luci (nel flusso sono 0 per mancanza di un livello con GLDEFS di Strife: la parita' prova solo il buffer vuoto), sectorlight e i pixel a schermo con una scheda grafica vera (#239).
```

### #250 #177 fetta 7 (contesto GL) e fetta 6 (lightmap dei voxel)

- **Stato.** Fetta 6 (`TEngineGlLightmapCalculator`, `gld_CalculateLightmapSTD`) unita e provata con i pacchetti delle luci (27.600 `glTexSubImage3D` nel flusso; 6 scenari con voxel, luci e lightmap UGUALI); misura con voxel 2026-11-16: +2,3% sui minimi, +0,6% sulle mediane (dispersione del vecchio 2,9%). Fetta 7: classi del contesto unite (par. #248); lista di controllo delle prove a mano postata nella #239.
- **Manca.** Le prove a mano della fetta 7 (finestra, schermo intero, Alt+Tab, cambio di modo, vsync, DPI: #239) e la misura finale con i voxel.
- **Dall'utente.** Le prove a mano.
- **Testo (chiusura con motivazione, dopo la misura).**

```
Chiudo la #250: la fetta 6 (lightmap dei voxel, TEngineGlLightmapCalculator) e provata (flusso UGUALE su 6 scenari con voxel, luci e lightmap) e misurata; la fetta 7 (contesto GL) e in classi con la parte pura in IdTech1\GlContext. Misura (variante con voxel, GLDoom32, demo3): <NUMERO MISURA GL>

Resta nella #239 la lista di controllo con scheda grafica vera (finestra, schermo intero, Alt+Tab, cambio di modo, vsync, DPI), che nessun agente puo' provare.
```

## 3. Tabella finale

| Issue | Esito proposto | Condizione | Perche' |
|---|---|---|---|
| #40 | **Chiudibile dopo la misura** | verdetto software entro il 5% | Condizione "fatto quando" soddisfatta; i residui passano a #239 e #251 |
| #244 | **Chiudibile dopo la misura** | verdetto software entro il 5% | Tutte le voci CM; il prerequisito dell'issue era proprio la misura |
| #175 | **Chiudibile dopo la misura** | misura di `MoveSprites` (`Tools\Verifica\175-sprites\Compila.ps1 -Misura 31`) entro il 5% | Gioco completo con parita'; la licenza e' decisa; restano solo prove a mano (#239) |
| #185 | **Chiudibile con motivazione** | misura entro il 5% e decisioni 1-3 del par. 5 dell'inventario | Residuo per la Release 2 in una issue nuova; copertura al 90% non misurata |
| #245 | **Chiudibile con motivazione** | misura entro il 5% e decisione sui salvataggi (C10 in Release 2) | CM e R2 con ragione scritta |
| #246 | **Chiudibile con motivazione** | misura entro il 5% e decisione su D1, D2, D4, D8 | Caldo fatto; residuo piccolo e documentato |
| #247 | **Chiudibile con motivazione** | misura entro il 5% e decisione sulle voci MC rimaste | Il renderer e' in classi a costo zero; residuo documentato |
| #177 | **Chiudibile con motivazione** | misura GL entro il 5%, flusso GL UGUALE sul master finale | La cancellazione di `Legacy` e' la #252 (Release 2) |
| #248 | **Chiudibile con motivazione** | come la #177 | Facciate di `gl_render`/`gl_main` dipendono dalla #252 |
| #249 | **Chiudibile con motivazione** | misura GL con luci entro il 5% | Strife con luci senza oracolo; `sectorlight` e pixel a schermo in #239 |
| #250 | **Chiudibile con motivazione** | misura GL con voxel entro il 5% | Fetta 6 fatta; fetta 7: prove a mano in #239 |
| #203 | **Chiudibile con motivazione** (non dipende dalla misura) | - | Indice: tutte le figlie sono chiuse; resta #253 e #251 |
| #157 | **Chiudibile con motivazione** (non dipende dalla misura) | - | Era analisi e piano; le integrazioni hanno le loro issue; licenze decise |
| #206 | **Chiudibile con motivazione** | #40, #175, #177, #185 chiuse | Contenitore: 21 su 22 chiuse; #47 resta da sola |
| #239 | **Resta aperta** | - | Servono orecchie, occhi, mani e hardware: lavoro dell'utente |

Riepilogo: chiudibili dopo la misura 3 (#40, #244, #175); chiudibili con motivazione 10 (#185, #245, #246, #247, #177, #248, #249, #250, #203, #157) piu' il contenitore #206 a cascata; restano aperte 1 (#239). Fuori dalla lista dei 15 e da non chiudere: #251, #252, #253, #254, #255, #47, #240.

## 4. Divergenze trovate tra documenti e codice (NON corrette)

Controllo fatto il 2026-11-19 sul ramo (`master` `67537a5e3`) con `grep`, conteggi e `git tag`, senza compilare: `docs\INVENTARIO_NON_MIGRATO.md` e le righe di stato di `CLAUDE.md`. **Nessun codice e' stato toccato.**

Confermato (senza divergenze): `strati` 0 violazioni nuove con 1 eccezione dichiarata; nessun `{$L}`; l'asm e' solo a doppia versione `{$IFDEF CPUX86}` (`m_fixed`, `p_local`, `r_mmx`, `r_softlights`, `d_delphi`) o terza parte (`ps_runtime`, `SynEdit`); le cinque classi di stato di `p_map.pas` (`TMapCheck :69`, `TMapUse :107`, `TMapBlast :118`, `TMapAim :136`, `TMapSlide :160`) come scritto nell'inventario; `p_common` ha 23 classi `TCommon*`; 15 giochi nel gruppo `Games`, 10 DLL nel gruppo `Dll`, 15 golden `Tests\Data\Acs\*.o` versionati; le unit di Radix e di Doom `PhysicsExtension` esistono entrambe; i conteggi della tabella di sintesi dell'inventario (87 voci: 26 MF, 22 MC, 33 CM, 6 R2) tornano con le righe delle tabelle; nessun link markdown rotto in `CLAUDE.md`; tutti i percorsi citati esistono salvo quelli volutamente cancellati (`DirectX.pas`, `Radix\st_stuff.pas`, `Radix\m_menu.pas`).

Divergenze:

1. **Numero dei test del gruppo.** `CLAUDE.md` (sezione "Layout della radice") dice "`DelphiDoom.Tests.groupproj` (113 test)"; il gruppo ha 125 progetti e `Tests\` ne ha 126.
2. **`DelphiDoom.Tests.Demo.dproj` non e' nel gruppo.** E' in `TESTS` di `Tools\build.bat` (che ha tutti i 126) ma non in `DelphiDoom.Tests.groupproj`: l'IDE non lo mostra. `CLAUDE.md` (par. ondata 13) dice che i tre progetti `Tests.Rules.*` sono nel gruppo: vero (30 occorrenze di `Tests.Rules` nel gruppo).
3. **Indice delle librerie di `CLAUDE.md` incompleto.** Cartelle senza voce d'indice: `Framework\Opl`, `Framework\Yaml`, `Games\XcomMod`, `Games\XcomSave`, `Games\XcomSurface`, `IdTech1\Radix` (descritta solo nel paragrafo finale), `IdTech1\GlAutomap`, `IdTech1\GlContext`, `IdTech1\GlLevel`, `IdTech1\GlScene`, `IdTech1\GlTexture`. Le cinque `Gl*` non hanno nemmeno un `CLAUDE.md` di cartella (la regola dell'indice dice "ogni cartella ha `CLAUDE.md` e `README.md`"). Sono programmi o dati senza `CLAUDE.md`: `Games\OpenXcom`, `Strumenti\DD_IDE`, `Strumenti\DD_Tools`, `Strumenti\DoomBuilder` (solo `.cfg`).
4. **Numeri di tag invecchiati nelle righe di stato di `CLAUDE.md`.** Ci sono tag oltre l'intervallo citato: `ondata13-185p-1..-5` (esiste anche `-6`), `ondata11b-185p-1..-16` (esiste `-17`), `ondata12b-185w-1..-7` (`-8`), `ondata12c-185t-1..-8` (`-9`), `ondata11b-185m-1..-5` (`-7`), `ondata11b-185d-1..-4` (`-5`). Utile al bisect.
5. **Numeri di riga dell'inventario invecchiati** dopo le ondate 12-13 (scarti normali di 2-14 righe): `V_PageDrawer` 3054 -> 3056, `AM_Responder` 720 -> 734, `G_Ticker` 1629 -> 1635, `G_BuildTiccmd` 955 -> 961, `G_PlayerReborn` 1847 -> 1853, `G_DoCompleted` 1987 -> 1977, `G_InitNew` 2600 -> 2590, `G_DoReborn` di Hexen 1696 -> 1685, asm di `r_softlights` `:665` -> `:710`; routine ora metodi di classe non si trovano piu' con "function/procedure" (`P_BlockLinesIterator`, `V_TileScreen8`).
6. **Conteggio delle unit di `Base`.** L'inventario (par. 2.8) dice 457 `.pas` in `IdTech1\Base`; i file tracciati sono 459.
7. **Il piano 13.4 e' in ritardo.** `docs\PIANO_TUTTO_A_CLASSI.md` par. 13.4 dice che la misura a coppie formale "non e' ancora stata chiusa da nessuna fetta della fase 2"; l'inventario (par. 4.2) e i commenti di #40, #185, #244, #245, #246 e #247 la danno chiusa il 2026-11-16 per `cb99f3ff1` (demo1 entro +0,83%; demo3 Win64 rifiutata per dispersione). Il par. 1.4 punto 5 dice di allinearlo.
8. **Corpi delle issue non allineati.** #185: "#244 analizzata, non migrata" (il par. 11.16 la mostra in classi) e spunte di fase vuote; #203: caselle tutte vuote con tutte le figlie chiuse; #250: dice che la fetta 6 "richiede un livello di prova e la misura" ma e' unita; #175: l'ultimo commento dice che la licenza "richiede una decisione", presa il 2026-11-17; #206: 17 su 22 chiuse. Non sono difetti di codice: si correggono con i commenti del par. 2.
9. **Strumenti per il bisect.** `Prova-PMap.ps1` e `Prova-PMobj.ps1` hanno percorsi di prima della #226 e commit `7bcb9a13` (inventario B4). **`Compila.ps1 -Which Old` non funzionava sul vecchio OpenGL `4282c434d`** (quello dei commenti della #177): `hook-gl.pre226.patch` e' fatto per un albero con l'unit `GlContext` (commit `55326b982` in poi) e a `4282c434d` non applica (`Libs/OpenGl/Legacy/DelphiDoom.Engine.GlContext.pas: No such file`, provato su un worktree). Corretto aggiungendo `hook-gl.pre-glcontext.patch` e la scelta in `Compila.ps1` (la patch applica con `git apply --check`; la compilazione del vecchio con i ganci non e' stata provata: qui non si compila).

## 5. Segnaposto dei commenti

| Segnaposto | Da dove |
|---|---|
| `<SHA MASTER>` | riga "Nuovo (master)" del rapporto (7-9 caratteri) |
| `<DATA>` | data nel nome del rapporto |
| `<NUMERO MISURA SW>` | paragrafo **Software** di "Testi pronti per i commenti" del rapporto (gia' nel formato dei commenti del 2026-11-16) |
| `<NUMERO MISURA GL>` | paragrafo **OpenGL** dello stesso titolo |
| `<NUMERO MISURA MOVESPRITES>` | uscita di `Tools\Verifica\175-sprites\Compila.ps1 -Misura 31` (rapporto e verdetto) |
| `<N>` (scenari del flusso GL) | uscita di `Confronta.ps1` del par. 1.1 n. 13 |
