{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelTable                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The growing array of records that the old code kept with realloc            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Table;

interface

uses
  System.SysUtils;

type
  /// <summary>An array of records that grows one element at a time; the elements are changed in place</summary>
  TRadixLevelTable<T: record> = class
  public
    type
      PItem = ^T;
  strict private
    FItems: TArray<T>;
    FCount: Integer;
    function GetItem(AIndex: Integer): PItem;
  public
    /// <summary>Appends a record; returns its index</summary>
    function Add(const AItem: T): Integer;
    /// <summary>The bytes of the first Count records, as they go in a lump</summary>
    function ToBytes: TBytes;
    property Count: Integer read FCount;
    /// <summary>The record at an index (checked); the pointer is valid until the next Add</summary>
    property Items[AIndex: Integer]: PItem read GetItem; default;
  end;

implementation

{ TRadixLevelTable<T> }

function TRadixLevelTable<T>.GetItem(AIndex: Integer): PItem;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise ERangeError.CreateFmt('Index %d of %d', [AIndex, FCount]);
  Result := @FItems[AIndex];
end;

function TRadixLevelTable<T>.Add(const AItem: T): Integer;
begin
  if FCount = Length(FItems) then
    SetLength(FItems, FCount * 2 + 16);
  FItems[FCount] := AItem;
  Result := FCount;
  Inc(FCount);
end;

function TRadixLevelTable<T>.ToBytes: TBytes;
begin
  SetLength(Result, FCount * SizeOf(T));
  if FCount > 0 then
    Move(FItems[0], Result[0], Length(Result));
end;

end.
