# War1: differenze tra il remake, War1gus e l'originale (issue #253)

Studio di sola lettura, senza eseguire nulla: `Reference\war1` (remake in C, zlib), `Reference\war1gus` (importer `war1tool.cpp`,
script Lua delle campagne e delle unita' sul motore Stratagus, **GPL-2.0**: si usa per capire, **nessun codice o dato e' copiato**
nel repository) e il nostro `Games\War`. I dati commerciali restano in `Reference\_dati\warcraft` e non entrano nel repository.
L'originale (DOS) non ha sorgente pubblico: il suo comportamento si vede solo in DOSBox, con confronti a mano dell'utente.

## 1. Missione 4 degli umani: causa trovata

- La missione e' il livello **123** del `DATA.WAR` (tileset 2, dungeon). Il test `DelphiDoom.Tests.War.LevelUnitCoverage` (dati
  veri, si ignora senza `DATA.WAR`) passa in rassegna le unita' di partenza dei 66 livelli e prova che **l'unico tipo che il
  modello non sa creare e' `WAR_UNIT_WOUNDED` (16), cinque unita' nel solo livello 123**. Tutti gli altri livelli sono interi.
- Nel remake `unitStats[]` (`war_units.c:236`, 28 voci) non ha `WAR_UNIT_WOUNDED`, ne' `DRAGON_CYCLOPS_GIANT`, 26 e 30: `wu_getUnitStats`
  usa `FIND_BY_TYPE` e cade su `assert(index < length)` (`war_units.c:702`). Quindi la missione 4 degli umani **non e' mai
  stata giocabile nel remake** (e' fuori dalla sua demo); non e' un difetto del nostro porting.
- In Warcraft 1 le unita' "ferite" sono il soggetto della missione (salvare Lothar e i feriti). In War1gus
  (`campaigns\human\04_c.sms`): le unita' del giocatore 4 sono feriti (`unit-wounded-lothar` per Lothar), partono con 5 punti
  ferita (`SetUnitVariable HitPoints 5`), tornano soldati (footman, o Lothar) quando superano i 20; vittoria quando Lothar
  e' vicino al punto di partenza (`IfNearUnit`/`IfRescuedNearUnit`), sconfitta se il giocatore non ha piu' unita' o se Lothar
  scende sotto 1 punto ferita. `scripts\units.lua`: "Wounded" 60 punti ferita, nessun attacco, immagine `neutral/units/wounded`.
  Nota: la parte "5 punti e guarigione" e' dichiarata da War1gus un "Hack" per il suo motore: non e' provata come regola dell'originale.
- Nostro comportamento: `TWarDatabase.GetUnitStats` -> `EWarException` (differenza voluta, `Games\War\README.md`), il programma esce con codice 1.
- **Proposta (non fatta: serve una decisione dell'utente)**: dare a `WOUNDED` statistiche proprie in una tabella *supplementare* (non nella
  tabella generata dal C: i golden `model.tables`, `map.tables` restano uguali), cosi' `TWarDatabase.TryGetUnitStats` e
  `TWarUnitCatalog.FindStats` le trovano. Valori candidati da War1gus: punti ferita 60, armatura 0, nessun attacco/mana, velocita'
  0 (gia' cosi' nel nostro codice). Mancano nelle fonti: raggio visivo (si propone 2 come gli altri non combattenti). Poi
  regola dei feriti (guarigione, passaggio a footman/Lothar) e condizione di vittoria della missione 4 in `TWarObjectives`
  (oggi: solo le tre `wcamp_check*` del remake, il resto della campagna non ha obiettivi). Prima di farlo conviene confrontare in DOSBox
  come si comportano i feriti (punto 4 della lista) perche' i numeri non sono verificabili qui.

## 2. Tileset dungeon

- Remake: `MAP_TILESET_DUNGEON` esiste, ma `renderRuin/Wall/Road/Forest` (`war_entities.c:1968..2151`) hanno
  `assert(tileset == FOREST || SWAMP)`: la prima mappa dungeon con strade, muri o rovine ferma il gioco (**orchi 4**: `war_entities.c:2085`).
  Anche `war_trees.c:234` usa le tegole della palude per gli alberi abbattuti del dungeon.
- War1gus (`war1tool.cpp:228..623`) estrae per il dungeon **tegole proprie**: muro (66), strada (81), rovine 4x4..1x1 (83),
  muro in costruzione (22), ingresso della miniera 2x3, pentagramma, pareti nord con botti/armadio. Quindi l'originale ha muri,
  strade e rovine nel dungeon: l'`assert` e' una lacuna del remake.
- Nostro codice: per il dungeon usiamo le tegole della palude (differenza voluta, `Games\War\CLAUDE.md`, parte B). Non provato su dati: la
  mappa dungeon con muri/rovine non e' mai stata disegnata. Livelli dungeon del `DATA.WAR` (tileset 2): 123 124 131 132 161..167 182..188
  (gli ultimi sono mappe del menu di una partita personalizzata).
- Proposta: tegole dungeon vere dal tileset

## 3. Cosa fa War1gus rispetto al remake

| Area | War1gus (Stratagus) | Remake in C / nostro port |
|---|---|---|
| Livelli | `war1tool` estrae da `DATA.WAR` mappe in `.smp`/`.sms` e le campagne in `campaigns\<razza>\NN_c.sms` (Lua) | legge il livello dal `DATA.WAR` (info, tegole visive, passabilita': `Level.*`) |
| Tileset | `scripts\tilesets\*_campaign.lua`: tegole con ruoli (muro, strada, rovine, alberi) per forest, swamp, dungeon | solo forest e swamp hanno raccordi; dungeon: palude |
| Vittoria | trigger Lua per missione: M1 umani 6 fattorie + 1 caserma; M5-M6, M9-M11 nessun nemico (`GetNumOpponents == 0`); M7 nessun contadino del giocatore 4 e nessun nemico; M4 Lothar al punto di partenza; orchi 4 nessun nemico | tre `wcamp_check*Objectives` (`Campaign.Objectives`): oro/legna/edifici/distruzione; il remake gioca solo le due missioni della demo; vittoria controllata prima della sconfitta |
| Sconfitta | `TotalNumUnits == 0` per tutte le missioni (4: anche Lothar morto) | tutte le unita' o gli edifici del giocatore |
| Statistiche | `scripts\units.lua`, `balancing.lua`, `upgrade.lua`: una tabella per unita' (anche Wounded, Lothar, Medivh), rimescolata con valori propri di Stratagus | `unitStats[]` 28 voci, `buildingStats`, `upgradeStats` (nostro `Model.StatData`, generata dal C) |
| IA | script Lua (`scripts\ai\`), con ondate e costruzione | copione fisso di 408 righe di C (giocatore 1: municipio e lavoratori, poi pausa); ATTACK/DEFEND non esistono |
| Movimento | motore di Stratagus (A star, formazioni) | campi di flusso + RVO "non ORCA", nessuna formazione |
| Combattimento | formule di Stratagus (danno base/piercing, armatura) | formule del remake (`we_takeDamage`, 1..9 + casuale) |
| Salvataggio | stato di Stratagus | storia dei comandi rigiocata (nostro) |

Il remake e il nostro porting **non** sono quindi una riproduzione dell'originale; sono fedeli al remake (golden sul C). War1gus
e' una seconda interpretazione (con regole sue) e va usato come indizio, mai come oracolo.

## 4. Differenze note nostro port / remake / originale

1. Obiettivi: `wcamp_getCampaignData` ha la funzione solo per i tipi della demo del remake; per gli altri `checkObjectivesFunc` e' nullo (nessuna vittoria automatica: da verificare giocando).
2. Livello 123 (umani 4): non si carica (WOUNDED senza statistiche); orchi 4 (probabilmente 124, dungeon): carica (nessuna unita' senza dati), ma muri/strade/rovine con tegole di palude.
3. Musica muta; effetti non ascoltati; filmati finali, WIN/LOSE e HMAP/OMAP non collegati.
4. IA: solo il copione del remake.
5. Il remake non ha formazioni, ne' comando di pattuglia, ne' colori per fazione (il remake e', in tutto, piu' povero dell'originale).
6. Caricamento di un salvataggio: replay dell'intera storia (lento in partite lunghe).
7. Debug: righe oblique con una coordinata in (-1, 0) e alfa parziali non uguali a SDL (limiti dichiarati in #197).

## 5. Lista di controllo per la giocata a mano (Warcraft32)

Per ogni voce annotare: missione, tempo di gioco, cosa succede, e se in DOSBox accade lo stesso.

- [ ] **Umani 1** (fattorie e caserma): costruire 6 fattorie e una caserma: arriva la vittoria? I contadini raccolgono oro e legna? Il cibo limita l'addestramento?
- [ ] **Umani 2 e 3**, **orchi 1-3**: condizione di vittoria e di sconfitta (distruggere tutti i nemici, perdere tutto); fine missione e passaggio al briefing successivo.
- [ ] **Umani 4**: si carica? Atteso oggi: uscita con codice 1 e il messaggio sul tipo 16. In DOSBox osservare: dove sono i feriti e Lothar, come appaiono (sprite "wounded"), quanti punti ferita hanno, cosa serve per salvarli (avvicinarsi? un chierico?), cosa diventano, come si vince.
- [ ] **Orchi 4** (dungeon): si carica; disegnare strade/muri/rovine: confronto dei tile con DOSBox. Costruire un muro nel dungeon e guardare il tile.
- [ ] Missioni dungeon 8 (umani) e orchi 8: stessa osservazione dei tile, presenza di Medivh/ingressi della miniera.
- [ ] Costruzione: anteprima verde/rossa, costo, tempo, annulla (rimborso); riparazione; strade e muri; addestramento in coda e annullamento.
- [ ] Combattimento: frecce, catapulta, incantesimi (pioggia di fuoco, nube velenosa, risuscita, vista), morte e cadaveri, danno ai muri; portata e velocita' rispetto a DOSBox.
- [ ] Movimento: gruppi che si incrociano (evitamento RVO), bloccaggio dopo 3 secondi, percorso attorno ai muri; l'originale non ha formazioni.
- [ ] Nebbia: bersagli rivelati, alberi tagliati, minimappa.
- [ ] Menu F10: opzioni, velocita', volumi, obiettivi, ricomincia, fine; trucchi; Salva (F5) e Carica (F9): tempo di caricamento dopo 5, 15, 30 minuti di partita.
- [ ] Audio: se si sente (effetti con posizione), volume con la distanza; la musica e' muta (atteso).
- [ ] Filmati: introduzione dal menu "Replay introduction"; finali non collegati (atteso).
- [ ] Qualunque arresto: copiare l'ultima riga di `stderr`/`crash.txt`.

## 6. Lista di controllo per il confronto in DOSBox (a mano, con `Reference\_dati\warcraft`)

Mai eseguito da automatismi. Per ogni punto: stessa missione, stessi ordini, confronto di screenshot e tempi.

1. **Feriti della missione 4 umana**: punti ferita, raggio visivo, cosa li fa tornare soldati, dove e' Lothar, condizione di vittoria.
2. **Tile del dungeon**: muro, strada, rovine, ingresso della miniera, pentagramma (War1gus ha tile propri per ognuno).
3. **Statistiche**: tempo di addestramento e costo di un fante e di un contadino, danno e portata di arciere e catapulta, velocita' di marcia, punti ferita di Lothar e Medivh (remake: 50 e 110).
4. **Vittoria/sconfitta** della missione 1 (6 fattorie e caserma) e di una missione "distruggi tutti": quando compare il messaggio.
5. **IA** del giocatore 1 nella missione 2: quante unita' costruisce e quando attacca (il nostro copione e' fermo dopo l'avvio).
6. **Formazioni e pattuglia**: confermare che non esistono (il remake non le ha).
7. **Salvataggio**: se l'originale salva la posizione delle unita' e il tempo.
