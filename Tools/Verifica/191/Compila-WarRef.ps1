<#
  Issue #191: compila il codice ORIGINALE del remake (acoto87/war1, zlib) che legge DATA.WAR e lo fa girare
  su un DATA.WAR vero per produrre i golden di Libs\War. Niente e' modificato in Reference\: si leggono i
  sorgenti e si scrivono estratti e programma in -Out (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-WarRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]

  Estrae alla lettera (per intervalli di righe cercati per testo, non per numero):
    war_file.c   : da "// Safe little-endian integer reads" (le due letture) a prima di "// .w1m custom map loading"  -> war_core.inc
    war_resources.h: da "struct _WarRawResource" a prima di "struct _WarLevelUnit"           -> war_types.inc
    war_enums.h  : da "typedef enum" a "} DatabaseEntryType;"                               -> war_enums.inc
    war_database.h: copia intera, senza le due #include                                      -> war_database_copy.h
  e compila war_ref.c con gcc (w64devkit, 32 bit). Non esegue nulla dei dati.
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe'
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null

function Slice([string]$File, [string]$From, [string]$Before) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber - 1
  $b = ($lines | Select-String -SimpleMatch $Before | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0 -or $b -le $a) { throw "Intervallo non trovato in ${File}: $From .. $Before" }
  $lines[$a..($b - 1)]
}
$src = Join-Path $War1 'src'
Slice (Join-Path $src 'war_file.c') '// Safe little-endian integer reads' '// .w1m custom map loading' | Set-Content (Join-Path $Out 'war_core.inc') -Encoding ASCII
Slice (Join-Path $src 'war_resources.h') 'struct _WarRawResource' 'struct _WarLevelUnit' | Set-Content (Join-Path $Out 'war_types.inc') -Encoding ASCII
$enum = [IO.File]::ReadAllLines((Join-Path $src 'war_enums.h'))
$e0 = ($enum | Select-String -SimpleMatch 'typedef enum' | Select-Object -First 1).LineNumber - 1
$e1 = ($enum | Select-String -SimpleMatch '} DatabaseEntryType;' | Select-Object -First 1).LineNumber - 1
$enum[$e0..$e1] | Set-Content (Join-Path $Out 'war_enums.inc') -Encoding ASCII
[IO.File]::ReadAllLines((Join-Path $src 'war_database.h')) | Where-Object { $_ -notmatch '^#include|^#pragma once' } |
  Set-Content (Join-Path $Out 'war_database_copy.h') -Encoding ASCII
Copy-Item (Join-Path $PSScriptRoot 'war_ref.c') (Join-Path $Out 'war_ref.c')

# la struct WarFile del remake e' dichiarata con "struct _WarFile"; war_types.inc comincia da _WarRawResource
$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_ref.exe') (Join-Path $Out 'war_ref.c') "-I$Out" -Wno-unused-function 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_ref.exe')"
