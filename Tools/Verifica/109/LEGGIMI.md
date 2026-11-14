# Verifica #109: navigazione AAS di Doom 3

Produce `Tests\Data\AasD3\route.golden.txt` e `route_small.golden.txt` con il codice **vero** di Doom 3: `Build-Harness.ps1` copia in `C:\harness\d3\idlib` (fuori dal repository) l'idlib di `Reference\doom3\neo\idlib`, i veri `AASFile.cpp`, `AASFile_sample.cpp`, `AASFileManager.cpp` del compilatore AAS e i veri `AAS.cpp`, `AAS_routing.cpp`, `AAS_pathing.cpp` di `game\ai`, e li compila con `bcc32c` (il clang a 32 bit di Delphi 11) insieme a `route_driver.cpp`. Le correzioni alla copia, tutte nello script: gli `#include` dei precompilati, `private:` in `public:` (le liste delle cache), `register` tolto da `Simd_Generic.cpp` (C++17), `Game_local.h` e `Pvs.h` al posto di stub, `MAX_ROUTING_CACHE_MEMORY` (a 3000 byte per `route_small`). Nessun file di Doom 3 e' nel repository.

```
powershell -NoProfile -File Tools\Verifica\109\Make-RoutingAas.ps1                      # aas_ring.aas (anello 5x3, un portale in colonna 2)
powershell -NoProfile -File Tools\Verifica\109\Make-RoutingAas.ps1 -Out Tests\Data\AasD3\aas_grid.aas -Columns 8 -Rows 3 -Layout full -PortalColumns 2,5 -Crc 2882400110
powershell -NoProfile -File Tools\Verifica\109\Make-RoutingAas.ps1 -Out Tests\Data\AasD3\aas_grid2.aas -Columns 7 -Rows 4 -Layout full -PortalColumns 3 -Crc 2882400111
powershell -NoProfile -File Tools\Verifica\109\Build-Harness.ps1                        # rifa le due golden
```

- `route_driver.cpp` e' il gemello di `Tests\Source\DelphiDoom.Tests.Aas.D3.Scenario.pas`: **le righe stampate sono le stesse**; cambiando una parte si cambia l'altra.
- Le righe: `AREAS`, `AR` (flags, travelFlags, contents, cluster, centro come bit), `PT` (portali), `RE` (raggiungibilita'), `RT` (route a tutte le coppie, 3 insiemi di travel flags), `CACHE` (numero di cache di aree e portali, memoria, nell'ordine in cui il C++ le conta), `WP`/`WV`/`WW`/`FP`/`FV` (percorsi), `FG` (`FindNearestGoal` con tre callback e un ostacolo), `WE`/`WS` (spigoli dei muri e ordinati), `EV` (vertici e punti di uno spigolo), `SAS`/`SAE` (aree portale chiuse e aperte), `AO`/`RO*` (ostacoli, con il difetto dell'originale), `INIT2` ("Keeping").
- I float sono `#` e gli 8 digit esadecimali dei bit. Le righe `P:`/`W:` sono i messaggi (`gameLocal.Printf`, `common->Warning`); le tre righe che l'idlib stampa caricando il file (`P: [Load AAS]`, `loading`, `done.`) il test le ignora.
- **Non e' una verifica sui dati di Doom 3**: i mondi sono inventati (`Make-RoutingAas.ps1`). Provati: tutto il C++ del routing, dei percorsi e degli ostacoli; non provati: il PVS e i tre `idAASCallback` di `AI.h`.

## Evitamento degli ostacoli (`AI_pathing.cpp`)

```
powershell -NoProfile -File Tools\Verifica\109\Build-AvoidHarness.ps1                   # rifa Tests\Data\AasD3\avoid.golden.txt
```

- Compila con bcc32c **le righe vere** di `Reference\doom3\neo\game\ai\AI_pathing.cpp` (da `obstacle_t` a `idAI::FreeObstacleAvoidanceNodes`, e `Ballistics`..`HeightForTrajectory`) insieme al vero `idAASLocal` e all'idlib, in `C:\harness\d3avoid` (niente di Doom 3 finisce nel repository). L'unica modifica alle righe vere: `memset` dell'array `optimizedPath` di `FindOptimalPath` (nell'originale non e' inizializzato).
- `avoid_stub.h` e' il finto del gioco (entita', fisica, clip, mondo di rendering); `avoid_driver.cpp` e' il pilota: scenario A (`idAI::FindPathAroundObstacles` su `idAASLocal`, modelli di sette generi), B (le funzioni su winding costruiti, albero compreso), C (tiri).
- E' il gemello di `Tests\Source\DelphiDoom.Tests.Aas.D3.AvoidScenario.pas`: **le righe stampate sono le stesse**; cambiando una parte si cambia l'altra. Estrazioni casuali (xorshift32, seme 2463534242) sempre in istruzioni separate: l'ordine di valutazione di argomenti e costruttori non e' definito.
- Righe: `FP` (percorso), `OB`/`PI`/`PO`/`BL` (ostacoli, punto dentro, punto fuori, primo bloccante), `BT`/`PT` e `TN` (albero prima e dopo la potatura), `FO` (percorso ottimo), `FT` (nodi dopo la liberazione), `BA` (tiri: angolo, tempo, altezza).