@echo off
rem ---------------------------------------------------------------------------
rem  Compila i progetti DelphiDoom con Delphi 11 (XE11) senza IDE.
rem
rem  Uso:   build.bat [progetto|all|giochi|strumenti] [Release|Debug] [clean]
rem
rem    build.bat                    Doom32, Release
rem    build.bat all                tutti i progetti
rem    build.bat giochi             i 8 eseguibili di gioco (software + OpenGL)
rem    build.bat strumenti          Launcher, DD_IDE, ddc e le 4 DLL ddc_*
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

set "GIOCHI=Doom32 GLDoom32 Heretic32 GLHeretic32 Hexen32 GLHexen32 Strife32 GLStrife32"
set "STRUMENTI=Launcher DD_IDE ddc ddc_doom ddc_heretic ddc_hexen ddc_strife"

set "LISTA="
if /i "%WHAT%"=="all"        set "LISTA=%GIOCHI% %STRUMENTI%"
if /i "%WHAT%"=="giochi"     set "LISTA=%GIOCHI%"
if /i "%WHAT%"=="strumenti"  set "LISTA=%STRUMENTI%"
if not defined LISTA set "LISTA=%WHAT%"

cd /d "%~dp0"

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
    echo ===== %%P =====
    msbuild "%%P.dproj" /t:Build /p:Config=%CONFIG% /p:Platform=Win32 /nologo /v:n /nr:false > "logs\%%P.log" 2>&1
    if errorlevel 1 (
      findstr /R /B /C:"[A-Za-z].*: error [A-Z][0-9]" "logs\%%P.log" | sort /unique
      echo [%%P] FALLITA - log: logs\%%P.log
      set "KO=!KO! %%P"
      set "RCTOT=1"
    ) else (
      findstr /B /C:"    Avvisi" /C:"    Warning(s)" "logs\%%P.log"
      echo [%%P] OK
      set "OK=!OK! %%P"
    )
    echo.
  )
)

echo ---------------------------------------------------------------
if defined OK echo Riuscite :%OK%
if defined KO echo Fallite  :%KO%
echo ---------------------------------------------------------------
exit /b %RCTOT%
