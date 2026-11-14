{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the cars that touch one another                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  New: the fork let the cars go through one another when they drove in a      }
{  line; here two cars that touch are pushed apart and the one that bumps the  }
{  other slows down                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.CarCollisions;

// Positions and speeds are 16.16 fixed point and wrap as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types;

const
  /// <summary>How far apart the centers of two cars are when they touch: two radii of 16 map units</summary>
  RACING_CAR_CONTACT_DISTANCE = 32 * 65536;
  /// <summary>
  ///   How fast the cars come together (map units for each tic, fixed point) before a touch is a bump
  ///   that slows them and makes a noise: 0.25 unit for each tic, about 4 km/h
  /// </summary>
  RACING_CAR_BUMP_SPEED = 65536 div 4;

type
  /// <summary>Two cars that bumped: the keys of the cars</summary>
  TRacingBump = record
    KeyA: Cardinal;
    KeyB: Cardinal;
  end;

  TRacingCarCollisions = class
  public
    /// <summary>
    ///   Looks at every pair of cars. Two cars closer than the contact distance are pushed away from one
    ///   another (the push is added to their momentum: the game moves the objects with it); if they
    ///   come together faster than the bump speed the engine of each loses an eighth of its speed.
    ///   The cars of the same grid place (same center) are pushed along the X axis
    /// </summary>
    /// <returns>The pairs that bumped (a pair that stays in contact bumps again only after it was apart)</returns>
    class function Resolve(const ACars: array of PRacingCarState; const ATouching: TArray<Boolean>;
      var ANowTouching: TArray<Boolean>): TArray<TRacingBump>; static;
  end;

implementation

uses
  System.Math;

{ TRacingCarCollisions }

class function TRacingCarCollisions.Resolve(const ACars: array of PRacingCarState;
  const ATouching: TArray<Boolean>; var ANowTouching: TArray<Boolean>): TArray<TRacingBump>;
var
  LA, LB, LIndex, LCount: Integer;
  LDeltaX, LDeltaY, LDistance, LPush: Double;
  LNormalX, LNormalY, LApproach: Double;
  LBump: TRacingBump;
begin
  Result := nil;
  LCount := Length(ACars);
  if Length(ANowTouching) < LCount * LCount then
    SetLength(ANowTouching, LCount * LCount);
  for LIndex := 0 to High(ANowTouching) do
    ANowTouching[LIndex] := False;
  for LA := 0 to LCount - 2 do
    for LB := LA + 1 to LCount - 1 do
    begin
      LDeltaX := Double(ACars[LA].X) - ACars[LB].X;
      LDeltaY := Double(ACars[LA].Y) - ACars[LB].Y;
      if (Abs(LDeltaX) >= RACING_CAR_CONTACT_DISTANCE) or (Abs(LDeltaY) >= RACING_CAR_CONTACT_DISTANCE) then
        Continue;
      LDistance := Sqrt(LDeltaX * LDeltaX + LDeltaY * LDeltaY);
      if LDistance >= RACING_CAR_CONTACT_DISTANCE then
        Continue;
      if LDistance < 1 then
      begin
        LNormalX := 1;
        LNormalY := 0;
        LDistance := 0;
      end
      else
      begin
        LNormalX := LDeltaX / LDistance;
        LNormalY := LDeltaY / LDistance;
      end;
      // each car is pushed half of what is missing to the contact distance, at most a quarter of it in a tic
      LPush := (RACING_CAR_CONTACT_DISTANCE - LDistance) / 4;
      ACars[LA].MomentumX := ACars[LA].MomentumX + Round(LNormalX * LPush);
      ACars[LA].MomentumY := ACars[LA].MomentumY + Round(LNormalY * LPush);
      ACars[LB].MomentumX := ACars[LB].MomentumX - Round(LNormalX * LPush);
      ACars[LB].MomentumY := ACars[LB].MomentumY - Round(LNormalY * LPush);

      // how fast they come together: the relative speed along the line between them
      LApproach := (Double(ACars[LB].MomentumX) - ACars[LA].MomentumX) * LNormalX +
        (Double(ACars[LB].MomentumY) - ACars[LA].MomentumY) * LNormalY;
      ANowTouching[LA * LCount + LB] := True;
      if (LApproach > RACING_CAR_BUMP_SPEED) and not ((Length(ATouching) > LA * LCount + LB) and
         ATouching[LA * LCount + LB]) then
      begin
        ACars[LA].EngineSpeed := ACars[LA].EngineSpeed - ACars[LA].EngineSpeed div 8;
        ACars[LB].EngineSpeed := ACars[LB].EngineSpeed - ACars[LB].EngineSpeed div 8;
        LBump.KeyA := ACars[LA].Key;
        LBump.KeyB := ACars[LB].Key;
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := LBump;
      end;
    end;
end;

end.
