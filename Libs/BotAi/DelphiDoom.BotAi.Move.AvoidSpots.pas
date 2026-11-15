{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotAvoidSpotChecker, the spots the bots avoid         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotAvoidSpots,      }
{  DistanceFromLineSquared and VectorDistanceSquared of code\botlib\           }
{  be_ai_move.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.AvoidSpots;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types;

type
  /// <summary>
  ///   Is a reachability a way towards a spot the bot should stay away from. Defect of the original kept: when the
  ///   travel type does not check the way between the start and the end, the test that is meant to look at the end
  ///   of the reachability uses the distance of the start (the result of <c>VectorDistanceSquared(spot, end)</c> is
  ///   thrown away).
  /// </summary>
  TBotAvoidSpotChecker = class
  public
    /// <summary>VectorDistanceSquared</summary>
    class function DistanceSquared(const AFirst, ASecond: TVec3): Single; static;
    /// <summary>DistanceFromLineSquared: the squared distance of a point from the line segment</summary>
    class function DistanceFromLineSquared(const APoint, ALineStart, ALineEnd: TVec3): Single; static;
    /// <summary>
    ///   BotAvoidSpots: the type of the spot that the move from the origin by the reachability goes towards
    ///   (AVOID_CLEAR if none; AVOID_ALWAYS ends the search)
    /// </summary>
    class function Check(const AOrigin: TVec3; const AReach: TAasReachability;
      const ASpots: array of TBotAvoidSpot; const ANumSpots: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Main.System, DelphiDoom.BotAi.Move.VectorMath;

{ TBotAvoidSpotChecker }

class function TBotAvoidSpotChecker.DistanceSquared(const AFirst, ASecond: TVec3): Single;
var
  LDir: TVec3;
begin
  TAasVectorMath.Subtract(ASecond, AFirst, LDir);
  Result := TBotVectorMath.LengthSquared(LDir);
end;

class function TBotAvoidSpotChecker.DistanceFromLineSquared(const APoint, ALineStart, ALineEnd: TVec3): Single;
var
  LProj: TVec3;
  LDir: TVec3;
  LIndex: Integer;
begin
  LProj := TAasSystem.ProjectPointOntoVector(APoint, ALineStart, ALineEnd);
  LIndex := 0;
  while LIndex < 3 do
  begin
    if ((LProj[LIndex] > ALineStart[LIndex]) and (LProj[LIndex] > ALineEnd[LIndex])) or
      ((LProj[LIndex] < ALineStart[LIndex]) and (LProj[LIndex] < ALineEnd[LIndex])) then
      Break;
    Inc(LIndex);
  end;
  if LIndex < 3 then
  begin
    if Abs(LProj[LIndex] - ALineStart[LIndex]) < Abs(LProj[LIndex] - ALineEnd[LIndex]) then
      TAasVectorMath.Subtract(APoint, ALineStart, LDir)
    else
      TAasVectorMath.Subtract(APoint, ALineEnd, LDir);
    Exit(TBotVectorMath.LengthSquared(LDir));
  end;
  TAasVectorMath.Subtract(APoint, LProj, LDir);
  Result := TBotVectorMath.LengthSquared(LDir);
end;

class function TBotAvoidSpotChecker.Check(const AOrigin: TVec3; const AReach: TAasReachability;
  const ASpots: array of TBotAvoidSpot; const ANumSpots: Integer): Integer;
var
  LCheckBetween: Boolean;
  LIndex: Integer;
  LType: Integer;
  LSquaredDist: Single;
  LSquaredRadius: Single;
  LStart: TVec3;
  LEnd: TVec3;
begin
  case AReach.TravelType and $FFFFFF of
    TRAVEL_WALK, TRAVEL_CROUCH, TRAVEL_BARRIERJUMP, TRAVEL_LADDER, TRAVEL_SWIM, TRAVEL_WATERJUMP:
      LCheckBetween := True;
    TRAVEL_WALKOFFLEDGE, TRAVEL_JUMP, TRAVEL_TELEPORT, TRAVEL_ELEVATOR, TRAVEL_GRAPPLEHOOK, TRAVEL_ROCKETJUMP,
      TRAVEL_BFGJUMP, TRAVEL_JUMPPAD, TRAVEL_FUNCBOB:
      LCheckBetween := False;
  else
    LCheckBetween := True;
  end;
  LStart := AReach.StartPoint;
  LEnd := AReach.EndPoint;
  LType := AVOID_CLEAR;
  LSquaredDist := 0;
  for LIndex := 0 to ANumSpots - 1 do
  begin
    LSquaredRadius := ASpots[LIndex].Radius * ASpots[LIndex].Radius;
    LSquaredDist := DistanceFromLineSquared(ASpots[LIndex].Origin, AOrigin, LStart);
    // if moving towards the avoid spot
    if (LSquaredDist < LSquaredRadius) and (DistanceSquared(ASpots[LIndex].Origin, AOrigin) > LSquaredDist) then
      LType := ASpots[LIndex].SpotType
    else if LCheckBetween then
    begin
      LSquaredDist := DistanceFromLineSquared(ASpots[LIndex].Origin, LStart, LEnd);
      // if moving towards the avoid spot
      if (LSquaredDist < LSquaredRadius) and (DistanceSquared(ASpots[LIndex].Origin, LStart) > LSquaredDist) then
        LType := ASpots[LIndex].SpotType;
    end
    else
    begin
      // the original discards the distance to the end of the reachability
      DistanceSquared(ASpots[LIndex].Origin, LEnd);
      // if the reachability leads closer to the avoid spot
      if (LSquaredDist < LSquaredRadius) and (DistanceSquared(ASpots[LIndex].Origin, LStart) > LSquaredDist) then
        LType := ASpots[LIndex].SpotType;
    end;
    if LType = AVOID_ALWAYS then
      Exit(LType);
  end;
  Result := LType;
end;

end.
