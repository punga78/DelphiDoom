<#
  Issue #197: compila il remake ORIGINALE (acoto87/war1, zlib: src\war1.c intero, main rinominato) con gcc a 32 bit e la SDL3
  vera (Reference\war1\deps\lib\win32), e ci aggiunge il programma di prova war_frame_ref.c (renderer software su una
  superficie di 320 x 200, tempo e generatore fissi, ingresso da script). Niente e' modificato in Reference\: il programma e
  i file di dati stanno in -Out (una cartella NUOVA fuori da Reference e dal repository).

  Il programma cerca nella cartella corrente ./DATA.WAR, ./war1_font_1.png e ./war1_font_2.png: -Out li riceve in copia
  (DATA.WAR da -DataWar, i PNG dei font da Reference\war1\assets) e SDL3.dll.

  Uso:
    powershell -NoProfile -File Compila-FrameRef.ps1 -Out <cartella> [-DataWar <DATA.WAR>] [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>] [-Opt -O1]
  Poi, dentro -Out:  war_frame_ref.exe <script>
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR',
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe',
  [string]$Opt = '-O1'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null

Copy-Item (Join-Path $PSScriptRoot 'war_frame_ref.c') (Join-Path $Out 'war_frame_ref.c')
Copy-Item (Join-Path $War1 'deps\lib\win32\SDL3.dll') $Out
Copy-Item (Join-Path $War1 'assets\war1_font_1.png') $Out
Copy-Item (Join-Path $War1 'assets\war1_font_2.png') $Out
if (Test-Path $DataWar) { Copy-Item $DataWar (Join-Path $Out 'DATA.WAR') } else { Write-Warning "DATA.WAR non trovato: $DataWar" }

$exe = Join-Path $Out 'war_frame_ref.exe'
$flags = @('-std=gnu11', $Opt, '-Wno-misleading-indentation', '-w', "-I$(Join-Path $War1 'deps\include')", "-I$(Join-Path $War1 'src')")
$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
$log = & $Gcc @flags (Join-Path $Out 'war_frame_ref.c') -o $exe "-L$(Join-Path $War1 'deps\lib\win32')" -lSDL3 -lm -lws2_32 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $exe)) { $log; throw 'Compilazione fallita' }
"Compilato: $exe"
