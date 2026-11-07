{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - images in YCbCr                                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.YccConverter;

interface

uses
  DelphiDoom.Jpeg.ColorConverter;

type
  /// <summary>
  ///   YCbCr to RGB, written as blue, green, red like the pixels of a Windows
  ///   bitmap (ycc_rgb_convert). The products with the constants are in
  ///   tables of 16 bit fixed point numbers
  /// </summary>
  TJpegYccConverter = class(TInterfacedObject, IJpegColorConverter)
  private
    class var FLimit: array[0..1023] of Byte;
    class constructor CreateLimitTable;
  private
    FCrToRed: array[0..255] of Integer;
    FCbToBlue: array[0..255] of Integer;
    FCrToGreen: array[0..255] of Integer;
    FCbToGreen: array[0..255] of Integer;
  public
    constructor Create;

    procedure ConvertRow(const ARows: array of PByte; AOutput: PByte; AWidth: Integer);
    function OutputComponents: Integer;
  end;

implementation

{$Q-}
{$R-}
{$POINTERMATH ON}

const
  SCALE_BITS = 16;
  ONE_HALF = 1 shl (SCALE_BITS - 1);

  // The constants 1.40200, 1.77200, 0.71414 and 0.34414 with 16 bits of fraction
  FIX_1_40200 = 91881;
  FIX_1_77200 = 116130;
  FIX_0_71414 = 46802;
  FIX_0_34414 = 22554;

function ArithmeticShiftRight(AValue, ACount: Integer): Integer; inline;
begin
  // The bits that come in at the top are copies of the sign (no branch: the
  // sign of the sum of two tables is not predictable)
  Result := Integer(Cardinal(AValue) shr ACount) or
    Integer(Cardinal(-Integer(Cardinal(AValue) shr 31)) shl (32 - ACount));
end;

{ TJpegYccConverter }

class constructor TJpegYccConverter.CreateLimitTable;
var
  LIndex: Integer;
begin
  // The sample for each value from -256 to 767
  for LIndex := 0 to High(FLimit) do
    if LIndex < 256 then
      FLimit[LIndex] := 0
    else if LIndex > 511 then
      FLimit[LIndex] := 255
    else
      FLimit[LIndex] := Byte(LIndex - 256);
end;

constructor TJpegYccConverter.Create;
var
  LIndex: Integer;
  LCentered: Integer;
begin
  inherited Create;
  // The tables are indexed by Cb and Cr, whose zero is at 128
  for LIndex := 0 to 255 do
  begin
    LCentered := LIndex - 128;
    FCrToRed[LIndex] := ArithmeticShiftRight(FIX_1_40200 * LCentered + ONE_HALF,
      SCALE_BITS);
    FCbToBlue[LIndex] := ArithmeticShiftRight(FIX_1_77200 * LCentered + ONE_HALF,
      SCALE_BITS);
    FCrToGreen[LIndex] := -FIX_0_71414 * LCentered;
    FCbToGreen[LIndex] := -FIX_0_34414 * LCentered + ONE_HALF;
  end;
end;

procedure TJpegYccConverter.ConvertRow(const ARows: array of PByte;
  AOutput: PByte; AWidth: Integer);
var
  LColumn: Integer;
  LLuma: Integer;
  LBlue: Integer;
  LRed: Integer;
  LY, LCb, LCr: PByte;
begin
  LY := ARows[0];
  LCb := ARows[1];
  LCr := ARows[2];
  for LColumn := 0 to AWidth - 1 do
  begin
    LLuma := LY[LColumn];
    LBlue := LCb[LColumn];
    LRed := LCr[LColumn];
    AOutput[0] := FLimit[LLuma + FCbToBlue[LBlue] + 256];
    AOutput[1] := FLimit[LLuma + ArithmeticShiftRight(FCbToGreen[LBlue] + FCrToGreen[LRed],
      SCALE_BITS) + 256];
    AOutput[2] := FLimit[LLuma + FCrToRed[LRed] + 256];
    Inc(AOutput, 3);
  end;
end;

function TJpegYccConverter.OutputComponents: Integer;
begin
  Result := 3;
end;

end.
