{******************************************************************************}
{                                                                              }
{  DD_Tools: bitmaps of Windows and arrays of pixels                            }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.Bitmaps;

interface

uses
  System.SysUtils,
  Vcl.Graphics;

type
  /// <summary>
  ///   The conversions between a TBitmap and the arrays of $xxRRGGBB pixels that the libraries use. A 32 bit
  ///   bitmap of Windows keeps the pixels as B, G, R, A in memory, which is $AARRGGBB for a Cardinal
  /// </summary>
  TToolsBitmapPixels = class
  public
    /// <summary>The pixels of a bitmap (any format) as 32 bit values with the alpha byte at 0</summary>
    class function FromBitmap(const ABitmap: TBitmap; out AWidth, AHeight: Integer): TArray<Cardinal>; static;
    /// <summary>A 32 bit bitmap with the pixels (AWidth * AHeight values); the caller owns it</summary>
    class function ToBitmap(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer): TBitmap; static;
  end;

implementation

uses
  System.Classes;

{ TToolsBitmapPixels }

class function TToolsBitmapPixels.FromBitmap(const ABitmap: TBitmap; out AWidth, AHeight: Integer): TArray<Cardinal>;
var
  LCopy: TBitmap;
  LRow: Integer;
begin
  AWidth := ABitmap.Width;
  AHeight := ABitmap.Height;
  SetLength(Result, AWidth * AHeight);
  if Length(Result) = 0 then
    Exit;
  LCopy := TBitmap.Create;
  try
    LCopy.Assign(ABitmap);
    LCopy.PixelFormat := pf32bit;
    for LRow := 0 to AHeight - 1 do
      Move(LCopy.ScanLine[LRow]^, Result[LRow * AWidth], AWidth * SizeOf(Cardinal));
  finally
    LCopy.Free;
  end;
  for LRow := 0 to High(Result) do
    Result[LRow] := Result[LRow] and $FFFFFF;
end;

class function TToolsBitmapPixels.ToBitmap(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer): TBitmap;
var
  LRow: Integer;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf32bit;
    Result.SetSize(AWidth, AHeight);
    for LRow := 0 to AHeight - 1 do
      Move(APixels[LRow * AWidth], Result.ScanLine[LRow]^, AWidth * SizeOf(Cardinal));
  except
    Result.Free;
    raise;
  end;
end;

end.
