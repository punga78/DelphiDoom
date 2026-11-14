{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the avoidance between units                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_rvo.c, wrvo_computeNewVelocity, (c) 2019   }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Rvo;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types;

const
  /// <summary>RVO_MAX_NB: the most neighbors that a unit looks at</summary>
  WAR_RVO_MAX_NEIGHBOURS = 16;
  /// <summary>RVO_RING_N: the directions of each of the two rings of candidate velocities</summary>
  WAR_RVO_RING = 16;
  /// <summary>RVO_MAX_CANDIDATES: the preferred velocity, the two rings and a stop</summary>
  WAR_RVO_MAX_CANDIDATES = 1 + WAR_RVO_RING * 2 + 1;

type
  /// <summary>WarRvoNeighbour: another unit as the avoidance sees it</summary>
  TWarRvoNeighbour = record
    Position: TWarVec2;
    Velocity: TWarVec2;
    Radius: Single;
  end;

  /// <summary>The neighbors of a unit (out[RVO_MAX_NB] and the count)</summary>
  TWarRvoNeighbours = record
    Count: Integer;
    Items: array[0..WAR_RVO_MAX_NEIGHBOURS - 1] of TWarRvoNeighbour;
  end;

  /// <summary>
  ///   The debug outputs of wrvo_computeNewVelocity (outCandidates, outNumCandidates, outBestIndex and
  ///   outCandidateHadCollision): what the original draws on the debug screen, kept here only for the tests
  /// </summary>
  TWarRvoDebug = record
    Candidates: array[0..WAR_RVO_MAX_CANDIDATES - 1] of TWarVec2;
    Count: Integer;
    BestIndex: Integer;
    HadCollision: array[0..WAR_RVO_MAX_CANDIDATES - 1] of Boolean;
  end;

  PWarRvoDebug = ^TWarRvoDebug;

  /// <summary>
  ///   wrvo_computeNewVelocity: the velocity of a unit that wants to go at APreferred, with the neighbors that are near.
  ///   It is not ORCA: it tries 34 velocities (the preferred one cut to the maximum speed, two rings of 16 directions at
  ///   the maximum speed and at half of it, and a stop), gives each one a score (how far it is from the preferred one,
  ///   plus a penalty for each neighbor it would hit within two seconds, assuming the neighbor takes half of the
  ///   avoidance) and takes the lowest; the first of the list wins a tie. Every operation of the original is a 32 bit
  ///   float operation, here one assignment to a Single each (at Win32 the x87 would keep more bits)
  /// </summary>
  TWarRvo = class
  strict private
    type
      // what does not depend on the candidate velocity, once per neighbor: the position of A relative to B, and the part of the
      // time to collision that is a constant of the pair (c: how far the two discs are from touching, squared; negative: overlap)
      TPairs = record
        RelX: array[0..WAR_RVO_MAX_NEIGHBOURS - 1] of Single;
        RelY: array[0..WAR_RVO_MAX_NEIGHBOURS - 1] of Single;
        C: array[0..WAR_RVO_MAX_NEIGHBOURS - 1] of Single;
      end;
    class function TimeToCollision(const APositionA, AVelocityA, APositionB, AVelocityB: TWarVec2; ARadius: Single;
      const ACandidate: TWarVec2): Single; static;
    class procedure PreparePairs(const APositionA: TWarVec2; ARadiusA: Single; const ANeighbours: TWarRvoNeighbours;
      var APairs: TPairs); static;
    class function Score(const ACandidate, APreferred, AVelocityA: TWarVec2; AWeight: Single;
      const ANeighbours: TWarRvoNeighbours; const APairs: TPairs): Single; static;
  public
    /// <summary>
    ///   The new velocity (never longer than AMaxSpeed); ADeltaTime is not used (it is there for the ORCA variant, in the
    ///   original too). ADebug is nil in the game
    /// </summary>
    class function ComputeNewVelocity(const APreferred, APositionA, AVelocityA: TWarVec2; ARadiusA, AMaxSpeed,
      ADeltaTime: Single; const ANeighbours: TWarRvoNeighbours; ADebug: PWarRvoDebug = nil): TWarVec2; static;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Model.Math;

const
  // the float constants of war_rvo.h
  TIME_HORIZON: Single = 2.0;
  COLLISION_WEIGHT: Single = 1.5;
  DEVIATION_WEIGHT: Single = 1.0;
  FLOAT_MAX: Single = 3.402823466E+38;
  // PI of war_math.h is a float
  SINGLE_PI: Single = 3.14159265358979323846;
  MICRO: Single = 1E-6;
  NANO: Single = 1E-8;

{ TWarRvo }

class function TWarRvo.TimeToCollision(const APositionA, AVelocityA, APositionB, AVelocityB: TWarVec2;
  ARadius: Single; const ACandidate: TWarVec2): Single;
var
  LRelPosX: Single;
  LRelPosY: Single;
  LRelVelX: Single;
  LRelVelY: Single;
  LTwiceX: Single;
  LTwiceY: Single;
  LProductX: Single;
  LProductY: Single;
  LA: Single;
  LB: Single;
  LC: Single;
  LRadiusSqr: Single;
  LDiscriminant: Single;
  LRoot: Single;
  LNumerator: Single;
  LTime: Single;
begin
  // relPos: the position of A relative to B
  LRelPosX := APositionA.X - APositionB.X;
  LRelPosY := APositionA.Y - APositionB.Y;
  // the relative velocity under the assumption that B steers away as much as A: 2 * candidate - (velocityA + velocityB)
  LTwiceX := 2.0 * ACandidate.X;
  LTwiceX := LTwiceX - AVelocityA.X;
  LRelVelX := LTwiceX - AVelocityB.X;
  LTwiceY := 2.0 * ACandidate.Y;
  LTwiceY := LTwiceY - AVelocityA.Y;
  LRelVelY := LTwiceY - AVelocityB.Y;
  LProductX := LRelVelX * LRelVelX;
  LProductY := LRelVelY * LRelVelY;
  LA := LProductX + LProductY;
  LProductX := LRelPosX * LRelVelX;
  LProductY := LRelPosY * LRelVelY;
  LB := LProductX + LProductY;
  LProductX := LRelPosX * LRelPosX;
  LProductY := LRelPosY * LRelPosY;
  LC := LProductX + LProductY;
  LRadiusSqr := ARadius * ARadius;
  LC := LC - LRadiusSqr;
  // already overlapping: immediate collision
  if LC < 0.0 then
    Exit(0.0);
  // no relative motion
  if LA < NANO then
    Exit(FLOAT_MAX);
  LProductX := LB * LB;
  LProductY := LA * LC;
  LDiscriminant := LProductX - LProductY;
  // the paths do not meet
  if LDiscriminant < 0.0 then
    Exit(FLOAT_MAX);
  LRoot := Sqrt(LDiscriminant);
  LNumerator := -LB;
  LNumerator := LNumerator - LRoot;
  LTime := LNumerator / LA;
  if LTime >= 0.0 then
    Result := LTime
  else
    Result := FLOAT_MAX;
end;

class procedure TWarRvo.PreparePairs(const APositionA: TWarVec2; ARadiusA: Single; const ANeighbours: TWarRvoNeighbours;
  var APairs: TPairs);
var
  LIndex: Integer;
  LRadius: Single;
  LRadiusSqr: Single;
  LProductX: Single;
  LProductY: Single;
  LC: Single;
begin
  for LIndex := 0 to ANeighbours.Count - 1 do
  begin
    APairs.RelX[LIndex] := APositionA.X - ANeighbours.Items[LIndex].Position.X;
    APairs.RelY[LIndex] := APositionA.Y - ANeighbours.Items[LIndex].Position.Y;
    LRadius := ARadiusA + ANeighbours.Items[LIndex].Radius;
    LRadiusSqr := LRadius * LRadius;
    LProductX := APairs.RelX[LIndex] * APairs.RelX[LIndex];
    LProductY := APairs.RelY[LIndex] * APairs.RelY[LIndex];
    LC := LProductX + LProductY;
    APairs.C[LIndex] := LC - LRadiusSqr;
  end;
end;

// wrvo_score with wrvo_tcc written out in the loop: the same operations on the same values, in the same order, with what
// does not depend on the candidate (the relative position, c, 2 * candidate - velocityA, the weight) computed once
class function TWarRvo.Score(const ACandidate, APreferred, AVelocityA: TWarVec2; AWeight: Single;
  const ANeighbours: TWarRvoNeighbours; const APairs: TPairs): Single;
var
  LDx: Single;
  LDy: Single;
  LProductX: Single;
  LProductY: Single;
  LSum: Single;
  LRoot: Single;
  LIndex: Integer;
  LTwiceX: Single;
  LTwiceY: Single;
  LRelVelX: Single;
  LRelVelY: Single;
  LA: Single;
  LB: Single;
  LDiscriminant: Single;
  LNumerator: Single;
  LTime: Single;
  LRemaining: Single;
  LPenalty: Single;
begin
  // the deviation from the preferred velocity (the distance in the space of velocities)
  LDx := ACandidate.X - APreferred.X;
  LDy := ACandidate.Y - APreferred.Y;
  LProductX := LDx * LDx;
  LProductY := LDy * LDy;
  LSum := LProductX + LProductY;
  LRoot := System.Sqrt(Double(LSum));
  Result := DEVIATION_WEIGHT * LRoot;
  LTwiceX := 2.0 * ACandidate.X;
  LTwiceX := LTwiceX - AVelocityA.X;
  LTwiceY := 2.0 * ACandidate.Y;
  LTwiceY := LTwiceY - AVelocityA.Y;
  // the penalty for every neighbor that would be hit before the horizon
  for LIndex := 0 to ANeighbours.Count - 1 do
  begin
    if APairs.C[LIndex] < 0.0 then
      // already overlapping: immediate collision
      LTime := 0.0
    else
    begin
      LRelVelX := LTwiceX - ANeighbours.Items[LIndex].Velocity.X;
      LRelVelY := LTwiceY - ANeighbours.Items[LIndex].Velocity.Y;
      LProductX := LRelVelX * LRelVelX;
      LProductY := LRelVelY * LRelVelY;
      LA := LProductX + LProductY;
      if LA < NANO then
        // no relative motion
        LTime := FLOAT_MAX
      else
      begin
        LProductX := APairs.RelX[LIndex] * LRelVelX;
        LProductY := APairs.RelY[LIndex] * LRelVelY;
        LB := LProductX + LProductY;
        LProductX := LB * LB;
        LProductY := LA * APairs.C[LIndex];
        LDiscriminant := LProductX - LProductY;
        if LDiscriminant < 0.0 then
          // the paths do not meet
          LTime := FLOAT_MAX
        else
        begin
          // the square root of a 32 bit float through the 64 bit one is as exact as sqrtf (the double rounding cannot show)
          LRoot := System.Sqrt(Double(LDiscriminant));
          LNumerator := -LB;
          LNumerator := LNumerator - LRoot;
          LTime := LNumerator / LA;
          if not (LTime >= 0.0) then
            LTime := FLOAT_MAX;
        end;
      end;
    end;
    if LTime < TIME_HORIZON then
    begin
      LRemaining := TIME_HORIZON - LTime;
      LPenalty := AWeight * LRemaining;
      Result := Result + LPenalty;
    end;
  end;
end;

class function TWarRvo.ComputeNewVelocity(const APreferred, APositionA, AVelocityA: TWarVec2; ARadiusA, AMaxSpeed,
  ADeltaTime: Single; const ANeighbours: TWarRvoNeighbours; ADebug: PWarRvoDebug): TWarVec2;
var
  LCandidates: array[0..WAR_RVO_MAX_CANDIDATES - 1] of TWarVec2;
  LCount: Integer;
  LLength: Single;
  LInverse: Single;
  LSpeeds: array[0..1] of Single;
  LRing: Integer;
  LStep: Integer;
  LSpeed: Single;
  LAngleStep: Single;
  LAngle: Single;
  LCosine: Single;
  LSine: Single;
  LBestIndex: Integer;
  LBestScore: Single;
  LScore: Single;
  LIndex: Integer;
  LNeighbour: Integer;
  LRadius: Single;
  LTime: Single;
  LHad: Boolean;
  LPairs: TPairs;
  LWeight: Single;
begin
  LCount := 0;
  // the preferred velocity, cut to the maximum speed
  LLength := TWarModelMath.Length(APreferred);
  if (LLength > AMaxSpeed) and (LLength > MICRO) then
  begin
    LInverse := AMaxSpeed / LLength;
    LCandidates[LCount].X := APreferred.X * LInverse;
    LCandidates[LCount].Y := APreferred.Y * LInverse;
  end
  else
    LCandidates[LCount] := APreferred;
  Inc(LCount);
  // the rings at the maximum speed and at half of it
  LSpeeds[0] := AMaxSpeed;
  LSpeeds[1] := AMaxSpeed * 0.5;
  LAngleStep := 2.0 * SINGLE_PI;
  LAngleStep := LAngleStep / WAR_RVO_RING;
  for LRing := 0 to 1 do
  begin
    LSpeed := LSpeeds[LRing];
    for LStep := 0 to WAR_RVO_RING - 1 do
    begin
      LAngle := LStep * LAngleStep;
      LCosine := Cos(LAngle);
      LSine := Sin(LAngle);
      LCandidates[LCount].X := LCosine * LSpeed;
      LCandidates[LCount].Y := LSine * LSpeed;
      Inc(LCount);
    end;
  end;
  // the stop
  LCandidates[LCount].X := 0.0;
  LCandidates[LCount].Y := 0.0;
  Inc(LCount);
  PreparePairs(APositionA, ARadiusA, ANeighbours, LPairs);
  LWeight := COLLISION_WEIGHT * AMaxSpeed;
  LBestIndex := 0;
  LBestScore := Score(LCandidates[0], APreferred, AVelocityA, LWeight, ANeighbours, LPairs);
  for LIndex := 1 to LCount - 1 do
  begin
    LScore := Score(LCandidates[LIndex], APreferred, AVelocityA, LWeight, ANeighbours, LPairs);
    if LScore < LBestScore then
    begin
      LBestScore := LScore;
      LBestIndex := LIndex;
    end;
  end;
  if Assigned(ADebug) then
  begin
    for LIndex := 0 to LCount - 1 do
    begin
      ADebug^.Candidates[LIndex] := LCandidates[LIndex];
      LHad := False;
      for LNeighbour := 0 to ANeighbours.Count - 1 do
      begin
        LRadius := ARadiusA + ANeighbours.Items[LNeighbour].Radius;
        LTime := TimeToCollision(APositionA, AVelocityA, ANeighbours.Items[LNeighbour].Position,
          ANeighbours.Items[LNeighbour].Velocity, LRadius, LCandidates[LIndex]);
        if LTime < TIME_HORIZON then
        begin
          LHad := True;
          Break;
        end;
      end;
      ADebug^.HadCollision[LIndex] := LHad;
    end;
    ADebug^.Count := LCount;
    ADebug^.BestIndex := LBestIndex;
  end;
  Result := LCandidates[LBestIndex];
end;

end.
