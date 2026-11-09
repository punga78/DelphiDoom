@echo off
set PATH=C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin;%PATH%
set O=C:\Progetti\DelphiDoom\Reference\OpenXcom\src
set D=C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\deps
set Y=C:\Progetti\DelphiDoom\Reference\_dati\openxcom_build\dl_src
cd /d %~dp0
g++ -O1 -std=c++17 -msse2 -mfpmath=sse -w -DYAML_CPP_STATIC_DEFINE -I%Y%\yaml-cpp-yaml-cpp-0.7.0\include -I%O% -I%D%\include\SDL savharness.cpp stubs.cpp %O%\Mod\RuleCountry.cpp %O%\Mod\RuleRegion.cpp %O%\Mod\RuleResearch.cpp %O%\Mod\City.cpp %O%\Savegame\Target.cpp %O%\Savegame\WeightedOptions.cpp %O%\Savegame\GameTime.cpp %O%\Savegame\Country.cpp %O%\Savegame\Region.cpp %O%\Savegame\ResearchProject.cpp %O%\Savegame\SerializationHelper.cpp %O%\Engine\RNG.cpp %Y%\yaml-build\libyaml-cpp.a -static-libgcc -static-libstdc++ -o savharness.exe

