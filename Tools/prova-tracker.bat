@echo off
rem Prova del tracker in Pascal (musica dei moduli MOD, S3M, XM, IT) dentro il gioco.
rem
rem   prova-tracker.bat [doom|heretic] [mod|s3m|xm|it|<file-di-un-modulo>] [altri parametri del gioco]
rem
rem Genera i brani di prova (o usa il modulo indicato), li mette in un WAD che sostituisce
rem la musica del livello 1 (o dei livelli 1..4) e avvia il gioco con -tracker.
rem Nessuno dei WAD originali contiene moduli: servono questi.
rem
rem   Brani di prova: livello 1 = MOD, 2 = S3M, 3 = XM, 4 = IT (E1M1..E1M4).
rem   Con un file, il livello 1 suona quel file.
rem Per confrontare con MikWin basta avviare il gioco senza -tracker.
setlocal
set "GIOCO=%~1"
if "%GIOCO%"=="" set "GIOCO=doom"
set "SCELTA=%~2"
if "%SCELTA%"=="" set "SCELTA=mod"
set "RADICE=%~dp0.."
set "USCITA=%RADICE%\bin\Tracker"

where python >nul 2>nul
if errorlevel 1 (
  echo Serve Python nel PATH per generare i brani di prova.
  exit /b 1
)

set "LIVELLO=1"
if exist "%SCELTA%" (
  python "%~dp0Tracker\MakeTestSongs.py" "%USCITA%" "%SCELTA%"
) else (
  python "%~dp0Tracker\MakeTestSongs.py" "%USCITA%"
  if /i "%SCELTA%"=="s3m" set "LIVELLO=2"
  if /i "%SCELTA%"=="xm" set "LIVELLO=3"
  if /i "%SCELTA%"=="it" set "LIVELLO=4"
)
if errorlevel 1 exit /b 1

rem I parametri dopo il secondo vanno al gioco
shift
shift
set "ALTRI="
:raccogli
if "%~1"=="" goto avvia
set "ALTRI=%ALTRI% %1"
shift
goto raccogli

:avvia
if /i "%GIOCO%"=="heretic" goto heretic
cd /d "%RADICE%\bin\Doom"
echo Doom: livello %LIVELLO%
start "" Doom32.exe -iwad doom1.wad -file ..\Tracker\TRACKER_DOOM.WAD -tracker -warp 1 %LIVELLO% -nomonsters%ALTRI%
goto fine

:heretic
cd /d "%RADICE%\bin\Heretic"
echo Heretic: livello %LIVELLO%
start "" Heretic32.exe -iwad heretic1.wad -file ..\Tracker\TRACKER_HERETIC.WAD -tracker -warp 1 %LIVELLO% -nomonsters%ALTRI%

:fine
endlocal
