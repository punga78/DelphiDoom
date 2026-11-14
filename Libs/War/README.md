# Libs\War

> Note per Claude e paragrafi di dettaglio: [CLAUDE.md](CLAUDE.md).

Port in classi della **lettura dell'archivio `DATA.WAR`** di *Warcraft: Orcs & Humans* (Blizzard, 1994), dal remake in C **war1** di Alejandro Coto Gutierrez (`acoto87/war1`, in `Reference\war1`, sola lettura): `war_file.c`/`war_file.h` (l'archivio e la decompressione), la tabella `assets[]` di `war_database.h` (che cos'e' ogni record) e `wres_tryGetPredefinedCustomMapIndex` di `war_resources.c`. Issue #191 (indice: #203; licenza e fuori ambito: #202; dati: #190). Senza dipendenze dal motore; usa solo `Libs\MathCore` (`TCrc32`) nei test.

**Licenza.** Il remake e' **zlib License** ((C) 2019 Alejandro Coto Gutierrez), compatibile con la GPL v2 o successiva del repository; il testo e' in [LICENSE-war1.txt](LICENSE-war1.txt) e ogni unit derivata dice nell'intestazione di essere una **versione modificata** del remake (clausola 2). I dati di gioco sono commerciali (Blizzard): **non sono nel repository** e non si ridistribuiscono (`Reference\_dati\MANIFEST.md`, `Tools\Verifica\190`).

## Formato

```
0   u32  archiveID       0x18 (24) o 0x1A = gioco completo, 0x19 (25) = demo
4   u32  numberOfEntries 583 nel DATA.WAR DOS (al massimo 586)
8   u32[numberOfEntries]  offset di ogni record; 0 o 0xFFFFFFFF = segnaposto (la demo non ha il record)
...  record: u32 (bit 0-28 = lunghezza espansa, bit 29-31 != 0 = compresso) e i dati
```

La lunghezza che un record occupa nel file e' la distanza dall'offset del successivo **che non e' un segnaposto** (l'ultimo: fino alla fine del file). La compressione e' una finestra di 4096 byte (tutti zero all'inizio) con gruppi di 8 elementi e un byte di maschera letto dal bit basso: 1 = byte letterale, 0 = due byte (12 bit di posizione nella finestra, 4 bit di lunghezza meno 3).

## Mappa nome C -> classe

| C (`Reference\war1\src`) | Delphi |
|---|---|
| `WarFile` / `WarRawResource` (`war_resources.h`) | `TWarArchive` (`IWarArchive`) e `TWarRecordInfo` (la riga della directory, senza i byte) |
| `wfile_loadWarFile`: lettura, intestazione, tabella, calcolo delle lunghezze, controlli | costruttore e `BuildDirectory` di `TWarArchive` |
| `wfile_loadWarFile`: la decompressione | `TWarDecompressor.Expand` |
| `wfile_freeWarFile` | niente: i byte non si tengono, `ReadRecord` li dà |
| `wfile_readU16LE`, `wfile_readU32LE` | `TWarLittleEndian.ReadWord`, `ReadCardinal` |
| `WarFileType`, `WarResourceType`/`DatabaseEntryType`, `MAX_RESOURCES_COUNT` | `TWarFileType`, `TWarRecordType`, `WAR_MAX_RESOURCES_COUNT` (`DelphiDoom.War.Types`) |
| `assets[]` (`war_database.h`, 579 voci) | `TWarCatalog` (`IWarCatalog`) con i dati di `DelphiDoom.War.Catalog.Data` (generato) |
| `skipDecompress[]` di `wg_loadDataFile` | `IWarCatalog.IsSkipped` e `wrsSkipped` nella directory |
| `wres_tryGetPredefinedCustomMapIndex` | `IWarCatalog.TryGetPredefinedCustomMapIndex` |
| `SDL_IOFromFile`/`SDL_ReadIO` | `IWarSource` (`TWarStreamSource` sopra un `TStream`) |
| `logError(...)` e segnaposto | `Status` (`TWarRecordStatus`) della riga della directory; l'eccezione `EWarException` per i guasti dell'archivio |

Una `TWarFactory` crea tutto (`OpenFile`, `OpenStream`, `CreateCatalog`).

## Parte grafica (issue #192, prima fetta)

I record grafici di `DATA.WAR` diventano pixel RGBA sopra `IWarArchive` e `IWarCatalog` (`IWarGraphics`, creato da `TWarFactory.CreateGraphics`). Ogni chiamata decodifica il record richiesto (l'originale decodificava tutto all'avvio); il tipo che il catalogo da' al record deve essere quello chiesto, altrimenti `EWarException`. I pixel sono `R G B A` (il colore 0 e' trasparente, tutti e quattro i byte a zero).

| C (`war_resources.c`, `war_font.c`) | Delphi |
|---|---|
| `wres_loadPaletteResource` (x4, correzioni delle palette 255 e 217, record corto completato con zeri) | `TWarPaletteDecoder.Decode`, `IWarGraphics.GetPalette` |
| `wres_getPalette` (palette 1 + palette 2, il magenta 252,0,252) | `TWarPaletteComposer.Compose`, `IWarGraphics.ComposePalette` |
| `buildRgbaLut` | `TWarColorLookupBuilder.Build` e `PutPixel` |
| `wres_loadImageResource` | `TWarImageDecoder`, `GetImage` (`TWarImage`) |
| `wres_loadSpriteResource` | `TWarSpriteDecoder`, `GetSprite` (`TWarSprite`, `TWarSpriteFrame`) |
| `wres_loadCursor` | `TWarCursorDecoder`, `GetCursor` (`TWarCursor`) |
| `wres_loadTiles` | `GetTiles` (`TWarTiles`: i byte e le due palette del catalogo) |
| `wres_loadTileset` (mega tegole 2 x 2, specchi X e Y, 512 x 256) | `TWarTilesetDecoder`, `GetTileset` (`TWarTileset`) |
| `WarFontData fontsData[2]`, `getFontData`, `getCharIndex` | `DelphiDoom.War.Font.Data` (generato), `TWarFontMetrics` (`IWarFontMetrics`, `CreateFontMetrics`) |

Record su disco `packed`, senza puntatori, con `SizeOf` coperto da un test: `TWarImageHeader` (4), `TWarSpriteHeader` (4), `TWarSpriteFrameEntry` (8), `TWarCursorHeader` (8), `TWarTilesetEntry` (8).

**Difetti del C conservati**: la palette e' il byte del file per 4 troncato a 8 bit (63 -> 252, 64 -> 0); le correzioni a mano delle palette 255 e 217; la seconda palette vale per ogni record che la cita; nello sprite tutti i fotogrammi stanno in un solo blocco di pixel, quindi un fotogramma che esce dalla riga scrive nella riga dopo e uno che esce dall'area nel fotogramma dopo (come il C, nello stesso ordine); lo scarto di una mini tegola e' `(valore & 0xFFFC) << 1` troncato a 16 bit; `getCharIndex` legge `char` con segno (da 128 in su e' il glifo 0, anche lo spazio e il byte 0); la tabella dei glifi del secondo font ha un glifo (`|`) che si sovrappone a quello del `q`.
**Differenze volute** (ognuna con un test): un record di immagine, cursore o sprite che non contiene tutti i suoi pixel, o uno sprite che scrive oltre il blocco, una mini tegola che punta oltre il record delle tegole o piu' di 512 tegole sono `EWarException` (il C leggeva o scriveva fuori dalla memoria); una palette citata che non e' una palette del catalogo e' `EWarException` (il C leggeva i byte di un altro tipo di record); i caratteri da 1 a 31 e il 127 non hanno un glifo (`TryGetGlyph` da' falso; il C leggeva la tabella fuori dai limiti).
**Non portato**: i **PNG dei due font** (`war1_font_1.png`, `war1_font_2.png`) sono immagini disegnate per il remake, non stanno in `DATA.WAR`: li carica il rendering (#197); `wfont_measure*`/`wfont_render*` (layout e disegno del testo, #197); `WarSprite`/`wspr_*` (texture SDL, #197); **la traduzione dei colori per fazione**: il remake non ha una tabella di traduzione per il giocatore (le unita' si disegnano con i colori del loro sprite; l'unico colore per giocatore e' `wu_getUnitColorOnMinimap`, della minimappa, #197) e `wmap_getMapTileAverage` (colore medio di una tegola per la minimappa, #193/#197); icone e immagini di interfaccia sono gia' record `wrtImage`/`wrtSprite` del catalogo (la distinzione e' del rendering, #197).

## Non portato (fetta #191)

- Il resto di `war_resources.c` (livelli, testi, musica, suoni): sono le fette #193 e #198.
- `wfile_loadWarMapFile` (le mappe `.w1m` dell'editor del remake): fuori ambito (#202).
- Gli archivi Macintosh (id big endian, `0x1A000000`): l'originale non li legge.

## Verifica

`Tools\build.bat DelphiDoom.Tests.War` e poi `bin\Tests\DelphiDoom.Tests.War.exe`. 174 test (archivio costruito in memoria con un finto del file, decompressore, catalogo, sorgente su stream, parita', e per #192 palette, decoder, `TWarGraphics`, font), copertura 99% (`Tools\Copertura.ps1 -Test War`, 515 righe su 518). **Parita' grafica con il C (#192)**: `Tools\Verifica\192` compila con gcc i `wres_*` ORIGINALI di `war_resources.c` (estratti alla lettera) e `fontsData[]` di `war_font.c`; il golden `Tests\Data\War\graphics.golden.txt` ha 184 righe (14 palette, 57 immagini, 91 sprite, 16 cursori, 3 tiles, 3 tileset, impronta CRC-32 di cio' che decodificano) e `fonts.golden.txt` i 190 glifi: **zero differenze** (vedi `Tools\Verifica\192\LEGGIMI.md`). **Parita' con il C**: `Tools\Verifica\191` compila con gcc (w64devkit) il `wfile_loadWarFile` ORIGINALE (estratto alla lettera da `war_file.c`) e lo fa girare sul `DATA.WAR` vero: i golden `Tests\Data\War\datawar.retail.golden.txt` (come `wg_loadDataFile`: 68 voci saltate), `datawar.retail.noskip.golden.txt` e `catalog.golden.txt` sono la sua uscita; le 583 voci (offset, compresso, lunghezze e CRC-32 dei byte espansi) danno **zero differenze**. I test sui dati veri (`DELPHIDOOM_WAR_DATA` o `Reference\_dati\warcraft`) sono **ignorati**, non verdi, se `DATA.WAR` manca.

## Livelli, campagne, raccordi e griglia (fetta #193)

Dal remake in C: `wres_loadLevelInfo`/`Visual`/`Passable` e le `wres_loadStart*` di `war_resources.c`, `war_campaigns.c`, `war_roads.c`, `war_walls.c`, `war_ruins.c`, `war_trees.c` (parte dei dati: tipi dai vicini, ricerche), le tabelle di `war_units.c` e `war_map_grid.c`.

| C | Delphi |
|---|---|
| `wres_loadLevelInfo` + `wres_loadStart*` | `TWarLevelInfoReader.Read` (`TWarLevelInfo`, `TWarLevelUnit`, `TWarLevelConstruct`) |
| `wres_loadLevelVisual` / `wres_loadLevelPassable` | `TWarLevelMapReader.Read` |
| i tre record di un livello | `IWarLevel` (`TWarLevel`), `IWarLevelLoader` (`TWarLevelLoader`, `TWarLevelFactory.CreateLevelLoader`) |
| `campaignsData[]`, `wcamp_getCampaignData`, `wcamp_tryGetMapType`, `wmap_getCampaignMapTypeByLevelInfoIndex` | `IWarCampaigns` (`TWarCampaigns`, dati generati in `DelphiDoom.War.Campaign.Data`) |
| `wcamp_checkMap01Objectives`, `wcamp_checkMap02Objectives`, `wcamp_checkCustomMapObjectives` | `IWarObjectives` (`TWarObjectives`) su `IWarCensus` |
| `we_add/has/get/remove/determine*` di strade e muri | `TWarLine` (`CreateRoad`, `CreateWall`) |
| `we_*Ruin*` | `TWarRuins` |
| `we_hasTreeAtPosition`, `we_getTreeAtTile`, `we_determineTreeTiles`, `we_validTree` | `TWarForest` |
| `roadTileTypeMap`, `wallTileTypeMap`, `ruinTileTypeMap`, `treeTileTypeMap`, `fogTileTypeMap`, `roadsData`, `wallsData`, `ruinsData`, `treesData` | `DelphiDoom.War.Autotile.Data` (generato) |
| `wgrid_clear`, `wgrid_build`, `wgrid_tileFromMapTile`, `wgrid_getTileIndex` | `TWarMapGrid` |

Difetti del C conservati, differenze volute e non portato: `CLAUDE.md`, sezione "Livelli, campagne, raccordi e griglia". Parita' con il C compilato con gcc: `Tools\Verifica\193\LEGGIMI.md`. 255 test in `Tests\DelphiDoom.Tests.War`.

## Audio (issue #198, prima fetta: effetti e musica fino al PCM e al MIDI)

I suoni e i brani di `DATA.WAR` diventano campioni PCM e file MIDI standard sopra `IWarArchive` e `IWarCatalog` (`IWarAudioLibrary`, `TWarAudioFactory.CreateLibrary`, in `DelphiDoom.War.Audio.Factory`: unit a parte, cosi' chi usa l'archivio e la grafica non ha bisogno di `Libs\Xmi` e `Libs\GameHost`). Cio' che un record suona lo dice il catalogo: i 45 record XMID sono i brani (`WAR_MUSIC_00..44`), i 111 record WAVE e VOC (472..582) sono i suoni; la tabella `audioData` di `war_audio.c` elenca gli stessi record, per questo non c'e' una seconda tabella.

| C | Delphi |
|---|---|
| `mv_read_memory` (`shl/voc.h`, MIT) | `TWarVocDecoder.TryDecode` |
| `mw_read_memory` (`shl/wav.h`, MIT) | `TWarWavDecoder.TryDecode` |
| `mv_resample_pcm`, `mw_resample_pcm` (lo stesso codice due volte) | `TWarPcmResampler.Resample` |
| `wres_loadVoc`, `wres_loadWave` (decodifica e 44100 Hz) | `TWarAudioLibrary.GetSound` (`DelphiDoom.War.Audio.Records`) |
| `wres_loadXmi` e `x2m_transcode` (`shl/xmi2mid.h`, MIT) | `TWarAudioLibrary.GetMusic` con `TWarXmiMusicConverter`, che usa `TXmiConverter` di `Libs\Xmi`: **nessun secondo convertitore XMI** |
| `wa_playWave` | `TWarWaveVoice.Mix` |
| il volume posizionale di `audioDataCallback` (`rect_containsf`, `rect_center`, `vec2_distance`) | `TWarSoundAttenuation` |
| il corpo di `audioDataCallback` (somma delle voci, volume dei suoni, voci finite) e `wa_createAudio*` | `TWarSoundMixer` (`IWarSoundMixer`) |
| il buffer mono di `audioDataCallback` verso l'uscita stereo | `TWarPcmSource` (`IGameHostPcmSource` di `Libs\GameHost`) |
| `MIN_ACK_SOUND_INTERVAL` in `wa_playAcknowledgementSound` | `TWarAcknowledgementThrottle` |

Il remake **non ha un canale dedicato** alle risposte delle unita' (come invece ipotizza l'issue): evita la saturazione con un solo controllo, una risposta ogni 150 ms (`TWarAcknowledgementThrottle`; il tempo e' un parametro, la classe non legge orologi). La scelta a caso tra `WAR_ORC_ACKNOWLEDGEMENT_1..4` e simili e' del gioco (#194): in `DelphiDoom.War.Audio.Types` ci sono gli intervalli.

**Difetti del C conservati**: un suono e' sempre 8 bit senza segno mono a 44100 Hz (il mixer non guarda formato e canali del campione); una voce senza ciclo richiamata dopo la fine ricomincia dal primo campione; la somma satura a ogni voce (l'ordine delle voci conta); `playbackTime` e' un `float` accumulato per blocchi (stessi bit); un VOC con piu' blocchi prende il formato dell'ultimo; la frequenza di un blocco 1 senza blocco 8 e' `1000000 / (256 - divisore)`; i VOC con compressione, i blocchi 9 con formato diverso da 0 e 4 e le somme di controllo sbagliate sono rifiutati; il lettore WAV prende canali, frequenza e bit da offset fissi e accetta qualunque `audio_format`; il ricampionatore usa lo shift aritmetico sui negativi e l'aritmetica a 32 bit che avvolge in `(b - a) * frac`.
**Differenze volute** (ognuna con un test): (1) il ricampionatore generale del C legge **un byte oltre il buffer** quando il passo in 16.16 arrotonda per eccesso (i 4 suoni a 11111 Hz del gioco: 474 e 481-483; l'ultimo campione dipende dallo heap); la libreria usa l'ultimo campione e i golden lasciano fuori quel byte; (2) un campione con canali 0 o bit non 8/16 e' `EWarException` al ricampionamento (il C divideva per zero o lasciava l'uscita non scritta), come un campione senza dati o una frequenza di destinazione 0 (dove il C ritorna 0); (3) un suono senza campioni in ciclo e' finito subito (il C non esce piu' dal `do ... while`); (4) il volume fuori dalla vista e' `0.75 * (1 - (d - 120) / 80)` come nel C ma e' un **fattore** del volume dei suoni: nel C non lo scala, quindi un suono lontano si sentirebbe anche con i suoni spenti (a volume 1 e' identico, bit per bit); (5) le voci finite le toglie il mixer stesso (il C le passa al thread principale con un mutex), `Mix` somma nel buffer e non lo azzera (lo fa `TWarPcmSource`); (6) **la musica non e' identica byte per byte**: vedi sotto.

**La musica**. `x2m_transcode` e `TXmiConverter` non danno gli stessi byte e non possono (il remake scrive un MIDI di tipo 0 con divisione dal tempo e i ritardi moltiplicati per 3; `TXmiConverter` un tipo 2 con divisione 60, i nomi degli strumenti come testo e i cambi di tempo applicati). Cio' che e' provato sui 45 brani di `DATA.WAR` (golden `audio.records.golden.txt`, `midiSummary` del harness contro `TWarMidiSummary` del test): **stesso numero di Note On** e, in 31 brani su 45, **lo stesso multiinsieme di tutti gli eventi di canale che non sono Note Off** (CRC-32 delle chiavi stato/dato1/dato2 ordinate); negli altri 14 la libreria scrive **un solo controller in piu'** del C; i Note Off sono uno per ogni Note On (nel C, in 14 brani, mancano quelli dopo l'evento di fine traccia: **difetto del C corretto**, le note restano accese); l'istante dell'ultimo Note On coincide entro il 5% (il C tiene il primo tempo, scarta i successivi e tronca la divisione dell'intestazione; `TXmiConverter` segue i cambi). **L'ascolto non e' stato fatto.**
**Non portato**: la riproduzione della musica (`wa_playMidi`, `wa_initAudio`, TinySoundFont con `GMGeneric.SF2`): serve un sintetizzatore di MIDI e un SoundFont; **la licenza di `GMGeneric.SF2` non e' dichiarata** nel repository del remake (ne' il README ne' LICENSE ne parlano) e non si include; alternative da valutare: `Libs\Opl`, un SoundFont con licenza chiara, il MIDI di sistema con `Libs\Midi`; il volume della musica e la dissolvenza; la dissolvenza al cambio scena (il C azzera l'audio fino a `transitionEndRealTime`: e' `SetSilenced`; la dissolvenza grafica e' del rendering, #197); la scelta a caso dei suoni, `wa_playDudeSelectionSound` e simili (dipendono dalle entita', #194); il collegamento a un programma (`Warcraft32`, #200: `TWarPcmSource` va aperto con `IGameHostPcmOutput.Open(WAR_PLAYBACK_RATE, ...)`).

**Verifica**: `Tools\Verifica\198` (`Compila-AudioRef.ps1`, `war_audio_ref.c`, `war_synth_cases.inc`) compila con gcc il codice ORIGINALE (`wres_loadXmi/Wave/Voc`, `wa_playWave`, il volume posizionale, con `voc.h`, `wav.h`, `xmi2mid.h`). Golden in `Tests\Data\War`: `audio.synth.golden.txt` (57 casi sintetici di VOC e WAV, **senza `DATA.WAR`**: il test ricostruisce gli input dalla specifica scritta nella riga), `audio.mixer.golden.txt` (9 scenari, 22 chiamate: ritorno, `sampleIndex`, bit di `playbackTime`, CRC-32 dell'uscita), `audio.position.golden.txt` (60 volumi, bit per bit), `audio.records.golden.txt` (111 suoni e 45 brani del `DATA.WAR` vero). Zero differenze sui suoni, sul ricampionatore, sul mixer e sul volume; sui brani l'equivalenza descritta sopra.

## Musica, scelta dei suoni e filmati (issue #198 seconda fetta, #199, #194 in parte)

**Musica** (`DelphiDoom.War.Music.*`). Il remake suona un brano con TinySoundFont e un SoundFont (`wa_playMidi`); qui **il sintetizzatore non si porta** (la licenza di `GMGeneric.SF2` non e' dichiarata): resta l'interfaccia `IWarMusicSynth` (le chiamate `tsf_*` che `wa_playMidi` fa: cambio di programma, nota, pitch bend, controller, `tsf_note_off_all`, `tsf_render_short`), un finto che scrive le chiamate nei test e `TWarSilentMusicSynth` (non aggiunge nulla ai campioni) per far girare il resto finche' non si sceglie un sintetizzatore.

| C | Delphi |
|---|---|
| i tempi in millisecondi di `tml_load` (`tml.h`, zlib) | `TWarMusicTimeline` (`IWarMusicTimeline`) sopra `IMidiStreamSequencer` di `Libs\Midi`: stessa formula (`tempo_msec + (int)((ticks - tempo_ticks) * ticks2time)`, `double`, troncata) |
| `wa_playMidi` (blocchi da 64, `playbackTime` `float`, eventi dovuti prima del blocco, velocita' per il volume, giro) | `TWarMusicPlayer` (`IWarMusicPlayer`: `Play`, `Stop`, `SetVolume`, `SetSilenced`, `Mix`) |
| la parte musica di `audioDataCallback` (volume, `musicEnabled`, scena che cambia) | `SetVolume`, `SetSilenced` |
| — (non c'e' nel remake) | `TWarMusicFade` (dissolvenza lineare in campioni, 16.16): `Play(..., AFadeInMs)`, `Stop(AFadeOutMs)` |
| il buffer dell'uscita | `TWarPcmSource.Create(AMixer, AMusic)`: prima la musica, poi gli effetti (in una mappa la musica e' la prima entita' audio) |
| — | `TWarMusicFactory` (unit a parte: chi la usa elenca anche `Libs\Midi`, `Libs\M2m`, `Libs\Logging`) |

Conservato dal C (e provato dai golden): blocchi da 64 campioni e tempo `Single` (`1000.0f / 44100` per blocco), gli eventi dovuti scattano **prima** di rendere il blocco, il volume scala la velocita' delle note che **iniziano** (una nota gia' iniziata non cambia), a volume 0 o con la musica spenta il brano **non avanza**, il giro ricomincia **subito dopo l'ultimo evento** tenendo il tempo che e' passato oltre (`playbackTime -= prevMessage->time`), il brano e' "finito" nella chiamata in cui scatta l'ultimo evento (il resto della chiamata si rende), gli eventi che `wa_playMidi` non suona (pressione, tempo) contano come ultimo messaggio del brano. **Parita'**: `Tools\Verifica\198\Compila-MusicRef.ps1` compila `wa_playMidi` e `tml.h` ORIGINALI con uno stub di `tsf_*` che scrive le chiamate: 12 canzoni (semi fissi, 1-3 tracce, eventi di ogni tipo, cambi di tempo, 4 giri), chiamate di 441, 1000, 64, 8192, 37 e 4410 campioni a ripetizione; il test (`MusicParity`) fa le stesse chiamate con il sequencer vero e dice **842 righe su 842 uguali**: stesso campione del blocco, stessa velocita' in bit.

**Difetti del C non conservati** (ognuno con un test, e gli scenari dei golden li evitano): (1) **`tml_load` perde messaggi** se il primo evento del file non e' della traccia 0 (scambia il suo primo messaggio con quello, ancora da leggere, della traccia 0): qui la fusione e' giusta (`MusicTimeline.DovrebbeFondereLeTracceAncheSeIlPrimoEventoEDellaSeconda`); (2) **un brano con `EndOfTrack` a delta 0 non si ripete mai** (il messaggio non e' nella lista, `currentMessage` diventa `NULL` e `wa_playMidi` tace per sempre) e con piu' tracce il primo `EndOfTrack` ferma il giro: qui il giro riparte dopo l'ultimo evento; (3) le voci ancora in suono quando un brano finisce restano nel sintetizzatore e ricompaiono col brano dopo: qui `AllNotesOff` alla fine; (4) un giro senza lunghezza (un solo evento a tempo 0) non esce mai dal blocco: qui si ferma dopo 64 ripartenze nello stesso blocco; (5) `tsf_note_off_all` a ogni callback mentre la scena cambia: una volta sola. **Non uguale**: gli eventi sysex e meta sconosciuti non arrivano dal sequencer di `Libs\Midi`, quindi il loro tempo conta nel delta del successivo ma non come "ultimo messaggio" del giro (cambia la lunghezza del giro solo se uno di loro e' l'ultimo). La **dissolvenza** (`TWarMusicFade`) non c'e' nel remake (silenzia la musica mentre la scena cambia): e' una scelta del port, sul volume in uscita (non tocca la velocita' delle note); `Stop(ms)` poi ferma; `Play` mentre suona sostituisce subito (chi vuole una dissolvenza incrociata fa `Stop(ms)` e poi `Play`).

**Scelta dei suoni** (`DelphiDoom.War.Sound.*`, #194 prima parte). `wa_playAttackSound`, `wa_playDudeSelectionSound`, `wa_playBuildingSelectionSound` e `wa_playAcknowledgementSound` diventano `TWarSoundPicker` (`IWarSoundPicker`: `AttackSound`, `DudeSelectionSound`, `BuildingSelectionSound`, `Pick(evento, razza)`, `DeathSound`, `BriefingSound`) sopra `TWarSoundTable` (`IWarSoundTable`: per ogni `TWarSoundEvent` e razza un suono fisso o un intervallo da cui si sceglie a caso, `randomi(a, b) = a + SDL_rand(b - a)`) e `IWarRandom.Below(n)` (il generatore e' **iniettato**: `TScriptedRandom` nei test, `TWarSeededRandom` — congruenziale con stato proprio, stesso seme stessi numeri a 32 e 64 bit — nel gioco; **non e' `SDL_rand`**, che non ha un seme riproducibile). Il picker restituisce l'indice del record (`WAR_SND_*` in `DelphiDoom.War.Sound.Ids`) o `WAR_SND_NONE`; chi suona lo da' a `IWarSoundMixer.Play` / `PlayAt`; l'intervallo tra due risposte resta di `TWarAcknowledgementThrottle`. **Parita'**: `Compila-SoundRef.ps1` compila le quattro funzioni `wa_play*Sound` ORIGINALI con stub di `wa_createAudio*` che scrivono la richiesta (un suono o un intervallo) e le fa girare su ogni ingresso (11 passi, 4 selezioni, 3 stati x 10 vite x 16 edifici, 2 risposte: **497 righe**); il test le rifa con un generatore che risponde sempre 0 e controlla suono e limite chiesto. Gli intervalli di **tutte** le chiamate del sorgente (non solo quelle di `war_audio.c`: collasso, abbattere alberi) li prende lo script dal testo (`randomFromId`/`randomToId` in ogni `src\*.c`, 9 coppie) e il test controlla che la tabella le abbia tutte. **Non verificato sul C**: i suoni *fissi* delle chiamate sparse nel sorgente (morte di una unita', lavoro finito, unita' pronta, incantesimo, strada) sono letti a mano (test di unita'); la vittoria e la sconfitta del giocatore non sono suonate dal remake (gli id ci sono, nessuna chiamata): `wseVictory` (un intervallo di 3 per razza) e `wseDefeat` sono una scelta del port, e per questo `RandomRanges` ha due intervalli piu' dei 9 del remake.

**Filmati** (`DelphiDoom.War.Cinematic.*` in `Libs\War`, la scena in `Libs\Cinematic`, #199). `TWarCinematicCatalog` ha le 39 animazioni di `cinematics.txt` (nome, ciclo: `CAVE2`, `HINTRO2`, `LOSE2`, `OFINALE`, `OINTRO2`, `WIN2` dicono "Loop") e la voce che le accompagna; `TWarCinematicDirector.TryOpen(nome, razza del giocatore)` da' la scena (`IFlicScene`, vedi `Libs\Cinematic`) con la voce (`TWarCinematicAudio`: parte con la scena, **si ferma se la scena e' saltata**, finisce da sola se la scena finisce) o `nil` se il gioco non ha quell'animazione o il file non c'e' (**HMAP01-12, OMAP01-12, LOSE1 e WIN1 mancano dal disco fornito: si saltano**, provato sui file veri: 13 su 39 ci sono). **L'abbinamento animazione-voce e' una scelta del port, non un fatto dell'originale** (il remake non suona nessun filmato): e' dato solo dove il nome non lascia dubbi (`CAVE3` "la porta si apre" -> `WAR_INTRO_DOOR`, `TITLE` -> `WAR_INTRO_5` "Welcome to the World of Warcraft", `HFINALE`/`OFINALE` -> i finali della razza, `WIN`/`LOSE` -> vittoria e sconfitta della razza del giocatore); le altre quattro narrazioni dell'introduzione (`WAR_INTRO_1..4`) e i filmati delle mappe restano senza voce finche' qualcuno non ascolta il gioco DOS. Il director dipende da `IFlicSceneMaker`, non dai file: un finto nei test, `TFlicSceneFactory.CreateMaker(CreateFolderSource(cartella, '.WAR'))` nel gioco; un `.dpr` che usa il director elenca anche le unit di `Libs\Cinematic`, `Libs\Flic` e `Libs\Imaging` (vedi `Tests\DelphiDoom.Tests.War.dpr`).

**Non fatto**: ascolto (nessuna delle tre parti e' stata sentita) e visione; il sintetizzatore e il SoundFont; la sequenza delle introduzioni (`CAVE1 -> CAVE2` in ciclo, ...) e il collegamento al gestore di scena di `Warcraft32` (#200); le modalita' di presentazione a 8 bit con palette; la misura delle prestazioni del mixer contro il remake (vedi `docs\PARITA_WAR.md`).
## Mappa di gioco (fetta #193, seconda)

Il livello diventa la mappa di una partita: `TWarMapBuilder.Build(livello, pixel del tileset)` da' un `TWarGameMap`. Dal C: `war_map.c` (`wmap_enterMap`, `updateFoW`, `determineFoWTypes`, le funzioni di stato delle tegole, `wmap_getMapTileAverage`, `wmap_updateMinimapTile`), `renderMinimap` di `war_entities.c`, `we_createUnit`, `war_trees.c` e le funzioni della griglia di `war_pathfinder.c`.

| C | Delphi |
|---|---|
| `wmap_enterMap` (i dati) | `TWarMapBuilder.Build`, `TWarGameMap` |
| `wpath_initPathFinder`, `wpath_setStaticEntity`, `wpath_isEmpty`, `wpath_isTileAccesible`... | `TWarPathGrid` |
| `setInitialTileState`, `wmap_setMapTileState`, `wmap_is*TileIn*`, `determineFoWTypes` | `TWarFogOfWar` |
| `updateFoW` | `TWarFogUpdater` |
| `createForestEntities`, `we_determineTreeTiles`, `we_plantTree`, `we_chopTree`, `we_takeTreeDown`, `we_findAccesibleTree`, `we_validTree` | `TWarMapForests`, `TWarMapForest` |
| `wmap_getMapTileAverage`, `wmap_updateMinimapTile`, il ciclo di `renderMinimap`, `wu_getUnitColorOnMinimap` | `TWarMinimap` (immagine RGBA 64 x 64 a byte) |
| `wmap_getMapTileIndex`, `wmap_setMapTileIndex` | `TWarMapTilePainter` (`IWarTilePainter`) |
| `we_createUnit`, `wu_is*UnitType`, `wu_getUnitSightRange`, `unitsData`/`unitStats`/`buildingStats` | `TWarUnitCatalog` (`IWarUnitCatalog`), `DelphiDoom.War.Map.UnitData` (generata) |

Difetti del C conservati, differenze volute e non portato: `CLAUDE.md`, sezione "Mappa di gioco". Parita' con il C compilato con gcc: `Tools\Verifica\193\LEGGIMI.md` (65 livelli, 60 scenari di alberi, zero differenze).

## Testo, disegno e sprite (fetta #192, seconda)

| C | Delphi |
|---|---|
| `getCharIndex`, `wfont_getAlignmentOffset`, `wfont_getLineAlignmentOffset`, `wfont_splitTextIntoLines`, `wfont_measureSingleSpriteText`, `wfont_measureMultiSpriteText` | `TWarTextLayout` |
| `wfont_renderSingleSpriteText`, `wfont_renderMultiSpriteText`, `wfont_renderSingleSpriteTextSpan` | `TWarTextRenderer` |
| `wr_save`, `wr_restore`, `wr_translate`, `wr_scale`, `wr_globalAlpha`, `wr_subImage` | `TWarRenderTransform` (aggiunge un `TWarBlit` a una lista) |
| `SDL_RenderTexture(Rotated)` sulla texture (nearest, colore, alfa, blend) | `TWarImageBlitter` (pixel RGBA a byte) |
| `wspr_createSprite`, `wspr_createSpriteFromFrames`, `wspr_createSpriteFromResource`, `wspr_getSpriteFrame`, `wspr_renderSprite`, `wspr_renderSubSprite` | `TWarSpriteSheet` |

Il PNG dei font non e' nel `DATA.WAR`: il chiamante da' a `TWarImageBlitter` l'immagine (`TWarImage`). Il remake non ha un colore per fazione: nessuno e' inventato. Parita': `Tools\Verifica\192\LEGGIMI.md` (240 testi a bit, 164 record grafici, zero differenze).

## Modello di gioco (issue #194, prima fetta)

`DelphiDoom.War.Model.*`, una classe per unit (tipi in `Model.Types`, `Model.State.Types`, `Model.Stats.Types`; contratti in `Model.Intf`;
`Model.Factory` e' l'unico posto che conosce le classi concrete). E' il modello delle entita' e delle unita' del remake (`war_entities.c`,
`war_state_machine*.c`, parte di `war_units.c`, `war_actions.c` e `war_math.c`) **senza** finestra, grafica, audio, percorsi ne' interfaccia.

**Mappa nome C -> classe**

| C | Delphi |
|---|---|
| `WarEntityManager` (pool, id, liste per tipo, `we_createEntity`, `we_findEntity`) | `TWarEntityPool` |
| `we_createUnit`, `we_createDude`, `we_createBuilding`, `we_setInitialIdleState`, `we_removeEntity(ById)` | `TWarEntityManager` (`IWarEntityManager`) |
| `WarStateStorage`, `wst_allocState`, `wst_releaseStateRef`, `wst_deref`, `wst_refOf` | `TWarStateStorage` (+ `TWarStateRefs`) |
| `wst_*` (pila di stati, transizioni differite, `wst_processPendingTransitions`, `stateDescriptors`) | `TWarStateMachine` (registro: `RegisterHooks`) |
| `wst_*IdleState`, `wst_*MoveState`, `wst_*DeathState`, `wst_*WaitState` | `TWarIdleState`, `TWarMoveState`, `TWarDeathState`, `TWarWaitState` |
| `unitStats`, `buildingStats`, `upgradeStats`, `spellStats`, `spellMappings`, `wu_get*Stats` | `TWarDatabase` (`IWarDatabase`) con `Model.StatData` **generata** da `Tools\Verifica\194\Make-WarModelTables.ps1` |
| `wu_is*UnitType`, `wu_getUnitTypeRace`, `wu_getUnitTypeForRace` | `TWarUnitClassifier` (funzioni statiche su insiemi) |
| `gUnitActionDefs` (presenza e durata in fotogrammi), `wact_setAction`, `wact_addUnitActions` | `TWarActionTable` + `Model.ActionData` **generata** |
| `wu_getUnit*Position/Tile/Center`, `wu_setUnitCenterPosition`, `wu_tileInRange` | `TWarUnitGeometry` |
| `we_getNearEnemy`, `we_getAttacker`, `wu_areEnemies`, `wu_canAttack`, `wu_getNumber*` | `TWarUnitQueries` (`IWarUnitQueries`) |
| `we_increase/decreaseUnitHp/Mana`, `we_getTotalDamage`, `we_takeDamage` | `TWarCombat` |
| `we_*PlayerResources`, `we_enoughFarmFood`, `we_checkFarmFood`, `we_increaseUpgradeLevel` | `TWarEconomy` |
| `vec2_*`, `wmap_mapToTileCoordinatesV`, `wmap_getMapScaledTime`, `wu_getDirectionFromDiff` | `TWarModelMath` |
| `wrvo_computeNewVelocity` (senza vicini) | `TWarStraightSteering` |
| `WarContext` e le parti di `WarMap` che servono (giocatori, tempo) | `TWarModelContext` (nessun globale); `TWarModelWorld` e' il modello intero (`AdvanceClock`, `Update`) |

**Il registro degli stati** e' una tabella di descrittori (come `Libs\Specials`): per ogni tipo di stato una procedura di ingresso, una di uscita
e una di aggiornamento **dell'intero tipo** (il ciclo sugli stati e' dentro la procedura): la tabella si attraversa una volta per tipo e per
tic, mai per unita'. Le procedure sono `class procedure ... static` (procedure semplici, non metodi virtuali ne' interfacce). Il ciclo di
`TWarMoveState` fa le sette passate del C. Gli stati non portati hanno il loro record e la maschera di interruzione del C, ma nessuna procedura:
si creano e restano dove sono. Lo storage degli stati (512 per tipo, generazioni, lista dei liberi LIFO) e l'ordine degli slot delle entita'
sono quelli del C: l'ordine degli aggiornamenti, e quindi dei numeri casuali, dipende da questo.

**Cosa e' portato**: enumerazioni; database statistico (28 unita', 19 edifici, 19 miglioramenti, 12 incantesimi, durata delle azioni per tipo); modello
delle entita' (trasformazione, componente unita', macchina a stati; gli altri componenti del C sono grafica e interfaccia); pool con id; creazione
e rimozione; macchina a stati completa (push, pop, replace, reset, richieste differite con causa e annullamento degli acquisti, maschere di
interruzione, `TearDown`); stati idle (guardarsi intorno, guerrieri che attaccano il nemico entro 5 caselle), move (in linea retta, avanzamento,
rallentamento all'arrivo, progresso e rinuncia dopo 3 s, attacco subito con `checkForAttacks`), death (corpo della razza, rimozione), wait;
economia (oro, legna, cibo, miglioramenti); danni e vita (`we_takeDamage`); generatore casuale iniettato (`IWarRandom`, `TWarSeededRandom`).

**Non portato (resta della #194)**: vedi "Resta" in `Libs\War\CLAUDE.md` (attacco, raccolta, incantesimi, pattuglia, inseguimento, consegna, il resto di `war_commands.c`,
`war_projectiles.c`). Costruzione, riparazione, crollo, addestramento, miglioramenti, passi delle azioni e muri come entita' sono nella seconda fetta (sezione piu' sotto).
**Percorsi e collisioni** sono la #195: senza un `IWarMovementSteering` una unita' va dritta al prossimo punto (il C su un campo libero fa lo stesso: campo di flusso nullo e
nessun vicino). La proprieta' `Steering` del contesto c'e' ma nessuno la usa ancora.

**Difetti del C conservati** (servono per avere gli stessi dati): (1) `wst_exitWaitState` libera le caselle solo se la pila e' vuota, ma quando un'uscita avviene la pila non lo e' mai: un'attesa non libera mai le caselle; (2) un corpo colpito di nuovo (con 0 punti ferita) rifa lo stato di morte e il conto riparte; (3) `we_decreasePlayerResources` controlla l'oro prima della legna e da' il messaggio del primo che manca; (4) i miglioramenti a coppie (frecce/lance, spade/asce, cavalli/lupi) condividono un livello (`upgrades[upgrade / 2]`); (5) `wst_enterIdleState` occupa le caselle e il suo `exit` le libera, ma un `Wait` che finisce non le riprende ne' le libera: un'unita' che ha aspettato puo' restare senza caselle occupate; (6) `wst_updateMoveStates` non guarda piu' le unita' che non sono `WAR_ENTITY_UNIT` (solo le unita' si muovono).
**Il C compilato con gcc ha un'enum senza segno**: `unit->direction += randomi(-1, 2)` da NORD con -1 da' un numero enorme, `< 0` e' falso e la direzione diventa NORD, non NORD-OVEST come con
MSVC (dove l'enum ha il segno). `TWarModelContext.UnsignedDirections` sceglie: **False (predefinito)** e' il comportamento voluto (NORD-OVEST), **True** riproduce il golden (fatto con gcc); i test di parita'
lo accendono, un test per ciascun comportamento.

**Differenze volute** (ognuna con un test): gli id sono a 16 bit come nel C ma **saltano 0 e gli id in uso** (il C, dopo 65535 entita', darebbe 0 -- che significa "slot libero" -- e id gia' presi); un tipo di unita' senza misura
o senza statistiche e' `EWarException` **prima** di creare l'entita' (il C la crea e poi si ferma su un `assert`); `we_increaseUpgradeLevel` oltre il massimo e' `EWarException` (il C: `assert`);
il livello di velocita' oltre 2 vale 2 (il C leggerebbe fuori da `speeds[3]`); una unita' senza statistiche di velocita' (WOUNDED) ha velocita' 0; la ricerca di un'entita' per id usa una tabella
(il C scorre le 1024 entita': lo stesso risultato, 5-9 volte piu' veloce); i componenti stanno nello slot dell'entita' invece che in array densi (non cambia l'ordine di nulla); i campi di
debug dell'RVO (candidati e collisioni) non ci sono; un `PUSH` su una pila vuota non legge `stack[-1]`; i messaggi della barra di stato, l'audio e le animazioni dei danni sono eventi
(`IWarModelEvents`) invece di chiamate.

**Parita'**: `Tools\Verifica\194` (`Compila-ModelRef.ps1`, `war_model_ref.c`, `Make-WarModelTables.ps1`): il modello ORIGINALE del remake compilato **come e'** (unity build: i `.c` di `war_entities`, `war_units`,
`war_actions`, `war_math`, `war_pathfinder`, `war_rvo`, `war_map` e di tutti gli stati sono inclusi interi, niente estratti) con gcc. Stub dichiarati nell'intestazione del programma: SDL (`SDL_rand` e' un LCG con seme,
lo stesso di `TWarSeededRandom`), la grafica (lo sprite di una unita' non e' stato), l'audio, l'interfaccia, e -- da rinominare con `#define` prima di includere il loro file -- le tre funzioni del campo di flusso e `wrvo_gatherNeighbours`
(nessun ostacolo, nessun vicino): e' quello che il Delphi fa. Il codice non raggiunto resta nel programma e ha un corpo che lo ferma (non una risposta sbagliata in silenzio). Golden: `model.tables.golden.txt` (statistiche, classificazione,
durata delle azioni, tempo scalato), `model.friendly.golden.txt` (20 scenari di 300 tic: unita' del giocatore 0 che si muovono, si guardano intorno, aspettano, muoiono, vengono curate, tolte, create; spese, cibo, miglioramenti),
`model.hostile.golden.txt` (16 scenari con due schieramenti, fino al primo ordine di attacco, che il modello non porta oltre), `model.dump.golden.txt` (il testo dello stato di un tic). L'impronta di ogni tic e' l'FNV-1a del testo di
tutto lo stato (entita', componenti, pile di stati e richieste in attesa, storage, griglia di occupazione, estrazioni casuali) con i float **a bit**: **zero differenze** a Win32 e a Win64. Test: `DelphiDoom.Tests.War.ModelParity` (9) e, per classe,
`ModelMath`, `ModelSteering`, `ModelTables`, `ModelStorage`, `ModelMachine`, `ModelIdle`, `ModelMove`, `ModelCombat`, `ModelEconomy`, `ModelEntities` (171 test nuovi in tutto, 9 di parita'); copertura delle 22 unit con codice 96% (1590 righe su 1649; la peggiore, `StateStorage`, 89%: i rami che
difendono da contatori corrotti). Prestazioni: 400 unita' che marciano, 1500 tic: Delphi 0,19 us per unita' e tic a Win32 (0,34 a Win64) contro 1,7 us del C a `-O1` (`war_model_ref bench`).
## Attacco, proiettili, inseguire e pattugliare (issue #194, seconda fetta)

Mappa nome C -> classe (`DelphiDoom.War.Model.*`, una classe per unit):

| C | Pascal |
|---|---|
| `wst_updateAttackStates` (`war_state_machine_attack.c`) | `TWarAttackState.UpdateAll` (`State.Attack`) |
| `wst_updateFollowStates` | `TWarFollowState.UpdateAll` (`State.Follow`) |
| `wst_enterPatrolState`, `wst_updatePatrolStates` | `TWarPatrolState.Enter`, `.UpdateAll` (`State.Patrol`) |
| `wst_createFollowState`, `wst_createPatrolState` | `TWarStateMachine.CreateFollow`, `.CreatePatrol` |
| `we_meleeAttack`, `we_rangeAttack` | `TWarAttacks.Melee`, `.Range` (`Attacks`) |
| `wproj_*` (`war_projectiles.c`) | `TWarProjectiles` (`Projectiles`): `Launch` (= `wproj_createProjectile`), `UpdateAll` (= `updateProjectiles`), sprite, impatto, danno a zona |
| `wgrid_build`, `we_getNearUnits` | `TWarNearUnits` (`NearUnits`, sopra `TWarMapGrid`) |
| `wact_updateAction` | `TWarActionRunner.Update` (`ActionRunner`), passi in `ActionSteps.Data` (**generata** da `Tools\Verifica\194\Make-WarActionSteps.ps1`) |
| `rect_closestPointOnRect`, `wu_unitPointOnTarget`, `wu_unitTileOnTarget`, `wu_unitInRange` | `TWarTargetGeometry` |

Composizione: `TWarAttackRegistration.Register` (`State.Attack.Registration`, una riga in `TWarModelFactory`) registra i tre stati e crea `TWarCombatServices` (`IWarCombatServices`, `Combat.Intf`), che tiene `TWarCombat` (una sua copia), la griglia, i colpi e i proiettili e fa "il resto del tic" di `wmap_updateMap` dopo gli stati: `TWarModelWorld.UpdateAfterStates` (griglia, passi delle azioni di tutte le unita', proiettili). **`Update` non e' cambiato** (le prove della prima fetta restano com'erano): il gioco chiama `Update` e poi `UpdateAfterStates`. Suoni ed esplosioni vanno a `IWarCombatEvents` (opzionale: lo stesso oggetto di `IWarModelEvents` se lo implementa, o `Context.CombatEvents`). Gli stati usano `Context.Combat` una volta per colpo, mai per unita' e per tic.
**Non portato**: l'attacco ai muri (`we_*WallAttack`, `wproj_doProjectileTargetDamage` su un muro, il danno a zona sui pezzi di muro: i muri non sono entita' del modello), `wanim_updateAnimations` e la rigenerazione del mana (`updateMagic`), le animazioni di danno degli edifici (restano gli eventi della prima fetta), i comandi che creano questi stati (`war_commands.c`), il cast (la pioggia di fuoco si crea con `IWarCombatServices.CreateProjectile`).
**Difetti del C conservati** (servono per avere gli stessi dati): (1) la lista dei proiettili si scorre mentre quello arrivato si toglie: il successivo salta un tic; (2) le esplosioni (catapulta, pioggia di fuoco) creano un'entita' animazione che nessuno toglie mai (a 1023 il pool e' pieno; il C si schianta con un puntatore nullo, qui `Launch` da' 0 e non c'e' proiettile); (3) il danno a zona della catapulta usa `wu_canAttack`, che non guarda chi e' il nemico: colpisce anche le unita' proprie e la catapulta stessa se e' vicina; (4) un proiettile che arriva su un bersaglio gia' morto fa `we_takeDamage` con 0 punti ferita: ricrea lo stato di morte e ne azzera il tempo; (5) lo stato attack legge l'azione **corrente** dell'unita' (non quella di attacco): un'unita' senza azione di attacco non colpisce mai; con nessuna azione corrente il C legge prima dell'array (qui: nessun colpo); (6) il colpo di un incantatore che resta senza mana rimette l'unita' in idle, che vede subito lo stesso nemico e riattacca: un ciclo ogni secondo senza tirare; (7) `unit->range` e `stats->range` coincidono (la statistica e' copiata alla creazione e mai cambiata), qui si legge la prima; (8) un colpo ha il 20% di mancare (tranne la catapulta) e consuma un numero casuale solo se non e' una catapulta.
**Differenze volute** (ognuna con un test): `Launch` con il pool pieno da' 0 (il C usa un puntatore nullo); una frazione non definita nel calcolo del frame (distanza totale 0, coseno oltre 1 per l'arrotondamento) non solleva eccezioni: nessun fotogramma trovato, come con i NaN del C.
**Parita'** (`Tools\Verifica\194`, gruppo `194 attacco` di `Tools\Verifica\201`): lo stesso C come unity build, ora con anche `war_projectiles.c` e lo stub di `wa_playAttackSound`; `war_model_ref actions` (i passi di tutte le 378 azioni: `model.steps.golden.txt`), `war_model_ref combat 16` (16 scenari da 600 tic: due schieramenti vicini, ordini di attacco, inseguimento, pattuglia, spostamento, danni, rimozioni, nuove unita', piogge di fuoco e altri proiettili; il tic e' quello di `wmap_updateMap` con griglia, azioni e proiettili; impronta FNV-1a del testo di tutto lo stato per tic con in piu' i passi delle azioni, `lastAttackSoundGameTime` e il proiettile: `model.combat.golden.txt`, 9600 righe) e `dump combat 3 200` (`model.combat.dump.golden.txt`). **Zero differenze** a Win32 e a Win64. Copertura sul C dei 16 scenari (`combatstats`): frecce, pietre di catapulta, palle di fuoco 1 e 2, magia dell'acqua, piogge di fuoco, morti, esplosioni; tutti gli stati. Gli scenari e il testo sono scritti due volte (`war_model_ref.c` e `Tests\Source\DelphiDoom.Tests.War.CombatScenario.pas`, `ModelDump.pas`). I golden della prima fetta sono **invariati** (rifatti con l'harness nuovo: stesso contenuto).
**Test**: `DelphiDoom.Tests.War.CombatParity` (3), `ModelAttack` (60: stato attack, tiri, proiettili, inseguire, pattugliare, passi delle azioni, geometria del bersaglio, unita' vicine). Copertura delle 10 unit nuove 91-100%.

## Raccolta (issue #194, seconda fetta)

Gli stati `gather_gold`, `mining`, `gather_wood`, `chopping`, `deliver` e quello che serve loro, in `Libs\War\DelphiDoom.War.Model.*`; registrati con **una riga** in `TWarModelFactory` (`TWarGatherRegistry.RegisterAll`).

| C (`war1`) | Delphi |
|---|---|
| `wst_createGatherGoldState` / `MiningState` / `GatherWoodState` / `ChoppingState` / `DeliverState` | `TWarGatherStateFactory.NewGold/NewMining/NewWood/NewChopping/NewDeliver` (`State.GatherFactory`: i cinque stati si creano a vicenda, la creazione sta in un posto solo), `ReplaceWithIdle` (le tre righe che tutti ripetono) |
| `war_state_machine_gather_gold.c` | `TWarGatherGoldState` (`State.GatherGold`) |
| `war_state_machine_mining.c` | `TWarMiningState` (`State.Mining`: ingresso, uscita, aggiornamento) |
| `war_state_machine_gather_wood.c` | `TWarGatherWoodState` (`State.GatherWood`) |
| `war_state_machine_chopping.c` | `TWarChoppingState` (`State.Chopping`) |
| `war_state_machine_deliver.c` | `TWarDeliverState` (`State.Deliver`) |
| `wst_createFollowState` | `TWarStateMachine.CreateFollow` (lo stato vero, vedi attacco) |
| `mine` | `TWarMine.Take` (`Mine`: toglie l'oro, a zero fa partire **una volta** il crollo con la sua causa di ciclo di vita e il suono) |
| `we_findClosestUnitOfType`, `wu_getTownHallOfRace` | `TWarUnitSearch.FindClosestOfType`, `TownHallOfRace` (`UnitSearch`) |
| `rect_closestPointOnRect`, `wu_unitTileOnTarget`, `wu_unitPointOnTarget`, `wu_unitDistanceInTiles`, `wu_unitInRange`, `wu_setUnitCenterTile` | `TWarTargetGeometry` (`TargetGeometry`, la stessa dell'attacco e della costruzione) |
| `wpath_findEmptyTile` | `TWarPathGrid.FindEmptyTile` (stessa visita in ampiezza, stesso ordine) |
| `we_getTreeAtTile`, `we_findAccesibleTree`, `we_chopTree`, `we_takeTreeDown`, `we_determineTreeTiles` | **gia' fatti** in `Map.Forests`/`Map.Forest` (#193): i raccoglitori li chiamano, nessuna copia |
| `wact_updateAction`, `wact_resetAction` | `TWarActionRunner.Update`, `Reset` (`ActionRunner`): l'unico esecutore dei passi di tutte le azioni |
| `we_increasePlayerResources` | `TWarPurse.Increase` (`IncreaseResources` della economia la chiama) |
| `we_addSpriteComponentFromResource`, `we_removeSpriteComponent`, `we_disableComponent(COMP_SPRITE)` | `TWarUnitSprites` (`UnitSprites`): l'immagine che l'entita' mostra e se e' disegnata sono **nell'entita'** (`HasSprite`, `SpriteResource`, `SpriteEnabled`, `SpriteFrame`, `ScaleX` negativo = specchiata), gli stessi campi che usano la costruzione e i passi dei frame |

**Cosa il gioco deve dare**: `TWarModelContext.Gather` (un `TWarGatherWorld`: la griglia di occupazione, le foreste e un `IWarGatherEvents` per il colpo d'ascia) e, se la raccolta deve girare, nulla altro; senza `Gather` gli stati sollevano `EWarException` (`SWarModelNotRegistered`) invece di fermarsi su un puntatore nullo. Il crollo della miniera usa `IWarModelEvents.BuildingCollapsing` (la stessa del crollo per i danni). Le foreste del modello sono entita' del pool (`WAR_ENTITY_FOREST`) con lo stesso id della foresta di `Map.Forests`: un'entita' rimossa vuol dire "la foresta non esiste". Chi disegna legge `UnitData.SpriteResource` (0 = nessuno sprite), `SpriteEnabled`, `SpriteFrame` e `Mirrored` invece di un componente sprite.
**Le immagini dei trasportatori** (`DelphiDoom.War.Model.WorkerSprites.Data`, **generato** da `Tools\Verifica\194\Make-WarGatherTables.ps1` dal golden `gather.tables.golden.txt`: `workersData` di `war_units.c`): peasant e peon. I passi dell'azione di raccolta non sono piu' un dato a parte: sono nella tabella unica di tutte le azioni (`ActionSteps.Data`) e li esegue `TWarActionRunner`, lo stesso per tutte le aree.

**Il seguimento e' quello vero** (`TWarFollowState`, attacco): `gather_gold` e `deliver` mettono uno stato `follow` con `TWarStateMachine.CreateFollow` (non c'e' piu' un segnaposto `TWarFollowRequest`) e il modello lo aggiorna: l'unita' cammina fino a portata. **Il golden di raccolta lo sostituisce di proposito, come il C dello scenario** (`gatherResolveFollows` in `war_model_ref.c`, `TGatherScenario.ResolveFollows`): lo scenario porta l'unita' sul bersaglio (`wu_unitPointOnTarget`) e toglie lo stato con `wst_popState(COMPLETION, SUCCESS)`, e registra `RegisterHooks(WAR_STATE_FOLLOW/PATROL/ATTACK, nil, nil, nil)` (il C dello scenario non li aggiorna), cosi' il golden misura gli stati di raccolta e non il cammino; i test di classe (`TGatherRig`) fanno lo stesso per i follow che mettono, e `TGatherRig.Create(seme, True)` lascia il follow vero (test `DovrebbeRaggiungereLaMinieraConIlSeguimentoVero`). **Il crollo** e' ora portato (costruzione): lo scenario di raccolta lo sostituisce ancora (`RegisterHooks(WAR_STATE_COLLAPSE, nil, nil, nil)`; nel C `gGatherStubs`: l'ingresso nel crollo non fa nulla e l'aggiornamento non si chiama), per avere gli stessi golden di prima: una miniera esaurita resta in piedi nello scenario. Per lo stesso motivo lo scenario aggiorna solo le azioni di raccolta (`gatherUpdateHarvestActions` nel C, `TGatherScenario.Tick`): il modello le aggiorna tutte con `UpdateAfterStates`.

**Difetti del C conservati** (servono per avere gli stessi dati, ognuno con un test): (1) `chopping` chiude il carico quando la legna e' **esattamente** 100: con una quantita' dispari (97 portati da prima) il lavoratore non smette mai di tagliare; (2) `mining` somma l'oro a quello che il lavoratore gia' porta, qualunque cosa sia (30 di legna + 100 d'oro sono 130 d'oro); (3) un lavoratore che e' dentro un edificio (`deliver` con `insideBuilding`) e riceve un altro ordine non esce mai: lo sprite resta disattivato (non c'e' un'uscita per `deliver`); (4) `chopping` non libera la casella che occupa quando finisce: resta segnata finche' qualcosa non la libera (il `move` che segue lo fa); (5) `wst_updateChoppingState non azzera `lastActionStep` quando manca il municipio (il colpo resta segnato, innocuo); (6) la ricerca del municipio guarda anche quelli che stanno crollando o morendo; (7) gli id a 16 bit del resto del modello.
**Differenze volute** (ognuna con un test): **lo sprite aggiunto sostituisce quello che c'e'**. Nel C `we_addSpriteComponent` non toglie lo sprite che l'entita' ha e ne lascia uno orfano nell'array denso, con lo stesso proprietario; la prima `we_removeSpriteComponent` che sposta l'ultimo elemento lo fa tornare lo sprite dell'unita': dopo l'ultima presa di una miniera (`wst_exitMiningState` aggiunge lo sprite normale senza togliere quello col carico) un peone mostra poi l'immagine del carico d'oro senza averlo. Il Delphi non ha uno spazio di componenti e non riproduce l'errore; **il C del golden e' lo stesso con un involucro** (`we_addSpriteComponentFromResource` toglie prima lo sprite che c'e': stesso comportamento, dichiarato nell'intestazione di `war_model_ref.c`) e senza l'involucro i golden differirebbero solo nell'immagine dello sprite (seme 2, dal tic 1480). Un tipo di unita' che non e' un lavoratore e riceve `mining`/`chopping` e' `EWarException` (il C: `assert` di `FIND_BY_TYPE`); un giocatore fuori da 0..4 e' `EWarException` (il C: puntatore nullo); `unit->actions[actionType]` con `actionType` fuori da 0..6 non si legge (il C leggerebbe fuori dall'array); `chopping` senza `Gather` e' `EWarException`.

**Parita'**: `war_model_ref gather [n]` (stessa unity build della prima fetta, con in piu' lo scenario di raccolta e tre sostituzioni dichiarate nell'intestazione: `wst_enterCollapseState` che non fa nulla, `wmap_setMapTileIndex` che registra le tessere scritte, lo sprite sostituito) fa girare **dieci scenari di 1800 tic** con seme fisso: due fazioni, ognuna con municipio, miniera (100-399 d'oro), foresta (alberi di 2-16 di legna, 15% di buchi) e tre lavoratori che portano gia' legna o oro nel 50% dei casi; ordini a caso (oro, legna, consegna, danni, `pop`, `move`, economia, cura, rimozione di una miniera o di un municipio) con il generatore di script, e gli ordini iniziali. Un'impronta FNV-1a per tic del testo di tutto lo stato (come nella prima fetta, con in piu' i nuovi stati, l'impronta delle tessere scritte, le foreste con i loro alberi e, per ogni unita', immagine, attivazione, fotogramma e specchio dello sprite): **zero differenze a Win32 e a Win64** sulle 18000 righe, sul testo dello stato di un tic (seme 2, tic 900) e sulle tabelle (passi della raccolta, immagini dei trasportatori). Il riassunto di ogni scenario (`Q`: oro e legna dei due giocatori, oro che resta nelle miniere, alberi che restano, tessere scritte) dice che i dieci scenari hanno consegnato oro e legna, esaurito miniere e abbattuto alberi (test `DovrebbeEsercitareOgniParteDellaRaccoltaNegliScenari`). Per cercare una differenza: `war_model_ref dump gather SEME TIC` e, dal lato Delphi, `DELPHIDOOM_WAR_GATHER_DUMP=seme,tic,file` con il test `DovrebbeScrivereIlTestoDelloStatoSeRichiesto`. Gruppo `194 raccolta` di `Tools\Verifica\201`.
**Numeri** (prima dell'unione): 63 test nuovi, copertura delle unit nuove o toccate 90-100%; numeri dell'insieme nella sezione "Unione delle tre aree".

## Costruzione, riparazione, crollo, addestramento e miglioramenti (issue #194, seconda fetta)

Gli stati di costruzione del remake (`war_state_machine_build.c`, `_repair.c`, `_repairing.c`, `_collapse.c`, `_train.c`, `_upgrade.c`), i passi delle azioni (`wact_updateAction`), i muri come entita' e gli ordini di `war_commands.c` che li creano, a classi, sopra il modello della prima fetta. Una classe per unit; il registro degli stati e' quello della prima fetta (si registrano con **una riga** in `TWarModelFactory`).

**Mappa nome C -> classe**

| C | Delphi |
|---|---|
| `wst_createBuildState`, `wst_enterBuildState`, `wst_exitBuildState`, `wst_updateBuildStates` | `TWarBuildState` (`Model.State.Build`) |
| `wst_*CollapseState` | `TWarCollapseState` (`Model.State.Collapse`) |
| `wst_*RepairState`, `wst_updateRepairStates` | `TWarRepairState` (`Model.State.Repair`) |
| `wst_*RepairingState` | `TWarRepairingState` (`Model.State.Repairing`) |
| `wst_*TrainState`, `wst_applyTrainTransaction` | `TWarTrainState` (`Model.State.Train`) |
| `wst_*UpgradeState`, `wst_applyUpgradeTransaction` | `TWarUpgradeState` (`Model.State.Upgrade`) |
| le righe di `stateDescriptors` di questi sei stati | `TWarConstructionStates.Register` (`Model.State.Construction`) |
| `wact_updateAction` e `updateActions` di `war_map.c` | `TWarActionRunner` (`UpdateAll`, chiamato da `TWarModelWorld.UpdateAfterStates`) con la tabella unica `ActionSteps.Data`; le risorse delle immagini di costruzione in `Model.BuildingResources.Data` (generata) |
| `wcmd_tryPlaceBuilding`, `we_checkTileToBuild`, `we_checkRectToBuild` | `TWarConstructionCommands.PlaceBuilding`, `TryPlaceBuilding`, `CheckTileToBuild`, `CheckRectToBuild` |
| `wcmd_executeRepairCommand` (per i contadini dati) | `TWarConstructionCommands.OrderRepair` |
| casi `WAR_COMMAND_TRAIN_*` e `WAR_COMMAND_UPGRADE_*` di `wcmd_executeCommand` | `OrderTrain`, `OrderUpgrade` |
| `wcmd_cancel` (per un'entita') | `TWarConstructionCommands.Cancel` |
| caso `WAR_COMMAND_BUILD_WALL` | `TWarConstructionCommands.PlaceWall` |
| `we_createWall`, `we_createRuins`, la parte di `createStartingWalls` | `TWarTerrainEntities` |
| `we_addWallPiece`, `we_determineWallTypes`, `we_takeWallDamage` | `TWarWalls` (`Context.Walls`) |
| `we_addRuinsPieces`, `we_determineRuinTypes` | `TWarRuins` di #193 (`Context.Ruins`) |
| il ramo del muro di `wst_updateIdleState` | `TWarIdleState` (ramo `WAR_ENTITY_WALL`) |
| `wu_unitInRange`, `wu_unitTileOnTarget`, `wu_unitPointOnTarget`, `rect_closestPointOnRect` | `TWarTargetGeometry` |
| `wpath_findEmptyTile`, `wpath_isEmpty` | `TWarPathGrid.FindEmptyTile`, `IWarOccupancyProbe` (`TWarGridOccupancy`) |
| `we_decreasePlayerResources` & C. | `TWarPurse` (e `TWarEconomy` che lo chiama) |

**Come lavorano gli stati.** *Costruire*: `TryPlaceBuilding` addebita il costo, crea l'edificio con il suo stato `build` (gia' pagato: `transactionApplied`) e manda il contadino in `repair` verso di lui; il contadino in portata (il raggio dei contadini e' 1 casella dalla casella piu' vicina dell'edificio) passa a `repairing`, che lo fa **entrare** (sprite nascosto) e gli da' il lavoro dell'edificio (`workerId`); lo stato `build` fa correre il tempo solo con un operaio dentro (il tempo del tic, per 100 con il trucco), mostra i fotogrammi dell'immagine di costruzione (uno ogni `1/n` della percentuale) e alla fine fa uscire il contadino sulla casella vuota piu' vicina, rida' all'edificio la sua immagine e dice "lavoro finito" con la voce della razza del giocatore 0. Un `build` annullato (`Cancel` -> `ResetStateForCancellation`) restituisce il costo **una volta** (`alreadyRefunded`), suona il crollo e, se e' l'unico stato, fa crollare l'edificio. *Riparare*: `repairing` su un edificio finito imposta l'azione REPAIR del contadino e ad ogni colpo di martello (`lastActionStep == ATTACK`) paga 1 oro e 1 legna e da' 9 punti ferita (fino al massimo, poi idle); senza denaro il contadino torna idle. *Crollare*: nasconde lo sprite, lascia le rovine (`Context.Ruins`, un quadrato per lato dell'edificio), libera le caselle, toglie l'edificio dalla selezione e lo rimuove dopo 17 fotogrammi da 0,1 s al tempo della mappa. *Addestrare e migliorare*: l'ingresso nello stato **addebita** il costo (se non basta piu', lo stato si annulla da solo con `pop`), l'edificio occupa le sue caselle e ha `building` e `buildPercent`; alla fine nasce l'unita' sulla casella vuota piu' vicina (`TWarEntityManager.CreateDude`, poi idle) e suona la voce della razza **dell'unita**, oppure sale il livello del miglioramento (`TWarEconomy.IncreaseUpgradeLevel`: le unita' del giocatore cambiano). Un ordine e' accettato solo se lo stato dell'unita' lo permette (le maschere di interruzione del C).

**Servizi opzionali** (nessun finto da aggiornare per le classi della prima fetta): `IWarConstructionHost` (`UnitFrames`, `ConstructionFrames`, `PlaySound`, `PlayRandomSound`, `Acknowledge`, `IsTileKnown`; `TWarNullConstructionHost` e' il predefinito: niente fotogrammi, nessun suono, mappa tutta nota) e `IWarOccupancyProbe` (si prende dall'occupazione con `Supports`, altrimenti ogni casella e' vuota). La nebbia di guerra, i fotogrammi delle immagini del `DATA.WAR` e i suoni sono del gioco (#200).

**Cosa NON e' portato**: l'IA (`aiCommand`), le animazioni dei danni e del crollo, le strade (`BUILD_ROAD`, `we_checkTileToBuildRoadOrWall` per le strade), la selezione, i bottoni e il mouse (la scelta della casella), `wcmd_cancel` sulla selezione (si chiama per entita'), le incantesimi, l'attacco e la raccolta (altre fette).

**Difetti del C conservati** (servono per avere le stesse impronte; ognuno ha un test): (1) un edificio **in costruzione** accetta l'ordine di addestramento o di miglioramento, e lo stato nuovo prende il posto di `build` (che esce senza rimborso e senza crollo); (2) `we_checkRectToBuild` salta le caselle fuori dalla mappa (un edificio mezzo fuori e' permesso); (3) ogni pezzo di muro e' del giocatore 0; (4) un colpo di martello da' sempre 9 punti ferita per 1 oro e 1 legna; (5) la voce di "pronto" e' della razza dell'unita' addestrata; (6) lo stato idle del muro gira ad ogni tic; (7) l'oro si controlla prima della legna (messaggio del primo che manca, come nella prima fetta); (8) i miglioramenti a coppie condividono un livello.
**Differenze volute** (ognuna con un test): due miglioramenti della stessa coppia in corso insieme: il C si ferma su un `assert` in `we_increaseUpgradeLevel` quando finisce il secondo, il port **rifiuta l'ordine** (`RejectOverbookedUpgrades`, predefinito True; a False lo accetta come il C e al termine solleva `EWarException`); un miglioramento oltre il massimo o il terzo livello (il C legge `goldCost[2]` fuori dall'array) e' rifiutato; `wst_enterRepairingState` su un edificio "da costruire" il cui stato non e' ancora sulla pila (il C si ferma su un `assert`) solleva `EWarException`; un'unita' addestrata con la piscina piena (il C usa un puntatore nullo) aspetta; un'immagine di costruzione senza fotogrammi non divide per zero (il C ottiene infinito, che nessuna percentuale raggiunge); un pezzo di muro senza massimo e' senza punti ferita (il C divide per zero); `FindEmptyTile` da una casella fuori mappa solleva `EWarException`; `CheckTileToBuild` per un tipo senza misura solleva `EWarException`; l'azione di un'unita' che non ha quel tipo si ferma come nel C; `TWarEconomy` e gli stati usano `TWarPurse`.

**Parita'** (`Tools\Verifica\194`, gruppo `194 costruzione` di `Tools\Verifica\201`): il C del remake come unity build con **`war_commands.c` intero** dentro: gli scenari (`war_construction_ref.inc`) chiamano i veri `wcmd_tryPlaceBuilding`, `wcmd_executeRepairCommand`, `wcmd_cancel` e, con la selezione e il comando messi a mano, `wcmd_executeCommand` per addestramento e miglioramenti; il solo clic sulla mappa e' sostituito da `we_checkTileToBuild` seguito dal comando (o dal suono di annullamento), come nel codice. Stub dichiarati nell'intestazione: `wa_createAudio*` e `wa_playAcknowledgementSound` (contano e mescolano l'id del suono), `wspr_createSpriteFromResourceIndex` (le immagini di costruzione 331..346 hanno `1 + risorsa % 4` fotogrammi: `TConstructionObserver` fa lo stesso), il resto come nella prima fetta. 24 scenari di 400 tic (seme fisso): una base di 17 edifici e 5 unita' del giocatore 0, il muro e le rovine, e una scelta casuale (stessa sequenza di estrazioni in C e in Delphi) tra costruire con un contadino vicino, addestrare, migliorare, annullare, riparare con un contadino nuovo accanto all'edificio, danneggiare, alzare e rompere muri, spese, rimozioni e `pop`; tic di 1/60, 0,25, 2 e 5 secondi, con e senza il trucco del tempo. Gli scenari non allontanano mai il contadino dall'edificio (il follow non c'e') e non ordinano due miglioramenti della stessa coppia. L'impronta di ogni tic e' l'FNV-1a del testo di tutto lo stato della prima fetta **piu'** sprite (abilitato, fotogrammi, indice, specchio), rovine, muri e suoni (`X`, `Y`, `R`, `V`). **Zero differenze** a Win32 e a Win64 (`model.construction.golden.txt`, 9600 righe; `model.construction.dump.golden.txt`, il testo di un tic; `model.construction.tables.golden.txt`: i 682 passi delle 151 azioni, le risorse delle immagini, i costi dei muri e il fattore del trucco). La prima fetta resta identica (4 golden su 4). `WAR_REF_COVER=1 war_model_ref construction` dice quanti tic ogni tipo di stato e' stato attivo; `DELPHIDOOM_WAR_CONSTRUCTION_DUMP=seme,tic,file` fa scrivere al test di Delphi il testo di un tic per cercare una differenza.
**Test**: `Tests\DelphiDoom.Tests.War.dpr`: `ConstructionParity` (7), `ConstructionBuild` (cantiere, riparazione, crollo: 39), `ConstructionTraining` (addestramento e miglioramenti: 24), `ConstructionSupport` (passi delle azioni, vicinanza, caselle libere, denaro, muri, ospite: 45), con `ConstructionRig`/`Observer`/`Scenario` come supporto; 899 test (898 passati, 1 ignorato) a Win32 e a Win64, 115 nuovi (due sono misure o aiuti che non fanno nulla senza la variabile d'ambiente). Copertura delle unit nuove: 100% (`ActionStepper` 93%: il giro oltre l'ultimo passo di una definizione senza attesa finale, che nessuna ha). Prestazioni (dopo l'unione vedi la sezione relativa): il passo delle azioni costa 0,011 us per unita' e per tic a Win32 (0,008 a Win64) contro 0,086 us per gli stati di 400 unita' ferme (`DELPHIDOOM_WAR_BENCH=file`); le funzioni sono statiche e nessuna chiamata virtuale ne' a interfaccia avviene per unita' e per tic (gli ospiti si chiamano una volta per acquisto o per edificio).

## Unione delle tre aree (issue #194, 2026-11-14)

L'attacco, la raccolta e la costruzione (le tre sezioni qui sopra) sono nate in parallelo sulla stessa base e hanno ciascuna una versione di alcune cose. Ora e' **un modello solo**:

| Prima (tre versioni) | Ora (una) |
|---|---|
| `TWarActionRunner` (attacco, senza frame), `TWarActionStepper` (raccolta, solo l'azione di raccolta, `GatherData`), `TWarActionStepper` (costruzione, tutte le azioni, `ActionStepData`) | **`TWarActionRunner`** (`ActionRunner`): `wact_updateAction` con attesa, passi, colpo, suoni, **fotogramma e specchio dello sprite** (`SpriteFrame`, `ScaleX`), `Reset`, `UpdateAll`; **una** tabella, `ActionSteps.Data` (54 x 7, generata da `Make-WarActionSteps.ps1`); un'azione che il tipo non ha finisce e l'unita' non ha piu' azione (il C la segnala e la ferma) |
| `World.Update` con le azioni dentro (raccolta), `World.UpdateActions` (costruzione), `World.UpdateAfterStates` (attacco) | `World.Update` = stati; **`World.UpdateAfterStates`** = griglia delle unita' vicine, azioni di tutte le unita', proiettili (l'ordine di `wmap_updateMap`); `IWarCombatServices.BuildNearUnits` e `UpdateProjectiles` |
| `TWarTargetGeometry`, `TWarUnitTargeting`, `TWarUnitRange` | **`TWarTargetGeometry`** (con `DistanceInTiles`, `SetCenterTile`) |
| `TWarPathGrid.FindEmptyTile: TPoint` e `FindEmptyTile(..., out X, Y)` | **`FindEmptyTile: TPoint`** (fuori mappa: `EWarException` come prima); `TWarGridOccupancy` lo adatta a `IWarOccupancyProbe` |
| `TWarEconomy.Increase` e `TWarPurse.Increase` | **`TWarPurse.Increase`** (l'economia la chiama) |
| `TWarFollowRequest.New` (solo la creazione, segnaposto) e lo stato `follow` dell'attacco | **`TWarStateMachine.CreateFollow`** + `TWarFollowState` (il follow vero, anche per la raccolta e la riparazione) |
| sprite nel componente unita' (raccolta: `SpriteResource`, `SpriteEnabled`, `SpriteFrame`, `Mirrored`) e nell'entita' (costruzione: `HasSprite`, `SpriteEnabled`, `SpriteFrames`, `SpriteFrame`, `ScaleX`) | **nell'entita'**: `HasSprite`, `SpriteResource`, `SpriteEnabled`, `SpriteFrames`, `SpriteFrame`, `ScaleX`; `TWarUnitSprites` lavora sull'entita' (togliere lo sprite = `HasSprite` falso) |
| `GatherData` (passi `H` + immagini dei trasportatori), `ActionStepData` (passi `S` + risorse di costruzione) | `WorkerSprites.Data` (solo `W`), `BuildingResources.Data` (solo `R`); `gather.tables` e `model.construction.tables` non hanno piu' i passi (li ha `model.steps`) |

**Nel C della parita'** (`war_model_ref.c`): `tickModel` e' il tic intero (stati nell'ordine di `wmap_updateMap`, `wgrid_build`, `updateActions`, `updateProjectiles`) per attacco e costruzione; la raccolta ha `gatherTick` **voluto cosi'**: gli scenari di raccolta misurano gli stati di raccolta (follow come stand-in `gatherResolveFollows`, crollo e scrittura delle tessere sostituiti con `gGatherStubs`, solo le azioni di raccolta si aggiornano). Con il giro intero i golden di raccolta cambierebbero (le azioni di inattivita' e di marcia avanzano, le miniere esaurite crollano e spariscono, i contadini camminano davvero): sono stati provati e non servono alla raccolta. Il lato Delphi fa lo stesso (`TGatherScenario.Tick`, `TGatherRig`).

**Differenze volute dell'unione** (con un test): il passo dell'azione e' ora eseguito per **tutte** le unita' e azioni (prima, per la raccolta, solo per quella di raccolta): `DovrebbeLasciareStareLeAzioniSenzaPassi` (GatherSupport) prova che l'inattivita' corre e che un'azione che il tipo non ha finisce; un contadino che deve raggiungere una miniera cammina davvero col follow vero (`DovrebbeRaggiungereLaMinieraConIlSeguimentoVero`); un edificio da riparare fuori portata fa camminare il riparatore (`DovrebbeInseguireLEdificioSeEFuoriPortata`, ora con il `move` sopra il `follow`).

**Numeri**: `DelphiDoom.Tests.War` **1025 test, 1 ignorato, 1024 passati, 0 falliti** a Win32 e a Win64; 13 golden dei quattro gruppi `194 *` identici al C (`Confronta-Golden.ps1 -Solo 194`); copertura di `Libs\War` 98% (6603 righe su 6683; `ActionRunner` 94%). **Costo** (400 unita' ferme che giocano l'azione di inattivita', 1500 tic, `DELPHIDOOM_WAR_BENCH=file`): stati 0,086 us per unita' e tic a Win32 (0,077 a Win64), passi delle azioni **0,011** (0,008), stati + `UpdateAfterStates` 0,16 (la griglia delle unita' vicine, dell'attacco, e' la parte maggiore). Nessuna chiamata virtuale o a interfaccia per unita' e per tic: `TWarActionRunner`, `TWarTargetGeometry`, `TWarUnitSprites` e gli stati sono funzioni di classe statiche; l'interfaccia `IWarCombatServices` si chiama due volte per tic.

## Comandi, incantesimi, animazioni, muri e tic intero (issue #194, completamento)

Con questa parte il modello ha tutto `war_commands.c`, lo stato `cast` e gli incantesimi, `updateMagic`/`updateSpells`,
`war_animations.c`, l'attacco ai muri e il tic intero di `wmap_updateMap`. Resta fuori solo cio' che e' di altre issue
(vedi in fondo).

### Mappa nome C -> classe

| C | Delphi (`DelphiDoom.War.Model.*`) |
|---|---|
| `map->selectedEntities`, `map->selectionGroups`, `wmap_add/removeEntity*Selection`, `wmap_clearSelection` | `TWarSelection` (`Selection`; `Context.Selection`) |
| `isEntitySelectable`, `updateSelectionFromList`, `updateSelectionGroups` | `TWarSelectionCommands` (`Commands.Selection`: `IsSelectable`, `Select`, `StoreGroup`, `RecallGroup`) |
| il ciclo sulla selezione di ogni `wcmd_execute*Command`, `wu_isFriendlyUnit`, `wst_canSubmitTransition`, `wst_resetState`, `wa_playAcknowledgementSound` | `TWarCommandFamily` + `TWarCommander` (`Commands.Family`) |
| `wcmd_executeMoveCommand`, `wcmd_executeFollowCommand`, `wcmd_executeStopCommand` | `TWarMovementCommands` (`Commands.Movement`: `Move`, `Follow`, `Stop`) |
| `wcmd_executeAttackCommand` | `TWarAttackCommands.Attack` (`Commands.Attack`) |
| `wcmd_executeHarvestCommand`, `wcmd_executeDeliverCommand` | `TWarGatherCommands` (`Commands.Gather`: `Harvest`, `Deliver`) |
| `wcmd_executeSummonCommand`, `wcmd_executeRainOfFire/PoisonCloud/Healing/Invisiblity/UnholyArmor/RaiseDead/SightCommand` | `TWarSpellCommands` (`Commands.Spells`) |
| `wcmd_tryPlaceBuilding`, `wcmd_executeRepairCommand`, casi TRAIN/UPGRADE/BUILD_WALL, `wcmd_cancel` (gia' portati) + caso `BUILD_ROAD`, ordine dell'IA | `TWarConstructionCommands` (`Commands.Construction`: aggiunti `PlaceRoad`, `OrderTrain(..., causa)`) |
| `wcmd_executeCommand` (il `switch`), `wcmd_train*`/`wcmd_upgrade*`/`wcmd_build*` (cosa mette ogni bottone nel comando), `updateCommandFromRightClick`, `wcmd_cancel` sulla selezione | `TWarCommands` (`Commands.Dispatcher`): **registro** tipo di comando -> gestore (`RegisterHandler`), `Execute`, `RightClick`, `Cancel`, `TrainOf`/`UpgradeOf`/`BuildingOf` |
| `wpath_getTileEntityId`, `wmap_isTileVisible/Fog/Unknown`, `wmap_isUnitUnknown`, `wmap_isUnitPartiallyVisible` (cio' che un ordine chiede alla mappa) | `IWarCommandMap` (`Commands.Intf`), `TWarGridCommandMap` (`Commands.GridMap`, sopra `TWarPathGrid` e `TWarFogOfWar`) |
| `wst_createCastState`, `wst_updateCastState(s)` | `TWarCastState` (`State.Cast`) |
| `wst_canInterruptCast` (mai registrata nel C) | `TWarStateMachine.CanSubmitTransition` con `Context.InterruptibleCasts` |
| `updateMagic`, `updatePoisonCloud`, `updateSight`, `updateSpells`, i fuochi della pioggia, `SDL_randf` | `TWarSpells` (`Spells`: `UpdateMagic`, `UpdateSpells`, `RainOfFire`, `SpawnSight`, `SpawnPoisonCloud`, `RandomUnit`) |
| `WarSightComponent`, `WarPoisonCloudComponent`, `WarAnimationsComponent` | campi di `TWarEntity` (`HasSight`, `HasPoisonCloud`, `SpellTile`, `SpellTime`, `SpellDamageTime`, `Animations`) |
| `war_animations.c` (`wanim_create*`, `wanim_addAnimation`, `wanim_removeAnimation`, `wanim_containsAnimation`, `wanim_updateAnimation(s)`) | `TWarAnimations` (`Animations`) |
| `we_meleeWallAttack`, `we_rangeWallAttack` | `TWarAttacks.WallMelee`, `WallRange` (`IWarCombatServices.MeleeWallAttack`, `RangeWallAttack`) |
| ramo dei muri di `wst_updateAttackState`, `wproj_doProjectileTargetDamage`, `wproj_do*SplashDamage` | `TWarAttackState`, `TWarProjectiles` (`WallSplash`) |
| `wst_isInsideBuilding` | `TWarStateMachine.IsInsideBuilding` (una sola: l'attacco e la selezione usano questa) |
| `we_createRoad`, `we_addRoadPiece`, `we_determineRoadTypes` | `TWarTerrainEntities.CreateRoad`, `Context.Roads` (`TWarLine` di #193) |
| `wmap_updateMap` (stati, griglia, azioni, animazioni, proiettili, mana, incantesimi) | `TWarModelWorld.Update` + `FinishTic`, o `Tick` |
| `createStartingEntities` + le entita' di `wmap_enterMap` | `TWarMapBinding` (`MapBinding`, `TWarModelFactory.CreateMapBinding`) |

**Riuso**: gli ordini di costruzione restano in `TWarConstructionCommands` (esteso con sole aggiunte); il seguimento e'
`TWarStateMachine.CreateFollow`; gli stati di raccolta si creano con `TWarGatherStateFactory`; le distanze con
`TWarUnitGeometry`/`TWarTargetGeometry`; il municipio con `TWarUnitSearch`; le caselle libere con `IWarOccupancyProbe`
(`TWarPathGrid.FindEmptyTile`); le strade con `TWarLine`; i muri con `TWarWalls`; i passi dell'azione di attacco (che
lo stato `cast` legge) con `TWarActionRunner`/`ActionSteps.Data`; gli alberi con `TWarMapForests`; i suoni degli ordini
con `IWarConstructionHost` (`Acknowledge`, `PlaySound`); le statistiche degli incantesimi erano gia' in `StatData`
(nessuna tabella nuova: le tabelle dei comandi sono tre array in `Commands.Dispatcher` **confrontati con il golden del
C** `model.commands.tables`).

### Comandi

`TWarCommands` e' cio' che un giocatore (o il computer) puo' ordinare alla **sua** selezione. Non ha mouse, bottoni ne'
pannelli: il comando che nel C aspetta un clic qui si esegue quando il punto e' noto (`TWarCommand.Target`, pixel della
mappa; `Queue` = SHIFT). Il registro (`RegisterHandler`) permette di aggiungere o sostituire un tipo di comando senza
toccare un `case`. `Execute` cerca chi sta sotto il punto con `IWarCommandMap` (come `wcmd_executeCommand`),
`RightClick` sceglie l'ordine da cio' che c'e' sotto (miniera o albero: raccogli; municipio proprio: consegna; nemico:
attacca; amico: segui; muro o niente: muovi).

**L'originale non ha formazioni**: `wcmd_executeMoveCommand` da' a tutte le unita' lo **stesso** punto (le separa
l'evitamento, #195). Non c'e' nemmeno un comando di pattuglia: lo stato `patrol` esiste e riceve punti con SHIFT, ma
nessun `WAR_COMMAND_*` lo crea.

**L'IA (#196) non e' portata; il suo punto d'ingresso si'**: `TWarModelFactory.CreateComputerCommands(mondo, selezione,
giocatore)` da' lo stesso `TWarCommands` con una selezione propria, il giocatore del computer e
`WAR_CAUSE_AI_ORDER`/`WAR_INTERRUPT_AI_ORDER` (`TWarCommander.Computer`). L'unico ordine che `war_ai.c` da' oggi
(addestrare) e' provato cosi' nei golden (`fOpAi`) e nei test.

### Incantesimi e mana

Lo stato `cast` legge il passo di colpo dell'azione di attacco, come lo stato `attack`. Costi, durate e portate vengono
da `StatData` (guarigione 6 mana per punto ferita, portata 6; vista lontana 70 e visione oscura 50, 10 s; invisibilita'
200, 50 s; armatura sacrilega 100, 13 s, dimezza i punti ferita; pioggia di fuoco 25 per colpo, 5 fuochi; nube velenosa
100, 10 s, 10 di danno al secondo entro 2 caselle; resurrezione 50 per scheletro entro 4 caselle; ragno e scorpione 51,
elementale 250, demone 255). Le evocazioni sono un **comando** (non passano dallo stato `cast`). Il mana sale di un
punto al secondo fino al massimo; un'unita' evocata ne perde uno al secondo e a zero muore.

### Animazioni

`TWarAnimations` tiene cio' che e' stato del gioco: quale animazione (il nome del C: `littleDamage`, `hugeDamage`,
`collapse`, `explosion_x_y`, `spell_x_y`, `poison_cloud_x_y`), ciclo, stato, fotogrammi, ritardo, tempo trascorso e il
punto dato alla `wanim_create*`. L'immagine, lo scostamento e la scala (che dipendono dalla misura dei fotogrammi nel
`DATA.WAR`) sono di chi disegna (#197). Le animazioni dei danni degli edifici si creano in `TWarCombat.TakeDamage`, il
crollo in `TWarCollapseState.Enter`, le esplosioni in `TWarProjectiles`, i lampi in `State.Cast`/`Commands.Spells`.

### Unita' iniziali del livello

`TWarMapBinding` crea nel modello, con `TWarEntityManager`, le entita' che `TWarMapBuilder` ha messo nella mappa
(foreste, strada, muro, rovine e poi le unita'), nello stesso ordine: prendono **gli stessi id** (`EWarException` se uno
differisce). Da li' le unita' sono quelle del modello e la lista `TWarGameMap.Units` (che nebbia e minimappa leggono) e'
cio' che `SyncUnits` copia da loro: la mappa non ha piu' unita' proprie. I golden della mappa (#193) non cambiano
(`TWarMapBuilder` non e' toccato).

### Difetti del C conservati (ognuno con un test)

1. **Chi lancia un incantesimo non accetta nessun ordine**: `wst_canInterruptCast` e' scritta ma mai messa nella
   tabella degli stati (maschera 0). `Context.InterruptibleCasts := True` la applica (`DovrebbeRifiutareOgniOrdineAChi...`,
   `DovrebbeAccettareUnOrdineAChiLanciaConLInterruttore`, `DovrebbeNonInterrompereLaPioggiaDiSuaIniziativa`).
2. La pioggia di fuoco parte da sopra **la vista del giocatore** (`map->camera.viewport.y`: `Context.ViewportTop`): dove
   guarda la camera cambia quanto ci mette a cadere.
3. La portata di un incantesimo si misura al punto dell'ordine, non a dove e' ora il bersaglio.
4. Resurrezione: un avviso "manca il mana" per **ogni** cadavere che non si puo' pagare.
5. L'evocazione spende tutto il mana che puo' e finisce sempre con "manca il mana"; non chiede di chi e' l'evocatore
   (un nemico selezionato evoca) ne' la razza (un conjurer lancia la nube velenosa se gli si ordina).
6. Un'animazione finita si toglie al tic dopo, e quella che la segue nella lista della stessa entita' salta quel tic;
   le entita' di esplosioni e lampi non si tolgono mai; un edificio a cui si ordina di crollare mentre crolla prende
   un'altra animazione di crollo ogni volta.
7. Un'entita' tolta dal gioco resta nella selezione e nei gruppi (solo morte, crollo e ingresso in un edificio la
   tolgono).
8. `stop` arriva anche agli edifici (ferma un addestramento); l'attacco di un punto e' dato anche ai lavoratori; un
   lavoratore con un carico non pieno (pieno = esattamente 100) parte per la nuova raccolta; chi porta un carico pieno
   e non ha un municipio della sua razza non fa nulla ma l'ordine e' confermato.
9. Con SHIFT un punto aggiunto a chi pattuglia va sia al movimento sia alla pattuglia.
10. La nube velenosa ferisce anche gli amici; un muro senza pezzo sulla casella dell'attacco si colpisce all'infinito.
11. Durante il cantiere l'immagine dell'edificio e' quella di costruzione (`SpriteResource`: prima il modello teneva
    quella dell'edificio; trovato con i golden nuovi).

### Differenze volute (il C si ferma su un `assert` o va in crash; ognuna con un test)

- **Evocare**: `wcmd_executeSummonCommand` non da' il componente delle animazioni all'entita' del lampo e
  `wanim_addAnimation` si ferma: qui l'evocazione crea il lampo come gli altri incantesimi (nel C dei golden un
  involucro dichiarato aggiunge il componente).
- **Segui** dato a un edificio (lo stato di movimento chiede le statistiche di unita'): non gli e' dato.
- **Attacco di un punto** dato a un edificio (idem): non gli e' dato.
- Un **lavoratore** mandato ad attaccare un **muro o un albero** "seguiva" un'entita' senza posizione: non riceve l'ordine.
- Un selezionato che non esiste piu', un comando di addestramento/miglioramento senza un solo edificio selezionato o
  con l'edificio sbagliato, muro/strada senza il municipio selezionato, consegna senza municipio, raccolta di cio' che
  non e' miniera ne' foresta, un tipo di comando che non esiste: `EWarException`.
- Piscina delle entita' piena: l'evocazione si ferma, la resurrezione lascia il cadavere, vista e nube non nascono (il
  C usa un puntatore nullo).
- Le animazioni di un'entita' sono una lista che cresce (il C ha `shl/list`): nessun limite.

### Non portato (e di chi e')

- **#195**: percorsi e evitamento (`wpath_computeFlowField`, RVO: resta `IWarMovementSteering`), la nebbia che legge le
  entita' di vista (`updateFoW` con `WAR_ENTITY_TYPE_SIGHT`: l'entita' c'e', con casella e tempo) e che rivela bersaglio
  e attaccante.
- **#196**: `war_ai.c` (`wai_updateAIPlayers`, `aiCommand` dello stato di addestramento).
- **#197**: lo stato del comando che aspetta un clic (`map->commandState`, `consumeCommand`,
  `suppressSelectionOnRelease`), i bottoni e i pannelli, il rettangolo di selezione e il clic, i suoni della selezione
  (`wa_playDudeSelectionSound`), immagine, scostamento e scala delle animazioni, il disegno di muri, strade e rovine.
- **#200**: il ciclo del gioco (`war_game.c`), i trucchi come testo (`war_cheats.c`: il modello ha gia' `GodMode` e
  `HurryUp`), il collegamento a `Warcraft32`.
- Fuori ambito (#202): gli strumenti dell'editor di `wmap_updateMap` (`updateTreesEdit`, `updateRoadsEdit`, ...,
  `updateAddUnit`), `war_state_machine_debug.c`.

### Parita'

`Tools\Verifica\194\war_full_ref.inc` (vedi `LEGGIMI.md`): 36 scenari di 900 tic con il **tic intero** e gli ordini
dati dai veri `wcmd_executeCommand`, `updateCommandFromRightClick`, `updateSelectionFromList`,
`updateSelectionGroups`. Gruppi `194 comandi` (`model.commands.tables`, `model.commands`, `model.commands.dump`),
`194 incantesimi` (`model.spells`, `model.spells.dump`), `194 completo` (`model.full`, `model.full.dump`): 32400
impronte, **zero differenze** a Win32 e a Win64. Nel gruppo `completo` ogni tipo di stato e' attivo almeno una volta
tranne `patrol` (nessun comando lo crea) e `wait` (`DovrebbeFarConvivere...`).

**Numeri (2026-11-14)**: `Confronta-Golden.ps1 -Solo 194` = 20 golden su 20 identici rifatti dal C (13 di prima, 7
nuovi); `DelphiDoom.Tests.War` 1191 test, 1190 passati, 1 ignorato, 0 falliti a Win32 e a Win64 (a 64 bit il `.dpr`
compilato con `dcc64` a parte, perche' il `.dproj` dichiara solo Win32: comando in `docs\PARITA_WAR.md`); 166 test
nuovi; copertura di `Libs\War` 98% (7923 righe su 8004), unit nuove 97-100%. **Costo** del tic intero (400 chierici
fermi, 3000 tic, minimo di 9 esecuzioni su una macchina con altro carico, us per unita' e tic; `war_model_ref benchfull`
e `DELPHIDOOM_WAR_BENCH_FULL`):

| | stati | griglia | azioni | animazioni | proiettili | mana | incantesimi | totale |
|---|---|---|---|---|---|---|---|---|
| C gcc `-O1` | 0,194 | 0,054 | 0,013 | 0,009 | 0,000 | 0,026 | 0,004 | 0,327 |
| C gcc `-O2` | 0,167 | 0,024 | 0,012 | 0,003 | 0,000 | 0,009 | 0,002 | 0,243 |
| Delphi Win32 | 0,140 | 0,072 | 0,015 | 0,008 | 0,000 | 0,020 | 0,005 | 0,364 |
| Delphi Win64 | 0,108 | 0,097 | 0,010 | 0,009 | 0,000 | 0,017 | 0,005 | 0,280 |

(ogni colonna e' il minimo di quella parte, il totale il minimo del totale: non e' la somma). Le parti nuove
(animazioni, mana, incantesimi) stanno al livello del C a `-O1` e sono 2-3 volte piu' lente del C a `-O2`, su costi di
centesimi di microsecondo; gli stati sono piu' veloci del C; la griglia delle unita' vicine (seconda fetta) e' piu'
lenta del C e porta il totale a Win32 l'11% sopra il C a `-O1`: **il 5% non e' dimostrato** (il rumore tra un'esecuzione
e l'altra e' del 20-30%). Nessuna chiamata virtuale nei cicli; a interfaccia, per unita' e per tic, solo
`Occupancy.SetStaticEntity` di chi sta lanciando un incantesimo (come lo stato di attacco).

