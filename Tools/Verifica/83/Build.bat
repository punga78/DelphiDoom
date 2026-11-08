@echo off
rem Compiles DumpOldMidi (the program that records the blocks of the old MIDI player).
rem Usage: Tools\Verifica\83\Build.bat   (from any folder)
rem Output: bin\Tools\Verifica\DumpOldMidi.exe ; log: logs\DumpOldMidi.log
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"
pushd "%~dp0"
if not exist "..\..\..\logs" mkdir "..\..\..\logs"
if not exist "..\..\..\bin\Tools\Verifica" mkdir "..\..\..\bin\Tools\Verifica"
if not exist "..\..\..\dcu\Verifica83" mkdir "..\..\..\dcu\Verifica83"
dcc32.exe -B -Q -E"..\..\..\bin\Tools\Verifica" -N0"..\..\..\dcu\Verifica83" ^
  -U"..\..\..\Libs\Logging;..\..\..\Libs\Audio;..\..\..\Tests\Source" ^
  -NS"Winapi;System;System.Win" DumpOldMidi.dpr > "..\..\..\logs\DumpOldMidi.log"
set RESULT=%ERRORLEVEL%
popd
exit /b %RESULT%
