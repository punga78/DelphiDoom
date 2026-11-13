<#
  Issues #198 e #194: compila il codice ORIGINALE che SCEGLIE i suoni (war_audio.c, acoto87/war1, zlib) e produce i
  golden della tabella dei suoni di Libs\War:
    Tests\Data\War\sounds.tables.golden.txt   gli esiti di wa_playAttackSound, wa_playDudeSelectionSound,
                                              wa_playBuildingSelectionSound e wa_playAcknowledgementSound
    Tests\Data\War\sounds.ranges.golden.txt   gli intervalli (randomFromId, randomToId) di OGNI chiamata del sorgente
                                              del remake (il testo di tutti i src\*.c, valori numerici dal C)
  Niente e' modificato in Reference\: si leggono i sorgenti e si scrivono estratti e programma in -Out (una cartella
  NUOVA fuori da Reference e dal repository).

  Uso:
    powershell -NoProfile -File Compila-SoundRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>]
      [-Tables <file di uscita>] [-Ranges <file di uscita>]

  Estrae alla lettera (per intervalli di righe cercati per testo):
    war_audio.c  : da wa_playAttackSound alla fine               -> war_play_sounds.inc
    war_audio.h  : CreateAudioArgs e le macro CREATE_AUDIO_ARGS  -> war_create_audio_args.inc
    war_enums.h  : WarRace, WarUnitType, WarUnitActionStepType, WarAudioId e WarAudioType
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe',
  [string]$Tables = '',
  [string]$Ranges = ''
)
$ErrorActionPreference = 'Stop'
if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota." }
New-Item -ItemType Directory -Force $Out | Out-Null

function Slice([string]$File, [string]$From, [string]$Before) {
  $lines = [IO.File]::ReadAllLines($File)
  $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0) { throw "Inizio non trovato in ${File}: $From" }
  if ($Before -eq '') { return $lines[$a..($lines.Count - 1)] }
  $rest = $lines[($a + 1)..($lines.Count - 1)]
  $bHit = $rest | Select-String -SimpleMatch $Before | Select-Object -First 1
  if (-not $bHit) { throw "Fine non trovata in ${File}: $Before" }
  $b = $a + 1 + $bHit.LineNumber - 1
  $lines[$a..($b - 1)]
}
function Put([string]$Name, $Lines) { $Lines | Set-Content (Join-Path $Out $Name) -Encoding ASCII }
function EnumBlock([string[]]$Enum, [string]$Start, [string]$End) {
  $a = ($Enum | Select-String -SimpleMatch $Start | Select-Object -First 1).LineNumber - 1
  $b = ($Enum | Select-String -SimpleMatch $End | Select-Object -First 1).LineNumber - 1
  if ($a -lt 0 -or $b -lt $a) { throw "Enum non trovata: $Start" }
  $Enum[$a..$b]
}

$src = Join-Path $War1 'src'
Put 'war_play_sounds.inc' (Slice (Join-Path $src 'war_audio.c') 'WarEntity* wa_playAttackSound' '')
$hdr = @('typedef struct {') + (Slice (Join-Path $src 'war_audio.h') 'WarAudioId audioId;' 'WarEntity* wa_createAudio(')
Put 'war_create_audio_args.inc' $hdr
$enum = [IO.File]::ReadAllLines((Join-Path $src 'war_enums.h'))
Put 'war_race_enum.inc' (EnumBlock $enum 'typedef enum _WarRace' '} WarRace;')
Put 'war_unit_enum.inc' (EnumBlock $enum 'typedef enum _WarUnitType' '} WarUnitType;')
Put 'war_step_enum.inc' (EnumBlock $enum 'typedef enum _WarUnitActionStepType' '} WarUnitActionStepType;')
Put 'war_audio_enums.inc' (EnumBlock $enum 'typedef enum _WarAudioId' '} WarAudioType;')
Copy-Item (Join-Path $PSScriptRoot 'war_sound_ref.c') (Join-Path $Out 'war_sound_ref.c')

# gli intervalli di OGNI chiamata del sorgente: coppie (randomFromId, randomToId) lette dal testo, valori dal C
$pairs = [ordered]@{}
foreach ($file in Get-ChildItem (Join-Path $src '*.c')) {
  $text = [IO.File]::ReadAllText($file.FullName)
  foreach ($m in [regex]::Matches($text, '\.randomFromId\s*=\s*(\w+)\s*,\s*\.randomToId\s*=\s*(\w+)')) {
    $pairs["$($m.Groups[1].Value) $($m.Groups[2].Value)"] = $true
  }
}
$rangeC = @('#include <stdio.h>', '#include "war_audio_enums.inc"', 'int main(void) {')
foreach ($p in $pairs.Keys) { $a, $b = $p -split ' '; $rangeC += "  printf(`"$a $b %d %d\n`", (int)$a, (int)$b);" }
$rangeC += '  return 0; }'
Put 'war_ranges.c' $rangeC

$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
$flags = @('-O1', '-std=gnu11', "-I$Out", '-Wno-unused-function', '-Wno-int-conversion', '-Wno-unused-value', '-Wno-unused-variable')
& $Gcc @flags -o (Join-Path $Out 'war_sound_ref.exe') (Join-Path $Out 'war_sound_ref.c') 2>&1 | Out-String
& $Gcc @flags -o (Join-Path $Out 'war_ranges.exe') (Join-Path $Out 'war_ranges.c') 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_sound_ref.exe')) -or -not (Test-Path (Join-Path $Out 'war_ranges.exe'))) { throw 'Compilazione fallita' }
if ($Tables -ne '') {
  $lines = & (Join-Path $Out 'war_sound_ref.exe') tables
  if ($LASTEXITCODE -ne 0) { throw "war_sound_ref e' uscito con $LASTEXITCODE" }
  [IO.File]::WriteAllText($Tables, (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$Tables : $($lines.Count) righe"
}
if ($Ranges -ne '') {
  $lines = & (Join-Path $Out 'war_ranges.exe')
  [IO.File]::WriteAllText($Ranges, (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$Ranges : $($lines.Count) righe"
}
