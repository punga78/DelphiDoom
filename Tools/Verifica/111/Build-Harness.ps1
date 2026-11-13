# Harness of the gui of Doom 3 (issue #111): compiles the real ui\Window.cpp, Winvar.h, RegExp.cpp, GuiScript.cpp,
# SimpleWindow.cpp, ChoiceWindow.cpp, SliderWindow.cpp, BindWindow.cpp, FieldWindow.cpp and the methods of
# idUserInterfaceLocal of UserInterface.cpp (InitFromFile, RunTimeEvents, Activate...) with idlib, and runs the scenarios.
#
#   Build-Harness.ps1 -Neo <Reference\doom3\neo> -Work <work folder> [-Scenarios Tests\Data\Gui\window\window.input.txt] [-Output golden.txt]
#
# Nothing of Doom 3 is copied into the repository: the copy of neo\idlib, ui, framework and renderer is made in the work
# folder and patched there. Written for the test: harness\driver.cpp.txt, ui_stubs.h.txt, stubs.cpp.txt (and
# the precompiled.h of Tests\Data\Decl\harness\material, edited below). Compiler: bcc32c of Delphi 11 (clang, 32 bit,
# without -std=c++14).
param(
  [Parameter(Mandatory = $true)][string]$Neo,
  [Parameter(Mandatory = $true)][string]$Work,
  [string]$Scenarios = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\Gui\window\window.input.txt'),
  [string]$Output = (Join-Path $Work 'golden.txt')
)
$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$B = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
$H = Join-Path $PSScriptRoot 'harness'
New-Item -ItemType Directory -Force "$Work\neo", "$Work\obj" | Out-Null
foreach ($d in 'idlib', 'framework', 'renderer', 'ui') { robocopy "$Neo\$d" "$Work\neo\$d" /E /NFL /NDL /NJH /NJS /NP | Out-Null }
$i = "$Work\neo\idlib"; $u = "$Work\neo\ui"

function Patch($file, [scriptblock]$edit) { $t = [IO.File]::ReadAllText($file); $t = & $edit $t; [IO.File]::WriteAllText($file, $t) }

# idlib: the same changes as the harness of the declarations (Tests\Data\Decl\README.md)
Patch "$i\Str.cpp" { param($t) $t.Replace('static idDynamicBlockAlloc<char, 1<<18, 128>	stringDataAllocator;', 'struct StubAlloc { char *Alloc(int n){return (char*)malloc(n);} void Free(char*p){free(p);} void Init(){} void Shutdown(){} void FreeEmptyBaseBlocks(){} int GetBaseBlockMemory(){return 0;} int GetFreeBlockMemory(){return 0;} int GetNumFreeBlocks(){return 0;} int GetNumEmptyBaseBlocks(){return 0;} }; static StubAlloc stringDataAllocator;') }
Patch "$i\Parser.cpp" { param($t) ($t -replace 'token\[7\] = ''\\0'';', '' -replace 'token\[10\] = ''\\0'';', '' -replace 'token\[8\] = ''\\0'';', '' -replace 'free\(curtime\);', '') }
Patch "$i\CmdArgs.cpp" { param($t) ($t -replace 'if \( idLib::cvarSystem \) \{\s*token = idLib::cvarSystem->GetCVarString\( token.c_str\(\) \);\s*\}', '') }
Patch "$i\math\Simd_Generic.cpp" { param($t) $t.Replace('register double', 'double') }
Patch "$i\hashing\MD5.cpp" { param($t) $t.Replace('register unsigned', 'unsigned') }
Patch "$i\Token.h" { param($t) $t -replace 'ID_INLINE idToken::idToken\( void \) \{\s*\}', 'ID_INLINE idToken::idToken( void ) { type = 0; subtype = 0; line = 0; linesCrossed = 0; flags = 0; intvalue = 0; floatvalue = 0; }' }

# precompiled.h of the harness of the declarations, without the material, with the stubs of the ui
$p = [IO.File]::ReadAllText((Join-Path $repo 'Tests\Data\Decl\harness\material\precompiled.h.txt'))
$p = $p.Replace('#include "../renderer/Material.h"', '')
$p = $p.Replace('#include "Str.h"', "#include `"Str.h`"`r`n#include `"bv/Sphere.h`"`r`n#include `"bv/Bounds.h`"")
$p = $p.Replace('class idCommon { public:', 'class idLangDict; class idCommon { public: idLangDict *GetLanguageDict();')
$p = $p.Replace('bool GetBool() const {return b;}', 'bool GetBool() const {return b;} const char *GetString() const {return "";} void SetString(const char *) {} float GetFloat() const {return 0;} void SetFloat(float) {} void SetInteger(int) {} void SetBool(bool) {}')
$idx = $p.LastIndexOf('#endif'); $p = $p.Substring(0, $idx) + "#include `"ui_stubs.h`"`r`n#endif"
[IO.File]::WriteAllText("$i\precompiled.h", $p)

# the fonts of RenderSystem.h that DeviceContext.h needs
$rs = Get-Content "$Work\neo\renderer\RenderSystem.h"
$start = ($rs | Select-String 'const int GLYPH_START').LineNumber - 1; $end = ($rs | Select-String '} fontInfoEx_t;').LineNumber - 1
$fonts = ($rs[$start..$end]) -join "`r`n"
[IO.File]::WriteAllText("$i\ui_stubs.h", ([IO.File]::ReadAllText("$H\ui_stubs.h.txt")).Replace('//@FONTS@', $fonts))
Copy-Item "$H\driver.cpp.txt" "$i\driver.cpp"; Copy-Item "$H\stubs.cpp.txt" "$i\stubs.cpp"

# the abstract idDeclManager: the pure virtual functions become empty
Patch "$Work\neo\framework\DeclManager.h" { param($t) $m = [regex]::Match($t, '(?s)class idDeclManager \{.*?\r?\n\};'); $t.Replace($m.Value, ($m.Value -replace '\) = 0;', ') {}' -replace '\) const = 0;', ') const {}')) }

# ui: the windows that are not compared (the game windows, list, marker, render and edit windows) are cut out of Window.cpp
Patch "$u\Window.cpp" { param($t)
  $t = [regex]::Replace($t, '(?s)else if \( token == "(game(SSD|BearShoot|BustOut)Def|listDef|markerDef|renderDef|editDef)" \) \{.*?\r?\n\t\t\}', '')
  $t = [regex]::Replace($t, '#include "Game\w+Window.h"\r?\n', '')
  $t.Replace('#include "ListWindow.h"', '').Replace('#include "RenderWindow.h"', '').Replace('#include "MarkerWindow.h"', '').Replace('#include "EditWindow.h"', '').Replace('#include "../tools/guied/GEWindowWrapper.h"', '') }

# the methods of idUserInterfaceLocal from the constructor to Trigger, cut from the real UserInterface.cpp
$ui = Get-Content "$u\UserInterface.cpp"
$first = ($ui | Select-String 'idUserInterfaceLocal::idUserInterfaceLocal\(\) \{').LineNumber - 1
$last = ($ui | Select-String 'void idUserInterfaceLocal::ReadFromDemoFile').LineNumber - 3
$ui[$first..$last] | Set-Content "$i\ui_extract.inc"

function Compile($f) {
  $dir = Split-Path $f -Parent; $name = [IO.Path]::GetFileNameWithoutExtension($f)
  Push-Location "$Work\neo\$dir"
  $o = "$Work\obj\" + ($dir -replace '\\', '_') + "_$name.o"
  $ErrorActionPreference = 'Continue'
  $out = & $B -c -w- -D_HAS_NOEXCEPT_FUNCTION_TYPE=0 -I..\idlib "-o$o" "$name.cpp" 2>&1
  if ($LASTEXITCODE -ne 0) { Write-Host "== $f FAILED"; $out | Select-String 'error' | Select-Object -First 10 | ForEach-Object { $_.Line }; throw "compile $f" }
  Pop-Location
}
$files = 'idlib\driver', 'idlib\stubs', 'idlib\Str', 'idlib\Token', 'idlib\Lexer', 'idlib\Parser', 'idlib\CmdArgs', 'idlib\Dict', 'idlib\Heap', 'idlib\BitMsg', 'idlib\LangDict',
  'idlib\math\Math', 'idlib\math\Vector', 'idlib\math\Matrix', 'idlib\math\Angles', 'idlib\math\Quat', 'idlib\math\Rotation', 'idlib\math\Plane', 'idlib\math\Pluecker', 'idlib\math\Polynomial',
  'idlib\math\Complex', 'idlib\math\Simd_Generic', 'idlib\hashing\CRC32', 'idlib\hashing\MD5', 'idlib\containers\HashIndex', 'idlib\geometry\JointTransform',
  'ui\Winvar', 'ui\RegExp', 'ui\GuiScript', 'ui\Window', 'ui\SimpleWindow', 'ui\ChoiceWindow', 'ui\SliderWindow', 'ui\BindWindow', 'ui\FieldWindow'
foreach ($f in $files) { Compile $f }
$objs = Get-ChildItem "$Work\obj\*.o" | ForEach-Object { $_.FullName }
$ErrorActionPreference = 'Continue'
& $B -o "$Work\gui.exe" @objs 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'
if (-not (Test-Path "$Work\gui.exe")) { throw 'link' }
& "$Work\gui.exe" $Scenarios > $Output
Write-Host "exit $LASTEXITCODE, $((Get-Content $Output).Count) lines in $Output"
