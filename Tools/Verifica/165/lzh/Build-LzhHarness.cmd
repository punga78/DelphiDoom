@echo off
rem Compiles and links the harness of the LZH of Keen Dreams (issue #165, K12) with Open Watcom 16 bit.
rem   Build-LzhHarness.cmd <work folder>
rem The work folder already has lzharn.c and LZHUF_P.C (Run-LzhParity.ps1 makes them: LZHUF_P.C is lzhuf.c of
rem Reference\_dati\keen_build\src with INCLUDE_LZH_COMP 1). Nothing is written in Reference.
if "%~1"=="" (
  echo usage: Build-LzhHarness.cmd ^<work folder^>
  exit /b 2
)
call C:\Progetti\DelphiDoom\Reference\_dati\keen_build\ow_env.cmd
set SRC=C:\Progetti\DelphiDoom\Reference\_dati\keen_build\src
cd /d "%~1"
set INCLUDE=%INCLUDE%;%SRC%
wcc -bt=dos -mm -0 -od -ei -zp1 -s -zq -fo=lzharn.obj lzharn.c
if errorlevel 1 exit /b 1
(
echo system dos
echo name LZHARN.EXE
echo option quiet
echo option stack=0x2000
echo file lzharn.obj
echo file %SRC%\obj\jam_io.obj
echo file %SRC%\obj\borland.obj
) > lzh.lnk
wlink @lzh.lnk
