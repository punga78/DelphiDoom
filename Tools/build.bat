@echo off
rem ---------------------------------------------------------------------------
rem  Compila i progetti DelphiDoom con Delphi 11 (XE11) senza IDE.
rem
rem  Uso:   Tools\build.bat [progetto|all|giochi|strumenti] [Release|Debug] [clean]
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
rem
rem  Cartelle (tutte dentro il progetto):
rem    bin\Doom, bin\Heretic, bin\Hexen, bin\Strife   eseguibili dei giochi
rem    bin\Tools                                      DD_IDE, ddc, ddc_*.dll
rem    bin                                            Launcher
rem    dcu\...\<Release|Debug>                        file .dcu
rem    logs\<progetto>.log                            log completo di ogni build
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
set "CLEAN=%~3"

set "GIOCHI=Doom\Doom32 Radix\Radix32 Speed\SpeedHaste32 Doom\GLDoom32 Heretic\Heretic32 Heretic\GLHeretic32 Hexen\Hexen32 Hexen\GLHexen32 Strife\Strife32 Strife\GLStrife32"
set "STRUMENTI=Launcher\Launcher DD_IDE\DD_IDE DD_Tools\DD_Tools Libs\Ddc\ddc Doom\ddc_doom Heretic\ddc_heretic Hexen\ddc_hexen Strife\ddc_strife Keen\Keen32 Greed\Greed32 Speed\Speed32 OpenXcom\Xcom32 Libs\Parity\ParityTool"
set "LIBRERIE=Libs\Zlib\DDZlib Libs\Jpeg\DDJpeg Libs\Mp3\DDMp3 Libs\Xmi\DDXmi Libs\Sndfile\DDSndfile Libs\Mikmod\DDMikmod Libs\Glbsp\DDGlbsp Libs\Png\DDPng Libs\Script\DDScript Libs\Wad\DDWad"
set "TESTS=Tests\DelphiDoom.Tests Tests\DelphiDoom.Tests.Jpeg Tests\DelphiDoom.Tests.Mp3 Tests\DelphiDoom.Tests.Xmi Tests\DelphiDoom.Tests.Sndfile Tests\DelphiDoom.Tests.Mikmod Tests\DelphiDoom.Tests.Glbsp Tests\DelphiDoom.Tests.M2m Tests\DelphiDoom.Tests.Ogg Tests\DelphiDoom.Tests.Png Tests\DelphiDoom.Tests.Script Tests\DelphiDoom.Tests.Wad Tests\DelphiDoom.Tests.IdTech Tests\DelphiDoom.Tests.CommandLine Tests\DelphiDoom.Tests.Configuration Tests\DelphiDoom.Tests.Logging Tests\DelphiDoom.Tests.Clock Tests\DelphiDoom.Tests.GameHost Tests\DelphiDoom.Tests.Input Tests\DelphiDoom.Tests.Video Tests\DelphiDoom.Tests.Audio Tests\DelphiDoom.Tests.Common Tests\DelphiDoom.Tests.Acs Tests\DelphiDoom.Tests.Udmf Tests\DelphiDoom.Tests.Specials Tests\DelphiDoom.Tests.Scanner Tests\DelphiDoom.Tests.Net Tests\DelphiDoom.Tests.MapInfo Tests\DelphiDoom.Tests.DynLights Tests\DelphiDoom.Tests.Dehacked Tests\DelphiDoom.Tests.ActorDef Tests\DelphiDoom.Tests.MusInfo Tests\DelphiDoom.Tests.TextureDefs Tests\DelphiDoom.Tests.Definitions Tests\DelphiDoom.Tests.Palette Tests\DelphiDoom.Tests.MathCore Tests\DelphiDoom.Tests.Console Tests\DelphiDoom.Tests.Imaging Tests\DelphiDoom.Tests.GlMath Tests\DelphiDoom.Tests.Models Tests\DelphiDoom.Tests.Texture Tests\DelphiDoom.Tests.Collision Tests\DelphiDoom.Tests.IdLib.Hashing Tests\DelphiDoom.Tests.IdLib.Containers Tests\DelphiDoom.Tests.IdLib.Text Tests\DelphiDoom.Tests.IdLib.Math Tests\DelphiDoom.Tests.Ide Tests\DelphiDoom.Tests.Obituary Tests\DelphiDoom.Tests.Iwad Tests\DelphiDoom.Tests.Zone Tests\DelphiDoom.Tests.Platform Tests\DelphiDoom.Tests.Endoom Tests\DelphiDoom.Tests.Voxel Tests\DelphiDoom.Tests.Automap Tests\DelphiDoom.Tests.Actions Tests\DelphiDoom.Tests.Screenshot Tests\DelphiDoom.Tests.Nodes Tests\DelphiDoom.Tests.Blockmap Tests\DelphiDoom.Tests.Serializer Tests\DelphiDoom.Tests.TableExport Tests\DelphiDoom.Tests.Threading Tests\DelphiDoom.Tests.Thinkers Tests\DelphiDoom.Tests.Midi Tests\DelphiDoom.Tests.AsmParity Tests\DelphiDoom.Tests.Renderer Tests\DelphiDoom.Tests.Keen Tests\DelphiDoom.Tests.ToolsCore Tests\DelphiDoom.Tests.EndoomEditor Tests\DelphiDoom.Tests.GameData Tests\DelphiDoom.Tests.Speed Tests\DelphiDoom.Tests.Racing Tests\DelphiDoom.Tests.Radix Tests\DelphiDoom.Tests.ScriptHost Tests\DelphiDoom.Tests.Greed Tests\DelphiDoom.Tests.OpenGl Tests\DelphiDoom.Tests.Xcom Tests\DelphiDoom.Tests.Yaml Tests\DelphiDoom.Tests.XcomSurface Tests\DelphiDoom.Tests.XcomMod Tests\DelphiDoom.Tests.XcomSave Tests\DelphiDoom.Tests.Opl Tests\DelphiDoom.Tests.XcomEngine Tests\DelphiDoom.Tests.Font Tests\DelphiDoom.Tests.FontEditor Tests\DelphiDoom.Tests.VoxelEditor Tests\DelphiDoom.Tests.XcomBattle Tests\DelphiDoom.Tests.XcomGeoscape Tests\DelphiDoom.Tests.XcomStrategy Tests\DelphiDoom.Tests.XcomDebriefing Tests\DelphiDoom.Tests.XcomBattleStates Tests\DelphiDoom.Tests.XcomTour Tests\DelphiDoom.Tests.XcomUfopaedia Tests\DelphiDoom.Tests.Parity Tests\DelphiDoom.Tests.Hud"
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
echo Configurazione: %CONFIG%, Win32
echo Progetti: %LISTA%
echo.

if not exist logs mkdir logs
rem Forza l'aggiornamento di dimensioni/date dei file (cartelle condivise con una VM
rem possono restituire dimensioni vecchie e far vedere i sorgenti troncati)
echo Aggiornamento elenco file...
dir /s /a-d *.pas *.inc *.dpr *.dproj *.dfm *.res >nul 2>&1
if /i "%CLEAN%"=="clean" (
  echo Pulizia cartella dcu...
  if exist dcu rd /s /q dcu
)

set "OK="
set "KO="
set "RCTOT=0"

for %%P in (%LISTA%) do (
  if not exist "%%P.dproj" (
    echo [%%P] ERRORE: %%P.dproj non esiste.
    set "KO=!KO! %%P"
    set "RCTOT=1"
  ) else (
    echo ===== %%~nxP =====
    msbuild "%%P.dproj" /t:Build /p:Config=%CONFIG% /p:Platform=Win32 /nologo /v:n /nr:false > "logs\%%~nxP.log" 2>&1
    if errorlevel 1 (
      findstr /R /B /C:"[A-Za-z].*: error [A-Z][0-9]" "logs\%%~nxP.log" | sort /unique
      echo [%%~nxP] FALLITA - log: logs\%%~nxP.log
      set "KO=!KO! %%P"
      set "RCTOT=1"
    ) else (
      findstr /B /C:"    Avvisi" /C:"    Warning(s)" "logs\%%~nxP.log"
      echo [%%~nxP] OK
      set "OK=!OK! %%P"
    )
    echo.
  )
)

if /i "%WHAT%"=="tests" (
  for %%T in (bin\Tests\DelphiDoom.Tests*.exe) do (
    echo ===== esecuzione %%~nxT =====
    "%%T" --exitbehavior:Continue | findstr /B /C:"Tests " /C:"  DelphiDoom" /C:"  Message"
  )
)
echo ---------------------------------------------------------------
if defined OK echo Riuscite :%OK%
if defined KO echo Fallite  :%KO%
echo ---------------------------------------------------------------
exit /b %RCTOT%
