# Verifica #165 (K8b): le azioni degli stati di Keen Dreams contro il C originale

Le 67 funzioni think, contact e react di `kd_keen.c`, `kd_act1.c` e `kd_act2.c` (porting in `Libs\Keen`:
`PlayerActions`, `CommonActions`, `Act1Actions`, `Act2Actions`, `ScoreBox`) sono confrontate con **gli oggetti originali**
compilati con Open Watcom a 16 bit (`int` e `unsigned` a 16 bit come nel gioco), eseguiti in DOSBox.

## Come funziona

1. `harness.c` (nostro, non e' codice di id Software) fa da mondo finto: la lista degli attori (`GetNewObj`, `RemoveObj`,
   `InitObjArray` copiate da `kd_play.c`), `RF_PlaceSprite`, `SD_PlaySound`, `US_RndT`, `GivePoints`, `NewState`, `ClipToWalls`,
   `ClipToSprite` e `ClipToSpriteSide` che scrivono nel log ogni chiamata. Il resto (le funzioni delle azioni, la tabella
   degli stati `s_*`) e' l'originale: `Reference\_dati\keen_build\src\obj\kd_keen.obj`, `kd_act1.obj`, `kd_act2.obj`.
   `tbl.inc` (generato dai nomi di `DelphiDoom.Keen.StateTable` e `ActionIds`) elenca i 213 stati e le 67 funzioni.
2. `SCEN.TXT` e' scritto dal test `GeneraGliScenariPerIlC` (`DELPHIDOOM_KEEN_SCENARIOS=<percorso>`) con il generatore di
   `DelphiDoom.Tests.Keen.ActionScenarios`: 30 scenari casuali (generatore xorshift con seme fisso) per ogni coppia
   funzione/tipo (66 coppie, 1980 scenari). Ogni scenario ha: il controllo, i tic e il tempo, l'origine della vista, il
   gioco (punti, vite, fiori, chiavi, bombe), i numeri casuali di `US_RndT`, una mappa 16x16 con i due piani, da 4 a 5
   attori con tutti i campi di `objtype` e quale e' l'attore e quale quello toccato.
3. `ACTHARN.EXE` legge `SCEN.TXT`, chiama la funzione e scrive: le chiamate al mondo, lo stato del gioco, `button0held`,
   `jumptime`, `leavepoletime`, `new` e tutti gli attori.
4. `New-ActionsGolden.ps1` fa `Tests\Data\Keen\actions.golden.txt`: una riga per scenario con l'FNV-1a a 32 bit del testo.
5. Il test `DovrebbeDareLoStessoRisultatoDelCInOgniScenario` esegue gli stessi scenari sul porting (con interfacce finte
   che scrivono nello stesso formato) e confronta gli hash.

## Comandi

```
Tools\build.bat DelphiDoom.Tests.Keen Debug
powershell -NoProfile -File Tools\Verifica\165\Run-ActionsParity.ps1        # tutto: scenari, harness, DOSBox, golden
Tools\build.bat DelphiDoom.Tests.Keen Debug
bin\Tests\DelphiDoom.Tests.Keen.exe --include:keen-parity
```

Per vedere una differenza riga per riga: con `DELPHIDOOM_KEEN_PORT_OUT=<PORT.TXT>` il test `ScriviIlRisultatoDelPorting`
scrive il testo del porting e `Compare-Actions.ps1 -C <OUT.TXT> -Port <PORT.TXT>` mostra la prima differenza di ogni funzione.

## Cosa e' dato per costruzione (e cosa no)

- Non sono nel confronto: `ScoreThink` (disegna nella memoria degli sprite con `asm` e `grsegs`: ha test propri sui byte
  del disegno), i `Spawn*` (test propri sui campi) e `FixScoreBox`.
- Il mondo e' finto di proposito: `ClipToWalls`, `NewState` ecc. non si muovono. Il confronto dice che **le azioni fanno le
  stesse scritture e le stesse chiamate**, non che la fisica complessiva sia uguale (quella e' di K8, `ActorMover`).
- Gli scenari evitano gli indici fuori tabella del C (`bounceangle` con `hitnorth` oltre 7, `worldshapes` e `worldanims` con
  `temp1` e `temp2` fuori intervallo): il C legge altra memoria. Il porting maschera con `and 7` e `and 3`.
- I puntatori del C nei `temp` (`new`, `ob`, `state`) sono indici di slot e di stato nel porting: il harness li scrive come
  numero (indice) per avere lo stesso testo.

## K10: gli effetti AdLib (`audio\`)

`audio\Run-AudioParity.ps1 [-Work <cartella>]` fa `Tests\Data\Keen\adlib.golden.txt`: il test `GeneraGliScenariPerIlC` di
`DelphiDoom.Tests.Keen.AdLibParity` scrive `SCEN.TXT` (300 script; `DELPHIDOOM_KEEN_ADLIB_SCENARIOS`), `id_sd.c` di
`Reference\_dati\keen_build\src` e' copiato nella cartella di lavoro come `ID_SD_P.C` con **una modifica**: la definizione di
`alOut` (i due `out` alle porte 388h e 389h con i ritardi) e' rinominata `alOut_hw`; `sdharn.c` include quel file e ha
l'`alOut` che scrive `w registro valore`. `Build-AudioHarness.cmd` compila con Open Watcom (`-mm -0 -zp1`, come il gioco),
DOSBox esegue `SDHARN.EXE > OUT.TXT` e `New-ActionsGolden.ps1` fa una riga per script con l'FNV-1a. La cartella di lavoro e'
fuori dal repository e da `Reference` (predefinita `%TEMP%\keen165-audio`).

Lo script e' testo: `S nome tipo`, `D suono lunghezza priorita' 17 byte (strumento e blocco) n dati...`, `M modo`
(`SD_SetSoundMode`: 0 spento, 2 AdLib), `P suono` (`SD_PlaySound`), `T n` (n volte `SDL_ALSoundService`: il timer non e'
installato, i servizi li chiama lo script), `X` (`SD_StopSound`), `Q` (`SD_SoundPlaying`), `E`. All'inizio di ogni script il
harness mette il modo a spento senza scrivere nel log. Per vedere una differenza: `DELPHIDOOM_KEEN_ADLIB_PORT_OUT=<file>` e
il test `ScriviIlRisultatoDelPorting`, poi un diff con `OUT.TXT`.
