<#
  Issue #197: scrive Libs\War\DelphiDoom.War.MapUi.CommandData.Data.pas dal codice ORIGINALE (Reference\war1\src\war_units.c:
  commandsBaseData, commandMappings, upgradesData, spellData; war_enums.h: gli enum dei comandi, delle capacita', degli
  incantesimi e dei miglioramenti): per ogni comando il tasto, il suggerimento (con la parte evidenziata) e il testo della riga di stato
  mentre un edificio lavora, e le tabelle che collegano un comando al suo tipo di unita', di miglioramento o di incantesimo.
  Nessuna modifica a mano: se il C cambia si rifa.

  Uso:  powershell -NoProfile -File Tools\Verifica\197\Make-WarCommandData.ps1 [-War1 <...\Reference\war1>]
#>
param([string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1')
$ErrorActionPreference = 'Stop'
$units = [IO.File]::ReadAllText((Join-Path $War1 'src\war_units.c'))
$enums = [IO.File]::ReadAllText((Join-Path $War1 'src\war_enums.h'))

function Read-Enum([string]$name, [string]$prefix) {
  $m = [regex]::Match($enums, "typedef enum $name\s*\{(.*?)\}", 'Singleline')
  if (-not $m.Success) { throw "enum $name non trovato" }
  $map = [ordered]@{}
  $index = 0
  foreach ($line in $m.Groups[1].Value -split "`n") {
    $t = ($line -replace '//.*$', '').Trim().TrimEnd(',')
    if ($t -match "^($prefix\w+)$") { $map[$Matches[1]] = $index; $index++ }
  }
  return $map
}

$commands = Read-Enum '_WarUnitCommandType' 'WAR_COMMAND_'
$features = Read-Enum '_WarFeatureType' 'WAR_FEATURE_'
$upgrades = Read-Enum '_WarUpgradeType' 'WAR_UPGRADE_'
$spells = Read-Enum '_WarSpellType' 'WAR_(SPELL|SUMMON)_'
$unitTypes = Read-Enum '_WarUnitType' 'WAR_UNIT_'
$portraits = Read-Enum '_WarUnitPortraits' 'WAR_PORTRAIT_'
if ($commands.Count -ne 74) { throw "Comandi letti: $($commands.Count)" }
if ($upgrades.Count -ne 19) { throw "Miglioramenti letti: $($upgrades.Count)" }
if ($spells.Count -ne 12) { throw "Incantesimi letti: $($spells.Count)" }

# commandsBaseData
$base = [regex]::Match($units, 'commandsBaseData\[\]\s*=\s*\{(.*?)\n\};', 'Singleline').Groups[1].Value
$rowRegex = '\{\s*(WAR_COMMAND_\w+)\s*,\s*(\w+)\s*,\s*(WAR_KEY_\w+)\s*,\s*(-?\d+)\s*,\s*(\d+)\s*,\s*WSV_INIT\("([^"]*)"\)\s*,\s*WSV_INIT\("([^"]*)"\)\s*\}'
$baseRows = @{}
foreach ($r in [regex]::Matches($base, $rowRegex)) {
  $key = $r.Groups[3].Value -replace '^WAR_KEY_', ''
  $pascalKey = 'wk' + $key.Substring(0, 1).ToUpper() + $key.Substring(1).ToLower()
  $baseRows[$commands[$r.Groups[1].Value]] = "    (CommandType: $($commands[$r.Groups[1].Value]); HotKey: $pascalKey; HighlightIndex: $($r.Groups[4].Value); HighlightCount: $($r.Groups[5].Value); Tooltip: '$($r.Groups[6].Value)'; Tooltip2: '$($r.Groups[7].Value)')"
}
if ($baseRows.Count -ne 74) { throw "Righe commandsBaseData lette: $($baseRows.Count)" }
$baseOut = (0..73 | ForEach-Object { $baseRows[$_] }) -join ",`n"

# commandMappings: il tipo mappato e' un tipo di unita', di miglioramento o di incantesimo secondo la posizione
$map = [regex]::Match($units, 'commandMappings\[\]\s*=\s*\{(.*?)\n\};', 'Singleline').Groups[1].Value
$mapRows = New-Object System.Collections.Generic.List[string]
foreach ($r in [regex]::Matches($map, '\{\s*(WAR_COMMAND_\w+)\s*,\s*(WAR_\w+)\s*\}')) {
  $name = $r.Groups[2].Value
  $value = if ($name -like 'WAR_UNIT_*') { $unitTypes[$name] } elseif ($name -like 'WAR_UPGRADE_*') { $upgrades[$name] } else { $spells[$name] }
  $mapRows.Add("    (CommandType: $($commands[$r.Groups[1].Value]); MappedType: $value)")
}
if ($mapRows.Count -ne 62) { throw "Righe commandMappings lette: $($mapRows.Count)" }

# upgradesData: i fotogrammi dei due livelli, nell'ordine dell'enum
$upg = [regex]::Match($units, 'upgradesData\[\]\s*=\s*\{(.*?)\n\};', 'Singleline').Groups[1].Value
$upgRows = @{}
foreach ($r in [regex]::Matches($upg, '\{\s*(WAR_UPGRADE_\w+)\s*,\s*(\d+)\s*,\s*\{\s*(WAR_PORTRAIT_\w+)\s*,\s*(WAR_PORTRAIT_\w+)\s*\}\s*\}')) {
  $upgRows[$upgrades[$r.Groups[1].Value]] = "    (Levels: $($r.Groups[2].Value); Frame1: $($portraits[$r.Groups[3].Value]); Frame2: $($portraits[$r.Groups[4].Value]))"
}
if ($upgRows.Count -ne 19) { throw "Righe upgradesData lette: $($upgRows.Count)" }
$upgOut = (0..18 | ForEach-Object { $upgRows[$_] }) -join ",`n"

# spellData: il ritratto di ogni incantesimo
$sp = [regex]::Match($units, 'spellData\[\]\s*=\s*\{(.*?)\n\};', 'Singleline').Groups[1].Value
$spRows = @{}
foreach ($r in [regex]::Matches($sp, '\{\s*(WAR_(?:SPELL|SUMMON)_\w+)\s*,\s*(WAR_PORTRAIT_\w+)\s*\}')) {
  $spRows[$spells[$r.Groups[1].Value]] = $portraits[$r.Groups[2].Value]
}
if ($spRows.Count -ne 12) { throw "Righe spellData lette: $($spRows.Count)" }
$spOut = (0..11 | ForEach-Object { "$($spRows[$_])" }) -join ', '

$featureOut = ($features.GetEnumerator() | ForEach-Object { "  $($_.Key) = $($_.Value);" }) -join "`n"
# the commands by name, WAR_CMD_ instead of WAR_COMMAND_ (Model.Commands.Types has some of them under the long name)
$commandOut = ($commands.GetEnumerator() | ForEach-Object { "  $($_.Key -replace '^WAR_COMMAND_', 'WAR_CMD_') = $($_.Value);" }) -join "`n"

$out = @'
{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - data of the commands of the units (GENERATED)      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (commandsBaseData, commandMappings, }
{  upgradesData, spellData) and war_enums.h, (c) 2019 Alejandro Coto Gutierrez, }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version,    }
{  not the original.                                                            }
{                                                                              }
{  Written by Tools\Verifica\197\Make-WarCommandData.ps1 from the original C    }
{  code: do not edit by hand                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.CommandData.Data;

interface

uses
  DelphiDoom.War.Ui.Types;

type
  /// <summary>WarUnitCommandBaseData without the click handler (the type of the command says what the click does)</summary>
  TWarCommandBase = record
    CommandType: Integer;
    HotKey: TWarKey;
    HighlightIndex: Integer;
    HighlightCount: Integer;
    Tooltip: AnsiString;
    /// <summary>What the status line says while a building trains or researches it</summary>
    Tooltip2: AnsiString;
  end;

  /// <summary>WarUnitCommandMapping: the unit, upgrade or spell that a command is for</summary>
  TWarCommandMapping = record
    CommandType: Integer;
    MappedType: Integer;
  end;

  /// <summary>WarUpgradeData: the frames of the portraits of the levels of an upgrade</summary>
  TWarUpgradeFrames = record
    Levels: Integer;
    Frame1: Integer;
    Frame2: Integer;
  end;

const
  /// <summary>commandsBaseData: by the number of the command (the table of the original is in another order, searched by type)</summary>
  WAR_COMMAND_BASE: array[0..73] of TWarCommandBase = (
'@
$out += $baseOut + "`n  );`n`n"
$out += "  /// <summary>commandMappings: 62 rows in the order of the table; the first 30 are units (train and build), then 20 upgrades, then the 4 summons and 8 spells</summary>`n"
$out += "  WAR_COMMAND_MAPPINGS: array[0..61] of TWarCommandMapping = (`n" + ($mapRows -join ",`n") + "`n  );`n`n"
$out += "  /// <summary>upgradesData: by the number of the upgrade</summary>`n"
$out += "  WAR_UPGRADE_FRAMES: array[0..18] of TWarUpgradeFrames = (`n" + $upgOut + "`n  );`n`n"
$out += "  /// <summary>spellData: the frame of the portrait of a spell or a summon, by its number</summary>`n"
$out += "  WAR_SPELL_PORTRAITS: array[0..11] of Integer = ($spOut);`n`n"
$out += "  // WarFeatureType of war_enums.h (player->features[feature / 2])`n$featureOut`n`n"
$out += "  // WarUnitCommandType of war_enums.h, as WAR_CMD_*`n$commandOut`n`nimplementation`n`nend.`n"
$root = Split-Path (Split-Path (Split-Path $PSScriptRoot))
[IO.File]::WriteAllText((Join-Path $root 'Libs\War\DelphiDoom.War.MapUi.CommandData.Data.pas'), ($out -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
"scritte $($baseRows.Count) righe dei comandi, $($mapRows.Count) mappature, $($features.Count) capacita'"
