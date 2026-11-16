{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBitmapOps                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the RX_* functions of radix_bitmap.pas that work on a buffer        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.BitmapOps;

interface

uses
  System.SysUtils;

type
  /// <summary>Operations on the 8 bit buffers of the images of Radix</summary>
  TRadixBitmapOps = class
  public
    /// <summary>RX_RotatebitmapBuffer90: the transposition of a W x H buffer, written back as is</summary>
    class procedure Rotate90(var ABuffer: TBytes; AWidth, AHeight: Integer); static;
    /// <summary>RX_FlipbitmapbufferHorz: row j goes to row h - j - 1</summary>
    class procedure FlipHorizontal(var ABuffer: TBytes; AWidth, AHeight: Integer); static;
    /// <summary>RX_BltImageBuffer: copies the columns X1..X2, rows Y1..Y2 of a buffer stored by columns</summary>
    class function Blt(const AInput: TBytes; AInputHeight: Integer; AX1, AX2, AY1,
      AY2: Integer): TBytes; static;
    /// <summary>RX_ColorReplace</summary>
    class procedure ColorReplace(var ABuffer: TBytes; ACount: Integer; AOld, ANew: Byte); static;
  end;

implementation

{ TRadixBitmapOps }

class procedure TRadixBitmapOps.Rotate90(var ABuffer: TBytes; AWidth, AHeight: Integer);
var
  LImage: TBytes;
  LX: Integer;
  LY: Integer;
begin
  SetLength(LImage, AWidth * AHeight);
  for LX := 0 to AWidth - 1 do
    for LY := 0 to AHeight - 1 do
      LImage[LX * AHeight + LY] := ABuffer[LY * AWidth + LX];
  for LX := 0 to AWidth - 1 do
    for LY := 0 to AHeight - 1 do
      ABuffer[LY * AWidth + LX] := LImage[LY * AWidth + LX];
end;

class procedure TRadixBitmapOps.FlipHorizontal(var ABuffer: TBytes; AWidth, AHeight: Integer);
var
  LImage: TBytes;
  LX: Integer;
  LY: Integer;
begin
  SetLength(LImage, AWidth * AHeight);
  for LX := 0 to AWidth - 1 do
    for LY := 0 to AHeight - 1 do
      LImage[(AHeight - LY - 1) * AWidth + LX] := ABuffer[LY * AWidth + LX];
  Move(LImage[0], ABuffer[0], AWidth * AHeight);
end;

class function TRadixBitmapOps.Blt(const AInput: TBytes; AInputHeight: Integer; AX1, AX2, AY1,
  AY2: Integer): TBytes;
var
  LHeight: Integer;
  LX: Integer;
  LY: Integer;
begin
  LHeight := AY2 - AY1 + 1;
  SetLength(Result, (AX2 - AX1 + 1) * LHeight);
  for LX := AX1 to AX2 do
    for LY := AY1 to AY2 do
      Result[(LX - AX1) * LHeight + (LY - AY1)] := AInput[LX * AInputHeight + LY];
end;

class procedure TRadixBitmapOps.ColorReplace(var ABuffer: TBytes; ACount: Integer; AOld,
  ANew: Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
    if ABuffer[LIndex] = AOld then
      ABuffer[LIndex] := ANew;
end;

end.
