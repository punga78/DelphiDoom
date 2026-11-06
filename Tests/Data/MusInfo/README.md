# Dati di prova di Libs\MusInfo

`cases.txt` ha i testi del lump MUSINFO scritti a mano (issue #72): mappe `ExMy` e `MAPxx`, id nei vari formati (decimale, `0x`, `$`, `#`, `x`, `+`), id fuori intervallo (`-1`, `65`), ripetuti, nomi di musica tra virgolette, vuoti, di otto caratteri, con caratteri sopra 127, commenti, fine riga CR LF / LF / CR, testo senza fine riga finale, lump mancante, token che sembrano mappe, lump letto due volte.

Formato: `@@@ nome` apre un caso; `@@ run [lf|cr] [notrail]` apre il testo di una chiamata di `P_InitMusInfo` (righe unite con CR LF, LF o CR; un fine riga anche dopo l'ultima, salvo `notrail`); `@@ missing` e' una chiamata senza lump; `@@ find ID MAPPA` chiede la musica dopo tutte le chiamate.

`musinfo.golden.txt` e' l'effetto del **vecchio** `Base\p_musinfo.pas`, per ogni caso: `warnings` (i messaggi di `I_Warning`, con `\r\n` scritti come testo), `count`, ogni voce (`map`, `id`, `name`, `num`: il numero e' quello dato da `S_GetMusicNumForName`) e le risposte di `P_FindMusinfoMusic` alle domande `find`.

Come e' stato fatto (l'harness non e' nel repository, e' temporaneo):

1. uno script ricava da `Base\p_musinfo.pas` una copia della sola parte di lettura **senza modifiche** (righe 170-311: `musinfo_t`, `P_AddMusInfo`, `P_InitMusInfo`, `P_FindMusinfoMusic`); la procedura `A_MusicChanger` e' esclusa perche' dipende da `mobj`, giocatori e livello. Alla copia si aggiungono tre funzioni di accesso (azzera, conta, leggi la voce) per scaricare l'array;
2. la copia e' compilata con `dcc32 -DDOOM` insieme ai veri `Common\d_delphi.pas` e `Base\sc_engine.pas` (la facciata sopra `Libs\Scanner`) e a stub di `i_system` (`I_Warning` scrive su una stringa), `w_wad` (`stringtochar8` come l'originale ma con eccezione al posto di `I_Error`; `W_CheckNumForName`/`W_TextLumpNum` danno il testo del caso) e `sounds` (`S_GetMusicNumForName`: un nome che inizia con `D_` esiste e il numero si calcola dal nome, `1000 + lunghezza * 100 + somma dei caratteri mod 97`; gli altri danno -1; stessa regola di `TFakeMusic` nei test);
3. il programma legge `cases.txt` (36 casi), azzera l'array, fa girare le chiamate e scrive il dump.

Non coperto: il vero `S_GetMusicNumForName` (accetta anche un numero e dice `0` per un nome vuoto), un lump letto da un WAD vero, l'overflow dei 1024 elementi (il vecchio codice li' scatena una `EConvertError` nel messaggio, vedi `WIRING.md`: e' coperto da `DelphiDoom.Tests.MusInfo.Catalog`) e i nomi sopra 8 caratteri (il vecchio codice si ferma con `I_Error`; coperto da `DelphiDoom.Tests.MusInfo.Parser`).
