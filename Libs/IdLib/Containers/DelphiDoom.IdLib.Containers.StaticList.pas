{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdStaticList, the list of fixed capacity    }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\StaticList.h. }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.StaticList;

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.IdLib.Core.Exceptions;

const
  SIdStaticListBadIndex = 'idStaticList: index %d is outside the list (%d elements)';
  SIdStaticListBadNum = 'idStaticList: %d elements do not fit in %d';
  SIdStaticListBadMax = 'idStaticList: the capacity must not be negative';
  SIdStaticListMaxDiffers = 'idStaticList: the lists have a different capacity';

type
  /// <summary>
  ///   A list with a capacity fixed when it is made (idStaticList: the capacity is a template argument in C++).
  ///   Nothing grows: a full list answers -1 (<c>Append</c>, <c>Insert</c>) instead of failing, as the
  ///   original does in release builds; <c>Clear</c> only sets the count to 0. <c>Swap</c> exchanges the whole
  ///   arrays, so elements beyond <c>Num</c> travel too, as the original (it copies the complete lists).
  ///   <para>Differences: the elements are compared with an injected <c>IEqualityComparer</c>; the C++ asserts
  ///   on an index out of range are <c>EIdLibException</c>; <c>Alloc</c> returns the index (-1 when full);
  ///   not ported: <c>Ptr</c>, <c>Find</c>, <c>IndexOf</c> and <c>FindNull</c> by pointer and
  ///   <c>DeleteContents</c> (pointer lists), the memory statistics.</para>
  /// </summary>
  TIdStaticList<T> = class
  strict private
    FItems: TArray<T>;
    FNum: Integer;
    FComparer: IEqualityComparer<T>;
    function GetItem(const AIndex: Integer): T;
    procedure SetItem(const AIndex: Integer; const AValue: T);
  public
    constructor Create(const AMax: Integer; const AComparer: IEqualityComparer<T> = nil);
    /// <summary>idStaticList::Clear: marks the list as empty (does not touch the data)</summary>
    procedure Clear;
    /// <summary>The copy of another list of the same capacity (the whole array, as the C++ assignment)</summary>
    procedure Assign(const AOther: TIdStaticList<T>);
    function Num: Integer;
    /// <summary>idStaticList::Max: the capacity</summary>
    function Max: Integer;
    /// <summary>idStaticList::SetNum: the new count must fit in the capacity</summary>
    procedure SetNum(const ANewNum: Integer);
    /// <summary>idStaticList::Alloc: the index of the next slot, or -1 when full</summary>
    function Alloc: Integer;
    /// <summary>idStaticList::Append: the index of the new element, or -1 when full</summary>
    function Append(const AValue: T): Integer; overload;
    /// <summary>idStaticList::Append(list): as many elements as fit; the new number of elements</summary>
    function Append(const AOther: TIdStaticList<T>): Integer; overload;
    /// <summary>idStaticList::AddUnique: the index of the value, appended when it is not there (-1 if full)</summary>
    function AddUnique(const AValue: T): Integer;
    /// <summary>idStaticList::Insert: the index clamped to 0..Num, or -1 when full</summary>
    function Insert(const AValue: T; AIndex: Integer): Integer;
    /// <summary>idStaticList::FindIndex: -1 when the value is not found</summary>
    function FindIndex(const AValue: T): Integer;
    /// <summary>idStaticList::RemoveIndex: false when the index is outside the list</summary>
    function RemoveIndex(const AIndex: Integer): Boolean;
    /// <summary>idStaticList::Remove: false when the value is not found</summary>
    function Remove(const AValue: T): Boolean;
    /// <summary>idStaticList::Swap: both lists must have the same capacity</summary>
    procedure Swap(const AOther: TIdStaticList<T>);
    property Items[const AIndex: Integer]: T read GetItem write SetItem; default;
  end;

implementation

uses
  System.Generics.Collections;

{ TIdStaticList<T> }

constructor TIdStaticList<T>.Create(const AMax: Integer; const AComparer: IEqualityComparer<T>);
begin
  inherited Create;
  if AMax < 0 then
    raise EIdLibException.Create(SIdStaticListBadMax);
  SetLength(FItems, AMax);
  if Assigned(AComparer) then
    FComparer := AComparer
  else
    FComparer := TEqualityComparer<T>.Default;
end;

function TIdStaticList<T>.GetItem(const AIndex: Integer): T;
begin
  if (AIndex < 0) or (AIndex >= FNum) then
    raise EIdLibException.CreateFmt(SIdStaticListBadIndex, [AIndex, FNum]);
  Result := FItems[AIndex];
end;

procedure TIdStaticList<T>.SetItem(const AIndex: Integer; const AValue: T);
begin
  if (AIndex < 0) or (AIndex >= FNum) then
    raise EIdLibException.CreateFmt(SIdStaticListBadIndex, [AIndex, FNum]);
  FItems[AIndex] := AValue;
end;

procedure TIdStaticList<T>.Clear;
begin
  FNum := 0;
end;

procedure TIdStaticList<T>.Assign(const AOther: TIdStaticList<T>);
var
  LIndex: Integer;
begin
  if Length(AOther.FItems) <> Length(FItems) then
    raise EIdLibException.Create(SIdStaticListMaxDiffers);
  FNum := AOther.FNum;
  for LIndex := 0 to High(FItems) do
    FItems[LIndex] := AOther.FItems[LIndex];
end;

function TIdStaticList<T>.Num: Integer;
begin
  Result := FNum;
end;

function TIdStaticList<T>.Max: Integer;
begin
  Result := Length(FItems);
end;

procedure TIdStaticList<T>.SetNum(const ANewNum: Integer);
begin
  if (ANewNum < 0) or (ANewNum > Length(FItems)) then
    raise EIdLibException.CreateFmt(SIdStaticListBadNum, [ANewNum, Length(FItems)]);
  FNum := ANewNum;
end;

function TIdStaticList<T>.Alloc: Integer;
begin
  if FNum >= Length(FItems) then
  begin
    Result := -1;
    Exit;
  end;
  Result := FNum;
  Inc(FNum);
end;

function TIdStaticList<T>.Append(const AValue: T): Integer;
begin
  if FNum >= Length(FItems) then
  begin
    Result := -1;
    Exit;
  end;
  FItems[FNum] := AValue;
  Inc(FNum);
  Result := FNum - 1;
end;

function TIdStaticList<T>.Append(const AOther: TIdStaticList<T>): Integer;
var
  LCount: Integer;
  LIndex: Integer;
begin
  LCount := AOther.FNum;
  if FNum + LCount > Length(FItems) then
    LCount := Length(FItems) - FNum;
  for LIndex := 0 to LCount - 1 do
    FItems[FNum + LIndex] := AOther.FItems[LIndex];
  Inc(FNum, LCount);
  Result := FNum;
end;

function TIdStaticList<T>.AddUnique(const AValue: T): Integer;
begin
  Result := FindIndex(AValue);
  if Result < 0 then
    Result := Append(AValue);
end;

function TIdStaticList<T>.Insert(const AValue: T; AIndex: Integer): Integer;
var
  LIndex: Integer;
begin
  if FNum >= Length(FItems) then
  begin
    Result := -1;
    Exit;
  end;
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

function TIdStaticList<T>.FindIndex(const AValue: T): Integer;
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

function TIdStaticList<T>.RemoveIndex(const AIndex: Integer): Boolean;
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

function TIdStaticList<T>.Remove(const AValue: T): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FindIndex(AValue);
  Result := (LIndex >= 0) and RemoveIndex(LIndex);
end;

procedure TIdStaticList<T>.Swap(const AOther: TIdStaticList<T>);
var
  LItems: TArray<T>;
  LNum: Integer;
begin
  if Length(AOther.FItems) <> Length(FItems) then
    raise EIdLibException.Create(SIdStaticListMaxDiffers);
  LNum := FNum;
  FNum := AOther.FNum;
  AOther.FNum := LNum;
  LItems := FItems;
  FItems := AOther.FItems;
  AOther.FItems := LItems;
end;

end.
