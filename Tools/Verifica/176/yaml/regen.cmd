@echo off
rem Rebuilds harness.exe (yaml-cpp 0.7.0 itself, see build.cmd) and rewrites the golden files of Libs\Yaml
rem from the corpus files in Tests\Data\Yaml. The stdout of the harness is binary (LF line ends, no BOM)
call "%~dp0build.cmd"
if errorlevel 1 exit /b 1
set D=%~dp0..\..\..\..\Tests\Data\Yaml
"%~dp0harness.exe" run "%D%\corpus.txt" > "%D%\parse.golden.txt"
if exist "%D%\emit_strings.corpus.txt" "%~dp0harness.exe" emitstrings > "%D%\emit_strings.golden.txt"
echo done
