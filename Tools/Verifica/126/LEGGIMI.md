# Verifica #126: modelli dei giocatori di Quake III (`animation.cfg`, animazioni a due livelli, tag)

**Seconda fetta (skin e file del giocatore)**: `build-skin.sh <cartella>` compila `q3skin.c` con le funzioni vere `CommaParse`, `RE_RegisterSkin`, `R_InitSkins`, `R_GetSkinByHandle` di `tr_image.c` e `CG_FileExists`, `CG_FindClientModelFile`, `CG_FindClientHeadFile` di `cg_players.c`; si lancia con `q3skin.exe Tests/Data/Models/q3player/skins > Tests/Data/Models/q3player/q3skin.golden.txt` (la cartella ha `fs.txt` con i file e le lunghezze che `trap_FS_FOpenFile` conosce, `regs.txt` con i nomi da registrare e i `.skin` scritti per i test). Il test e' `DelphiDoom.Tests.Models.Q3SkinParity`.

Produce `Tests\Data\Models\q3player\q3player.golden.txt` con il codice **vero** di Quake III, non riscritto. `build.sh` compila con il gcc di `Reference\_dati\_strumenti\w64devkit` (SSE, `-ffp-contract=off`: ogni operazione `float` arrotondata da sola) i seguenti intervalli di righe, ritagliati dai sorgenti in sola lettura:

- `code\cgame\cg_players.c`: `CG_ParseAnimationFile`, `CG_SetLerpFrameAnimation`, `CG_RunLerpFrame`, `CG_ClearLerpFrame`, `CG_PlayerAnimation`, `CG_SwingAngles`, `CG_AddPainTwitch`, `CG_PlayerAngles`;
- `code\cgame\cg_ents.c`: `CG_PositionEntityOnTag`, `CG_PositionRotatedEntityOnTag`;
- `code\renderer\tr_model.c`: `R_GetTag`, `R_LerpTag`;
- `code\game\q_math.c`: `AnglesToAxis`, `AxisClear`, `AngleSubtract`, `AnglesSubtract`, `AngleMod`, `VectorNormalize`, `MatrixMultiply`, `AngleVectors`;
- `code\game\q_shared.c` intero (`COM_Parse`, `Q_stricmp`) e le dichiarazioni di `animation_t`, `lerpFrame_t`, `playerEntity_t`, `animNumber_t`, `footstep_t`, `gender_t`.

`stubs.h` e `q3gen.c` sostituiscono il resto del gioco (file da una cartella, `cg.time` e `cg.frametime`, le quattro cvar, `CG_Printf` raccolto in righe, `CG_Error` con `longjmp`, il modello di un solo MD3 per `R_GetModelByHandle`).

```
sh Tools/Verifica/126/build.sh <cartella di lavoro>
D=Tests/Data/Models/q3player
<cartella>/q3gen.exe $D/files $D/tags.md3 mkmd3          # solo se si rifa tags.md3 (3132 byte, 6 fotogrammi, 4 tag, nessuna superficie)
<cartella>/q3gen.exe $D/files $D/tags.md3 > $D/q3player.golden.txt
```

- I file `.cfg` (`Tests\Data\Models\q3player\files`) e `tags.md3` sono **scritti per i test**: mai file di Quake III, di Team Arena o di OpenArena. `tags.md3` ha assi non unitari di proposito (per provare la normalizzazione di `R_LerpTag`).
- Il programma non si deve chiamare `patch*.exe` o `setup*.exe`.
- Una riga per caso, `ingressi | uscite`, ogni `float` come `#bit` esadecimali: `cfg`/`anim`/`cfgmsg` (le 7 configurazioni, tutte le 37 animazioni, gli avvisi), `timeline` + `step` (cinque percorsi a seme fisso: `CG_PlayerAngles` e `CG_PlayerAnimation` in sequenza, come in `CG_Player`, con tempi a passi irregolari, pause lunghe, cambi di animazione con il bit di alternanza, fretta, morte, dolore; gli ultimi due finiscono con `CG_Error`), `tag` (`R_LerpTag`, 100 casi, frame oltre l'ultimo e tag mancanti) e `pos` (le due `CG_Position*EntityOnTag`, 100 casi).
- Un file `.cfg` senza animazioni o che finisce dopo una parola opzionale **non** e' nello scenario: nel C `CG_ParseAnimationFile` non esce mai da quel ciclo (vedi `Libs\Models\README.md`, sez. 2e).
- Gli scenari sono scritti in `q3gen.c`; i test Delphi (`DelphiDoom.Tests.Models.Q3PlayerParity`) rileggono le righe, ricalcolano le uscite dagli ingressi e confrontano token per token (interi e parole uguali, float entro 4 ULP o 1e-6 assoluto).
