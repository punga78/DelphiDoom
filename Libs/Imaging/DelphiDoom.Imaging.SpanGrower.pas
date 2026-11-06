{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - grows the 64x64 flats with a filter           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.SpanGrower;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   R_GrowSpan64to128, R_GrowSpan64to256 and R_GrowSpan64to512 (r_grow.pas) on arrays: the
  ///   new pixels blend each pixel of the 64x64 flat with the ones at its right, below it and
  ///   at its right and below (the flat wraps around, as it does when it is drawn)
  /// </summary>
  /// <remarks>
  ///   Kept as in the old code: in the 128x128 one the pixel under the original is blended
  ///   first and the one that follows uses that value instead of the original
  /// </remarks>
  TImagingSpanGrower = class(TInterfacedObject, IImagingSpanGrower)
  private
    const
      SPAN_PIXELS = IMAGING_FLAT_PIXELS;
    var
      FLeft: array[0..SPAN_PIXELS - 1] of Integer;
      FDown: array[0..SPAN_PIXELS - 1] of Integer;
      FLeftDown: array[0..SPAN_PIXELS - 1] of Integer;
    procedure CheckSource(const ASource: TImagingPixels);
    function GrowFiltered(const ASource: TImagingPixels; ABits: Integer): TImagingPixels;
  public
    constructor Create;
    function Grow64to128(const ASource: TImagingPixels): TImagingPixels;
    function Grow64to256(const ASource: TImagingPixels): TImagingPixels;
    function Grow64to512(const ASource: TImagingPixels): TImagingPixels;
  end;

implementation

uses
  DelphiDoom.Imaging.ColorMath;

{ TImagingSpanGrower }

constructor TImagingSpanGrower.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  // R_InitSpanTables
  for LIndex := 0 to SPAN_PIXELS - 1 do
  begin
    if (LIndex + 1) mod 64 = 0 then
      FLeft[LIndex] := (LIndex - 63) and 4095
    else
      FLeft[LIndex] := (LIndex + 1) and 4095;
    FDown[LIndex] := (LIndex + 64) and 4095;
    if (LIndex + 65) mod 64 = 0 then
      FLeftDown[LIndex] := (LIndex + 1) and 4095
    else
      FLeftDown[LIndex] := (LIndex + 65) and 4095;
  end;
end;

procedure TImagingSpanGrower.CheckSource(const ASource: TImagingPixels);
begin
  if Length(ASource) < SPAN_PIXELS then
    raise EImagingException.Create(SImagingSpanTooSmall);
end;

function TImagingSpanGrower.Grow64to128(const ASource: TImagingPixels): TImagingPixels;
var
  LIndex: Integer;
  LDest: Integer;
  LA, LB, LC, LD: Cardinal;
begin
  CheckSource(ASource);
  SetLength(Result, 128 * 128);
  LDest := 0;
  for LIndex := 0 to SPAN_PIXELS - 1 do
  begin
    LA := ASource[LIndex];
    LB := ASource[FLeft[LIndex]];
    LC := ASource[FDown[LIndex]];
    LD := ASource[FLeftDown[LIndex]];
    Result[LDest] := LA;
    Inc(LDest);
    Result[LDest] := TImagingColorMath.MidAverage(LA, LB);
    Inc(LDest, 127);
    Result[LDest] := TImagingColorMath.MidAverage(LA, LC);
    LA := Result[LDest];
    Inc(LDest);
    Result[LDest] := TImagingColorMath.MidAverage(LA, TImagingColorMath.MidAverage(LB, LD));
    if LIndex and 63 = 63 then
      Inc(LDest)
    else
      Dec(LDest, 127);
  end;
end;

function TImagingSpanGrower.GrowFiltered(const ASource: TImagingPixels;
  ABits: Integer): TImagingPixels;
var
  LSide: Integer;
  LIndex: Integer;
  LXFrac, LYFrac: Integer;
  LSpot, LLastSpot: Integer;
  LXMod, LYMod: Integer;
  LA, LB, LC, LD, LX, LY: Cardinal;
  LStepMod: Integer;
begin
  CheckSource(ASource);
  // ABits is 2 for 256x256 (each source pixel becomes 4x4) and 3 for 512x512
  LSide := 64 shl ABits;
  SetLength(Result, LSide * LSide);
  LStepMod := $10000 shr ABits;
  LLastSpot := 0;
  LA := ASource[0];
  LB := ASource[FLeft[0]];
  LC := ASource[FDown[0]];
  LD := ASource[FLeftDown[0]];
  for LIndex := 0 to LSide * LSide - 1 do
  begin
    LXFrac := LIndex and (LSide - 1);
    LYFrac := LIndex div LSide;
    LSpot := (LXFrac shr ABits) + (LYFrac shr ABits) * 64;
    if LSpot <> LLastSpot then
    begin
      LA := ASource[LSpot];
      LB := ASource[FLeft[LSpot]];
      LC := ASource[FDown[LSpot]];
      LD := ASource[FLeftDown[LSpot]];
      LLastSpot := LSpot;
    end;
    LXMod := (LIndex and ((1 shl ABits) - 1)) * LStepMod;
    LYMod := (LYFrac and ((1 shl ABits) - 1)) * LStepMod;

    LX := TImagingColorMath.Average(LA, LB, LXMod);
    LY := TImagingColorMath.Average(LC, LD, LXMod);
    Result[LIndex] := TImagingColorMath.Average(LX, LY, LYMod);
  end;
end;

function TImagingSpanGrower.Grow64to256(const ASource: TImagingPixels): TImagingPixels;
begin
  Result := GrowFiltered(ASource, 2);
end;

function TImagingSpanGrower.Grow64to512(const ASource: TImagingPixels): TImagingPixels;
begin
  Result := GrowFiltered(ASource, 3);
end;

end.
