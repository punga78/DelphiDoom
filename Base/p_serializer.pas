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
    st_string
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
    TSerializerFieldKind.Text
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