@echo off
rem Spike #173: RegisterDelphiMethod a 32 e 64 bit (programma console fuori dal motore).
rem Compila con dcc32 e dcc64 e lascia gli eseguibili in out32\ e out64\ (non committati).
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"
set R=%~dp0..\..\..\..
set S=%R%\Libs\Script\Shim;%R%\Libs\PascalScript
set H=%~dp0
if not exist "%H%out32" mkdir "%H%out32"
if not exist "%H%out64" mkdir "%H%out64"
cd /d "%H%"
dcc32 -Q -B -NSSystem;Winapi;System.Win -U"%S%" -I"%S%" -O"%S%" -N0"%H%out32" -E"%H%out32" Spike173.dpr > build32.log 2>&1
dcc64 -Q -B -NSSystem;Winapi;System.Win -U"%S%" -I"%S%" -O"%S%" -N0"%H%out64" -E"%H%out64" Spike173.dpr > build64.log 2>&1
