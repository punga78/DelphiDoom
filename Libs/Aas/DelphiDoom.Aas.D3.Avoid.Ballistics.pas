{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - the angle and time of a shot             }
{                                                                              }
{  Port of Ballistics and HeightForTrajectory (AI_pathing.cpp), Doom 3 GPL      }
{  Source Code.                                                                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Avoid.Ballistics;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>ballistics_t: a way to hit the target with a projectile of the given speed</summary>
  TAvoidBallistic = record
    /// <summary>The angle to shoot at, in degrees</summary>
    Angle: Single;
    /// <summary>The time the projectile takes to arrive</summary>
    Time: Single;
  end;

  /// <summary>
  ///   The two shots (a low and a high one) that go from a point to another with a projectile of a speed under a
  ///   gravity, and the height that a throw reaches. Pure arithmetic: no state
  /// </summary>
  TAvoidBallistics = class sealed
  public
    /// <summary>
    ///   The number (0, 1 or 2) of the shots that reach the target; they are stored from the first of
    ///   <c>ABallistics</c>, which holds at least two
    /// </summary>
    class function Solve(const AStart, AEnd: TGeoVec3; const ASpeed, AGravity: Single;
      var ABallistics: array of TAvoidBallistic): Integer; static;
    /// <summary>The maximum height of a trajectory with the vertical speed given (HeightForTrajectory)</summary>
    class function HeightForTrajectory(const AStart: TGeoVec3; const AZVel, AGravity: Single): Single; static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Math;

{ TAvoidBallistics }

class function TAvoidBallistics.Solve(const AStart, AEnd: TGeoVec3; const ASpeed, AGravity: Single;
  var ABallistics: array of TAvoidBallistic): Integer;
var
  LIndex, LNumber: Integer;
  LX, LY, LA, LB, LC, LD, LSqrtD, LInvA: Single;
  LP: array[0..1] of Single;
  LDelta: TIdVec2;
  LAngle: Single;
  LCos, LNumerator, LDenominator: Single;
begin
  LDelta := TIdVec2.Create(AEnd.X, AEnd.Y) - TIdVec2.Create(AStart.X, AStart.Y);
  LX := LDelta.Length;
  LY := AEnd.Z - AStart.Z;

  LA := 4.0 * LY * LY + 4.0 * LX * LX;
  LB := -4.0 * ASpeed * ASpeed - 4.0 * LY * AGravity;
  LC := AGravity * AGravity;

  LD := LB * LB - 4.0 * LA * LC;
  if (LD <= 0.0) or (LA = 0.0) then
    Exit(0);
  LSqrtD := TIdMath.Sqrt(LD);
  LInvA := 0.5 / LA;
  LP[0] := (-LB + LSqrtD) * LInvA;
  LP[1] := (-LB - LSqrtD) * LInvA;
  LNumber := 0;
  for LIndex := 0 to 1 do
  begin
    if LP[LIndex] <= 0.0 then
      Continue;
    LD := TIdMath.Sqrt(LP[LIndex]);
    // the arguments of atan2( float, float ) are floats: not the extended of a Pascal expression
    LNumerator := 0.5 * (2.0 * LY * LP[LIndex] - AGravity) / LD;
    LDenominator := LD * LX;
    LAngle := ArcTan2(LNumerator, LDenominator);
    // cos( float ) of C++ gives a float
    LCos := Cos(LAngle);
    ABallistics[LNumber].Time := LX / (LCos * ASpeed);
    ABallistics[LNumber].Angle := TIdMath.AngleNormalize180(LAngle * ID_RAD2DEG);
    Inc(LNumber);
  end;
  Result := LNumber;
end;

class function TAvoidBallistics.HeightForTrajectory(const AStart: TGeoVec3; const AZVel, AGravity: Single): Single;
var
  LTime: Single;
begin
  LTime := AZVel / AGravity;
  // maximum height of projectile
  Result := AStart.Z - 0.5 * AGravity * (LTime * LTime);
end;

end.
