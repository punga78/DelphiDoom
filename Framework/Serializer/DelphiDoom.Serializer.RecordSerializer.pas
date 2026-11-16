{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the table of fields and the stream         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.RecordSerializer;

interface

uses
  System.Classes, DelphiDoom.Serializer.Types, DelphiDoom.Serializer.Intf,
  DelphiDoom.Serializer.FieldCodec;

type
  /// <summary>
  ///   What the old TSerializer of the engine: the table of the fields of a record and the format of
  ///   the stream. The bytes written are the same as before, on 32 and on 64 bit
  /// </summary>
  TRecordSerializer = class(TInterfacedObject, ISerializer)
  strict private
    FCodec: TSerializerFieldCodec;
    FFields: TArray<TSerializerField>;
    function Append(AOffset: NativeInt; AKind: TSerializerFieldKind; ASize: Integer;
      const AOnLoaded: TSerializerLoadedProc): Integer;
  public
    constructor Create(const ACodec: TSerializerFieldCodec);
    destructor Destroy; override;
    procedure Clear;
    function GetCount: Integer;
    procedure AddGeneric(AOffset: NativeInt; ASize: Integer; const AOnLoaded: TSerializerLoadedProc = nil);
    procedure AddText(AOffset: NativeInt; const ADefault: AnsiString; const AOnLoaded: TSerializerLoadedProc = nil);
    procedure AddFloat(AOffset: NativeInt; ADefault: Single; const AOnLoaded: TSerializerLoadedProc = nil);
    procedure AddTyped(AOffset: NativeInt; AKind: TSerializerFieldKind; ADefault: Int64;
      const AOnLoaded: TSerializerLoadedProc = nil);
    function SaveToStream(const AStream: TStream; const AStruct: Pointer): Integer;
    function LoadFromStream(const AStream: TStream; const AStruct: Pointer): Integer;
    function SaveToMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
    function LoadFromMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
    procedure ResolvePointers(const AStruct: Pointer);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Serializer.MemoryStream;

{ TRecordSerializer }

constructor TRecordSerializer.Create(const ACodec: TSerializerFieldCodec);
begin
  inherited Create;
  if not Assigned(ACodec) then
    raise EArgumentNilException.Create('ACodec');
  FCodec := ACodec;
end;

destructor TRecordSerializer.Destroy;
begin
  FCodec.Free;
  inherited;
end;

procedure TRecordSerializer.Clear;
begin
  FFields := nil;
end;

function TRecordSerializer.GetCount: Integer;
begin
  Result := Length(FFields);
end;

function TRecordSerializer.Append(AOffset: NativeInt; AKind: TSerializerFieldKind; ASize: Integer;
  const AOnLoaded: TSerializerLoadedProc): Integer;
begin
  Result := Length(FFields);
  SetLength(FFields, Result + 1);
  FFields[Result].Id := Result + 1;
  FFields[Result].Offset := AOffset;
  FFields[Result].Kind := AKind;
  FFields[Result].Size := ASize;
  FFields[Result].IntegerDefault := 0;
  FFields[Result].FloatDefault := 0.0;
  FFields[Result].TextDefault := '';
  FFields[Result].OnLoaded := AOnLoaded;
end;

procedure TRecordSerializer.AddGeneric(AOffset: NativeInt; ASize: Integer; const AOnLoaded: TSerializerLoadedProc);
begin
  Append(AOffset, TSerializerFieldKind.Generic, ASize, AOnLoaded);
end;

procedure TRecordSerializer.AddText(AOffset: NativeInt; const ADefault: AnsiString;
  const AOnLoaded: TSerializerLoadedProc);
var
  LIndex: Integer;
begin
  LIndex := Append(AOffset, TSerializerFieldKind.Text, SERIALIZER_TEXT_CAPACITY, AOnLoaded);
  // a short string holds at most 255 characters
  FFields[LIndex].TextDefault := Copy(ADefault, 1, SERIALIZER_TEXT_CAPACITY);
end;

procedure TRecordSerializer.AddFloat(AOffset: NativeInt; ADefault: Single; const AOnLoaded: TSerializerLoadedProc);
var
  LIndex: Integer;
begin
  LIndex := Append(AOffset, TSerializerFieldKind.Float, SERIALIZER_FIELD_SIZES[TSerializerFieldKind.Float],
    AOnLoaded);
  FFields[LIndex].FloatDefault := ADefault;
end;

procedure TRecordSerializer.AddTyped(AOffset: NativeInt; AKind: TSerializerFieldKind; ADefault: Int64;
  const AOnLoaded: TSerializerLoadedProc);
var
  LIndex: Integer;
begin
  LIndex := Append(AOffset, AKind, SERIALIZER_FIELD_SIZES[AKind], AOnLoaded);
  FFields[LIndex].IntegerDefault := ADefault;
end;

function TRecordSerializer.SaveToStream(const AStream: TStream; const AStruct: Pointer): Integer;
var
  LStart: Int64;
  LEnd: Word;
  LIndex: Integer;
begin
  LStart := AStream.Position;
  for LIndex := 0 to High(FFields) do
    FCodec.Save(AStream, AStruct, FFields[LIndex]);
  LEnd := SERIALIZER_END_MARKER;
  AStream.WriteBuffer(LEnd, SizeOf(Word));
  Result := Integer(AStream.Position - LStart);
end;

function TRecordSerializer.LoadFromStream(const AStream: TStream; const AStruct: Pointer): Integer;
var
  LStart: Int64;
  LId: Word;
  LIndex: Integer;
begin
  LStart := AStream.Position;
  for LIndex := 0 to High(FFields) do
    FCodec.ApplyDefault(AStruct, FFields[LIndex]);
  while True do
  begin
    AStream.ReadBuffer(LId, SizeOf(Word));
    if LId = SERIALIZER_END_MARKER then
      Break;
    if LId > Length(FFields) then
      raise ESerializerException.CreateFmt(SSerializerUnknownFieldId, [LId, Length(FFields)]);
    FCodec.Load(AStream, AStruct, FFields[LId - 1]);
  end;
  Result := Integer(AStream.Position - LStart);
end;

function TRecordSerializer.SaveToMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
var
  LStream: TSerializerMemoryStream;
begin
  LStream := TSerializerMemoryStream.Create(AMemory, AMaxSize);
  try
    try
      Result := SaveToStream(LStream, AStruct);
    except
      on EWriteError do
        raise ESerializerException.CreateFmt(SSerializerBufferOverrun, [AMaxSize]);
    end;
  finally
    LStream.Free;
  end;
end;

function TRecordSerializer.LoadFromMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
var
  LStream: TSerializerMemoryStream;
begin
  LStream := TSerializerMemoryStream.Create(AMemory, AMaxSize);
  try
    Result := LoadFromStream(LStream, AStruct);
  finally
    LStream.Free;
  end;
end;

procedure TRecordSerializer.ResolvePointers(const AStruct: Pointer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FFields) do
    FCodec.Resolve(AStruct, FFields[LIndex]);
end;

end.
