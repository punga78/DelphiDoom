@echo off
rem Builds RadixDiff.dpr (Win32) into out%1\ ; usage: build-diff.bat [suffix]   then: out%1\RadixDiff.exe RADIX.DAT golden.txt [-v]
cd /d "%~dp0"
if not exist out%1 mkdir out%1
if not exist dcu%1 mkdir dcu%1
set R=..\..\..
set L=%R%\Libs\Radix;%R%\Libs\GameData;%R%\Framework\Wad;%R%\Framework\Palette;%R%\Framework\Video;%R%\Framework\CommandLine;%R%\Framework\Scanner;%R%\Framework\Logging;%R%\Framework\MathCore;%R%\Framework\GameMath
"C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe" -B -Q -Eout%1 -NUdcu%1 -U"%L%" -I"%L%" -NSSystem;Winapi RadixDiff.dpr
