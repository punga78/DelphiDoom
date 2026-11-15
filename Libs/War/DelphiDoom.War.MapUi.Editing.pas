{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the clicks of the cheats of editing                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (updateAddUnit, updateRainOfFireEdit,  }
{  updatePoisonCloudEdit, updateRaiseDeadEdit and the castDebug* they call),     }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                         }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Editing;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.World,
  DelphiDoom.War.Map.Game, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera,
  DelphiDoom.War.MapUi.DebugNearUnits;

type
  /// <summary>
  ///   What a click on the map does while one of the cheats of editing is on (map->editing): "Add unit" puts the unit on the
  ///   tile for the first player of its race, "Rain of fire" and "Poison cloud" cast the spell on the tile and "Raise dead"
  ///   turns the corpses near it into skeletons of the player (all without mana). The modes that change the ground (trees,
  ///   walls, roads and ruins of "Edit": updateTreesEdit, updateWallsEdit, updateRoadsEdit, updateRuinsEdit) plant or fell a
  ///   tree and add or remove a piece of the wall, the road or the ruins on the tile that is clicked
  /// </summary>
  TWarMapEditing = class
  strict private
    FWorld: TWarModelWorld;
    FMap: TWarGameMap;
    FCamera: TWarMapCamera;
    FMode: TWarMapEditMode;
    FUnitType: Integer;
    FNearUnits: TWarDebugNearUnits;
    procedure AddUnit(AX, AY: Integer);
    procedure RainOfFire(const ATile: TWarVec2);
    procedure PoisonCloud(const ATile: TWarVec2);
    procedure RaiseDead(const ATile: TWarVec2);
    procedure EditTree(AX, AY: Integer);
    procedure EditWall(AX, AY: Integer);
    procedure EditRoad(AX, AY: Integer);
    procedure EditRuin(AX, AY: Integer);
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const AWorld: TWarModelWorld; const AMap: TWarGameMap; const ACamera: TWarMapCamera);
    /// <summary>map->editing.mode and, for "Add unit", pendingUnitType (kept for the next time if the mode is another)</summary>
    procedure SetMode(AMode: TWarMapEditMode; AUnitType: Integer);
    /// <summary>The click of this frame, if any, in the mode that is on: only a left click on the map panel counts</summary>
    procedure Update(const AInput: IWarUiInput);
    property Mode: TWarMapEditMode read FMode;
    property UnitType: Integer read FUnitType;
    /// <summary>
    ///   Where the spells of editing show the box of their radius (castDebugRainOfFire, castDebugPoisonCloud,
    ///   castDebugRaiseDead: setNearUnitsDebugParams); nil: nowhere. Not owned
    /// </summary>
    property NearUnits: TWarDebugNearUnits read FNearUnits write FNearUnits;
  end;

implementation

uses
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Spells,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.EntityPool, DelphiDoom.War.Map.Forest, DelphiDoom.War.Autotile.Types, DelphiDoom.War.Model.Walls,
  DelphiDoom.War.Model.Construction.Types, DelphiDoom.War.Map.Types;

{ TWarMapEditing }

constructor TWarMapEditing.Create(const AWorld: TWarModelWorld; const AMap: TWarGameMap; const ACamera: TWarMapCamera);
begin
  inherited Create;
  FWorld := AWorld;
  FMap := AMap;
  FCamera := ACamera;
  FMode := wemNone;
end;

procedure TWarMapEditing.SetMode(AMode: TWarMapEditMode; AUnitType: Integer);
begin
  FMode := AMode;
  if AMode = wemAddUnit then
    FUnitType := AUnitType;
end;

procedure TWarMapEditing.AddUnit(AX, AY: Integer);
var
  LRace: TWarRace;
  LIndex: Integer;
  LSlot: Integer;
begin
  if FMap.Grid.GetTileEntityId(AX, AY) <> 0 then
    Exit;
  LRace := TWarUnitClassifier.RaceOf(FUnitType);
  for LIndex := 0 to FWorld.Context.PlayersCount - 1 do
    if FWorld.Context.Players[LIndex]^.Race = LRace then
    begin
      LSlot := FWorld.Entities.CreateUnit(FUnitType, AX, AY, FWorld.Context.Players[LIndex]^.Index, wrkNone, 0, True);
      if LSlot <> 0 then
        FWorld.Entities.SetInitialIdle(LSlot);
      Break;
    end;
end;

procedure TWarMapEditing.RainOfFire(const ATile: TWarVec2);
begin
  // NEAR_RAIN_OF_FIRE_RADIUS of war.h is 1
  if Assigned(FNearUnits) then
    FNearUnits.SetParams(ATile, 1);
  TWarSpells.RainOfFire(FWorld.Context, TWarModelMath.TileToMap(ATile, True));
end;

procedure TWarMapEditing.PoisonCloud(const ATile: TWarVec2);
var
  LPosition: TWarVec2;
begin
  LPosition := TWarModelMath.TileToMap(ATile, True);
  TWarSpells.SpawnPoisonCloud(FWorld.Context, ATile, FWorld.Context.SpellStats(WAR_SPELL_POISON_CLOUD).Time);
  if Assigned(FWorld.Context.SpellEvents) then
    FWorld.Context.SpellEvents.SpellCast(LPosition);
  // the radius of the damage of the cloud
  if Assigned(FNearUnits) then
    FNearUnits.SetParams(ATile, 2);
end;

procedure TWarMapEditing.RaiseDead(const ATile: TWarVec2);
var
  LNear: TList<Integer>;
  LIndex: Integer;
  LCorpse: PWarEntity;
  LTile: TWarVec2;
  LPosition: TWarVec2;
  LSkeleton: Integer;
begin
  if Assigned(FNearUnits) then
    FNearUnits.SetParams(ATile, 4);
  LNear := TList<Integer>.Create;
  try
    FWorld.Context.Combat.CollectNearUnits(ATile, 4, LNear);
    for LIndex := 0 to LNear.Count - 1 do
    begin
      LCorpse := FWorld.Context.Pool.Slots[LNear[LIndex]];
      if not TWarUnitClassifier.IsCorpse(LCorpse^.UnitData.UnitType) then
        Continue;
      LTile := TWarUnitGeometry.CenterTile(LCorpse);
      LPosition := TWarUnitGeometry.CenterPosition(LCorpse);
      LSkeleton := FWorld.Entities.CreateUnit(WAR_UNIT_SKELETON, Trunc(LTile.X), Trunc(LTile.Y), 0, wrkNone, 0, True);
      if LSkeleton = 0 then
        Continue;
      FWorld.Entities.SetInitialIdle(LSkeleton);
      TWarAnimations.SpawnSpellEffect(FWorld.Context, LPosition);
      if Assigned(FWorld.Context.SpellEvents) then
        FWorld.Context.SpellEvents.SpellCast(LPosition);
      FWorld.Entities.RemoveEntityById(LCorpse^.Id);
    end;
  finally
    LNear.Free;
  end;
end;

procedure TWarMapEditing.EditTree(AX, AY: Integer);
var
  LId: Word;
  LForest: TWarMapForest;
  LTree: TWarTree;
begin
  // updateTreesEdit: a tile with no entity gets a tree of the editing forest; a tree of a forest is chopped down (all its wood);
  // whatever else stands there (a unit, a building) is left alone. The tiles of the trees are decided again in both cases
  LId := FMap.Grid.GetTileEntityId(AX, AY);
  if LId = 0 then
  begin
    FMap.Forests.PlantTree(FMap.Forests.EditingForest, AX, AY);
    FMap.Forests.DetermineAllTiles;
  end
  else
  begin
    LForest := FMap.Forests.FindForest(LId);
    if Assigned(LForest) and LForest.TryGetTreeAt(AX, AY, LTree) then
    begin
      FMap.Forests.ChopTree(LForest, AX, AY, WAR_TREE_MAX_WOOD);
      FMap.Forests.DetermineAllTiles;
    end;
  end;
end;

procedure TWarMapEditing.EditWall(AX, AY: Integer);
var
  LWalls: TWarWalls;
  LIndex: Integer;
begin
  // updateWallsEdit: a new piece with all its hit points, or the piece that is there goes (and its tile is free)
  LWalls := FWorld.Context.Walls;
  LIndex := LWalls.IndexAt(AX, AY);
  if LIndex < 0 then
  begin
    LIndex := LWalls.Add(AX, AY, 0);
    LWalls[LIndex]^.Hp := WAR_WALL_MAX_HP;
    LWalls[LIndex]^.MaxHp := WAR_WALL_MAX_HP;
  end
  else
  begin
    FMap.Grid.SetFreeTiles(AX, AY, 1, 1);
    LWalls.Remove(LIndex);
  end;
  LWalls.DetermineTypes;
end;

procedure TWarMapEditing.EditRoad(AX, AY: Integer);
var
  LPiece: TWarLinePiece;
begin
  // updateRoadsEdit
  if FWorld.Context.Roads.TryGetPieceAt(AX, AY, LPiece) then
    FWorld.Context.Roads.RemovePiece(LPiece)
  else
    FWorld.Context.Roads.AddPiece(AX, AY, 0);
  FWorld.Context.Roads.DetermineTypes;
end;

procedure TWarMapEditing.EditRuin(AX, AY: Integer);
var
  LPiece: TWarRuinPiece;
begin
  // updateRuinsEdit: a square of two by two pieces, or the piece that is there goes
  if FWorld.Context.Ruins.TryGetPieceAt(AX, AY, LPiece) then
    FWorld.Context.Ruins.RemovePiece(LPiece)
  else
    FWorld.Context.Ruins.AddSquare(AX, AY, 2);
  FWorld.Context.Ruins.DetermineTypes;
end;

procedure TWarMapEditing.Update(const AInput: IWarUiInput);
var
  LMapX: Single;
  LMapY: Single;
  LTile: TWarVec2;
begin
  if FMode = wemNone then
    Exit;
  if (not AInput.IsButtonJustPressed(wmbLeft)) or
    (not WarRectContains(FCamera.Panels.MapPanel, AInput.PositionX, AInput.PositionY)) then
    Exit;
  FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, LMapX, LMapY);
  TWarMapCamera.MapToTile(LMapX, LMapY, LTile.X, LTile.Y);
  case FMode of
    wemTrees: EditTree(Trunc(LTile.X), Trunc(LTile.Y));
    wemWalls: EditWall(Trunc(LTile.X), Trunc(LTile.Y));
    wemRoads: EditRoad(Trunc(LTile.X), Trunc(LTile.Y));
    wemRuins: EditRuin(Trunc(LTile.X), Trunc(LTile.Y));
    wemAddUnit: AddUnit(Trunc(LTile.X), Trunc(LTile.Y));
    wemRainOfFire: RainOfFire(LTile);
    wemPoisonCloud: PoisonCloud(LTile);
    wemRaiseDead: RaiseDead(LTile);
  end;
end;

end.
