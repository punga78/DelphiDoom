# Warcraft32

Il programma di **Warcraft: Orcs & Humans** (DOS, 1994) in classi: apre il `DATA.WAR` del gioco e lo fa giocare
in una finestra di 320 x 200 pixel per una scala (3 di solito): il logo della Blizzard, il menu principale, i briefing, le
missioni delle campagne degli umani e degli orchi (e le partite personalizzate). Il gioco sta in `Games\War` (port a classi
del remake in C `acoto87/war1`, licenza zlib); questa cartella ha il **programma**: il composition root, la finestra, l'uscita
audio e il file del salvataggio. Issue #200; il nome del programma e' una scelta di progetto (il marchio Warcraft e' di
Blizzard, da riesaminare prima di una distribuzione pubblica, #202).

## Dati

Il gioco non e' nel repository: servono `DATA.WAR` del gioco DOS (12852768 byte, 583 voci) e le due immagini dei font del remake
(`war1_font_1.png`, `war1_font_2.png`, in `Reference\war1\assets`, non nel repository).

```
Warcraft32 -data <cartella>                  la cartella ha DATA.WAR, o la sottocartella DATA
Warcraft32 -fonts <cartella>                 se i PNG dei font stanno altrove
```

Senza `-data` si cerca nella cartella del programma (con `TDataFolderLocator` di `Framework\Platform`: `bin\War` se l'eseguibile sta in
`bin\<Piattaforma>\<Configurazione>\War`) e in quella corrente. I font si cercano nella cartella dei dati (e in `FONTS`,
`assets`) e in `Reference\war1\assets` di una cartella sopra. Se manca qualcosa il programma lo dice con i percorsi guardati.
Per le prove: `Reference\_dati\warcraft` (estratto da `Reference\_dati\_download\warcraft.zip`, immagine disco `warcraft.img`).

## Si gioca

Mouse e tastiera come nell'originale (e nel remake). In piu', di questo programma:

| Tasto | Cosa fa |
|---|---|
| F10 | il menu della mappa (Save e Load ci sono: nell'originale non facevano niente) |
| F5 / F9 | salva / carica lo slot rapido (`SAVES\quick.war1sav`, accanto al programma) |
| Ctrl+P | pausa |
| Invio | la riga dei trucchi (`Yours truly` = vittoria, `Crushing defeat` = sconfitta, ...) |

`-play human|orc N` va subito alla missione N della campagna; `-scale N` (1..8) la dimensione della finestra; `-nosound` niente
uscita audio; `-nointro` salta l'introduzione. Le impostazioni (volumi di musica ed effetti, accesi o spenti) sono in `Warcraft32.ini` accanto al programma e si
riscrivono quando si chiude la finestra.

## Introduzione (issue #238)

Scelta del port: il remake ha il bottone `Replay introduction` e nessun codice dietro, e non suona nessun filmato. Dopo il logo,
in una finestra che parte dal titolo (senza `-play`, `-load`, `-script`, `-headless`), il gioco suona `CAVE1`, `CAVE2` (in ciclo
finche' non si preme un tasto), `CAVE3` (la porta, con il suo suono) e `TITLE` ("Welcome to the World of Warcraft"), poi il
menu. Un tasto (non Maiusc, Ctrl, Alt) o un clic salta la animazione che gira, `Esc` salta tutto il resto; un file che manca o
che non e' un'animazione si salta. `Replay introduction` nel menu principale la suona di nuovo; senza i file `CAVE*.WAR` accanto
a `DATA.WAR` il bottone resta inerte, come nell'originale. **Non vista in una finestra vera**: provata con i fotogrammi veri dei
file (`DelphiDoom.Tests.War.UiCinematics`) e con finti. Le voci delle narrazioni `WAR_INTRO_1..4` non sono assegnate (nessuno ha
ascoltato il gioco DOS).

## Salvataggio e caricamento (il remake non li ha)

Il **modello del gioco e' deterministico** (stesso generatore, stessi tempi, stesso ingresso: stessa partita; lo provano i
golden contro il C in `Games\War`). Un gioco salvato e' percio' **la sua storia**: come e' partito (il seme del generatore e la
missione di `-play`) e, fotogramma per fotogramma, il tempo che e' passato e quello che il giocatore ha fatto con il mouse e
la tastiera. Caricare fa un gioco nuovo e rigioca quella storia **senza mostrarla e senza suoni** (`TWarSession.Load`), fino al
fotogramma in cui si e' salvato; se qualcosa non va il gioco che girava resta com'e'.

- Formato: `DelphiDoom.War.Save.Types` (intestazione di 32 byte, un'intestazione di 6 byte per fotogramma, 12 byte per evento,
  checksum FNV-1a alla fine; **senza puntatori**, `SizeOf` coperto da un test); **versionato** due volte: la versione del
  formato e la versione delle regole (`WAR_SAVE_MODEL_VERSION`, da alzare quando una modifica del modello fa giocare un vecchio
  salvataggio in un altro modo); il `DATA.WAR` con cui si e' giocato (la dimensione) deve essere lo stesso.
- Costo: un fotogramma (cinque byte e gli eventi) per ogni 1/60 di secondo giocato, e **il tempo per caricare e' quello per
  calcolare la partita senza schermo e senza orologio**: circa 2 ms per fotogramma su una macchina di prova (una partita di dieci
  minuti sono 36000 fotogrammi, un minuto abbondante per caricarla). Se serve di piu' il passo successivo e' un salvataggio dello
  stato del modello (non fatto: sono i 1024 slot delle entita', gli stati, le mappe, la nebbia, i muri, l'IA e il generatore).
- Quello che **non** si salva: la musica che suonava (ricomincia con la prossima scena) e le impostazioni dei volumi (sono nel
  `.ini`).
- Dall'esterno: `-save <file>` (alla fine del programma) e `-load <file>` (prima del primo fotogramma). Con `-script` non
  funzionano: uno script muove l'ingresso del gioco da solo e quello non e' in un salvataggio.

## Prove senza finestra

```
Warcraft32 -data <cartella> -headless -quitafter 900 -seed 3 -play human 1 -shot a.png -audiostats
Warcraft32 -data <cartella> -script Tools\Verifica\200\scripts\titolo_umani_vittoria.script -shot fine.png
```

`-headless`: niente finestra, niente scheda audio, niente orologio (un fotogramma e' sempre 1/60 di secondo, il programma va
veloce quanto puo') e **le stesse opzioni danno sempre la stessa partita**; il mouse sta al centro della pittura. Senza
`-quitafter` va avanti 1800 fotogrammi. `-script` usa il formato di `Tools\Verifica\197\scripts` (`scene`, `campaign`, `move`,
`lbutton`, `key`, `text`, `run N K`, `hash`, `rgba`): scrive le righe `H n impronta` di cio' che lo script chiede.
`Tools\Verifica\200` ha due script dal logo alla vittoria degli umani e alla sconfitta degli orchi e `Prova-Esecuzioni.ps1` (decine di
esecuzioni con semi diversi, e salvare-e-ricaricare).

## Com'e' fatto

Un solo **composition root** (`DelphiDoom.War.Composition`, `TWarComposition.Run`): apre l'archivio e le risorse, fa il suono
(`TWarAudioFactory`, `TWarMusicFactory`, `TWarSceneAudio`), dice a `TWarSession` come fare un gioco (`TWarUiFactory.CreateGame` con
`TWarMapLauncher` e `UnsignedDirections = True` come il C fatto con gcc, un solo `TWarSeededRandom` per gioco) e la fa girare
con `TWarRunner`. Nessun `{$IFDEF}`.

| Dove | Cosa |
|---|---|
| `Games\War\DelphiDoom.War.App.*` | opzioni e lettore, ricerca dei dati, impostazioni, suono delle scene, tela -> colori, sessione, richieste, sink degli eventi, ciclo |
| `Games\War\DelphiDoom.War.Save.*` | formato, scrittura, lettura e checksum del salvataggio |
| `Games\War\DelphiDoom.War.Ui.*`, `MapUi.*` | le scene e la mappa (estese: i bottoni Save e Load, il suono dei suoni scelti) |
| `Framework\GameHost` | finestra, eventi, schermo GDI a colori, uscita PCM waveOut |
| `Games\War\DelphiDoom.War.HostWindow` | `IWarFramePresenter` sullo schermo di `Framework\GameHost` |
| `Games\War\DelphiDoom.War.HostAudio` | apre e chiude l'uscita PCM sul mixer degli effetti e della musica |
| `Games\War\DelphiDoom.War.FileSaveStorage` | lo slot rapido su file |

## Non fatto / limiti

- **Musica**: i brani si leggono (XMI -> MIDI) e si seguono, ma il sintetizzatore e' quello muto (il SoundFont del remake non ha una
  licenza dichiarata): non si sente musica. Gli effetti si sentono (mixer di `Games\War` sull'uscita waveOut a 44100 Hz), con la posizione
  sulla mappa per colpi, morti, crolli, tagli, frecce, esplosioni e incantesimi (volume pieno nella vista, poi cala tra 120 e 200 pixel dal
  centro come nel C; il C e' mono: il pan non esiste; con la nebbia accesa un suono nella nebbia non si sente).
- I **filmati**: l'introduzione (CAVE1..TITLE, vedi sopra) e' nel gestore delle scene; i **finali** (HFINALE, OFINALE), `WIN`, `LOSE` e i
  filmati delle mappe (HMAP, OMAP: non sono sul disco) **non sono ancora collegati** alle scene di fine campagna e della mappa.
- **Missione 4 degli umani**: il livello 123 ha unita' (`WAR_UNIT_WOUNDED`) senza dati nelle tabelle, e il C si ferma con un `assert`:
  qui e' `EWarException` e il programma esce con codice 1 dicendo quale (`Games\War\CLAUDE.md`).
- Non provati: **l'ascolto** (l'uscita waveOut si apre e consuma i buffer, `-audiostats` li conta, ma nessuno ha sentito i
  suoni), lo schermo intero, la finestra a 64 bit (a Win64 il programma compila e gira senza finestra con le stesse impronte
  di Win32), e nessuna partita giocata a mano da un giocatore.

## Verifica

`Tools\Verifica\200`: `scripts\titolo_umani_vittoria.script` e `titolo_orchi_sconfitta.script` (dal logo alla vittoria e alla
sconfitta con `-script`: impronte `46a49e09` e `5832fe15`, uguali a Win32 e a Win64, Release e Debug), `Prova-Esecuzioni.ps1` (decine
di esecuzioni senza finestra con semi diversi, da ogni missione di entrambe le razze, con salvataggio e ricaricamento; la
build Debug scrive le perdite di memoria su stderr), `Prova-Finestra.ps1` (la finestra vera con il mouse e la tastiera di Windows:
dal titolo alla mappa, F5, F9; serve un desktop attivo). La finestra gira a 60 fotogrammi al secondo (600 fotogrammi in 11 s
con l'avvio; `TClockFactory.AcquireTimerResolution(1)`: senza, `Sleep(1)` dura 15 ms e il gioco va a 33).
