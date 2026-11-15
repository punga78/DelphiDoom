<#
  Issue #197: compila sdl_raster_ref.c (il rasterizzatore software della SDL3 vera su scenari con seme fisso) con gcc a 32 bit.
  Uso:  powershell -NoProfile -File Compila-RasterRef.ps1 -Out <cartella nuova fuori dal repository>
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null
Copy-Item (Join-Path $War1 'deps\lib\win32\SDL3.dll') $Out
$exe = Join-Path $Out 'sdl_raster_ref.exe'
$ErrorActionPreference = 'Continue'
$log = & $Gcc -std=gnu11 -O1 -w "-I$(Join-Path $War1 'deps\include')" (Join-Path $PSScriptRoot 'sdl_raster_ref.c') -o $exe "-L$(Join-Path $War1 'deps\lib\win32')" -lSDL3 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $exe)) { $log; throw 'Compilazione fallita' }
"Compilato: $exe"
