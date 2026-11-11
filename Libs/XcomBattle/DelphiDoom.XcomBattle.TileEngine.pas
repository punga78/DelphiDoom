{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - light, sight, blockage, lines of      }
{  fire and explosions on the map (TileEngine)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.TileEngine;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Directions,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.Host.Intf,
  DelphiDoom.XcomBattle.ThrowRange, DelphiDoom.XcomBattle.Trajectory, DelphiDoom.XcomMod.RuleInventory;

type
  /// <summary>
  ///   Modifies and reads the tiles of the map: sun and terrain and unit light, the field of view, the blockage
  ///   of light, smoke and explosions between tiles, the lines through voxels, falling and explosions
  ///   (TileEngine). It holds the saved battle without owning it. What needs the battle in progress
  ///   (BattlescapeGame: reaction fire, the throw, the hit that pushes states) is not here
  /// </summary>
  TXcomTileEngine = class(TInterfacedObject, IXcomGeneratorTileEngine, IXcomBattleTileEngine, IXcomProjectileEngine)
  strict private
    const
      MAX_VIEW_DISTANCE = 20;
      MAX_VIEW_DISTANCE_SQR = MAX_VIEW_DISTANCE * MAX_VIEW_DISTANCE;
      MAX_VOXEL_VIEW_DISTANCE = MAX_VIEW_DISTANCE * 16;
      MAX_DARKNESS_TO_SEE_UNITS = 9;
  strict private
    FSave: TXcomSavedBattleGame;
    FContext: IXcomBattleContext;
    FVoxelData: TArray<Word>;
    FPersonalLighting: Boolean;
    FCacheTile: TXcomTile;
    FCacheTileBelow: TXcomTile;
    FCacheTilePosition: TXcomPosition;
    FDetonationRank: TArray<Integer>;
    [weak]
    FHost: IXcomBattleHost;
    procedure AddLight(const ACenter: TXcomPosition; APower, ALayer: Integer);
    function Blockage(const ATile: TXcomTile; APart: Integer; ADamageType: Integer; ADirection: Integer = -1;
      ACheckingFromOrigin: Boolean = False): Integer;
    class function VoxelToTile(const AVoxel: TXcomPosition): TXcomPosition; static;
  public
    /// <param name="AVoxelData">The LOFT templates: the words of LOFTEMPS.DAT (Mod::getVoxelData)</param>
    constructor Create(const ASave: TXcomSavedBattleGame; const AContext: IXcomBattleContext;
      const AVoxelData: TArray<Word>);
    procedure CalculateSunShading; overload;
    procedure CalculateSunShading(const ATile: TXcomTile); overload;
    procedure CalculateTerrainLighting;
    procedure CalculateUnitLighting;
    /// <summary>calculateFOV(unit): true when new aliens are spotted</summary>
    function CalculateFovOfUnit(const AUnit: TXcomBattleUnit): Boolean;
    /// <summary>calculateFOV(position): the units within range of a place of changed terrain</summary>
    procedure CalculateFovAt(const APosition: TXcomPosition);
    procedure RecalculateFov;
    procedure CalculateFov(const AUnit: TXcomBattleUnit);
    function GetSightOriginVoxel(const AUnit: TXcomBattleUnit): TXcomPosition;
    function Visible(const AUnit: TXcomBattleUnit; const ATile: TXcomTile): Boolean;
    function CheckVoxelExposure(const AOrigin: TXcomPosition; const ATile: TXcomTile;
      const AExcludeUnit, AExcludeAllBut: TXcomBattleUnit): Integer;
    function CanTargetUnit(const AOrigin: TXcomPosition; const ATile: TXcomTile; out AScan: TXcomPosition;
      const AExcludeUnit: TXcomBattleUnit; ARememberObstacles: Boolean;
      const APotentialUnit: TXcomBattleUnit = nil): Boolean;
    function CanTargetTile(const AOrigin: TXcomPosition; const ATile: TXcomTile; APart: Integer;
      out AScan: TXcomPosition; const AExcludeUnit: TXcomBattleUnit; ARememberObstacles: Boolean): Boolean;
    function HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer): Integer; overload;
    function HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer; ASkipObject: Boolean): Integer;
      overload;
    function VerticalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer; ASkipObject: Boolean = False)
      : Integer;
    /// <summary>
    ///   calculateLine: the trajectory is the list of the voxels passed (all of them when AStoreTrajectory, else only
    ///   the one of the impact); the result is the voxel type, a blockage over 127, -1 or V_EMPTY
    /// </summary>
    function CalculateLine(const AOrigin, ATarget: TXcomPosition; AStoreTrajectory: Boolean;
      const ATrajectory: TList<TXcomPosition>; const AExcludeUnit: TXcomBattleUnit; ADoVoxelCheck: Boolean = True;
      AOnlyVisible: Boolean = False; const AExcludeAllBut: TXcomBattleUnit = nil): Integer;
    function CalculateParabola(const AOrigin, ATarget: TXcomPosition; AStoreTrajectory: Boolean;
      const ATrajectory: TList<TXcomPosition>; const AExcludeUnit: TXcomBattleUnit; ACurvature: Double;
      const ADelta: TXcomPosition): Integer;
    function CastedShade(const AVoxel: TXcomPosition): Integer;
    function IsVoxelVisible(const AVoxel: TXcomPosition): Boolean;
    function VoxelCheck(const AVoxel: TXcomPosition; const AExcludeUnit: TXcomBattleUnit;
      AExcludeAllUnits: Boolean = False; AOnlyVisible: Boolean = False;
      const AExcludeAllBut: TXcomBattleUnit = nil): Integer;
    procedure VoxelCheckFlush;
    procedure TogglePersonalLighting;
    function DistanceUnitToPositionSq(const AUnit: TXcomBattleUnit; const APosition: TXcomPosition;
      AConsiderZ: Boolean): Integer;
    function Distance(const AFirst, ASecond: TXcomPosition): Integer;
    function DistanceSq(const AFirst, ASecond: TXcomPosition; AConsiderZ: Boolean = True): Integer;
    function CloseUfoDoors: Integer;
    /// <summary>
    ///   unitOpensDoor: the unit opens the door it faces (ADirection -1: the direction of the unit); gives -1 when there
    ///   is none, 0 a normal door, 1 a UFO door, 4 not enough time units, 5 the time units are reserved
    /// </summary>
    function UnitOpensDoor(const AUnit: TXcomBattleUnit; ARightClick: Boolean = False; ADirection: Integer = -1)
      : Integer;
    /// <summary>setDangerZone: the tiles a grenade that is about to explode would reach are marked dangerous for the AI</summary>
    procedure SetDangerZone(const APosition: TXcomPosition; ARadius: Integer; const AUnit: TXcomBattleUnit);
    /// <summary>checkAdjacentDoors: opens the UFO doors that continue a door that was opened</summary>
    procedure CheckAdjacentDoors(const APosition: TXcomPosition; APart: Integer);
    /// <summary>faceWindow: the direction (0, 2, 4, 6) of a window next to the tile, or -1</summary>
    function FaceWindow(const APosition: TXcomPosition): Integer;
    /// <summary>applyGravity: units and items fall to where there is a floor; gives the tile where the items end up</summary>
    function ApplyGravityTile(const ATile: TXcomTile): TXcomTile;
    procedure ApplyGravity(const ATile: TXcomTile);
    /// <summary>
    ///   itemDrop: puts the item on the tile (on the ground slot), lets it fall and lights a flare; ANewItem adds it to
    ///   the items of the battle, ARemoveItem takes it away from its owner
    /// </summary>
    procedure ItemDrop(const ATile: TXcomTile; const AItem: TXcomBattleItem; const AGround: TXcomRuleInventory;
      ANewItem: Boolean = False; ARemoveItem: Boolean = False);
    /// <summary>checkForTerrainExplosions: a tile with a chained explosion, or nil</summary>
    function CheckForTerrainExplosions: TXcomTile;
    /// <summary>detonate: applies the explosive power of a tile to its parts; true when the objective is destroyed</summary>
    function Detonate(const ATile: TXcomTile): Boolean;
    /// <summary>
    ///   explode: HE, smoke, fire and stun in a sphere of rays of 5 and 3 degrees, one tile at a time with the
    ///   power losing 10 a tile and what the walls block; the unit that caused it may be nil. The tiles hit by HE
    ///   are detonated in the order of their index (the C++ keeps them in a set of pointers)
    /// </summary>
    procedure Explode(const ACenter: TXcomPosition; APower, ADamageType, AMaxRadius: Integer;
      const AUnit: TXcomBattleUnit = nil);
    /// <summary>
    ///   The order in which explode detonates the tiles it reached, as the tile indexes in that order (empty: by
    ///   index). The C++ keeps them in a set of pointers, so the order is the one of the memory addresses and has
    ///   no meaning of its own; the parity tests give the order that the real run had
    /// </summary>
    procedure SetDetonationOrder(const AOrder: TArray<Integer>);
    /// <summary>getDirectionTo: the direction 0..7 (north is 0, clockwise) from one position to another</summary>
    function GetDirectionTo(const AOrigin, ATarget: TXcomPosition): Integer;
    /// <summary>
    ///   getOriginVoxel: where the projectile of an action starts, in voxels (the tile is the one of the action
    ///   or, when nil, the tile of the actor)
    /// </summary>
    function GetOriginVoxel(const AAction: TXcomBattleAction; const ATile: TXcomTile): TXcomPosition;
    /// <summary>
    ///   validateThrow: tries curvatures of 0.5 more at a time until the arc lands on the target tile; false when
    ///   none does or the target is out of range. The tiles where an arc hit an obstacle are marked for the player
    /// </summary>
    function ValidateThrow(const AAction: TXcomBattleAction; const AOrigin, ATarget: TXcomPosition;
      var ACurve: Double; var AVoxelType: Integer; AForced: Boolean): Boolean;
    /// <summary>
    ///   hit: a bullet or a weapon hits a voxel: damages the part of the tile or the unit and refreshes light and
    ///   field of view; gives the unit that was hit. The explosion of a unit that dies is pushed to the host
    /// </summary>
    function Hit(const ACenter: TXcomPosition; APower, ADamageType: Integer;
      const AUnit: TXcomBattleUnit): TXcomBattleUnit;
    /// <summary>validMeleeRange(attacker, target, dir): the attacker may hit the target from where it stands</summary>
    function ValidMeleeRange(const AAttacker, ATarget: TXcomBattleUnit; ADirection: Integer): Boolean; overload;
    /// <summary>
    ///   validMeleeRange(pos, direction, attacker, target, dest): a unit (the target, or any when nil) within reach
    ///   of the tile in a direction; ADestination gets its position when there is one. The target that is chosen
    ///   among several is an enemy (preferEnemy) or the friend with most wounds
    /// </summary>
    function ValidMeleeRange(const APosition: TXcomPosition; ADirection: Integer; const AAttacker, ATarget: TXcomBattleUnit;
      out ADestination: TXcomPosition; APreferEnemy: Boolean = True): Boolean; overload;
    /// <summary>The game in progress that the hit asks for the action being carried out and the list of steps</summary>
    property Host: IXcomBattleHost read FHost write FHost;
    property PersonalLighting: Boolean read FPersonalLighting;
  end;

implementation

uses
  DelphiDoom.XcomBattle.ExplosionState;

const
  HEIGHT_FROM_CENTER: array[0..10] of Integer = (0, -2, 2, -4, 4, -6, 6, -8, 8, -12, 12);
  PI_VALUE: Double = 3.14159265358979323846;

{ TXcomTileEngine }

constructor TXcomTileEngine.Create(const ASave: TXcomSavedBattleGame; const AContext: IXcomBattleContext;
  const AVoxelData: TArray<Word>);
begin
  inherited Create;
  FSave := ASave;
  FContext := AContext;
  FVoxelData := AVoxelData;
  FPersonalLighting := True;
  FCacheTilePosition := TXcomPosition.Make(-1, -1, -1);
end;

class function TXcomTileEngine.VoxelToTile(const AVoxel: TXcomPosition): TXcomPosition;
begin
  Result := TXcomPosition.Make(AVoxel.X div 16, AVoxel.Y div 16, AVoxel.Z div 24);
end;

procedure TXcomTileEngine.CalculateSunShading;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
  begin
    FSave.TileByIndex(LIndex).ResetLight(0);
    CalculateSunShading(FSave.TileByIndex(LIndex));
  end;
end;

procedure TXcomTileEngine.CalculateSunShading(const ATile: TXcomTile);
var
  LPower: Integer;
  LBlock: Integer;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  LPower := 15 - FSave.GlobalShade;
  // at night and dusk the sun does not drop the shades blocked by roofs
  if FSave.GlobalShade <= 4 then
  begin
    LBlock := 0;
    LX := ATile.Position.X;
    LY := ATile.Position.Y;
    for LZ := FSave.MapSizeZ - 1 downto ATile.Position.Z + 1 do
    begin
      Inc(LBlock, Blockage(FSave.TileAt(TXcomPosition.Make(LX, LY, LZ)), XCOM_PART_FLOOR, TXcomRuleItem.DT_NONE));
      Inc(LBlock, Blockage(FSave.TileAt(TXcomPosition.Make(LX, LY, LZ)), XCOM_PART_OBJECT, TXcomRuleItem.DT_NONE,
        DIR_DOWN));
    end;
    if LBlock > 0 then
      Dec(LPower, 2);
  end;
  ATile.AddLight(LPower, 0);
end;

procedure TXcomTileEngine.CalculateTerrainLighting;
const
  LAYER = 1;
  FIRE_LIGHT_POWER = 15;
var
  LIndex: Integer;
  LTile: TXcomTile;
  LItem: TXcomBattleItem;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
    FSave.TileByIndex(LIndex).ResetLight(LAYER);
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
  begin
    LTile := FSave.TileByIndex(LIndex);
    if Assigned(LTile.MapData[XCOM_PART_FLOOR]) and (LTile.MapData[XCOM_PART_FLOOR].GetLightSource <> 0) then
      AddLight(LTile.Position, LTile.MapData[XCOM_PART_FLOOR].GetLightSource, LAYER);
    if Assigned(LTile.MapData[XCOM_PART_OBJECT]) and (LTile.MapData[XCOM_PART_OBJECT].GetLightSource <> 0) then
      AddLight(LTile.Position, LTile.MapData[XCOM_PART_OBJECT].GetLightSource, LAYER);
    if LTile.Fire <> 0 then
      AddLight(LTile.Position, FIRE_LIGHT_POWER, LAYER);
    for LItem in LTile.Inventory do
      if LItem.Rules.BattleType = TXcomRuleItem.BT_FLARE then
        AddLight(LTile.Position, LItem.Rules.Power, LAYER);
  end;
end;

procedure TXcomTileEngine.CalculateUnitLighting;
const
  LAYER = 2;
  PERSONAL_LIGHT_POWER = 15;
  FIRE_LIGHT_POWER = 15;
var
  LIndex: Integer;
  LUnit: TXcomBattleUnit;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
    FSave.TileByIndex(LIndex).ResetLight(LAYER);
  for LUnit in FSave.Units do
  begin
    if FPersonalLighting and (LUnit.Faction = FACTION_PLAYER) and not LUnit.IsOut then
      AddLight(LUnit.Position, PERSONAL_LIGHT_POWER, LAYER);
    if LUnit.Fire <> 0 then
      AddLight(LUnit.Position, FIRE_LIGHT_POWER, LAYER);
  end;
end;

procedure TXcomTileEngine.AddLight(const ACenter: TXcomPosition; APower, ALayer: Integer);
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LDistance: Integer;
  LRadius: Single;
  LTile: TXcomTile;

  procedure Light(AX, AY: Integer);
  begin
    LTile := FSave.TileAt(TXcomPosition.Make(AX, AY, LZ));
    if Assigned(LTile) then
      LTile.AddLight(APower - LDistance, ALayer);
  end;

begin
  // only the positive quadrant is looped through
  for LX := 0 to APower do
    for LY := 0 to APower do
      for LZ := 0 to FSave.MapSizeZ - 1 do
      begin
        // (int)Round(sqrt(float(x*x + y*y))) with the float round of fmath.h
        LRadius := Sqrt(Single(LX * LX + LY * LY));
        LDistance := Trunc(Floor(LRadius + 0.5));
        Light(ACenter.X + LX, ACenter.Y + LY);
        Light(ACenter.X - LX, ACenter.Y - LY);
        Light(ACenter.X - LX, ACenter.Y + LY);
        Light(ACenter.X + LX, ACenter.Y - LY);
      end;
end;

function TXcomTileEngine.CalculateFovOfUnit(const AUnit: TXcomBattleUnit): Boolean;
const
  SIGN_X: array[0..7] of Integer = (1, 1, 1, 1, -1, -1, -1, -1);
  SIGN_Y: array[0..7] of Integer = (-1, -1, -1, 1, 1, 1, -1, -1);
var
  LOldCount: Integer;
  LCenter: TXcomPosition;
  LTest: TXcomPosition;
  LDirection: Integer;
  LSwap: Boolean;
  LTrajectory: TList<TXcomPosition>;
  LY1: Integer;
  LY2: Integer;
  LPosition: TXcomPosition;
  LTileAbove: TXcomTile;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LDistanceSqr: Integer;
  LVisibleUnit: TXcomBattleUnit;
  LTile: TXcomTile;
  LSize: Integer;
  LXo: Integer;
  LYo: Integer;
  LPositionO: TXcomPosition;
  LTest2: Integer;
  LCount: Integer;
  LIndex: Integer;
  LPassed: TXcomPosition;
  LOther: TXcomTile;
begin
  LOldCount := AUnit.UnitsSpottedThisTurn.Count;
  LCenter := AUnit.Position;
  LDirection := AUnit.Direction;
  LSwap := (LDirection = 0) or (LDirection = 4);
  AUnit.ClearVisibleUnits;
  AUnit.ClearVisibleTiles;
  if AUnit.IsOut then
    Exit(False);
  LPosition := AUnit.Position;
  if (AUnit.GetHeight + AUnit.FloatHeight + -FSave.TileAt(AUnit.Position).GetTerrainLevel) >= 24 + 4 then
  begin
    LTileAbove := FSave.TileAt(LPosition + TXcomPosition.Make(0, 0, 1));
    if Assigned(LTileAbove) and LTileAbove.HasNoFloor(nil) then
      Inc(LPosition.Z);
  end;
  LTrajectory := TList<TXcomPosition>.Create;
  try
    for LX := 0 to MAX_VIEW_DISTANCE do
    begin
      if (LDirection mod 2) <> 0 then
      begin
        LY1 := 0;
        LY2 := MAX_VIEW_DISTANCE;
      end
      else
      begin
        LY1 := -LX;
        LY2 := LX;
      end;
      for LY := LY1 to LY2 do
        for LZ := 0 to FSave.MapSizeZ - 1 do
        begin
          LDistanceSqr := LX * LX + LY * LY;
          LTest.Z := LZ;
          if LDistanceSqr <= MAX_VIEW_DISTANCE_SQR then
          begin
            if LSwap then
              LTest.X := LCenter.X + SIGN_X[LDirection] * LY
            else
              LTest.X := LCenter.X + SIGN_X[LDirection] * LX;
            if LSwap then
              LTest.Y := LCenter.Y + SIGN_Y[LDirection] * LX
            else
              LTest.Y := LCenter.Y + SIGN_Y[LDirection] * LY;
            LTile := FSave.TileAt(LTest);
            if Assigned(LTile) then
            begin
              LVisibleUnit := LTile.CurrentUnit;
              if Assigned(LVisibleUnit) and not LVisibleUnit.IsOut and Visible(AUnit, LTile) then
              begin
                if AUnit.Faction = FACTION_PLAYER then
                begin
                  LVisibleUnit.Tile.SetVisible(1);
                  LVisibleUnit.Visible := True;
                end;
                if ((LVisibleUnit.Faction = FACTION_HOSTILE) and (AUnit.Faction = FACTION_PLAYER)) or
                  ((LVisibleUnit.Faction <> FACTION_HOSTILE) and (AUnit.Faction = FACTION_HOSTILE)) then
                begin
                  AUnit.AddToVisibleUnits(LVisibleUnit);
                  AUnit.AddToVisibleTiles(LVisibleUnit.Tile);
                  if (AUnit.Faction = FACTION_HOSTILE) and (LVisibleUnit.Faction <> FACTION_HOSTILE) then
                    LVisibleUnit.TurnsSinceSpotted := 0;
                end;
              end;
              if AUnit.Faction = FACTION_PLAYER then
              begin
                // the tiles of the line of sight are discovered; the tile space is used, not the voxel space,
                // and large units have four pairs of eyes
                LSize := AUnit.Armor.Size;
                for LXo := 0 to LSize - 1 do
                  for LYo := 0 to LSize - 1 do
                  begin
                    LPositionO := LPosition + TXcomPosition.Make(LXo, LYo, 0);
                    LTrajectory.Clear;
                    LTest2 := CalculateLine(LPositionO, LTest, True, LTrajectory, AUnit, False);
                    LCount := LTrajectory.Count;
                    if LTest2 > 127 then
                      Dec(LCount);
                    for LIndex := 0 to LCount - 1 do
                    begin
                      LPassed := LTrajectory[LIndex];
                      FSave.TileAt(LPassed).SetVisible(1);
                      FSave.TileAt(LPassed).SetDiscovered(True, 2);
                      LOther := FSave.TileAt(TXcomPosition.Make(LPassed.X + 1, LPassed.Y, LPassed.Z));
                      if Assigned(LOther) then
                        LOther.SetDiscovered(True, 0);
                      LOther := FSave.TileAt(TXcomPosition.Make(LPassed.X, LPassed.Y + 1, LPassed.Z));
                      if Assigned(LOther) then
                        LOther.SetDiscovered(True, 1);
                    end;
                  end;
              end;
            end;
          end;
        end;
    end;
  finally
    LTrajectory.Free;
  end;
  Result := (AUnit.UnitsSpottedThisTurn.Count > LOldCount) and (AUnit.VisibleUnits.Count > 0);
end;

procedure TXcomTileEngine.CalculateFov(const AUnit: TXcomBattleUnit);
begin
  CalculateFovOfUnit(AUnit);
end;

procedure TXcomTileEngine.CalculateFovAt(const APosition: TXcomPosition);
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FSave.Units do
    if DistanceSq(APosition, LUnit.Position) <= MAX_VIEW_DISTANCE_SQR then
      CalculateFovOfUnit(LUnit);
end;

procedure TXcomTileEngine.RecalculateFov;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in FSave.Units do
    if Assigned(LUnit.Tile) then
      CalculateFovOfUnit(LUnit);
end;

function TXcomTileEngine.GetSightOriginVoxel(const AUnit: TXcomBattleUnit): TXcomPosition;
var
  LTileAbove: TXcomTile;
begin
  Result := TXcomPosition.Make(AUnit.Position.X * 16 + 8, AUnit.Position.Y * 16 + 8, AUnit.Position.Z * 24);
  Dec(Result.Z, FSave.TileAt(AUnit.Position).GetTerrainLevel);
  // one voxel lower: the eye level
  Inc(Result.Z, AUnit.GetHeight + AUnit.FloatHeight - 1);
  LTileAbove := FSave.TileAt(AUnit.Position + TXcomPosition.Make(0, 0, 1));
  if AUnit.Armor.Size > 1 then
  begin
    Inc(Result.X, 8);
    Inc(Result.Y, 8);
    Inc(Result.Z);
  end;
  if (Result.Z >= (AUnit.Position.Z + 1) * 24) and (not Assigned(LTileAbove) or not LTileAbove.HasNoFloor(nil)) then
    while Result.Z >= (AUnit.Position.Z + 1) * 24 do
      Dec(Result.Z);
end;

function TXcomTileEngine.Visible(const AUnit: TXcomBattleUnit; const ATile: TXcomTile): Boolean;
var
  LOrigin: TXcomPosition;
  LScan: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LTile: TXcomTile;
  LVisibleDistance: Cardinal;
  LIndex: Integer;
  LVoxel: TXcomPosition;
begin
  if not Assigned(ATile) or not Assigned(ATile.CurrentUnit) then
    Exit(False);
  // aliens see in the dark; xcom sees at a distance of 9 or less, further when there is enough light
  if ((AUnit.Faction = FACTION_PLAYER) and (Distance(AUnit.Position, ATile.Position) > 9) and
    (ATile.GetShade > MAX_DARKNESS_TO_SEE_UNITS)) or (Distance(AUnit.Position, ATile.Position) > MAX_VIEW_DISTANCE) then
    Exit(False);
  if AUnit.Faction = ATile.CurrentUnit.Faction then
    Exit(True);
  LOrigin := GetSightOriginVoxel(AUnit);
  Result := CanTargetUnit(LOrigin, ATile, LScan, AUnit, False);
  if Result then
  begin
    // smoke tiles along the way: the density of a fresh smoke grenade (15) divided by 3 is the loss of sight
    LTrajectory := TList<TXcomPosition>.Create;
    try
      CalculateLine(LOrigin, LScan, True, LTrajectory, AUnit);
      LTile := FSave.TileAt(AUnit.Position);
      LVisibleDistance := LTrajectory.Count;
      for LIndex := 0 to LTrajectory.Count - 1 do
      begin
        LVoxel := LTrajectory[LIndex];
        if LTile <> FSave.TileAt(TXcomPosition.Make(LVoxel.X div 16, LVoxel.Y div 16, LVoxel.Z div 24)) then
          LTile := FSave.TileAt(TXcomPosition.Make(LVoxel.X div 16, LVoxel.Y div 16, LVoxel.Z div 24));
        if LTile.Fire = 0 then
          Inc(LVisibleDistance, LTile.Smoke div 3);
        if LVisibleDistance > Cardinal(MAX_VOXEL_VIEW_DISTANCE) then
        begin
          Result := False;
          Break;
        end;
      end;
    finally
      LTrajectory.Free;
    end;
  end;
end;

function TXcomTileEngine.CheckVoxelExposure(const AOrigin: TXcomPosition; const ATile: TXcomTile;
  const AExcludeUnit, AExcludeAllBut: TXcomBattleUnit): Integer;
var
  LTarget: TXcomPosition;
  LScan: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LOther: TXcomBattleUnit;
  LMinHeight: Integer;
  LHeightRange: Integer;
  LRadius: Integer;
  LRelative: TXcomPosition;
  LNormal: Single;
  LLength: Single;
  LRelX: Integer;
  LRelY: Integer;
  LSlice: array[0..5] of Integer;
  LMaxHeight: Integer;
  LTotal: Integer;
  LVisible: Integer;
  LIndex: Integer;
  LSlot: Integer;
  LTest: Integer;
  LProduct: Single;
begin
  LTarget := TXcomPosition.Make(ATile.Position.X * 16 + 8, ATile.Position.Y * 16 + 8, ATile.Position.Z * 24);
  LOther := ATile.CurrentUnit;
  if not Assigned(LOther) then
    Exit(0);
  if LOther = AExcludeUnit then
    Exit(0);
  LMinHeight := LTarget.Z - ATile.GetTerrainLevel;
  Inc(LMinHeight, LOther.FloatHeight);
  LRadius := LOther.GetLoftemps;
  if LOther.Armor.Size > 1 then
    LRadius := 3;
  LRelative := LTarget - AOrigin;
  LLength := Single(LRelative.X * LRelative.X + LRelative.Y * LRelative.Y);
  if LLength = 0 then
    LNormal := 0
  else
    LNormal := LRadius / Sqrt(LLength);
  LProduct := Single(LRelative.Y) * LNormal;
  LRelX := Floor(LProduct + 0.5);
  LProduct := Single(-LRelative.X) * LNormal;
  LRelY := Floor(LProduct + 0.5);
  LSlice[0] := 0;
  LSlice[1] := 0;
  LSlice[2] := LRelX;
  LSlice[3] := LRelY;
  LSlice[4] := -LRelX;
  LSlice[5] := -LRelY;
  if not LOther.IsOut then
    LHeightRange := LOther.GetHeight
  else
    LHeightRange := 12;
  LMaxHeight := LMinHeight + LHeightRange;
  LTotal := 0;
  LVisible := 0;
  LTrajectory := TList<TXcomPosition>.Create;
  try
    LIndex := LHeightRange;
    while LIndex >= 0 do
    begin
      Inc(LTotal);
      LScan.Z := LMinHeight + LIndex;
      for LSlot := 0 to 2 do
      begin
        // an origin straight above or below the target: the C++ divides by zero, the offsets of the two side
        // rays are not numbers and as integers they point two billion voxels away: those rays never count (the
        // real TileEngine answers 100 where three rays to the center would give 300)
        if (LLength = 0) and (LSlot > 0) then
          Continue;
        LScan.X := LTarget.X + LSlice[LSlot * 2];
        LScan.Y := LTarget.Y + LSlice[LSlot * 2 + 1];
        LTrajectory.Clear;
        LTest := CalculateLine(AOrigin, LScan, False, LTrajectory, AExcludeUnit, True, False, AExcludeAllBut);
        if LTest = V_UNIT then
          if (LTrajectory[0].X div 16 = LScan.X div 16) and (LTrajectory[0].Y div 16 = LScan.Y div 16) and
            (LTrajectory[0].Z >= LMinHeight) and (LTrajectory[0].Z <= LMaxHeight) then
            Inc(LVisible);
      end;
      Dec(LIndex, 2);
    end;
  finally
    LTrajectory.Free;
  end;
  Result := (LVisible * 100) div LTotal;
end;

function TXcomTileEngine.CanTargetUnit(const AOrigin: TXcomPosition; const ATile: TXcomTile;
  out AScan: TXcomPosition; const AExcludeUnit: TXcomBattleUnit; ARememberObstacles: Boolean;
  const APotentialUnit: TXcomBattleUnit): Boolean;
var
  LTarget: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LHypothetical: Boolean;
  LPotential: TXcomBattleUnit;
  LMinHeight: Integer;
  LMaxHeight: Integer;
  LCenterHeight: Integer;
  LHeightRange: Integer;
  LRadius: Integer;
  LTargetSize: Integer;
  LOffsetX: Integer;
  LOffsetY: Integer;
  LRelative: TXcomPosition;
  LNormal: Single;
  LLength: Single;
  LProduct: Single;
  LRelX: Integer;
  LRelY: Integer;
  LSlice: array[0..9] of Integer;
  LIndex: Integer;
  LSlot: Integer;
  LTest: Integer;
  LX: Integer;
  LY: Integer;
  LObstacle: TXcomTile;
begin
  AScan := TXcomPosition.Make(0, 0, 0);
  LTarget := TXcomPosition.Make(ATile.Position.X * 16 + 8, ATile.Position.Y * 16 + 8, ATile.Position.Z * 24);
  LHypothetical := Assigned(APotentialUnit);
  LPotential := APotentialUnit;
  if not Assigned(LPotential) then
  begin
    LPotential := ATile.CurrentUnit;
    if not Assigned(LPotential) then
      Exit(False);
  end;
  if LPotential = AExcludeUnit then
    Exit(False);
  LMinHeight := LTarget.Z - ATile.GetTerrainLevel;
  Inc(LMinHeight, LPotential.FloatHeight);
  LMaxHeight := LMinHeight;
  LRadius := LPotential.GetLoftemps;
  LTargetSize := LPotential.Armor.Size - 1;
  LOffsetX := LPotential.Position.X - ATile.Position.X;
  LOffsetY := LPotential.Position.Y - ATile.Position.Y;
  if LTargetSize > 0 then
    LRadius := 3;
  LRelative := LTarget - AOrigin;
  LLength := Single(LRelative.X * LRelative.X + LRelative.Y * LRelative.Y);
  if LLength = 0 then
    LNormal := 0
  else
    LNormal := LRadius / Sqrt(LLength);
  LProduct := Single(LRelative.Y) * LNormal;
  LRelX := Floor(LProduct + 0.5);
  LProduct := Single(-LRelative.X) * LNormal;
  LRelY := Floor(LProduct + 0.5);
  LSlice[0] := 0;
  LSlice[1] := 0;
  LSlice[2] := LRelX;
  LSlice[3] := LRelY;
  LSlice[4] := -LRelX;
  LSlice[5] := -LRelY;
  LSlice[6] := LRelY;
  LSlice[7] := -LRelX;
  LSlice[8] := -LRelY;
  LSlice[9] := LRelX;
  if not LPotential.IsOut then
    LHeightRange := LPotential.GetHeight
  else
    LHeightRange := 12;
  Inc(LMaxHeight, LHeightRange);
  LCenterHeight := (LMaxHeight + LMinHeight) div 2;
  LHeightRange := LHeightRange div 2;
  if LHeightRange > 10 then
    LHeightRange := 10;
  if LHeightRange <= 0 then
    LHeightRange := 0;
  LTrajectory := TList<TXcomPosition>.Create;
  try
    for LIndex := 0 to LHeightRange do
    begin
      AScan.Z := LCenterHeight + HEIGHT_FROM_CENTER[LIndex];
      for LSlot := 0 to 4 do
      begin
        if (LIndex < LHeightRange - 1) and (LSlot > 2) then
          Break;
        AScan.X := LTarget.X + LSlice[LSlot * 2];
        AScan.Y := LTarget.Y + LSlice[LSlot * 2 + 1];
        LTrajectory.Clear;
        LTest := CalculateLine(AOrigin, AScan, False, LTrajectory, AExcludeUnit, True, False);
        if LTest = V_UNIT then
        begin
          for LX := 0 to LTargetSize do
            for LY := 0 to LTargetSize do
              if (LTrajectory[0].X div 16 = (AScan.X div 16) + LX + LOffsetX) and
                (LTrajectory[0].Y div 16 = (AScan.Y div 16) + LY + LOffsetY) and (LTrajectory[0].Z >= LMinHeight) and
                (LTrajectory[0].Z <= LMaxHeight) then
                Exit(True);
        end
        else if (LTest = V_EMPTY) and LHypothetical and (LTrajectory.Count > 0) then
          Exit(True);
        if ARememberObstacles and (LTrajectory.Count > 0) then
        begin
          LObstacle := FSave.TileAt(TXcomPosition.Make(LTrajectory[0].X div 16, LTrajectory[0].Y div 16,
            LTrajectory[0].Z div 24));
          if Assigned(LObstacle) then
            LObstacle.SetObstacle(LTest);
        end;
      end;
    end;
  finally
    LTrajectory.Free;
  end;
  Result := False;
end;

function TXcomTileEngine.CanTargetTile(const AOrigin: TXcomPosition; const ATile: TXcomTile; APart: Integer;
  out AScan: TXcomPosition; const AExcludeUnit: TXcomBattleUnit; ARememberObstacles: Boolean): Boolean;
const
  OBJECT_SPIRAL: array[0..81] of Integer = (8, 8, 8, 6, 10, 6, 10, 8, 10, 10, 8, 10, 6, 10, 6, 8, 6, 6, 8, 4, 10, 4,
    12, 4, 12, 6, 12, 8, 12, 10, 12, 12, 10, 12, 8, 12, 6, 12, 4, 12, 4, 10, 4, 8, 4, 6, 4, 4, 6, 4, 8, 1, 12, 1,
    15, 1, 15, 4, 15, 8, 15, 12, 15, 15, 12, 15, 8, 15, 4, 15, 1, 15, 1, 12, 1, 8, 1, 4, 1, 1, 4, 1);
  WEST_WALL_SPIRAL: array[0..13] of Integer = (0, 7, 0, 9, 0, 6, 0, 11, 0, 4, 0, 13, 0, 2);
  NORTH_WALL_SPIRAL: array[0..13] of Integer = (7, 0, 9, 0, 6, 0, 11, 0, 4, 0, 13, 0, 2, 0);
var
  LTarget: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LSpiral: TArray<Integer>;
  LCount: Integer;
  LMinZ: Integer;
  LMaxZ: Integer;
  LMinZFound: Boolean;
  LMaxZFound: Boolean;
  LDummy: Boolean;
  LJ: Integer;
  LI: Integer;
  LRangeZ: Integer;
  LCenterZ: Integer;
  LTest: Integer;
  LObstacle: TXcomTile;

  procedure UseSpiral(const ASource: array of Integer; ASpiralCount: Integer);
  var
    LK: Integer;
  begin
    SetLength(LSpiral, Length(ASource));
    for LK := 0 to High(ASource) do
      LSpiral[LK] := ASource[LK];
    LCount := ASpiralCount;
  end;

begin
  AScan := TXcomPosition.Make(0, 0, 0);
  LTarget := TXcomPosition.Make(ATile.Position.X * 16, ATile.Position.Y * 16, ATile.Position.Z * 24);
  LMinZ := 0;
  LMaxZ := 0;
  LMinZFound := False;
  LMaxZFound := False;
  LDummy := False;
  if APart = XCOM_PART_OBJECT then
    UseSpiral(OBJECT_SPIRAL, 41)
  else if APart = XCOM_PART_NORTHWALL then
    UseSpiral(NORTH_WALL_SPIRAL, 7)
  else if APart = XCOM_PART_WESTWALL then
    UseSpiral(WEST_WALL_SPIRAL, 7)
  else if APart = XCOM_PART_FLOOR then
  begin
    UseSpiral(OBJECT_SPIRAL, 41);
    LMinZFound := True;
    LMinZ := 0;
    LMaxZFound := True;
    LMaxZ := 0;
  end
  else if APart = XCOM_PART_DUMMY then
  begin
    UseSpiral(OBJECT_SPIRAL, 41);
    LMinZFound := True;
    LMinZ := 12;
    LMaxZFound := True;
    LMaxZ := 12;
  end
  else
    Exit(False);
  VoxelCheckFlush;
  if not LMinZFound then
    for LJ := 1 to 11 do
    begin
      if LMinZFound then
        Break;
      for LI := 0 to LCount - 1 do
        if VoxelCheck(TXcomPosition.Make(LTarget.X + LSpiral[LI * 2], LTarget.Y + LSpiral[LI * 2 + 1],
          LTarget.Z + LJ * 2), nil, True) = APart then
          if not LMinZFound then
          begin
            LMinZ := LJ * 2;
            LMinZFound := True;
            Break;
          end;
    end;
  if not LMinZFound then
  begin
    if ARememberObstacles then
    begin
      LMinZ := 10;
      LDummy := True;
    end
    else
      Exit(False);
  end;
  if not LMaxZFound then
    for LJ := 10 downto 0 do
    begin
      if LMaxZFound then
        Break;
      for LI := 0 to LCount - 1 do
        if VoxelCheck(TXcomPosition.Make(LTarget.X + LSpiral[LI * 2], LTarget.Y + LSpiral[LI * 2 + 1],
          LTarget.Z + LJ * 2), nil, True) = APart then
          if not LMaxZFound then
          begin
            LMaxZ := LJ * 2;
            LMaxZFound := True;
            Break;
          end;
    end;
  if not LMaxZFound then
  begin
    if ARememberObstacles then
    begin
      LMaxZ := 10;
      LDummy := True;
    end
    else
      Exit(False);
  end;
  if LMinZ > LMaxZ then
    LMinZ := LMaxZ;
  LRangeZ := LMaxZ - LMinZ;
  if LRangeZ > 10 then
    LRangeZ := 10;
  LCenterZ := (LMaxZ + LMinZ) div 2;
  LTrajectory := TList<TXcomPosition>.Create;
  try
    for LJ := 0 to LRangeZ do
    begin
      AScan.Z := LTarget.Z + LCenterZ + HEIGHT_FROM_CENTER[LJ];
      for LI := 0 to LCount - 1 do
      begin
        AScan.X := LTarget.X + LSpiral[LI * 2];
        AScan.Y := LTarget.Y + LSpiral[LI * 2 + 1];
        LTrajectory.Clear;
        LTest := CalculateLine(AOrigin, AScan, False, LTrajectory, AExcludeUnit, True);
        if (LTest = APart) and not LDummy then
          if (LTrajectory[0].X div 16 = AScan.X div 16) and (LTrajectory[0].Y div 16 = AScan.Y div 16) and
            (LTrajectory[0].Z div 24 = AScan.Z div 24) then
            Exit(True);
        if ARememberObstacles and (LTrajectory.Count > 0) then
        begin
          LObstacle := FSave.TileAt(TXcomPosition.Make(LTrajectory[0].X div 16, LTrajectory[0].Y div 16,
            LTrajectory[0].Z div 24));
          if Assigned(LObstacle) then
            LObstacle.SetObstacle(LTest);
        end;
      end;
    end;
  finally
    LTrajectory.Free;
  end;
  Result := False;
end;

function TXcomTileEngine.VerticalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer;
  ASkipObject: Boolean): Integer;
var
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LCurrent: TXcomTile;
begin
  Result := 0;
  if not Assigned(AStart) or not Assigned(AEnd) then
    Exit(0);
  LDirection := AEnd.Position.Z - AStart.Position.Z;
  if LDirection = 0 then
    Exit(0);
  LX := AStart.Position.X;
  LY := AStart.Position.Y;
  LZ := AStart.Position.Z;
  if LDirection < 0 then
  begin
    Inc(Result, Blockage(AStart, XCOM_PART_FLOOR, ADamageType));
    if not ASkipObject then
      Inc(Result, Blockage(AStart, XCOM_PART_OBJECT, ADamageType, DIR_DOWN));
    if (LX <> AEnd.Position.X) or (LY <> AEnd.Position.Y) then
    begin
      LX := AEnd.Position.X;
      LY := AEnd.Position.Y;
      LCurrent := FSave.TileAt(TXcomPosition.Make(LX, LY, LZ));
      Inc(Result, HorizontalBlockage(AStart, LCurrent, ADamageType, ASkipObject));
      Inc(Result, Blockage(LCurrent, XCOM_PART_FLOOR, ADamageType));
      if not ASkipObject then
        Inc(Result, Blockage(LCurrent, XCOM_PART_OBJECT, ADamageType, DIR_DOWN));
    end;
  end
  else if LDirection > 0 then
  begin
    Inc(LZ);
    LCurrent := FSave.TileAt(TXcomPosition.Make(LX, LY, LZ));
    Inc(Result, Blockage(LCurrent, XCOM_PART_FLOOR, ADamageType));
    if not ASkipObject then
      Inc(Result, Blockage(LCurrent, XCOM_PART_OBJECT, ADamageType, DIR_UP));
    if (LX <> AEnd.Position.X) or (LY <> AEnd.Position.Y) then
    begin
      LX := AEnd.Position.X;
      LY := AEnd.Position.Y;
      LCurrent := FSave.TileAt(TXcomPosition.Make(LX, LY, LZ));
      Inc(Result, HorizontalBlockage(AStart, LCurrent, ADamageType, ASkipObject));
      Inc(Result, Blockage(LCurrent, XCOM_PART_FLOOR, ADamageType));
      if not ASkipObject then
        Inc(Result, Blockage(LCurrent, XCOM_PART_OBJECT, ADamageType, DIR_UP));
    end;
  end;
end;

function TXcomTileEngine.HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer): Integer;
begin
  Result := HorizontalBlockage(AStart, AEnd, ADamageType, False);
end;

function TXcomTileEngine.HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer;
  ASkipObject: Boolean): Integer;
var
  LNorth: TXcomPosition;
  LEast: TXcomPosition;
  LSouth: TXcomPosition;
  LWest: TXcomPosition;
  LDirection: Integer;
  LBlock: Integer;
  LTemp: TXcomTile;

  function At(const AOffset: TXcomPosition): TXcomTile;
  begin
    Result := FSave.TileAt(AStart.Position + AOffset);
  end;

  function IsNotWall(const ATile: TXcomTile; AWall: Integer): Boolean;
  begin
    Result := Assigned(ATile) and Assigned(ATile.MapData[XCOM_PART_OBJECT]) and
      (ATile.MapData[XCOM_PART_OBJECT].BigWall <> AWall);
  end;

begin
  if not Assigned(AStart) or not Assigned(AEnd) then
    Exit(0);
  if AStart.Position.Z <> AEnd.Position.Z then
    Exit(0);
  LNorth := TXcomPosition.Make(0, -1, 0);
  LEast := TXcomPosition.Make(1, 0, 0);
  LSouth := TXcomPosition.Make(0, 1, 0);
  LWest := TXcomPosition.Make(-1, 0, 0);
  LDirection := TXcomDirections.FromVector(AEnd.Position - AStart.Position);
  if LDirection = -1 then
    Exit(0);
  LBlock := 0;
  case LDirection of
    0:
      LBlock := Blockage(AStart, XCOM_PART_NORTHWALL, ADamageType);
    1:
      if ADamageType = TXcomRuleItem.DT_NONE then
      begin
        LBlock := Blockage(AStart, XCOM_PART_NORTHWALL, ADamageType) + Blockage(AEnd, XCOM_PART_WESTWALL, ADamageType);
        LTemp := At(LNorth);
        if IsNotWall(LTemp, BIGWALL_NESW) then
          Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 3));
        if LBlock <> 0 then
        begin
          LBlock := Blockage(At(LEast), XCOM_PART_NORTHWALL, ADamageType) +
            Blockage(At(LEast), XCOM_PART_WESTWALL, ADamageType);
          LTemp := At(LEast);
          if IsNotWall(LTemp, BIGWALL_NESW) then
            Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 7));
        end;
      end
      else
      begin
        LBlock := (Blockage(AStart, XCOM_PART_NORTHWALL, ADamageType) + Blockage(AEnd, XCOM_PART_WESTWALL,
          ADamageType)) div 2 + (Blockage(At(LEast), XCOM_PART_WESTWALL, ADamageType) +
          Blockage(At(LEast), XCOM_PART_NORTHWALL, ADamageType)) div 2;
        Inc(LBlock, (Blockage(At(LNorth), XCOM_PART_OBJECT, ADamageType, 4) +
          Blockage(At(LEast), XCOM_PART_OBJECT, ADamageType, 6)) div 2);
      end;
    2:
      LBlock := Blockage(AEnd, XCOM_PART_WESTWALL, ADamageType);
    3:
      if ADamageType = TXcomRuleItem.DT_NONE then
      begin
        LBlock := Blockage(At(LSouth), XCOM_PART_NORTHWALL, ADamageType) + Blockage(AEnd, XCOM_PART_WESTWALL, ADamageType);
        LTemp := At(LSouth);
        if IsNotWall(LTemp, BIGWALL_NWSE) then
          Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 1));
        if LBlock <> 0 then
        begin
          LBlock := Blockage(At(LEast), XCOM_PART_WESTWALL, ADamageType) + Blockage(AEnd, XCOM_PART_NORTHWALL, ADamageType);
          LTemp := At(LEast);
          if IsNotWall(LTemp, BIGWALL_NWSE) then
            Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 5));
        end;
      end
      else
      begin
        LBlock := (Blockage(AEnd, XCOM_PART_WESTWALL, ADamageType) + Blockage(AEnd, XCOM_PART_NORTHWALL, ADamageType)) div 2 +
          (Blockage(At(LEast), XCOM_PART_WESTWALL, ADamageType) + Blockage(At(LSouth), XCOM_PART_NORTHWALL,
          ADamageType)) div 2;
        Inc(LBlock, (Blockage(At(LSouth), XCOM_PART_OBJECT, ADamageType, 0) +
          Blockage(At(LEast), XCOM_PART_OBJECT, ADamageType, 6)) div 2);
      end;
    4:
      LBlock := Blockage(AEnd, XCOM_PART_NORTHWALL, ADamageType);
    5:
      if ADamageType = TXcomRuleItem.DT_NONE then
      begin
        LBlock := Blockage(At(LSouth), XCOM_PART_NORTHWALL, ADamageType) +
          Blockage(At(LSouth), XCOM_PART_WESTWALL, ADamageType);
        LTemp := At(LSouth);
        if IsNotWall(LTemp, BIGWALL_NESW) then
          Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 7));
        if LBlock <> 0 then
        begin
          LBlock := Blockage(AStart, XCOM_PART_WESTWALL, ADamageType) + Blockage(AEnd, XCOM_PART_NORTHWALL, ADamageType);
          LTemp := At(LWest);
          if IsNotWall(LTemp, BIGWALL_NESW) then
            Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 3));
        end;
      end
      else
      begin
        LBlock := (Blockage(AEnd, XCOM_PART_NORTHWALL, ADamageType) + Blockage(AStart, XCOM_PART_WESTWALL,
          ADamageType)) div 2 + (Blockage(At(LSouth), XCOM_PART_WESTWALL, ADamageType) +
          Blockage(At(LSouth), XCOM_PART_NORTHWALL, ADamageType)) div 2;
        Inc(LBlock, (Blockage(At(LSouth), XCOM_PART_OBJECT, ADamageType, 0) +
          Blockage(At(LWest), XCOM_PART_OBJECT, ADamageType, 2)) div 2);
      end;
    6:
      LBlock := Blockage(AStart, XCOM_PART_WESTWALL, ADamageType);
    7:
      if ADamageType = TXcomRuleItem.DT_NONE then
      begin
        LBlock := Blockage(AStart, XCOM_PART_NORTHWALL, ADamageType) +
          Blockage(At(LNorth), XCOM_PART_WESTWALL, ADamageType);
        LTemp := At(LNorth);
        if IsNotWall(LTemp, BIGWALL_NWSE) then
          Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 5));
        if LBlock <> 0 then
        begin
          LBlock := Blockage(AStart, XCOM_PART_WESTWALL, ADamageType) +
            Blockage(At(LWest), XCOM_PART_NORTHWALL, ADamageType);
          LTemp := At(LWest);
          if IsNotWall(LTemp, BIGWALL_NWSE) then
            Inc(LBlock, Blockage(LTemp, XCOM_PART_OBJECT, ADamageType, 1));
        end;
      end
      else
      begin
        LBlock := (Blockage(AStart, XCOM_PART_WESTWALL, ADamageType) + Blockage(AStart, XCOM_PART_NORTHWALL,
          ADamageType)) div 2 + (Blockage(At(LNorth), XCOM_PART_WESTWALL, ADamageType) +
          Blockage(At(LWest), XCOM_PART_NORTHWALL, ADamageType)) div 2;
        Inc(LBlock, (Blockage(At(LNorth), XCOM_PART_OBJECT, ADamageType, 4) +
          Blockage(At(LWest), XCOM_PART_OBJECT, ADamageType, 2)) div 2);
      end;
  end;
  if not ASkipObject or ((ADamageType = TXcomRuleItem.DT_NONE) and AStart.IsBigWall) then
    Inc(LBlock, Blockage(AStart, XCOM_PART_OBJECT, ADamageType, LDirection));
  if ADamageType <> TXcomRuleItem.DT_NONE then
  begin
    Inc(LDirection, 4);
    if LDirection > 7 then
      Dec(LDirection, 8);
    if AEnd.IsBigWall then
      Inc(LBlock, Blockage(AEnd, XCOM_PART_OBJECT, ADamageType, LDirection, True));
  end
  else if LBlock <= 127 then
  begin
    Inc(LDirection, 4);
    if LDirection > 7 then
      Dec(LDirection, 8);
    if Blockage(AEnd, XCOM_PART_OBJECT, ADamageType, LDirection, True) > 127 then
      Exit(-1);
  end;
  Result := LBlock;
end;

function TXcomTileEngine.Blockage(const ATile: TXcomTile; APart: Integer; ADamageType: Integer; ADirection: Integer;
  ACheckingFromOrigin: Boolean): Integer;
var
  LCheck: Boolean;
  LWall: Integer;
begin
  Result := 0;
  if not Assigned(ATile) then
    Exit(0);
  if Assigned(ATile.MapData[APart]) then
  begin
    LCheck := True;
    LWall := -1;
    if ADirection <> -1 then
    begin
      // the C++ reads the object of the tile here: no object is a null pointer there
      if not Assigned(ATile.MapData[XCOM_PART_OBJECT]) then
        raise EXcomBattleException.Create('Xcom: the blockage of a direction needs the object of the tile');
      LWall := ATile.MapData[XCOM_PART_OBJECT].BigWall;
      if (ADamageType <> TXcomRuleItem.DT_SMOKE) and ACheckingFromOrigin and
        ((LWall = BIGWALL_NESW) or (LWall = BIGWALL_NWSE)) then
        LCheck := False;
      case ADirection of
        0:
          if (LWall = BIGWALL_WEST) or (LWall = BIGWALL_EAST) or (LWall = BIGWALL_SOUTH) or
            (LWall = BIGWALL_EAST_AND_SOUTH) then
            LCheck := False;
        1:
          if (LWall = BIGWALL_WEST) or (LWall = BIGWALL_SOUTH) then
            LCheck := False;
        2:
          if (LWall = BIGWALL_NORTH) or (LWall = BIGWALL_SOUTH) or (LWall = BIGWALL_WEST) or
            (LWall = BIGWALL_WEST_AND_NORTH) then
            LCheck := False;
        3:
          if (LWall = BIGWALL_NORTH) or (LWall = BIGWALL_WEST) or (LWall = BIGWALL_WEST_AND_NORTH) then
            LCheck := False;
        4:
          if (LWall = BIGWALL_WEST) or (LWall = BIGWALL_EAST) or (LWall = BIGWALL_NORTH) or
            (LWall = BIGWALL_WEST_AND_NORTH) then
            LCheck := False;
        5:
          if (LWall = BIGWALL_NORTH) or (LWall = BIGWALL_EAST) then
            LCheck := False;
        6:
          if (LWall = BIGWALL_NORTH) or (LWall = BIGWALL_SOUTH) or (LWall = BIGWALL_EAST) or
            (LWall = BIGWALL_EAST_AND_SOUTH) then
            LCheck := False;
        7:
          if (LWall = BIGWALL_SOUTH) or (LWall = BIGWALL_EAST) or (LWall = BIGWALL_EAST_AND_SOUTH) then
            LCheck := False;
        8, 9:
          if (LWall <> 0) and (LWall <> BIGWALL_BLOCK) then
            LCheck := False;
      end;
    end
    else if (APart = XCOM_PART_FLOOR) and (ATile.MapData[APart].GetBlock(ADamageType) = 0) then
    begin
      if ADamageType <> TXcomRuleItem.DT_NONE then
        Inc(Result, ATile.MapData[APart].Armor)
      else if not ATile.MapData[APart].IsNoFloor then
        Exit(256);
    end;
    if LCheck then
    begin
      // -1 is a regular wall and anything over 0 is a big wall
      if (ADamageType = TXcomRuleItem.DT_SMOKE) and (LWall <> 0) and not ATile.IsUfoDoorOpen(APart) then
        Exit(256);
      Inc(Result, ATile.MapData[APart].GetBlock(ADamageType));
    end;
  end;
  // an open ufo door is still closed behind the scenes: it blocks nothing
  if ATile.IsUfoDoorOpen(APart) then
    Result := 0;
end;

function TXcomTileEngine.CalculateLine(const AOrigin, ATarget: TXcomPosition; AStoreTrajectory: Boolean;
  const ATrajectory: TList<TXcomPosition>; const AExcludeUnit: TXcomBattleUnit; ADoVoxelCheck, AOnlyVisible: Boolean;
  const AExcludeAllBut: TXcomBattleUnit): Integer;
var
  LX, LX0, LX1, LDeltaX, LStepX: Integer;
  LY, LY0, LY1, LDeltaY, LStepY: Integer;
  LZ, LZ0, LZ1, LDeltaZ, LStepZ: Integer;
  LSwapXy, LSwapXz: Boolean;
  LDriftXy, LDriftXz: Integer;
  LCx, LCy, LCz: Integer;
  LLastPoint: TXcomPosition;
  LSteps: Integer;
  LExcludeAllUnits: Boolean;
  LTemp: Integer;
  LVertical: Integer;
begin
  LLastPoint := AOrigin;
  LSteps := 0;
  // no unit spotting before the inventory of the craft (a large unit on that tile would crash)
  LExcludeAllUnits := FSave.BeforeGame;
  LX0 := AOrigin.X;
  LX1 := ATarget.X;
  LY0 := AOrigin.Y;
  LY1 := ATarget.Y;
  LZ0 := AOrigin.Z;
  LZ1 := ATarget.Z;
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
  if ADoVoxelCheck then
    VoxelCheckFlush;
  LX := LX0;
  while True do
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
    if AStoreTrajectory and Assigned(ATrajectory) then
      ATrajectory.Add(TXcomPosition.Make(LCx, LCy, LCz));
    if ADoVoxelCheck then
    begin
      Result := VoxelCheck(TXcomPosition.Make(LCx, LCy, LCz), AExcludeUnit, False, AOnlyVisible, AExcludeAllBut);
      if Result <> V_EMPTY then
      begin
        if Assigned(ATrajectory) then
          ATrajectory.Add(TXcomPosition.Make(LCx, LCy, LCz));
        Exit;
      end;
    end
    else
    begin
      LVertical := VerticalBlockage(FSave.TileAt(LLastPoint), FSave.TileAt(TXcomPosition.Make(LCx, LCy, LCz)),
        TXcomRuleItem.DT_NONE);
      Result := HorizontalBlockage(FSave.TileAt(LLastPoint), FSave.TileAt(TXcomPosition.Make(LCx, LCy, LCz)),
        TXcomRuleItem.DT_NONE, LSteps < 2);
      Inc(LSteps);
      if Result = -1 then
      begin
        if LVertical > 127 then
          Result := 0
        else
          Exit;
      end;
      Inc(Result, LVertical);
      if Result > 127 then
        Exit;
      LLastPoint := TXcomPosition.Make(LCx, LCy, LCz);
    end;
    if LX = LX1 then
      Break;
    Dec(LDriftXy, LDeltaY);
    Dec(LDriftXz, LDeltaZ);
    if LDriftXy < 0 then
    begin
      Inc(LY, LStepY);
      Inc(LDriftXy, LDeltaX);
      if ADoVoxelCheck then
      begin
        LCx := LX;
        LCz := LZ;
        LCy := LY;
        if LSwapXz then
        begin
          LTemp := LCx; LCx := LCz; LCz := LTemp;
        end;
        if LSwapXy then
        begin
          LTemp := LCx; LCx := LCy; LCy := LTemp;
        end;
        Result := VoxelCheck(TXcomPosition.Make(LCx, LCy, LCz), AExcludeUnit, LExcludeAllUnits, AOnlyVisible,
          AExcludeAllBut);
        if Result <> V_EMPTY then
        begin
          if Assigned(ATrajectory) then
            ATrajectory.Add(TXcomPosition.Make(LCx, LCy, LCz));
          Exit;
        end;
      end;
    end;
    if LDriftXz < 0 then
    begin
      Inc(LZ, LStepZ);
      Inc(LDriftXz, LDeltaX);
      if ADoVoxelCheck then
      begin
        LCx := LX;
        LCz := LZ;
        LCy := LY;
        if LSwapXz then
        begin
          LTemp := LCx; LCx := LCz; LCz := LTemp;
        end;
        if LSwapXy then
        begin
          LTemp := LCx; LCx := LCy; LCy := LTemp;
        end;
        Result := VoxelCheck(TXcomPosition.Make(LCx, LCy, LCz), AExcludeUnit, LExcludeAllUnits, AOnlyVisible,
          AExcludeAllBut);
        if Result <> V_EMPTY then
        begin
          if Assigned(ATrajectory) then
            ATrajectory.Add(TXcomPosition.Make(LCx, LCy, LCz));
          Exit;
        end;
      end;
    end;
    Inc(LX, LStepX);
  end;
  Result := V_EMPTY;
end;

function TXcomTileEngine.CalculateParabola(const AOrigin, ATarget: TXcomPosition; AStoreTrajectory: Boolean;
  const ATrajectory: TList<TXcomPosition>; const AExcludeUnit: TXcomBattleUnit; ACurvature: Double;
  const ADelta: TXcomPosition): Integer;
var
  LRo: Double;
  LFi: Double;
  LTe: Double;
  LZa: Double;
  LZk: Double;
  LX, LY, LZ: Integer;
  LI: Integer;
  LLast: TXcomPosition;
  LNext: TXcomPosition;
  LSumSquares: Integer;
begin
  LSumSquares := (ATarget.X - AOrigin.X) * (ATarget.X - AOrigin.X) + (ATarget.Y - AOrigin.Y) * (ATarget.Y - AOrigin.Y) +
    (ATarget.Z - AOrigin.Z) * (ATarget.Z - AOrigin.Z);
  LRo := Sqrt(Double(LSumSquares));
  if Abs(LRo - 0.0) <= 2.220446049250313E-16 * Max(1.0, Max(Abs(LRo), 0.0)) then
    Exit(V_EMPTY);
  LFi := ArcCos(Double(ATarget.Z - AOrigin.Z) / LRo);
  LTe := ArcTan2(Double(ATarget.Y - AOrigin.Y), Double(ATarget.X - AOrigin.X));
  LTe := LTe + (ADelta.X / LRo) / 2 * PI_VALUE;
  LFi := LFi + ((ADelta.Z + ADelta.Y) / LRo) / 14 * PI_VALUE * ACurvature;
  LZa := Sqrt(LRo) * ACurvature;
  LZk := 4.0 * LZa / LRo / LRo;
  LX := AOrigin.X;
  LY := AOrigin.Y;
  LZ := AOrigin.Z;
  LI := 8;
  Result := V_EMPTY;
  LLast := TXcomPosition.Make(LX, LY, LZ);
  if AStoreTrajectory and Assigned(ATrajectory) then
    ATrajectory.Add(LLast);
  while LZ > 0 do
  begin
    LX := Trunc(Double(AOrigin.X) + Double(LI) * Cos(LTe) * Sin(LFi));
    LY := Trunc(Double(AOrigin.Y) + Double(LI) * Sin(LTe) * Sin(LFi));
    LZ := Trunc(Double(AOrigin.Z) + Double(LI) * Cos(LFi) - LZk * (Double(LI) - LRo / 2.0) * (Double(LI) - LRo / 2.0) +
      LZa);
    LNext := TXcomPosition.Make(LX, LY, LZ);
    if AStoreTrajectory and Assigned(ATrajectory) then
      ATrajectory.Delete(ATrajectory.Count - 1);
    if AStoreTrajectory then
      Result := CalculateLine(LLast, LNext, AStoreTrajectory, ATrajectory, AExcludeUnit)
    else
      Result := CalculateLine(LLast, LNext, AStoreTrajectory, nil, AExcludeUnit);
    if Result <> V_EMPTY then
    begin
      if not AStoreTrajectory and Assigned(ATrajectory) then
        Result := CalculateLine(LLast, LNext, False, ATrajectory, AExcludeUnit);
      Break;
    end;
    LLast := LNext;
    Inc(LI);
  end;
end;

function TXcomTileEngine.CastedShade(const AVoxel: TXcomPosition): Integer;
var
  LZStart: Integer;
  LCoord: TXcomPosition;
  LTile: TXcomTile;
  LVoxel: TXcomPosition;
begin
  LZStart := AVoxel.Z;
  LCoord := VoxelToTile(AVoxel);
  LTile := FSave.TileAt(LCoord);
  while Assigned(LTile) and LTile.IsVoid and not Assigned(LTile.CurrentUnit) do
  begin
    LZStart := LCoord.Z * 24;
    Dec(LCoord.Z);
    LTile := FSave.TileAt(LCoord);
  end;
  LVoxel := AVoxel;
  VoxelCheckFlush;
  Result := LZStart;
  while Result > 0 do
  begin
    LVoxel.Z := Result;
    if VoxelCheck(LVoxel, nil) <> V_EMPTY then
      Break;
    Dec(Result);
  end;
end;

function TXcomTileEngine.IsVoxelVisible(const AVoxel: TXcomPosition): Boolean;
var
  LZStart: Integer;
  LZEnd: Integer;
  LVoxel: TXcomPosition;
  LZ: Integer;
begin
  LZStart := AVoxel.Z + 3;
  if (LZStart div 24) <> (AVoxel.Z div 24) then
    Exit(True);
  LVoxel := AVoxel;
  LZEnd := (LZStart div 24) * 24 + 24;
  VoxelCheckFlush;
  for LZ := LZStart to LZEnd - 1 do
  begin
    LVoxel.Z := LZ;
    // only an object can occlude further, because of its shape
    if VoxelCheck(LVoxel, nil) = V_OBJECT then
      Exit(False);
    Inc(LVoxel.X);
    if VoxelCheck(LVoxel, nil) = V_OBJECT then
      Exit(False);
    Inc(LVoxel.Y);
    if VoxelCheck(LVoxel, nil) = V_OBJECT then
      Exit(False);
  end;
  Result := True;
end;

function TXcomTileEngine.VoxelCheck(const AVoxel: TXcomPosition; const AExcludeUnit: TXcomBattleUnit;
  AExcludeAllUnits, AOnlyVisible: Boolean; const AExcludeAllBut: TXcomBattleUnit): Integer;
const
  LARGE_PARTS: array[0..3] of Integer = (1, 0, 3, 2);
var
  LPosition: TXcomPosition;
  LTile: TXcomTile;
  LTileBelow: TXcomTile;
  LIndex: Integer;
  LPart: TXcomMapData;
  LX: Integer;
  LY: Integer;
  LOffset: Integer;
  LUnit: TXcomBattleUnit;
  LUnitPosition: TXcomPosition;
  LTerrainHeight: Integer;
  LXs: Integer;
  LYs: Integer;
  LTempTile: TXcomTile;
  LTz: Integer;
  LLarge: Integer;
  LTilePosition: TXcomPosition;
begin
  if (AVoxel.X < 0) or (AVoxel.Y < 0) or (AVoxel.Z < 0) then
    Exit(V_OUTOFBOUNDS);
  LPosition := VoxelToTile(AVoxel);
  if FCacheTilePosition = LPosition then
  begin
    LTile := FCacheTile;
    LTileBelow := FCacheTileBelow;
  end
  else
  begin
    LTile := FSave.TileAt(LPosition);
    if not Assigned(LTile) then
      Exit(V_OUTOFBOUNDS);
    LTileBelow := FSave.TileAt(LPosition + TXcomPosition.Make(0, 0, -1));
    FCacheTilePosition := LPosition;
    FCacheTile := LTile;
    FCacheTileBelow := LTileBelow;
  end;
  if LTile.IsVoid and not Assigned(LTile.CurrentUnit) and (not Assigned(LTileBelow) or not Assigned(LTileBelow.CurrentUnit)) then
    Exit(V_EMPTY);
  if Assigned(LTile.MapData[XCOM_PART_FLOOR]) and LTile.MapData[XCOM_PART_FLOOR].IsGravLift and
    (((AVoxel.Z mod 24) = 0) or ((AVoxel.Z mod 24) = 1)) then
    if not (Assigned(LTileBelow) and Assigned(LTileBelow.MapData[XCOM_PART_FLOOR]) and
      LTileBelow.MapData[XCOM_PART_FLOOR].IsGravLift) then
      Exit(V_FLOOR);
  // the terrain voxel data first, so that units of 2x2 do not stick through walls
  for LIndex := V_FLOOR to V_OBJECT do
  begin
    LPart := LTile.MapData[LIndex];
    if ((LIndex = XCOM_PART_WESTWALL) or (LIndex = XCOM_PART_NORTHWALL)) and LTile.IsUfoDoorOpen(LIndex) then
      Continue;
    if Assigned(LPart) then
    begin
      LX := 15 - AVoxel.X mod 16;
      LY := AVoxel.Y mod 16;
      LOffset := LPart.GetLoftId((AVoxel.Z mod 24) div 2) * 16 + LY;
      if (LOffset < 0) or (LOffset >= Length(FVoxelData)) then
        raise EXcomBattleException.Create('Xcom: a voxel is outside the LOFT data');
      if (FVoxelData[LOffset] and (1 shl LX)) <> 0 then
        Exit(LIndex);
    end;
  end;
  if not AExcludeAllUnits then
  begin
    LUnit := LTile.CurrentUnit;
    // a unit of the tile below may stick up into this tile with its head
    if not Assigned(LUnit) and LTile.HasNoFloor(LTileBelow) then
      if Assigned(LTileBelow) then
      begin
        LTile := LTileBelow;
        LUnit := LTile.CurrentUnit;
      end;
    if Assigned(LUnit) and (LUnit <> AExcludeUnit) and (not Assigned(AExcludeAllBut) or (LUnit = AExcludeAllBut)) and
      (not AOnlyVisible or LUnit.GetVisible) then
    begin
      LUnitPosition := LUnit.Position;
      LTerrainHeight := 0;
      for LXs := 0 to LUnit.Armor.Size - 1 do
        for LYs := 0 to LUnit.Armor.Size - 1 do
        begin
          LTempTile := FSave.TileAt(LUnitPosition + TXcomPosition.Make(LXs, LYs, 0));
          if LTempTile.GetTerrainLevel < LTerrainHeight then
            LTerrainHeight := LTempTile.GetTerrainLevel;
        end;
      // the bottom most voxel; the terrain heights are negative
      LTz := LUnitPosition.Z * 24 + LUnit.FloatHeight - LTerrainHeight;
      if (AVoxel.Z > LTz) and (AVoxel.Z <= LTz + LUnit.GetHeight) then
      begin
        LX := 15 - AVoxel.X mod 16;
        LY := AVoxel.Y mod 16;
        LLarge := 0;
        if LUnit.Armor.Size > 1 then
        begin
          LTilePosition := LTile.Position;
          LLarge := LARGE_PARTS[LTilePosition.X - LUnitPosition.X + (LTilePosition.Y - LUnitPosition.Y) * 2];
        end;
        LOffset := LUnit.GetLoftemps(LLarge) * 16 + LY;
        if (LOffset < 0) or (LOffset >= Length(FVoxelData)) then
          raise EXcomBattleException.Create('Xcom: a voxel is outside the LOFT data');
        if (FVoxelData[LOffset] and (1 shl LX)) <> 0 then
          Exit(V_UNIT);
      end;
    end;
  end;
  Result := V_EMPTY;
end;

procedure TXcomTileEngine.VoxelCheckFlush;
begin
  FCacheTilePosition := TXcomPosition.Make(-1, -1, -1);
  FCacheTile := nil;
  FCacheTileBelow := nil;
end;

procedure TXcomTileEngine.TogglePersonalLighting;
begin
  FPersonalLighting := not FPersonalLighting;
  CalculateUnitLighting;
end;

function TXcomTileEngine.DistanceUnitToPositionSq(const AUnit: TXcomBattleUnit; const APosition: TXcomPosition;
  AConsiderZ: Boolean): Integer;
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  LX := AUnit.Position.X - APosition.X;
  LY := AUnit.Position.Y - APosition.Y;
  if AConsiderZ then
    LZ := AUnit.Position.Z - APosition.Z
  else
    LZ := 0;
  if AUnit.Armor.Size > 1 then
  begin
    if AUnit.Position.X < APosition.X then
      Inc(LX);
    if AUnit.Position.Y < APosition.Y then
      Inc(LY);
  end;
  Result := LX * LX + LY * LY + LZ * LZ;
end;

function TXcomTileEngine.Distance(const AFirst, ASecond: TXcomPosition): Integer;
var
  LX: Integer;
  LY: Integer;
  LRoot: Single;
begin
  LX := AFirst.X - ASecond.X;
  LY := AFirst.Y - ASecond.Y;
  LRoot := Sqrt(Single(LX * LX + LY * LY));
  Result := Ceil(LRoot);
end;

function TXcomTileEngine.DistanceSq(const AFirst, ASecond: TXcomPosition; AConsiderZ: Boolean): Integer;
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  LX := AFirst.X - ASecond.X;
  LY := AFirst.Y - ASecond.Y;
  if AConsiderZ then
    LZ := AFirst.Z - ASecond.Z
  else
    LZ := 0;
  Result := LX * LX + LY * LY + LZ * LZ;
end;

function TXcomTileEngine.FaceWindow(const APosition: TXcomPosition): Integer;
var
  LTile: TXcomTile;
begin
  LTile := FSave.TileAt(APosition);
  if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_NORTHWALL]) and
    (LTile.MapData[XCOM_PART_NORTHWALL].GetBlock(0) = 0) then
    Exit(0);
  LTile := FSave.TileAt(APosition + TXcomPosition.Make(1, 0, 0));
  if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_WESTWALL]) and
    (LTile.MapData[XCOM_PART_WESTWALL].GetBlock(0) = 0) then
    Exit(2);
  LTile := FSave.TileAt(APosition + TXcomPosition.Make(0, 1, 0));
  if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_NORTHWALL]) and
    (LTile.MapData[XCOM_PART_NORTHWALL].GetBlock(0) = 0) then
    Exit(4);
  LTile := FSave.TileAt(APosition);
  if Assigned(LTile) and Assigned(LTile.MapData[XCOM_PART_WESTWALL]) and
    (LTile.MapData[XCOM_PART_WESTWALL].GetBlock(0) = 0) then
    Exit(6);
  Result := -1;
end;

function TXcomTileEngine.UnitOpensDoor(const AUnit: TXcomBattleUnit; ARightClick: Boolean;
  ADirection: Integer): Integer;
type
  TCheck = record
    Offset: TXcomPosition;
    Part: Integer;
  end;
var
  LDoor: Integer;
  LTuCost: Integer;
  LSize: Integer;
  LZ: Integer;
  LX: Integer;
  LY: Integer;
  LTile: TXcomTile;
  LChecks: TList<TCheck>;
  LPart: Integer;
  LIndex: Integer;
  LBase: TXcomPosition;
  LVisible: TArray<TXcomBattleUnit>;
  LOther: TXcomBattleUnit;

  procedure Add(AX, AY, APart: Integer);
  var
    LCheck: TCheck;
  begin
    LCheck.Offset := TXcomPosition.Make(AX, AY, 0);
    LCheck.Part := APart;
    LChecks.Add(LCheck);
  end;

begin
  LDoor := -1;
  LTuCost := 0;
  LSize := AUnit.Armor.Size;
  // if we're standing on stairs, check the tile above instead.
  if AUnit.Tile.GetTerrainLevel < -12 then
    LZ := 1
  else
    LZ := 0;
  if ADirection = -1 then
    ADirection := AUnit.Direction;
  LChecks := TList<TCheck>.Create;
  try
    LX := 0;
    while (LX < LSize) and (LDoor = -1) do
    begin
      LY := 0;
      while (LY < LSize) and (LDoor = -1) do
      begin
        LChecks.Clear;
        LTile := FSave.TileAt(AUnit.Position + TXcomPosition.Make(LX, LY, LZ));
        if not Assigned(LTile) then
        begin
          Inc(LY);
          Continue;
        end;
        case ADirection of
          0: // north
            begin
              Add(0, 0, XCOM_PART_NORTHWALL);
              if LX <> 0 then
                Add(0, -1, XCOM_PART_WESTWALL);
            end;
          1: // north east
            begin
              Add(0, 0, XCOM_PART_NORTHWALL);
              Add(1, -1, XCOM_PART_WESTWALL);
              if ARightClick then
              begin
                Add(1, 0, XCOM_PART_WESTWALL);
                Add(1, 0, XCOM_PART_NORTHWALL);
              end;
            end;
          2: // east
            Add(1, 0, XCOM_PART_WESTWALL);
          3: // south-east
            begin
              if LY = 0 then
                Add(1, 1, XCOM_PART_WESTWALL);
              if LX = 0 then
                Add(1, 1, XCOM_PART_NORTHWALL);
              if ARightClick then
              begin
                Add(1, 0, XCOM_PART_WESTWALL);
                Add(0, 1, XCOM_PART_NORTHWALL);
              end;
            end;
          4: // south
            Add(0, 1, XCOM_PART_NORTHWALL);
          5: // south-west
            begin
              Add(0, 0, XCOM_PART_WESTWALL);
              Add(-1, 1, XCOM_PART_NORTHWALL);
              if ARightClick then
              begin
                Add(0, 1, XCOM_PART_WESTWALL);
                Add(0, 1, XCOM_PART_NORTHWALL);
              end;
            end;
          6: // west
            begin
              Add(0, 0, XCOM_PART_WESTWALL);
              if LY <> 0 then
                Add(-1, 0, XCOM_PART_NORTHWALL);
            end;
          7: // north-west
            begin
              Add(0, 0, XCOM_PART_WESTWALL);
              Add(0, 0, XCOM_PART_NORTHWALL);
              if LX <> 0 then
                Add(-1, -1, XCOM_PART_WESTWALL);
              if LY <> 0 then
                Add(-1, -1, XCOM_PART_NORTHWALL);
              if ARightClick then
              begin
                Add(0, -1, XCOM_PART_WESTWALL);
                Add(-1, 0, XCOM_PART_NORTHWALL);
              end;
            end;
        end;
        LPart := XCOM_PART_FLOOR;
        LIndex := 0;
        while (LIndex < LChecks.Count) and (LDoor = -1) do
        begin
          LBase := AUnit.Position + TXcomPosition.Make(LX, LY, LZ) + LChecks[LIndex].Offset;
          LTile := FSave.TileAt(LBase);
          if Assigned(LTile) then
          begin
            LDoor := LTile.OpenDoor(LChecks[LIndex].Part, AUnit, FHost.ReservedAction);
            if LDoor <> -1 then
            begin
              LPart := LChecks[LIndex].Part;
              if LDoor = 1 then
                CheckAdjacentDoors(LBase, LChecks[LIndex].Part);
            end;
          end;
          Inc(LIndex);
        end;
        if (LDoor = 0) and ARightClick then
        begin
          if LPart = XCOM_PART_WESTWALL then
            LPart := XCOM_PART_NORTHWALL
          else
            LPart := XCOM_PART_WESTWALL;
          LTuCost := LTile.GetTuCost(LPart, AUnit.MovementType);
        end
        else if (LDoor = 1) or (LDoor = 4) then
          LTuCost := LTile.GetTuCost(LPart, AUnit.MovementType);
        Inc(LY);
      end;
      Inc(LX);
    end;
  finally
    LChecks.Free;
  end;
  if LTuCost <> 0 then
  begin
    if FHost.CheckReservedTu(AUnit, LTuCost) then
    begin
      if AUnit.SpendTimeUnits(LTuCost) then
      begin
        CalculateFovAt(AUnit.Position);
        // look from the other side
        LVisible := AUnit.VisibleUnits.ToArray;
        for LOther in LVisible do
          CalculateFov(LOther);
      end
      else
        Exit(4);
    end
    else
      Exit(5);
  end;
  Result := LDoor;
end;

procedure TXcomTileEngine.SetDangerZone(const APosition: TXcomPosition; ARadius: Integer;
  const AUnit: TXcomBattleUnit);
var
  LTile: TXcomTile;
  LOrigin: TXcomPosition;
  LTarget: TXcomPosition;
  LX: Integer;
  LY: Integer;
  LTrajectory: TList<TXcomPosition>;
  LCell: TXcomPosition;
begin
  LTile := FSave.TileAt(APosition);
  if not Assigned(LTile) then
    Exit;
  // set the epicenter as dangerous
  LTile.Dangerous := True;
  LOrigin := (APosition * TXcomPosition.Make(16, 16, 24)) + TXcomPosition.Make(8, 8, 12 + -LTile.GetTerrainLevel);
  LTrajectory := TList<TXcomPosition>.Create;
  try
    // the loops of the C++ stop before +radius
    LX := -ARadius;
    while LX <> ARadius do
    begin
      LY := -ARadius;
      while LY <> ARadius do
      begin
        // we can skip the epicenter
        if (LX <> 0) or (LY <> 0) then
          // make sure we're within the radius
          if LX * LX + LY * LY <= ARadius * ARadius then
          begin
            LCell := APosition + TXcomPosition.Make(LX, LY, 0);
            LTile := FSave.TileAt(LCell);
            if Assigned(LTile) then
            begin
              LTarget := (LCell * TXcomPosition.Make(16, 16, 24)) +
                TXcomPosition.Make(8, 8, 12 + -LTile.GetTerrainLevel);
              LTrajectory.Clear;
              // we'll trace a line here, ignoring all units, to check if the explosion will reach this point
              if CalculateLine(LOrigin, LTarget, False, LTrajectory, AUnit, True, False, AUnit) = V_EMPTY then
                if (LTrajectory.Count > 0) and
                  ((LTrajectory[LTrajectory.Count - 1] div TXcomPosition.Make(16, 16, 24)) = LCell) then
                  LTile.Dangerous := True;
            end;
          end;
        Inc(LY);
      end;
      Inc(LX);
    end;
  finally
    LTrajectory.Free;
  end;
end;

procedure TXcomTileEngine.CheckAdjacentDoors(const APosition: TXcomPosition; APart: Integer);
var
  LWestSide: Boolean;
  LIndex: Integer;
  LTile: TXcomTile;

  function Offset(AStep: Integer): TXcomPosition;
  begin
    if LWestSide then
      Result := TXcomPosition.Make(0, AStep, 0)
    else
      Result := TXcomPosition.Make(AStep, 0, 0);
  end;

begin
  LWestSide := APart = XCOM_PART_WESTWALL;
  LIndex := 1;
  while True do
  begin
    LTile := FSave.TileAt(APosition + Offset(LIndex));
    if Assigned(LTile) and Assigned(LTile.MapData[APart]) and LTile.MapData[APart].IsUfoDoor then
      LTile.OpenDoor(APart)
    else
      Break;
    Inc(LIndex);
  end;
  LIndex := -1;
  while True do
  begin
    LTile := FSave.TileAt(APosition + Offset(LIndex));
    if Assigned(LTile) and Assigned(LTile.MapData[APart]) and LTile.MapData[APart].IsUfoDoor then
      LTile.OpenDoor(APart)
    else
      Break;
    Dec(LIndex);
  end;
end;

function TXcomTileEngine.CloseUfoDoors: Integer;
var
  LIndex: Integer;
  LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
  LNorth: TXcomTile;
  LWest: TXcomTile;
begin
  Result := 0;
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
  begin
    LTile := FSave.TileByIndex(LIndex);
    if Assigned(LTile.CurrentUnit) and (LTile.CurrentUnit.Armor.Size > 1) then
    begin
      LUnit := LTile.CurrentUnit;
      LNorth := FSave.TileAt(LTile.Position + TXcomPosition.Make(0, -1, 0));
      LWest := FSave.TileAt(LTile.Position + TXcomPosition.Make(-1, 0, 0));
      if (LTile.IsUfoDoorOpen(XCOM_PART_NORTHWALL) and Assigned(LNorth) and Assigned(LNorth.CurrentUnit) and
        (LNorth.CurrentUnit = LUnit)) or (LTile.IsUfoDoorOpen(XCOM_PART_WESTWALL) and Assigned(LWest) and
        Assigned(LWest.CurrentUnit) and (LWest.CurrentUnit = LUnit)) then
        Continue;
    end;
    Inc(Result, LTile.CloseUfoDoor);
  end;
end;

procedure TXcomTileEngine.ApplyGravity(const ATile: TXcomTile);
begin
  ApplyGravityTile(ATile);
end;

procedure TXcomTileEngine.ItemDrop(const ATile: TXcomTile; const AItem: TXcomBattleItem;
  const AGround: TXcomRuleInventory; ANewItem, ARemoveItem: Boolean);
var
  LPosition: TXcomPosition;
begin
  // don't spawn anything outside of bounds
  if not Assigned(ATile) then
    Exit;
  LPosition := ATile.Position;
  // don't ever drop fixed items
  if AItem.Rules.FixedWeapon then
    Exit;
  ATile.AddItem(AItem, AGround);
  if Assigned(AItem.CorpseUnit) then
    AItem.CorpseUnit.SetPosition(LPosition);
  if ANewItem then
    FSave.AddItem(AItem)
  else if FSave.Side <> FACTION_PLAYER then
    AItem.TurnFlag := True;
  if ARemoveItem then
    AItem.MoveToOwner(nil)
  else if (AItem.Rules.BattleType <> TXcomRuleItem.BT_GRENADE) and
    (AItem.Rules.BattleType <> TXcomRuleItem.BT_PROXIMITYGRENADE) then
    AItem.SetOwner(nil);
  ApplyGravity(FSave.TileAt(LPosition));
  if AItem.Rules.BattleType = TXcomRuleItem.BT_FLARE then
  begin
    CalculateTerrainLighting;
    CalculateFovAt(LPosition);
  end;
end;

function TXcomTileEngine.ApplyGravityTile(const ATile: TXcomTile): TXcomTile;
var
  LPosition: TXcomPosition;
  LTarget: TXcomTile;
  LBelow: TXcomTile;
  LOccupant: TXcomBattleUnit;
  LUnitPosition: TXcomPosition;
  LCanFall: Boolean;
  LX: Integer;
  LY: Integer;
  LOrigin: TXcomPosition;
  LItem: TXcomBattleItem;
  LIndex: Integer;
begin
  if not Assigned(ATile) or ((ATile.Inventory.Count = 0) and not Assigned(ATile.CurrentUnit)) then
    Exit(ATile);
  LPosition := ATile.Position;
  LOccupant := ATile.CurrentUnit;
  if Assigned(LOccupant) then
  begin
    LUnitPosition := LOccupant.Position;
    while LUnitPosition.Z >= 0 do
    begin
      LCanFall := True;
      LY := 0;
      while (LY < LOccupant.Armor.Size) and LCanFall do
      begin
        LX := 0;
        while (LX < LOccupant.Armor.Size) and LCanFall do
        begin
          LTarget := FSave.TileAt(TXcomPosition.Make(LUnitPosition.X + LX, LUnitPosition.Y + LY, LUnitPosition.Z));
          LBelow := FSave.TileAt(TXcomPosition.Make(LUnitPosition.X + LX, LUnitPosition.Y + LY, LUnitPosition.Z - 1));
          if not LTarget.HasNoFloor(LBelow) then
            LCanFall := False;
          Inc(LX);
        end;
        Inc(LY);
      end;
      if not LCanFall then
        Break;
      Dec(LUnitPosition.Z);
    end;
    if LUnitPosition <> LOccupant.Position then
    begin
      if (LOccupant.Health <> 0) and (LOccupant.StunLevel < LOccupant.Health) then
      begin
        if LOccupant.MovementType = MT_FLY then
        begin
          // moves to the position it is in: the kneeling flag goes off and the floating flag on
          LOccupant.StartWalking(LOccupant.Direction, LOccupant.Position,
            FSave.TileAt(LOccupant.Position + TXcomPosition.Make(0, 0, -1)), True);
          LOccupant.AbortTurn;
        end
        else
        begin
          // sets up the last position of the unit for falling
          LOccupant.SetPosition(LOccupant.Position);
          FSave.AddFallingUnit(LOccupant);
        end;
      end
      else if LOccupant.IsOut then
      begin
        LOrigin := LOccupant.Position;
        for LY := LOccupant.Armor.Size - 1 downto 0 do
          for LX := LOccupant.Armor.Size - 1 downto 0 do
            FSave.TileAt(LOrigin + TXcomPosition.Make(LX, LY, 0)).SetUnit(nil);
        LOccupant.SetPosition(LUnitPosition);
      end;
    end;
  end;
  LTarget := ATile;
  LCanFall := True;
  while (LPosition.Z >= 0) and LCanFall do
  begin
    LTarget := FSave.TileAt(LPosition);
    LBelow := FSave.TileAt(TXcomPosition.Make(LPosition.X, LPosition.Y, LPosition.Z - 1));
    if not LTarget.HasNoFloor(LBelow) then
      LCanFall := False;
    Dec(LPosition.Z);
  end;
  // the loop of the C++ iterates the items of the tile while adding them to another tile
  for LIndex := 0 to ATile.Inventory.Count - 1 do
  begin
    LItem := ATile.Inventory[LIndex];
    if Assigned(LItem.CorpseUnit) and (ATile.Position = LItem.CorpseUnit.Position) then
      LItem.CorpseUnit.SetPosition(LTarget.Position);
    if ATile <> LTarget then
      LTarget.AddItem(LItem, LItem.Slot);
  end;
  if ATile <> LTarget then
    ATile.Inventory.Clear;
  Result := LTarget;
end;

function TXcomTileEngine.CheckForTerrainExplosions: TXcomTile;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
    if FSave.TileByIndex(LIndex).Explosive <> 0 then
      Exit(FSave.TileByIndex(LIndex));
  Result := nil;
end;

function TXcomTileEngine.Detonate(const ATile: TXcomTile): Boolean;
const
  PARTS: array[0..8] of Integer = (XCOM_PART_FLOOR, XCOM_PART_WESTWALL, XCOM_PART_NORTHWALL, XCOM_PART_FLOOR,
    XCOM_PART_WESTWALL, XCOM_PART_NORTHWALL, XCOM_PART_OBJECT, XCOM_PART_OBJECT, XCOM_PART_OBJECT);
var
  LExplosive: Integer;
  LTiles: array[0..8] of TXcomTile;
  LPosition: TXcomPosition;
  LI: Integer;
  LRemaining: Integer;
  LFireProof: Integer;
  LFuel: Integer;
  LDestroyed: Boolean;
  LBigWallDestroyed: Boolean;
  LSkipNorthWest: Boolean;
  LBigWall: Integer;
  LVolume: Integer;
  LCurrent: Integer;
  LNextPart: Integer;
  LDieMcd: Integer;
  LJ: Integer;
  LSmoke: Integer;
  LSet: TObject;
begin
  Result := False;
  LExplosive := ATile.Explosive;
  if LExplosive = 0 then
    Exit(False);
  ATile.SetExplosive(0, 0, True);
  LPosition := ATile.Position;
  LTiles[0] := FSave.TileAt(TXcomPosition.Make(LPosition.X, LPosition.Y, LPosition.Z + 1));
  LTiles[1] := FSave.TileAt(TXcomPosition.Make(LPosition.X + 1, LPosition.Y, LPosition.Z));
  LTiles[2] := FSave.TileAt(TXcomPosition.Make(LPosition.X, LPosition.Y + 1, LPosition.Z));
  LTiles[3] := ATile;
  LTiles[4] := ATile;
  LTiles[5] := ATile;
  LTiles[6] := ATile;
  LTiles[7] := FSave.TileAt(TXcomPosition.Make(LPosition.X, LPosition.Y - 1, LPosition.Z));
  LTiles[8] := FSave.TileAt(TXcomPosition.Make(LPosition.X - 1, LPosition.Y, LPosition.Z));
  LBigWallDestroyed := True;
  LSkipNorthWest := False;
  for LI := 8 downto 0 do
  begin
    if not Assigned(LTiles[LI]) or not Assigned(LTiles[LI].MapData[PARTS[LI]]) then
      Continue;
    LBigWall := LTiles[LI].MapData[PARTS[LI]].BigWall;
    if (LI > 6) and not ((LBigWall = 1) or (LBigWall = 8) or ((LI = 8) and (LBigWall = 6)) or
      ((LI = 7) and (LBigWall = 7))) then
      Continue;
    if LBigWall <> 0 then
      LSkipNorthWest := True;
    if not LBigWallDestroyed and (LI < 6) then
      Continue;
    if LSkipNorthWest and ((LI = 2) or (LI = 1)) then
      Continue;
    LRemaining := LExplosive;
    LDestroyed := False;
    LVolume := 0;
    LCurrent := PARTS[LI];
    LFireProof := LTiles[LI].GetFlammability(LCurrent);
    LFuel := LTiles[LI].GetFuel(LCurrent) + 1;
    for LJ := 0 to 11 do
      if LTiles[LI].MapData[LCurrent].GetLoftId(LJ) <> 0 then
        Inc(LVolume);
    if (LI = 6) and ((LBigWall = 2) or (LBigWall = 3)) and (2 * LTiles[LI].MapData[LCurrent].Armor > LRemaining) then
      LBigWallDestroyed := False;
    while Assigned(LTiles[LI].MapData[LCurrent]) and (2 * LTiles[LI].MapData[LCurrent].Armor <= LRemaining) and
      (LTiles[LI].MapData[LCurrent].Armor <> 255) do
    begin
      if (LI = 6) and ((LBigWall = 2) or (LBigWall = 3)) then
        LBigWallDestroyed := True;
      if (LI = 6) and ((LBigWall = 6) or (LBigWall = 7) or (LBigWall = 8)) then
        LSkipNorthWest := False;
      Dec(LRemaining, 2 * LTiles[LI].MapData[LCurrent].Armor);
      LDestroyed := True;
      if (FSave.MissionType = 'STR_BASE_DEFENSE') and LTiles[LI].MapData[LCurrent].IsBaseModule then
        FSave.ModuleMap[ATile.Position.X div 10][ATile.Position.Y div 10] :=
          TPair<Integer, Integer>.Create(FSave.ModuleMap[ATile.Position.X div 10][ATile.Position.Y div 10].Key,
          FSave.ModuleMap[ATile.Position.X div 10][ATile.Position.Y div 10].Value - 1);
      // transformed parts: an object can become a ground
      LDieMcd := LTiles[LI].MapData[LCurrent].DieMcd;
      if LDieMcd <> 0 then
      begin
        LSet := LTiles[LI].MapData[LCurrent].Dataset;
        LNextPart := (LSet as TXcomMapDataSet).GetObject(LDieMcd).ObjectType;
      end
      else
        LNextPart := LCurrent;
      if LTiles[LI].DestroyPart(LCurrent, FSave.ObjectiveType, FSave.ScorchedEarth) then
        Result := True;
      LCurrent := LNextPart;
      if Assigned(LTiles[LI].MapData[LCurrent]) then
      begin
        LFireProof := LTiles[LI].GetFlammability(LCurrent);
        LFuel := LTiles[LI].GetFuel(LCurrent) + 1;
      end;
    end;
    // set the tile on fire
    if (2 * LFireProof) < LRemaining then
      if Assigned(LTiles[LI].MapData[XCOM_PART_FLOOR]) or Assigned(LTiles[LI].MapData[XCOM_PART_OBJECT]) then
      begin
        LTiles[LI].SetFire(LFuel);
        LTiles[LI].SetSmoke(EnsureRange(15 - (LFireProof div 10), 1, 12));
      end;
    // some smoke when the tile was destroyed and is not on fire
    if LDestroyed then
    begin
      if (LTiles[LI].Fire <> 0) and not Assigned(LTiles[LI].MapData[XCOM_PART_FLOOR]) and
        not Assigned(LTiles[LI].MapData[XCOM_PART_OBJECT]) then
        LTiles[LI].SetFire(0);
      if LTiles[LI].Fire = 0 then
      begin
        LSmoke := FContext.Random.Generate(1, (LVolume div 2) + 3) + (LVolume div 2);
        if LSmoke > LTiles[LI].Smoke then
          LTiles[LI].SetSmoke(EnsureRange(LSmoke, 0, 15));
      end;
    end;
  end;
end;


procedure TXcomTileEngine.SetDetonationOrder(const AOrder: TArray<Integer>);
var
  LIndex: Integer;
begin
  SetLength(FDetonationRank, Length(AOrder));
  for LIndex := 0 to High(AOrder) do
    FDetonationRank[AOrder[LIndex]] := LIndex;
end;

procedure TXcomTileEngine.Explode(const ACenter: TXcomPosition; APower, ADamageType, AMaxRadius: Integer;
  const AUnit: TXcomBattleUnit);
var
  LCenterZ: Double;
  LCenterX: Double;
  LCenterY: Double;
  LHitSide: Integer;
  LDiagonalWall: Integer;
  LPower: Integer;
  LAffected: TList<TXcomTile>;
  LSeen: TDictionary<Integer, Boolean>;
  LExHeight: Integer;
  LVertDec: Integer;
  LDamageRange: Integer;
  LOrigin: TXcomTile;
  LDest: TXcomTile;
  LFi: Integer;
  LTe: Integer;
  LCosTe, LSinTe, LSinFi, LCosFi: Double;
  LLength: Double;
  LTileX, LTileY, LTileZ: Integer;
  LMin: Integer;
  LMax: Integer;
  LUnit: TXcomBattleUnit;
  LBelow: TXcomTile;
  LWounds: Integer;
  LItem: TXcomBattleItem;
  LCopy: TArray<TXcomBattleItem>;
  LResistance: Single;
  LBurnTime: Integer;
  LDirection: Integer;
  LSkipObject: Boolean;
  LCenterTile: TXcomPosition;
  LTile: TXcomTile;
  LAbove: TXcomTile;
  LDistanceFromCenter: Integer;
  LRounded: Double;
  LAngle: Double;

  function CenterPosition: TXcomPosition;
  begin
    Result := TXcomPosition.Make(Trunc(LCenterX), Trunc(LCenterY), Trunc(LCenterZ));
  end;

begin
  LCenterZ := ACenter.Z div 24 + 0.5;
  LCenterX := ACenter.X div 16 + 0.5;
  LCenterY := ACenter.Y div 16 + 0.5;
  LHitSide := 0;
  LDiagonalWall := 0;
  if ADamageType = TXcomRuleItem.DT_IN then
    APower := APower div 2;
  LExHeight := EnsureRange(FContext.ExplosionHeight, 0, 3);
  LVertDec := 1000;
  if ADamageType = TXcomRuleItem.DT_HE then
    LDamageRange := FContext.ExplosiveDamageRange
  else
    LDamageRange := FContext.DamageRange;
  case LExHeight of
    1: LVertDec := 30;
    2: LVertDec := 10;
    3: LVertDec := 5;
  end;
  LOrigin := FSave.TileAt(CenterPosition);
  if LOrigin.IsBigWall then
  begin
    LDiagonalWall := LOrigin.MapData[XCOM_PART_OBJECT].BigWall;
    if LDiagonalWall = BIGWALL_NWSE then
    begin
      if (ACenter.X mod 16 - ACenter.Y mod 16) > 0 then
        LHitSide := 1
      else
        LHitSide := -1;
    end;
    if LDiagonalWall = BIGWALL_NESW then
    begin
      if (ACenter.X mod 16 + ACenter.Y mod 16 - 15) > 0 then
        LHitSide := 1
      else
        LHitSide := -1;
    end;
  end;
  LAffected := TList<TXcomTile>.Create;
  LSeen := TDictionary<Integer, Boolean>.Create;
  try
    LFi := -90;
    while LFi <= 90 do
    begin
      // a ray every 3 degrees makes sure that all the tiles of a circle are reached
      LTe := 0;
      while LTe <= 360 do
      begin
        // Deg2Rad returns a double and sin/cos take one: the angle is rounded to 53 bits before the x87 function
        // (the sine of 330 degrees is on the boundary of a tile, so the last bit decides the tile)
        LAngle := LTe * PI_VALUE / 180.0;
        LCosTe := Cos(LAngle);
        LSinTe := Sin(LAngle);
        LAngle := LFi * PI_VALUE / 180.0;
        LSinFi := Sin(LAngle);
        LCosFi := Cos(LAngle);
        LOrigin := FSave.TileAt(CenterPosition);
        LDest := LOrigin;
        LLength := 0;
        LPower := APower;
        while (LPower > 0) and (LLength <= AMaxRadius) do
        begin
          if LPower > 0 then
          begin
            if ADamageType = TXcomRuleItem.DT_HE then
              // explosives do half damage to the terrain
              LDest.SetExplosive(LPower, 0);
            if not LSeen.ContainsKey(FSave.TileIndex(LDest.Position)) then
            begin
              LSeen.Add(FSave.TileIndex(LDest.Position), True);
              LAffected.Add(LDest);
              LMin := LPower * (100 - LDamageRange) div 100;
              LMax := LPower * (100 + LDamageRange) div 100;
              LUnit := LDest.CurrentUnit;
              LBelow := FSave.TileAt(LDest.Position - TXcomPosition.Make(0, 0, 1));
              LWounds := 0;
              if not Assigned(LUnit) and (LDest.Position.Z > 0) and LDest.HasNoFloor(LBelow) then
              begin
                LUnit := LBelow.CurrentUnit;
                // a unit below with no voxels poking into the tile is not damaged
                if Assigned(LUnit) and (LUnit.GetHeight + LUnit.FloatHeight - LBelow.GetTerrainLevel <= 24) then
                  LUnit := nil;
              end;
              if Assigned(LUnit) and Assigned(AUnit) then
                LWounds := LUnit.GetFatalWounds;
              case ADamageType of
                TXcomRuleItem.DT_STUN:
                  begin
                    if Assigned(LUnit) then
                    begin
                      LDistanceFromCenter := Distance(LDest.Position, CenterPosition);
                      if LDistanceFromCenter < 2 then
                        LUnit.Damage(TXcomPosition.Make(0, 0, 0), FContext.Random.Generate(LMin, LMax), ADamageType)
                      else
                        LUnit.Damage(CenterPosition - LDest.Position, FContext.Random.Generate(LMin, LMax), ADamageType);
                    end;
                    for LItem in LDest.Inventory do
                      if Assigned(LItem.CorpseUnit) then
                        LItem.CorpseUnit.Damage(TXcomPosition.Make(0, 0, 0), FContext.Random.Generate(LMin, LMax),
                          ADamageType);
                  end;
                TXcomRuleItem.DT_HE:
                  begin
                    if Assigned(LUnit) then
                    begin
                      if ((Abs(LDest.Position.X - Trunc(LCenterX)) < 2) and (Abs(LDest.Position.Y - Trunc(LCenterY)) < 2) and
                        (LDest.Position.Z = Trunc(LCenterZ))) or (LDest.Position.Z > Trunc(LCenterZ)) then
                        // ground zero, or a unit above the explosion
                        LUnit.Damage(TXcomPosition.Make(0, 0, 0), FContext.Random.Generate(LMin, LMax), ADamageType)
                      else
                        // directional damage: a unit above is hit in the legs, the others in the torso
                        LUnit.Damage(TXcomPosition.Make(Trunc(LCenterX), Trunc(LCenterY), Trunc(LCenterZ) + 5) -
                          LDest.Position, FContext.Random.Generate(LMin, LMax), ADamageType);
                    end;
                    LCopy := LDest.Inventory.ToArray;
                    for LItem in LCopy do
                      if LPower > LItem.Rules.Armor then
                      begin
                        if Assigned(LItem.CorpseUnit) and (LItem.CorpseUnit.Status = STATUS_UNCONSCIOUS) then
                          LItem.CorpseUnit.Kill;
                        FSave.RemoveItem(LItem);
                      end;
                  end;
                TXcomRuleItem.DT_SMOKE:
                  if (LDest.Smoke < 10) and (LDest.GetTerrainLevel > -24) then
                  begin
                    LDest.SetFire(0);
                    LDest.SetSmoke(FContext.Random.Generate(7, 15));
                  end;
                TXcomRuleItem.DT_IN:
                  if not LDest.IsVoid then
                  begin
                    if (LDest.Fire = 0) and (Assigned(LDest.MapData[XCOM_PART_FLOOR]) or
                      Assigned(LDest.MapData[XCOM_PART_OBJECT])) then
                    begin
                      LDest.SetFire(LDest.GetFuel + 1);
                      LDest.SetSmoke(EnsureRange(15 - (LDest.GetFlammability div 10), 1, 12));
                    end;
                    if Assigned(LUnit) then
                    begin
                      LResistance := LUnit.Armor.DamageModifier[TXcomRuleItem.DT_IN];
                      if LResistance > 0.0 then
                      begin
                        LUnit.Damage(TXcomPosition.Make(0, 0, 12 - LDest.GetTerrainLevel),
                          FContext.Random.Generate(FContext.FireDamageRange(0), FContext.FireDamageRange(1)),
                          TXcomRuleItem.DT_IN, True);
                        LBurnTime := FContext.Random.Generate(0, Trunc(Single(5.0) * LResistance));
                        if LUnit.Fire < LBurnTime then
                          LUnit.SetFire(LBurnTime);
                      end;
                    end;
                  end;
              end;
              if Assigned(AUnit) and Assigned(LUnit) and (LUnit.Faction <> AUnit.Faction) then
              begin
                AUnit.AddFiringExp;
                // credit for a kill by bleeding to death, if it is not a unit of the player
                if (LWounds < LUnit.GetFatalWounds) and (LUnit.Faction <> FACTION_PLAYER) then
                  LUnit.KilledBy := AUnit.Faction;
              end;
            end;
          end;
          LLength := LLength + 1.0;
          // the C++ passes a double to floor(): the sum is rounded to 53 bits before the floor (on a boundary
          // like 0.5 + 0.49999999999999994 the extended value would give the tile below)
          LRounded := LCenterX + LLength * LSinTe * LCosFi;
          LTileX := Floor(LRounded);
          LRounded := LCenterY + LLength * LCosTe * LCosFi;
          LTileY := Floor(LRounded);
          LRounded := LCenterZ + LLength * LSinFi;
          LTileZ := Floor(LRounded);
          LOrigin := LDest;
          LDest := FSave.TileAt(TXcomPosition.Make(LTileX, LTileY, LTileZ));
          if not Assigned(LDest) then
            Break;
          // the blockage by the terrain is deducted from the power: 10 a tile
          Dec(LPower, 10);
          if LOrigin.Position.Z <> LTileZ then
            Dec(LPower, LVertDec);
          if ADamageType = TXcomRuleItem.DT_IN then
          begin
            LDirection := TXcomDirections.FromVector(LOrigin.Position - LDest.Position);
            // a diagonal step costs half as much again for fire
            if (LDirection <> -1) and ((LDirection mod 2) <> 0) then
              Dec(LPower, 5);
          end;
          if LLength > 0.5 then
          begin
            if LLength > 1.5 then
            begin
              Dec(LPower, VerticalBlockage(LOrigin, LDest, ADamageType, False) * 2);
              Dec(LPower, HorizontalBlockage(LOrigin, LDest, ADamageType, False) * 2);
            end
            else
            begin
              // the deflection of the big walls
              LSkipObject := LDiagonalWall = 0;
              if LDiagonalWall = BIGWALL_NESW then
              begin
                if (LHitSide < 0) and (LTe >= 135) and (LTe < 315) then
                  LSkipObject := True;
                if (LHitSide > 0) and ((LTe < 135) or (LTe > 315)) then
                  LSkipObject := True;
              end;
              if LDiagonalWall = BIGWALL_NWSE then
              begin
                if (LHitSide > 0) and (LTe >= 45) and (LTe < 225) then
                  LSkipObject := True;
                if (LHitSide < 0) and ((LTe < 45) or (LTe > 225)) then
                  LSkipObject := True;
              end;
              Dec(LPower, VerticalBlockage(LOrigin, LDest, ADamageType, LSkipObject) * 2);
              Dec(LPower, HorizontalBlockage(LOrigin, LDest, ADamageType, LSkipObject) * 2);
            end;
          end;
        end;
        Inc(LTe, 3);
      end;
      Inc(LFi, 5);
    end;
    // the tiles that HE reached are detonated
    if ADamageType = TXcomRuleItem.DT_HE then
    begin
      LAffected.Sort(TComparer<TXcomTile>.Construct(
        function(const ALeft, ARight: TXcomTile): Integer
        begin
          if Length(FDetonationRank) > 0 then
            Result := FDetonationRank[FSave.TileIndex(ALeft.Position)] - FDetonationRank[FSave.TileIndex(ARight.Position)]
          else
            Result := FSave.TileIndex(ALeft.Position) - FSave.TileIndex(ARight.Position);
        end));
      for LTile in LAffected do
      begin
        if Detonate(LTile) then
          FSave.AddDestroyedObjective;
        ApplyGravityTile(LTile);
        LAbove := FSave.TileAt(LTile.Position + TXcomPosition.Make(0, 0, 1));
        if Assigned(LAbove) then
          ApplyGravityTile(LAbove);
      end;
    end;
  finally
    LSeen.Free;
    LAffected.Free;
  end;
  // roofs may have been destroyed and fires started
  CalculateSunShading;
  CalculateTerrainLighting;
  LCenterTile := VoxelToTile(ACenter);
  CalculateFovAt(LCenterTile);
end;

function TXcomTileEngine.GetDirectionTo(const AOrigin, ATarget: TXcomPosition): Integer;
const
  QUARTER_PI: Double = 0.785398163397448309616;
var
  LDeltaX: Double;
  LDeltaY: Double;
  LAngle: Double;
  LPie: array[0..3] of Double;
begin
  LDeltaX := ATarget.X - AOrigin.X;
  LDeltaY := ATarget.Y - AOrigin.Y;
  LAngle := ArcTan2(LDeltaX, -LDeltaY);
  // divide the pie in 4 angles each at 1/8th before each quarter
  LPie[0] := (QUARTER_PI * 4.0) - QUARTER_PI / 2.0;
  LPie[1] := (QUARTER_PI * 3.0) - QUARTER_PI / 2.0;
  LPie[2] := (QUARTER_PI * 2.0) - QUARTER_PI / 2.0;
  LPie[3] := (QUARTER_PI * 1.0) - QUARTER_PI / 2.0;
  Result := 0;
  if (LAngle > LPie[0]) or (LAngle < -LPie[0]) then
    Result := 4
  else if LAngle > LPie[1] then
    Result := 3
  else if LAngle > LPie[2] then
    Result := 2
  else if LAngle > LPie[3] then
    Result := 1
  else if LAngle < -LPie[1] then
    Result := 5
  else if LAngle < -LPie[2] then
    Result := 6
  else if LAngle < -LPie[3] then
    Result := 7
  else if LAngle < LPie[0] then
    Result := 0;
end;

function TXcomTileEngine.GetOriginVoxel(const AAction: TXcomBattleAction; const ATile: TXcomTile): TXcomPosition;
const
  DIRECTION_Y_SHIFT: array[0..7] of Integer = (1, 1, 8, 15, 15, 15, 8, 1);
  DIRECTION_X_SHIFT: array[0..7] of Integer = (8, 14, 15, 15, 8, 1, 1, 1);
var
  LTile: TXcomTile;
  LOrigin: TXcomPosition;
  LTileAbove: TXcomTile;
  LDirection: Integer;
begin
  LTile := ATile;
  if not Assigned(LTile) then
    LTile := AAction.Actor.Tile;
  LOrigin := LTile.Position;
  LTileAbove := FSave.TileAt(LOrigin + TXcomPosition.Make(0, 0, 1));
  Result := TXcomPosition.Make(LOrigin.X * 16, LOrigin.Y * 16, LOrigin.Z * 24);
  // the height of the soldier and the terrain level count when the projectile leaves a soldier
  if (AAction.Actor.Position = LOrigin) or (AAction.ActionType <> BA_LAUNCH) then
  begin
    Dec(Result.Z, LTile.GetTerrainLevel);
    Inc(Result.Z, AAction.Actor.GetHeight + AAction.Actor.FloatHeight);
    if AAction.ActionType = BA_THROW then
      Dec(Result.Z, 3)
    else
      Dec(Result.Z, 4);
    if Result.Z >= (LOrigin.Z + 1) * 24 then
    begin
      if Assigned(LTileAbove) and LTileAbove.HasNoFloor(nil) then
        Inc(LOrigin.Z)
      else
      begin
        while Result.Z >= (LOrigin.Z + 1) * 24 do
          Dec(Result.Z);
        Dec(Result.Z, 4);
      end;
    end;
    LDirection := GetDirectionTo(LOrigin, AAction.Target);
    Inc(Result.X, DIRECTION_X_SHIFT[LDirection] * AAction.Actor.Armor.Size);
    Inc(Result.Y, DIRECTION_Y_SHIFT[LDirection] * AAction.Actor.Armor.Size);
  end
  else
  begin
    // from a waypoint: the height of the soldier and the terrain level do not count
    Inc(Result.X, 8);
    Inc(Result.Y, 8);
    Inc(Result.Z, 16);
  end;
end;

function TXcomTileEngine.ValidateThrow(const AAction: TXcomBattleAction; const AOrigin, ATarget: TXcomPosition;
  var ACurve: Double; var AVoxelType: Integer; AForced: Boolean): Boolean;
var
  LFoundCurve: Boolean;
  LCurvature: Double;
  LRatio: Double;
  LRoot: Double;
  LKneel: Double;
  LTargetTile: TXcomTile;
  LTargetPosition: TXcomPosition;
  LTrajectory: TList<TXcomPosition>;
  LTest: Integer;
  LHitPosition: TXcomPosition;
  LTilePosition: TXcomPosition;
  LHitTile: TXcomTile;
  LObject: TXcomMapData;
begin
  LFoundCurve := False;
  if AAction.Actor.IsKneeled then
    LKneel := 0.1
  else
    LKneel := 0.0;
  if AAction.ActionType = BA_THROW then
  begin
    if AAction.Weapon.Rules.Weight = 0 then
      LCurvature := 0.48
    else
    begin
      LRatio := Double(AAction.Actor.Stats.Strength) / Double(AAction.Weapon.Rules.Weight);
      LRoot := Sqrt(Sqrt(LRatio));
      if LRoot = 0 then
        Exit(False);
      LCurvature := 1.73 / LRoot + LKneel;
      LCurvature := Max(0.48, LCurvature);
    end;
  end
  else
  begin
    // arcing projectile weapons assume a fixed strength and weight (70 and 10)
    LRoot := Sqrt(Sqrt(70.0 / 10.0));
    LCurvature := 1.73 / LRoot + LKneel;
  end;
  LTargetTile := FSave.TileAt(AAction.Target);
  LTargetPosition := ATarget div TXcomPosition.Make(16, 16, 24);
  // object blocking: cannot throw here
  if (AAction.ActionType = BA_THROW) and Assigned(LTargetTile) and Assigned(LTargetTile.MapData[XCOM_PART_OBJECT]) then
  begin
    LObject := LTargetTile.MapData[XCOM_PART_OBJECT];
    if (LObject.GetTuCost(MT_WALK) = 255) and
      not (LTargetTile.IsBigWall and ((LObject.BigWall < 1) or (LObject.BigWall > 3))) then
      Exit(False);
  end;
  if not TXcomThrowRange.IsValid(AAction, AOrigin, LTargetTile) then
    Exit(False);
  LTrajectory := TList<TXcomPosition>.Create;
  try
    while (not LFoundCurve) and (LCurvature < 5.0) do
    begin
      LTrajectory.Clear;
      LTest := CalculateParabola(AOrigin, ATarget, True, LTrajectory, AAction.Actor, LCurvature,
        TXcomPosition.Make(0, 0, 0));
      // where the item hit and where it lands
      LHitPosition := (LTrajectory.Last + TXcomPosition.Make(0, 0, 1)) div TXcomPosition.Make(16, 16, 24);
      LTilePosition := TXcomTrajectory.PositionFromEnd(LTrajectory, ITEM_DROP_VOXEL_OFFSET) div
        TXcomPosition.Make(16, 16, 24);
      if AForced or ((LTest <> V_OUTOFBOUNDS) and (LTilePosition = LTargetPosition)) then
      begin
        AVoxelType := LTest;
        LFoundCurve := True;
      end
      else
      begin
        LCurvature := LCurvature + 0.5;
        // the obstacle indicator is for the player only
        if (LTest <> V_OUTOFBOUNDS) and (AAction.Actor.Faction = FACTION_PLAYER) then
        begin
          LHitTile := FSave.TileAt(LHitPosition);
          if Assigned(LHitTile) then
            LHitTile.SetObstacle(LTest);
        end;
      end;
    end;
  finally
    LTrajectory.Free;
  end;
  if LCurvature >= 5.0 then
    Exit(False);
  ACurve := LCurvature;
  Result := True;
end;

function TXcomTileEngine.ValidMeleeRange(const AAttacker, ATarget: TXcomBattleUnit; ADirection: Integer): Boolean;
var
  LDestination: TXcomPosition;
begin
  Result := ValidMeleeRange(AAttacker.Position, ADirection, AAttacker, ATarget, LDestination);
end;

function TXcomTileEngine.ValidMeleeRange(const APosition: TXcomPosition; ADirection: Integer;
  const AAttacker, ATarget: TXcomBattleUnit; out ADestination: TXcomPosition; APreferEnemy: Boolean): Boolean;
var
  LPotential: TList<TXcomBattleUnit>;
  LChosen: TXcomBattleUnit;
  LVector: TXcomPosition;
  LSize: Integer;
  LX: Integer;
  LY: Integer;
  LOrigin: TXcomTile;
  LTargetTile: TXcomTile;
  LAbove: TXcomTile;
  LBelow: TXcomTile;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LUnit: TXcomBattleUnit;
begin
  ADestination := TXcomPosition.Make(0, 0, 0);
  if (ADirection < 0) or (ADirection > 7) then
    Exit(False);
  LPotential := TList<TXcomBattleUnit>.Create;
  try
    LChosen := nil;
    LSize := AAttacker.Armor.Size - 1;
    LVector := TXcomDirections.ToVector(ADirection);
    for LX := 0 to LSize do
      for LY := 0 to LSize do
      begin
        LOrigin := FSave.TileAt(APosition + TXcomPosition.Make(LX, LY, 0));
        LTargetTile := FSave.TileAt(APosition + TXcomPosition.Make(LX, LY, 0) + LVector);
        LAbove := FSave.TileAt(APosition + TXcomPosition.Make(LX, LY, 1) + LVector);
        LBelow := FSave.TileAt(APosition + TXcomPosition.Make(LX, LY, -1) + LVector);
        if Assigned(LTargetTile) and Assigned(LOrigin) then
        begin
          if (LOrigin.GetTerrainLevel <= -16) and Assigned(LAbove) and (not LAbove.HasNoFloor(LTargetTile)) then
            LTargetTile := LAbove
          else if Assigned(LBelow) and LTargetTile.HasNoFloor(LBelow) and (not Assigned(LTargetTile.CurrentUnit)) and
            (LBelow.GetTerrainLevel <= -16) then
            LTargetTile := LBelow;
          if Assigned(LTargetTile.CurrentUnit) then
          begin
            if (not Assigned(ATarget)) or (LTargetTile.CurrentUnit = ATarget) then
            begin
              LOriginVoxel := LOrigin.Position * TXcomPosition.Make(16, 16, 24) +
                TXcomPosition.Make(8, 8, AAttacker.GetHeight + AAttacker.FloatHeight - 4 - LOrigin.GetTerrainLevel);
              if CanTargetUnit(LOriginVoxel, LTargetTile, LTargetVoxel, AAttacker, False) then
              begin
                ADestination := LTargetTile.Position;
                if Assigned(ATarget) then
                  Exit(True);
                LPotential.Add(LTargetTile.CurrentUnit);
              end;
            end;
          end;
        end;
      end;
    for LUnit in LPotential do
    begin
      // if there is actually something there, this is a success
      if not Assigned(LChosen) then
        LChosen := LUnit
      // but a target of a different faction is prioritized
      else if (APreferEnemy and (LUnit.Faction <> AAttacker.Faction)) or
        // or, with a medikit, whichever friend is wounded the most
        ((not APreferEnemy) and (LUnit.Faction = AAttacker.Faction) and
        (LUnit.GetFatalWounds > LChosen.GetFatalWounds)) then
        LChosen := LUnit;
    end;
    if Assigned(LChosen) then
      ADestination := LChosen.Position;
    Result := Assigned(LChosen);
  finally
    LPotential.Free;
  end;
end;

function TXcomTileEngine.Hit(const ACenter: TXcomPosition; APower, ADamageType: Integer;
  const AUnit: TXcomBattleUnit): TXcomBattleUnit;
var
  LTile: TXcomTile;
  LTileBelow: TXcomTile;
  LPart: Integer;
  LRandomPower: Integer;
  LDamageRange: Integer;
  LMin: Integer;
  LMax: Integer;
  LVerticalOffset: Integer;
  LUnitBelow: TXcomBattleUnit;
  LSize: Integer;
  LTarget: TXcomPosition;
  LRelative: TXcomPosition;
  LWounds: Integer;
  LAdjustedDamage: Integer;
  LBravery: Integer;
  LModifier: Integer;
  LMoraleLoss: Integer;
  LModuleX: Integer;
  LModuleY: Integer;
  LCenterTile: TXcomPosition;
begin
  LTile := FSave.TileAt(VoxelToTile(ACenter));
  if not Assigned(LTile) then
    Exit(nil);
  Result := LTile.CurrentUnit;
  VoxelCheckFlush;
  LPart := VoxelCheck(ACenter, AUnit);
  if (LPart >= V_FLOOR) and (LPart <= V_OBJECT) then
  begin
    // power 25% to 75%
    LRandomPower := FContext.Random.Generate(APower div 4, (APower * 3) div 4);
    if (LPart = V_OBJECT) and (LRandomPower >= LTile.MapData[XCOM_PART_OBJECT].Armor) and
      (FSave.MissionType = 'STR_BASE_DEFENSE') and LTile.MapData[XCOM_PART_OBJECT].IsBaseModule then
    begin
      LModuleX := (ACenter.X div 16) div 10;
      LModuleY := (ACenter.Y div 16) div 10;
      FSave.ModuleMap[LModuleX][LModuleY] := TPair<Integer, Integer>.Create(FSave.ModuleMap[LModuleX][LModuleY].Key,
        FSave.ModuleMap[LModuleX][LModuleY].Value - 1);
    end;
    if LTile.Damage(LPart, LRandomPower, FSave.ObjectiveType, FSave.ScorchedEarth) then
      FSave.AddDestroyedObjective;
  end
  else if LPart = V_UNIT then
  begin
    if ADamageType = TXcomRuleItem.DT_HE then
      LDamageRange := FContext.ExplosiveDamageRange
    else
      LDamageRange := FContext.DamageRange;
    LMin := APower * (100 - LDamageRange) div 100;
    LMax := APower * (100 + LDamageRange) div 100;
    LRandomPower := FContext.Random.Generate(LMin, LMax);
    LVerticalOffset := 0;
    if not Assigned(Result) then
    begin
      // a unit below the tile, standing on stairs with its head out to the next tile
      LTileBelow := FSave.TileAt(TXcomPosition.Make(ACenter.X div 16, ACenter.Y div 16, (ACenter.Z div 24) - 1));
      if Assigned(LTileBelow) then
      begin
        LUnitBelow := LTileBelow.CurrentUnit;
        if Assigned(LUnitBelow) then
        begin
          Result := LUnitBelow;
          LVerticalOffset := 24;
        end;
      end;
    end;
    if Assigned(Result) and (Result.Health <> 0) and (Result.StunLevel < Result.Health) then
    begin
      LSize := Result.Armor.Size * 8;
      LTarget := Result.Position * TXcomPosition.Make(16, 16, 24) +
        TXcomPosition.Make(LSize, LSize, Result.FloatHeight - LTile.GetTerrainLevel);
      LRelative := (ACenter - LTarget) - TXcomPosition.Make(0, 0, LVerticalOffset);
      LWounds := Result.GetFatalWounds;
      LAdjustedDamage := Result.Damage(LRelative, LRandomPower, ADamageType);
      // if it is going to bleed to death and it is not a player, give credit for the kill
      if Assigned(AUnit) and (Result.Faction <> FACTION_PLAYER) and (LWounds < Result.GetFatalWounds) then
        Result.KilledBy := AUnit.Faction;
      LBravery := (110 - Result.Stats.Bravery) div 10;
      if Result.Faction = FACTION_PLAYER then
        LModifier := FSave.GetMoraleModifier(nil)
      else
        LModifier := 100;
      LMoraleLoss := 100 * ((LAdjustedDamage * LBravery) div 10) div LModifier;
      Result.MoraleChange(-LMoraleLoss);
      if ((Result.SpecialAbility = SPECAB_EXPLODEONDEATH) or (Result.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) and
        (not Result.IsOut) and ((Result.Health = 0) or (Result.StunLevel >= Result.Health)) then
      begin
        if (ADamageType <> TXcomRuleItem.DT_STUN) and (ADamageType <> TXcomRuleItem.DT_HE) and
          (ADamageType <> TXcomRuleItem.DT_IN) and (ADamageType <> TXcomRuleItem.DT_MELEE) then
          FHost.StatePushNext(TXcomExplosionState.Create(FHost,
            TXcomPosition.Make(Result.Position.X * 16, Result.Position.Y * 16, Result.Position.Z * 24), nil, Result,
            nil));
      end;
      if (Result.OriginalFaction = FACTION_HOSTILE) and Assigned(AUnit) and
        (AUnit.OriginalFaction = FACTION_PLAYER) and (ADamageType <> TXcomRuleItem.DT_NONE) and
        (FHost.CurrentActionType <> BA_HIT) then
        AUnit.AddFiringExp;
    end;
  end;
  ApplyGravityTile(LTile);
  CalculateSunShading; // roofs could have been destroyed
  CalculateTerrainLighting; // fires could have been started
  LCenterTile := ACenter div TXcomPosition.Make(16, 16, 24);
  CalculateFovAt(LCenterTile);
end;

end.
