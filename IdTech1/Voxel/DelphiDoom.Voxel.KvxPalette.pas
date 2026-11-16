{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the palette at the end of KVX and VOX files     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.KvxPalette;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types;

type
  /// <summary>
  ///   The last 768 bytes of a KVX or VOX file are the palette: 256 colors of red, green and blue.
  ///   The old loaders (three copies of the same code) turn black into 1 (zero means no voxel)
  ///   and, when no component reaches 255 (the palette of Ken's files goes 0..63), scale all
  ///   by 255 over the biggest component, at most four times.
  /// </summary>
  TVoxelKvxPalette = class
  public
    /// <summary>The 256 colors as $00RRGGBB; EVoxelException if the file is shorter than the palette</summary>
    class function Read(const ABytes: TBytes): TArray<Cardinal>; static;
  end;

implementation

{ TVoxelKvxPalette }

class function TVoxelKvxPalette.Read(const ABytes: TBytes): TArray<Cardinal>;
var
  LIndex: Integer;
  LBase: Integer;
  LRed, LGreen, LBlue: Byte;
  LMaxComponent: Integer;
  LFactor: Double;
  LValue: Integer;

  function Scaled(const AComponent: Byte): Byte;
  begin
    LValue := Round(LFactor * AComponent);
    if LValue < 0 then
      LValue := 0
    else if LValue > 255 then
      LValue := 255;
    Result := LValue;
  end;

begin
  if Length(ABytes) < VOXEL_PALETTE_BYTES then
    raise EVoxelException.CreateFmt(SVoxelTooShort, [Length(ABytes)]);
  SetLength(Result, 256);
  LBase := Length(ABytes) - VOXEL_PALETTE_BYTES;
  LMaxComponent := 0;
  for LIndex := 0 to 255 do
  begin
    LRed := ABytes[LBase + LIndex * 3];
    if LRed > LMaxComponent then
      LMaxComponent := LRed;
    LGreen := ABytes[LBase + LIndex * 3 + 1];
    if LGreen > LMaxComponent then
      LMaxComponent := LGreen;
    LBlue := ABytes[LBase + LIndex * 3 + 2];
    if LBlue > LMaxComponent then
      LMaxComponent := LBlue;
    Result[LIndex] := (LRed shl 16) + (LGreen shl 8) + LBlue;
    if Result[LIndex] = 0 then
      Result[LIndex] := VOXEL_BLACK_COLOR;
  end;

  // the palette of Ken's files usually uses the colors 0..63
  if (LMaxComponent < 255) and (LMaxComponent > 0) then
  begin
    LFactor := 255 / LMaxComponent;
    if LFactor > 4.0 then
      LFactor := 4.0;
    for LIndex := 0 to 255 do
    begin
      LRed := Result[LIndex] shr 16;
      LGreen := Result[LIndex] shr 8;
      LBlue := Result[LIndex];
      Result[LIndex] := (Scaled(LRed) shl 16) + (Scaled(LGreen) shl 8) + Scaled(LBlue);
    end;
  end;
end;

end.
