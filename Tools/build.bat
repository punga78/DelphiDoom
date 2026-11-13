@echo off
rem ---------------------------------------------------------------------------
rem  Compila i progetti DelphiDoom con Delphi 11 (XE11) senza IDE.
rem
rem  Uso:   Tools\build.bat [progetto|all|giochi|strumenti] [Release|Debug] [Win32|Win64|both] [clean]
rem         (si puo' chiamare da qualsiasi cartella: la radice del repository si
rem          ricava dal percorso di questo file; i log vanno in <radice>\logs)
rem
rem  Il progetto si indica per nome (Doom32, ddc_hexen, DDWad, DelphiDoom.Tests.Wad...)
rem  oppure per percorso senza estensione (Doom\Doom32, Libs\Wad\DDWad, Tests\DelphiDoom.Tests.Wad).
rem  Le liste GIOCHI, STRUMENTI, LIBRERIE e TESTS sono la tabella nome -> percorso.
rem
rem    build.bat                    Doom32, Release
rem    build.bat all                tutti i progetti
rem    build.bat giochi             i 8 eseguibili di gioco (software + OpenGL)
rem    build.bat strumenti          Launcher, DD_IDE, DD_Tools, ddc e le 4 DLL ddc_*
rem    build.bat librerie           le DLL delle librerie (DDZlib, DDJpeg, DDMp3, DDXmi, DDSndfile, DDMikmod, DDGlbsp, DDPng, DDScript, DDWad -> bin\Libs)
rem    build.bat tests              librerie + un progetto di test DUnitX per libreria (bin\Tests); li esegue
rem    build.bat Heretic32 Debug    un solo progetto, configurazione Debug
rem    build.bat all Release clean  cancella tutta la cartella dcu prima di compilare
rem    build.bat all Release Win64  tutti i progetti a 64 bit (dcc64); i progetti che non
rem                                 compilano ancora a 64 bit (#41, #42, #43) sono elencati a parte
rem    build.bat tests Release Win64  librerie e test a 64 bit, li esegue (DLL e exe della stessa bitness)
rem    build.bat all Release both   Win32 e poi Win64, riepilogo per piattaforma
rem  La piattaforma e il clean si possono dare in qualsiasi ordine dopo la configurazione;
rem  predefinita Win32 (comportamento di sempre).
rem
rem  Cartelle (tutte dentro il progetto):
rem    bin\Doom, bin\Heretic, bin\Hexen, bin\Strife   eseguibili dei giochi
rem    bin\Tools                                      DD_IDE, ddc, ddc_*.dll
rem    bin                                            Launcher
rem    dcu\...\<Release|Debug>                        file .dcu
rem    logs\<progetto>.log                            log completo di ogni build
rem  Win64: bin\Win64\... (stesse sottocartelle, DLL in bin\Win64\Libs), dcu\Win64\...,
rem         logs\Win64\<progetto>.log. Win32 resta dov'e' sempre.
rem  Codice di uscita: errori di Win32 -> 1; i progetti che non compilano a 64 bit non lo alzano.
rem
rem  Variabile opzionale:
rem    BDS_DIR  cartella di installazione di Delphi, es.
rem             C:\Program Files (x86)\Embarcadero\Studio\22.0
rem ---------------------------------------------------------------------------
setlocal EnableDelayedExpansion

set "WHAT=%~1"
if "%WHAT%"=="" set "WHAT=Doom32"
set "CONFIG=%~2"
if "%CONFIG%"=="" set "CONFIG=Release"
set "CLEAN="
set "PLATS=Win32"
for %%A in (%3 %4) do (
  if /i "%%~A"=="clean" set "CLEAN=clean"
  if /i "%%~A"=="Win32" set "PLATS=Win32"
  if /i "%%~A"=="Win64" set "PLATS=Win64"
  if /i "%%~A"=="both"  set "PLATS=Win32 Win64"
)

set "GIOCHI=Doom\Doom32 Radix\Radix32 Speed\SpeedHaste32 Doom\GLDoom32 Heretic\Heretic32 Heretic\GLHeretic32 Hexen\Hexen32 Hexen\GLHexen32 Strife\Strife32 Strife\GLStrife32"
set "STRUMENTI=Launcher\Launcher DD_IDE\DD_IDE DD_Tools\DD_Tools Libs\Ddc\ddc Doom\ddc_doom Heretic\ddc_heretic Hexen\ddc_hexen Strife\ddc_strife Keen\Keen32 Greed\Greed32 Speed\Speed32 OpenXcom\Xcom32 Libs\Parity\ParityTool"
set "LIBRERIE=Libs\Zlib\DDZlib Libs\Jpeg\DDJpeg Libs\Mp3\DDMp3 Libs\Xmi\DDXmi Libs\Sndfile\DDSndfile Libs\Mikmod\DDMikmod Libs\Glbsp\DDGlbsp Libs\Png\DDPng Libs\Script\DDScript Libs\Wad\DDWad"
set "TESTS=Tests\DelphiDoom.Tests Tests\DelphiDoom.Tests.Jpeg Tests\DelphiDoom.Tests.Mp3 Tests\DelphiDoom.Tests.Xmi Tests\DelphiDoom.Tests.Sndfile Tests\DelphiDoom.Tests.Mikmod Tests\DelphiDoom.Tests.Glbsp Tests\DelphiDoom.Tests.M2m Tests\DelphiDoom.Tests.Ogg Tests\DelphiDoom.Tests.Png Tests\DelphiDoom.Tests.Script Tests\DelphiDoom.Tests.Wad Tests\DelphiDoom.Tests.IdTech Tests\DelphiDoom.Tests.CommandLine Tests\DelphiDoom.Tests.Configuration Tests\DelphiDoom.Tests.Logging Tests\DelphiDoom.Tests.Clock Tests\DelphiDoom.Tests.GameHost Tests\DelphiDoom.Tests.Input Tests\DelphiDoom.Tests.Video Tests\DelphiDoom.Tests.Audio Tests\DelphiDoom.Tests.Common Tests\DelphiDoom.Tests.Acs Tests\DelphiDoom.Tests.Udmf Tests\DelphiDoom.Tests.Specials Tests\DelphiDoom.Tests.Scanner Tests\DelphiDoom.Tests.Net Tests\DelphiDoom.Tests.MapInfo Tests\DelphiDoom.Tests.DynLights Tests\DelphiDoom.Tests.Dehacked Tests\DelphiDoom.Tests.ActorDef Tests\DelphiDoom.Tests.MusInfo Tests\DelphiDoom.Tests.TextureDefs Tests\DelphiDoom.Tests.Definitions Tests\DelphiDoom.Tests.Palette Tests\DelphiDoom.Tests.MathCore Tests\DelphiDoom.Tests.Console Tests\DelphiDoom.Tests.Imaging Tests\DelphiDoom.Tests.GlMath Tests\DelphiDoom.Tests.Models Tests\DelphiDoom.Tests.Texture Tests\DelphiDoom.Tests.Collision Tests\DelphiDoom.Tests.IdLib.Hashing Tests\DelphiDoom.Tests.IdLib.Containers Tests\DelphiDoom.Tests.IdLib.Text Tests\DelphiDoom.Tests.IdLib.Math Tests\DelphiDoom.Tests.Ide Tests\DelphiDoom.Tests.Obituary Tests\DelphiDoom.Tests.Iwad Tests\DelphiDoom.Tests.Zone Tests\DelphiDoom.Tests.Platform Tests\DelphiDoom.Tests.Endoom Tests\DelphiDoom.Tests.Voxel Tests\DelphiDoom.Tests.Automap Tests\DelphiDoom.Tests.Actions Tests\DelphiDoom.Tests.Screenshot Tests\DelphiDoom.Tests.Nodes Tests\DelphiDoom.Tests.Blockmap Tests\DelphiDoom.Tests.Serializer Tests\DelphiDoom.Tests.TableExport Tests\DelphiDoom.Tests.Threading Tests\DelphiDoom.Tests.Thinkers Tests\DelphiDoom.Tests.Midi Tests\DelphiDoom.Tests.AsmParity Tests\DelphiDoom.Tests.Renderer Tests\DelphiDoom.Tests.Keen Tests\DelphiDoom.Tests.ToolsCore Tests\DelphiDoom.Tests.EndoomEditor Tests\DelphiDoom.Tests.GameData Tests\DelphiDoom.Tests.Speed Tests\DelphiDoom.Tests.Racing Tests\DelphiDoom.Tests.Radix Tests\DelphiDoom.Tests.ScriptHost Tests\DelphiDoom.Tests.Greed Tests\DelphiDoom.Tests.OpenGl Tests\DelphiDoom.Tests.Xcom Tests\DelphiDoom.Tests.Yaml Tests\DelphiDoom.Tests.XcomSurface Tests\DelphiDoom.Tests.XcomMod Tests\DelphiDoom.Tests.XcomSave Tests\DelphiDoom.Tests.Opl Tests\DelphiDoom.Tests.XcomEngine Tests\DelphiDoom.Tests.Font Tests\DelphiDoom.Tests.FontEditor Tests\DelphiDoom.Tests.VoxelEditor Tests\DelphiDoom.Tests.XcomBattle Tests\DelphiDoom.Tests.XcomGeoscape Tests\DelphiDoom.Tests.XcomStrategy Tests\DelphiDoom.Tests.XcomDebriefing Tests\DelphiDoom.Tests.XcomBattleStates Tests\DelphiDoom.Tests.XcomTour Tests\DelphiDoom.Tests.XcomUfopaedia Tests\DelphiDoom.Tests.Parity Tests\DelphiDoom.Tests.Hud Tests\DelphiDoom.Tests.InfoTables Tests\DelphiDoom.Tests.EngineSystem Tests\DelphiDoom.Tests.War"
set "LISTA="
if /i "%WHAT%"=="all"        set "LISTA=%LIBRERIE% %GIOCHI% %STRUMENTI%"
if /i "%WHAT%"=="librerie"   set "LISTA=%LIBRERIE%"
if /i "%WHAT%"=="tests"      set "LISTA=%LIBRERIE% %TESTS%"
if /i "%WHAT%"=="giochi"     set "LISTA=%GIOCHI%"
if /i "%WHAT%"=="strumenti"  set "LISTA=%STRUMENTI%"
if not defined LISTA (
  rem un solo progetto: se e' indicato per nome si cerca nella tabella
  set "LISTA=%WHAT%"
  for %%P in (%LIBRERIE% %GIOCHI% %STRUMENTI% %TESTS%) do (
    if /i "%%~nxP"=="%WHAT%" set "LISTA=%%P"
  )
)

rem --- Radice del repository: la cartella sopra Tools\ ----------------------
cd /d "%~dp0.."

rem --- Trova Delphi ---------------------------------------------------------
if not defined BDS_DIR (
  for %%V in (22.0 23.0 21.0 20.0) do (
    if not defined BDS_DIR if exist "%ProgramFiles(x86)%\Embarcadero\Studio\%%V\bin\rsvars.bat" set "BDS_DIR=%ProgramFiles(x86)%\Embarcadero\Studio\%%V"
    if not defined BDS_DIR if exist "%ProgramFiles%\Embarcadero\Studio\%%V\bin\rsvars.bat" set "BDS_DIR=%ProgramFiles%\Embarcadero\Studio\%%V"
  )
)
if not defined BDS_DIR (
  for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Embarcadero\BDS\22.0" /v RootDir 2^>nul ^| find "RootDir"') do set "BDS_DIR=%%B"
)
if not defined BDS_DIR (
  echo ERRORE: Delphi non trovato.
  echo Imposta BDS_DIR, ad esempio:
  echo    set BDS_DIR=C:\Program Files ^(x86^)\Embarcadero\Studio\22.0
  exit /b 2
)
if "%BDS_DIR:~-1%"=="\" set "BDS_DIR=%BDS_DIR:~0,-1%"
if not exist "%BDS_DIR%\bin\rsvars.bat" (
  echo ERRORE: "%BDS_DIR%\bin\rsvars.bat" non esiste.
  exit /b 2
)

call "%BDS_DIR%\bin\rsvars.bat"
echo Delphi: %BDS_DIR%
echo Configurazione: %CONFIG%, %PLATS%
echo Progetti: %LISTA%
echo.

if not exist logs mkdir logs
rem Forza l'aggiornamento di dimensioni/date dei file (cartelle condivise con una VM
rem possono restituire dimensioni vecchie e far vedere i sorgenti troncati)
echo Aggiornamento elenco file...
dir /s /a-d *.pas *.inc *.dpr *.dproj *.dfm *.res >nul 2>&1
if /i "%CLEAN%"=="clean" (
  if "%PLATS%"=="Win64" (
    echo Pulizia cartella dcu\Win64...
    if exist dcu\Win64 rd /s /q dcu\Win64
  ) else (
    echo Pulizia cartella dcu...
    if exist dcu rd /s /q dcu
  )
)

set "RCTOT=0"

for %%Q in (%PLATS%) do (
  set "PLAT=%%Q"
  set "OK="
  set "KO="
  if /i "%%Q"=="Win64" (
    set "PBIN=bin\Win64"
    set "PLOG=logs\Win64"
  ) else (
    set "PBIN=bin"
    set "PLOG=logs"
  )
  if not exist "!PLOG!" mkdir "!PLOG!"
  if exist "!PLOG!\_riepilogo_errori.txt" del "!PLOG!\_riepilogo_errori.txt"
  echo ################ %%Q ################
  echo.

  for %%P in (%LISTA%) do (
    if not exist "%%P.dproj" (
      echo [%%P] ERRORE: %%P.dproj non esiste.
      set "KO=!KO! %%P"
      set "RCTOT=1"
    ) else (
      echo ===== %%~nxP ^(%%Q^) =====
      msbuild "%%P.dproj" /t:Build /p:Config=%CONFIG% /p:Platform=%%Q /nologo /v:n /nr:false > "!PLOG!\%%~nxP.log" 2>&1
      if errorlevel 1 (
        findstr /R /B /C:"[A-Za-z].*: error [A-Z][0-9]" "!PLOG!\%%~nxP.log" | sort /unique
        echo [%%~nxP] FALLITA ^(%%Q^) - log: !PLOG!\%%~nxP.log
        set "KO=!KO! %%P"
        if /i "%%Q"=="Win32" set "RCTOT=1"
        set "PRIMO="
        for /f "delims=" %%E in ('findstr /R /C:"error [A-Z][0-9]" "!PLOG!\%%~nxP.log"') do if not defined PRIMO (
          set "PRIMO=1"
          >> "!PLOG!\_riepilogo_errori.txt" echo   %%~nxP: %%E
        )
        if not defined PRIMO >> "!PLOG!\_riepilogo_errori.txt" echo   %%~nxP: nessun errore di compilazione nel log, vedi !PLOG!\%%~nxP.log
      ) else (
        findstr /B /C:"    Avvisi" /C:"    Warning(s)" "!PLOG!\%%~nxP.log"
        echo [%%~nxP] OK
        set "OK=!OK! %%P"
      )
      echo.
    )
  )

  if /i "%WHAT%"=="tests" (
    rem I test cercano i dati con ..\..\Tests\Data a partire dalla cartella dell'exe: a 64 bit l'exe sta
    rem in bin\Win64\Tests e quel percorso diventa bin\Tests\Data, quindi si copia Tests\Data li' (solo i
    rem file mancanti o piu' vecchi; nessuna giunzione ne' link simbolico). bin e' ignorata da git.
    if /i "%%Q"=="Win64" robocopy "Tests\Data" "bin\Tests\Data" /E /NJH /NJS /NP /NFL /NDL >nul
    for %%T in (!PBIN!\Tests\DelphiDoom.Tests*.exe) do (
      echo ===== esecuzione %%~nxT ^(%%Q^) =====
      "%%T" --exitbehavior:Continue | findstr /B /C:"Tests " /C:"  DelphiDoom" /C:"  Message"
    )
  )
  set "OK_%%Q=!OK!"
  set "KO_%%Q=!KO!"
)

echo ---------------------------------------------------------------
for %%Q in (%PLATS%) do (
  echo [%%Q]
  if defined OK_%%Q (echo   Riuscite :!OK_%%Q!) else echo   Riuscite : nessuna
  if defined KO_%%Q (
    if /i "%%Q"=="Win64" (echo   Non ancora a 64 bit ^(primo errore di ciascuno; sbloccano #41, #42, #43^):) else echo   Fallite  :!KO_%%Q!
    if /i "%%Q"=="Win64" if exist logs\Win64\_riepilogo_errori.txt type logs\Win64\_riepilogo_errori.txt
  )
)
echo ---------------------------------------------------------------
exit /b %RCTOT%