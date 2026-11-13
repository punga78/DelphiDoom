<#
  Issue #198: compila il codice ORIGINALE di wa_playMidi (war_audio.c, acoto87/war1, zlib) con tml.h di TinySoundFont
  (zlib) e produce i golden del tempo e degli eventi della musica di Libs\War (Tests\Data\War\music.golden.txt).
  Niente e' modificato in Reference\: si leggono i sorgenti e si scrivono estratti e programma in -Out (una cartella
  NUOVA fuori da Reference e dal repository). Il sintetizzatore del remake (tsf) NON si usa: e' sostituito da uno
  stub che scrive le chiamate (e il SoundFont non serve).

  Uso:
    powershell -NoProfile -File Compila-MusicRef.ps1 -Out <cartella> [-War1 <...\Reference\war1>] [-Gcc <gcc.exe>] [-Run <file di uscita>]

  Estrae alla lettera (per intervalli di righe cercati per testo):
    war_audio.c   : bool wa_playMidi                      -> war_play_midi.inc
    war_audio.h   : struct _WarAudioComponent             -> war_audio_component.inc
    war_enums.h   : WarAudioId e WarAudioType             -> war_audio_enums.inc
    war.h         : #define PLAYBACK_FREQ                 -> war_defines.inc
#>
param(
  [Parameter(Mandatory)][string]$Out,
  [string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1',
  [string]$Gcc = 'C:\Progetti\DelphiDoom\Reference\_dati\_strumenti\w64devkit\w64devkit\bin\gcc.exe',
  [string]$Run = ''
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
Put 'war_play_midi.inc' (Slice (Join-Path $src 'war_audio.c') 'bool wa_playMidi' 'bool wa_playWave')
Put 'war_audio_component.inc' (Slice (Join-Path $src 'war_audio.h') 'struct _WarAudioComponent' '#define WAR_AUDIO_COMPONENT_INIT_FIELDS')
$enum = [IO.File]::ReadAllLines((Join-Path $src 'war_enums.h'))
$a0 = ($enum | Select-String -SimpleMatch 'typedef enum _WarAudioId' | Select-Object -First 1).LineNumber - 1
$a1 = ($enum | Select-String -SimpleMatch '} WarAudioType;' | Select-Object -First 1).LineNumber - 1
Put 'war_audio_enums.inc' $enum[$a0..$a1]
Put 'war_defines.inc' ([IO.File]::ReadAllLines((Join-Path $src 'war.h')) | Where-Object { $_ -match '^#define PLAYBACK_FREQ ' })
Copy-Item (Join-Path $PSScriptRoot 'war_music_ref.c') (Join-Path $Out 'war_music_ref.c')

$ErrorActionPreference = 'Continue'   # gcc scrive gli avvisi su stderr
& $Gcc -O1 -std=gnu11 -o (Join-Path $Out 'war_music_ref.exe') (Join-Path $Out 'war_music_ref.c') "-I$Out" "-I$(Join-Path $War1 'deps\include')" -Wno-unused-function -Wno-int-conversion -Wno-unused-value -lm 2>&1 | Out-String
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Out 'war_music_ref.exe'))) { throw 'Compilazione fallita' }
"Compilato: $(Join-Path $Out 'war_music_ref.exe')"
if ($Run -ne '') {
  $lines = & (Join-Path $Out 'war_music_ref.exe') scenarios
  if ($LASTEXITCODE -ne 0) { throw "war_music_ref e' uscito con $LASTEXITCODE" }
  [IO.File]::WriteAllText($Run, (($lines -join "`n") + "`n"), [Text.Encoding]::ASCII)
  "$Run : $($lines.Count) righe"
}
