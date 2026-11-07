{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - fake resolvers and a record   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.Fakes;

interface

uses
  DelphiDoom.Serializer.Intf;

const
  FAKE_STATE_BASE = $1000;
  FAKE_STATE_STRIDE = 16;
  FAKE_MOBJ_BASE = $100000;
  FAKE_PLAYER_BASE = $200000;
  FAKE_PLAYER_STRIDE = 64;

type
  /// <summary>
  ///   Resolvers on made up pointers: state N is FAKE_STATE_BASE + N * stride, the mobj with
  ///   key K is FAKE_MOBJ_BASE + K, player number N is FAKE_PLAYER_BASE + (N - 1) * stride
  /// </summary>
  TFakeResolver = class(TInterfacedObject, ISerializerStateResolver, ISerializerMobjResolver,
    ISerializerPlayerResolver)
  public
    /// <summary>The keys that StateAt, MobjByKey and PlayerByNumber were asked for, in order</summary>
    Asked: TArray<Cardinal>;
    function StateIndex(const AState: Pointer): Cardinal;
    function StateAt(AIndex: Cardinal): Pointer;
    function MobjKey(const AMobj: Pointer): Cardinal;
    function MobjByKey(AKey: Cardinal): Pointer;
    function PlayerNumber(const APlayer: Pointer): Cardinal;
    function PlayerByNumber(ANumber: Cardinal): Pointer;
    class function StatePointer(AIndex: Cardinal): Pointer; static;
    class function MobjPointer(AKey: Cardinal): Pointer; static;
    class function PlayerPointer(ANumber: Cardinal): Pointer; static;
  end;

type
  /// <summary>
  ///   A record with a field of each kind: the same one that produced the golden of the old
  ///   serializer. The three references are pointers, so the record has another size on 64 bit:
  ///   the stream does not
  /// </summary>
  TGoldenRecord = packed record
    Generic6: array[0..5] of Byte;
    Byte0: Byte;
    Byte1: Byte;
    ShortInt0: ShortInt;
    ShortInt1: ShortInt;
    Word0: Word;
    Word1: Word;
    SmallInt0: SmallInt;
    SmallInt1: SmallInt;
    LongWord0: Cardinal;
    LongWord1: Cardinal;
    Integer0: Integer;
    Integer1: Integer;
    Int640: Int64;
    Int641: Int64;
    Float0: Single;
    Float1: Single;
    State: Pointer;
    Mobj: Pointer;
    Player: Pointer;
    Text0: string[255];
    Text1: string[255];
    Generic4: array[0..3] of Byte;
  end;
  PGoldenRecord = ^TGoldenRecord;

const
  /// <summary>Fields of the table of TGoldenRecord (the order of the golden)</summary>
  GOLDEN_FIELD_COUNT = 23;

/// <summary>Fills the table of TGoldenRecord with the defaults that the golden used</summary>
procedure FillGoldenTable(const ASerializer: ISerializer);

implementation

uses
  DelphiDoom.Serializer.Types;

{ TFakeResolver }

function TFakeResolver.StateIndex(const AState: Pointer): Cardinal;
begin
  Result := Cardinal((NativeUInt(AState) - FAKE_STATE_BASE) div FAKE_STATE_STRIDE);
end;

function TFakeResolver.StateAt(AIndex: Cardinal): Pointer;
begin
  Asked := Asked + [AIndex];
  Result := StatePointer(AIndex);
end;

function TFakeResolver.MobjKey(const AMobj: Pointer): Cardinal;
begin
  Result := Cardinal(NativeUInt(AMobj) - FAKE_MOBJ_BASE);
end;

function TFakeResolver.MobjByKey(AKey: Cardinal): Pointer;
begin
  Asked := Asked + [AKey];
  // like the engine: no mobj has key 0
  if AKey = 0 then
    Result := nil
  else
    Result := MobjPointer(AKey);
end;

function TFakeResolver.PlayerNumber(const APlayer: Pointer): Cardinal;
begin
  Result := Cardinal((NativeUInt(APlayer) - FAKE_PLAYER_BASE) div FAKE_PLAYER_STRIDE) + 1;
end;

function TFakeResolver.PlayerByNumber(ANumber: Cardinal): Pointer;
begin
  Asked := Asked + [ANumber];
  Result := PlayerPointer(ANumber);
end;

class function TFakeResolver.StatePointer(AIndex: Cardinal): Pointer;
begin
  Result := Pointer(NativeUInt(FAKE_STATE_BASE) + NativeUInt(AIndex) * FAKE_STATE_STRIDE);
end;

class function TFakeResolver.MobjPointer(AKey: Cardinal): Pointer;
begin
  Result := Pointer(NativeUInt(FAKE_MOBJ_BASE) + AKey);
end;

class function TFakeResolver.PlayerPointer(ANumber: Cardinal): Pointer;
begin
  Result := Pointer(NativeUInt(FAKE_PLAYER_BASE) + NativeUInt(ANumber - 1) * FAKE_PLAYER_STRIDE);
end;

procedure FillGoldenTable(const ASerializer: ISerializer);
var
  LRecord: PGoldenRecord;
begin
  // the offsets are the ones of the fields of a record at address 0
  LRecord := nil;
  ASerializer.AddGeneric(NativeInt(@LRecord.Generic6), 6);
  ASerializer.AddTyped(NativeInt(@LRecord.Byte0), TSerializerFieldKind.UnsignedByte, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Byte1), TSerializerFieldKind.UnsignedByte, 9);
  ASerializer.AddTyped(NativeInt(@LRecord.ShortInt0), TSerializerFieldKind.SignedByte, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.ShortInt1), TSerializerFieldKind.SignedByte, -5);
  ASerializer.AddTyped(NativeInt(@LRecord.Word0), TSerializerFieldKind.UnsignedWord, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Word1), TSerializerFieldKind.UnsignedWord, 300);
  ASerializer.AddTyped(NativeInt(@LRecord.SmallInt0), TSerializerFieldKind.SignedWord, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.SmallInt1), TSerializerFieldKind.SignedWord, -2);
  ASerializer.AddTyped(NativeInt(@LRecord.LongWord0), TSerializerFieldKind.UnsignedLong, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.LongWord1), TSerializerFieldKind.UnsignedLong, 4000000000);
  ASerializer.AddTyped(NativeInt(@LRecord.Integer0), TSerializerFieldKind.SignedLong, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Integer1), TSerializerFieldKind.SignedLong, -1);
  ASerializer.AddTyped(NativeInt(@LRecord.Int640), TSerializerFieldKind.SignedQuad, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Int641), TSerializerFieldKind.SignedQuad, Int64(1) shl 40);
  ASerializer.AddFloat(NativeInt(@LRecord.Float0), 0.0);
  ASerializer.AddFloat(NativeInt(@LRecord.Float1), 1.5);
  ASerializer.AddTyped(NativeInt(@LRecord.State), TSerializerFieldKind.State, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Mobj), TSerializerFieldKind.Mobj, 0);
  ASerializer.AddTyped(NativeInt(@LRecord.Player), TSerializerFieldKind.Player, 0);
  ASerializer.AddText(NativeInt(@LRecord.Text0), '');
  ASerializer.AddText(NativeInt(@LRecord.Text1), 'abc');
  ASerializer.AddGeneric(NativeInt(@LRecord.Generic4), 4);
end;

end.
