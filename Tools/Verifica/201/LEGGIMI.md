# Verifica #201: il criterio di parita' di Libs\War come strumento

Il documento e' `docs\PARITA_WAR.md`. Qui i due script e la tabella.

```
powershell -NoProfile -File Confronta-Golden.ps1 [-DataWar <DATA.WAR>] [-Solo 191|192|193|198|musica|suoni] [-Out <cartella nuova>] [-Test <DelphiDoom.Tests.War.exe>]
powershell -NoProfile -File Registra-Golden.ps1  [-DataWar <DATA.WAR>] [-Solo ...] [-Out <cartella nuova>]
```

- `Golden-Common.ps1` ha la **tabella** gruppo -> `Compila-*.ps1` (in `Tools\Verifica\191`, `192`, `193`, `198`) -> programma C ->
  argomenti -> golden di `Tests\Data\War`. Per una parte nuova di War (il modello di gioco, #194) si aggiunge un gruppo.
- `Confronta-Golden.ps1` rifa ogni golden dal C del remake in una cartella temporanea e lo confronta (senza BOM e fine riga):
  e' la prova che i golden sono ancora quelli del C. Con `-Test` esegue anche il progetto di test e riporta i numeri.
  Codice di uscita 1 se qualcosa differisce o un test fallisce; i golden che vogliono il `DATA.WAR` si saltano se manca.
- `Registra-Golden.ps1` li riscrive: **solo** quando il C e' cambiato di proposito.
- Misura a coppie (`Tools\Misura-Coppie.ps1`): vale per due eseguibili di gioco; War non ne ha ancora uno (#200).
