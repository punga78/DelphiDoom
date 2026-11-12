@echo off
rem Compiles and links the harness of the AdLib sound effects of Keen Dreams (issue #165, K10) with Open Watcom 16 bit.
rem   Build-AudioHarness.cmd <work folder>
rem The work folder already has sdharn.c and ID_SD_P.C (Run-AudioParity.ps1 makes them: ID_SD_P.C is id_sd.c of
rem Reference\_dati\keen_build\src with alOut renamed, see sdharn.c). Nothing is written in Reference.
if "%~1"=="" (
  echo usage: Build-AudioHarness.cmd ^<work folder^>
  exit /b 2
)
call C:\Progetti\DelphiDoom\Reference\_dati\keen_build\ow_env.cmd
set SRC=C:\Progetti\DelphiDoom\Reference\_dati\keen_build\src
cd /d "%~1"
set INCLUDE=%INCLUDE%;%SRC%
wcc -bt=dos -mm -0 -od -ei -zp1 -s -zq -fo=sdharn.obj sdharn.c
if errorlevel 1 exit /b 1
(
echo system dos
echo name SDHARN.EXE
echo option quiet
echo option stack=0x2000
echo file sdharn.obj
echo file %SRC%\obj\borland.obj
) > sd.lnk
wlink @sd.lnk
