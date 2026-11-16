{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the units of the player see                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c, updateFoW and determineFoWTypes,    }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-     }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.FogRevealer;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Fog, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Intf;

type
  /// <summary>
  ///   updateFoW and determineFoWTypes of the units of the model, over the fog of the map (TWarFogOfWar): every tile in
  ///   sight goes to fog, then the sight spells (Holy Sight and Dark Vision) light a square of 7 tiles, every unit of the
  ///   player 0 lights its tiles and its sight range (without the four corners, with the quirks of wmap_setMapTileState),
  ///   the target of a unit that attacks is revealed if it is in range (a unit, or the piece of a wall) and so is whoever
  ///   attacks it, the buildings of the player are seen for good, the units of the others that are not partly in sight
  ///   leave the selection and their buildings that are in sight are seen for good; last, the piece of fog and the
  ///   boundary of every tile (what the drawing needs, as data). The sight range of a type is read from the tables once.
  ///   Defect of the original kept: the piece of a wall that is attacked is lit as a rectangle of one tile, and
  ///   wmap_setMapTileState leaves out the corners of a rectangle, which here are all of it: it changes nothing
  /// </summary>
  TWarFogRevealer = class(TInterfacedObject, IWarFogUpdater)
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FFog: TWarFogOfWar;
    FSight: array[0..WAR_UNIT_COUNT - 1] of Integer;
    function SightOf(AEntity: PWarEntity): Integer;
    procedure RevealUnit(ASlot: Integer);
    procedure RevealTarget(ASlot: Integer);
    procedure RevealSights;
  public
    /// <summary>The fog is the one of the map (not owned: it must outlive the revealer)</summary>
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine; const AFog: TWarFogOfWar);
    procedure Update;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.TargetGeometry,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Stats.Types;

const
  // the Holy Sight and Dark Vision spells light a square of this many tiles around the tile that is seen (rect_expand by 3)
  SIGHT_SPELL_REACH = 3;
  NOT_READ = -1;

{ TWarFogRevealer }

constructor TWarFogRevealer.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const AFog: TWarFogOfWar);
var
  LIndex: Integer;
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FFog := AFog;
  for LIndex := 0 to WAR_UNIT_COUNT - 1 do
    FSight[LIndex] := NOT_READ;
end;

// wu_getUnitSightRange
function TWarFogRevealer.SightOf(AEntity: PWarEntity): Integer;
var
  LType: Integer;
begin
  LType := AEntity^.UnitData.UnitType;
  if FSight[LType] = NOT_READ then
    if TWarUnitClassifier.IsBuilding(LType) then
      FSight[LType] := FContext.Database.GetBuildingStats(LType).Sight
    else
      FSight[LType] := FContext.Database.GetUnitStats(LType).Sight;
  Result := FSight[LType];
end;

// wmap_setUnitMapTileState with the state visible, and the lighting of a unit of the player: its tiles and its sight range
procedure TWarFogRevealer.RevealUnit(ASlot: Integer);
var
  LEntity: PWarEntity;
  LSight: Integer;
  LTile: TWarVec2;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LSight := SightOf(LEntity);
  LTile := TWarUnitGeometry.Tile(LEntity);
  FFog.SetState(Trunc(LTile.X) - LSight, Trunc(LTile.Y) - LSight, LEntity^.UnitData.SizeX + 2 * LSight,
    LEntity^.UnitData.SizeY + 2 * LSight, wtsVisible);
end;

// the target of the unit that attacks: a unit that is in range is seen; a piece of wall that is in range too
procedure TWarFogRevealer.RevealTarget(ASlot: Integer);
var
  LEntity: PWarEntity;
  LAttack: PWarStateAttack;
  LTargetSlot: Integer;
  LStats: TWarUnitStatsFull;
  LTile: TWarVec2;
  LTileX: Integer;
  LTileY: Integer;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LAttack := PWarStateAttack(FMachine.FindState(ASlot, WAR_STATE_ATTACK));
  if not Assigned(LAttack) then
    Exit;
  LTargetSlot := FContext.Pool.FindSlot(LAttack^.TargetEntityId);
  if LTargetSlot = 0 then
    Exit;
  // a unit type without unit statistics (a building that attacks) has no range: the original stops on an assert
  LStats := FContext.Database.GetUnitStats(LEntity^.UnitData.UnitType);
  if FContext.Pool.Slots[LTargetSlot]^.EntityType = WAR_ENTITY_UNIT then
  begin
    if TWarTargetGeometry.UnitInRange(LEntity, FContext.Pool.Slots[LTargetSlot], LStats.Range) then
      RevealUnit(LTargetSlot);
  end
  else if FContext.Pool.Slots[LTargetSlot]^.EntityType = WAR_ENTITY_WALL then
  begin
    LTile := TWarModelMath.MapToTile(LAttack^.TargetPosition);
    if TWarUnitGeometry.TileInRange(LEntity, LTile, LStats.Range) then
    begin
      LTileX := Trunc(LTile.X);
      LTileY := Trunc(LTile.Y);
      if FContext.Walls.IndexAt(LTileX, LTileY) >= 0 then
        FFog.SetState(LTileX, LTileY, 1, 1, wtsVisible);
    end;
  end;
end;

procedure TWarFogRevealer.RevealSights;
var
  LSights: TList<Integer>;
  LIndex: Integer;
  LTile: TWarVec2;
  LStartX: Single;
  LStartY: Single;
begin
  LSights := FContext.Pool.OfType[WAR_ENTITY_SIGHT];
  for LIndex := 0 to LSights.Count - 1 do
  begin
    LTile := FContext.Pool.Slots[LSights[LIndex]]^.SpellTile;
    LStartX := LTile.X - SIGHT_SPELL_REACH;
    LStartY := LTile.Y - SIGHT_SPELL_REACH;
    // the rectangle of one tile expanded by 3 on each side is 7 tiles wide
    FFog.SetState(Trunc(LStartX), Trunc(LStartY), 1 + 2 * SIGHT_SPELL_REACH, 1 + 2 * SIGHT_SPELL_REACH, wtsVisible);
  end;
end;

procedure TWarFogRevealer.Update;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LAttacker: Integer;
  LFriendly: Integer;
  LTile: TWarVec2;
begin
  FFog.BeginUpdate;
  // the Holy Sight and Dark Vision spells are the first that change the fog
  RevealSights;
  LFriendly := FContext.Players[0]^.Index;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  // the units of the player first
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LSlot := LUnits[LIndex];
    LEntity := FContext.Pool.Slots[LSlot];
    if not (LEntity^.HasUnit and (LEntity^.UnitData.Player = LFriendly)) then
      Continue;
    // the buildings of the player are always seen
    if TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType) then
      LEntity^.UnitData.HasBeenSeen := True;
    RevealUnit(LSlot);
    RevealTarget(LSlot);
    // whoever attacks the unit is revealed
    LAttacker := FContext.Queries.Attacker(LSlot);
    if LAttacker <> 0 then
      RevealUnit(LAttacker);
  end;
  // and then the units of the enemies and of the neutrals
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LSlot := LUnits[LIndex];
    LEntity := FContext.Pool.Slots[LSlot];
    if LEntity^.HasUnit and (LEntity^.UnitData.Player = LFriendly) then
      Continue;
    LTile := TWarUnitGeometry.Tile(LEntity);
    if not FFog.IsAnyTileInState(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX, LEntity^.UnitData.SizeY,
      wtsVisible) then
      // a unit of the others that goes into the fog is not selected any more
      FContext.Selection.Remove(LEntity^.Id)
    else if TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType) then
      LEntity^.UnitData.HasBeenSeen := True;
  end;
  FFog.DetermineTypes;
end;

end.
