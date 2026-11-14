//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Base binary serializer: the facade of the serializer library (DelphiDoom.Serializer.*)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_serializer;

interface

uses
  d_delphi,
  DelphiDoom.Serializer.Intf;

type
  // The order is the one of TSerializerFieldKind of the library
  serializetype_t = (
    st_generic,
    st_byte,
    st_shortint,
    st_word,
    st_smallint,
    st_longword,
    st_integer,
    st_int64,
    st_float,
    st_state,
    st_mobj,
    st_player,
    st_string,
    st_nativeint // as wide as a pointer in the record, 4 bytes in the saved game (issue #40)
  );

//==============================================================================
//
// P_ConfigureSerializer
//
// The factory of the serializers (the library): ComposeEngine gives it, before
// the first TSerializer is created
//
//==============================================================================
procedure P_ConfigureSerializer(const AFactory: ISerializerFactory);

//==============================================================================
//
// P_ConfigureSaveRecords
//
// The layouts on disk of the records that the saved games keep "raw" (the whole
// record: players, thinkers of the sectors, the old formats of the mobjs).
// ComposeEngine gives them. On disk a record is what the 32 bit program has in
// memory (a pointer is 4 bytes), whatever the program that writes or reads it:
// a game saved by the 32 bit program is read by the 64 bit one and back.
//
//==============================================================================
procedure P_ConfigureSaveRecords(const ALayouts: IDiskLayouts; const AWriter: IDiskRecordWriter);

//==============================================================================
//
// P_SaveRecords
//
//==============================================================================
function P_SaveRecords: IDiskLayouts;

//==============================================================================
//
// P_RecordDiskSize
//
// typ is TypeInfo(the record). The bytes of the record in a saved game.
//
//==============================================================================
function P_RecordDiskSize(const typ: pointer): integer;

//==============================================================================
//
// P_PackRecord
//
// Writes the record rec as it lies in a saved game (P_RecordDiskSize bytes)
//
//==============================================================================
procedure P_PackRecord(const typ: pointer; const rec: pointer; const disk: pointer);

//==============================================================================
//
// P_UnpackRecord
//
// Reads the record rec from the bytes of a saved game. A value that is a pointer
// in memory comes back with its sign (-1 stays -1).
//
//==============================================================================
procedure P_UnpackRecord(const typ: pointer; const disk: pointer; const rec: pointer);

//==============================================================================
//
// P_PutRecord
//
// P_PackRecord at buf, then buf moves after the record
//
//==============================================================================
procedure P_PutRecord(var buf: pointer; const typ: pointer; const rec: pointer);

//==============================================================================
//
// P_GetRecord
//
// P_UnpackRecord from buf, then buf moves after the record
//
//==============================================================================
procedure P_GetRecord(var buf: pointer; const typ: pointer; const rec: pointer);

//==============================================================================
//
// P_ReserveRecord
//
// For the code that copies a record into the buffer and then changes the pointers
// of the copy into numbers: gives a copy of src in memory (to change) and keeps
// its place at buf, which moves after the record. P_CommitRecords writes the
// copies to their places: call it before the buffer is used.
//
//==============================================================================
function P_ReserveRecord(var buf: pointer; const typ: pointer; const src: pointer): pointer;

//==============================================================================
//
// P_CommitRecords
//
//==============================================================================
procedure P_CommitRecords;

//==============================================================================
//
// P_UnpackRecordPrefix
//
// Reads the record of an old version of the saved games (oldtyp) over the start
// of the record of today (typ), as the engine has always done with a memcpy: the
// old record is the start of the new one in a saved game, that is in the memory
// of the 32 bit program, but not always in the memory of the 64 bit one.
//
//==============================================================================
procedure P_UnpackRecordPrefix(const typ: pointer; const disk: pointer; const rec: pointer; const oldtyp: pointer);

//==============================================================================
//
// P_GetRecordPrefix
//
// P_UnpackRecordPrefix from buf, then buf moves after the old record
//
//==============================================================================
procedure P_GetRecordPrefix(var buf: pointer; const typ: pointer; const rec: pointer; const oldtyp: pointer);

type
  TSerializer = class(TObject)
  private
    fserializer: ISerializer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    procedure AddItem(const offs: Pointer; const size: integer; const lproc: PPointerParmProcedure = nil);
    procedure AddStringItem(const offs: Pointer; const def: string; const lproc: PPointerParmProcedure = nil);
    procedure AddFloatItem(const offs: Pointer; const def: float; const lproc: PPointerParmProcedure = nil);
    procedure AddTypedItem(const offs: Pointer; const typ: serializetype_t; const def: int64; const lproc: PPointerParmProcedure = nil);
    function SaveToMem(const mem, struct: Pointer; const maxsize: integer): integer;
    function SaveToStream(const strm: TDStream; const struct: Pointer; const maxsize: integer): integer;
    function LoadFromMem(const mem, struct: Pointer; const maxsize: integer): integer;
    function LoadFromStream(const strm: TDStream; const struct: Pointer; const maxsize: integer): integer;
    procedure ResolvePointers(const struct: Pointer);
  end;

implementation

uses
  DelphiDoom.Serializer.Types,
  DelphiDoom.Engine.Serializer.Stream,
  i_system;

var
  serializerfactory: ISerializerFactory = nil;

const
  SERIALIZERKINDS: array[serializetype_t] of TSerializerFieldKind = (
    TSerializerFieldKind.Generic,
    TSerializerFieldKind.UnsignedByte,
    TSerializerFieldKind.SignedByte,
    TSerializerFieldKind.UnsignedWord,
    TSerializerFieldKind.SignedWord,
    TSerializerFieldKind.UnsignedLong,
    TSerializerFieldKind.SignedLong,
    TSerializerFieldKind.SignedQuad,
    TSerializerFieldKind.Float,
    TSerializerFieldKind.State,
    TSerializerFieldKind.Mobj,
    TSerializerFieldKind.Player,
    TSerializerFieldKind.Text,
    TSerializerFieldKind.NativeInteger
  );

//==============================================================================
//
// P_ConfigureSerializer
//
//==============================================================================
procedure P_ConfigureSerializer(const AFactory: ISerializerFactory);
begin
  serializerfactory := AFactory;
end;

var
  saverecords: IDiskLayouts = nil;
  saverecordwriter: IDiskRecordWriter = nil;

//==============================================================================
//
// P_ConfigureSaveRecords
//
//==============================================================================
procedure P_ConfigureSaveRecords(const ALayouts: IDiskLayouts; const AWriter: IDiskRecordWriter);
begin
  saverecords := ALayouts;
  saverecordwriter := AWriter;
end;

//==============================================================================
//
// P_SaveRecords
//
//==============================================================================
function P_SaveRecords: IDiskLayouts;
begin
  if saverecords = nil then
    I_Error('P_SaveRecords(): the layouts of the saved records were not configured (P_ConfigureSaveRecords)');
  result := saverecords;
end;

//==============================================================================
//
// P_RecordLayout
//
//==============================================================================
function P_RecordLayout(const typ: pointer): IDiskLayout;
begin
  result := nil;
  try
    result := P_SaveRecords.LayoutOf(typ);
  except
    on E: ESerializerException do
      I_Error('P_RecordLayout(): %s', [E.Message]);
  end;
end;

//==============================================================================
//
// P_RecordDiskSize
//
//==============================================================================
function P_RecordDiskSize(const typ: pointer): integer;
begin
  result := P_RecordLayout(typ).DiskSize;
end;

//==============================================================================
//
// P_PackRecord
//
//==============================================================================
procedure P_PackRecord(const typ: pointer; const rec: pointer; const disk: pointer);
begin
  P_RecordLayout(typ).Pack(rec, disk);
end;

//==============================================================================
//
// P_UnpackRecord
//
//==============================================================================
procedure P_UnpackRecord(const typ: pointer; const disk: pointer; const rec: pointer);
begin
  P_RecordLayout(typ).Unpack(disk, rec);
end;

//==============================================================================
//
// P_PutRecord
//
//==============================================================================
procedure P_PutRecord(var buf: pointer; const typ: pointer; const rec: pointer);
var
  layout: IDiskLayout;
begin
  layout := P_RecordLayout(typ);
  layout.Pack(rec, buf);
  buf := pointer(NativeUInt(buf) + NativeUInt(layout.DiskSize));
end;

//==============================================================================
//
// P_GetRecord
//
//==============================================================================
procedure P_GetRecord(var buf: pointer; const typ: pointer; const rec: pointer);
var
  layout: IDiskLayout;
begin
  layout := P_RecordLayout(typ);
  layout.Unpack(buf, rec);
  buf := pointer(NativeUInt(buf) + NativeUInt(layout.DiskSize));
end;

//==============================================================================
//
// P_ReserveRecord
//
//==============================================================================
function P_ReserveRecord(var buf: pointer; const typ: pointer; const src: pointer): pointer;
begin
  if saverecordwriter = nil then
    I_Error('P_ReserveRecord(): the layouts of the saved records were not configured (P_ConfigureSaveRecords)');
  result := saverecordwriter.Reserve(P_RecordLayout(typ), src, buf);
end;

//==============================================================================
//
// P_CommitRecords
//
//==============================================================================
procedure P_CommitRecords;
begin
  if saverecordwriter <> nil then
    saverecordwriter.Commit;
end;

//==============================================================================
//
// P_UnpackRecordPrefix
//
//==============================================================================
procedure P_UnpackRecordPrefix(const typ: pointer; const disk: pointer; const rec: pointer; const oldtyp: pointer);
begin
  P_RecordLayout(typ).UnpackPrefix(disk, rec, P_RecordLayout(oldtyp).DiskSize);
end;

//==============================================================================
//
// P_GetRecordPrefix
//
//==============================================================================
procedure P_GetRecordPrefix(var buf: pointer; const typ: pointer; const rec: pointer; const oldtyp: pointer);
var
  size: integer;
begin
  size := P_RecordLayout(oldtyp).DiskSize;
  P_RecordLayout(typ).UnpackPrefix(buf, rec, size);
  buf := pointer(NativeUInt(buf) + NativeUInt(size));
end;

//==============================================================================
//
// WrapLoadProc
//
//==============================================================================
function WrapLoadProc(const lproc: PPointerParmProcedure): TSerializerLoadedProc;
begin
  if not Assigned(lproc) then
  begin
    Result := nil;
    exit;
  end;
  Result :=
    procedure(const AStruct: Pointer)
    begin
      lproc(AStruct);
    end;
end;

//==============================================================================
//
// TSerializer.Create
//
//==============================================================================
constructor TSerializer.Create;
begin
  if not Assigned(serializerfactory) then
    I_Error('TSerializer.Create(): the serializer is not configured (ComposeEngine has not run)');
  fserializer := serializerfactory.CreateSerializer;
  inherited Create;
end;

//==============================================================================
//
// TSerializer.Destroy
//
//==============================================================================
destructor TSerializer.Destroy;
begin
  fserializer := nil;
  inherited;
end;

//==============================================================================
//
// TSerializer.Clear
//
//==============================================================================
procedure TSerializer.Clear;
begin
  fserializer.Clear;
end;

//==============================================================================
//
// TSerializer.AddItem
//
//==============================================================================
procedure TSerializer.AddItem(const offs: Pointer; const size: integer; const lproc: PPointerParmProcedure = nil);
begin
  fserializer.AddGeneric(NativeInt(offs), size, WrapLoadProc(lproc));
end;

//==============================================================================
//
// TSerializer.AddStringItem
//
//==============================================================================
procedure TSerializer.AddStringItem(const offs: Pointer; const def: string; const lproc: PPointerParmProcedure = nil);
begin
  fserializer.AddText(NativeInt(offs), AnsiString(def), WrapLoadProc(lproc));
end;

//==============================================================================
//
// TSerializer.AddFloatItem
//
//==============================================================================
procedure TSerializer.AddFloatItem(const offs: Pointer; const def: float; const lproc: PPointerParmProcedure = nil);
begin
  fserializer.AddFloat(NativeInt(offs), def, WrapLoadProc(lproc));
end;

//==============================================================================
//
// TSerializer.AddTypedItem
//
//==============================================================================
procedure TSerializer.AddTypedItem(const offs: Pointer; const typ: serializetype_t; const def: int64; const lproc: PPointerParmProcedure = nil);
begin
  fserializer.AddTyped(NativeInt(offs), SERIALIZERKINDS[typ], def, WrapLoadProc(lproc));
end;

//==============================================================================
//
// TSerializer.SaveToMem
//
//==============================================================================
function TSerializer.SaveToMem(const mem, struct: Pointer; const maxsize: integer): integer;
begin
  result := fserializer.SaveToMemory(mem, struct, maxsize);
end;

//==============================================================================
//
// TSerializer.SaveToStream
//
//==============================================================================
function TSerializer.SaveToStream(const strm: TDStream; const struct: Pointer; const maxsize: integer): integer;
var
  adapter: TEngineSerializerStream;
begin
  adapter := TEngineSerializerStream.Create(strm);
  try
    result := fserializer.SaveToStream(adapter, struct);
  finally
    adapter.Free;
  end;
end;

//==============================================================================
//
// TSerializer.LoadFromMem
//
//==============================================================================
function TSerializer.LoadFromMem(const mem, struct: Pointer; const maxsize: integer): integer;
begin
  result := fserializer.LoadFromMemory(mem, struct, maxsize);
end;

//==============================================================================
//
// TSerializer.LoadFromStream
//
//==============================================================================
function TSerializer.LoadFromStream(const strm: TDStream; const struct: Pointer; const maxsize: integer): integer;
var
  adapter: TEngineSerializerStream;
begin
  adapter := TEngineSerializerStream.Create(strm);
  try
    result := fserializer.LoadFromStream(adapter, struct);
  finally
    adapter.Free;
  end;
end;

//==============================================================================
//
// TSerializer.ResolvePointers
//
//==============================================================================
procedure TSerializer.ResolvePointers(const struct: Pointer);
begin
  fserializer.ResolvePointers(struct);
end;

end.