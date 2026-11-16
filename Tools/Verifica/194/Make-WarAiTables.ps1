<#
  Issue #196: scrive DelphiDoom.War.Ai.Tables.Data.pas dall'uscita del C
  (Tests\Data\War\ai.tables.golden.txt, prodotta da `war_model_ref ai-tables`): il produttore di ogni tipo di unita'
  (wu_getProducerUnitOfType, riga P) e il copione che wai_initAI da' a ogni razza (riga S: i comandi che il C crea davvero
  eseguendo wai_initAIPlayer, non letti dal testo). Le tabelle non si scrivono a mano: si rifanno.

  Uso: powershell -NoProfile -File Make-WarAiTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\ai.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Games\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }
$producers = @($lines | Where-Object { $_.StartsWith('P ') } | ForEach-Object { , ($_.Split(' ')) })
$script = @($lines | Where-Object { $_.StartsWith('S ') } | ForEach-Object { , ($_.Split(' ')) })
if ($producers.Count -ne 54) { throw "Attesi 54 produttori, trovati $($producers.Count)" }
for ($i = 0; $i -lt $producers.Count; $i++) { if ([int]$producers[$i][1] -ne $i) { throw "Produttore fuori ordine alla riga $i" } }
$races = 3
$length = $script.Count / $races
if ($script.Count % $races -ne 0) { throw 'Il copione non e'' uguale per ogni razza' }

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - tables of the computer player (GENERATED)         }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_ai.c and war_units.c, (c) 2019 Alejandro    }',
  '{  Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an     }',
  '{  altered version, not the original.                                          }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarAiTables.ps1 from the output of the   }',
  '{  original C code (Tests\Data\War\ai.tables.golden.txt): do not edit by hand  }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Ai.Tables.Data;',
  '',
  'interface',
  '',
  'uses',
  '  DelphiDoom.War.Ai.Types;',
  '',
  'const',
  '  /// <summary>The number of commands of the script that wai_initAI gives to a player</summary>',
  "  WAR_AI_SCRIPT_LENGTH = $length;",
  '',
  '  /// <summary>',
  '  ///   The script of wai_initAI by race (0 neutral, 1 humans, 2 orcs): the commands the original makes, in order (the unit types',
  '  ///   are already those of the race)',
  '  /// </summary>',
  "  WAR_AI_SCRIPT: array[0..$($races - 1), 0..$($length - 1)] of TWarAiScriptEntry = ("
))
for ($r = 0; $r -lt $races; $r++) {
  $items = @()
  for ($i = 0; $i -lt $length; $i++) {
    $e = $script[$r * $length + $i]
    if ([int]$e[1] -ne $r -or [int]$e[2] -ne $i) { throw "Copione fuori ordine ($r, $i)" }
    $items += "(Kind: $($e[3]); UnitType: $($e[4]); Count: $($e[5]))"
  }
  $o.Add('    (' + ($items -join ', ') + ')' + $(if ($r -lt $races - 1) { ',' } else { ');' }))
}
$o.Add('')
$o.Add('  /// <summary>wu_getProducerUnitOfType by unit type: the building that trains the unit, -1 for a type nothing trains</summary>')
$o.Add("  WAR_UNIT_PRODUCERS: array[0..$($producers.Count - 1)] of Integer = (")
$vals = $producers | ForEach-Object { $_[2] }
for ($i = 0; $i -lt $vals.Count; $i += 18) {
  $chunk = $vals[$i..([Math]::Min($i + 17, $vals.Count - 1))] -join ', '
  $o.Add('    ' + $chunk + $(if ($i + 18 -lt $vals.Count) { ',' } else { ');' }))
}
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
$out = Join-Path $OutDir 'DelphiDoom.War.Ai.Tables.Data.pas'
[IO.File]::WriteAllText($out, (($o -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($true)))
"Scritto $out ($($producers.Count) produttori, copione di $length comandi per $races razze)"
