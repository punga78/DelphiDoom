{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the mouse and the keys select on the map     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (updateDragRect, updateSelection,     }
{  updateSelectionFromList, updateSelectionGroups), (c) 2019 Alejandro Coto     }
{  Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Selecting;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Render.Types, DelphiDoom.War.Map.Game,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Commands.Selection,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Intf, DelphiDoom.War.MapUi.Camera,
  DelphiDoom.War.MapUi.Picker, DelphiDoom.War.MapUi.CommandState;

type
  /// <summary>
  ///   The rectangle that the mouse drags on the map and the selection that follows: a click selects what is under the
  ///   mouse (units and buildings, not trees or walls), a rectangle selects the units that touch it (in the order of the
  ///   list of the pool), Control keeps what was selected, Control and a digit remember a group and a digit recalls it.
  ///   The rules of who can be selected are the model's (TWarSelectionCommands); here are the mouse, the keys and the
  ///   sounds of the selection
  /// </summary>
  TWarMapSelecting = class
  strict private
    FMap: TWarGameMap;
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FCamera: TWarMapCamera;
    FPicker: TWarMapPicker;
    FSelecting: TWarSelectionCommands;
    FAudio: IWarMapAudio;
    FStatus: TWarDragStatus;
    FStartX: Single;
    FStartY: Single;
    FRect: TWarRectF;
    FSuppressOnRelease: Boolean;
    FCommandState: TWarMapCommandState;
    procedure SelectFromList(const ACandidates: TList<Integer>);
    function TakeSuppress: Boolean;
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(const AMap: TWarGameMap; const AContext: TWarModelContext; const AMachine: TWarStateMachine;
      const ACamera: TWarMapCamera; const APicker: TWarMapPicker; const ASelecting: TWarSelectionCommands;
      const AAudio: IWarMapAudio);
    /// <summary>updateDragRect</summary>
    procedure UpdateDragRect(const AInput: IWarUiInput);
    /// <summary>
    ///   What wmap_updateMap does while the map does not play (a menu is open): the drag is forgotten, with no start and an
    ///   empty rectangle
    /// </summary>
    procedure ResetDrag;
    /// <summary>updateSelection</summary>
    procedure UpdateSelection(const AInput: IWarUiInput);
    /// <summary>updateSelectionGroups (not while the cheat panel is open)</summary>
    procedure UpdateGroups(const AInput: IWarUiInput; ACheatsOpen: Boolean = False);
    /// <summary>isMapDragging</summary>
    function IsDragging: Boolean;
    /// <summary>A rectangle that is not worth a drag: the click that gave an order must not select on release</summary>
    property SuppressOnRelease: Boolean read FSuppressOnRelease write FSuppressOnRelease;
    /// <summary>
    ///   The command that waits for a target, if the map has one: a new selection (not the same single entity) clears it and
    ///   the click that gave an order does not select on release. Not owned; without it the selection works as before
    /// </summary>
    property CommandState: TWarMapCommandState read FCommandState write FCommandState;
    property DragRect: TWarRectF read FRect;
    property DragStatus: TWarDragStatus read FStatus;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Ui.Types, DelphiDoom.War.Sound.Ids;

{ TWarMapSelecting }

constructor TWarMapSelecting.Create(const AMap: TWarGameMap; const AContext: TWarModelContext;
  const AMachine: TWarStateMachine; const ACamera: TWarMapCamera; const APicker: TWarMapPicker;
  const ASelecting: TWarSelectionCommands; const AAudio: IWarMapAudio);
begin
  inherited Create;
  FMap := AMap;
  FContext := AContext;
  FMachine := AMachine;
  FCamera := ACamera;
  FPicker := APicker;
  FSelecting := ASelecting;
  FAudio := AAudio;
end;

function TWarMapSelecting.IsDragging: Boolean;
begin
  Result := FStatus <> wdsNone;
end;

procedure TWarMapSelecting.ResetDrag;
begin
  FStatus := wdsNone;
  FStartX := 0;
  FStartY := 0;
  FRect := Default(TWarRectF);
end;

procedure TWarMapSelecting.UpdateDragRect(const AInput: IWarUiInput);
begin
  if FCamera.IsScrolling then
  begin
    FStatus := wdsNone;
    FStartX := 0;
    FStartY := 0;
    FRect := Default(TWarRectF);
    Exit;
  end;
  case FStatus of
    wdsStarted, wdsActive:
      begin
        if AInput.IsButtonHeld(wmbLeft) then
          FStatus := wdsActive
        else if AInput.IsButtonJustReleased(wmbLeft) then
          FStatus := wdsReleased;
        // rectpf: the corner of the start and the corner of the mouse
        FRect.X := Min(FStartX, AInput.PositionX);
        FRect.Y := Min(FStartY, AInput.PositionY);
        FRect.Width := Abs(FStartX - AInput.PositionX);
        FRect.Height := Abs(FStartY - AInput.PositionY);
      end;
    wdsReleased:
      begin
        FStatus := wdsNone;
        FStartX := 0;
        FStartY := 0;
        FRect := Default(TWarRectF);
      end;
  else
    // no button of the interface is captured (the buttons are of the immediate interface): a press on the map starts it
    if AInput.IsButtonJustPressed(wmbLeft) and
      WarRectContains(FCamera.Panels.MapPanel, AInput.PositionX, AInput.PositionY) then
    begin
      FStatus := wdsStarted;
      FStartX := AInput.PositionX;
      FStartY := AInput.PositionY;
      FRect.X := AInput.PositionX;
      FRect.Y := AInput.PositionY;
      FRect.Width := 0;
      FRect.Height := 0;
    end;
  end;
end;

procedure TWarMapSelecting.SelectFromList(const ACandidates: TList<Integer>);
var
  LIndex: Integer;
  LIndex2: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LDudes: Boolean;
  LBuildings: Boolean;
begin
  // updateSelectionFromList: repeated candidates go, then who can not be selected, then the buildings if there are units
  for LIndex := ACandidates.Count - 1 downto 0 do
    for LIndex2 := 0 to LIndex - 1 do
      if ACandidates[LIndex2] = ACandidates[LIndex] then
      begin
        ACandidates.Delete(LIndex);
        Break;
      end;
  for LIndex := ACandidates.Count - 1 downto 0 do
    if not FSelecting.IsSelectable(ACandidates[LIndex]) then
      ACandidates.Delete(LIndex);
  LDudes := False;
  LBuildings := False;
  for LIndex := 0 to ACandidates.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[ACandidates[LIndex]];
    if TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) then
      LDudes := True
    else if TWarUnitClassifier.IsBuilding(LEntity^.UnitData.UnitType) then
      LBuildings := True;
  end;
  if LDudes then
  begin
    for LIndex := ACandidates.Count - 1 downto 0 do
      if TWarUnitClassifier.IsBuilding(FContext.Pool.Slots[ACandidates[LIndex]]^.UnitData.UnitType) then
        ACandidates.Delete(LIndex);
  end
  else if LBuildings then
    while ACandidates.Count > 1 do
      ACandidates.Delete(ACandidates.Count - 1);
  // the sounds: one unit is heard (or a click if it is not ours), several are not; a building of ours is heard
  if Assigned(FAudio) then
  begin
    if LDudes then
    begin
      if ACandidates.Count = 1 then
      begin
        LSlot := ACandidates[0];
        if FContext.Pool.Slots[LSlot]^.UnitData.Player = 0 then
          FAudio.DudeSelected(LSlot)
        else
          FAudio.PlaySound(WAR_SND_UI_CLICK);
      end;
    end
    else if LBuildings then
    begin
      LSlot := ACandidates[0];
      if FContext.Pool.Slots[LSlot]^.UnitData.Player = 0 then
        FAudio.BuildingSelected(LSlot);
    end;
  end;
  // if the new selected entity is the same one the command stays, otherwise it is cleared
  if Assigned(FCommandState) then
  begin
    if (ACandidates.Count = 1) and (FContext.Selection.Count = 1) then
    begin
      if FContext.Selection[0] <> FContext.Pool.Slots[ACandidates[0]]^.Id then
        FCommandState.Clear;
    end
    else
      FCommandState.Clear;
  end;
  FSelecting.Select(ACandidates.ToArray);
end;

function TWarMapSelecting.TakeSuppress: Boolean;
begin
  // suppressSelectionOnRelease: asked once, then forgotten
  if Assigned(FCommandState) then
  begin
    Result := FCommandState.SuppressSelectionOnRelease;
    FCommandState.SuppressSelectionOnRelease := False;
  end
  else
  begin
    Result := FSuppressOnRelease;
    FSuppressOnRelease := False;
  end;
end;

procedure TWarMapSelecting.UpdateSelection(const AInput: IWarUiInput);
var
  LCandidates: TList<Integer>;
  LPointer: TWarRectF;
  LUnits: TArray<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LUnit: TWarRectF;
  LKind: Integer;
  LMapX: Single;
  LMapY: Single;
  LRight: Single;
  LBottom: Single;
begin
  // while it scrolled last frame, or the mouse still drags, nothing is selected: it is done when the mouse is released
  if FCamera.WasScrolling or (FStatus <> wdsReleased) then
    Exit;
  if TakeSuppress then
    Exit;
  LCandidates := TList<Integer>.Create;
  try
    if (FRect.Width >= WAR_MAPUI_DRAG_THRESHOLD) or (FRect.Height >= WAR_MAPUI_DRAG_THRESHOLD) then
    begin
      // wmap_screenToMapCoordinatesR: the rectangle moved to the coordinates of the map
      LPointer := FRect;
      LPointer.X := LPointer.X + (-FCamera.Panels.MapPanel.X);
      LPointer.Y := LPointer.Y + (-FCamera.Panels.MapPanel.Y);
      LPointer.X := LPointer.X + FCamera.X;
      LPointer.Y := LPointer.Y + FCamera.Y;
      LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
      for LIndex := 0 to High(LUnits) do
      begin
        LSlot := LUnits[LIndex];
        if not FSelecting.IsSelectable(LSlot) then
          Continue;
        LEntity := FContext.Pool.Slots[LSlot];
        LUnit.X := LEntity^.Position.X;
        LUnit.Y := LEntity^.Position.Y;
        LUnit.Width := LEntity^.UnitData.SizeX * WAR_MODEL_MEGA_TILE;
        LUnit.Height := LEntity^.UnitData.SizeY * WAR_MODEL_MEGA_TILE;
        // rect_intersects
        LRight := LPointer.X + LPointer.Width;
        LBottom := LPointer.Y + LPointer.Height;
        if not ((LRight < LUnit.X) or (LPointer.X > LUnit.X + LUnit.Width) or (LBottom < LUnit.Y) or
          (LPointer.Y > LUnit.Y + LUnit.Height)) then
          LCandidates.Add(LSlot);
      end;
    end
    else
    begin
      FCamera.ScreenToMap(AInput.PositionX, AInput.PositionY, LMapX, LMapY);
      LKind := FPicker.Find(LMapX, LMapY, False, False, LSlot);
      if (LKind = WAR_ENTITY_UNIT) and FSelecting.IsSelectable(LSlot) then
        LCandidates.Add(LSlot);
    end;
    // Control keeps what was selected
    if AInput.IsKeyHeld(wkCtrl) then
      for LIndex := 0 to FContext.Selection.Count - 1 do
      begin
        LSlot := FContext.Pool.FindSlot(FContext.Selection[LIndex]);
        if LSlot <> 0 then
          LCandidates.Add(LSlot);
      end;
    SelectFromList(LCandidates);
  finally
    LCandidates.Free;
  end;
end;

procedure TWarMapSelecting.UpdateGroups(const AInput: IWarUiInput; ACheatsOpen: Boolean);
const
  DIGITS: array[0..8] of TWarKey = (wk1, wk2, wk3, wk4, wk5, wk6, wk7, wk8, wk9);
var
  LGroup: Integer;
  LCandidates: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
begin
  // the digits that are typed in the cheat line are not groups
  if ACheatsOpen then
    Exit;
  for LGroup := 0 to 8 do
  begin
    if not AInput.IsKeyJustPressed(DIGITS[LGroup]) then
      Continue;
    if AInput.IsKeyHeld(wkCtrl) then
    begin
      FSelecting.StoreGroup(LGroup);
      Break;
    end;
    if FContext.Selection.GroupCount(LGroup) = 0 then
      Break;
    LCandidates := TList<Integer>.Create;
    try
      for LIndex := 0 to FContext.Selection.GroupCount(LGroup) - 1 do
      begin
        LSlot := FContext.Pool.FindSlot(FContext.Selection.GroupItem(LGroup, LIndex));
        if (LSlot <> 0) and FSelecting.IsSelectable(LSlot) then
          LCandidates.Add(LSlot);
      end;
      SelectFromList(LCandidates);
    finally
      LCandidates.Free;
    end;
    Break;
  end;
end;

end.
