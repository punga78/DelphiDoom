{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the velocity of a unit that has nothing around    }
{                                                                              }
{  Port of war1 (acoto87/war1), wrvo_computeNewVelocity and wrvo_score of      }
{  war_rvo.c for the case of no neighbours, (c) 2019 Alejandro Coto Gutierrez, }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.StraightSteering;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   The velocity that the original gives to a unit with no other unit near (the avoidance of collisions, issue
  ///   #195, is not ported): the preferred velocity clipped to the maximum speed. The original builds 34 candidates (the
  ///   preferred one clipped, two rings of 16 directions and a stop) and takes the one that deviates least from the
  ///   preferred: when the preferred one is not longer than the maximum it deviates by nothing and wins, so the
  ///   rings are only looked at when it has to be clipped, as the original would
  /// </summary>
  TWarStraightSteering = class
  public
    /// <summary>wrvo_computeNewVelocity with no neighbours</summary>
    class function NewVelocity(const APreferred: TWarVec2; AMaxSpeed: Single): TWarVec2; static;
  end;

implementation

const
  RING_COUNT = 16;
  // PI of war_math.h is a float
  SINGLE_PI: Single = 3.14159265358979323846;
  // 1e-6f
  SINGLE_MICRO: Single = 1E-6;

{ TWarStraightSteering }

class function TWarStraightSteering.NewVelocity(const APreferred: TWarVec2; AMaxSpeed: Single): TWarVec2;
var
  LLength: Single;
  LInverse: Single;
  LBest: TWarVec2;
  LBestScore: Single;
  LRing: Integer;
  LStep: Integer;
  LSpeed: Single;
  LAngleStep: Single;
  LAngle: Single;
  LCosine: Single;
  LSine: Single;
  LCandidate: TWarVec2;
  LDx: Single;
  LDy: Single;
  LXX: Single;
  LYY: Single;
  LScore: Single;
  LSquare: Single;

  procedure Consider(const ACandidate: TWarVec2);
  begin
    LDx := ACandidate.X - APreferred.X;
    LDy := ACandidate.Y - APreferred.Y;
    LXX := LDx * LDx;
    LYY := LDy * LDy;
    LSquare := LXX + LYY;
    LScore := Sqrt(LSquare);
    if LScore < LBestScore then
    begin
      LBestScore := LScore;
      LBest := ACandidate;
    end;
  end;

begin
  LXX := APreferred.X * APreferred.X;
  LYY := APreferred.Y * APreferred.Y;
  LSquare := LXX + LYY;
  LLength := Sqrt(LSquare);
  if not ((LLength > AMaxSpeed) and (LLength > SINGLE_MICRO)) then
    Exit(APreferred);
  LInverse := AMaxSpeed / LLength;
  LBest.X := APreferred.X * LInverse;
  LBest.Y := APreferred.Y * LInverse;
  LDx := LBest.X - APreferred.X;
  LDy := LBest.Y - APreferred.Y;
  LXX := LDx * LDx;
  LYY := LDy * LDy;
  LSquare := LXX + LYY;
  LBestScore := Sqrt(LSquare);
  LAngleStep := 2.0 * SINGLE_PI;
  LAngleStep := LAngleStep / RING_COUNT;
  for LRing := 0 to 1 do
  begin
    if LRing = 0 then
      LSpeed := AMaxSpeed
    else
      LSpeed := AMaxSpeed * 0.5;
    for LStep := 0 to RING_COUNT - 1 do
    begin
      LAngle := LStep * LAngleStep;
      LCosine := Cos(LAngle);
      LSine := Sin(LAngle);
      LCandidate.X := LCosine * LSpeed;
      LCandidate.Y := LSine * LSpeed;
      Consider(LCandidate);
    end;
  end;
  LCandidate.X := 0;
  LCandidate.Y := 0;
  Consider(LCandidate);
  Result := LBest;
end;

end.
