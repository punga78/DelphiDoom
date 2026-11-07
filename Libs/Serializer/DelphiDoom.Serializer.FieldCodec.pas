{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - reading and writing one field              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.FieldCodec;

// Same arithmetic as the old serializer: defaults are compared after the promotion to Int64
// of the field, and an Int64 default is cut to the size of the field when it is applied
{$Q-}
{$R-}

interface

uses
  System.Classes, DelphiDoom.Serializer.Types, DelphiDoom.Serializer.Intf;

type
  /// <summary>
  ///   Writes a field, reads it, gives it its default, turns the raw numbers of the references
  ///   into pointers. The record is addressed as bytes: a field is AField.Offset bytes from its
  ///   start. A reference is a pointer in the record and a 32 bit number in the stream
  /// </summary>
  TSerializerFieldCodec = class
  strict private
    FStates: ISerializerStateResolver;
    FMobjs: ISerializerMobjResolver;
    FPlayers: ISerializerPlayerResolver;
    class function Slot(const AStruct: Pointer; const AField: TSerializerField): PByte; static; inline;
    class function IsZeroes(const ASlot: PByte; ASize: Integer): Boolean; static;
    class procedure WriteId(const AStream: TStream; const AField: TSerializerField); static;
    class procedure WriteValue(const AStream: TStream; const AField: TSerializerField; const ASlot: PByte); static;
  public
    constructor Create(const AStates: ISerializerStateResolver; const AMobjs: ISerializerMobjResolver;
      const APlayers: ISerializerPlayerResolver);
    /// <summary>Writes (field number, value) if the field is not at its default</summary>
    procedure Save(const AStream: TStream; const AStruct: Pointer; const AField: TSerializerField);
    /// <summary>Reads the value of a field, whose number has already been read, and tells the field</summary>
    procedure Load(const AStream: TStream; const AStruct: Pointer; const AField: TSerializerField);
    procedure ApplyDefault(const AStruct: Pointer; const AField: TSerializerField);
    procedure Resolve(const AStruct: Pointer; const AField: TSerializerField);
  end;

implementation

uses
  System.SysUtils;

{ TSerializerFieldCodec }

constructor TSerializerFieldCodec.Create(const AStates: ISerializerStateResolver;
  const AMobjs: ISerializerMobjResolver; const APlayers: ISerializerPlayerResolver);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AMobjs) then
    raise EArgumentNilException.Create('AMobjs');
  if not Assigned(APlayers) then
    raise EArgumentNilException.Create('APlayers');
  FStates := AStates;
  FMobjs := AMobjs;
  FPlayers := APlayers;
end;

class function TSerializerFieldCodec.Slot(const AStruct: Pointer; const AField: TSerializerField): PByte;
begin
  Result := PByte(AStruct) + AField.Offset;
end;

class function TSerializerFieldCodec.IsZeroes(const ASlot: PByte; ASize: Integer): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ASize - 1 do
    if ASlot[LIndex] <> 0 then
      Exit(False);
  Result := True;
end;

class procedure TSerializerFieldCodec.WriteId(const AStream: TStream; const AField: TSerializerField);
var
  LId: Word;
begin
  LId := AField.Id;
  AStream.WriteBuffer(LId, SizeOf(Word));
end;

class procedure TSerializerFieldCodec.WriteValue(const AStream: TStream; const AField: TSerializerField;
  const ASlot: PByte);
begin
  WriteId(AStream, AField);
  AStream.WriteBuffer(ASlot^, AField.Size);
end;

procedure TSerializerFieldCodec.Save(const AStream: TStream; const AStruct: Pointer;
  const AField: TSerializerField);
var
  LSlot: PByte;
  LReference: Pointer;
  LNumber: Cardinal;
  LLength: Byte;
begin
  LSlot := Slot(AStruct, AField);
  case AField.Kind of
    TSerializerFieldKind.Generic:
      if not IsZeroes(LSlot, AField.Size) then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.UnsignedByte:
      if Int64(PByte(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.SignedByte:
      if Int64(PShortInt(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.UnsignedWord:
      if Int64(PWord(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.SignedWord:
      if Int64(PSmallInt(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.UnsignedLong:
      if Int64(PCardinal(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.SignedLong:
      if Int64(PInteger(LSlot)^) <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.SignedQuad:
      if PInt64(LSlot)^ <> AField.IntegerDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.Float:
      if PSingle(LSlot)^ <> AField.FloatDefault then
        WriteValue(AStream, AField, LSlot);
    TSerializerFieldKind.Text:
      begin
        // always written, even when empty
        WriteId(AStream, AField);
        LLength := LSlot^;
        AStream.WriteBuffer(LLength, SizeOf(Byte));
        if LLength > 0 then
          AStream.WriteBuffer(LSlot[1], LLength);
      end;
    TSerializerFieldKind.State:
      begin
        LReference := PPointer(LSlot)^;
        if LReference <> nil then
        begin
          WriteId(AStream, AField);
          LNumber := FStates.StateIndex(LReference);
          AStream.WriteBuffer(LNumber, SizeOf(Cardinal));
        end;
      end;
    TSerializerFieldKind.Mobj:
      begin
        LReference := PPointer(LSlot)^;
        if LReference <> nil then
        begin
          LNumber := FMobjs.MobjKey(LReference);
          if LNumber <> 0 then
          begin
            WriteId(AStream, AField);
            AStream.WriteBuffer(LNumber, SizeOf(Cardinal));
          end;
        end;
      end;
    TSerializerFieldKind.Player:
      begin
        LReference := PPointer(LSlot)^;
        if LReference <> nil then
        begin
          WriteId(AStream, AField);
          LNumber := FPlayers.PlayerNumber(LReference);
          AStream.WriteBuffer(LNumber, SizeOf(Cardinal));
        end;
      end;
  end;
end;

procedure TSerializerFieldCodec.Load(const AStream: TStream; const AStruct: Pointer;
  const AField: TSerializerField);
var
  LSlot: PByte;
  LLength: Byte;
  LRaw: Cardinal;
begin
  LSlot := Slot(AStruct, AField);
  case AField.Kind of
    TSerializerFieldKind.Text:
      begin
        AStream.ReadBuffer(LLength, SizeOf(Byte));
        LSlot^ := LLength;
        // one byte per character, as it is written (the old reader took two: it was a Char)
        if LLength > 0 then
          AStream.ReadBuffer(LSlot[1], LLength);
      end;
    TSerializerFieldKind.State,
    TSerializerFieldKind.Mobj,
    TSerializerFieldKind.Player:
      begin
        // the slot is a pointer: it holds the raw number until ResolvePointers
        AStream.ReadBuffer(LRaw, SizeOf(Cardinal));
        PPointer(LSlot)^ := nil;
        PCardinal(LSlot)^ := LRaw;
      end;
  else
    AStream.ReadBuffer(LSlot^, AField.Size);
  end;
  if Assigned(AField.OnLoaded) then
    AField.OnLoaded(AStruct);
end;

procedure TSerializerFieldCodec.ApplyDefault(const AStruct: Pointer; const AField: TSerializerField);
var
  LSlot: PByte;
  LIndex: Integer;
begin
  LSlot := Slot(AStruct, AField);
  case AField.Kind of
    TSerializerFieldKind.Generic:
      FillChar(LSlot^, AField.Size, 0);
    TSerializerFieldKind.UnsignedByte:
      PByte(LSlot)^ := Byte(AField.IntegerDefault);
    TSerializerFieldKind.SignedByte:
      PShortInt(LSlot)^ := ShortInt(AField.IntegerDefault);
    TSerializerFieldKind.UnsignedWord:
      PWord(LSlot)^ := Word(AField.IntegerDefault);
    TSerializerFieldKind.SignedWord:
      PSmallInt(LSlot)^ := SmallInt(AField.IntegerDefault);
    TSerializerFieldKind.UnsignedLong:
      PCardinal(LSlot)^ := Cardinal(AField.IntegerDefault);
    TSerializerFieldKind.SignedLong:
      PInteger(LSlot)^ := Integer(AField.IntegerDefault);
    TSerializerFieldKind.SignedQuad:
      PInt64(LSlot)^ := AField.IntegerDefault;
    TSerializerFieldKind.Float:
      PSingle(LSlot)^ := AField.FloatDefault;
    TSerializerFieldKind.Text:
      begin
        LSlot^ := Byte(Length(AField.TextDefault));
        for LIndex := 1 to Length(AField.TextDefault) do
          LSlot[LIndex] := Ord(AField.TextDefault[LIndex]);
      end;
    TSerializerFieldKind.State,
    TSerializerFieldKind.Mobj,
    TSerializerFieldKind.Player:
      PPointer(LSlot)^ := nil;
  end;
end;

procedure TSerializerFieldCodec.Resolve(const AStruct: Pointer; const AField: TSerializerField);
var
  LSlot: PByte;
  LRaw: Cardinal;
begin
  if not (AField.Kind in [TSerializerFieldKind.State, TSerializerFieldKind.Mobj,
    TSerializerFieldKind.Player]) then
    Exit;
  LSlot := Slot(AStruct, AField);
  LRaw := PCardinal(LSlot)^;
  case AField.Kind of
    TSerializerFieldKind.Mobj:
      PPointer(LSlot)^ := FMobjs.MobjByKey(LRaw);
    TSerializerFieldKind.Player:
      // 0 is "no player": the slot stays nil
      if LRaw <> 0 then
        PPointer(LSlot)^ := FPlayers.PlayerByNumber(LRaw);
  else
    // an absent state becomes state 0: as the old ResolvePointers did
    PPointer(LSlot)^ := FStates.StateAt(LRaw);
  end;
end;

end.
