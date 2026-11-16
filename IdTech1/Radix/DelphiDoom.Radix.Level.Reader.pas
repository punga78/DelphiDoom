{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelReader                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the reading part of RX_CreateDoomLevel of radix_level.pas           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Reader;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data,
  DelphiDoom.Radix.Level.Intf;

type
  TRadixLevelReader = class(TInterfacedObject, IRadixLevelReader)
  strict private
    type
      TCursor = class
      strict private
        FBytes: TBytes;
        FPosition: Integer;
        FName: string;
      public
        constructor Create(const AName: string; const ABytes: TBytes);
        procedure Read(var ABuffer; ASize: Integer);
        procedure Seek(APosition: Integer);
        function ReadSmallInt: SmallInt;
      end;
    class procedure ReadGrid(const ACursor: TCursor; AOrthogonal: Boolean;
      out AWidth, AHeight: Integer; var ACells: array of SmallInt); static;
    class procedure ReadActions(const ACursor: TCursor; const ALevel: TRadixLevelData); static;
    class procedure ReadTriggers(const ACursor: TCursor; const ALevel: TRadixLevelData); static;
  public
    function TryRead(const AName: string; const ABytes: TBytes): TRadixLevelData;
  end;

implementation

{ TRadixLevelReader.TCursor }

constructor TRadixLevelReader.TCursor.Create(const AName: string; const ABytes: TBytes);
begin
  inherited Create;
  FName := AName;
  FBytes := ABytes;
end;

procedure TRadixLevelReader.TCursor.Read(var ABuffer; ASize: Integer);
begin
  if ASize <= 0 then
    Exit;
  if FPosition + ASize > Length(FBytes) then
    raise ERadixException.CreateFmt(SRadixLevelTruncated, [FName]);
  Move(FBytes[FPosition], ABuffer, ASize);
  Inc(FPosition, ASize);
end;

procedure TRadixLevelReader.TCursor.Seek(APosition: Integer);
begin
  if (APosition < 0) or (APosition > Length(FBytes)) then
    raise ERadixException.CreateFmt(SRadixLevelTruncated, [FName]);
  FPosition := APosition;
end;

function TRadixLevelReader.TCursor.ReadSmallInt: SmallInt;
begin
  Read(Result, SizeOf(SmallInt));
end;

{ TRadixLevelReader }

// A grid is 320 x 128 (orthogonal map) or 1280 x 32 cells of a word; -32000 starts a run
// (value, count). A run may go past the end of a row, as it did in the old code (the cells follow).
class procedure TRadixLevelReader.ReadGrid(const ACursor: TCursor; AOrthogonal: Boolean;
  out AWidth, AHeight: Integer; var ACells: array of SmallInt);
var
  LX: Integer;
  LY: Integer;
  LValue: SmallInt;
  LCount: SmallInt;
  LRun: Integer;
  LIndex: Integer;
begin
  if AOrthogonal then
  begin
    AWidth := 320;
    AHeight := 128;
  end
  else
  begin
    AWidth := 1280;
    AHeight := 32;
  end;
  FillChar(ACells[0], Length(ACells) * SizeOf(SmallInt), 0);
  for LY := 0 to AHeight - 1 do
  begin
    LX := 0;
    repeat
      LValue := ACursor.ReadSmallInt;
      if LValue = -32000 then
      begin
        LValue := ACursor.ReadSmallInt;
        LCount := ACursor.ReadSmallInt;
        for LRun := 0 to LCount - 1 do
        begin
          LIndex := LY * AWidth + LX;
          if (LIndex >= 0) and (LIndex < Length(ACells)) then
            ACells[LIndex] := LValue;
          Inc(LX);
        end;
      end
      else
      begin
        LIndex := LY * AWidth + LX;
        if (LIndex >= 0) and (LIndex < Length(ACells)) then
          ACells[LIndex] := LValue;
        Inc(LX);
      end;
    until LX >= AWidth;
  end;
end;

// The parameters follow the first 40 bytes and may be more than the record has: the old code
// wrote them over the next record, which the next read starts to overwrite. Here the records are
// in one buffer, so the bytes go where they went.
class procedure TRadixLevelReader.ReadActions(const ACursor: TCursor; const ALevel: TRadixLevelData);
var
  LBuffer: TBytes;
  LIndex: Integer;
  LExtra: Integer;
  LOffset: Integer;
begin
  SetLength(LBuffer, Length(ALevel.Actions) * SizeOf(TRadixLevelAction) + 4096);
  for LIndex := 0 to High(ALevel.Actions) do
  begin
    LOffset := LIndex * SizeOf(TRadixLevelAction);
    ACursor.Read(LBuffer[LOffset], RADIX_ACTION_HEADER_SIZE);
    LExtra := SmallInt(Word(LBuffer[LOffset + 28]) or (Word(LBuffer[LOffset + 29]) shl 8));
    if (LExtra < 0) or (LExtra > 4096) then
      raise ERadixException.CreateFmt(SRadixLevelBadAction, [ALevel.Name, LExtra]);
    ACursor.Read(LBuffer[LOffset + RADIX_ACTION_HEADER_SIZE], LExtra);
  end;
  if Length(ALevel.Actions) > 0 then
    Move(LBuffer[0], ALevel.Actions[0], Length(ALevel.Actions) * SizeOf(TRadixLevelAction));
end;

class procedure TRadixLevelReader.ReadTriggers(const ACursor: TCursor; const ALevel: TRadixLevelData);
var
  LBuffer: TBytes;
  LIndex: Integer;
  LCount: Integer;
  LOffset: Integer;
begin
  SetLength(LBuffer, Length(ALevel.Triggers) * SizeOf(TRadixLevelTrigger) + 8192);
  for LIndex := 0 to High(ALevel.Triggers) do
  begin
    LOffset := LIndex * SizeOf(TRadixLevelTrigger);
    ACursor.Read(LBuffer[LOffset], RADIX_TRIGGER_HEADER_SIZE);
    LCount := PInteger(@LBuffer[LOffset + 28])^;
    if (LCount < 0) or (LCount > 600) then
      raise ERadixException.CreateFmt(SRadixLevelBadAction, [ALevel.Name, LCount]);
    ACursor.Read(LBuffer[LOffset + RADIX_TRIGGER_HEADER_SIZE], LCount * SizeOf(TRadixLevelTriggerAction));
  end;
  if Length(ALevel.Triggers) > 0 then
    Move(LBuffer[0], ALevel.Triggers[0], Length(ALevel.Triggers) * SizeOf(TRadixLevelTrigger));
end;

function TRadixLevelReader.TryRead(const AName: string; const ABytes: TBytes): TRadixLevelData;
var
  LCursor: TCursor;
  LHeader: TRadixLevelHeader;
  LSkipped: array[0..RADIX_GRID_SIZE - 1] of SmallInt;
  LWidth: Integer;
  LHeight: Integer;
  LCounts: TArray<Integer>;
  LIndex: Integer;
begin
  Result := nil;
  if Length(ABytes) < SizeOf(TRadixLevelHeader) then
    Exit;
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Id <> RADIX_MAP_MAGIC then
    Exit;
  LCounts := [LHeader.NumSectors, LHeader.NumWalls, LHeader.NumThings, LHeader.NumActions,
    LHeader.NumTriggers];
  for LIndex := 0 to High(LCounts) do
    if (LCounts[LIndex] < 0) or (LCounts[LIndex] > Length(ABytes)) then
      raise ERadixException.CreateFmt(SRadixLevelTruncated, [AName]);

  Result := TRadixLevelData.Create;
  try
    Result.Name := AName;
    Result.Header := LHeader;
    LCursor := TCursor.Create(AName, ABytes);
    try
      LCursor.Seek(SizeOf(TRadixLevelHeader));
      SetLength(Result.Sectors, LHeader.NumSectors);
      SetLength(Result.Walls, LHeader.NumWalls);
      SetLength(Result.Things, LHeader.NumThings);
      SetLength(Result.Actions, LHeader.NumActions);
      SetLength(Result.Triggers, LHeader.NumTriggers);
      if LHeader.NumSectors > 0 then
        LCursor.Read(Result.Sectors[0], LHeader.NumSectors * SizeOf(TRadixLevelSector));
      if LHeader.NumWalls > 0 then
        LCursor.Read(Result.Walls[0], LHeader.NumWalls * SizeOf(TRadixLevelWall));
      // the first grid is the blocking of the lines: not used by the engine, it only moves the position
      ReadGrid(LCursor, LHeader.OrthogonalMap <> 0, LWidth, LHeight, LSkipped);
      if LHeader.NumThings > 0 then
        LCursor.Read(Result.Things[0], LHeader.NumThings * SizeOf(TRadixLevelThing));
      ReadGrid(LCursor, LHeader.OrthogonalMap <> 0, Result.GridWidth, Result.GridHeight,
        Result.TriggerGrid.Cells);
      Result.TriggerGrid.X := Result.GridWidth;
      Result.TriggerGrid.Y := Result.GridHeight;
      ReadActions(LCursor, Result);
      ReadTriggers(LCursor, Result);
      LCursor.Seek(LHeader.PlayerStartOffsets);
      LCursor.Read(Result.PlayerStarts, SizeOf(Result.PlayerStarts));
    finally
      LCursor.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
