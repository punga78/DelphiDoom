{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the slots of the active ceilings and platforms}
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.ActiveSlots;

interface

type
  /// <summary>
  ///   A fixed number of slots for the thinkers of the same kind that can be stopped and
  ///   started again (activeceilings, activeplats and their UDMF twins): a free slot is nil
  /// </summary>
  /// <remarks>
  ///   The slots are not written in the saved games: the loader puts every thinker back with
  ///   Add, and the writer asks Contains. The order of the slots is the order of the scans of
  ///   the old arrays (the first free slot takes the new thinker). The items are opaque
  ///   pointers: the library does not know the records of the engine. No method is virtual
  /// </remarks>
  TActiveSlots = class sealed
  strict private
    FItems: array of Pointer;
    function GetCapacity: Integer;
    function GetItem(const AIndex: Integer): Pointer;
  public
    /// <param name="ACapacity">The number of slots</param>
    /// <exception cref="EArgumentOutOfRangeException">ACapacity is not positive</exception>
    constructor Create(const ACapacity: Integer);

    /// <summary>Puts a thinker in the first free slot</summary>
    /// <returns>False if every slot is taken</returns>
    function Add(const AItem: Pointer): Boolean;
    /// <summary>Frees the slot of a thinker (the thinker is not touched)</summary>
    /// <returns>False if the thinker is not in the slots</returns>
    function Remove(const AItem: Pointer): Boolean;
    /// <summary>The slot of a thinker, -1 if it is not in the slots (nil never is)</summary>
    function IndexOf(const AItem: Pointer): Integer;
    /// <summary>True if the thinker is in a slot</summary>
    function Contains(const AItem: Pointer): Boolean;
    /// <summary>Frees the slot at an index (the thinker is not touched)</summary>
    /// <exception cref="EArgumentOutOfRangeException">The index is out of range</exception>
    procedure Release(const AIndex: Integer);
    /// <summary>Frees every slot (a new level)</summary>
    procedure Clear;

    property Capacity: Integer read GetCapacity;
    /// <summary>The thinker of a slot, nil if it is free</summary>
    property Items[const AIndex: Integer]: Pointer read GetItem; default;
  end;

implementation

uses
  System.SysUtils;

{ TActiveSlots }

constructor TActiveSlots.Create(const ACapacity: Integer);
begin
  inherited Create;
  if ACapacity <= 0 then
    raise EArgumentOutOfRangeException.Create('ACapacity');
  SetLength(FItems, ACapacity);
end;

function TActiveSlots.GetCapacity: Integer;
begin
  Result := Length(FItems);
end;

function TActiveSlots.GetItem(const AIndex: Integer): Pointer;
begin
  Result := FItems[AIndex];
end;

function TActiveSlots.Add(const AItem: Pointer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to High(FItems) do
    if FItems[LIndex] = nil then
    begin
      FItems[LIndex] := AItem;
      Result := True;
      Break;
    end;
end;

function TActiveSlots.Remove(const AItem: Pointer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AItem);
  Result := LIndex >= 0;
  if Result then
    FItems[LIndex] := nil;
end;

function TActiveSlots.IndexOf(const AItem: Pointer): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  // a free slot is not a thinker
  if AItem = nil then
    Exit;
  for LIndex := 0 to High(FItems) do
    if FItems[LIndex] = AItem then
    begin
      Result := LIndex;
      Break;
    end;
end;

function TActiveSlots.Contains(const AItem: Pointer): Boolean;
begin
  Result := IndexOf(AItem) >= 0;
end;

procedure TActiveSlots.Release(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FItems)) then
    raise EArgumentOutOfRangeException.Create('AIndex');
  FItems[AIndex] := nil;
end;

procedure TActiveSlots.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FItems) do
    FItems[LIndex] := nil;
end;

end.
