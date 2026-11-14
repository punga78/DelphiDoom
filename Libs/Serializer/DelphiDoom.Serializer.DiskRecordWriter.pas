{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the raw records being written              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.DiskRecordWriter;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Serializer.Intf;

type
  /// <summary>
  ///   The engine saves a thinker by copying it into the buffer of the saved game and then changing, in
  ///   the copy, the pointers into numbers (the index of the sector, of the line...). The copy in the
  ///   buffer has the layout on disk, where a pointer is 4 bytes, so the engine cannot work on it. Reserve
  ///   gives a copy in memory to work on and keeps its place in the buffer; Commit writes every copy to
  ///   its place. Nothing must read the places before Commit
  /// </summary>
  TDiskRecordWriter = class(TInterfacedObject, IDiskRecordWriter)
  strict private
    type
      TPending = record
        Layout: IDiskLayout;
        Copy: Pointer;
        Disk: Pointer;
      end;
  strict private
    FPending: TList<TPending>;
    function GetPendingCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   A copy of the record ASource to change; its place is ADisk, which moves after the record. The copy
    ///   lives until Commit
    /// </summary>
    function Reserve(const ALayout: IDiskLayout; const ASource: Pointer; var ADisk: Pointer): Pointer;
    /// <summary>Writes the copies to their places and frees them</summary>
    procedure Commit;
    property PendingCount: Integer read GetPendingCount;
  end;

implementation

uses
  System.SysUtils;

{ TDiskRecordWriter }

constructor TDiskRecordWriter.Create;
begin
  inherited Create;
  FPending := TList<TPending>.Create;
end;

destructor TDiskRecordWriter.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FPending.Count - 1 do
    FreeMem(FPending[LIndex].Copy);
  FPending.Free;
  inherited Destroy;
end;

function TDiskRecordWriter.GetPendingCount: Integer;
begin
  Result := FPending.Count;
end;

function TDiskRecordWriter.Reserve(const ALayout: IDiskLayout; const ASource: Pointer;
  var ADisk: Pointer): Pointer;
var
  LPending: TPending;
begin
  if not Assigned(ALayout) then
    raise EArgumentNilException.Create('ALayout');
  GetMem(Result, ALayout.NativeSize);
  Move(ASource^, Result^, ALayout.NativeSize);
  LPending.Layout := ALayout;
  LPending.Copy := Result;
  LPending.Disk := ADisk;
  FPending.Add(LPending);
  ADisk := PByte(ADisk) + ALayout.DiskSize;
end;

procedure TDiskRecordWriter.Commit;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FPending.Count - 1 do
  begin
    FPending[LIndex].Layout.Pack(FPending[LIndex].Copy, FPending[LIndex].Disk);
    FreeMem(FPending[LIndex].Copy);
  end;
  FPending.Clear;
end;

end.
