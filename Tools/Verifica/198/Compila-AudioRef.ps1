<#
  Issue #198: compila il codice ORIGINALE del remake (acoto87/war1, zlib; shl/voc.h, wav.h e xmi2mid.h sono MIT) che
  carica i suoni e la musica di DATA.WAR e mixa i suoni, e lo fa girare per produrre i golden di Libs\War
  (parte audio). Niente e' modificato in Reference\: si leggono i sorgenti e si scrivono estratti e programma in -Out
  (una cartella NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-AudioRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]

  Estrae alla lettera (per intervalli di righe cercati per testo, non per numero):
    war_file.c      : letture little endian, wfile_loadWarFile, wfile_freeWarFile      -> war_core.inc   (come #191)
    war_resources.h : le struct di WarResource                                         -> war_types.inc, war_types2.inc
    war_enums.h     : DatabaseEntryType, WarResourceType, WarAudioId e WarAudioType
    war_database.h  : copia intera senza le #include
    war_sprite_frame: struct _WarSpriteFrame (WarResource la contiene)
    war_resources.c : #define readXX; da "static void buildRgbaLut" a "s32 wres_loadStartEntities" (serve
                      wres_getOrCreateResource); da "void wres_loadXmi" a "void wres_loadCursor" (XMI, WAVE, VOC)
    war_audio.h     : struct _WarAudioComponent
    war_audio.c     : bool wa_playWave
    war_math.c      : vec2_distanceSqr/vec2_distance, rect_containsf, rect_center
    war.h           : le #define delle costanti usate
  e compila war_audio_ref.c con gcc (w64devkit), con -I<War1>\deps\include per i tre convertitori. Non esegue nulla.
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
  $rest = $lines[($a + 1)..($lines.Count - 1)]
  $bHit = $rest | Select-String -SimpleMatch $Before | Select-Object -First 1
  if ($a -lt 0 -or -not $bHit) { throw "Intervallo non trovato in ${File}: $From .. $Before" }
  $b = $a + 1 + $bHit.LineNumber - 1
  $lines[$a..($b - 1)]
}
function Put([string]$Name, $Lines) { $Lines | Set-Content (Join-Path $Out $Name) -Encoding ASCII }

$src = Join-Path $War1 'src'
Put 'war_core.inc' (Slice (Join-Path $src 'war_file.c') '// Safe little-endian integer reads' '// .w1m custom map loading')
Put 'war_types.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarRawResource' 'struct _WarLevelUnit')
Put 'war_types2.inc' (Slice (Join-Path $src 'war_resources.h') 'struct _WarLevelUnit' 'WarResource* wres_getOrCreateResource')
$enums = Join-Path $src 'war_enums.h'
$enum = [IO.File]::ReadAllLines($enums)
$e0 = ($enum | Select-String -SimpleMatch 'typedef enum' | Select-Object -First 1).LineNumber - 1
$e1 = ($enum | Select-String -SimpleMatch '} DatabaseEntryType;' | Select-Object -First 1).LineNumber - 1
Put 'war_enums.inc' $enum[$e0..$e1]
$r0 = ($enum | Select-String -SimpleMatch 'typedef enum _WarResourceType' | Select-Object -First 1).LineNumber - 1
$r1 = ($enum | Select-String -SimpleMatch '} WarResourceType;' | Select-Object -First 1).LineNumber - 1
Put 'war_resource_type.inc' $enum[$r0..$r1]
$a0 = ($enum | Select-String -SimpleMatch 'typedef enum _WarAudioId' | Select-Object -First 1).LineNumber - 1
$a1 = ($enum | Select-String -SimpleMatch '} WarAudioType;' | Select-Object -First 1).LineNumber - 1
Put 'war_audio_enums.inc' $enum[$a0..$a1]
Put 'war_database_copy.h' ([IO.File]::ReadAllLines((Join-Path $src 'war_database.h')) | Where-Object { $_ -notmatch '^#include|^#pragma once' })
Put 'war_sprite_frame.inc' (Slice (Join-Path $src 'war_sprites.h') 'struct _WarSpriteFrame' 'struct _WarSprite')

$res = Join-Path $src 'war_resources.c'
Put 'war_read_macros.inc' (Slice $res '#define readu8' 'static void buildRgbaLut')
Put 'war_res_a.inc' (Slice $res 'static void buildRgbaLut' 's32 wres_loadStartEntities')
Put 'war_res_audio.inc' (Slice $res 'void wres_loadXmi' 'void wres_loadCursor')

Put 'war_audio_component.inc' (Slice (Join-Path $src 'war_audio.h') 'struct _WarAudioComponent' '#define WAR_AUDIO_COMPONENT_INIT_FIELDS')
Put 'war_audio_wave.inc' (Slice (Join-Path $src 'war_audio.c') 'bool wa_playWave' 'void SDLCALL audioDataCallback')

$math = Join-Path $src 'war_math.c'
$pos = @()
$pos += Slice $math 'f32 vec2_distanceSqr' 'f32 vec2_distanceInTiles'
$pos += Slice $math 'bool rect_containsf' 'bool rect_intersects'
$pos += Slice $math 'vec2 rect_center' 'rect rect_expand'
Put 'war_math_pos.inc' $pos

$wanted = 'MAX_RESOURCES_COUNT|MAX_SPRITE_FRAME_COUNT|MAX_CUSTOM_MAP_CONFIGURATIONS_COUNT|PALETTE_LENGTH|MINI_TILE_WIDTH|MINI_TILE_HEIGHT|MEGA_TILE_WIDTH|MEGA_TILE_HEIGHT|TILESET_WIDTH|TILESET_HEIGHT|TILESET_TILES_PER_ROW|MAX_OBJECTIVES_LENGTH|MAX_PLAYERS_COUNT|MAX_FEATURES_COUNT|MAX_UPGRADES_COUNT|PLAYBACK_FREQ'
Put 'war_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war.h')) | Where-Object { $_ -match "^#define ($wanted) " })

Copy-Item (Join-Path $PSScriptRoot 'war_audio_ref.c') (Join-Path $Out 'war_audio_ref.c')
Copy-Item (Join-Path $PSScriptRoot 'war_synth_cases.inc') (Join-Path $Out 'war_synth_cases.inc')

$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_audio_ref.exe') (Join-Path $Out 'war_audio_ref.c') "-I$Out" "-I$(Join-Path $War1 'deps\include')" -Wno-unused-function -Wno-int-conversion -lm 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_audio_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_audio_ref.exe')"
