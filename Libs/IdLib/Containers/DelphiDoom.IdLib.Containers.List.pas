{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdList, the growable list with granularity  }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\List.h.       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.List;

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.IdLib.Core.Exceptions;

const
  SIdListBadIndex = 'idList: index %d is outside the list (%d elements)';
  SIdListBadSize = 'idList: bad size %d';
  SIdListBadGranularity = 'idList: the granularity must be positive';

type
  /// <summary>
  ///   A list that grows by a granularity (idList). Unlike <c>TList&lt;T&gt;</c> it keeps the allocation rules
  ///   of the original, which callers can observe: <c>NumAllocated</c> grows by whole granularities, an
  ///   <c>Insert</c> index is clamped into the list, <c>RemoveIndex</c> and <c>Remove</c> answer false instead
  ///   of failing, <c>AddUnique</c> answers the index, <c>SetNum</c>, <c>Resize</c> and <c>Condense</c> set the
  ///   allocation. A resize copies only the used elements into a new zeroed array (what lies beyond
  ///   <c>Num</c> is lost), a removal leaves the old last element behind the end as in the original.
  ///   <para>Differences: the elements are compared with an injected <c>IEqualityComparer</c> (default: the
  ///   one of the type, the C++ uses <c>operator==</c>); <c>Sort</c> takes a comparison (default: the
  ///   order of the type, the C++ uses <c>*a - *b</c>) and is not stable, as <c>qsort</c>; the C++ asserts
  ///   (index out of range, negative size) are <c>EIdLibException</c>; <c>Alloc</c> returns the index of the
  ///   new element (Delphi has no reference result); not ported: <c>Ptr</c>, <c>Find</c> by pointer,
  ///   <c>IndexOf</c> by pointer, <c>FindNull</c> and <c>DeleteContents</c> (they are for pointer lists;
  ///   a list of objects is freed by its owner), and the memory statistics.</para>
  /// </summary>
  TIdList<T> = class
  strict private
    FItems: TArray<T>;
    FNum: Integer;
    FSize: Integer;
    FGranularity: Integer;
    FComparer: IEqualityComparer<T>;
    function GetItem(const AIndex: Integer): T;
    procedure SetItem(const AIndex: Integer; const AValue: T);
    procedure Reallocate(const ANewSize: Integer);
    procedure GrowByGranularity;
    function RoundedUp(const ASize: Integer): Integer;
  public
    /// <summary>A list with the granularity (positive) and the comparison of elements (nil: the default)</summary>
    constructor Create(const AGranularity: Integer = 16; const AComparer: IEqualityComparer<T> = nil);
    /// <summary>idList::Clear: frees the allocation</summary>
    procedure Clear;
    /// <summary>idList::operator=: clears this list and copies the size, the granularity and the used elements</summary>
    procedure Assign(const AOther: TIdList<T>);
    function Num: Integer;
    function NumAllocated: Integer;
    function GetGranularity: Integer;
    /// <summary>idList::SetGranularity: resizes to the nearest multiple of the new granularity above Num</summary>
    procedure SetGranularity(const AGranularity: Integer);
    /// <summary>idList::Condense: allocates exactly Num elements (frees everything when empty)</summary>
    procedure Condense;
    /// <summary>idList::Resize(newsize): no change when the size is the same, frees at 0, cuts Num to the size</summary>
    procedure Resize(const ANewSize: Integer); overload;
    /// <summary>idList::Resize(newsize, newgranularity): sets the granularity and always reallocates</summary>
    procedure Resize(const ANewSize, AGranularity: Integer); overload;
    /// <summary>idList::SetNum: with <c>AResize</c> (or when growing) allocates exactly this number</summary>
    procedure SetNum(const ANewNum: Integer; const AResize: Boolean = True);
    /// <summary>idList::AssureSize: at least this number of elements, the new ones left as they come (zero)</summary>
    procedure AssureSize(const ANewSize: Integer); overload;
    /// <summary>idList::AssureSize(newSize, initValue): the new elements get the value</summary>
    procedure AssureSize(const ANewSize: Integer; const AInitValue: T); overload;
    /// <summary>idList::Alloc: the slot of a new element at the end (it keeps what was there, zero after a resize); its index</summary>
    function Alloc: Integer;
    /// <summary>idList::Append: the index of the new element</summary>
    function Append(const AValue: T): Integer; overload;
    /// <summary>idList::Append(list): appends every element of the other list; the new number of elements</summary>
    function Append(const AOther: TIdList<T>): Integer; overload;
    /// <summary>idList::AddUnique: the index of the value, appended when it is not there</summary>
    function AddUnique(const AValue: T): Integer;
    /// <summary>idList::Insert: at the index clamped to 0..Num; the index used</summary>
    function Insert(const AValue: T; AIndex: Integer = 0): Integer;
    /// <summary>idList::FindIndex: -1 when the value is not found</summary>
    function FindIndex(const AValue: T): Integer;
    /// <summary>idList::RemoveIndex: false when the index is outside the list</summary>
    function RemoveIndex(const AIndex: Integer): Boolean;
    /// <summary>idList::Remove: false when the value is not found</summary>
    function Remove(const AValue: T): Boolean;
    /// <summary>idList::Sort with the default order of the type</summary>
    procedure Sort; overload;
    procedure Sort(const AComparer: IComparer<T>); overload;
    /// <summary>idList::SortSubSection: the elements from the start to the end index, both clamped</summary>
    procedure SortSubSection(AStartIndex, AEndIndex: Integer; const AComparer: IComparer<T> = nil);
    /// <summary>idList::Swap: exchanges the contents (and the allocation) of two lists</summary>
    procedure Swap(const AOther: TIdList<T>);
    /// <summary>The elements, 0..Num-1</summary>
    property Items[const AIndex: Integer]: T read GetItem write SetItem; default;
  end;

implementation

uses
  System.Generics.Collections;

{ TIdList<T> }

constructor TIdList<T>.Create(const AGranularity: Integer; const AComparer: IEqualityComparer<T>);
begin
  inherited Create;
  if AGranularity <= 0 then
    raise EIdLibException.Create(SIdListBadGranularity);
  FGranularity := AGranularity;
  if Assigned(AComparer) then
    FComparer := AComparer
  else
    FComparer := TEqualityComparer<T>.Default;
end;

function TIdList<T>.GetItem(const AIndex: Integer): T;
begin
  if (AIndex < 0) or (AIndex >= FNum) then
    raise EIdLibException.CreateFmt(SIdListBadIndex, [AIndex, FNum]);
  Result := FItems[AIndex];
end;

procedure TIdList<T>.SetItem(const AIndex: Integer; const AValue: T);
begin
  if (AIndex < 0) or (AIndex >= FNum) then
    raise EIdLibException.CreateFmt(SIdListBadIndex, [AIndex, FNum]);
  FItems[AIndex] := AValue;
end;

procedure TIdList<T>.Reallocate(const ANewSize: Integer);
var
  LItems: TArray<T>;
  LIndex: Integer;
begin
  FSize := ANewSize;
  if FSize < FNum then
    FNum := FSize;
  // The original copies the used elements into a fresh array: anything beyond Num is lost
  SetLength(LItems, FSize);
  for LIndex := 0 to FNum - 1 do
    LItems[LIndex] := FItems[LIndex];
  FItems := LItems;
end;

procedure TIdList<T>.GrowByGranularity;
var
  LNewSize: Integer;
begin
  if FSize = 0 then
    Resize(FGranularity);
  if FNum = FSize then
  begin
    LNewSize := FSize + FGranularity;
    Resize(LNewSize - LNewSize mod FGranularity);
  end;
end;

function TIdList<T>.RoundedUp(const ASize: Integer): Integer;
begin
  Result := ASize + FGranularity - 1;
  Dec(Result, Result mod FGranularity);
end;

procedure TIdList<T>.Clear;
begin
  FItems := nil;
  FNum := 0;
  FSize := 0;
end;

procedure TIdList<T>.Assign(const AOther: TIdList<T>);
var
  LIndex: Integer;
begin
  Clear;
  FNum := AOther.FNum;
  FSize := AOther.FSize;
  FGranularity := AOther.FGranularity;
  if FSize > 0 then
  begin
    SetLength(FItems, FSize);
    for LIndex := 0 to FNum - 1 do
      FItems[LIndex] := AOther.FItems[LIndex];
  end;
end;

function TIdList<T>.Num: Integer;
begin
  Result := FNum;
end;

function TIdList<T>.NumAllocated: Integer;
begin
  Result := FSize;
end;

function TIdList<T>.GetGranularity: Integer;
begin
  Result := FGranularity;
end;

procedure TIdList<T>.SetGranularity(const AGranularity: Integer);
var
  LNewSize: Integer;
begin
  if AGranularity <= 0 then
    raise EIdLibException.Create(SIdListBadGranularity);
  FGranularity := AGranularity;
  if FSize > 0 then
  begin
    LNewSize := RoundedUp(FNum);
    if LNewSize <> FSize then
      Resize(LNewSize);
  end;
end;

procedure TIdList<T>.Condense;
begin
  if FSize > 0 then
  begin
    if FNum > 0 then
      Resize(FNum)
    else
      Clear;
  end;
end;

procedure TIdList<T>.Resize(const ANewSize: Integer);
begin
  if ANewSize < 0 then
    raise EIdLibException.CreateFmt(SIdListBadSize, [ANewSize]);
  if ANewSize = 0 then
  begin
    Clear;
    Exit;
  end;
  if ANewSize = FSize then
    Exit;
  Reallocate(ANewSize);
end;

procedure TIdList<T>.Resize(const ANewSize, AGranularity: Integer);
begin
  if ANewSize < 0 then
    raise EIdLibException.CreateFmt(SIdListBadSize, [ANewSize]);
  if AGranularity <= 0 then
    raise EIdLibException.Create(SIdListBadGranularity);
  FGranularity := AGranularity;
  if ANewSize = 0 then
  begin
    Clear;
    Exit;
  end;
  Reallocate(ANewSize);
end;

procedure TIdList<T>.SetNum(const ANewNum: Integer; const AResize: Boolean);
begin
  if ANewNum < 0 then
    raise EIdLibException.CreateFmt(SIdListBadSize, [ANewNum]);
  if AResize or (ANewNum > FSize) then
    Resize(ANewNum);
  FNum := ANewNum;
end;

procedure TIdList<T>.AssureSize(const ANewSize: Integer);
var
  LNewNum: Integer;
begin
  LNewNum := ANewSize;
  if ANewSize > FSize then
    Resize(RoundedUp(ANewSize));
  FNum := LNewNum;
end;

procedure TIdList<T>.AssureSize(const ANewSize: Integer; const AInitValue: T);
var
  LNewNum: Integer;
  LNewSize: Integer;
  LIndex: Integer;
begin
  LNewNum := ANewSize;
  if ANewSize > FSize then
  begin
    LNewSize := RoundedUp(ANewSize);
    FNum := FSize;
    Resize(LNewSize);
    for LIndex := FNum to LNewSize - 1 do
      FItems[LIndex] := AInitValue;
  end;
  FNum := LNewNum;
end;

function TIdList<T>.Alloc: Integer;
begin
  if FSize = 0 then
    Resize(FGranularity);
  if FNum = FSize then
    Resize(FSize + FGranularity);
  Result := FNum;
  Inc(FNum);
end;

function TIdList<T>.Append(const AValue: T): Integer;
begin
  GrowByGranularity;
  FItems[FNum] := AValue;
  Inc(FNum);
  Result := FNum - 1;
end;

function TIdList<T>.Append(const AOther: TIdList<T>): Integer;
var
  LCount: Integer;
  LIndex: Integer;
begin
  if FSize = 0 then
    Resize(FGranularity);
  // Taken before the loop: appending a list to itself adds its elements once
  LCount := AOther.Num;
  for LIndex := 0 to LCount - 1 do
    Append(AOther[LIndex]);
  Result := FNum;
end;

function TIdList<T>.AddUnique(const AValue: T): Integer;
begin
  Result := FindIndex(AValue);
  if Result < 0 then
    Result := Append(AValue);
end;

function TIdList<T>.Insert(const AValue: T; AIndex: Integer): Integer;
var
  LIndex: Integer;
begin
  GrowByGranularity;
  if AIndex < 0 then
    AIndex := 0
  else if AIndex > FNum then
    AIndex := FNum;
  for LIndex := FNum downto AIndex + 1 do
    FItems[LIndex] := FItems[LIndex - 1];
  Inc(FNum);
  FItems[AIndex] := AValue;
  Result := AIndex;
end;

function TIdList<T>.FindIndex(const AValue: T): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FNum - 1 do
    if FComparer.Equals(FItems[LIndex], AValue) then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

function TIdList<T>.RemoveIndex(const AIndex: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := (AIndex >= 0) and (AIndex < FNum);
  if not Result then
    Exit;
  Dec(FNum);
  for LIndex := AIndex to FNum - 1 do
    FItems[LIndex] := FItems[LIndex + 1];
end;

function TIdList<T>.Remove(const AValue: T): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FindIndex(AValue);
  Result := (LIndex >= 0) and RemoveIndex(LIndex);
end;

procedure TIdList<T>.Sort;
begin
  Sort(nil);
end;

procedure TIdList<T>.Sort(const AComparer: IComparer<T>);
begin
  if FSize = 0 then
    Exit;
  if Assigned(AComparer) then
    TArray.Sort<T>(FItems, AComparer, 0, FNum)
  else
    TArray.Sort<T>(FItems, TComparer<T>.Default, 0, FNum);
end;

procedure TIdList<T>.SortSubSection(AStartIndex, AEndIndex: Integer; const AComparer: IComparer<T>);
begin
  if FSize = 0 then
    Exit;
  if AStartIndex < 0 then
    AStartIndex := 0;
  if AEndIndex >= FNum then
    AEndIndex := FNum - 1;
  if AStartIndex >= AEndIndex then
    Exit;
  if Assigned(AComparer) then
    TArray.Sort<T>(FItems, AComparer, AStartIndex, AEndIndex - AStartIndex + 1)
  else
    TArray.Sort<T>(FItems, TComparer<T>.Default, AStartIndex, AEndIndex - AStartIndex + 1);
end;

procedure TIdList<T>.Swap(const AOther: TIdList<T>);
var
  LItems: TArray<T>;
  LValue: Integer;
begin
  LValue := FNum;
  FNum := AOther.FNum;
  AOther.FNum := LValue;
  LValue := FSize;
  FSize := AOther.FSize;
  AOther.FSize := LValue;
  LValue := FGranularity;
  FGranularity := AOther.FGranularity;
  AOther.FGranularity := LValue;
  LItems := FItems;
  FItems := AOther.FItems;
  AOther.FItems := LItems;
end;

end.
