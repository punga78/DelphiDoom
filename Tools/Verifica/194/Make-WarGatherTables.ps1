<#
  Issue #194 (seconda fetta, raccolta): scrive DelphiDoom.War.Model.WorkerSprites.Data.pas dall'uscita del C
  (Tests\Data\War\gather.tables.golden.txt, prodotta da `war_model_ref gather-tables`): le immagini dei trasportatori
  (workersData di war_units.c). I passi dell'azione di raccolta non sono piu' qui: sono nella tabella unica di tutte le azioni
  (Make-WarActionSteps.ps1, DelphiDoom.War.Model.ActionSteps.Data). Le tabelle non si scrivono a mano: si rifanno.

  Uso: powershell -NoProfile -File Make-WarGatherTables.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\gather.tables.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }
$workers = @($lines | Where-Object { $_.StartsWith('W ') } | ForEach-Object { ,($_.Split(' ')) })

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - images of the workers that carry (GENERATED)      }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_units.c, (c) 2019 Alejandro Coto           }',
  '{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }',
  '{  version, not the original.                                                  }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarGatherTables.ps1 from the output of   }',
  '{  the original C code (Tests\Data\War\gather.tables.golden.txt): do not edit  }',
  '{  by hand                                                                     }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Model.WorkerSprites.Data;',
  '',
  'interface',
  '',
  'type',
  '  /// <summary>WarWorkerData: the images of a worker that carries wood or gold</summary>',
  '  TWarWorkerSprites = record',
  '    UnitType: Integer;',
  '    CarryingWood: Integer;',
  '    CarryingGold: Integer;',
  '  end;',
  '',
  'const'
))
$o.Add("  /// <summary>workersData of war_units.c</summary>")
$o.Add("  WAR_WORKER_SPRITES: array[0..$($workers.Count - 1)] of TWarWorkerSprites = (")
for ($i = 0; $i -lt $workers.Count; $i++) {
  $r = $workers[$i]
  $sep = if ($i -lt $workers.Count - 1) { ',' } else { '' }
  $o.Add("    (UnitType: $($r[1]); CarryingWood: $($r[2]); CarryingGold: $($r[3]))$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
[IO.File]::WriteAllLines((Join-Path $OutDir 'DelphiDoom.War.Model.WorkerSprites.Data.pas'), $o, (New-Object System.Text.UTF8Encoding($false)))
"Scritta WorkerSprites.Data ($($workers.Count) trasportatori)"
