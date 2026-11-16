{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - tables of blends of the colors of a palette   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.HiResTables;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   The table that R_CalcHiResTables_SingleThread (r_hires.pas) fills for the 32 bit
  ///   renderer: level 0 holds the first color; level k blends it with the second one at
  ///   k / 8. The old threads (one, two or four of them) computed the same values: here
  ///   the table is built by one call and the caller decides where to run it
  /// </summary>
  TImagingHiResTableBuilder = class(TInterfacedObject, IImagingHiResTableBuilder)
  public
    function Build(const APalette: TImagingPixels): TImagingPixels;
  end;

implementation

{ TImagingHiResTableBuilder }

function TImagingHiResTableBuilder.Build(const APalette: TImagingPixels): TImagingPixels;
var
  LLevel: Integer;
  LFirst: Integer;
  LSecond: Integer;
  LTarget: Integer;
  LColor: Cardinal;
  LColor2: Cardinal;
  LFactor1, LFactor2: Integer;
  LRedA, LGreenA, LBlueA: Integer;
  LMultiples: array[0..255] of Integer;
  LRed, LGreen, LBlue: Cardinal;
  LIndex: Integer;
begin
  if Length(APalette) < IMAGING_PALETTE_SIZE then
    raise EImagingException.Create(SImagingBadPalette);
  SetLength(Result, IMAGING_HIRES_FACTOR * IMAGING_PALETTE_SIZE * IMAGING_PALETTE_SIZE);

  for LFirst := 0 to 255 do
  begin
    LTarget := LFirst * IMAGING_PALETTE_SIZE;
    for LSecond := 0 to 255 do
      Result[LTarget + LSecond] := APalette[LFirst];
  end;

  for LLevel := 1 to IMAGING_HIRES_FACTOR - 1 do
  begin
    LFactor2 := LLevel shl (IMAGING_FRACBITS - IMAGING_HIRES_BITS);
    LFactor1 := (IMAGING_FRACUNIT - 1) - LFactor2;
    for LIndex := 0 to 255 do
      LMultiples[LIndex] := LIndex * LFactor2;
    for LFirst := 0 to 255 do
    begin
      LColor := APalette[LFirst];
      LRedA := Byte(LColor) * LFactor1;
      LGreenA := Byte(LColor shr 8) * LFactor1;
      LBlueA := Byte(LColor shr 16) * LFactor1;
      LTarget := (LLevel * IMAGING_PALETTE_SIZE + LFirst) * IMAGING_PALETTE_SIZE;
      for LSecond := 0 to 255 do
      begin
        LColor2 := APalette[LSecond];
        LRed := (LMultiples[Byte(LColor2)] + LRedA) shr IMAGING_FRACBITS;
        LGreen := (LMultiples[Byte(LColor2 shr 8)] + LGreenA) shr IMAGING_FRACBITS;
        // the blue channel is already where it goes: it is masked and not shifted
        LBlue := (LMultiples[Byte(LColor2 shr 16)] + LBlueA) and $FF0000;
        Result[LTarget + LSecond] := LRed + LGreen shl 8 + LBlue;
      end;
    end;
  end;
end;

end.
