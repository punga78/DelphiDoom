# Parita' di Warcraft: Orcs & Humans (issue #201, indice #203)

Il criterio con cui si prova che `Libs\War` e `Libs\Cinematic` fanno quello che fa il remake in C (`Reference\war1`,
acoto87/war1, zlib), come per Greed (#175) e Rad-X. Le regole generali del repository (golden, test DUnitX, copertura)
sono in `CLAUDE.md`; qui c'e' cio' che e' specifico di War e i comandi per ripeterlo.

## Il criterio

1. **Il riferimento e' il C, non un'opinione.** Ogni golden di `Tests\Data\War` e' l'uscita di un programma in C che contiene
   il codice **originale** del remake, estratto alla lettera (per intervalli di righe cercati per testo: se il remake cambia
   l'estrazione fallisce, non si adatta in silenzio) e compilato con il gcc di `Reference\_dati\_strumenti\w64devkit`
   (non c'e' un compilatore C nel PATH). Gli unici pezzi scritti da noi sono gli **stub** di cio' che non e' logica del gioco
   (SDL, Tracy, `wm_alloc`, il log, il sintetizzatore `tsf_*`, i modelli di `WarContext`) e i **generatori di scenari**
   (seme fisso, nessun materiale commerciale). Niente e' modificato in `Reference\`.
2. **Il test di Delphi legge lo stesso file** e deve dare le stesse righe: impronte CRC-32 dei record e delle mappe,
   campioni PCM (anche i bit dei `float`), eventi del sintetizzatore con il campione in cui avvengono. Zero differenze e'
   l'unico risultato accettato; una tolleranza si dichiara nel test e nel README della libreria con il motivo (qui non ce ne sono).
3. **Dove il C ha un difetto** si decide caso per caso (come in `CLAUDE.md`): se l'uscita e' consumata da altri (i byte di un
   formato) il difetto si **conserva**; se e' un crash, una lettura fuori dal buffer o un errore evidente si **corregge**, con
   un test e una riga tra le "differenze volute" del README. Gli scenari dei golden **evitano** i difetti non conservati
   (e lo dicono nel generatore), perche' un golden che li contiene non si puo' ripetere.
4. **Dati commerciali**: `DATA.WAR` e i filmati non sono nel repository. I golden contengono solo numeri (CRC e conteggi).
   Un test che vuole il `DATA.WAR` vero si **ignora** se manca (`DELPHIDOOM_WAR_DATA` o `Reference\_dati\warcraft`); gli
   altri si costruiscono in memoria.
5. **Prestazioni**: il percorso caldo di War (il mixer, poi il gioco) deve stare entro il 5% del remake. `Tools\Misura-Coppie.ps1`
   misura due eseguibili del motore con `-timedemo`: serve un gioco, quindi si potra' usare quando esistera' `Warcraft32`
   (#200); finche' non c'e', la misura sul mixer non e' stata fatta (vedi "Cosa non e' coperto").

## Cosa prova cosa

| Area | Programma C (`Tools\Verifica\...`) | Golden (`Tests\Data\War`) | Test (`Tests\Source\DelphiDoom.Tests.War.*`) |
|---|---|---|---|
| Archivio `DATA.WAR` (#191) | `191\war_ref.c` (`wfile_loadWarFile`) | `datawar.retail*.golden.txt`, `catalog.golden.txt` | `Parity`, `Archive`, `Catalog` |
| Palette, immagini, sprite, cursori, tileset, font (#192) | `192\war_gfx_ref.c` (`wres_*`) | `graphics.golden.txt`, `fonts.golden.txt` | `GraphicsParity` |
| Livelli, campagne, raccordi, griglia (#193) | `193\war_lvl_ref.c` | `levels`, `campaigns`, `objectives`, `autotile*`, `grid` | `LevelParity`, `Campaign`, `Autotile`, `MapGrid` |
| Suoni, ricampionatore, mixer, volume posizionale (#198) | `198\war_audio_ref.c` | `audio.synth/mixer/position/records` | `AudioDecoders`, `AudioMixer`, `AudioMixParity` |
| **Tempo e eventi della musica** (#198) | `198\war_music_ref.c` (`wa_playMidi` + `tml.h`) | `music.golden.txt` (12 canzoni, 842 righe) | `MusicParity` |
| **Scelta dei suoni** (#198, #194) | `198\war_sound_ref.c` (`wa_play*Sound`) | `sounds.tables.golden.txt` (497), `sounds.ranges.golden.txt` (9) | `SoundPicker` |
| Filmati FLIC (#199) | `199\flc*.cpp` (`FlcPlayer` di OpenXcom: il remake **non** ha codice FLIC) | `Tests\Data\Cinematic\flic-*` | `Tests\...Cinematic.FlicParity` |

## Come si ripete

```
:: tutti i golden di War rifatti dal C e confrontati con quelli del repository (e i numeri dei test di Delphi)
powershell -NoProfile -File Tools\Verifica\201\Confronta-Golden.ps1 -Test bin\Tests\DelphiDoom.Tests.War.exe

:: un solo gruppo (191, 192, 193, 198, musica, suoni)
powershell -NoProfile -File Tools\Verifica\201\Confronta-Golden.ps1 -Solo musica

:: solo se il C e' cambiato di proposito: riscrive i golden (poi si guarda il diff e si rifanno i test)
powershell -NoProfile -File Tools\Verifica\201\Registra-Golden.ps1 -Solo musica
```

`Confronta-Golden.ps1` compila ogni gruppo in una cartella temporanea nuova, esegue i programmi, confronta riga per riga
(senza BOM e fine riga) e dice la prima riga che differisce; esce con 1 se qualcosa differisce o se il test fallisce.
Senza il `DATA.WAR` salta i golden che lo vogliono (lo dice), senza gcc non parte il gruppo. Ultima esecuzione
(2026-11-13): **18 golden su 18 identici** (6 gruppi), `DelphiDoom.Tests.War` 443 passati, 0 falliti, 1 ignorato (il PNG
di ispezione, `DELPHIDOOM_WAR_PNG_OUT`).

Per compilare i test: `Tools\build.bat DelphiDoom.Tests.War Release` (e `DelphiDoom.Tests.Cinematic`); in un worktree sotto
`.claude\worktrees\` serve la variabile `DCC_UnitSearchPath` con la cartella `DUnitX\Source` (vedi `Libs\War\CLAUDE.md`).
`build.bat` copia `Tests\Data` in `bin\Tests\Data`; per un eseguibile a mano: `robocopy Tests\Data bin\Tests\Data /E`.
A 64 bit `DelphiDoom.Tests.Cinematic` compila e passa; `DelphiDoom.Tests.War` non compila per intero (gli `AreEqual` e i
`WillRaise` di `Tests\Source\DelphiDoom.Tests.War.Palette.pas`, preesistenti): un programma con tutte le fixture tranne le
quattro grafiche (`Palette`, `Pixels`, `Graphics`, `Font` e i loro derivati) compila con `dcc64` e passa.

## Copertura

`Tools\Copertura.ps1 -Test War -Cartella Libs\War` e `-Test Cinematic -Cartella Libs\Cinematic` (richiede CodeCoverage.exe,
`DELPHI_CODECOVERAGE`; compila in Debug). Obiettivo 90% sulle librerie nuove. Risultato (2026-11-13): `Libs\War` 99%
(2107 righe su 2118), `Libs\Cinematic` 99% (1119 su 1130); le unit nuove di #198 e #199: 97-100% ciascuna.

## Cosa non e' coperto

- **L'ascolto**: nessuna delle tre parti nuove (musica, scelta dei suoni, scena di filmato) e' stata ascoltata o vista in una
  finestra. Il sintetizzatore e' un'interfaccia (`IWarMusicSynth`) con un finto nei test e un sintetizzatore muto: il
  SoundFont `GMGeneric.SF2` del remake non ha una licenza dichiarata e TinySoundFont non si porta.
- **Le misure a coppie** del percorso caldo (vedi sopra): il mixer e' stato confrontato per i **campioni** (identici),
  non per il tempo.
- **Il gioco originale DOS** come secondo riferimento dove il remake si discosta (IA, regole): serve il modello di gioco
  (#194-#196); per l'audio e i filmati il remake e' l'unico riferimento tranne per i FLIC (OpenXcom).
- Gli stati per tic e i fotogrammi dei punti 2-5 dell'issue #201 aspettano il modello di gioco e il renderer: l'harness e'
  fatto per aggiungere un gruppo alla tabella di `Tools\Verifica\201\Golden-Common.ps1` (programma C, argomenti, golden).
