{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotReachabilityLocator, the area a bot is in          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later):                     }
{  BotFuzzyPointReachabilityArea and BotReachabilityArea of code\botlib\       }
{  be_ai_move.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Locator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Move.Intf,
  DelphiDoom.BotAi.Move.ModelTypes;

type
  /// <summary>Finds the area with reachabilities a point is in, or near</summary>
  TBotReachabilityLocator = class(TInterfacedObject, IBotReachabilityLocator)
  strict private
    FImport: IBotImport;
    FWorld: IBotAasWorld;
    FModelTypes: TBotBrushModelTypes;
  public
    constructor Create(const AImport: IBotImport; const AWorld: IBotAasWorld;
      const AModelTypes: TBotBrushModelTypes);
    function FuzzyPointReachabilityArea(const AOrigin: TVec3): Integer;
    function ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.BoxMath,
  DelphiDoom.Aas.VectorMath,
  DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.VectorMath;

const
  /// <summary>CONTENTS_SOLID or CONTENTS_PLAYERCLIP</summary>
  MASK_SOLID_PLAYERCLIP = $00010001;
  MAX_FUZZY_AREAS = 10;

{ TBotReachabilityLocator }

constructor TBotReachabilityLocator.Create(const AImport: IBotImport; const AWorld: IBotAasWorld;
  const AModelTypes: TBotBrushModelTypes);
begin
  inherited Create;
  FImport := AImport;
  FWorld := AWorld;
  FModelTypes := AModelTypes;
end;

function TBotReachabilityLocator.FuzzyPointReachabilityArea(const AOrigin: TVec3): Integer;
var
  LFirstArea: Integer;
  LAreaNum: Integer;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LNumAreas: Integer;
  LBestArea: Integer;
  LBestDist: Single;
  LDist: Single;
  LEnd: TVec3;
  LDelta: TVec3;
  LJ, LX, LY, LZ: Integer;
begin
  LFirstArea := 0;
  LAreaNum := FWorld.Sampler.PointAreaNum(AOrigin);
  if LAreaNum <> 0 then
  begin
    LFirstArea := LAreaNum;
    if FWorld.Areas.AreaReachability(LAreaNum) <> 0 then
      Exit(LAreaNum);
  end;
  LEnd := AOrigin;
  LEnd[2] := LEnd[2] + 4;
  LNumAreas := FWorld.Tracer.TraceAreas(AOrigin, LEnd, MAX_FUZZY_AREAS, LAreas, LPoints);
  for LJ := 0 to LNumAreas - 1 do
  begin
    if FWorld.Areas.AreaReachability(LAreas[LJ]) <> 0 then
      Exit(LAreas[LJ]);
  end;
  LBestDist := 999999;
  LBestArea := 0;
  for LZ := 1 downto -1 do
  begin
    for LX := 1 downto -1 do
    begin
      for LY := 1 downto -1 do
      begin
        LEnd := AOrigin;
        LEnd[0] := LEnd[0] + LX * 8;
        LEnd[1] := LEnd[1] + LY * 8;
        LEnd[2] := LEnd[2] + LZ * 12;
        LNumAreas := FWorld.Tracer.TraceAreas(AOrigin, LEnd, MAX_FUZZY_AREAS, LAreas, LPoints);
        for LJ := 0 to LNumAreas - 1 do
        begin
          if FWorld.Areas.AreaReachability(LAreas[LJ]) <> 0 then
          begin
            TAasVectorMath.Subtract(LPoints[LJ], AOrigin, LDelta);
            LDist := TAasVectorMath.Length(LDelta);
            if LDist < LBestDist then
            begin
              LBestArea := LAreas[LJ];
              LBestDist := LDist;
            end;
          end;
          if LFirstArea = 0 then
            LFirstArea := LAreas[LJ];
        end;
      end;
    end;
    if LBestArea <> 0 then
      Exit(LBestArea);
  end;
  Result := LFirstArea;
end;

function TBotReachabilityLocator.ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
const
  UP: TVec3 = (0, 0, 1);
var
  LMins: TVec3;
  LMaxs: TVec3;
  LEnd: TVec3;
  LOrg: TVec3;
  LBspTrace: TAasBspTrace;
  LTrace: TAasTrace;
  LModelNum: Integer;
  LModelType: Integer;
  LReachNum: Integer;
  LReach: TAasReachability;
  LAreaNum: Integer;
begin
  // check if the bot is standing on something
  TAasBoxMath.PresenceTypeBoundingBox(FImport, PRESENCE_CROUCH, LMins, LMaxs);
  TBotVectorMath.MultiplyAdd(AOrigin, -3, UP, LEnd);
  LBspTrace := FWorld.Bsp.Trace(AOrigin, @LMins, @LMaxs, LEnd, AClient, MASK_SOLID_PLAYERCLIP);
  if (not LBspTrace.StartSolid) and (LBspTrace.Fraction < 1) and (LBspTrace.EntityNum <> ENTITYNUM_NONE) then
  begin
    // if standing on the world the bot should be in a valid area
    if LBspTrace.EntityNum = ENTITYNUM_WORLD then
      Exit(FuzzyPointReachabilityArea(AOrigin));
    LModelNum := FWorld.Entities.EntityModelIndex(LBspTrace.EntityNum);
    LModelType := FModelTypes.ModelType(LModelNum);
    // if standing on a func_plat or func_bobbing then the bot is assumed to be in the area the reachability points to
    if (LModelType = MODELTYPE_FUNC_PLAT) or (LModelType = MODELTYPE_FUNC_BOB) then
    begin
      LReachNum := FWorld.Router.NextModelReachability(0, LModelNum);
      if LReachNum <> 0 then
      begin
        FWorld.Router.ReachabilityFromNum(LReachNum, LReach);
        Exit(LReach.AreaNum);
      end;
    end;
    // if the bot is swimming the bot should be in a valid area
    if FWorld.Movement.Swimming(AOrigin) then
      Exit(FuzzyPointReachabilityArea(AOrigin));
    LAreaNum := FuzzyPointReachabilityArea(AOrigin);
    // if the bot is in an area with reachabilities
    if (LAreaNum <> 0) and (FWorld.Areas.AreaReachability(LAreaNum) <> 0) then
      Exit(LAreaNum);
    // trace down till the ground is hit because the bot is standing on some other entity
    LOrg := AOrigin;
    LEnd := LOrg;
    LEnd[2] := LEnd[2] - 800;
    LTrace := FWorld.Tracer.TraceClientBBox(LOrg, LEnd, PRESENCE_CROUCH, -1);
    if not LTrace.StartSolid then
      LOrg := LTrace.EndPos;
    Exit(FuzzyPointReachabilityArea(LOrg));
  end;
  Result := FuzzyPointReachabilityArea(AOrigin);
end;

end.
