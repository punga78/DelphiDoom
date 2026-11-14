{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelLumpReader                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of P_LoadRadixSprites, P_LoadRadixTriggers, P_LoadGrid, P_LoadMapGrid  }
{  and of the extra data of P_LoadThings (p_setup.pas of Rad-X) and of         }
{  RX_InitRadixGrid (radix_grid.pas): the lumps of Radix of a level            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.LevelLumps.Reader;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types;

type
  /// <summary>
  ///   Copies the records of RACTION, RTRIGGER, RGRID, RMAPGRID and RTHINGS out of the bytes of
  ///   their lumps, in the layout that TRadixLevelConverter writes. The old code used the lump in
  ///   place and cut a short one without a word; here a lump that is not made of whole records is
  ///   an error
  /// </summary>
  TRadixLevelLumpReader = class(TInterfacedObject, IRadixLevelLumpReader)
  strict private
    class function RecordCount(const ABytes: TBytes; ARecordSize: Integer; const ALump: string): Integer; static;
  public
    function ReadActions(const ABytes: TBytes): TArray<TRadixLevelAction>;
    function ReadTriggers(const ABytes: TBytes): TArray<TRadixLevelTrigger>;
    function ReadGrid(const ABytes: TBytes): TRadixTriggerGridData;
    function ReadMapPoints(const ABytes: TBytes): TArray<TRadixLevelMapPoint>;
    function ReadThingExtras(const ABytes: TBytes): TArray<TRadixDoomThingExtra>;
  end;

implementation

uses
  DelphiDoom.Radix.Types;

const
  SBadLumpSize = 'The lump %s has %d bytes: it is not made of records of %d bytes';
  SBadGridLumpSize = 'The lump %s has %d bytes instead of %d';
  SBadGridSize = 'The lump RGRID has a grid of %d x %d cells instead of %d cells';
  SBadActionCount = 'The trigger %d of RTRIGGER has %d actions (at most %d)';

  ACTION_LUMP = 'RACTION';
  TRIGGER_LUMP = 'RTRIGGER';
  GRID_LUMP = 'RGRID';
  MAP_POINT_LUMP = 'RMAPGRID';
  THING_LUMP = 'RTHINGS';

{ TRadixLevelLumpReader }

class function TRadixLevelLumpReader.RecordCount(const ABytes: TBytes; ARecordSize: Integer;
  const ALump: string): Integer;
begin
  if Length(ABytes) mod ARecordSize <> 0 then
    raise ERadixException.CreateFmt(SBadLumpSize, [ALump, Length(ABytes), ARecordSize]);
  Result := Length(ABytes) div ARecordSize;
end;

function TRadixLevelLumpReader.ReadActions(const ABytes: TBytes): TArray<TRadixLevelAction>;
begin
  SetLength(Result, RecordCount(ABytes, SizeOf(TRadixLevelAction), ACTION_LUMP));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(ABytes));
end;

function TRadixLevelLumpReader.ReadTriggers(const ABytes: TBytes): TArray<TRadixLevelTrigger>;
var
  LIndex: Integer;
begin
  SetLength(Result, RecordCount(ABytes, SizeOf(TRadixLevelTrigger), TRIGGER_LUMP));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(ABytes));
  // the game walks the actions of a trigger by this count
  for LIndex := 0 to High(Result) do
    if (Result[LIndex].NumActions < 0) or (Result[LIndex].NumActions > RADIX_MAX_TRIGGER_ACTIONS) then
      raise ERadixException.CreateFmt(SBadActionCount, [LIndex, Result[LIndex].NumActions,
        RADIX_MAX_TRIGGER_ACTIONS]);
end;

function TRadixLevelLumpReader.ReadGrid(const ABytes: TBytes): TRadixTriggerGridData;
var
  LIndex: Integer;
  LHeader: packed record
    X: Integer;
    Y: Integer;
  end;
begin
  SetLength(Result.Cells, RADIX_GRID_SIZE);
  if Length(ABytes) = 0 then
  begin
    Result.Width := 0;
    Result.Height := 0;
    for LIndex := 0 to RADIX_GRID_SIZE - 1 do
      Result.Cells[LIndex] := RADIX_NO_TRIGGER;
    Exit;
  end;
  if Length(ABytes) <> SizeOf(TRadixLevelGrid) then
    raise ERadixException.CreateFmt(SBadGridLumpSize, [GRID_LUMP, Length(ABytes), SizeOf(TRadixLevelGrid)]);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if (LHeader.X < 0) or (LHeader.Y < 0) or
    ((Int64(LHeader.X) * LHeader.Y <> 0) and (Int64(LHeader.X) * LHeader.Y <> RADIX_GRID_SIZE)) then
    raise ERadixException.CreateFmt(SBadGridSize, [LHeader.X, LHeader.Y, RADIX_GRID_SIZE]);
  Result.Width := LHeader.X;
  Result.Height := LHeader.Y;
  Move(ABytes[SizeOf(LHeader)], Result.Cells[0], RADIX_GRID_SIZE * SizeOf(SmallInt));
end;

function TRadixLevelLumpReader.ReadMapPoints(const ABytes: TBytes): TArray<TRadixLevelMapPoint>;
begin
  SetLength(Result, RADIX_GRID_SIZE);
  if Length(ABytes) = 0 then
    Exit;
  if Length(ABytes) <> SizeOf(TRadixLevelMapPoints) then
    raise ERadixException.CreateFmt(SBadGridLumpSize, [MAP_POINT_LUMP, Length(ABytes),
      SizeOf(TRadixLevelMapPoints)]);
  Move(ABytes[0], Result[0], Length(ABytes));
end;

function TRadixLevelLumpReader.ReadThingExtras(const ABytes: TBytes): TArray<TRadixDoomThingExtra>;
begin
  SetLength(Result, RecordCount(ABytes, SizeOf(TRadixDoomThingExtra), THING_LUMP));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(ABytes));
end;

end.
