@echo off
rem Builds lbmharness.exe against the real SDL 1.2.15 and SDL_image 1.2.12 (32 bit MinGW)
set PATH=C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin;%PATH%
set D=C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\deps
cd /d %~dp0
g++ -O1 -std=c++17 -w -I%D%\include\SDL lbmharness.cpp %D%\lib\Win32\libSDL_image.a %D%\lib\Win32\libSDL.dll.a -static-libgcc -static-libstdc++ -o lbmharness.exe
copy /y C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\openxcom_nightly\SDL.dll . >nul
copy /y C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\openxcom_nightly\SDL_image.dll . >nul
