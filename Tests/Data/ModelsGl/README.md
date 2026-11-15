# PK3 di prova dei modelli MD2 nel renderer OpenGL (issue #177, fetta 11)

Dati sintetici scritti da `Make-ModelPk3.ps1`: **dominio pubblico (CC0)**, nessun asset di un gioco.
Servono a mettere il disegno dei modelli (`gld_DrawModels`, ora `TEngineGlSceneModelPainter`) nel flusso del
registratore delle chiamate OpenGL (`Tools\Verifica\opengl`): senza un `MODELDEF` caricato quel codice non gira.

| File | Contenuto |
|---|---|
| `zmdl_d.pk3`, `zmdl_h.pk3`, `zmdl_x.pk3`, `zmdl_s.pk3` | un PK3 per gioco (Doom, Heretic, Hexen, Strife). Il nome non supera 8 caratteri: `-file` lo passa a `ExtractFileBase` |
| `models/ZCUBE.MD2` | un cubo (8 vertici, 12 triangoli, 4 punti di texture, pelle 64x64) in 2 fotogrammi (`frame0`, il secondo piu' piccolo) |
| `textures/ZMDLTEX.png` | texture 64x64 |
| `MODELDEF` | lega **ogni** stato del gioco (da `<Gioco>\info_h.pas`: Doom 1076, Heretic 1205, Hexen 2845, Strife 1566) al cubo e alla texture; stato pari: fotogramma 0 con fine 1, dispari: 1 con fine 0. Cosi' oggetti, mostri e proiettili visibili diventano il modello, anche con l'interpolazione tra stati (`gld_FindNextModelFrame`) |

Uso (il gioco rifiuta file esterni nelle versioni shareware senza `-devparm`):

```
Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom -Models
Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom -Models -Scenario "-iwad DOOM1.WAD -timedemo demo1" -WithMonsters -Tics 300
```

Rigenerare: `powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\ModelsGl\Make-ModelPk3.ps1`
(uscita deterministica tranne il PNG, encoder di `System.Drawing`).

| `zmdl_t.pk3` | come `zmdl_d.pk3` (solo Doom) ma con `transparency 0.5` su uno stato ogni tre: il ramo "trasparenza del MODELDEF" di `gld_DrawModel` |

Cosa si vede nel flusso (un disegno del modello = `glBindTexture($0DE1,1)` seguito da `glCallList` della lista del
fotogramma o da `glBegin(GL_TRIANGLES)` quando il fotogramma e' interpolato; senza pacchetto sono 0 in ogni scenario):

| Scenario (tic registrati dal 35) | disegni del modello |
|---|---|
| Doom 1 E1M1, 70 tic, senza mostri | 1400 |
| Freedoom 2 MAP01, 70 tic / 300 tic con mostri | 420 / 2700 |
| Freedoom 2 MAP02 / MAP03, 70 tic | 2310 / 1470 |
| Heretic E1M1, 70 tic | 3990 |
| Hexen MAP01, 70 tic | 5914 |
| Strife map32, 70 tic / 300 tic con mostri | 140 / 600 |
| Doom 1 `-timedemo demo1` (E1M5) / `demo3` (E1M7), 300 tic con mostri | 7776 / 12644, con l'ombra degli spettri (`GLS_SHADOW`) |

Non coperti: additivo e sottrattivo (le bandiere `GLS_ADDITIVE`/`GLS_SUBTRACTIVE` vengono da DEHACKED/ACTORDEF, nessuna
cosa dei livelli provati le ha), i modelli DDMODEL, DMX e DLL (solo MD2).
