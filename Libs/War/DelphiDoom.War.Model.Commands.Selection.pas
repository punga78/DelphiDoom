{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the rules of the selection                        }
{                                                                              }
{  Port of war1 (acoto87/war1), isEntitySelectable, updateSelectionFromList    }
{  and updateSelectionGroups of war_map.c, (c) 2019 Alejandro Coto Gutierrez,  }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version,   }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Selection;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Selection, DelphiDoom.War.Model.Commands.Intf;

type
  /// <summary>
  ///   Who can be selected and what a new selection becomes: no dead, dying or collapsing unit, no corpse, no worker
  ///   inside a building, nothing that the player does not see; with dudes among the candidates the buildings are left
  ///   out, with buildings only the first one stays; at most 32. What the mouse does (the rectangle, the click) and the
  ///   sounds of the selection are not here: the candidates are given as slots, in the order in which the original
  ///   finds them
  /// </summary>
  TWarSelectionCommands = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FSelection: TWarSelection;
    FMap: IWarCommandMap;
  public
    /// <summary>The map tells what the player sees; nil means everything</summary>
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const ASelection: TWarSelection; const AMap: IWarCommandMap);
    /// <summary>isEntitySelectable</summary>
    function IsSelectable(ASlot: Integer): Boolean;
    /// <summary>updateSelectionFromList: the selection becomes what is left of the candidates. How many are selected</summary>
    function Select(const ASlots: array of Integer): Integer;
    /// <summary>CTRL + digit of updateSelectionGroups: the group remembers the selection</summary>
    procedure StoreGroup(AGroup: Integer);
    /// <summary>
    ///   Digit of updateSelectionGroups: the members of the group that still can be selected become the selection. An
    ///   empty group changes nothing. How many are selected
    /// </summary>
    function RecallGroup(AGroup: Integer): Integer;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry;

{ TWarSelectionCommands }

constructor TWarSelectionCommands.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const ASelection: TWarSelection; const AMap: IWarCommandMap);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FSelection := ASelection;
  FMap := AMap;
end;

function TWarSelectionCommands.IsSelectable(ASlot: Integer): Boolean;
var
  LEntity: PWarEntity;
  LTile: TWarVec2;
begin
  if ASlot <= 0 then
    Exit(False);
  LEntity := FContext.Pool.Slots[ASlot];
  if (LEntity^.Id = 0) or not LEntity^.HasUnit then
    Exit(False);
  if FMachine.IsDead(ASlot) or FMachine.IsGoingToDie(ASlot) or
    TWarUnitClassifier.IsCorpse(LEntity^.UnitData.UnitType) or FMachine.IsCollapsing(ASlot) or
    FMachine.IsGoingToCollapse(ASlot) then
    Exit(False);
  if TWarUnitClassifier.IsWorker(LEntity^.UnitData.UnitType) and FMachine.IsInsideBuilding(ASlot) then
    Exit(False);
  Result := True;
  if Assigned(FMap) then
  begin
    LTile := TWarUnitGeometry.Tile(LEntity);
    Result := FMap.IsAreaPartiallyVisible(Trunc(LTile.X), Trunc(LTile.Y), LEntity^.UnitData.SizeX,
      LEntity^.UnitData.SizeY);
  end;
end;

function TWarSelectionCommands.Select(const ASlots: array of Integer): Integer;
var
  LList: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LDudes: Boolean;
  LBuildings: Boolean;
  LType: Integer;
begin
  LList := TList<Integer>.Create;
  try
    // no entity twice (the first stays), and only those that can be selected
    for LIndex := 0 to High(ASlots) do
    begin
      LSlot := ASlots[LIndex];
      if (LList.IndexOf(LSlot) < 0) and IsSelectable(LSlot) then
        LList.Add(LSlot);
    end;
    LDudes := False;
    LBuildings := False;
    for LIndex := 0 to LList.Count - 1 do
    begin
      LType := FContext.Pool.Slots[LList[LIndex]]^.UnitData.UnitType;
      if TWarUnitClassifier.IsDude(LType) then
        LDudes := True
      else if TWarUnitClassifier.IsBuilding(LType) then
        LBuildings := True;
    end;
    if LDudes then
    begin
      for LIndex := LList.Count - 1 downto 0 do
        if TWarUnitClassifier.IsBuilding(FContext.Pool.Slots[LList[LIndex]]^.UnitData.UnitType) then
          LList.Delete(LIndex);
    end
    else if LBuildings and (LList.Count > 1) then
      LList.DeleteRange(1, LList.Count - 1);
    FSelection.Clear;
    for LIndex := 0 to LList.Count - 1 do
      if LIndex < WAR_MODEL_MAX_SELECTED then
        FSelection.Add(FContext.Pool.Slots[LList[LIndex]]^.Id);
    Result := FSelection.Count;
  finally
    LList.Free;
  end;
end;

procedure TWarSelectionCommands.StoreGroup(AGroup: Integer);
begin
  FSelection.StoreGroup(AGroup);
end;

function TWarSelectionCommands.RecallGroup(AGroup: Integer): Integer;
var
  LSlots: TArray<Integer>;
  LCount: Integer;
  LIndex: Integer;
  LSlot: Integer;
begin
  if FSelection.GroupCount(AGroup) = 0 then
    Exit(FSelection.Count);
  SetLength(LSlots, FSelection.GroupCount(AGroup));
  LCount := 0;
  for LIndex := 0 to FSelection.GroupCount(AGroup) - 1 do
  begin
    LSlot := FContext.Pool.FindSlot(FSelection.GroupItem(AGroup, LIndex));
    if IsSelectable(LSlot) then
    begin
      LSlots[LCount] := LSlot;
      Inc(LCount);
    end;
  end;
  SetLength(LSlots, LCount);
  Result := Select(LSlots);
end;

end.
