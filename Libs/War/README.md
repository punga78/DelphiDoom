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
