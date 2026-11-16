{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - arithmetic of the colors ($00BBGGRR)          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ColorMath;

interface

type
  /// <summary>
  ///   The color operations of r_hires.pas (R_ColorAdd, R_ColorAverage ...) as functions
  ///   without state. They give the same values of the old ones, also where those are odd:
  ///   the factors are 16.16 numbers and the average takes FRACUNIT - 1 - factor for the
  ///   first color
  /// </summary>
  TImagingColorMath = class sealed
  public
    class function Add(AFirst, ASecond: Cardinal): Cardinal; static;
    class function Subtract(AFirst, ASecond: Cardinal): Cardinal; static;
    class function Mean(AFirst, ASecond: Cardinal): Cardinal; static;
    /// <summary>The first color for a factor of 0, the second one for FRACUNIT</summary>
    class function Average(AFirst, ASecond: Cardinal; AFactor: Integer): Cardinal; static;
    class function LightAverage(AFirst, ASecond: Cardinal; AFactor, ALightFactor: Integer): Cardinal; static;
    class function InverseLightAverage(AFirst, ASecond: Cardinal; AFactor: Integer): Cardinal; static;
    /// <summary>The mean of the three channels, one by one</summary>
    class function MidAverage(AFirst, ASecond: Cardinal): Cardinal; static;
    /// <summary>Black for a light factor of 0, the color itself for FRACUNIT - 1</summary>
    class function Light(AColor: Cardinal; ALightFactor: Integer): Cardinal; static;
    /// <summary>As Light, but the channels are limited to 255 so the factor can exceed FRACUNIT</summary>
    class function Boost(AColor: Cardinal; ALightFactor: Integer): Cardinal; static;
    class function InverseLight(AColor: Cardinal): Cardinal; static;
    class function FuzzLight(AColor: Cardinal): Cardinal; static;
    /// <summary>Adds to the color what is left up to 255, for each channel, in 256ths</summary>
    class function LightAdd(AColor, ARed, AGreen, ABlue: Cardinal): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.Imaging.Types;

{ TImagingColorMath }

class function TImagingColorMath.Add(AFirst, ASecond: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LRed := Byte(AFirst) + Byte(ASecond);
  if LRed > 255 then
    LRed := 255;
  LGreen := Byte(AFirst shr 8) + Byte(ASecond shr 8);
  if LGreen > 255 then
    LGreen := 255;
  LBlue := Byte(AFirst shr 16) + Byte(ASecond shr 16);
  if LBlue > 255 then
    LBlue := 255;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.Subtract(AFirst, ASecond: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  if Byte(ASecond) >= Byte(AFirst) then
    LRed := 0
  else
    LRed := Byte(AFirst) - Byte(ASecond);
  if Byte(ASecond shr 8) >= Byte(AFirst shr 8) then
    LGreen := 0
  else
    LGreen := Byte(AFirst shr 8) - Byte(ASecond shr 8);
  if Byte(ASecond shr 16) >= Byte(AFirst shr 16) then
    LBlue := 0
  else
    LBlue := Byte(AFirst shr 16) - Byte(ASecond shr 16);
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.Mean(AFirst, ASecond: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LRed := (Byte(AFirst) + Byte(ASecond)) shr 1;
  LGreen := (Byte(AFirst shr 8) + Byte(ASecond shr 8)) shr 1;
  LBlue := (Byte(AFirst shr 16) + Byte(ASecond shr 16)) shr 1;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.Average(AFirst, ASecond: Cardinal; AFactor: Integer): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
  LFactor1: Integer;
begin
  LFactor1 := IMAGING_FRACUNIT - 1 - AFactor;
  LRed := ((Byte(ASecond) * AFactor) + (Byte(AFirst) * LFactor1)) shr IMAGING_FRACBITS;
  LGreen := ((Byte(ASecond shr 8) * AFactor) + (Byte(AFirst shr 8) * LFactor1)) shr IMAGING_FRACBITS;
  // the blue channel is not shifted down and up: it is masked where it already is
  LBlue := ((Byte(ASecond shr 16) * AFactor) + (Byte(AFirst shr 16) * LFactor1)) and $FF0000;
  Result := LRed + LGreen shl 8 + LBlue;
end;

class function TImagingColorMath.LightAverage(AFirst, ASecond: Cardinal;
  AFactor, ALightFactor: Integer): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
  LFactor1, LFactor2: Integer;
begin
  LFactor1 := ((IMAGING_FRACUNIT - 1 - AFactor) * ALightFactor) shr IMAGING_FRACBITS;
  LFactor2 := (AFactor * ALightFactor) shr IMAGING_FRACBITS;
  LRed := ((Byte(ASecond) * LFactor2) + (Byte(AFirst) * LFactor1)) shr IMAGING_FRACBITS;
  LGreen := ((Byte(ASecond shr 8) * LFactor2) + (Byte(AFirst shr 8) * LFactor1)) shr IMAGING_FRACBITS;
  LBlue := ((Byte(ASecond shr 16) * LFactor2) + (Byte(AFirst shr 16) * LFactor1)) shr IMAGING_FRACBITS;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.InverseLightAverage(AFirst, ASecond: Cardinal;
  AFactor: Integer): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
  LFactor1: Integer;
begin
  LFactor1 := IMAGING_FRACUNIT - 1 - AFactor;
  LRed := (Byte(ASecond) * AFactor) + (Byte(AFirst) * LFactor1);
  LGreen := (Byte(ASecond shr 8) * AFactor) + (Byte(AFirst shr 8) * LFactor1);
  LBlue := (Byte(ASecond shr 16) * AFactor) + (Byte(AFirst shr 16) * LFactor1);
  LRed := 255 - (LRed + LGreen + LBlue) div (IMAGING_FRACUNIT * 3);
  Result := LRed + LRed shl 8 + LRed shl 16;
end;

class function TImagingColorMath.MidAverage(AFirst, ASecond: Cardinal): Cardinal;
begin
  Result := TImagingColorMath.Mean(AFirst, ASecond);
end;

class function TImagingColorMath.Light(AColor: Cardinal; ALightFactor: Integer): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LRed := (Byte(AColor) * ALightFactor) shr IMAGING_FRACBITS;
  LGreen := (Byte(AColor shr 8) * ALightFactor) shr IMAGING_FRACBITS;
  LBlue := (Byte(AColor shr 16) * ALightFactor) shr IMAGING_FRACBITS;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.Boost(AColor: Cardinal; ALightFactor: Integer): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LRed := (Byte(AColor) * ALightFactor) shr IMAGING_FRACBITS;
  if LRed > 255 then
    LRed := 255;
  LGreen := (Byte(AColor shr 8) * ALightFactor) shr IMAGING_FRACBITS;
  if LGreen > 255 then
    LGreen := 255;
  LBlue := (Byte(AColor shr 16) * ALightFactor) shr IMAGING_FRACBITS;
  if LBlue > 255 then
    LBlue := 255;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.InverseLight(AColor: Cardinal): Cardinal;
var
  LGray: Cardinal;
begin
  LGray := 255 - (Byte(AColor) + Byte(AColor shr 8) + Byte(AColor shr 16)) div 3;
  Result := LGray + LGray shl 8 + LGray shl 16;
end;

class function TImagingColorMath.FuzzLight(AColor: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LRed := Byte(AColor) shr 3 * 7;
  LGreen := Byte(AColor shr 8) shr 3 * 7;
  LBlue := Byte(AColor shr 16) shr 3 * 7;
  Result := LRed + LGreen shl 8 + LBlue shl 16;
end;

class function TImagingColorMath.LightAdd(AColor, ARed, AGreen, ABlue: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Cardinal;
begin
  LBlue := AColor and $FF;
  if ABlue > 0 then
    LBlue := LBlue + ((255 - LBlue) * ABlue) div 256;
  LGreen := (AColor shr 8) and $FF;
  if AGreen > 0 then
    LGreen := LGreen + ((255 - LGreen) * AGreen) div 256;
  LRed := (AColor shr 16) and $FF;
  if ARed > 0 then
    LRed := LRed + ((255 - LRed) * ARed) div 256;
  Result := LBlue + LGreen shl 8 + LRed shl 16;
end;

end.
