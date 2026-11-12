<#
  Makes the golden file of the LZH of Keen Dreams from the original C (issue #165, K12):
    1. lzhuf.c of Reference\_dati\keen_build\src is copied to the work folder as LZHUF_P.C with two changes, both
       in the compressor (that the game does not use; the expansion is not touched): the switch INCLUDE_LZH_COMP
       is 1, so it is compiled, and the pointer "key" of InsertNode is far like the window it points to;
    2. Build-LzhHarness.cmd compiles lzharn.c with Open Watcom and links it with the original jam_io object;
    3. DOSBox runs LZHARN.EXE: it compresses seven made up buffers, writes the compressed bytes and expands them
       again with the original lzhDecompress ("same" on each D line);
    4. OUT.TXT becomes Tests\Data\Keen\lzh.golden.txt (LF line ends).
  The work folder is outside the repository and outside Reference (default: %TEMP%\keen165-lzh).
#>
param([string]$Work = (Join-Path $env:TEMP 'keen165-lzh'), [int]$Seconds = 240)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$src = 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\src'
if (-not (Test-Path $Work)) { New-Item -ItemType Directory $Work | Out-Null }
Copy-Item (Join-Path $PSScriptRoot 'lzharn.c') $Work -Force
$text = [IO.File]::ReadAllText((Join-Path $src 'lzhuf.c'), [Text.Encoding]::GetEncoding(437))
$needle = '#define INCLUDE_LZH_COMP'
$at = $text.IndexOf($needle)
if ($at -lt 0) { throw 'INCLUDE_LZH_COMP was not found in lzhuf.c' }
$end = $text.IndexOf("`n", $at)
$text = $text.Substring(0, $at) + '#define INCLUDE_LZH_COMP 1' + $text.Substring($end - 1)
# the match finder of the compressor keeps a near pointer to the far window (it was made for a tool built with far
# data): in the memory model of the game it reads other memory and the compressor finds matches that are not there
$key = "unsigned char  *key;"
if ($text.IndexOf($key) -lt 0) { throw 'the key pointer of InsertNode was not found in lzhuf.c' }
$text = $text.Replace($key, 'unsigned char far *key;')
[IO.File]::WriteAllText((Join-Path $Work 'LZHUF_P.C'), $text, [Text.Encoding]::GetEncoding(437))
$ErrorActionPreference = 'Continue'
cmd /c "`"$(Join-Path $PSScriptRoot 'Build-LzhHarness.cmd')`" `"$Work`"" 2>&1 | Write-Host
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Work 'LZHARN.EXE'))) { throw 'the harness was not built' }
if (Test-Path (Join-Path $Work 'OUT.TXT')) { Remove-Item (Join-Path $Work 'OUT.TXT') }
& powershell -NoProfile -File 'C:\Progetti\DelphiDoom\Reference\_dati\keen_build\dosrun.ps1' -Dir $Work -Cmd 'LZHARN.EXE > OUT.TXT' -Seconds $Seconds
$out = [IO.File]::ReadAllText((Join-Path $Work 'OUT.TXT'), [Text.Encoding]::ASCII).Replace("`r`n", "`n")
if ($out -match '(?m)^QUIT' -or $out -match 'DIFFERENT' -or -not $out.TrimEnd().EndsWith('E')) { throw 'the harness did not end well' }
[IO.File]::WriteAllText((Join-Path $root 'Tests\Data\Keen\lzh.golden.txt'), $out)
'cases: ' + ([regex]::Matches($out, '(?m)^C ')).Count
