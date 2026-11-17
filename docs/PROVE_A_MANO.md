# Prove a mano (issue #239)

Lista di controllo per chi prova **con le proprie mani**: tastiera, mouse, joystick, finestra, schermo intero, scheda grafica e audio
veri. Raccoglie tutto cio' che il repository dichiara **non provato**, **non ascoltato** o **da provare a mano** (CLAUDE.md di
`Framework\Audio`, `Framework\GameHost`, `Framework\Input`, `Strumenti\Ide`, `Strumenti\Launcher`, `Games\War`, `IdTech1\Radix`,
`IdTech1\Speed`, `IdTech1\OpenGl`, `Games\Keen`, `Games\Greed`, `docs\WAR1_AUDIO.md`, `docs\WAR1_DIFFERENZE.md`, issue #239).
**Nessuno dei comandi qui sotto e' stato eseguito per scrivere questo documento**: percorsi e opzioni sono controllati sul codice, sui
`.dproj` e sugli script; dove non e' stato possibile c'e' scritto **da verificare**.

## Riepilogo (10 righe)

1. Si prova in ordine di valore: prima cio' che un giocatore incontra subito (finestra, tastiera, audio), poi le varianti (schermo intero, joystick, 64 bit).
2. **30 minuti**: A1 (audio dei giochi software), A2 (finestra), B1 (Radix E1M1 con la tastiera), D1 e D2 (Warcraft32: finestra e effetti), H1 (Launcher).
3. **2 ore**: in piu' B2-B4 (Radix: menu, salvataggio, audio), C1-C2 (gara di Speed Haste), D3-D5 (musica MIDI, Umani 1, F5/F9), E1-E2 (Keen), F1-F3 (Greed), G1 (GLDoom32), I1 (DD_IDE), K1 (gruppi nell'IDE).
4. **Mezza giornata**: tutto il resto: schermo intero e Alt+Tab (A3), joystick (A4, C4, E4, F5), rete di Greed (F6), luci, modelli e voxel OpenGL (G4-G7), 64 bit con la finestra (sezione L), DPI diverso da 100% (L3).
5. Ogni prova ha: come costruire, comando, cosa fare, cosa osservare, dove e' il log, una casella `[ ]`.
6. Le build: `Tools\build.bat <progetto> Release` (Win32) o `... Release Win64`; gli eseguibili escono in `bin\<Piattaforma>\Release\<Cartella>\`.
7. I dati (WAD, `RADIX.DAT`, `SPEEDH.JCL`, `DATA.WAR`, `GREED.BLO`, dati di Keen) **non sono nel repository**: vanno messi in `bin\<Gioco>` (sotto, la tabella dei percorsi).
8. Se qualcosa va storto: copiare la riga di `stderr`, `crash.txt` e compilare il modulo qui sotto; non ritentare in ciclo.
9. Annotare l'esito con la data accanto alla casella: `[x] 2026-11-18 ok` o `[!] 2026-11-18 vedi segnalazione`.
10. Le voci marcate **da verificare** non hanno un comando provato: prima si guarda il file citato, poi si prova.

## Modulo di segnalazione

```
PROGRAMMA:        (es. Radix32, Win32 Release)
PROVA:            (es. B1 - E1M1 con la tastiera)
COMMIT/VERSIONE:  (git rev-parse --short HEAD del albero con cui si e' costruito; data della build)
MACCHINA:         (Windows, scheda grafica e driver, DPI/scala, scheda audio, joystick)
COMANDO:          (riga esatta, cartella di lavoro)
PASSI:            1) ... 2) ... 3) ...
ATTESO:           (il criterio di riuscita della prova)
OSSERVATO:        (cosa e' successo; schermata o registrazione se serve)
LOG:              (ultime righe di bin\<Gioco>\DATA\LOGS\*_stderr.txt; crash.txt accanto all'exe, se c'e')
```

## Percorsi, build e log

Cartella di partenza: la radice del repository (dove c'e' `Tools\build.bat`). `<P>` = `Win32` o `Win64`.

| Programma | Build | Eseguibile | Dati e `.ini` | Log |
|---|---|---|---|---|
| Doom32 | `Tools\build.bat Doom32 Release` | `bin\<P>\Release\Doom\Doom32.exe` | `bin\Doom` (`DOOM1.WAD`, `Doom32.swd`, `Doom32.ini`) | `bin\Doom\DATA\LOGS` |
| GLDoom32 | `Tools\build.bat GLDoom32 Release` | `bin\<P>\Release\Doom\GLDoom32.exe` | come Doom32 (il codice del `.ini` e' lo stesso: `Doom32.ini`) | `bin\Doom\DATA\LOGS` |
| Heretic32, GLHeretic32 | `Tools\build.bat Heretic32 Release` | `bin\<P>\Release\Heretic\Heretic32.exe` | `bin\Heretic` (`HERETIC1.WAD`, `Heretic32.ini`) | `bin\Heretic\DATA\LOGS` |
| Hexen32, GLHexen32 | `Tools\build.bat Hexen32 Release` | `bin\<P>\Release\Hexen\Hexen32.exe` | `bin\Hexen` (`HEXEN.WAD`, `Hexen32.ini`) | `bin\Hexen\DATA\LOGS` |
| Strife32, GLStrife32 | `Tools\build.bat Strife32 Release` | `bin\<P>\Release\Strife\Strife32.exe` | `bin\Strife` (`STRIFE0.WAD`, `Strife32.ini`) | `bin\Strife\DATA\LOGS` |
| Radix32 | `Tools\build.bat Radix32 Release` | `bin\<P>\Release\Radix\Radix32.exe` | `bin\Radix` (`RADIX.DAT`, `Radix32.swd` = copia di `Doom32.swd`) | `bin\Radix\DATA\LOGS` |
| SpeedHaste32 | `Tools\build.bat SpeedHaste32 Release` | `bin\<P>\Release\Speed\SpeedHaste32.exe` | `bin\Speed` (`SPEEDH.JCL`, `Speed32.swd` = copia di `Doom32.swd`; le scelte della gara stanno nel `.ini`, `Doom32.ini` secondo `IdTech1\Speed\CLAUDE.md`) | `bin\Speed\DATA\LOGS` |
| Warcraft32 | `Tools\build.bat Warcraft32 Release` | `bin\<P>\Release\War\Warcraft32.exe` | `bin\War` o `-data <cartella>` (`DATA.WAR`; font `war1_font_1.png`, `war1_font_2.png`); `Warcraft32.ini` accanto all'exe | stderr della console; `-audiostats` |
| Keen32 | `Tools\build.bat Keen32 Release` | `bin\<P>\Release\Keen\Keen32.exe` | accanto all'exe o `-data <cartella>` (dati di Keen Dreams); `KDREAMS.CFG` | stderr della console |
| Greed32 | `Tools\build.bat Greed32 Release` | `bin\<P>\Release\Greed\Greed32.exe` | `GREED.BLO` accanto all'exe o in cartella corrente; `DATA\xGreed.ini`, `DATA\SAVE1.*` | stderr della console |
| Launcher | `Tools\build.bat Launcher Release` | `bin\<P>\Release\Launcher.exe` | trova i giochi in `bin\<P>\Release\<Gioco>` | `Launcher.last.cmd` (la riga che ha lanciato) |
| DD_IDE | `Tools\build.bat DD_IDE Release` | `bin\<P>\Release\Tools\DD_IDE.exe` | compilatori `ddc` e `ddc_*.dll` in `bin\<P>\Release\Tools` (`Tools\build.bat strumenti Release`) | - |
| DD_Tools | `Tools\build.bat DD_Tools Release` | `bin\<P>\Release\Tools\DD_Tools.exe` | - | - |

- Il **crash** di un gioco scrive `crash.txt` **accanto all'eseguibile** (`bin\<P>\Release\<Cartella>\crash.txt`), non in `bin\<Gioco>`; `I_Error` non e' un'eccezione e non lo scrive: lo dice `stderr` (`bin\<Gioco>\DATA\LOGS\*_stderr.txt`). Il `.map` accanto all'exe risale all'indirizzo (`IdTech1\Base\i_crashlog.pas`).
- Per vedere `stderr` di un programma senza cartella `DATA\LOGS` (Warcraft32, Keen32, Greed32) lanciarlo da `cmd`: `cmd /c "bin\Win32\Release\War\Warcraft32.exe -data C:\dati\war 2> errori.txt"`.
- Nei comandi `<dati>` e' la cartella con i dati; i giochi di Doom la trovano da soli in `bin\<Gioco>` (`TDataFolderLocator`), per gli altri si passa `-data <cartella>`.
- Gli `.ini` dei giochi si **riscrivono alla chiusura**: prima di una prova da zero, spostarli.
- I comandi sono scritti per PowerShell dalla radice del repository, con i percorsi a barra rovesciata. A 64 bit il nome del file e' lo stesso e cambia solo la cartella `Win64` (**da verificare** con `dir` dopo la prima build `Win64`).

---

## A. Giochi software: Doom32, Heretic32, Hexen32, Strife32 (issue #189, #40, #232)

Valore alto: sono i programmi piu' usati e il loro audio e la loro finestra sono stati riscritti con la #189 (mixer software su waveOut,
`GDI` al posto di DirectDraw). Provare prima Doom32, poi gli altri tre con la stessa lista.

### A1. Audio degli effetti (mixer su waveOut) — #189 — non ascoltato
- [ ] **Programma**: Doom32 (poi Heretic32, Hexen32, Strife32). **Build**: `Tools\build.bat Doom32 Release`.
- **Comando**: `bin\Win32\Release\Doom\Doom32.exe -iwad DOOM1.WAD -warp 1 1 -nomusic`
- **Fare**: sparare con Ctrl, aprire una porta (barra spaziatrice), farsi sparare dal primo mostro, camminare per i corridoi; poi `-skill 4` per avere piu' suoni insieme.
- **Osservare**: gli effetti si sentono, nel posto giusto (destra/sinistra, piu' piano da lontano), **senza scatti, clic o ritardo evidente** tra il colpo e il suono (latenza attesa 70-90 ms al massimo, ricampionamento lineare a 44100 Hz: `Framework\Audio\CLAUDE.md`). Fallimento: silenzio, crepitii, suono in ritardo che disturba, suoni tagliati.
- **Confronto** (se si ha il vecchio eseguibile con DirectSound, `a449cacd` e precedenti): annotare se il timbro e' piu' "ruvido" (interpolazione lineare al posto del filtro di Windows).
- **Log**: `bin\Doom\DATA\LOGS\*_stderr.txt` (cercare `Sfx` e `not found`).

### A2. Finestra: avvio, scala, ridimensionamento, cambio di modo — #189
- [ ] **Comando**: `bin\Win32\Release\Doom\Doom32.exe -iwad DOOM1.WAD -windowed -screenwidth 800 -screenheight 600`, poi `-screenwidth 640 -screenheight 480`.
- **Fare**: aprire il menu (Esc) > Options > Display e cambiare risoluzione e `r_blitmultiplier` (se c'e' la voce), ridimensionare la finestra con il mouse, minimizzare e ripristinare.
- **Osservare**: l'immagine e' nitida (scalatura a **pixel piu' vicino**, `StretchDIBits`, confrontata a occhio con il vecchio DirectDraw), non c'e' sfarfallio, i colori della palette sono giusti (anche quando si prende un colpo o si raccoglie un oggetto: lampi di palette), il mouse resta dentro la finestra in gioco.
- **Log**: `bin\Doom\DATA\LOGS`.

### A3. Schermo intero esclusivo e Alt+Tab — #189 — non visto
- [ ] **Comando**: `bin\Win32\Release\Doom\Doom32.exe -iwad DOOM1.WAD -fullscreen -screenwidth 1024 -screenheight 768` (e `-windowed` per tornare).
- **Fare**: giocare un minuto; Alt+Tab verso un altro programma e ritorno; (menu Options) passare da schermo intero a finestra a runtime.
- **Osservare**: `ChangeDisplaySettings` porta il monitor al modo richiesto **e lo rimette com'era** all'uscita e dopo Alt+Tab (la risoluzione del desktop e le icone non restano cambiate); nessuno schermo nero, nessun blocco; chiudendo il gioco il desktop e' intatto.
- **Se resta il modo sbagliato**: annotare risoluzione, monitor e scheda; `bin\Doom\DATA\LOGS\*_stderr.txt`.

### A4. Joystick vero — #189/#232 — non provato
- [ ] **Comando**: `bin\Win32\Release\Doom\Doom32.exe -iwad DOOM1.WAD -joystick` (**da verificare**: `-joystick` e `-nojoystick` sono letti dal codice; l'impostazione stabile e' `use_joystick` in `Doom32.ini`, da guardare in `IdTech1\Base\m_defs.pas`).
- **Fare**: calibrare dal menu (Options > Joystick, se presente: **da verificare**), muovere gli assi, premere sparo/usa (`joyb_fire`, `joyb_use` nel `.ini`).
- **Osservare**: assi e pulsanti rispondono, nessuna deriva con la leva ferma.

### A5. Icona in finestra e nella barra delle applicazioni — #232
- [ ] **Comando**: lanciare ogni programma (Doom32, Heretic32, Hexen32, Strife32, GLDoom32, Radix32, SpeedHaste32, Warcraft32, Keen32, Greed32, Launcher, DD_IDE, DD_Tools).
- **Osservare**: l'icona giusta nell'angolo della finestra, nella barra delle applicazioni e in Alt+Tab (`doom.ico`, `heretic.ico`, `hexen.ico`, `strife.ico`, `radix.ico`, `speed.ico`, `xGreed.ico`, `launcher.ico`, `DD_IDE.ico`, `base.ico` per DD_Tools e Keen32; `war1.ico` per Warcraft32: **da verificare** che il `.dproj` la usi). Fallimento: icona di default di Delphi o icona sbagliata.
- Anche l'icona del file `.exe` in Esplora risorse.

### A6. Musica sul player MIDI legacy, XMI e pausa — Framework\Audio — non provati
- [ ] **Comando**: impostare `snd_uselegacymidiplayer = 1` in `bin\Doom\Doom32.ini`, poi `bin\Win32\Release\Doom\Doom32.exe -iwad DOOM1.WAD -warp 1 1` (senza `-nomusic`).
- **Fare**: ascoltare, aprire il menu (pausa), richiudere; cambiare livello.
- **Osservare**: la musica parte, si ferma e riprende dopo la pausa, nessuna nota appesa. Confronto con `snd_uselegacymidiplayer = 0` (percorso normale).

### A7. Altri tre giochi con la stessa lista
- [ ] Heretic32: `bin\Win32\Release\Heretic\Heretic32.exe -iwad HERETIC1.WAD -warp 1 1` (A1-A3).
- [ ] Hexen32: `bin\Win32\Release\Hexen\Hexen32.exe -iwad HEXEN.WAD -warp 1` (A1-A3).
- [ ] Strife32: `bin\Win32\Release\Strife\Strife32.exe -iwad STRIFE0.WAD -warp 32` (A1-A3; la mappa 32 e' quella dei golden: **da verificare** che sia giocabile da shareware).

---

## B. Radix32 (issue #169) — **mai giocato con la tastiera**

Valore altissimo: tutto cio' che si sa viene da un copione automatico. **Build**: `Tools\build.bat Radix32 Release`. Servono
`RADIX.DAT` e `Radix32.swd` in `bin\Radix`.

### B1. E1M1 dall'inizio alla fine con la tastiera
- [ ] **Comando**: `bin\Win32\Release\Radix\Radix32.exe -warp 1 1 -screenwidth 640 -screenheight 480`
- **Fare**: volare per l'hangar (frecce per girare e avanzare), sparare ai muri-bersaglio e ai nemici, raccogliere oggetti, **entrare nei settori segreti** (non visti mai), arrivare all'uscita, vedere debriefing e passaggio a E1M2. Armi oltre i cannoni, cabina (`screenblocks` 11).
- **Osservare**: nemici che muoiono e danneggiano, danno da contatto, muri che si rompono, salute/scudo/energia nell'HUD di Radix; l'uscita porta al debriefing; **nessun** `I_Error` ne' blocco. Il copione del repository finisce al tic 11544: un tempo molto diverso con la stessa partita e' un indizio.
- **Log**: `bin\Radix\DATA\LOGS\*_stderr.txt`; `-radixstate stato.txt` (opzione di `IdTech1\Radix\radix_statelog.pas`) scrive una riga a ogni cambio di salute, corazza, energia, bombe, uccisioni.

### B2. Tasti della navetta: postbruciatore, bomba al plasma, vola su/giu'
- [ ] **Comando**: come B1, aggiungendo `-radixbombs 3` (da' tre bombe alla nascita, a skill 2 non si raggiungono).
- **Fare**: premere i tasti di default del `.ini`: vola su `e` (101), vola giu' `q` (113), bomba al plasma `b` (98), postbruciatore `/` (47); poi verificarli nel menu dei tasti ("Fly up", "Fly down", "Afterburner", "Plasma Bomb").
- **Osservare**: la navetta sale e scende, il postbruciatore accelera e scarica l'energia (circa un punto ogni 8 tic), la bomba uccide i nemici vicini e non si ripete dentro 8 tic. Documento: "Non provati: i tasti veri della tastiera, la voce di menu".

### B3. Menu, briefing, debriefing, salvataggio e caricamento
- [ ] **Comando**: `bin\Win32\Release\Radix\Radix32.exe` (senza `-warp`: titolo e menu).
- **Fare**: percorrere il menu principale e le opzioni; dal gioco salvare (F2) e caricare (F3) o dal menu; controllare che nasca `<salvataggio>.radix` accanto al file; ricaricare e verificare salute, energia, posizione e nemici.
- **Osservare**: il menu e' quello di Doom "vestito da Radix"; il salvataggio si ricarica con lo stesso stato; il tasto `ESC to play` e l'aiuto `F12` degli obiettivi (**da verificare**: indicati come "restano" in `IdTech1\Radix\CLAUDE.md`).

### B4. Audio e musica — **mai ascoltati**
- [ ] **Comando**: `bin\Win32\Release\Radix\Radix32.exe -warp 1 1` (senza `-nomusic` ne' `-nosound`).
- **Fare**: ascoltare titolo, E1M1, motore della navetta, **sirena** (scudo sotto un quarto con un nemico che vede la navetta entro 2048 unita'), armi, urti, debriefing.
- **Osservare**: la musica (moduli ProTracker, tracker di `Framework\Mikmod`) suona senza scatti; il motore e' udibile sopra gli altri suoni, la sirena parte; i suoni degli urti; nota: resta senza suono `slop` (un'uscita su otto).

### B5. Fine di E1M8, E1M9 e livelli 2..9
- [ ] **Comando**: `bin\Win32\Release\Radix\Radix32.exe -warp 1 9` (poi `-warp 1 2` ... `1 8`).
- **Osservare**: i livelli si caricano e si giocano; l'uscita di E1M9 porta al livello 5 (`radixnamedlevel`: mai arrivata davvero) e dopo E1M8 il motore va alla fine dell'episodio **senza** debriefing (da confrontare con il fork: non verificato).

### B6. Radix32 a 64 bit con la finestra
- [ ] **Build**: `Tools\build.bat Radix32 Release Win64`. **Comando**: `bin\Win64\Release\Radix\Radix32.exe` e poi `-warp 1 1`. Documentato: parte al titolo; **da verificare** `-warp` a 64 bit (a 32 bit funziona).

---

## C. SpeedHaste32 (issue #168)

**Build**: `Tools\build.bat SpeedHaste32 Release`. Servono `SPEEDH.JCL` e `Speed32.swd` (copia di `Doom32.swd`; con il `SYS.WAD` del fork si ha `I_Error: XCROSS0 not found`).

### C1. Una gara intera con la tastiera
- [ ] **Comando**: `bin\Win32\Release\Speed\SpeedHaste32.exe -warp 1 1` (o dal menu: New race).
- **Fare**: accelerare, frenare, sterzare, fare i giri, vedere display, cielo e montagne, posizioni, classifica, tabelle dei record, arrivare al traguardo.
- **Osservare**: l'auto risponde ai tasti, le 19 auto del computer corrono, la partenza a luci, i giri, il traguardo, la classifica; nessun `I_Error`. Il copione arriva al traguardo in circa 2723 tic con l'auto predefinita.
- **Log**: `bin\Speed\DATA\LOGS`; `crash.txt` accanto all'exe (`bin\Win32\Release\Speed`).

### C2. Suono e musica — non ascoltati
- [ ] **Comando**: come C1, senza `-nomusic` ne' `-nosound`.
- **Osservare**: il motore delle auto, gli urti tra auto (evento `Collision`), la musica del JCL.

### C3. Menu di New race, campionato, cambio manuale
- [ ] **Comando**: `bin\Win32\Release\Speed\SpeedHaste32.exe` e scegliere New race (pista, auto, giri, cambio, tipo di gioco, difficolta'); per il cambio manuale `-manual` con i tasti `key_gearup`/`key_geardown` del `.ini`.
- **Osservare**: le immagini dei menu sono rese con il **testo** (non ci sono le immagini di Doom); dopo la gara risultato, classifica, record, campionato che passa da E1M1 a E1M2; la marcia sale e scende. E1M3..E1M8 non sono nello shareware.

### C4. Joystick
- [ ] **Comando**: come C1; abilitare il joystick come in A4. **Osservare**: sterzo e acceleratore su assi e pulsanti. (La documentazione non cita un joystick per Speed: **da verificare**.)

### C5. 64 bit: gara intera, schermate, salvataggi
- [ ] **Build**: `Tools\build.bat SpeedHaste32 Release Win64`; **comando**: `bin\Win64\Release\Speed\SpeedHaste32.exe -warp 1 1`. Documentato: lo stato della gara a 64 bit e' uguale a quello a 32; **non provati** la gara intera con finestra, le schermate e i salvataggi. Salvare e caricare a 64 bit, e un salvataggio fatto a 32 bit caricato a 64.

---

## D. Warcraft32 (issue #198, #199, #200, #203, #238)

**Build**: `Tools\build.bat Warcraft32 Release`. **Dati**: `DATA.WAR` del gioco DOS (12852768 byte) e i due PNG dei font (`war1_font_1.png`, `war1_font_2.png`); `-data <cartella>` e, se serve, `-fonts <cartella>`. Per le prove: `Reference\_dati\warcraft`.

### D1. Finestra, logo, introduzione FLIC, menu, mouse
- [ ] **Comando**: `bin\Win32\Release\War\Warcraft32.exe -data <dati> -scale 3`
- **Fare**: guardare il logo della Blizzard, l'introduzione (CAVE1, CAVE2, CAVE3, TITLE), saltare con un tasto/clic e con `Esc`; dal menu principale "Replay introduction"; muovere il mouse e cliccare i bottoni.
- **Osservare**: la finestra (320x200 per scala) e' nitida, 60 fotogrammi al secondo senza strappi, i filmati FLIC si vedono completi, il clic salta l'animazione che gira, `Esc` salta tutto, il mouse e' preciso. **Non vista in una finestra vera** (#199): sono provati solo i fotogrammi dei file.
- **Log**: stderr della console (`cmd /c ... 2> errori.txt`).

### D2. Effetti sonori — non ascoltati
- [ ] **Comando**: `bin\Win32\Release\War\Warcraft32.exe -data <dati> -music none -play human 1 -audiostats` (con `-music none` si sentono solo gli effetti).
- **Fare**: clic su un contadino (voci di conferma), clic destro sulla mappa, far partire colpi e crolli.
- **Osservare**: voci di conferma, colpi e crolli con la posizione (piu' lontani = piu' piano, tra 120 e 200 pixel dal centro; con la nebbia accesa un suono nella nebbia non si sente). Alla chiusura `-audiostats` stampa: `Sounds started` = 0 (le scene non chiedono suoni), `sounds that could not be played` > 0 (decodifica), `Buffers played by the sound device` = 0 (il dispositivo non consuma), tutto positivo (allora volume, `.ini`, uscita di Windows). **Se non si sente nulla**: cancellare `Warcraft32.ini` accanto all'exe (puo' avere `sound`/`music` spenti) e controllare il mixer di Windows.

### D3. Musica sul MIDI di Windows — non ascoltata
- [ ] **Comando**: `bin\Win32\Release\War\Warcraft32.exe -data <dati> -music midi -play human 1` (e poi `-music none`).
- **Fare**: menu principale (musica del titolo); mappa (musica della mappa); passaggio mappa/menu; salvare con F5, caricare con F9; volume della musica dal menu F10.
- **Osservare**: la musica suona sul "Microsoft GS Wavetable Synth" (timbri GM, diversi dal remake), il tempo ha lo sfarfallio di 23 ms (se disturba, vedi `FRAMES_PER_BUFFER` in `docs\WAR1_AUDIO.md`), la dissolvenza tra scene, **F9 riporta la musica del livello**, nessuna nota appesa con la musica spenta, `-music none` e `-nosound` tolgono la musica. Fallimento: `No MIDI device` (il programma lo dice) o note appese.

### D4. Umani 1 giocata a mano (lista di `docs\WAR1_DIFFERENZE.md` sez. 5)
- [ ] **Comando**: `bin\Win32\Release\War\Warcraft32.exe -data <dati> -play human 1`
- **Fare**: costruire 6 fattorie e una caserma; raccogliere oro e legna con i contadini; addestrare in coda e annullare.
- **Osservare**: arriva la vittoria? (obiettivo del remake: 6 fattorie + 1 caserma); il cibo limita l'addestramento; costruzione (anteprima verde/rossa, costo, tempo, annulla con rimborso, riparazione).

### D5. Salvataggio rapido e caricamento
- [ ] **Comando**: come D4. **Fare**: giocare 5, 15 e 30 minuti, F5 (salva), F9 (carica); anche Save/Load dal menu F10; chiudere e riaprire con `-load <file>` (o lo slot rapido `SAVES\quick.war1sav` accanto al programma).
- **Osservare**: la partita si ritrova uguale (e' la storia dei comandi rigiocata, circa 2 ms per fotogramma: un minuto abbondante per 10 minuti di gioco): annotare i **tempi di caricamento**.

### D6. Altre missioni e combattimento (resto della lista di `docs\WAR1_DIFFERENZE.md` sez. 5)
- [ ] Umani 2 e 3, orchi 1-3: condizioni di vittoria e sconfitta, passaggio al briefing successivo.
- [ ] **Umani 4**: atteso oggi uscita con codice 1 e il messaggio sul tipo 16 (livello 123, feriti senza dati); annotare cosa si osserva.
- [ ] Orchi 4 (dungeon) e missioni dungeon 8: tile di muri, strade, rovine (confronto con DOSBox in `Reference\_dati\warcraft`).
- [ ] Combattimento (frecce, catapulta, incantesimi), movimento di gruppo, nebbia, minimappa, menu F10 (opzioni, velocita', volumi), trucchi (`Invio`, `Yours truly` = vittoria), pausa `Ctrl+P`.
- [ ] Confronto in DOSBox (sez. 6 di `docs\WAR1_DIFFERENZE.md`): feriti, tile, statistiche, vittoria/sconfitta, IA, salvataggio.

### D7. Schermo intero e 64 bit con la finestra
- [ ] Schermo intero: **non documentata una opzione** (la finestra e' scalata con `-scale 1..8`): **da verificare** se Warcraft32 sa andare a schermo intero; se non puo', annotarlo come "non c'e'".
- [ ] **Build**: `Tools\build.bat Warcraft32 Release Win64`; **comando**: `bin\Win64\Release\War\Warcraft32.exe -data <dati> -play human 1`. Documentato: a Win64 gira senza finestra con le stesse impronte; la finestra non e' stata provata.
- [ ] Prova automatica con finestra vera (serve un desktop attivo): `Tools\Verifica\200\Prova-Finestra.ps1`.

---

## E. Keen32 (issue #165)

**Build**: `Tools\build.bat Keen32 Release`. **Dati**: quelli di Commander Keen in Keen Dreams (proprietari); accanto all'exe o `-data <cartella>`.

### E1. Giocare con la tastiera in finestra
- [ ] **Comando**: `bin\Win32\Release\Keen\Keen32.exe -data <dati> -scale 3`
- **Fare**: titolo, pannello di controllo (scegliere tastiera), nuova partita, mappa del mondo, entrare in un livello, camminare, saltare, lanciare (Alt lancia: l'Alt non apre il menu della finestra), nemici, raccolta, morire, salvare e caricare; **finire il livello 1 (Horseradish Hill)**, mai finito (si e' finito un livello piccolo, il 6).
- **Osservare**: ritmo a 70 tic e 35 quadri al secondo, nessun strappo, colori EGA giusti, i punteggi, la fine livello e il finale. Opzione di diagnostica: `-report` stampa tic, refresh e tempi.
- **Log**: stderr della console; `KDREAMS.CFG`.

### E2. Audio AdLib — solo contato
- [ ] **Comando**: come E1 (senza `-nosound`; per spegnere l'AdLib `noal`, con o senza `-`).
- **Osservare**: gli effetti e la musica AdLib (emulatore `Framework\Opl`) sono quelli del gioco DOS, niente scatti. (L'audio digitalizzato Sound Blaster non e' portato: lo shareware non ha i dati; la musica di `SD_StartMusic` non e' scritta.)

### E3. Mouse vero
- [ ] **Comando**: come E1; nel pannello di controllo scegliere il mouse come controllo.
- **Fare**: muovere a destra/sinistra, pulsanti. **Osservare**: Keen va a destra e sinistra, salta; **la finestra deve avere il primo piano** (a finestra in secondo piano il mouse e' ignorato per costruzione). Parametro `nomouse` lo spegne.

### E4. Joystick vero — non provato
- [ ] **Comando**: come E1; scegliere il joystick come controllo nel pannello. **Osservare**: rilevamento (`IN_Startup`, parametro `nojoys` lo spegne), assi e pulsanti. Questa e' l'unica prova con un joystick vero (finora solo un finto).

### E5. Salvataggio dell'originale DOS e dati 1.93
- [ ] **Comando**: `Keen32 -importsave <file> -exe <KDREAMS.EXE> [-slot n]` con un salvataggio preso **dentro un livello** da `KDREAMS.EXE` 1.13 (provato solo con uno preso in DOSBox dalla mappa). I dati 1.93 non sono disponibili: **non provabili** senza di essi.

---

## F. Greed32 (issue #175)

**Build**: `Tools\build.bat Greed32 Release`. **Dati**: `GREED.BLO` (o i dati della demo) accanto all'exe o in cartella corrente.

### F1. Giocare con la tastiera in finestra
- [ ] **Comando**: `bin\Win32\Release\Greed\Greed32.exe -play 0 -nomouse`
- **Fare**: frecce o `W` `S` per avanzare, `Q` `E` per girare, `A` `D` di lato, Maiusc per correre, Esc per il menu; aprire porte, sparare, raccogliere; il menu (`-skipintro`, `-nobriefing` le salta; `-game1/2/3` sceglie l'episodio); chiudere con la X.
- **Osservare**: la vista in prima persona 640x400 (opzione `-lowres` per piu' leggera), le porte si aprono e richiudono, lo specchietto, l'HUD, nessuna eccezione, la **chiusura con la X** (mai provata). Il puntatore del mouse vince sulle frecce del menu: per usare solo tasti passare `-nomouse`.
- **Log**: stderr della console; `DATA\xGreed.ini`, `DATA\SAVE1.*`.

### F2. Tasti configurabili `bt_*` di `xGreed.ini`
- [ ] **Comando**: spegnere il gioco, aprire `bin\Win32\Release\Greed\DATA\xGreed.ini`, cambiare per esempio `bt_fire` (scan code della tastiera; i 19 tasti sono `bt_*`), rilanciare come F1.
- **Osservare**: il nuovo tasto fa il nuovo comando, i vecchi no. Annotare i nomi dei `bt_*` presenti nel file (**da verificare** l'elenco con il file generato alla prima chiusura).

### F3. Audio — non ascoltato
- [ ] **Comando**: `bin\Win32\Release\Greed\Greed32.exe -play 0 -nomouse -musicvol 6 -sfxvol 6 -audiostats`
- **Osservare**: effetti (WAV con volume e pan) e musica (moduli tracker di `Framework\Mikmod`) senza scatti; `-audiostats` alla fine stampa i buffer suonati (nei test: 254 buffer, 260096 frame).

### F4. Mouse di sistema
- [ ] **Comando**: `bin\Win32\Release\Greed\Greed32.exe -play 0` (senza `-nomouse`).
- **Osservare**: il cursore e' ricentrato a ogni lettura, nei menu il puntatore sceglie la voce, YES/NO di `ShowQuit` col clic, sparo e uso coi pulsanti. A finestra non attiva il gioco ignora il mouse.

### F5. Joystick vero (estensione dichiarata, non c'e' in xGreed)
- [ ] **Comando**: `bin\Win32\Release\Greed\Greed32.exe -play 0 -nomouse -joystick`
- **Osservare**: assi e pulsanti comandano il giocatore. Senza `-joystick` il joystick resta spento.

### F6. Rete tra due macchine — non provata
- [ ] **Comando** (due macchine A e B): A: `Greed32.exe -play 0 -net 0 2 -netport 5000 -netpeer <ip-di-B>:5000 -netname A`; B: `Greed32.exe -play 0 -net 1 2 -netport 5000 -netpeer <ip-di-A>:5000 -netname B` (forma `-net <giocatore> <giocatori> -netport P -netpeer host[:porta] -netname N`; il numero del giocatore parte da 0).
- **Osservare**: i due vedono l'altro e i suoi colpi; mancano HUD dei frag, menu di rete e specchietto sul nemico (non portati). Possibile blocco del firewall di Windows (UDP): annotarlo.

### F7. Schermo intero, DPI, 64 bit con la finestra
- [ ] Schermo intero e DPI diverso da 100%: **non provati**; l'opzione per lo schermo intero non e' documentata (**da verificare** nel codice di `Games\Greed`).
- [ ] **Build**: `Tools\build.bat Greed32 Release Win64`; `bin\Win64\Release\Greed\Greed32.exe -play 0 -nomouse`. Documentato: la finestra a 64 bit e il mouse di sistema a 64 bit non sono provati.

---

## G. Giochi OpenGL: GLDoom32, GLHeretic32, GLHexen32, GLStrife32 (issue #177, #248-#250, #40)

Valore alto per chi ha una scheda grafica vera: i test e le catture sono fatti con un OpenGL software di una VM (Mesa) senza scheda vera.
**Build**: `Tools\build.bat GLDoom32 Release` (e `GLHeretic32`, `GLHexen32`, `GLStrife32`). Si lanciano dalla stessa cartella dei giochi software
(`bin\Win32\Release\<Gioco>\`) e usano gli stessi dati.

### G1. Finestra e livello
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1 -windowed -screenwidth 1024 -screenheight 768`
- **Osservare**: la finestra OpenGL si apre sulla scheda vera, il livello si vede senza errori grafici (muri, pavimenti, cielo, sprite, HUD), nessun `I_Error` o `crash.txt`. Annotare scheda e driver.
- **Log**: `bin\Doom\DATA\LOGS\*_stderr.txt`.

### G2. Schermo intero
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1 -fullscreen -screenwidth 1280 -screenheight 720`
- **Osservare**: modo cambiato e ripristinato all'uscita, nessun nero, Alt+Tab; (`TEngineGlContext.ApplyFullScreen`).

### G3. Sincronizzazione verticale (vsync)
- [ ] **Comando**: come G1; impostare `gl_screensync` (nel menu Options > Display/OpenGL o nel `.ini`) a 1 e a 0.
- **Osservare**: con 1 niente strappi e fotogrammi limitati al monitor; con 0 piu' fotogrammi e strappi possibili; il cambio a runtime vale subito (`wglSwapIntervalEXT`). Annotare il numero di fotogrammi.

### G4. Luci dinamiche (GLDEFS) — #249
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1 -devparm -file C:\ddgl_pack\zlgt_d.pk3` dopo aver copiato `Tests\Data\LightsGl\zlgt_d.pk3` in un percorso **senza punti nel nome delle cartelle** (`-file` prende l'estensione dal primo punto: un albero sotto `.claude\worktrees` fa vedere il PK3 come "WAD non valido") e aver messo `uselightboost=1` e `gl_drawshadows=1` nel `.ini`.
- **Osservare**: dischi di luce colorati attorno a spari e oggetti (tre sprite su quattro), flicker e pulse, ombre sotto gli sprite senza luce.

### G5. Strife con luci
- [ ] **Comando**: `bin\Win32\Release\Strife\GLStrife32.exe -iwad STRIFE0.WAD -warp 32 -devparm -file C:\ddgl_pack\zlgt_s.pk3` (stesse impostazioni del `.ini` di G4: `Strife32.ini`). **Osservare**: luci e ombre; le trasparenze di Strife corrette.

### G6. Modelli 3D — #177 fetta 11
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1 -devparm -file C:\ddgl_pack\zmdl_d.pk3` (da `Tests\Data\ModelsGl`; `gl_drawmodels` acceso). **Osservare**: ogni sprite e' un cubo MD2 con texture; Heretic, Hexen e Strife con `zmdl_h`, `zmdl_x`, `zmdl_s` e il rispettivo `GL*32.exe`.

### G7. Voxel — #177 fetta 12
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1 -devparm -file C:\ddgl_pack\zvox_d.pk3` (da `Tests\Data\VoxelsGl`; `gl_drawvoxels` acceso). **Osservare**: ogni sprite e' la piramide a gradini 8x8x8; con `zvox_p.pk3` (rotazione `AngleOffset 45`, `DroppedSpin 60`, `PlacedSpin 90`) gli oggetti girano.

### G8. Prestazioni (comandi della misura GL)
- [ ] **Comando**: `bin\Win32\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -timedemo demo3` (poi `demo1`).
- **Osservare**: il gioco scrive `timed N gametics in R realtics` (demo3 = 2134 gametic); annotare `R` con vsync spento (G3) e scheda. Il confronto vecchio/nuovo con `Tools\Verifica\opengl\Misura-Gl.ps1 -Game GLDoom -Pairs 5` richiede due eseguibili costruiti con `Compila.ps1` (strumento temporaneo della #177): **da verificare** se e' ancora usabile prima di contare su di esso.

### G9. GLHeretic32, GLHexen32 e DPI
- [ ] Stesso comando di G1 con `GLHeretic32.exe -iwad HERETIC1.WAD -warp 1 1`, `GLHexen32.exe -iwad HEXEN.WAD -warp 1`.
- [ ] DPI diverso da 100% (Impostazioni di Windows > Scala): finestra e schermo intero a 125% e 150%: nessuna immagine tagliata o sfocata e il mouse allineato.
- [ ] **Win64**: `Tools\build.bat GLDoom32 Release Win64`; `bin\Win64\Release\Doom\GLDoom32.exe -iwad DOOM1.WAD -warp 1 1` con la scheda vera (a 64 bit parte e disegna solo su Mesa).

---

## H. Launcher (issue #232)

**Build**: `Tools\build.bat Launcher Release`. **Eseguibile**: `bin\Win32\Release\Launcher.exe`.

### H1. Avvio e Play per ogni gioco
- [ ] **Comando**: `bin\Win32\Release\Launcher.exe`
- **Fare**: scegliere Doom, poi Heretic, Hexen, Strife, Radix nella lista; premere **Play** (e la linguetta "Advanced"); provare le opzioni (risoluzione, schermo intero, `-nomusic`).
- **Osservare**: il gioco parte; `Launcher.last.cmd` accanto al Launcher contiene la riga esatta (es. `...\radix32.exe  -screenwidth 640 -screenheight 480`). Provato solo con Radix (gli altri quattro, stesso codice, WAD assenti).
- [ ] **Casella OpenGL con Radix a schermo** (solo nei test): scegliere Radix con la casella OpenGL accesa (GLRadix32 non esiste: **da verificare** cosa fa).
- [ ] **Doppio clic sulla lista**; rete (opzioni di rete); l'immagine di Radix nella lista "Easy Start" (oggi un punto interrogativo, noto).

---

## I. DD_IDE e DD_Tools (finestre VCL)

### I1. DD_IDE
- [ ] **Build**: `Tools\build.bat DD_IDE Release` e `Tools\build.bat strumenti Release` (i compilatori). **Comando**: `bin\Win32\Release\Tools\DD_IDE.exe`.
- **Fare**: aprire un progetto di script, pannelli di **libreria**, **ricerca e sostituzione**, **stampa**, finestra di **completamento**, salvare il progetto e il **PK3**; compilare un progetto **Radix** (usa `ddc_doom.dll`).
- **Osservare**: la finestra e' completa e i pannelli funzionano; la compilazione dei progetti Doom e Radix; nessun errore al salvataggio. Documentato: "Non provato" gli altri pannelli, il salvataggio del progetto e del PK3, la finestra di completamento.

### I2. DD_Tools (editor dei voxel, dei font, di ENDOOM)
- [ ] **Build**: `Tools\build.bat DD_Tools Release`. **Comando**: `bin\Win32\Release\Tools\DD_Tools.exe`.
- **Fare**: aprire i moduli (Voxel: cubo, viste, strumenti, formati DDVOX/KVX/VOX/DDMESH; Font: creatore di DD_FONT; Endoom: ENDEDIT), aprire e salvare un file, annulla/rifai, file recenti.
- **Osservare**: i moduli si aprono, gli editor disegnano e salvano; **da verificare** quali parti sono gia' provate a runtime nei `CLAUDE.md` di `Strumenti\VoxelEditor`, `Strumenti\Font`, `Strumenti\EndoomEditor`.

---

## K. L'IDE di Delphi e i gruppi di progetti (issue #235)

### K1. I quattro gruppi
- [ ] **Comando**: dall'IDE di Delphi aprire `DelphiDoom.Games.groupproj`, poi `DelphiDoom.Dll.groupproj`, `DelphiDoom.Tools.groupproj`, `DelphiDoom.Tests.groupproj` (alla radice).
- **Osservare**: il gruppo si apre; per ogni progetto il gestore delle configurazioni mostra **Base, Debug, Release** e le piattaforme **Win32 e Win64** (tranne `DelphiDoom.Tests.War`, solo Win32, voluto); compilare un progetto dall'IDE (Release e Win64).
- **Verifica che l'IDE non riscriva i `.dproj`**: prima `git status --short` pulito; aprire, compilare e chiudere salvando; `git status --short` e `git diff --stat` **non devono mostrare modifiche** ai `.dproj`. Se ne mostrano, annotare quale file e quali righe (e `Tools\Confronta-Proprieta-Dproj.ps1` prova che le proprieta' valutate non sono cambiate).

---

## L. Trasversali: 64 bit con la finestra, schermo intero, DPI

### L1. Win64 dove non e' provato
- [ ] **Build**: `Tools\build.bat giochi Release Win64` e `Tools\build.bat strumenti Release Win64`. Provare con la finestra: Doom32 (A1-A3), Radix32 (B1), SpeedHaste32 (C1), Warcraft32 (D1), Keen32 (E1), Greed32 (F1), i quattro GL (G1), Launcher, DD_IDE, DD_Tools. Annotare ogni differenza rispetto a Win32 (audio, mouse, colori, schermo intero).
- Elementi documentati come non provati a 64 bit: la finestra e il mouse di sistema di Greed32, la finestra di Warcraft32, la gara intera e i salvataggi di Speed, l'audio di ogni gioco, lo schermo intero esclusivo, la scheda grafica vera dei GL.

### L2. Audio di Windows
- [ ] In ogni prova audio verificare che il programma compaia come voce a parte nel mixer di Windows (volume per applicazione) e che non resti suono dopo la chiusura.

### L3. DPI diverso da 100%
- [ ] Per Doom32, GLDoom32, Radix32, SpeedHaste32, Greed32, Keen32, Warcraft32: scala di Windows a 125% e 150%, finestra e schermo intero; la dimensione e l'immagine devono restare corrette (nessun ritaglio) e il mouse allineato. (#40, `Games\Greed\CLAUDE.md`: "non provato: schermo intero, DPI diverso da 100%".)

---

## Conteggio

Le prove con casella `[ ]` sono numerate per sezione (A1-A7, B1-B6, C1-C5, D1-D7, E1-E5, F1-F7, G1-G9, H1, I1-I2, K1, L1-L3) piu' le sotto-caselle di D6, G9, H1, F7. Le voci **da verificare** sono quelle in cui il comando o l'opzione non si e' potuto controllare sul codice: vanno prima verificate e poi eseguite.
