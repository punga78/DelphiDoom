{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the palette at the end of a KVX or VOX file       }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Format.SlabPalette;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>
  ///   The last 768 bytes of a KVX or a Slab6 VOX file: 256 colors as blue, green, red. A color that is black
  ///   becomes 1 (0 is "no voxel"). A palette of the VGA, with channels that do not reach 255, is stretched by
  ///   255 / (the largest channel), at most 4 times. The color is made as r shl 16 + g shl 8 + b, as the old
  ///   loaders did and the editor shows it (so a voxel that was red is shown blue: the old behavior)
  /// </summary>
  TVoxelEditorSlabPalette = class sealed
  public
    class function Read(const ABytes: TBytes): TVoxelEditorPalette; static;
  end;

implementation

uses
  System.Math;

{ TVoxelEditorSlabPalette }

class function TVoxelEditorSlabPalette.Read(const ABytes: TBytes): TVoxelEditorPalette;
var
  LIndex, LStart, LMaximum, LValue: Integer;
  LRed, LGreen, LBlue: Byte;
  LFactor: Double;
begin
  if Length(ABytes) < 768 then
    raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, ['no palette']);
  LStart := Length(ABytes) - 768;
  LMaximum := 0;
  for LIndex := 0 to 255 do
  begin
    LBlue := ABytes[LStart + LIndex * 3];
    LGreen := ABytes[LStart + LIndex * 3 + 1];
    LRed := ABytes[LStart + LIndex * 3 + 2];
    LMaximum := Max(LMaximum, Max(LBlue, Max(LGreen, LRed)));
    Result[LIndex] := (Cardinal(LRed) shl 16) + (Cardinal(LGreen) shl 8) + LBlue;
    if Result[LIndex] = 0 then
      Result[LIndex] := 1;
  end;
  if (LMaximum < 255) and (LMaximum > 0) then
  begin
    LFactor := 255 / LMaximum;
    if LFactor > 4.0 then
      LFactor := 4.0;
    for LIndex := 0 to 255 do
    begin
      LRed := Byte(Result[LIndex] shr 16);
      LGreen := Byte(Result[LIndex] shr 8);
      LBlue := Byte(Result[LIndex]);
      LValue := EnsureRange(Round(LFactor * LRed), 0, 255);
      LRed := LValue;
      LValue := EnsureRange(Round(LFactor * LGreen), 0, 255);
      LGreen := LValue;
      LValue := EnsureRange(Round(LFactor * LBlue), 0, 255);
      LBlue := LValue;
      Result[LIndex] := (Cardinal(LRed) shl 16) + (Cardinal(LGreen) shl 8) + LBlue;
    end;
  end;
end;

end.
