@echo off
rem Builds gfxharness.exe against the real SDL 1.2.15 and SDL_gfx of the OpenXcom dependencies (32 bit MinGW)
set PATH=C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin;%PATH%
set D=C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\deps
cd /d %~dp0
g++ -O1 -std=c++17 -w -I%D%\include\SDL gfxharness.cpp %D%\lib\Win32\libSDL_gfx.dll.a %D%\lib\Win32\libSDL.dll.a -static-libgcc -static-libstdc++ -o gfxharness.exe
copy /y %D%\bin\SDL.dll . >nul
copy /y %D%\bin\SDL_gfx.dll . >nul
