{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the selected units and the selection groups       }
{                                                                              }
{  Port of war1 (acoto87/war1), wmap_addEntityToSelection,                      }
{  wmap_removeEntityFromSelection, wmap_clearSelection and the groups of       }
{  updateSelectionGroups of war_map.c, (c) 2019 Alejandro Coto Gutierrez, zlib }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Selection;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   map->selectedEntities and map->selectionGroups as data of the model: the ids of the selected entities in the order
  ///   in which they were added (at most 32, never twice) and nine groups that remember a selection. No rule of the game
  ///   is here (who can be selected is TWarSelectionCommands) and no drawing. Defect of the original kept: an entity that
  ///   is removed from the game stays in the selection and in the groups unless its state takes it out (death, collapse,
  ///   a worker that enters a building)
  /// </summary>
  TWarSelection = class
  strict private
    FItems: array[0..WAR_MODEL_MAX_SELECTED - 1] of Word;
    FCount: Integer;
    FGroups: array[0..WAR_MODEL_SELECTION_GROUPS - 1, 0..WAR_MODEL_MAX_SELECTED - 1] of Word;
    FGroupCounts: array[0..WAR_MODEL_SELECTION_GROUPS - 1] of Integer;
    function GetItem(AIndex: Integer): Word;
    procedure CheckGroup(AGroup: Integer);
  public
    /// <summary>wmap_addEntityToSelection: False if the selection is full or already has the id</summary>
    function Add(AId: Word): Boolean;
    /// <summary>wmap_removeEntityFromSelection: False if the id was not selected</summary>
    function Remove(AId: Word): Boolean;
    /// <summary>wmap_clearSelection</summary>
    procedure Clear;
    function Contains(AId: Word): Boolean;
    function IndexOf(AId: Word): Integer;
    /// <summary>Replaces the selection with the ids (those over the maximum and the repeated ones are left out)</summary>
    procedure Assign(const AIds: array of Word);
    /// <summary>CTRL + digit: the group (0..8) remembers the selection of now; EWarException for a group that does not exist</summary>
    procedure StoreGroup(AGroup: Integer);
    function GroupCount(AGroup: Integer): Integer;
    function GroupItem(AGroup, AIndex: Integer): Word;
    property Count: Integer read FCount;
    /// <summary>The id at the position; 0 outside (the original reads past the list)</summary>
    property Items[AIndex: Integer]: Word read GetItem; default;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarSelection }

function TWarSelection.GetItem(AIndex: Integer): Word;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    Exit(0);
  Result := FItems[AIndex];
end;

procedure TWarSelection.CheckGroup(AGroup: Integer);
begin
  if (AGroup < 0) or (AGroup >= WAR_MODEL_SELECTION_GROUPS) then
    raise EWarException.CreateFmt(SWarModelBadGroup, [AGroup]);
end;

function TWarSelection.IndexOf(AId: Word): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    if FItems[LIndex] = AId then
      Exit(LIndex);
  Result := -1;
end;

function TWarSelection.Contains(AId: Word): Boolean;
begin
  Result := IndexOf(AId) >= 0;
end;

function TWarSelection.Add(AId: Word): Boolean;
begin
  if (FCount >= WAR_MODEL_MAX_SELECTED) or Contains(AId) then
    Exit(False);
  FItems[FCount] := AId;
  Inc(FCount);
  Result := True;
end;

function TWarSelection.Remove(AId: Word): Boolean;
var
  LIndex: Integer;
  LMove: Integer;
begin
  LIndex := IndexOf(AId);
  if LIndex < 0 then
    Exit(False);
  for LMove := LIndex to FCount - 2 do
    FItems[LMove] := FItems[LMove + 1];
  Dec(FCount);
  Result := True;
end;

procedure TWarSelection.Clear;
begin
  FCount := 0;
end;

procedure TWarSelection.Assign(const AIds: array of Word);
var
  LIndex: Integer;
begin
  Clear;
  for LIndex := 0 to High(AIds) do
    Add(AIds[LIndex]);
end;

procedure TWarSelection.StoreGroup(AGroup: Integer);
var
  LIndex: Integer;
begin
  CheckGroup(AGroup);
  FGroupCounts[AGroup] := FCount;
  for LIndex := 0 to FCount - 1 do
    FGroups[AGroup, LIndex] := FItems[LIndex];
end;

function TWarSelection.GroupCount(AGroup: Integer): Integer;
begin
  CheckGroup(AGroup);
  Result := FGroupCounts[AGroup];
end;

function TWarSelection.GroupItem(AGroup, AIndex: Integer): Word;
begin
  CheckGroup(AGroup);
  if (AIndex < 0) or (AIndex >= FGroupCounts[AGroup]) then
    Exit(0);
  Result := FGroups[AGroup, AIndex];
end;

end.
