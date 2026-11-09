@echo off
rem Compila HarnessVoxel con Delphi 11 (dcc32): prima eseguire prepare.ps1 ed extract.ps1
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"
set H=%~dp0
set REF=%H%..\..\..\Reference\DD_VOXEL
if not exist "%H%build\dcu" mkdir "%H%build\dcu"
cd /d "%H%"
dcc32 -B -Q -E"%H%build" -N0"%H%build\dcu" -U"%H%build;%H%;%REF%" -I"%REF%" -NSSystem;Winapi;Vcl;Vcl.Imaging;System.Win;Data -$Q- -$R- HarnessVoxel.dpr
