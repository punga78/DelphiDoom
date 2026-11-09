{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the list of the actors                            }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  InitObjArray, GetNewObj and RemoveObj of kd_play.c                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ObjectList;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   objarray: the structures of every actor that plays, as a linked list that starts at the player and ends
  ///   where Next is -1. GetNewObj puts the new one at the end, so an actor that makes another one will see
  ///   it think and react in the same frame. RemoveObj takes an actor out of the list and gives it back to
  ///   the free list (a list that goes backwards), but does not change its Next: a loop that was on it can
  ///   still go on to the next. The slots are in an array of the class: a pointer to an actor stays good
  ///   until the list is freed
  /// </summary>
  TKeenObjectList = class(TInterfacedObject, IKeenObjectList)
  strict private
    FObjects: array[0..KEEN_MAXACTORS] of TKeenObject;
    FFreeList: Integer;
    FLast: Integer;
    FNew: Integer;
    FPlayer: Integer;
    FScoreObj: Integer;
    FCount: Integer;
    FRefresh: IKeenRefresh;
    function Slot(AObject: PKeenObject): Integer;
  public
    /// <param name="ARefresh">The refresh manager that an actor that goes away takes its sprite from</param>
    constructor Create(const ARefresh: IKeenRefresh);
    function GetCount: Integer;
    function GetNew: PKeenObject;
    function GetPlayer: PKeenObject;
    function GetScoreObj: PKeenObject;
    function GetFirst: PKeenObject;
    function GetObject(ASlot: Integer): PKeenObject;
    procedure Init;
    function GetNewObj(AUseDummy: Boolean): PKeenObject;
    procedure RemoveObj(AGone: PKeenObject);
    function NextOf(AObject: PKeenObject): PKeenObject;
  end;

implementation

const
  /// <summary>The place after the last one, for the actor that nothing uses (dummyobj)</summary>
  DUMMY_SLOT = KEEN_MAXACTORS;

{ TKeenObjectList }

constructor TKeenObjectList.Create(const ARefresh: IKeenRefresh);
begin
  inherited Create;
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  FRefresh := ARefresh;
  FLast := -1;
  FNew := -1;
  FPlayer := -1;
  FScoreObj := -1;
  Init;
end;

function TKeenObjectList.Slot(AObject: PKeenObject): Integer;
begin
  Result := AObject^.Slot;
  if (Result < 0) or (Result > DUMMY_SLOT) or (@FObjects[Result] <> AObject) then
    raise EKeenException.CreateFmt(SKeenObjectInvalid, [Result]);
end;

function TKeenObjectList.GetCount: Integer;
begin
  Result := FCount;
end;

function TKeenObjectList.GetNew: PKeenObject;
begin
  if FNew < 0 then
    Exit(nil);
  Result := @FObjects[FNew];
end;

function TKeenObjectList.GetPlayer: PKeenObject;
begin
  Result := @FObjects[FPlayer];
end;

function TKeenObjectList.GetScoreObj: PKeenObject;
begin
  Result := @FObjects[FScoreObj];
end;

function TKeenObjectList.GetFirst: PKeenObject;
begin
  Result := @FObjects[FPlayer];
end;

function TKeenObjectList.GetObject(ASlot: Integer): PKeenObject;
begin
  if (ASlot < 0) or (ASlot >= KEEN_MAXACTORS) then
    raise EKeenException.CreateFmt(SKeenObjectInvalid, [ASlot]);
  Result := @FObjects[ASlot];
end;

procedure TKeenObjectList.Init;
var
  LIndex: Integer;
begin
  for LIndex := 0 to KEEN_MAXACTORS - 1 do
  begin
    FObjects[LIndex].Slot := LIndex;
    FObjects[LIndex].Prev := LIndex + 1;
    FObjects[LIndex].Next := -1;
  end;
  FObjects[KEEN_MAXACTORS - 1].Prev := -1;
  FillChar(FObjects[DUMMY_SLOT], SizeOf(TKeenObject), 0);
  FObjects[DUMMY_SLOT].Slot := DUMMY_SLOT;
  FObjects[DUMMY_SLOT].Next := -1;
  FObjects[DUMMY_SLOT].Prev := -1;
  FFreeList := 0;
  FLast := -1;
  FCount := 0;
  // the player and the score box get the first two places
  GetNewObj(False);
  FPlayer := FNew;
  GetNewObj(False);
  FScoreObj := FNew;
end;

function TKeenObjectList.GetNewObj(AUseDummy: Boolean): PKeenObject;
var
  LSlot: Integer;
begin
  if FFreeList < 0 then
  begin
    if AUseDummy then
    begin
      FNew := DUMMY_SLOT;
      Exit(@FObjects[DUMMY_SLOT]);
    end;
    raise EKeenException.Create(SKeenObjectListFull);
  end;
  LSlot := FFreeList;
  FFreeList := FObjects[LSlot].Prev;
  FillChar(FObjects[LSlot], SizeOf(TKeenObject), 0);
  FObjects[LSlot].Slot := LSlot;
  FObjects[LSlot].Next := -1;
  if FLast >= 0 then
    FObjects[FLast].Next := LSlot;
  FObjects[LSlot].Prev := FLast;
  FObjects[LSlot].Active := kaYes;
  FObjects[LSlot].NeedToClip := True;
  FLast := LSlot;
  FNew := LSlot;
  Inc(FCount);
  Result := @FObjects[LSlot];
end;

procedure TKeenObjectList.RemoveObj(AGone: PKeenObject);
var
  LSlot: Integer;
begin
  LSlot := Slot(AGone);
  if LSlot = FPlayer then
    raise EKeenException.Create(SKeenObjectRemovePlayer);
  // erase it from the refresh manager
  FRefresh.RemoveSprite(FObjects[LSlot].Sprite);
  // fix the next actor's back link
  if LSlot = FLast then
    FLast := FObjects[LSlot].Prev
  else if FObjects[LSlot].Next >= 0 then
    FObjects[FObjects[LSlot].Next].Prev := FObjects[LSlot].Prev;
  // fix the previous actor's forward link
  FObjects[FObjects[LSlot].Prev].Next := FObjects[LSlot].Next;
  // back to the free list
  FObjects[LSlot].Prev := FFreeList;
  FFreeList := LSlot;
  Dec(FCount);
end;

function TKeenObjectList.NextOf(AObject: PKeenObject): PKeenObject;
var
  LNext: Integer;
begin
  LNext := AObject^.Next;
  if (LNext < 0) or (LNext >= KEEN_MAXACTORS) then
    Exit(nil);
  Result := @FObjects[LNext];
end;

end.
