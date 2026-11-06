# Dati di prova di Libs\Dehacked

Le patch `*.deh` sono scritte a mano per coprire ogni blocco, ogni campo, i formati dei numeri, i commenti e le righe sbagliate (issue #68). I valori sono scelti perche' siano diversi da quelli di partenza dei quattro giochi: una patch che scrive il valore che c'era gia' non cambia l'uscita e non si vede.

I file `*.golden.txt` (cartella base per Doom, sottocartelle `Heretic`, `Hexen`, `Strife`) sono l'effetto del **vecchio** `DEH_Parse` di ciascun gioco, compilato nel motore e fatto girare su ogni patch (un processo per file, tabelle di partenza pulite):

```
[numstates]   quanti stati aveva il motore prima della patch
[warnings]    i messaggi di I_Warning, come li ha scritti
[changes]     le righe dello stesso dump di DEH_CurrentSettings che la patch ha cambiato: intestazione|campo=valore
[old]         il valore che avevano le stringhe cambiate ([Strings]|NOME=testo), per risalire al nome dal testo vecchio
```

Come sono stati fatti (l'harness non e' nel repository, e' temporaneo):

1. un programma `DehHarness<Gioco>.dpr` con lo stesso elenco di unit di `<Gioco>32.dpr` (il motore intero, senza finestra), che dopo `ComposeEngine`, `Z_Init`, `Info_Init(true)`, `Info_InitStateOwners`, `SC_DefaultStatedefLump` e `DEH_Init` legge una patch, chiama `DEH_CurrentSettings` (e `DEH_SpritesCSV`) prima e dopo `DEH_ParseText`, e scrive le differenze;
2. il log dei messaggi e' un `TLogRecorder` dato a `I_ConfigureLog`;
3. nelle uscite di Heretic e Hexen sono state tolte le righe `Thing N|Weave Index Z=0`: il dump del motore le cambia in ogni cosa, con o senza patch (rumore, non effetto di una patch).

`Tests\Source\DelphiDoom.Tests.Dehacked.Parity.pas` fa leggere la stessa patch alla libreria, la passa a `TDumpApplier` (che fa le veci del motore e scrive le stesse righe) e confronta. Per Doom si confrontano tutti i blocchi; per gli altri giochi cose, frame, Misc e Ammo (i loro dump di armi, stringhe, musica e suoni hanno altre intestazioni).

Non e' confrontato (dipende dalle tabelle del motore e lo fa il motore): i nomi di suoni, sprite, azioni, musiche e stringhe; le cose e gli stati nuovi (i loro campi non scritti hanno i valori di partenza del motore); i blocchi `Weapon` degli altri giochi. Le prove su questi punti stanno in `DelphiDoom.Tests.Dehacked.Parser`.
