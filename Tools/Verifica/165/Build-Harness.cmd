@echo off
rem Compiles and links the harness of the actions of Keen Dreams (issue #165, K8b) with Open Watcom 16 bit.
rem The objects of the game (kd_keen, kd_act1, kd_act2) are the ones of Reference\_dati\keen_build\src\obj.
call C:\Progetti\DelphiDoom\Reference\_dati\keen_build\ow_env.cmd
set SRC=C:\Progetti\DelphiDoom\Reference\_dati\keen_build\src
set OUT=C:\Progetti\DelphiDoom\Reference\_dati\keen_build\actions
if not exist %OUT% mkdir %OUT%
copy /y "%~dp0harness.c" %OUT%\ >nul
copy /y "%~dp0tbl.inc" %OUT%\ >nul
cd /d %OUT%
set INCLUDE=%INCLUDE%;%SRC%
wcc -bt=dos -mm -0 -od -ei -zp1 -s -zq -fo=harness.obj harness.c
if errorlevel 1 exit /b 1
(
echo system dos
echo name ACTHARN.EXE
echo option quiet
echo option stack=0x2000
echo file harness.obj
echo file %SRC%\obj\kd_keen.obj
echo file %SRC%\obj\kd_act1.obj
echo file %SRC%\obj\kd_act2.obj
) > act.lnk
wlink @act.lnk
