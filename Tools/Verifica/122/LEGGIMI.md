# Verifica #122: AAS di Quake III

Produce `Tests\Data\Aas\aas.golden.txt` con il codice **vero** di Quake III: `build.sh` copia senza modifiche `code/botlib/be_aas_file.c` e `be_aas_sample.c` (e `aasfile.h`, con un guard) in una cartella di lavoro, con le righe vere di `game/be_aas.h` (`aas_trace_t`, `aas_areainfo_t`), `game/q_math.c` (`VectorLength`, `VectorNormalize`), `botlib/be_aas_main.c` (`AAS_Error`) e `botlib/be_aas_reach.c` (`AAS_AreaReachability`, `AAS_AreaSwim` ... `AAS_AreaDoNotEnter`); `stub/` sostituisce il resto (`q_shared.h` con le macro vettoriali copiate da quello vero, `botlib.h`, memoria, variabili, `be_aas_def.h` ridotto ai campi usati); `aasgen.c` e' il pilota.

```
sh Tools/Verifica/122/build.sh <cartella di uscita>
<cartella>/aasgen.exe | sed 's/$/\r/' > Tests/Data/Aas/aas.golden.txt
<cartella>/aasgen.exe dump <variante 0..3> <file>      (scrive un file .aas di prova)
```

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`: ogni operazione float arrotondata da sola).
- Nessun file di un gioco: il pilota costruisce i mondi (una fila di scatole da 64 unita', stessa ricetta di `Tests\Source\DelphiDoom.Tests.Aas.Sample.pas`), li serve a `AAS_LoadAASFile` attraverso `botimport.FS_*` finti e campiona con xorshift32 a seme 2463534242 (coordinate multiple di 1/8). Casi: `0` (4 aree, versione 5), `1` (6 aree, piano obliquo alla radice dell'albero delle aree), `2` (versione 4, intestazione in chiaro), `3` (16 byte tra i lump degli spigoli e delle facce: avvisi "not sequentially read"), poi file rovinati (identificatore, versione 6, checksum, file mancante).
- Righe: `P<livello>|testo` e' `botimport.Print` (byte sotto 32, sopra 126 e barra rovesciata come `\xNN`); i float sono i 8 digit esadecimali dei bit; `crcs` sono i CRC-32 dei 14 lump (come nel file); `pt`, `ta`, `ta2`, `tb`, `face`, `box`, `area`, `bbox`, `reachabilityareas` sono le funzioni di `be_aas_sample.c` e `be_aas_reach.c`.
- Per le aree portale (`cluster < 0`) `AAS_PointReachabilityAreaIndex` non e' chiamata (`reach P`): il C legge `portals[-1]`, fuori dall'array (difetto, vedi `IdTech4\Aas\README.md`).
- Cosa **non** viene dal C: i mondi e il pilota; il C vero da' la lettura del file, la decifratura dell'intestazione, i controlli, i messaggi, il campionamento.


## Il routing (be_aas_route.c, be_aas_routealt.c): `route\`

`route\build.sh` (come `build.sh`: gcc di w64devkit, `DELPHIDOOM_ROOT` con la barra dritta, `sh` di w64devkit) compila i **veri** `be_aas_file.c`, `be_aas_sample.c`, `be_aas_route.c` e `be_aas_routealt.c` con `route\routegen.c`; `route\Make-Golden.ps1` lo costruisce, estrae i `.aas` di OpenArena dai pak (`Reference\openarena`, non nel repository) e scrive `Tests\Data\Aas\route_<mappa>.golden.txt` e `route_<mappa>_small.golden.txt`. Le **uniche due modifiche** al codice vero stanno in `route\build.sh` (con il motivo): `reachnum = 0` in `AAS_AreaTravelTimeToGoalArea`/`AAS_AreaReachabilityToGoalArea` (lo stack da' risposte diverse) e `startareatraveltimes[4096]` al posto di `[128]` (un'area di 266 raggiungibilita' inverse legge oltre). `AAS_NearestHideArea` non e' nel pilota (overflow di heap nel C). Il gemello Delphi e' `Tests\Source\DelphiDoom.Tests.Aas.Route.Scenario.pas`. Dettaglio: `IdTech4\Aas\README.md`.
