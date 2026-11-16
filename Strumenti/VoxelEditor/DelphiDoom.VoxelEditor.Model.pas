{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the cube of voxels                                }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>
  ///   The cube of a voxel (voxelbuffer_t of DD_VOXEL, which was always 256 x 256 x 256 and used the corner it
  ///   needed): size x size x size cells, each a color $00BBGGRR where 0 means "no voxel". The cell (x, y, z) is
  ///   Cells[(x * size + y) * size + z]
  /// </summary>
  TVoxelEditorModel = class
  strict private
    FSize: Integer;
    FCells: TArray<Cardinal>;
  public
    constructor Create(ASize: Integer);
    /// <summary>A new empty cube; the old cells are gone</summary>
    procedure Reset(ASize: Integer);
    procedure Clear;
    function IndexOf(AX, AY, AZ: Integer): Integer; inline;
    function Get(AX, AY, AZ: Integer): Cardinal; inline;
    procedure Put(AX, AY, AZ: Integer; AColor: Cardinal); inline;
    function CountVoxels: Integer;
    /// <summary>
    ///   The state of the cube as bytes, for the undo: the size, a mark, then each voxel as x, y, z (a byte each)
    ///   and its color (4 bytes), then an entry of zeros. It is what DD_VOXEL wrote for the undo of a whole cube
    /// </summary>
    function Snapshot: TBytes;
    /// <summary>The cube of a snapshot (its size is the one of the snapshot)</summary>
    procedure Restore(const ABytes: TBytes);
    procedure AssignFrom(const AOther: TVoxelEditorModel);
    class procedure CheckSize(ASize: Integer); static;
    property Size: Integer read FSize;
    property Cells: TArray<Cardinal> read FCells;
  end;

implementation

const
  SNAPSHOT_HEADER = 4;
  SNAPSHOT_ENTRY = 7;
  SNAPSHOT_MARK = Ord('a');

{ TVoxelEditorModel }

class procedure TVoxelEditorModel.CheckSize(ASize: Integer);
begin
  if (ASize < 1) or (ASize > VOXEL_EDITOR_MAX_SIZE) then
    raise EVoxelEditorException.CreateFmt(SVoxelEditorBadSize, [ASize]);
end;

constructor TVoxelEditorModel.Create(ASize: Integer);
begin
  inherited Create;
  Reset(ASize);
end;

procedure TVoxelEditorModel.Reset(ASize: Integer);
begin
  CheckSize(ASize);
  FSize := ASize;
  FCells := nil;
  SetLength(FCells, ASize * ASize * ASize);
  // SetLength does not clear the new cells of an array of numbers
  Clear;
end;

procedure TVoxelEditorModel.Clear;
begin
  if Length(FCells) > 0 then
    FillChar(FCells[0], Length(FCells) * SizeOf(Cardinal), 0);
end;

function TVoxelEditorModel.IndexOf(AX, AY, AZ: Integer): Integer;
begin
  Result := (AX * FSize + AY) * FSize + AZ;
end;

function TVoxelEditorModel.Get(AX, AY, AZ: Integer): Cardinal;
begin
  Result := FCells[(AX * FSize + AY) * FSize + AZ];
end;

procedure TVoxelEditorModel.Put(AX, AY, AZ: Integer; AColor: Cardinal);
begin
  FCells[(AX * FSize + AY) * FSize + AZ] := AColor;
end;

function TVoxelEditorModel.CountVoxels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FCells) do
    if FCells[LIndex] <> 0 then
      Inc(Result);
end;

procedure TVoxelEditorModel.AssignFrom(const AOther: TVoxelEditorModel);
begin
  if not Assigned(AOther) then
    raise EArgumentNilException.Create('AOther');
  FSize := AOther.FSize;
  FCells := Copy(AOther.FCells);
end;

function TVoxelEditorModel.Snapshot: TBytes;
var
  LX, LY, LZ, LPosition: Integer;
  LColor: Cardinal;
begin
  SetLength(Result, SNAPSHOT_HEADER + 1 + (CountVoxels + 1) * SNAPSHOT_ENTRY);
  PInteger(@Result[0])^ := FSize;
  Result[SNAPSHOT_HEADER] := SNAPSHOT_MARK;
  LPosition := SNAPSHOT_HEADER + 1;
  for LX := 0 to FSize - 1 do
    for LY := 0 to FSize - 1 do
      for LZ := 0 to FSize - 1 do
      begin
        LColor := Get(LX, LY, LZ);
        if LColor <> 0 then
        begin
          Result[LPosition] := LX;
          Result[LPosition + 1] := LY;
          Result[LPosition + 2] := LZ;
          PCardinal(@Result[LPosition + 3])^ := LColor;
          Inc(LPosition, SNAPSHOT_ENTRY);
        end;
      end;
  FillChar(Result[LPosition], SNAPSHOT_ENTRY, 0);
end;

procedure TVoxelEditorModel.Restore(const ABytes: TBytes);
var
  LSize, LPosition: Integer;
  LColor: Cardinal;
begin
  if (Length(ABytes) < SNAPSHOT_HEADER + 1 + SNAPSHOT_ENTRY) or (ABytes[SNAPSHOT_HEADER] <> SNAPSHOT_MARK) then
    raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, ['undo']);
  LSize := PInteger(@ABytes[0])^;
  Reset(LSize);
  LPosition := SNAPSHOT_HEADER + 1;
  while LPosition + SNAPSHOT_ENTRY <= Length(ABytes) do
  begin
    LColor := PCardinal(@ABytes[LPosition + 3])^;
    if LColor = 0 then
      Break;
    if (ABytes[LPosition] < LSize) and (ABytes[LPosition + 1] < LSize) and (ABytes[LPosition + 2] < LSize) then
      Put(ABytes[LPosition], ABytes[LPosition + 1], ABytes[LPosition + 2], LColor);
    Inc(LPosition, SNAPSHOT_ENTRY);
  end;
end;

end.
