# Verifica #194: parita' del modello di gioco di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). Il modello (entita', unita', macchina a stati, economia, danni) si compila **intero**, come unity build (stessa struttura di `tests\test_main.c`), con il gcc di `Reference\_dati\_strumenti\w64devkit`. Non serve il `DATA.WAR`.

```r
powershell -NoProfile -File Compila-ModelRef.ps1 -Out <cartella nuova fuori dal repository>       # compila war_model_ref.exe
war_model_ref tables | scenarios [n] | hostile [n] | dump friendly|hostile SEME TIC | bench [unita' tic]
powershell -NoProfile -File Make-WarModelTables.ps1                                                    # rigenera Model.StatData e Model.ActionData dal golden delle tabelle
powershell -NoProfile -File ..\201\Registra-Golden.ps1 -Solo 194                                      # riscrive model.*.golden.txt (solo se il C e' cambiato di proposito)
powershell -NoProfile -File ..\201\Confronta-Golden.ps1 -Solo 194                                      # confronta
```r

In `war_model_ref.c` ci sono solo gli stub (SDL, grafica, audio, interfaccia), il flusso dei campi e i vicini dell'RVO sostituiti (le definizioni originali sono rinominate con `#define` prima di includere il loro file), gli scenari e il testo dello stato. `Compila-ModelRef.ps1` estrae le intestazioni da `tests\test_main.c` e, al collegamento, da' un corpo che ferma il programma a ogni funzione non definita (codice mai raggiunto del disegno, dell'audio, dei menu). `WAR_REF_TRACE=1` stampa ogni numero casuale e l'inizio di ogni tic. Dettagli di scenari, difetti e differenze: `Libs\War\README.md` (sezione Modello di gioco).
