# Speed

Speed Haste (Noriaworks 1995, fork GLSpeed di DelphiDoom, issue #168). **Non e ancora il gioco**: per ora un programma di prova nello stile di `Keen\Keen32` e `Greed\Greed32`, con composition root
proprio (`DelphiDoom.Speed.Composition.pas`; non tocca `ComposeEngine` ne `TIdTechGeneration`).

```
Tools\build.bat Speed\Speed32            (output bin\Speed\Speed32.exe)
Speed32 -jcl <SPEEDH.JCL o la cartella> -list                  elenca i lump del WAD tradotto e i modelli I3D
Speed32 -jcl <...> -level 1..8 -laps 2 -cars 8 -tics 20000     una gara di auto del computer su una pista
```

* La traduzione e `Libs\Speed` (S1-S2): il contenitore diventa un WAD in memoria (`IGameWadComposer`).
* La gara e `DelphiDoom.Speed.RaceSimulation`: legge `THINGS` (punti del percorso di tipo 512 e posizioni di partenza di tipo 241), `PATH` (velocita) e il flat `FMAPnn` (terreno) del livello E1M<n>
  e fa girare le classi di `Libs\Racing` (guidatore del computer, fisica, percorso, classifica). Non c'e il motore: niente muri e niente urti tra le auto, niente suono (`DelphiDoom.Speed.Sim.Effects`
  conta le richieste), la vista e il punto di partenza della prima auto (`DelphiDoom.Speed.Sim.Geometry`).
* Con i dati dello shareware (`Reference\_dati\speed\SPEEDH.JCL`: 1613 lump, 50 modelli, E1M1 con 88 punti e E1M2 con 186) le otto auto finiscono 2 giri sia su E1M1 sia su E1M2. Il tempo dei giri su E1M2 varia molto
  (2761-4433 tic) perche senza muri le auto escono dalla pista; **non c'e un riferimento dal vecchio gioco** per questo.
* Codice di uscita: 0 se tutte le auto finiscono i giri entro `-tics`, 2 se no (anche se il livello non c'e: lo dice il testo), 1 per un errore (file mancante, argomento sbagliato).
* Test: `Tests\DelphiDoom.Tests.Speed` (`DelphiDoom.Tests.Speed.RaceSimulation`).

## Che cosa manca per il gioco (S5)

Il gioco su motore id Tech 1 (`GLSpeed32`): `m_base` con `_GAME`, profilo Iwad e `TSpeedLevelRules` in `ComposeLevelRules`; `mobj_t` e `player_t` propri (con `TRacingCarState` copiato da e verso l'oggetto);
le azioni `A_*` di `speed_actions`, HUD (`speed_hud`), menu, schermate, intermission, `speed_end_screen`; il file dei record su disco (`TRacingScoreTableStore`); i savegame (`Libs\Serializer` con la tabella del
gioco); l'adattatore OpenGL dei modelli I3D (`Libs\Models`). Vedi `Libs\Speed\README.md` e `Libs\Racing\README.md` ("Come si collega").
