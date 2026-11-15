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
  DelphiDoom.War.Map.Game, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Camera;

type
  /// <summary>
  ///   What a click on the map does while one of the cheats of editing is on (map->editing): "Add unit" puts the unit on the
  ///   tile for the first player of its race, "Rain of fire" and "Poison cloud" cast the spell on the tile and "Raise dead"
  ///   turns the corpses near it into skeletons of the player (all without mana). The modes that change the ground
  ///   (trees, walls, roads and ruins of "Edit") are not ported: they are set and shown, and the click does nothing
  /// </summary>
  TWarMapEditing = class
  strict private
    FWorld: TWarModelWorld;
    FMap: TWarGameMap;
    FCamera: TWarMapCamera;
    FMode: TWarMapEditMode;
    FUnitType: Integer;
    procedure AddUnit(AX, AY: Integer);
    procedure RainOfFire(const ATile: TWarVec2);
    procedure PoisonCloud(const ATile: TWarVec2);
    procedure RaiseDead(const ATile: TWarVec2);
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const AWorld: TWarModelWorld; const AMap: TWarGameMap; const ACamera: TWarMapCamera);
    /// <summary>map->editing.mode and, for "Add unit", pendingUnitType (kept for the next time if the mode is another)</summary>
    procedure SetMode(AMode: TWarMapEditMode; AUnitType: Integer);
    /// <summary>The click of this frame, if any, in the mode that is on: only a left click on the map panel counts</summary>
    procedure Update(const AInput: IWarUiInput);
    property Mode: TWarMapEditMode read FMode;
    property UnitType: Integer read FUnitType;
  end;

implementation

uses
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Spells,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.EntityPool;

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

procedure TWarMapEditing.Update(const AInput: IWarUiInput);
var
  LMapX: Single;
  LMapY: Single;
  LTile: TWarVec2;
begin
  if FMode in [wemNone, wemTrees, wemWalls, wemRoads, wemRuins] then
    Exit;
  if (not AInput.IsButtonJustPressed(wmbLeft)) or
    (not WarRectContains(FCamera.Panels.MapPanel, AInput.PositionX, AInput.PositionY)) then
    Exit;
  FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, LMapX, LMapY);
  TWarMapCamera.MapToTile(LMapX, LMapY, LTile.X, LTile.Y);
  case FMode of
    wemAddUnit: AddUnit(Trunc(LTile.X), Trunc(LTile.Y));
    wemRainOfFire: RainOfFire(LTile);
    wemPoisonCloud: PoisonCloud(LTile);
    wemRaiseDead: RaiseDead(LTile);
  end;
end;

end.
