{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a pool of objects in a doubly linked list        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): RF_ClearWorld, RF_GetSprite,}
{  RF_RemoveSprite, RF_GetElevator and RF_RemoveElevator of r_public.pas        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LinkedPool;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

const
  /// <summary>The index of "no object": the end of the list, or an empty free list</summary>
  GREED_POOL_NIL = -1;

type
  /// <summary>
  ///   A fixed array of objects with a list of the objects in use and a list of the free ones, as the original
  ///   keeps the sprites and the elevators (scaleobjlist, elevlist and the sentinels firstscaleobj and
  ///   lastscaleobj): the pointers are indices, so a saved or compared state has no addresses. The order of the
  ///   list is the order of creation, and the free objects are taken from the front of the free list (the object
  ///   that was removed last is the first to be reused, as in the original). The objects do not move: a pointer
  ///   from Item stays valid until the pool is destroyed
  /// </summary>
  TGreedLinkedPool<T: record> = class
  public type
    PItem = ^T;
  strict private
    FCapacity: Integer;
    FName: string;
    FItems: TArray<T>;
    // two more than the objects: the sentinels before the first and after the last
    FPrev: TArray<Integer>;
    FNext: TArray<Integer>;
    FFree: Integer;
    FCount: Integer;
    function FirstSentinel: Integer; inline;
    function LastSentinel: Integer; inline;
    procedure CheckIndex(AIndex: Integer);
  public
    /// <summary>AName is the kind of object in the message of the error when the pool is full</summary>
    constructor Create(ACapacity: Integer; const AName: string);
    /// <summary>The part of RF_ClearWorld for this list: no object in use, all free in order 0, 1, 2 ...</summary>
    procedure Clear;
    /// <summary>
    ///   RF_GetSprite and RF_GetElevator: a new object at the end of the list, all zero. EGreedException if there are
    ///   no free ones
    /// </summary>
    function Add: Integer;
    /// <summary>RF_RemoveSprite and RF_RemoveElevator: out of the list, to the front of the free list</summary>
    procedure Remove(AIndex: Integer);
    /// <summary>The first object of the list, GREED_POOL_NIL if it is empty</summary>
    function First: Integer;
    /// <summary>The object after AIndex, GREED_POOL_NIL after the last one</summary>
    function Next(AIndex: Integer): Integer;
    /// <summary>The object before AIndex, GREED_POOL_NIL before the first one</summary>
    function Previous(AIndex: Integer): Integer;
    /// <summary>The object itself, to read and to write</summary>
    function Item(AIndex: Integer): PItem;
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity;
  end;

implementation

{ TGreedLinkedPool<T> }

constructor TGreedLinkedPool<T>.Create(ACapacity: Integer; const AName: string);
begin
  inherited Create;
  if ACapacity < 1 then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [ACapacity, 'ACapacity', 1, MaxInt]);
  FCapacity := ACapacity;
  FName := AName;
  SetLength(FItems, ACapacity);
  SetLength(FPrev, ACapacity + 2);
  SetLength(FNext, ACapacity + 2);
  Clear;
end;

function TGreedLinkedPool<T>.FirstSentinel: Integer;
begin
  Result := FCapacity;
end;

function TGreedLinkedPool<T>.LastSentinel: Integer;
begin
  Result := FCapacity + 1;
end;

procedure TGreedLinkedPool<T>.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCapacity) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'AIndex', 0, FCapacity - 1]);
end;

procedure TGreedLinkedPool<T>.Clear;
var
  LIndex: Integer;
begin
  FPrev[FirstSentinel] := GREED_POOL_NIL;
  FNext[FirstSentinel] := LastSentinel;
  FPrev[LastSentinel] := FirstSentinel;
  FNext[LastSentinel] := GREED_POOL_NIL;
  for LIndex := 0 to FCapacity - 1 do
  begin
    FItems[LIndex] := Default(T);
    FPrev[LIndex] := GREED_POOL_NIL;
    if LIndex < FCapacity - 1 then
      FNext[LIndex] := LIndex + 1
    else
      FNext[LIndex] := GREED_POOL_NIL;
  end;
  FFree := 0;
  FCount := 0;
end;

function TGreedLinkedPool<T>.Add: Integer;
begin
  if FFree = GREED_POOL_NIL then
    raise EGreedException.CreateFmt(SGreedTooMany, [FName, FCapacity]);
  Result := FFree;
  FFree := FNext[Result];
  FItems[Result] := Default(T);
  FNext[Result] := LastSentinel;
  FPrev[Result] := FPrev[LastSentinel];
  FPrev[LastSentinel] := Result;
  FNext[FPrev[Result]] := Result;
  Inc(FCount);
end;

procedure TGreedLinkedPool<T>.Remove(AIndex: Integer);
begin
  CheckIndex(AIndex);
  FPrev[FNext[AIndex]] := FPrev[AIndex];
  FNext[FPrev[AIndex]] := FNext[AIndex];
  FNext[AIndex] := FFree;
  FFree := AIndex;
  Dec(FCount);
end;

function TGreedLinkedPool<T>.First: Integer;
begin
  Result := Next(FirstSentinel);
end;

function TGreedLinkedPool<T>.Next(AIndex: Integer): Integer;
begin
  Result := FNext[AIndex];
  if Result = LastSentinel then
    Result := GREED_POOL_NIL;
end;

function TGreedLinkedPool<T>.Previous(AIndex: Integer): Integer;
begin
  Result := FPrev[AIndex];
  if Result = FirstSentinel then
    Result := GREED_POOL_NIL;
end;

function TGreedLinkedPool<T>.Item(AIndex: Integer): PItem;
begin
  CheckIndex(AIndex);
  Result := @FItems[AIndex];
end;

end.
