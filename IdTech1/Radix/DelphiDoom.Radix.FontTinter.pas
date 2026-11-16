{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixFontTinter                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The loop that turns a grey image of a font into the colors of the palette   }
{  (GenerateBigFonts and GenerateDosFonts of radix_xlat_wad.pas)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.FontTinter;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf;

type
  /// <summary>The noise added to a pixel (its position in the image is the argument); nil is none</summary>
  TRadixTintNoise = reference to function(AIndex: Integer): Double;

  /// <summary>Colors a grey level image: 0 is a hole (254), 255 may have noise</summary>
  TRadixFontTinter = class
  public
    /// <summary>The image as indexes of the palette (a black color is a hole too)</summary>
    class function Tint(const AGrey: TBytes; AColor: Cardinal; const APalette: TArray<Cardinal>;
      const AMatcher: IColorMatcher; const ANoise: TRadixTintNoise): TBytes; static;
  end;

implementation

{ TRadixFontTinter }

class function TRadixFontTinter.Tint(const AGrey: TBytes; AColor: Cardinal;
  const APalette: TArray<Cardinal>; const AMatcher: IColorMatcher;
  const ANoise: TRadixTintNoise): TBytes;

  function Channel(ABase: Integer; AGrey: Byte; ANoiseValue: Double): Cardinal;
  var
    LValue: Int64;
  begin
    LValue := Round(ABase * AGrey / 256 + ANoiseValue);
    if LValue > 255 then
      LValue := 255
    else if LValue < 0 then
      LValue := 0;
    Result := Cardinal(LValue);
  end;

var
  LIndex: Integer;
  LNoise: Double;
  LColor: Cardinal;
begin
  SetLength(Result, Length(AGrey));
  for LIndex := 0 to High(AGrey) do
  begin
    if AGrey[LIndex] = 0 then
    begin
      Result[LIndex] := 254;
      Continue;
    end;
    LNoise := 0.0;
    if Assigned(ANoise) and (AGrey[LIndex] = 255) then
      LNoise := ANoise(LIndex);
    LColor := (Channel((AColor shr 16) and $FF, AGrey[LIndex], LNoise) shl 16) or
      (Channel((AColor shr 8) and $FF, AGrey[LIndex], LNoise) shl 8) or
      Channel(AColor and $FF, AGrey[LIndex], LNoise);
    Result[LIndex] := Byte(AMatcher.FindApproximateIndex(APalette, LColor, 0, 253));
    if APalette[Result[LIndex]] = 0 then
      Result[LIndex] := 254;
  end;
end;

end.
