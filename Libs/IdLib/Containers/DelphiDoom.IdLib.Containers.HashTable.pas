{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdHashTable, the table keyed by text        }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\HashTable.h.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.HashTable;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions;

const
  SIdHashTableBadSize = 'idHashTable: the table size %d is not a power of two';

type
  /// <summary>
  ///   A table of values keyed by text (idHashTable): a fixed number of buckets (a power of two), each a
  ///   chain kept sorted by the exact (case-sensitive) comparison of the keys; the bucket of a key is
  ///   <c>idStr::Hash(key) and (size - 1)</c>. <c>GetIndex</c> walks the buckets in order, so the index of an
  ///   element changes when others are added.
  ///   <para>Differences: <c>Get</c> returns a copy of the value (the C++ a pointer: change a value with
  ///   <c>Put</c>); <c>GetIndex</c> with an index equal to <c>Num</c> or more gives false (the C++ asserts
  ///   and answers NULL); <c>DeleteContents</c> and the memory statistics are not ported (the table does
  ///   not own what its values point to); <c>GetSpread</c> is not ported: the original does not compile with
  ///   GCC 4 or newer and, where it is built, uses an undeclared <c>numItems</c>.</para>
  /// </summary>
  TIdHashTable<T> = class
  strict private
    type
      TNode = class
        Key: AnsiString;
        Value: T;
        Next: TNode;
      end;
  strict private
    FHeads: TArray<TNode>;
    FNumEntries: Integer;
    FTableSizeMask: Integer;
    function BucketOf(const AKey: AnsiString): Integer;
  public
    /// <summary>A table with the number of buckets (a power of two, 256 by default)</summary>
    constructor Create(const ATableSize: Integer = 256);
    destructor Destroy; override;
    /// <summary>The copy constructor of the C++ class: this table gets the contents of the other, with its size</summary>
    procedure Assign(const AOther: TIdHashTable<T>);
    /// <summary>idHashTable::Set: adds the key or replaces its value</summary>
    procedure Put(const AKey: AnsiString; const AValue: T);
    /// <summary>idHashTable::Get: false when the key is not there (the value is then the default)</summary>
    function Get(const AKey: AnsiString; out AValue: T): Boolean; overload;
    function Get(const AKey: AnsiString): Boolean; overload;
    /// <summary>idHashTable::Remove: false when the key is not there</summary>
    function Remove(const AKey: AnsiString): Boolean;
    procedure Clear;
    function Num: Integer;
    function GetTableSize: Integer;
    /// <summary>idHashTable::GetIndex: the value at the position in bucket order; false when out of range</summary>
    function GetIndex(const AIndex: Integer; out AValue: T): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TIdHashTable<T> }

constructor TIdHashTable<T>.Create(const ATableSize: Integer);
begin
  inherited Create;
  if (ATableSize <= 0) or ((ATableSize and (ATableSize - 1)) <> 0) then
    raise EIdLibException.CreateFmt(SIdHashTableBadSize, [ATableSize]);
  SetLength(FHeads, ATableSize);
  FTableSizeMask := ATableSize - 1;
end;

destructor TIdHashTable<T>.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TIdHashTable<T>.BucketOf(const AKey: AnsiString): Integer;
begin
  Result := TIdStrings.Hash(AKey) and FTableSizeMask;
end;

procedure TIdHashTable<T>.Assign(const AOther: TIdHashTable<T>);
var
  LBucket: Integer;
  LNode: TNode;
  LNew: TNode;
  LLast: TNode;
begin
  if AOther = Self then
    Exit;
  Clear;
  SetLength(FHeads, Length(AOther.FHeads));
  FTableSizeMask := AOther.FTableSizeMask;
  FNumEntries := AOther.FNumEntries;
  for LBucket := 0 to High(FHeads) do
  begin
    LLast := nil;
    LNode := AOther.FHeads[LBucket];
    while Assigned(LNode) do
    begin
      LNew := TNode.Create;
      LNew.Key := LNode.Key;
      LNew.Value := LNode.Value;
      if Assigned(LLast) then
        LLast.Next := LNew
      else
        FHeads[LBucket] := LNew;
      LLast := LNew;
      LNode := LNode.Next;
    end;
  end;
end;

procedure TIdHashTable<T>.Put(const AKey: AnsiString; const AValue: T);
var
  LBucket: Integer;
  LNode: TNode;
  LPrevious: TNode;
  LCompare: Integer;
  LNew: TNode;
begin
  LBucket := BucketOf(AKey);
  LPrevious := nil;
  LNode := FHeads[LBucket];
  while Assigned(LNode) do
  begin
    LCompare := TIdStrings.Cmp(LNode.Key, AKey);
    if LCompare = 0 then
    begin
      LNode.Value := AValue;
      Exit;
    end;
    if LCompare > 0 then
      Break;
    LPrevious := LNode;
    LNode := LNode.Next;
  end;
  Inc(FNumEntries);
  // The chain is sorted: the new node goes before the first greater key
  LNew := TNode.Create;
  LNew.Key := AKey;
  LNew.Value := AValue;
  LNew.Next := LNode;
  if Assigned(LPrevious) then
    LPrevious.Next := LNew
  else
    FHeads[LBucket] := LNew;
end;

function TIdHashTable<T>.Get(const AKey: AnsiString; out AValue: T): Boolean;
var
  LNode: TNode;
  LCompare: Integer;
begin
  AValue := Default(T);
  LNode := FHeads[BucketOf(AKey)];
  while Assigned(LNode) do
  begin
    LCompare := TIdStrings.Cmp(LNode.Key, AKey);
    if LCompare = 0 then
    begin
      AValue := LNode.Value;
      Result := True;
      Exit;
    end;
    if LCompare > 0 then
      Break;
    LNode := LNode.Next;
  end;
  Result := False;
end;

function TIdHashTable<T>.Get(const AKey: AnsiString): Boolean;
var
  LValue: T;
begin
  Result := Get(AKey, LValue);
end;

function TIdHashTable<T>.Remove(const AKey: AnsiString): Boolean;
var
  LBucket: Integer;
  LNode: TNode;
  LPrevious: TNode;
begin
  LBucket := BucketOf(AKey);
  LPrevious := nil;
  LNode := FHeads[LBucket];
  while Assigned(LNode) do
  begin
    if LNode.Key = AKey then
    begin
      if Assigned(LPrevious) then
        LPrevious.Next := LNode.Next
      else
        FHeads[LBucket] := LNode.Next;
      LNode.Free;
      Dec(FNumEntries);
      Result := True;
      Exit;
    end;
    LPrevious := LNode;
    LNode := LNode.Next;
  end;
  Result := False;
end;

procedure TIdHashTable<T>.Clear;
var
  LBucket: Integer;
  LNode: TNode;
  LNext: TNode;
begin
  for LBucket := 0 to High(FHeads) do
  begin
    LNext := FHeads[LBucket];
    while Assigned(LNext) do
    begin
      LNode := LNext;
      LNext := LNext.Next;
      LNode.Free;
    end;
    FHeads[LBucket] := nil;
  end;
  FNumEntries := 0;
end;

function TIdHashTable<T>.Num: Integer;
begin
  Result := FNumEntries;
end;

function TIdHashTable<T>.GetTableSize: Integer;
begin
  Result := Length(FHeads);
end;

function TIdHashTable<T>.GetIndex(const AIndex: Integer; out AValue: T): Boolean;
var
  LBucket: Integer;
  LNode: TNode;
  LCount: Integer;
begin
  AValue := Default(T);
  Result := False;
  if (AIndex < 0) or (AIndex >= FNumEntries) then
    Exit;
  LCount := 0;
  for LBucket := 0 to High(FHeads) do
  begin
    LNode := FHeads[LBucket];
    while Assigned(LNode) do
    begin
      if LCount = AIndex then
      begin
        AValue := LNode.Value;
        Result := True;
        Exit;
      end;
      Inc(LCount);
      LNode := LNode.Next;
    end;
  end;
end;

end.
