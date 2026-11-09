@echo off
set PATH=C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin;%PATH%
set Y=C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\dl_src
cd /d %~dp0
g++ -O1 -std=c++17 -msse2 -mfpmath=sse -DYAML_CPP_STATIC_DEFINE -I%Y%\yaml-cpp-yaml-cpp-0.7.0\include harness.cpp %Y%\yaml-build\libyaml-cpp.a -o harness.exe
