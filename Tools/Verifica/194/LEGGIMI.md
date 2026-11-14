# Verifica #194: parita' del modello di gioco di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). Il modello (entita', unita', macchina a stati, economia, danni) si compila **intero**, come unity build (stessa struttura di `tests\test_main.c`), con il gcc di `Reference\_dati\_strumenti\w64devkit`. Non serve il `DATA.WAR`.

```r
powershell -NoProfile -File Compila-ModelRef.ps1 -Out <cartella nuova fuori dal repository>       # compila war_model_ref.exe
war_model_ref tables | scenarios [n] | hostile [n] | dump friendly|hostile SEME TIC | bench [unita' tic]
war_model_ref actions | combat [n] | combatstats [n] | dump combat SEME TIC                      # seconda fetta: passi delle azioni, combattimento (gruppo '194 attacco'), copertura degli scenari
powershell -NoProfile -File Make-WarActionSteps.ps1                                                    # rigenera Model.ActionSteps.Data dal golden dei passi
war_model_ref tables | scenarios [n] | hostile [n] | gather [n] | gather-tables | dump friendly|hostile|gather SEME TIC | bench [unita' tic]
powershell -NoProfile -File Make-WarGatherTables.ps1                                                  # rigenera Model.GatherData dal golden gather.tables.golden.txt (passi della raccolta, immagini dei trasportatori)
powershell -NoProfile -File Make-WarModelTables.ps1                                                    # rigenera Model.StatData e Model.ActionData dal golden delle tabelle
powershell -NoProfile -File ..\201\Registra-Golden.ps1 -Solo 194                                      # riscrive model.*.golden.txt (solo se il C e' cambiato di proposito)
powershell -NoProfile -File ..\201\Confronta-Golden.ps1 -Solo 194                                      # confronta
```r

In `war_model_ref.c` ci sono solo gli stub (SDL, grafica, audio, interfaccia), il flusso dei campi e i vicini dell'RVO sostituiti (le definizioni originali sono rinominate con `#define` prima di includere il loro file), gli scenari e il testo dello stato. `Compila-ModelRef.ps1` estrae le intestazioni da `tests\test_main.c` e, al collegamento, da' un corpo che ferma il programma a ogni funzione non definita (codice mai raggiunto del disegno, dell'audio, dei menu). `WAR_REF_TRACE=1` stampa ogni numero casuale e l'inizio di ogni tic. Dettagli di scenari, difetti e differenze: `Libs\War\README.md` (sezione Modello di gioco).

**Raccolta (seconda fetta)**: `gather` fa girare 10 scenari di raccolta di 1800 tic (ogni tic una riga `G seme tic impronta entita`, poi il riassunto `Q`). Dichiarato in `war_model_ref.c`: il crollo (`wst_enterCollapseState` non fa nulla, il giro di aggiornamento non si chiama), `wmap_setMapTileIndex` registra le tessere, il seguimento non si chiama e lo scenario toglie lo stato come fa il seguimento (`gatherResolveFollows`), e `we_addSpriteComponentFromResource` toglie lo sprite che c'e' (difetto del remake non conservato, vedi README di `Libs\War`).
