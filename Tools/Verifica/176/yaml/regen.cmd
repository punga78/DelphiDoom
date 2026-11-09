@echo off
rem Rebuilds harness.exe (yaml-cpp 0.7.0 itself, see build.cmd) and rewrites the corpora and the golden files
rem of Libs\Yaml in Tests\Data\Yaml. The stdout of the harness is binary (LF line ends, no BOM).
rem   parse:   gen: handwritten.txt + 600 random documents (seed 176) + escapes and encodings -> corpus.txt,
rem            run: corpus.txt -> parse.golden.txt
rem   emitter: emit-gen (fixed seed) -> emit_*.corpus.txt, emit-run -> emit_*.golden.txt
call "%~dp0build.cmd"
if errorlevel 1 exit /b 1
set D=%~dp0..\..\..\..\Tests\Data\Yaml
"%~dp0harness.exe" gen "%~dp0handwritten.txt" "%D%\corpus.txt" 600 176
"%~dp0harness.exe" run "%D%\corpus.txt" > "%D%\parse.golden.txt"
"%~dp0harness.exe" emit-gen "%D%"
for %%N in (strings values settings random) do "%~dp0harness.exe" emit-run "%D%\emit_%%N.corpus.txt" > "%D%\emit_%%N.golden.txt"
echo done
