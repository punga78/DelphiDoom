<#
  Issue #197: scrive Games\War\DelphiDoom.War.Render.ColorList.Data.pas dal codice ORIGINALE (Reference\war1\src\war_render.c,
  wr_getColorFromList): i colori che il disegno di debug dei proiettili e delle altre righe prende dall'id di una entita'.
  Nessuna modifica a mano: se il C cambia si rifa.

  Uso:  powershell -NoProfile -File Tools\Verifica\197\Make-WarColorList.ps1 [-War1 <...\Reference\war1>]
#>
param([string]$War1 = 'C:\Progetti\DelphiDoom\Reference\war1')
$ErrorActionPreference = 'Stop'
$render = [IO.File]::ReadAllText((Join-Path $War1 'src\war_render.c'))
$m = [regex]::Match($render, 'WarColor wr_getColorFromList\(s32 index\)\s*\{\s*const u32 colors\[\]\s*=\s*\{(.*?)\};', 'Singleline')
if (-not $m.Success) { throw 'wr_getColorFromList non trovata' }
$rows = New-Object System.Collections.Generic.List[string]
foreach ($r in [regex]::Matches($m.Groups[1].Value, '0x([0-9A-Fa-f]{6})')) {
  $v = [Convert]::ToInt32($r.Groups[1].Value, 16)
  $rows.Add(('    (R: {0}; G: {1}; B: {2}; A: 255)' -f (($v -shr 16) -band 255), (($v -shr 8) -band 255), ($v -band 255)))
}
if ($rows.Count -ne 85) { throw "Colori letti: $($rows.Count), ne servono 85" }
$text = @"
{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the list of colors of the debug drawing (GENERATED)}
{                                                                              }
{  Port of war1 (acoto87/war1), war_render.c (wr_getColorFromList), (c) 2019    }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This }
{  is an altered version, not the original.                                    }
{                                                                              }
{  Written by Tools\Verifica\197\Make-WarColorList.ps1 from the original C     }
{  code: do not edit by hand                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Render.ColorList.Data;

interface

uses
  DelphiDoom.War.Render.Types;

const
  WAR_COLOR_LIST_COUNT = 85;
  /// <summary>The 85 colors of wr_getColorFromList, opaque</summary>
  WAR_COLOR_LIST: array[0..WAR_COLOR_LIST_COUNT - 1] of TWarRgba = (
$($rows -join ",`r`n")
  );

implementation

end.
"@
$out = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot))) 'Games\War\DelphiDoom.War.Render.ColorList.Data.pas'
[IO.File]::WriteAllText($out, ($text -replace "`r?`n", "`r`n"), (New-Object Text.UTF8Encoding($false)))
"Scritto $out ($($rows.Count) colori)"
