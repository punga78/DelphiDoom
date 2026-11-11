@echo off
rem Builds simgen.exe linking the REAL OpenXcom objects of the build in Reference\_dati\openxcom_build (without main).
rem usage: build6.cmd <output folder>   (the folder also gets the SDL dlls and obj.a, the objects without main.cpp.obj)
set PATH=C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin;%PATH%
set B=C:/Progetti/DelphiDoom/Reference/_dati/openxcom_build
set O=%1
if not exist %O% mkdir %O%
if not exist %O%\obj.a (
  copy %B:/=\%\build\src\CMakeFiles\openxcom.dir\objects.a %O%\obj.a >nul
  ar d %O%\obj.a main.cpp.obj
  copy %B:/=\%\build\bin\*.dll %O% >nul
)
g++ -O1 -std=c++11 -w -DGIT_BUILD=1 -DYAML_CPP_DLL -I%B%/build -IC:/Progetti/DelphiDoom/Reference/OpenXcom/src -isystem %B%/deps/include/SDL -isystem %B%/deps/include/yaml-cpp -isystem %B%/deps/include %~dp0simgen.cpp -Wl,--whole-archive %O%\obj.a -Wl,--no-whole-archive -L%B%/deps/lib/Win32 -ldbghelp -ladvapi32 -lshell32 -lshlwapi -lmingw32 -static -lSDL_image -lSDL_mixer -lwinmm -lSDL_gfx -lSDL -lopengl32 -lglu32 -lyaml-cpp -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 -o %O%\simgen.exe
