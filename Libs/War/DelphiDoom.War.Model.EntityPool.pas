{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the pool of the entities                          }
{                                                                              }
{  Port of war1 (acoto87/war1), the entity manager of war_entities.c           }
{  (we_initEntityManager, we_createEntity, we_findEntity, the lists by type),  }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.EntityPool;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   The flat pool of the entities (slot 0 is never used; a slot with id 0 is free) with their ids and the lists by
  ///   entity type and by unit type, in the order in which the entities were added. A slot is found by a number, as the
  ///   pointer of the original, and the slots stay where they are: the updates of the states go through them in order
  /// </summary>
  TWarEntityPool = class
  strict private
    FSlots: TArray<TWarEntity>;
    FSlotOfId: TArray<Word>;
    FEntityCount: Integer;
    FNextEntityId: Integer;
    FByType: array[0..WAR_ENTITY_TYPE_COUNT - 1] of TList<Integer>;
    FUnitsByType: array[0..WAR_UNIT_COUNT - 1] of TList<Integer>;
    function GetSlot(ASlot: Integer): PWarEntity;
    function GetOfType(AType: Integer): TList<Integer>;
    function GetUnitsOfType(AType: Integer): TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   we_createEntity: the first free slot and the next id. Slot 0 if the pool is full (the original logs an error and
    ///   gives NULL). With AAddToScene False the entity is not in the list of its type (the units that are going to be
    ///   trained) but it is found by its id
    /// </summary>
    function CreateEntity(AEntityType: Integer; AAddToScene: Boolean): Integer;
    /// <summary>we_findEntity: the slot of the entity with that id, 0 if there is none</summary>
    function FindSlot(AId: Word): Integer;
    /// <summary>Adds the entity to the list of its unit type (the units that are in the map)</summary>
    procedure AddToUnitList(ASlot, AUnitType: Integer);
    /// <summary>The last step of we_removeEntity: out of the lists and of the id table, the slot free</summary>
    procedure FreeSlot(ASlot: Integer; AUnitType: Integer; AIsUnit: Boolean);
    property Slots[ASlot: Integer]: PWarEntity read GetSlot;
    property EntityCount: Integer read FEntityCount;
    /// <summary>The ids given so far (the original counts them without end; here the last one given)</summary>
    property LastId: Integer read FNextEntityId;
    /// <summary>we_getEntitiesOfType: slots, in the order of insertion</summary>
    property OfType[AType: Integer]: TList<Integer> read GetOfType;
    /// <summary>we_getUnitsOfType</summary>
    property UnitsOfType[AType: Integer]: TList<Integer> read GetUnitsOfType;
  end;

implementation

{ TWarEntityPool }

constructor TWarEntityPool.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FSlots, WAR_MODEL_MAX_ENTITIES);
  SetLength(FSlotOfId, 65536);
  for LIndex := 0 to High(FByType) do
    FByType[LIndex] := TList<Integer>.Create;
  for LIndex := 0 to High(FUnitsByType) do
    FUnitsByType[LIndex] := TList<Integer>.Create;
end;

destructor TWarEntityPool.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FByType) do
    FByType[LIndex].Free;
  for LIndex := 0 to High(FUnitsByType) do
    FUnitsByType[LIndex].Free;
  inherited;
end;

function TWarEntityPool.GetSlot(ASlot: Integer): PWarEntity;
begin
  if (ASlot < 0) or (ASlot >= WAR_MODEL_MAX_ENTITIES) then
    raise EWarException.CreateFmt(SWarModelBadEntity, [ASlot]);
  Result := @FSlots[ASlot];
end;

function TWarEntityPool.GetOfType(AType: Integer): TList<Integer>;
begin
  Result := FByType[AType];
end;

function TWarEntityPool.GetUnitsOfType(AType: Integer): TList<Integer>;
begin
  Result := FUnitsByType[AType];
end;

function TWarEntityPool.CreateEntity(AEntityType: Integer; AAddToScene: Boolean): Integer;
var
  LId: Word;
begin
  Result := 0;
  for LId := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
    if FSlots[LId].Id = 0 then
    begin
      Result := LId;
      Break;
    end;
  if Result = 0 then
    Exit;
  // the original takes (u16)++nextEntityId: after 65535 entities it hands out 0, which means a free slot, and ids
  // that are still in use. Here those ids are skipped
  repeat
    Inc(FNextEntityId);
    LId := Word(FNextEntityId);
  until (LId <> 0) and (FSlotOfId[LId] = 0);
  FSlots[Result] := Default(TWarEntity);
  FSlots[Result].Id := LId;
  FSlots[Result].EntityType := Word(AEntityType);
  FSlotOfId[LId] := Word(Result);
  Inc(FEntityCount);
  if AAddToScene then
    FByType[AEntityType].Add(Result);
end;

function TWarEntityPool.FindSlot(AId: Word): Integer;
begin
  Result := FSlotOfId[AId];
end;

procedure TWarEntityPool.AddToUnitList(ASlot, AUnitType: Integer);
begin
  FUnitsByType[AUnitType].Add(ASlot);
end;

procedure TWarEntityPool.FreeSlot(ASlot: Integer; AUnitType: Integer; AIsUnit: Boolean);
var
  LIndex: Integer;
begin
  if AIsUnit then
  begin
    LIndex := FUnitsByType[AUnitType].IndexOf(ASlot);
    if LIndex >= 0 then
      FUnitsByType[AUnitType].Delete(LIndex);
  end;
  LIndex := FByType[FSlots[ASlot].EntityType].IndexOf(ASlot);
  if LIndex >= 0 then
    FByType[FSlots[ASlot].EntityType].Delete(LIndex);
  FSlotOfId[FSlots[ASlot].Id] := 0;
  FSlots[ASlot] := Default(TWarEntity);
  Dec(FEntityCount);
end;

end.
