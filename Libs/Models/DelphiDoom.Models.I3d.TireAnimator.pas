{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the rotation of the tires of an I3D car     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The tire part of TI3DModelLoader.RenderGLEx (OPENGL\i3d_model.pas).         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.TireAnimator;

interface

uses
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

const
  /// <summary>
  ///   In real physics a tire makes about one turn in a tic: the rotation is slowed down by this
  ///   factor so that the eye can see it
  /// </summary>
  I3D_TIRE_EYE_COEFFICIENT = 8.0;

type
  /// <summary>
  ///   From the distance that a tire has run to its rotation in degrees. The distance and the
  ///   steering angle are the numbers of the car of the game (the engine reads them); the model
  ///   gives the size of the tire.
  /// </summary>
  TI3dTireAnimator = class
  public
    /// <summary>
    ///   The rotation, in degrees from 0 to 360, of a tire that ran ADistance (map units): the
    ///   distance over the length of the circle (the height of the box of the tire, scaled like
    ///   the model), with the slowdown for the eye. A positive rotation is brought back to the
    ///   first turn; a negative one is left as it is (as the old code). A tire of no height gives 0.
    /// </summary>
    class function Rotation(const ADistance: Double; const APerimeter: Integer;
      const APlacementScaleX, AMapCoefficient: Double; const AObjectScaleY: Integer): Single; static;
    /// <summary>The state of the four tires of a model, from the distance that each has run</summary>
    class function State(const AModel: II3dModel; const ADistances: array of Double;
      const AAngleDegrees: Single; const APlacementScaleX, AMapCoefficient: Double): TI3dTireState; static;
  end;

implementation

uses
  System.SysUtils;

{ TI3dTireAnimator }

class function TI3dTireAnimator.Rotation(const ADistance: Double; const APerimeter: Integer;
  const APlacementScaleX, AMapCoefficient: Double; const AObjectScaleY: Integer): Single;
var
  LLength: Double;
  LResult: Double;
begin
  LLength := Abs(APerimeter / I3D_DEFAULT_SCALE * APlacementScaleX * AMapCoefficient * AObjectScaleY *
    I3D_TIRE_EYE_COEFFICIENT);
  if LLength = 0 then
    Exit(0.0);
  LResult := ADistance / LLength * 360.0;
  if LResult > 0 then
    LResult := LResult - (Trunc(LResult) div 360) * 360;
  Result := LResult;
end;

class function TI3dTireAnimator.State(const AModel: II3dModel; const ADistances: array of Double;
  const AAngleDegrees: Single; const APlacementScaleX, AMapCoefficient: Double): TI3dTireState;
var
  LTire: Integer;
begin
  Result := Default(TI3dTireState);
  if not AModel.HasTires then
    Exit;
  for LTire := 0 to 3 do
    if LTire <= High(ADistances) then
      Result.Rotation[LTire] := Rotation(ADistances[LTire], AModel.Tires[LTire].Perimeter,
        APlacementScaleX, AMapCoefficient, AModel.Header.ScaleY);
  Result.Angle := AAngleDegrees;
end;

end.
