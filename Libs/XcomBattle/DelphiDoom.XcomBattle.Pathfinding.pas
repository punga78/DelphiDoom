{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the paths of the units (Pathfinding)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Pathfinding;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Directions,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.PathfindingNode, DelphiDoom.XcomBattle.PathfindingOpenSet;

const
  /// <summary>Pathfinding::bigWallTypes and O_BIGWALL</summary>
  BIGWALL_BLOCK = 1;
  BIGWALL_NESW = 2;
  BIGWALL_NWSE = 3;
  BIGWALL_WEST = 4;
  BIGWALL_NORTH = 5;
  BIGWALL_EAST = 6;
  BIGWALL_SOUTH = 7;
  BIGWALL_EAST_AND_SOUTH = 8;
  BIGWALL_WEST_AND_NORTH = 9;
  PART_BIGWALL = -1;

type
  /// <summary>
  ///   Finds the shortest path of a unit on the map with a fast straight line first and A* if that fails, and the
  ///   tiles a unit can reach (Pathfinding). Holds the saved battle without owning it. The path preview (it
  ///   draws on the tiles through BattlescapeGame) and the strafing move (it reads the keyboard) are not ported
  /// </summary>
  TXcomPathfinding = class(TInterfacedObject, IXcomBattlePathfinder)
  strict private
    FSave: TXcomSavedBattleGame;
    FNodes: TObjectList<TXcomPathfindingNode>;
    FUnit: TXcomBattleUnit;
    FTotalTuCost: Integer;
    FMovementType: Integer;
    FSneakyAi: Boolean;
    FPath: TList<Integer>;
    function GetNode(const APosition: TXcomPosition): TXcomPathfindingNode;
    class function NeedTile(const ATile: TXcomTile): TXcomTile; static;
    function IsBlockedPart(const ATile: TXcomTile; APart: Integer; const AMissileTarget: TXcomBattleUnit;
      ABigWallExclusion: Integer = -1): Boolean;
    function BresenhamPath(const AOrigin, ATarget: TXcomPosition; const ATargetUnit: TXcomBattleUnit;
      ASneak: Boolean; AMaxTuCost: Integer = 1000): Boolean;
    function AStarPath(const AStart, AEnd: TXcomPosition; const ATarget: TXcomBattleUnit; ASneak: Boolean;
      AMaxTuCost: Integer = 1000): Boolean;
    function CanFallDownTile(const AHere: TXcomTile): Boolean;
    function CanFallDownSize(const AHere: TXcomTile; ASize: Integer): Boolean;
  public
    /// <param name="ASneakyAi">Options::sneakyAI: hostile units avoid the tiles that are visible</param>
    constructor Create(const ASave: TXcomSavedBattleGame; ASneakyAi: Boolean = False);
    destructor Destroy; override;
    /// <summary>calculate: AMaxTuCost -1 with a target is the path of a missile</summary>
    procedure Calculate(const AUnit: TXcomBattleUnit; AEndPosition: TXcomPosition;
      const ATarget: TXcomBattleUnit = nil; AMaxTuCost: Integer = 1000);
    /// <summary>getTUCost: one step; it also gives the end position (stairs and falls change the level)</summary>
    function GetTuCost(const AStart: TXcomPosition; ADirection: Integer; out AEnd: TXcomPosition;
      const AUnit, ATarget: TXcomBattleUnit; AMissile: Boolean): Integer;
    function GetStartDirection: Integer;
    function DequeuePath: Integer;
    procedure AbortPath;
    function IsBlocked(const AStart, AEnd: TXcomTile; ADirection: Integer; const AMissileTarget: TXcomBattleUnit)
      : Boolean; overload;
    function IsBlocked(const ATile: TXcomTile; APart: Integer; const AMissileTarget: TXcomBattleUnit;
      ABigWallExclusion: Integer = -1): Boolean; overload;
    function IsOnStairs(const AStart, AEnd: TXcomPosition): Boolean;
    function ValidateUpDown(const AUnit: TXcomBattleUnit; const AStart: TXcomPosition; ADirection: Integer;
      AMissile: Boolean = False): Boolean;
    /// <summary>findReachable: the indexes of the tiles that the unit reaches, the nearest first; ties keep the order of the search</summary>
    function FindReachable(const AUnit: TXcomBattleUnit; ATuMax: Integer): TArray<Integer>;
    procedure SetUnit(const AUnit: TXcomBattleUnit);
    property TotalTuCost: Integer read FTotalTuCost;
    /// <summary>The path in the order of the walk (the C++ keeps it reversed)</summary>
    function Path: TArray<Integer>;
  end;

implementation

{ TXcomPathfinding }

constructor TXcomPathfinding.Create(const ASave: TXcomSavedBattleGame; ASneakyAi: Boolean);
var
  LIndex: Integer;
  LPosition: TXcomPosition;
begin
  inherited Create;
  FSave := ASave;
  FSneakyAi := ASneakyAi;
  FMovementType := MT_WALK;
  FPath := TList<Integer>.Create;
  FNodes := TObjectList<TXcomPathfindingNode>.Create(True);
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
  begin
    FSave.TileCoords(LIndex, LPosition.X, LPosition.Y, LPosition.Z);
    FNodes.Add(TXcomPathfindingNode.Create(LPosition));
  end;
end;

destructor TXcomPathfinding.Destroy;
begin
  FNodes.Free;
  FPath.Free;
  inherited Destroy;
end;

class function TXcomPathfinding.NeedTile(const ATile: TXcomTile): TXcomTile;
begin
  if not Assigned(ATile) then
    raise EXcomBattleException.Create('Xcom: the pathfinding needs a tile that is not on the map');
  Result := ATile;
end;

function TXcomPathfinding.GetNode(const APosition: TXcomPosition): TXcomPathfindingNode;
begin
  Result := FNodes[FSave.TileIndex(APosition)];
end;

function TXcomPathfinding.Path: TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, FPath.Count);
  for LIndex := 0 to FPath.Count - 1 do
    Result[LIndex] := FPath[FPath.Count - 1 - LIndex];
end;

procedure TXcomPathfinding.SetUnit(const AUnit: TXcomBattleUnit);
begin
  FUnit := AUnit;
  if Assigned(AUnit) then
    FMovementType := AUnit.MovementType
  else
    FMovementType := MT_WALK;
end;

procedure TXcomPathfinding.Calculate(const AUnit: TXcomBattleUnit; AEndPosition: TXcomPosition;
  const ATarget: TXcomBattleUnit; AMaxTuCost: Integer);
const
  CORNER_DIRECTIONS: array[0..2] of Integer = (4, 2, 3);
var
  LSneak: Boolean;
  LStart: TXcomPosition;
  LDestination: TXcomTile;
  LSize: Integer;
  LIterations: Integer;
  LX: Integer;
  LY: Integer;
  LCheck: TXcomTile;
begin
  FTotalTuCost := 0;
  FPath.Clear;
  if (AEndPosition.X > FSave.MapSizeX - AUnit.Armor.Size) or (AEndPosition.Y > FSave.MapSizeY - AUnit.Armor.Size) or
    (AEndPosition.X < 0) or (AEndPosition.Y < 0) then
    Exit;
  LSneak := FSneakyAi and (AUnit.Faction = FACTION_HOSTILE);
  LStart := AUnit.Position;
  FMovementType := AUnit.MovementType;
  if Assigned(ATarget) and (AMaxTuCost = -1) then
  begin
    FMovementType := MT_FLY;
    AMaxTuCost := 10000;
  end;
  FUnit := AUnit;
  LDestination := FSave.TileAt(AEndPosition);
  if IsBlockedPart(LDestination, XCOM_PART_FLOOR, ATarget) or IsBlockedPart(LDestination, XCOM_PART_OBJECT, ATarget) then
    Exit;
  // walking behind the stairs when we click behind them to go up
  if IsOnStairs(LStart, AEndPosition) then
  begin
    Inc(AEndPosition.Z);
    LDestination := FSave.TileAt(AEndPosition);
  end;
  while (AEndPosition.Z <> FSave.MapSizeZ) and (NeedTile(LDestination).GetTerrainLevel = -24) do
  begin
    Inc(AEndPosition.Z);
    LDestination := FSave.TileAt(AEndPosition);
  end;
  // a terrain level -24 object on the top floor leaves the destination outside the map
  if AEndPosition.Z = FSave.MapSizeZ then
    Exit;
  while CanFallDownSize(NeedTile(LDestination), FUnit.Armor.Size) and (FMovementType <> MT_FLY) do
  begin
    Dec(AEndPosition.Z);
    LDestination := FSave.TileAt(AEndPosition);
  end;
  if IsBlockedPart(LDestination, XCOM_PART_FLOOR, ATarget) or IsBlockedPart(LDestination, XCOM_PART_OBJECT, ATarget) then
    Exit;
  LSize := AUnit.Armor.Size - 1;
  if LSize >= 1 then
  begin
    LIterations := 0;
    LX := 0;
    while LX <= LSize do
    begin
      LY := 0;
      while LY <= LSize do
      begin
        if (LX <> 0) or (LY <> 0) then
        begin
          LCheck := FSave.TileAt(AEndPosition + TXcomPosition.Make(LX, LY, 0));
          if (IsBlocked(LDestination, LCheck, CORNER_DIRECTIONS[LIterations], AUnit) and
            IsBlocked(LDestination, LCheck, CORNER_DIRECTIONS[LIterations], ATarget)) or
            (Assigned(LCheck.CurrentUnit) and (LCheck.CurrentUnit <> AUnit) and LCheck.CurrentUnit.GetVisible and
            (LCheck.CurrentUnit <> ATarget)) then
            Exit;
          if (LX <> 0) and (LY <> 0) then
            if (Assigned(LCheck.MapData[XCOM_PART_NORTHWALL]) and LCheck.MapData[XCOM_PART_NORTHWALL].IsDoor) or
              (Assigned(LCheck.MapData[XCOM_PART_WESTWALL]) and LCheck.MapData[XCOM_PART_WESTWALL].IsDoor) then
              Exit;
          Inc(LIterations);
        end;
        if LSize = 0 then
          Break;
        Inc(LY, LSize);
      end;
      if LSize = 0 then
        Break;
      Inc(LX, LSize);
    end;
  end;
  // a fast and accurate straight path first, A* if it fails
  if (LStart.Z = AEndPosition.Z) and BresenhamPath(LStart, AEndPosition, ATarget, LSneak) then
  begin
    FPath.Reverse;
    Exit;
  end
  else
    AbortPath;
  if not AStarPath(LStart, AEndPosition, ATarget, LSneak, AMaxTuCost) then
    AbortPath;
end;

function TXcomPathfinding.AStarPath(const AStart, AEnd: TXcomPosition; const ATarget: TXcomBattleUnit;
  ASneak: Boolean; AMaxTuCost: Integer): Boolean;
var
  LNode: TXcomPathfindingNode;
  LStartNode: TXcomPathfindingNode;
  LOpen: TXcomPathfindingOpenSet;
  LMissile: Boolean;
  LCurrent: TXcomPathfindingNode;
  LDirection: Integer;
  LNextPosition: TXcomPosition;
  LTuCost: Integer;
  LNext: TXcomPathfindingNode;
  LPrevious: TXcomPathfindingNode;
begin
  for LNode in FNodes do
    LNode.Reset;
  LStartNode := GetNode(AStart);
  LStartNode.Connect(0, nil, 0, AEnd);
  LOpen := TXcomPathfindingOpenSet.Create;
  try
    LOpen.Push(LStartNode);
    LMissile := Assigned(ATarget) and (AMaxTuCost = 10000);
    while not LOpen.IsEmpty do
    begin
      LCurrent := LOpen.Pop;
      LCurrent.SetChecked;
      if LCurrent.Position = AEnd then
      begin
        FPath.Clear;
        LPrevious := LCurrent;
        while Assigned(LPrevious.PreviousNode) do
        begin
          FPath.Add(LPrevious.PreviousDirection);
          LPrevious := LPrevious.PreviousNode;
        end;
        Exit(True);
      end;
      for LDirection := 0 to 9 do
      begin
        LTuCost := GetTuCost(LCurrent.Position, LDirection, LNextPosition, FUnit, ATarget, LMissile);
        if LTuCost >= 255 then
          Continue;
        if ASneak and (FSave.TileAt(LNextPosition).Visible <> 0) then
          LTuCost := LTuCost * 2;
        LNext := GetNode(LNextPosition);
        if LNext.IsChecked then
          Continue;
        FTotalTuCost := LCurrent.GetTuCost(LMissile) + LTuCost;
        if (not LNext.InOpenSet or (LNext.GetTuCost(LMissile) > FTotalTuCost)) and (FTotalTuCost <= AMaxTuCost) then
        begin
          LNext.Connect(FTotalTuCost, LCurrent, LDirection, AEnd);
          LOpen.Push(LNext);
        end;
      end;
    end;
  finally
    LOpen.Free;
  end;
  Result := False;
end;

function TXcomPathfinding.GetTuCost(const AStart: TXcomPosition; ADirection: Integer; out AEnd: TXcomPosition;
  const AUnit, ATarget: TXcomBattleUnit; AMissile: Boolean): Integer;
var
  LFellDown: Boolean;
  LTriedStairs: Boolean;
  LSize: Integer;
  LCost: Integer;
  LPartsUp: Integer;
  LPartsDown: Integer;
  LPartsFalling: Integer;
  LPartsChangingHeight: Integer;
  LTotalCost: Integer;
  LX: Integer;
  LY: Integer;
  LOffset: TXcomPosition;
  LStartTile: TXcomTile;
  LDestination: TXcomTile;
  LBelow: TXcomTile;
  LAbove: TXcomTile;
  LVertical: TXcomPosition;
  LWallCounter: Integer;
  LWallTemp: Integer;
  LWallCost: Integer;
  LUnitHere: TXcomBattleUnit;
  LDiagonalStart: TXcomTile;
  LDiagonalDestination: TXcomTile;
  LTempDirection: Integer;
begin
  FUnit := AUnit;
  AEnd := TXcomDirections.ToVector(ADirection) + AStart;
  LFellDown := False;
  LTriedStairs := False;
  LSize := FUnit.Armor.Size - 1;
  LCost := 0;
  LPartsUp := 0;
  LPartsDown := 0;
  LPartsFalling := 0;
  LPartsChangingHeight := 0;
  LTotalCost := 0;
  for LX := 0 to LSize do
    for LY := 0 to LSize do
    begin
      LOffset := TXcomPosition.Make(LX, LY, 0);
      LStartTile := FSave.TileAt(AStart + LOffset);
      LDestination := FSave.TileAt(AEnd + LOffset);
      LBelow := FSave.TileAt(AEnd + LOffset + TXcomPosition.Make(0, 0, -1));
      LAbove := FSave.TileAt(AEnd + LOffset + TXcomPosition.Make(0, 0, 1));
      // the destination is probably outside the map
      if not Assigned(LStartTile) or not Assigned(LDestination) then
        Exit(255);
      if (LX = 0) and (LY = 0) and (FMovementType <> MT_FLY) and CanFallDownSize(LStartTile, LSize + 1) then
      begin
        if ADirection <> DIR_DOWN then
          Exit(255)
        else
          LFellDown := True;
      end;
      if (ADirection < DIR_UP) and (LStartTile.GetTerrainLevel > -16) then
      begin
        if IsBlocked(LStartTile, LDestination, ADirection, ATarget) then
          Exit(255);
        if LStartTile.GetTerrainLevel - LDestination.GetTerrainLevel > 8 then
          Exit(255);
      end;
      LVertical := TXcomPosition.Make(0, 0, 0);
      // on a stairs: try to go up a level
      if (ADirection < DIR_UP) and (LStartTile.GetTerrainLevel <= -16) and Assigned(LAbove) and
        not LAbove.HasNoFloor(LDestination) then
      begin
        Inc(LPartsUp);
        Inc(LVertical.Z);
        if not LTriedStairs then
        begin
          Inc(AEnd.Z);
          LDestination := FSave.TileAt(AEnd + LOffset);
          LBelow := FSave.TileAt(AEnd + TXcomPosition.Make(LX, LY, -1));
          LTriedStairs := True;
        end;
      end
      else if (ADirection < DIR_UP) and not LFellDown and (FMovementType <> MT_FLY) and Assigned(LBelow) and
        CanFallDownTile(LDestination) and (LBelow.GetTerrainLevel <= -12) then
      begin
        Inc(LPartsDown);
        if LPartsDown = (LSize + 1) * (LSize + 1) then
        begin
          Dec(AEnd.Z);
          LDestination := FSave.TileAt(AEnd + LOffset);
          LBelow := FSave.TileAt(AEnd + TXcomPosition.Make(LX, LY, -1));
          LFellDown := True;
        end;
      end
      else if not AMissile and (FMovementType = MT_FLY) and Assigned(LBelow) and Assigned(LBelow.CurrentUnit) and
        (LBelow.CurrentUnit <> AUnit) then
      begin
        // two or more voxels poking into this tile: no go
        if LBelow.CurrentUnit.GetHeight + LBelow.CurrentUnit.FloatHeight - LBelow.GetTerrainLevel > 26 then
          Exit(255);
      end;
      if not Assigned(LDestination) then
        Exit(255);
      if (ADirection < DIR_UP) and (AEnd.Z = LStartTile.Position.Z) then
      begin
        if IsBlocked(LStartTile, LDestination, ADirection, ATarget) then
          Exit(255);
        if LStartTile.GetTerrainLevel - LDestination.GetTerrainLevel > 8 then
          Exit(255);
      end
      else if (ADirection >= DIR_UP) and not LFellDown then
      begin
        // up or down through a grav lift or by flying
        if ValidateUpDown(AUnit, AStart + LOffset, ADirection, AMissile) then
          LCost := 8
        else
          Exit(255);
      end;
      // no floor: fall down
      if (FMovementType <> MT_FLY) and not LFellDown and CanFallDownTile(LStartTile) then
      begin
        Inc(LPartsFalling);
        if (LPartsFalling = (LSize + 1) * (LSize + 1)) and (ADirection <> DIR_DOWN) then
          Exit(0);
      end;
      LStartTile := FSave.TileAt(LStartTile.Position + LVertical);
      if (ADirection < DIR_UP) and (LPartsUp <> 0) then
      begin
        if IsBlocked(NeedTile(LStartTile), LDestination, ADirection, ATarget) then
          Exit(255);
        if LStartTile.GetTerrainLevel - LDestination.GetTerrainLevel > 8 then
          Exit(255);
      end;
      LWallCounter := 0;
      LWallTemp := 0;
      LWallCost := 0;
      if (ADirection = 0) or (ADirection = 7) or (ADirection = 1) then
      begin
        Inc(LWallTemp, LStartTile.GetTuCost(XCOM_PART_NORTHWALL, FMovementType));
        if LWallTemp > 0 then
        begin
          Inc(LWallCost, LWallTemp);
          Inc(LWallCounter);
        end;
      end;
      if not LFellDown and ((ADirection = 2) or (ADirection = 1) or (ADirection = 3)) then
      begin
        Inc(LWallTemp, LDestination.GetTuCost(XCOM_PART_WESTWALL, FMovementType));
        if LWallTemp > 0 then
        begin
          Inc(LWallCost, LWallTemp);
          Inc(LWallCounter);
        end;
      end;
      if not LFellDown and ((ADirection = 4) or (ADirection = 3) or (ADirection = 5)) then
      begin
        Inc(LWallTemp, LDestination.GetTuCost(XCOM_PART_NORTHWALL, FMovementType));
        if LWallTemp > 0 then
        begin
          Inc(LWallCost, LWallTemp);
          Inc(LWallCounter);
        end;
      end;
      if (ADirection = 6) or (ADirection = 5) or (ADirection = 7) then
      begin
        Inc(LWallTemp, LStartTile.GetTuCost(XCOM_PART_WESTWALL, FMovementType));
        if LWallTemp > 0 then
        begin
          Inc(LWallCost, LWallTemp);
          Inc(LWallCounter);
        end;
      end;
      // the "average" cost of the walls
      if LWallCounter > 0 then
        LWallCost := LWallCost div LWallCounter;
      // the big units do not go through doors diagonally
      if (LX <> 0) and (LY <> 0) then
        if (Assigned(LDestination.MapData[XCOM_PART_NORTHWALL]) and LDestination.MapData[XCOM_PART_NORTHWALL].IsDoor) or
          (Assigned(LDestination.MapData[XCOM_PART_WESTWALL]) and LDestination.MapData[XCOM_PART_WESTWALL].IsDoor) then
          Exit(255);
      if IsBlockedPart(LDestination, XCOM_PART_FLOOR, ATarget) or IsBlockedPart(LDestination, XCOM_PART_OBJECT, ATarget) then
        Exit(255);
      // no floor and no fall: the cost is 4 by default
      if (ADirection < DIR_UP) and not LFellDown and LDestination.HasNoFloor(nil) then
        LCost := 4;
      if ADirection < DIR_UP then
      begin
        Inc(LCost, LDestination.GetTuCost(XCOM_PART_FLOOR, FMovementType));
        if not LFellDown and not LTriedStairs and Assigned(LDestination.MapData[XCOM_PART_OBJECT]) then
          Inc(LCost, LDestination.GetTuCost(XCOM_PART_OBJECT, FMovementType));
        if LVertical.Z > 0 then
          Inc(LCost);
      end;
      // diagonal walking costs half as much again
      if (ADirection < DIR_UP) and ((ADirection and 1) <> 0) then
        LCost := Trunc(Double(LCost) * 1.5);
      Inc(LCost, LWallCost);
      if (FUnit.Faction <> FACTION_PLAYER) and (FUnit.SpecialAbility < SPECAB_BURNFLOOR) and (LDestination.Fire > 0) then
        Inc(LCost, 32);
      // TFTD: tiles on fire or with smoke cost 2 more under water
      if (FSave.Depth > 0) and ((LDestination.Fire > 0) or (LDestination.Smoke > 0)) then
        Inc(LCost, 2);
      if AMissile and Assigned(LDestination.CurrentUnit) then
      begin
        LUnitHere := LDestination.CurrentUnit;
        if (LUnitHere <> ATarget) and not LUnitHere.IsOut then
        begin
          if LUnitHere.Faction = FUnit.Faction then
            Exit(255)
          else if Assigned(AUnit.UnitRules) and (LUnitHere.TurnsSinceSpotted <= AUnit.UnitRules.Intelligence) then
            Exit(255);
        end;
      end;
      Inc(LTotalCost, LCost);
      LCost := 0;
    end;
  // bigger units: the path between the parts in an X at the end position
  if LSize <> 0 then
  begin
    LTotalCost := LTotalCost div ((LSize + 1) * (LSize + 1));
    LDiagonalStart := FSave.TileAt(AEnd + TXcomPosition.Make(1, 1, 0));
    LDiagonalDestination := FSave.TileAt(AEnd);
    LTempDirection := 7;
    if IsBlocked(NeedTile(LDiagonalStart), LDiagonalDestination, LTempDirection, ATarget) then
      Exit(255);
    if not LFellDown and (Abs(LDiagonalStart.GetTerrainLevel - LDiagonalDestination.GetTerrainLevel) > 10) then
      Exit(255);
    LDiagonalStart := FSave.TileAt(AEnd + TXcomPosition.Make(1, 0, 0));
    LDiagonalDestination := FSave.TileAt(AEnd + TXcomPosition.Make(0, 1, 0));
    LTempDirection := 5;
    if IsBlocked(NeedTile(LDiagonalStart), LDiagonalDestination, LTempDirection, ATarget) then
      Exit(255);
    if not LFellDown and (Abs(LDiagonalStart.GetTerrainLevel - LDiagonalDestination.GetTerrainLevel) > 10) then
      Exit(255);
    // two parts must change level, so a big unit cannot climb a small stairs
    if LPartsChangingHeight = 1 then
      Exit(255);
  end;
  if AMissile then
    Result := 0
  else
    Result := LTotalCost;
end;

function TXcomPathfinding.GetStartDirection: Integer;
begin
  if FPath.Count = 0 then
    Exit(-1);
  Result := FPath[FPath.Count - 1];
end;

function TXcomPathfinding.DequeuePath: Integer;
begin
  if FPath.Count = 0 then
    Exit(-1);
  Result := FPath[FPath.Count - 1];
  FPath.Delete(FPath.Count - 1);
end;

procedure TXcomPathfinding.AbortPath;
begin
  FTotalTuCost := 0;
  FPath.Clear;
end;

function TXcomPathfinding.IsBlocked(const ATile: TXcomTile; APart: Integer; const AMissileTarget: TXcomBattleUnit;
  ABigWallExclusion: Integer): Boolean;
begin
  Result := IsBlockedPart(ATile, APart, AMissileTarget, ABigWallExclusion);
end;

function TXcomPathfinding.IsBlockedPart(const ATile: TXcomTile; APart: Integer;
  const AMissileTarget: TXcomBattleUnit; ABigWallExclusion: Integer): Boolean;
var
  LObject: TXcomMapData;
  LWest: TXcomTile;
  LNorth: TXcomTile;
  LUnit: TXcomBattleUnit;
  LPosition: TXcomPosition;
  LHere: TXcomTile;
  LPart: TXcomMapData;
begin
  if not Assigned(ATile) then
    Exit(True);
  if APart = PART_BIGWALL then
  begin
    LObject := ATile.MapData[XCOM_PART_OBJECT];
    Exit(Assigned(LObject) and (LObject.BigWall <> 0) and (LObject.BigWall <= BIGWALL_NWSE) and
      (LObject.BigWall <> ABigWallExclusion));
  end;
  if APart = XCOM_PART_WESTWALL then
  begin
    LObject := ATile.MapData[XCOM_PART_OBJECT];
    if Assigned(LObject) and ((LObject.BigWall = BIGWALL_WEST) or (LObject.BigWall = BIGWALL_WEST_AND_NORTH)) then
      Exit(True);
    LWest := FSave.TileAt(ATile.Position + TXcomPosition.Make(-1, 0, 0));
    if not Assigned(LWest) then
      Exit(True);
    LObject := LWest.MapData[XCOM_PART_OBJECT];
    if Assigned(LObject) and ((LObject.BigWall = BIGWALL_EAST) or (LObject.BigWall = BIGWALL_EAST_AND_SOUTH)) then
      Exit(True);
  end;
  if APart = XCOM_PART_NORTHWALL then
  begin
    LObject := ATile.MapData[XCOM_PART_OBJECT];
    if Assigned(LObject) and ((LObject.BigWall = BIGWALL_NORTH) or (LObject.BigWall = BIGWALL_WEST_AND_NORTH)) then
      Exit(True);
    LNorth := FSave.TileAt(ATile.Position + TXcomPosition.Make(0, -1, 0));
    if not Assigned(LNorth) then
      Exit(True);
    LObject := LNorth.MapData[XCOM_PART_OBJECT];
    if Assigned(LObject) and ((LObject.BigWall = BIGWALL_SOUTH) or (LObject.BigWall = BIGWALL_EAST_AND_SOUTH)) then
      Exit(True);
  end;
  if APart = XCOM_PART_FLOOR then
  begin
    if Assigned(ATile.CurrentUnit) then
    begin
      LUnit := ATile.CurrentUnit;
      if (LUnit = FUnit) or (LUnit = AMissileTarget) or LUnit.IsOut then
        Exit(False);
      if Assigned(FUnit) then
      begin
        if (FUnit.Faction = FACTION_PLAYER) and LUnit.GetVisible then
          Exit(True);
        if FUnit.Faction = LUnit.Faction then
          Exit(True);
        if (FUnit.Faction = FACTION_HOSTILE) and (FUnit.UnitsSpottedThisTurn.IndexOf(LUnit) >= 0) then
          Exit(True);
      end;
    end
    else if ATile.HasNoFloor(nil) and (FMovementType <> MT_FLY) then
    begin
      // large units take no part in any kind of falling
      LPosition := ATile.Position;
      while LPosition.Z >= 0 do
      begin
        LHere := FSave.TileAt(LPosition);
        LUnit := LHere.CurrentUnit;
        if Assigned(LUnit) and (LUnit <> FUnit) then
        begin
          if Assigned(FUnit) and (FUnit.Armor.Size > 1) then
            Exit(True);
          if (LUnit <> FUnit) and (LUnit <> AMissileTarget) and not LUnit.IsOut and (LUnit.Armor.Size > 1) then
            Exit(True);
        end;
        if not LHere.HasNoFloor(nil) then
          Break;
        Dec(LPosition.Z);
      end;
    end;
  end;
  // missiles cannot go through closed doors
  LPart := ATile.MapData[APart];
  if Assigned(AMissileTarget) and Assigned(LPart) and
    (LPart.IsDoor or (LPart.IsUfoDoor and not ATile.IsUfoDoorOpen(APart))) then
    Exit(True);
  Result := ATile.GetTuCost(APart, FMovementType) = 255;
end;

function TXcomPathfinding.IsBlocked(const AStart, AEnd: TXcomTile; ADirection: Integer;
  const AMissileTarget: TXcomBattleUnit): Boolean;
var
  LCurrent: TXcomPosition;
  LNorth: TXcomPosition;
  LEast: TXcomPosition;
  LSouth: TXcomPosition;
  LWest: TXcomPosition;

  function At(const AOffset: TXcomPosition): TXcomTile;
  begin
    Result := FSave.TileAt(LCurrent + AOffset);
  end;

begin
  LCurrent := NeedTile(AStart).Position;
  LNorth := TXcomPosition.Make(0, -1, 0);
  LEast := TXcomPosition.Make(1, 0, 0);
  LSouth := TXcomPosition.Make(0, 1, 0);
  LWest := TXcomPosition.Make(-1, 0, 0);
  Result := True;
  case ADirection of
    0:
      if IsBlockedPart(AStart, XCOM_PART_NORTHWALL, AMissileTarget) then
        Exit;
    1:
      begin
        if IsBlockedPart(AStart, XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LNorth + LEast), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LEast), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LEast), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LEast), PART_BIGWALL, AMissileTarget, BIGWALL_NESW) then
          Exit;
        if IsBlockedPart(At(LNorth), PART_BIGWALL, AMissileTarget, BIGWALL_NESW) then
          Exit;
      end;
    2:
      if IsBlockedPart(At(LEast), XCOM_PART_WESTWALL, AMissileTarget) then
        Exit;
    3:
      begin
        if IsBlockedPart(At(LEast), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth + LEast), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth + LEast), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LEast), PART_BIGWALL, AMissileTarget, BIGWALL_NWSE) then
          Exit;
        if IsBlockedPart(At(LSouth), PART_BIGWALL, AMissileTarget, BIGWALL_NWSE) then
          Exit;
      end;
    4:
      if IsBlockedPart(At(LSouth), XCOM_PART_NORTHWALL, AMissileTarget) then
        Exit;
    5:
      begin
        if IsBlockedPart(AStart, XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LSouth), PART_BIGWALL, AMissileTarget, BIGWALL_NESW) then
          Exit;
        if IsBlockedPart(At(LWest), PART_BIGWALL, AMissileTarget, BIGWALL_NESW) then
          Exit;
        if IsBlockedPart(At(LSouth + LWest), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
      end;
    6:
      if IsBlockedPart(AStart, XCOM_PART_WESTWALL, AMissileTarget) then
        Exit;
    7:
      begin
        if IsBlockedPart(AStart, XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(AStart, XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LWest), XCOM_PART_NORTHWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LNorth), XCOM_PART_WESTWALL, AMissileTarget) then
          Exit;
        if IsBlockedPart(At(LNorth), PART_BIGWALL, AMissileTarget, BIGWALL_NWSE) then
          Exit;
        if IsBlockedPart(At(LWest), PART_BIGWALL, AMissileTarget, BIGWALL_NWSE) then
          Exit;
      end;
  end;
  Result := False;
end;

function TXcomPathfinding.CanFallDownTile(const AHere: TXcomTile): Boolean;
begin
  if NeedTile(AHere).Position.Z = 0 then
    Exit(False);
  Result := AHere.HasNoFloor(FSave.TileAt(AHere.Position - TXcomPosition.Make(0, 0, 1)));
end;

function TXcomPathfinding.CanFallDownSize(const AHere: TXcomTile; ASize: Integer): Boolean;
var
  LX: Integer;
  LY: Integer;
begin
  for LX := 0 to ASize - 1 do
    for LY := 0 to ASize - 1 do
      if not CanFallDownTile(FSave.TileAt(NeedTile(AHere).Position + TXcomPosition.Make(LX, LY, 0))) then
        Exit(False);
  Result := True;
end;

function TXcomPathfinding.IsOnStairs(const AStart, AEnd: TXcomPosition): Boolean;

  function Level(const AOffset: TXcomPosition; out AExists: Boolean): Integer;
  var
    LTile: TXcomTile;
  begin
    LTile := FSave.TileAt(AEnd + AOffset);
    AExists := Assigned(LTile);
    if AExists then
      Result := LTile.GetTerrainLevel
    else
      Result := 0;
  end;

  function Check(const AStep: TXcomPosition; AUpper, ALower: Integer; out ADecided: Boolean): Boolean;
  var
    LExists: Boolean;
  begin
    ADecided := False;
    Result := False;
    if Level(AStep, LExists) = AUpper then
      if LExists then
      begin
        // the lower part of the stairs one tile further
        if Level(AStep + AStep, LExists) <> ALower then
          if LExists then
          begin
            ADecided := True;
            Exit(False);
          end;
        if (AStart = AEnd + AStep) or (AStart = AEnd + AStep + AStep) or (AStart = AEnd + AStep + AStep + AStep) then
        begin
          ADecided := True;
          Exit(True);
        end;
      end;
  end;

var
  LDecided: Boolean;
begin
  Result := Check(TXcomPosition.Make(0, 1, 0), -16, -8, LDecided);
  if LDecided then
    Exit;
  Result := Check(TXcomPosition.Make(1, 0, 0), -16, -8, LDecided);
  if LDecided then
    Exit;
  Result := Check(TXcomPosition.Make(0, 1, 0), -18, -12, LDecided);
  if LDecided then
    Exit;
  Result := Check(TXcomPosition.Make(1, 0, 0), -18, -12, LDecided);
end;

function TXcomPathfinding.ValidateUpDown(const AUnit: TXcomBattleUnit; const AStart: TXcomPosition;
  ADirection: Integer; AMissile: Boolean): Boolean;
var
  LEnd: TXcomPosition;
  LStartTile: TXcomTile;
  LBelowStart: TXcomTile;
  LDestination: TXcomTile;
begin
  LEnd := TXcomDirections.ToVector(ADirection) + AStart;
  LStartTile := NeedTile(FSave.TileAt(AStart));
  LBelowStart := FSave.TileAt(AStart + TXcomPosition.Make(0, 0, -1));
  LDestination := FSave.TileAt(LEnd);
  if Assigned(LStartTile.MapData[XCOM_PART_FLOOR]) and Assigned(LDestination) and
    Assigned(LDestination.MapData[XCOM_PART_FLOOR]) and LStartTile.MapData[XCOM_PART_FLOOR].IsGravLift and
    LDestination.MapData[XCOM_PART_FLOOR].IsGravLift then
  begin
    if AMissile then
    begin
      if ADirection = DIR_UP then
      begin
        if LDestination.MapData[XCOM_PART_FLOOR].GetLoftId(0) <> 0 then
          Exit(False);
      end
      else if LStartTile.MapData[XCOM_PART_FLOOR].GetLoftId(0) <> 0 then
        Exit(False);
    end;
    Exit(True);
  end;
  if AUnit.MovementType = MT_FLY then
    if ((ADirection = DIR_UP) and Assigned(LDestination) and LDestination.HasNoFloor(LStartTile)) or
      ((ADirection = DIR_DOWN) and Assigned(LDestination) and LStartTile.HasNoFloor(LBelowStart)) then
      Exit(True);
  Result := False;
end;

function TXcomPathfinding.BresenhamPath(const AOrigin, ATarget: TXcomPosition;
  const ATargetUnit: TXcomBattleUnit; ASneak: Boolean; AMaxTuCost: Integer): Boolean;
const
  XD: array[0..7] of Integer = (0, 1, 1, 1, 0, -1, -1, -1);
  YD: array[0..7] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1);
var
  LX, LX0, LX1, LDeltaX, LStepX: Integer;
  LY, LY0, LY1, LDeltaY, LStepY: Integer;
  LZ, LZ0, LZ1, LDeltaZ, LStepZ: Integer;
  LSwapXy, LSwapXz: Boolean;
  LDriftXy, LDriftXz: Integer;
  LCx, LCy, LCz: Integer;
  LLastPoint: TXcomPosition;
  LDirection: Integer;
  LLastTuCost: Integer;
  LNextPoint: TXcomPosition;
  LRealNext: TXcomPosition;
  LTuCost: Integer;
  LIsDiagonal: Boolean;
  LLastDiagonal: Integer;
  LTuDiagonal: Integer;
  LTemp: Integer;
begin
  LLastPoint := AOrigin;
  LLastTuCost := -1;
  FTotalTuCost := 0;
  LX0 := AOrigin.X;
  LX1 := ATarget.X;
  LY0 := AOrigin.Y;
  LY1 := ATarget.Y;
  LZ0 := AOrigin.Z;
  LZ1 := ATarget.Z;
  // a steep line in xy: the longest delta is x
  LSwapXy := Abs(LY1 - LY0) > Abs(LX1 - LX0);
  if LSwapXy then
  begin
    LTemp := LX0; LX0 := LY0; LY0 := LTemp;
    LTemp := LX1; LX1 := LY1; LY1 := LTemp;
  end;
  LSwapXz := Abs(LZ1 - LZ0) > Abs(LX1 - LX0);
  if LSwapXz then
  begin
    LTemp := LX0; LX0 := LZ0; LZ0 := LTemp;
    LTemp := LX1; LX1 := LZ1; LZ1 := LTemp;
  end;
  LDeltaX := Abs(LX1 - LX0);
  LDeltaY := Abs(LY1 - LY0);
  LDeltaZ := Abs(LZ1 - LZ0);
  LDriftXy := LDeltaX div 2;
  LDriftXz := LDeltaX div 2;
  LStepX := 1;
  if LX0 > LX1 then
    LStepX := -1;
  LStepY := 1;
  if LY0 > LY1 then
    LStepY := -1;
  LStepZ := 1;
  if LZ0 > LZ1 then
    LStepZ := -1;
  LY := LY0;
  LZ := LZ0;
  LX := LX0;
  while LX <> (LX1 + LStepX) do
  begin
    LCx := LX;
    LCy := LY;
    LCz := LZ;
    if LSwapXz then
    begin
      LTemp := LCx; LCx := LCz; LCz := LTemp;
    end;
    if LSwapXy then
    begin
      LTemp := LCx; LCx := LCy; LCy := LTemp;
    end;
    if (LX <> LX0) or (LY <> LY0) or (LZ <> LZ0) then
    begin
      LRealNext := TXcomPosition.Make(LCx, LCy, LCz);
      LNextPoint := LRealNext;
      LDirection := 0;
      while LDirection < 8 do
      begin
        if (XD[LDirection] = LCx - LLastPoint.X) and (YD[LDirection] = LCy - LLastPoint.Y) then
          Break;
        Inc(LDirection);
      end;
      if LDirection > 7 then
        raise EXcomBattleException.Create('Xcom: the straight path has a step that is not one of the 8 directions');
      LTuCost := GetTuCost(LLastPoint, LDirection, LNextPoint, FUnit, ATargetUnit,
        Assigned(ATargetUnit) and (AMaxTuCost = 10000));
      if ASneak and (FSave.TileAt(LNextPoint).Visible <> 0) then
        Exit(False);
      LIsDiagonal := (LDirection and 1) <> 0;
      LLastDiagonal := LLastTuCost + LLastTuCost div 2;
      LTuDiagonal := LTuCost + LTuCost div 2;
      if (LNextPoint = LRealNext) and (LTuCost < 255) and
        ((LTuCost = LLastTuCost) or (LIsDiagonal and (LTuCost = LLastDiagonal)) or
        (not LIsDiagonal and (LTuDiagonal = LLastTuCost)) or (LLastTuCost = -1)) and
        not IsBlocked(FSave.TileAt(LLastPoint), FSave.TileAt(LNextPoint), LDirection, ATargetUnit) then
        FPath.Add(LDirection)
      else
        Exit(False);
      if not Assigned(ATargetUnit) and (LTuCost <> 255) then
      begin
        LLastTuCost := LTuCost;
        Inc(FTotalTuCost, LTuCost);
      end;
      LLastPoint := TXcomPosition.Make(LCx, LCy, LCz);
    end;
    Dec(LDriftXy, LDeltaY);
    Dec(LDriftXz, LDeltaZ);
    if LDriftXy < 0 then
    begin
      Inc(LY, LStepY);
      Inc(LDriftXy, LDeltaX);
    end;
    if LDriftXz < 0 then
    begin
      Inc(LZ, LStepZ);
      Inc(LDriftXz, LDeltaX);
    end;
    Inc(LX, LStepX);
  end;
  Result := True;
end;

function TXcomPathfinding.FindReachable(const AUnit: TXcomBattleUnit; ATuMax: Integer): TArray<Integer>;
var
  LStart: TXcomPosition;
  LEnergyMax: Integer;
  LNode: TXcomPathfindingNode;
  LStartNode: TXcomPathfindingNode;
  LUnvisited: TXcomPathfindingOpenSet;
  LReachable: TList<TXcomPathfindingNode>;
  LCurrent: TXcomPathfindingNode;
  LDirection: Integer;
  LNextPosition: TXcomPosition;
  LTuCost: Integer;
  LNext: TXcomPathfindingNode;
  LTotal: Integer;
  LIndex: Integer;
  LSorted: TArray<TXcomPathfindingNode>;
begin
  LStart := AUnit.Position;
  LEnergyMax := AUnit.Energy;
  for LNode in FNodes do
    LNode.Reset;
  LStartNode := GetNode(LStart);
  LStartNode.Connect(0, nil, 0);
  LUnvisited := TXcomPathfindingOpenSet.Create;
  LReachable := TList<TXcomPathfindingNode>.Create;
  try
    LUnvisited.Push(LStartNode);
    while not LUnvisited.IsEmpty do
    begin
      LCurrent := LUnvisited.Pop;
      for LDirection := 0 to 9 do
      begin
        LTuCost := GetTuCost(LCurrent.Position, LDirection, LNextPosition, AUnit, nil, False);
        if LTuCost = 255 then
          Continue;
        if (LCurrent.GetTuCost(False) + LTuCost > ATuMax) or
          ((LCurrent.GetTuCost(False) + LTuCost) div 2 > LEnergyMax) then
          Continue;
        LNext := GetNode(LNextPosition);
        if LNext.IsChecked then
          Continue;
        LTotal := LCurrent.GetTuCost(False) + LTuCost;
        if not LNext.InOpenSet or (LNext.GetTuCost(False) > LTotal) then
        begin
          LNext.Connect(LTotal, LCurrent, LDirection);
          LUnvisited.Push(LNext);
        end;
      end;
      LCurrent.SetChecked;
      LReachable.Add(LCurrent);
    end;
    LSorted := LReachable.ToArray;
    // MinNodeCosts; std::sort is not stable, an ordering of equal costs by the order of the search is used here
    TArray.Sort<TXcomPathfindingNode>(LSorted, TComparer<TXcomPathfindingNode>.Construct(
      function(const ALeft, ARight: TXcomPathfindingNode): Integer
      begin
        Result := ALeft.GetTuCost(False) - ARight.GetTuCost(False);
        if Result = 0 then
          Result := LReachable.IndexOf(ALeft) - LReachable.IndexOf(ARight);
      end));
    SetLength(Result, Length(LSorted));
    for LIndex := 0 to High(LSorted) do
      Result[LIndex] := FSave.TileIndex(LSorted[LIndex].Position);
  finally
    LReachable.Free;
    LUnvisited.Free;
  end;
end;

end.
