{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the angles of the "fake 3D" view             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_CalculateAnglesTable of r_fake3d.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Fake3DAngles;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   The table of the cosines of the angles of the view when the player looks up and down
  ///   (usefake3d): done once, when the renderer starts
  /// </summary>
  TRendererFake3DAngles = class(TInterfacedObject, IRendererFake3DAngles)
  strict private
    class function CircleFromPoints(const A1, A2, B1, B2, C1, C2: Extended;
      out X, Y, R: Extended): Boolean; static;
    class procedure PointsInCircle(L: Integer; const X, Y, R: Extended;
      out V1, V2: Extended); static;
  public
    function Cosines(AMinIndex, AMaxIndex: Integer): TArray<Double>;
  end;

implementation

uses
  System.Math;

// Extended on purpose: the old code used it, and the angles of the frames depend on every bit
// (on Win64 Extended is a Double, as it was)
const
  LOOK_DIRECTION_TO_ANGLE = 0.5 / 16;
  COLLINEAR_EPSILON = 0.0000000001;
  RANGE_EPSILON = 0.001;

{ TRendererFake3DAngles }

class function TRendererFake3DAngles.CircleFromPoints(const A1, A2, B1, B2, C1, C2: Extended;
  out X, Y, R: Extended): Boolean;
var
  LDeterminant: Extended;
  LU: Extended;
  LV: Extended;
begin
  X := 0;
  Y := 0;
  R := 0;
  LDeterminant := (A1 - B1) * (B2 - C2) - (B1 - C1) * (A2 - B2);
  if (LDeterminant > -COLLINEAR_EPSILON) and (LDeterminant < COLLINEAR_EPSILON) then
    Exit(False);
  LU := (A1 * A1 - B1 * B1 + A2 * A2 - B2 * B2) / 2;
  LV := (B1 * B1 - C1 * C1 + B2 * B2 - C2 * C2) / 2;
  X := (LU * (B2 - C2) - LV * (A2 - B2)) / LDeterminant;
  Y := (LV * (A1 - B1) - LU * (B1 - C1)) / LDeterminant;
  R := Sqrt((X - A1) * (X - A1) + (Y - A2) * (Y - A2));
  Result := True;
end;

class procedure TRendererFake3DAngles.PointsInCircle(L: Integer; const X, Y, R: Extended;
  out V1, V2: Extended);
var
  LRoot: Extended;
begin
  LRoot := Sqrt(R * R - (L - X) * (L - X));
  V1 := Y - LRoot;
  V2 := Y + LRoot;
end;

function TRendererFake3DAngles.Cosines(AMinIndex, AMaxIndex: Integer): TArray<Double>;
var
  A1, A2, B1, B2, C1, C2: Extended;
  X, Y, R: Extended;
  V1, V2: Extended;
  LLow, LHigh: Extended;
  LIndex: Integer;
begin
  if AMaxIndex < AMinIndex then
    raise EArgumentException.Create('AMaxIndex');
  SetLength(Result, AMaxIndex - AMinIndex + 1);
  A1 := AMinIndex;
  A2 := A1 * LOOK_DIRECTION_TO_ANGLE * Pi / 270;
  LLow := A2 - RANGE_EPSILON;
  B1 := 0.0;
  B2 := 0.0;
  C1 := AMaxIndex;
  C2 := C1 * LOOK_DIRECTION_TO_ANGLE * Pi / 180;
  LHigh := C2 + RANGE_EPSILON;
  if CircleFromPoints(A1, A2, B1, B2, C1, C2, X, Y, R) then
  begin
    for LIndex := AMinIndex to AMaxIndex do
    begin
      PointsInCircle(LIndex, X, Y, R, V1, V2);
      // the root of the circle that is inside the range of the angles
      if ((LLow < LHigh) and (V1 >= LLow) and (V1 <= LHigh)) or
        ((not (LLow < LHigh)) and (V1 >= LHigh) and (V1 <= LLow)) then
        Result[LIndex - AMinIndex] := Cos(V1)
      else
        Result[LIndex - AMinIndex] := Cos(V2);
    end;
  end
  else // unreachable with the real range: the points are not collinear
    for LIndex := 0 to High(Result) do
      Result[LIndex] := 1.0;
end;

end.
