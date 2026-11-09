{******************************************************************************}
{                                                                              }
{  DD_Tools: bitmaps of Windows and the pictures of the voxel editor            }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.VoxelBitmaps;

interface

uses
  System.SysUtils,
  Vcl.Graphics,
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>
  ///   The conversions between a TBitmap and the pictures of the voxel editor: size x size cells, the cell (i, j)
  ///   being the pixel at column i and row j, each one a color of Windows ($00BBGGRR, as a TColor)
  /// </summary>
  TVoxelBitmaps = class sealed
  public
    /// <summary>A 32 bit bitmap with the pictures of the cells; the caller owns it</summary>
    class function ToBitmap(const AImage: TVoxelEditorImage; ASize: Integer): TBitmap; static;
    /// <summary>The cells of a bitmap stretched to size x size (a bitmap of that size is read as it is)</summary>
    class function FromBitmap(const ABitmap: TBitmap; ASize: Integer): TVoxelEditorImage; static;
  end;

implementation

uses
  System.Types;

{ TVoxelBitmaps }

class function TVoxelBitmaps.ToBitmap(const AImage: TVoxelEditorImage; ASize: Integer): TBitmap;
var
  LRow, LColumn: Integer;
  LLine: PCardinal;
  LColor: Cardinal;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf32bit;
    Result.SetSize(ASize, ASize);
    for LRow := 0 to ASize - 1 do
    begin
      LLine := Result.ScanLine[LRow];
      for LColumn := 0 to ASize - 1 do
      begin
        LColor := AImage[LColumn * ASize + LRow];
        // the bitmap keeps B, G, R, A in memory: $00RRGGBB for a Cardinal
        LLine^ := ((LColor and $FF) shl 16) or (LColor and $FF00) or ((LColor shr 16) and $FF);
        Inc(LLine);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TVoxelBitmaps.FromBitmap(const ABitmap: TBitmap; ASize: Integer): TVoxelEditorImage;
var
  LCopy: TBitmap;
  LRow, LColumn: Integer;
  LLine: PCardinal;
  LColor: Cardinal;
begin
  SetLength(Result, ASize * ASize);
  LCopy := TBitmap.Create;
  try
    LCopy.PixelFormat := pf32bit;
    LCopy.SetSize(ASize, ASize);
    if (ABitmap.Width = ASize) and (ABitmap.Height = ASize) then
      LCopy.Canvas.Draw(0, 0, ABitmap)
    else
      LCopy.Canvas.StretchDraw(Rect(0, 0, ASize, ASize), ABitmap);
    for LRow := 0 to ASize - 1 do
    begin
      LLine := LCopy.ScanLine[LRow];
      for LColumn := 0 to ASize - 1 do
      begin
        LColor := LLine^;
        Result[LColumn * ASize + LRow] := ((LColor and $FF) shl 16) or (LColor and $FF00) or ((LColor shr 16) and $FF);
        Inc(LLine);
      end;
    end;
  finally
    LCopy.Free;
  end;
end;

end.
