<#
  Issue #194 (seconda fetta): scrive DelphiDoom.War.Model.ActionSteps.Data.pas dall'uscita del C
  (Tests\Data\War\model.steps.golden.txt, prodotta da `war_model_ref actions`): i passi (frame, attesa, colpo, suoni) di
  ogni azione di ogni tipo di unita'. La tabella non si scrive a mano: si rifa.

  Uso: powershell -NoProfile -File Make-WarActionSteps.ps1
#>
param(
  [string]$Golden = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\War\model.steps.golden.txt'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Libs\War')
)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines($Golden) | Where-Object { $_ -and -not $_.StartsWith('#') }
$rows = @($lines | Where-Object { $_.StartsWith('K ') } | ForEach-Object { ,($_.Split(' ')) })
if ($rows.Count -ne 54 * 7) { throw "Attese 378 righe K, trovate $($rows.Count)" }

$steps = New-Object System.Collections.Generic.List[string]
$defs = New-Object System.Collections.Generic.List[string]
for ($t = 0; $t -lt 54; $t++) {
  $items = New-Object System.Collections.Generic.List[string]
  for ($a = 0; $a -lt 7; $a++) {
    $r = $rows[$t * 7 + $a]
    if ([int]$r[1] -ne $t -or [int]$r[2] -ne $a) { throw "Riga fuori ordine: $($r -join ' ')" }
    if ($r[3] -eq '0') {
      $items.Add('(Present: False; Loop: False; Directional: False; Start: 0; Count: 0)')
    } else {
      $count = [int]$r[6]
      $items.Add("(Present: True; Loop: $(if ($r[4] -eq '1') { 'True' } else { 'False' }); Directional: $(if ($r[5] -eq '1') { 'True' } else { 'False' }); Start: $($steps.Count); Count: $count)")
      for ($i = 0; $i -lt $count; $i++) {
        $pair = $r[7 + $i].Split(',')
        $steps.Add("(Kind: $($pair[0]); Param: $($pair[1]))")
      }
    }
  }
  $sep = if ($t -lt 53) { ',' } else { '' }
  $defs.Add("    ($($items -join (',' + [Environment]::NewLine + '     ')))$sep")
}

$o = New-Object System.Collections.Generic.List[string]
$o.AddRange([string[]]@(
  '{******************************************************************************}',
  '{                                                                              }',
  '{  DelphiDoom: war library - the steps of the actions of the units (GENERATED) }',
  '{                                                                              }',
  '{  Port of war1 (acoto87/war1), war_actions.c, (c) 2019 Alejandro Coto         }',
  '{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }',
  '{  version, not the original.                                                  }',
  '{                                                                              }',
  '{  Written by Tools\Verifica\194\Make-WarActionSteps.ps1 from the output of    }',
  '{  the original C code (Tests\Data\War\model.steps.golden.txt): do not edit    }',
  '{  by hand                                                                     }',
  '{                                                                              }',
  '{  Licensed under the GNU General Public License, version 2 or later           }',
  '{                                                                              }',
  '{******************************************************************************}',
  'unit DelphiDoom.War.Model.ActionSteps.Data;',
  '',
  'interface',
  '',
  'type',
  '  /// <summary>WarUnitActionStep: the type (WAR_ACTION_STEP_*) and its parameter (frames to wait, frame number)</summary>',
  '  TWarActionStepData = record',
  '    Kind: Byte;',
  '    Param: SmallInt;',
  '  end;',
  '',
  '  /// <summary>One WarUnitActionDef: where its steps are in WAR_ACTION_STEP_DATA</summary>',
  '  TWarActionDefData = record',
  '    Present: Boolean;',
  '    Loop: Boolean;',
  '    Directional: Boolean;',
  '    Start: Word;',
  '    Count: Word;',
  '  end;',
  '',
  'const',
  '  /// <summary>gUnitActionDefs of war_actions.c: for each unit type and each action (idle, walk, attack, death, harvest, repair, build)</summary>',
  '  WAR_ACTION_DEF_DATA: array[0..53, 0..6] of TWarActionDefData = ('
))
$o.AddRange([string[]]$defs)
$o.Add('  );')
$o.Add('')
$o.Add("  /// <summary>The $($steps.Count) steps of all the definitions, one after the other</summary>")
$o.Add("  WAR_ACTION_STEP_DATA: array[0..$($steps.Count - 1)] of TWarActionStepData = (")
for ($i = 0; $i -lt $steps.Count; $i += 4) {
  $chunk = $steps[$i..([Math]::Min($i + 3, $steps.Count - 1))]
  $sep = if ($i + 4 -lt $steps.Count) { ',' } else { '' }
  $o.Add("    $($chunk -join ', ')$sep")
}
$o.Add('  );')
$o.Add('')
$o.Add('implementation')
$o.Add('')
$o.Add('end.')
[IO.File]::WriteAllLines((Join-Path $OutDir 'DelphiDoom.War.Model.ActionSteps.Data.pas'), $o, (New-Object System.Text.UTF8Encoding($true)))
"Scritti i passi delle azioni: $($steps.Count) passi, 54 tipi x 7 azioni"
