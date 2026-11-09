# Verifica della issue #150 (da eseguire dal coordinatore, uno alla volta)

Nulla di questo lavoro e' stato compilato o eseguito dall'agente.

## 1. Build
    Tools\build.bat tests
    Tools\build.bat all Release
Leggere `logs\*.log` (righe `error`). Attesi: zero errori. Firme cambiate da controllare:
`TEngineAcsHost.Create(IGameRandom)`, `TEngineDynLightServices.Create(.., IGameRandom)`, `TLevelLoader.Create(.., ICommandRegistry, IGameRandom)`,
`TDoomLevelRules/THereticLevelRules/TStrifeLevelRules.Create(.., IGameRandom)`, `THexenLevelRules.Create(ICommandLine)`, `TEngineDefaults`, `TEngineConsoleStartup`,
`TEngineLevelBlockmap`, `TEngineLevelNodes`, `TMusMusicBackend`, `TEngineUdmfMapLoader`, `TEngineVoxelSpriteGenerator`, `TEngineScreenshotService`, `TEngineScreenshotFolders`,
`TEngineTempDirectory`, `TEngineExportSettings`, `TEngineConsoleScreen`, `TEngineActorDefLumps`, `M_ConfigureArgv(builder, queried, savenames)`.

## 2. Test
`Tests\DelphiDoom.Tests.CommandLine`: attesi 55 test verdi (30 esistenti + 14 `Queried` + 11 `SaveFileNames`).
Copertura: `powershell -NoProfile -File Tools\Copertura.ps1 -Test CommandLine` (>= 90%).

## 3. Parita' comandi e opzioni (confronto vecchio/nuovo)
Costruire l'eseguibile del commit precedente (master) in un'altra cartella, poi per Doom, Heretic, Hexen, Strife:
    powershell -NoProfile -File Tools\Verifica\150\Confronta-150.ps1 -OldExe <vecchio>\bin\Doom\Doom32.exe -NewExe bin\Doom\Doom32.exe
Atteso `IDENTICO` (cmdline, commandlineparams con e senza maschera = stesso elenco e ordine, cmdlist = stessi comandi con gli stessi nomi, typeof).
Per Heretic/Hexen/Strife passare `-Iwad HERETIC1.WAD` ecc.

## 4. Serie casuale e demo
-timedemo demo1, demo2, demo3 (Doom shareware): gametics identici al vecchio (demo3 = 2134).
Hexen: `-warp 1` carica il BEHAVIOR (TEngineAcsHost con il nuovo generatore); `-timer 1 -deathmatch` per `-timer`.

## 5. Smoke
Otto eseguibili con `Tools\Esegui-gioco.ps1` (25 s, `-devparm`), nessun `crash.txt` ne' `I_Error`. In particolare: `-config altro.ini`, `-con file.con`,
`-nomusic`, `-blockmap`, `-cdrom` (crea la cartella di lavoro), comandi `suicide`, `DEH_PrintActordef`, `DEH_SaveActordef x.txt`.
