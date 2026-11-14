# Verifica #194: parita' del modello di gioco di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). Il modello (entita', unita', macchina a stati, economia, danni) si compila **intero**, come unity build (stessa struttura di `tests\test_main.c`), con il gcc di `Reference\_dati\_strumenti\w64devkit`. Non serve il `DATA.WAR`.

```r
powershell -NoProfile -File Compila-ModelRef.ps1 -Out <cartella nuova fuori dal repository>       # compila war_model_ref.exe
war_model_ref tables | scenarios [n] | hostile [n] | dump friendly|hostile SEME TIC | bench [unita' tic]
war_model_ref construction-tables | construction [n] | dump construction SEME TIC                      # seconda fetta: costruzione e addestramento (war_construction_ref.inc)
powershell -NoProfile -File Make-WarModelTables.ps1                                                    # rigenera Model.StatData e Model.ActionData dal golden delle tabelle
powershell -NoProfile -File Make-WarConstructionTables.ps1                                             # rigenera Model.ActionStepData dal golden dei passi delle azioni
powershell -NoProfile -File ..\201\Registra-Golden.ps1 -Solo 194                                      # riscrive model.*.golden.txt (solo se il C e' cambiato di proposito)
powershell -NoProfile -File ..\201\Confronta-Golden.ps1 -Solo 194                                      # confronta
```r

In `war_model_ref.c` ci sono solo gli stub (SDL, grafica, audio, interfaccia), il flusso dei campi e i vicini dell'RVO sostituiti (le definizioni originali sono rinominate con `#define` prima di includere il loro file), gli scenari e il testo dello stato. `Compila-ModelRef.ps1` estrae le intestazioni da `tests\test_main.c` e, al collegamento, da' un corpo che ferma il programma a ogni funzione non definita (codice mai raggiunto del disegno, dell'audio, dei menu). `WAR_REF_TRACE=1` stampa ogni numero casuale e l'inizio di ogni tic. Dettagli di scenari, difetti e differenze: `Libs\War\README.md` (sezione Modello di gioco).

**Seconda fetta (costruzione e addestramento)**: `war_model_ref.c` include anche `war_commands.c` intero e, prima di `main`, `war_construction_ref.inc` (`Compila-ModelRef.ps1` lo copia accanto). Gli scenari `construction` chiamano le funzioni **vere** di `war_commands.c` (`wcmd_tryPlaceBuilding`, `wcmd_executeRepairCommand`, `wcmd_cancel`, i casi TRAIN e UPGRADE di `wcmd_executeCommand`), 24 scenari di 400 tic; `construction-tables` scrive i passi delle azioni (`S`), le risorse delle immagini di costruzione (`R`), i costi dei muri (`K`) e il fattore del trucco del tempo (`H`), da cui `Make-WarConstructionTables.ps1` genera `Model.ActionStepData`. `WAR_REF_COVER=1` stampa su stderr, per scenario, i tic in cui c'era almeno uno stato di ogni tipo. Per cercare una differenza: `war_model_ref dump construction SEME TIC` e, dal lato Delphi, `DELPHIDOOM_WAR_CONSTRUCTION_DUMP=seme,tic,file` con il test `DovrebbeScrivereIlTestoDelloStatoSeRichiesto`. Un contadino non si allontana mai dall'edificio (il follow non c'e') e due miglioramenti della stessa coppia non si ordinano insieme (il C si ferma su un `assert`).
