{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the colors of the RoQ vectors               }
{                                                                              }
{  Port of ROQ_GenYUVTables and yuv_to_rgb24 of the RoQ decoder of Quake III   }
{  Arena (cl_cin.c, GPL v2 or later, Copyright (C) 1999-2005 Id Software,      }
{  Inc.) and of Doom 3 (Cinematic.cpp, GPL v3 with the additional terms of the }
{  Doom 3 Source Code License, Copyright (C) 1999-2011 id Software LLC).       }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.YuvConverter;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   Turns the Y, Cr and Cb bytes of a RoQ vector into a pixel $AABBGGRR with the tables of
  ///   the original (ROQ_YY_tab ...). The tables are the ones of the object: nothing is global
  /// </summary>
  TRoqYuvConverter = class
  strict private
    FYy: array[0..255] of Integer;
    FUb: array[0..255] of Integer;
    FUg: array[0..255] of Integer;
    FVg: array[0..255] of Integer;
    FVr: array[0..255] of Integer;
    FAlpha: Cardinal;
  public
    /// <param name="AAlpha">The alpha byte of the pixels: $FF as Quake III, 0 as Doom 3</param>
    constructor Create(AAlpha: Byte);
    /// <summary>yuv_to_rgb24 (Cr is the parameter u and Cb is v, as the file stores them)</summary>
    function ToPixel(AY, AU, AV: Integer): Cardinal;
    /// <summary>
    ///   yuv_to_rgb: the same colors as a 16 bit RGB 5-6-5 word (red in the high bits). It uses
    ///   other shifts than <c>ToPixel</c> (9, 8 and 9), as the original does, so it is not the
    ///   truncation of the 32 bit pixel
    /// </summary>
    function ToRgb565(AY, AU, AV: Integer): Word;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TRoqYuvConverter }

constructor TRoqYuvConverter.Create(AAlpha: Byte);
var
  LIndex: Integer;
  LTUb, LTVr, LTUg, LTVg, LX, LProduct, LSum: Single;
begin
  inherited Create;
  FAlpha := Cardinal(AAlpha) shl 24;
  // every operation is rounded to Single, as the float of the original does with SSE
  LTUb := 1.77200 / 2.0;
  LTUb := LTUb * 64.0;
  LTUb := LTUb + 0.5;
  LTVr := 1.40200 / 2.0;
  LTVr := LTVr * 64.0;
  LTVr := LTVr + 0.5;
  LTUg := 0.34414 / 2.0;
  LTUg := LTUg * 64.0;
  LTUg := LTUg + 0.5;
  LTVg := 0.71414 / 2.0;
  LTVg := LTVg * 64.0;
  LTVg := LTVg + 0.5;
  for LIndex := 0 to 255 do
  begin
    LX := 2 * LIndex - 255;
    LProduct := LTUb * LX;
    LSum := LProduct + 32;
    FUb[LIndex] := Trunc(LSum);
    LProduct := LTVr * LX;
    LSum := LProduct + 32;
    FVr[LIndex] := Trunc(LSum);
    LProduct := -LTUg * LX;
    FUg[LIndex] := Trunc(LProduct);
    LProduct := -LTVg * LX;
    LSum := LProduct + 32;
    FVg[LIndex] := Trunc(LSum);
    FYy[LIndex] := (LIndex shl 6) or (LIndex shr 2);
  end;
end;

function TRoqYuvConverter.ToPixel(AY, AU, AV: Integer): Cardinal;
var
  LRed, LGreen, LBlue, LLuma: Integer;
begin
  LLuma := FYy[AY];
  LRed := TIdMath.Sar(LLuma + FVr[AV], 6);
  LGreen := TIdMath.Sar(LLuma + FUg[AU] + FVg[AV], 6);
  LBlue := TIdMath.Sar(LLuma + FUb[AU], 6);
  if LRed < 0 then
    LRed := 0;
  if LGreen < 0 then
    LGreen := 0;
  if LBlue < 0 then
    LBlue := 0;
  if LRed > 255 then
    LRed := 255;
  if LGreen > 255 then
    LGreen := 255;
  if LBlue > 255 then
    LBlue := 255;
  Result := Cardinal(LRed) or (Cardinal(LGreen) shl 8) or (Cardinal(LBlue) shl 16) or FAlpha;
end;

function TRoqYuvConverter.ToRgb565(AY, AU, AV: Integer): Word;
var
  LRed, LGreen, LBlue, LLuma: Integer;
begin
  LLuma := FYy[AY];
  LRed := TIdMath.Sar(LLuma + FVr[AV], 9);
  LGreen := TIdMath.Sar(LLuma + FUg[AU] + FVg[AV], 8);
  LBlue := TIdMath.Sar(LLuma + FUb[AU], 9);
  if LRed < 0 then
    LRed := 0;
  if LGreen < 0 then
    LGreen := 0;
  if LBlue < 0 then
    LBlue := 0;
  if LRed > 31 then
    LRed := 31;
  if LGreen > 63 then
    LGreen := 63;
  if LBlue > 31 then
    LBlue := 31;
  Result := Word((LRed shl 11) + (LGreen shl 5) + LBlue);
end;

end.
