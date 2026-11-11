{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the transparency tables       }
{  (Mod::createTransparencyLUT)                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.TransparencyTable;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>
  ///   The lookup tables of the transparency that the particles are drawn with: for every tint of the ruleset, four
  ///   levels of opacity, and for every level the palette index that is closest to the color of the pixel under it
  ///   mixed with the tint (Mod::createTransparencyLUT). The result is 1024 bytes per tint: tint * 1024 + level * 256
  ///   + pixel, with the level from 0 (opacity 1) to 3
  /// </summary>
  TXcomTransparencyTable = class
  public
    /// <param name="APalette">The palette of the battlescape (PAL_BATTLESCAPE)</param>
    /// <param name="ATints">The tints of the ruleset (Mod::getTransparencies)</param>
    class function Build(const APalette: TXcomPalette; const ATints: TArray<TXcomTransparencyColor>): TBytes; static;
  end;

implementation

{ TXcomTransparencyTable }

class function TXcomTransparencyTable.Build(const APalette: TXcomPalette;
  const ATints: TArray<TXcomTransparencyColor>): TBytes;
const
  OPACITY_MAX = 4;
var
  LTint: Integer;
  LOpacity: Integer;
  LOpacityStep: Integer;
  LCurrent: Integer;
  LComparator: Integer;
  LCo: Single;
  LTo: Single;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LClosest: Integer;
  LLowest: Integer;
  LDifference: Integer;
  LPosition: Integer;
  LSingle: Single;

  function RoundFloat(AValue: Single): Integer;
  begin
    // Round(float): ceil(x - 0.5) below zero, floor(x + 0.5) otherwise
    if AValue < 0 then
      Result := Ceil(AValue - 0.5)
    else
      Result := Floor(AValue + 0.5);
  end;

begin
  SetLength(Result, Length(ATints) * 256 * OPACITY_MAX);
  LPosition := 0;
  for LTint := 0 to High(ATints) do
    for LOpacity := 1 to OPACITY_MAX do
    begin
      LOpacityStep := EnsureRange(LOpacity * ATints[LTint].Unused, 0, 64);
      LSingle := LOpacityStep / 64.0;
      LCo := 1.0 - LSingle * LSingle;
      LTo := LOpacityStep * 1.0;
      for LCurrent := 0 to 255 do
      begin
        LRed := Min(255, RoundFloat(Single(APalette.Colors[LCurrent].Red * LCo) + Single(ATints[LTint].R * LTo)));
        LGreen := Min(255, RoundFloat(Single(APalette.Colors[LCurrent].Green * LCo) + Single(ATints[LTint].G * LTo)));
        LBlue := Min(255, RoundFloat(Single(APalette.Colors[LCurrent].Blue * LCo) + Single(ATints[LTint].B * LTo)));
        LClosest := LCurrent;
        LLowest := MaxInt;
        // opacity zero keeps the color, and the transparent color stays the same
        if (LOpacityStep <> 0) and (LCurrent <> 0) then
          for LComparator := 1 to 255 do
          begin
            LDifference := Sqr(LRed - APalette.Colors[LComparator].Red) + Sqr(LGreen - APalette.Colors[LComparator].Green) +
              Sqr(LBlue - APalette.Colors[LComparator].Blue);
            if LDifference < LLowest then
            begin
              LClosest := LComparator;
              LLowest := LDifference;
            end;
          end;
        Result[LPosition] := LClosest;
        Inc(LPosition);
      end;
    end;
end;

end.
