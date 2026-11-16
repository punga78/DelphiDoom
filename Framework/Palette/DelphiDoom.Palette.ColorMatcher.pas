{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the nearest color                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.ColorMatcher;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf,
  DelphiDoom.Palette.NearestColor;

type
  /// <summary>V_BestColor and V_FindAproxColorIndex, without the engine</summary>
  TColorMatcher = class(TInterfacedObject, IColorMatcher)
  public
    function BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes;
      ALow, AHigh: Integer): Byte;
    function FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
  end;

implementation

{ TColorMatcher }

function TColorMatcher.BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes;
  ALow, AHigh: Integer): Byte;
var
  LIndex: Integer;
  LOffset: Integer;
  LDeltaRed: Integer;
  LDeltaGreen: Integer;
  LDeltaBlue: Integer;
  LBestDistortion: Integer;
  LDistortion: Integer;
  LBestColor: Integer;
begin
  if (ALow < 0) or (AHigh < ALow) or (Length(APalette) < (AHigh + 1) * 3) then
    raise EPaletteException.CreateFmt(SPaletteRangeInvalid, [ALow, AHigh]);

  // let any color go to 0 as a last resort
  LBestDistortion := (ARed * ARed + AGreen * AGreen + ABlue * ABlue) * 2;
  LBestColor := 0;
  LOffset := ALow * 3;
  for LIndex := ALow to AHigh do
  begin
    LDeltaRed := ARed - APalette[LOffset];
    LDeltaGreen := AGreen - APalette[LOffset + 1];
    LDeltaBlue := ABlue - APalette[LOffset + 2];
    Inc(LOffset, 3);
    LDistortion := LDeltaRed * LDeltaRed + LDeltaGreen * LDeltaGreen + LDeltaBlue * LDeltaBlue;
    if LDistortion < LBestDistortion then
    begin
      if LDistortion = 0 then
        Exit(Byte(LIndex)); // perfect match
      LBestDistortion := LDistortion;
      LBestColor := LIndex;
    end;
  end;
  Result := Byte(LBestColor);
end;

function TColorMatcher.FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal;
  ALow, AHigh: Integer): Integer;
begin
  if (ALow < 0) or (AHigh < ALow) or (Length(AColors) <= AHigh) then
    raise EPaletteException.CreateFmt(SPaletteRangeInvalid, [ALow, AHigh]);

  Result := TNearestColor.Find(@AColors[0], AColor, ALow, AHigh);
end;

end.
