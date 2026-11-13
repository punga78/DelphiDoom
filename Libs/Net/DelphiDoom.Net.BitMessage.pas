{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - TBitMessage, the bit stream message (idBitMsg)    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\BitMsg.h,          }
{  BitMsg.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.BitMessage;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults,
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Net.BitMessage.Types, DelphiDoom.Net.BitMessage.Intf;

type
  /// <summary>
  ///   idBitMsg: a message that is written and read bit by bit, least significant bit first, with the
  ///   byte order and alignment of the original (the bytes are the same at 32 and at 64 bit and on any
  ///   machine). The buffer is the caller's: <c>Init</c> shares the array, it never copies or resizes it,
  ///   and <c>SetSize</c>, <c>BeginWriting</c> and the like only move the counters.
  ///   <para>Reading never fails: past the end <c>ReadBits</c> returns -1 and does not advance. Writing
  ///   past the end is an error (<c>EBitMessageException</c>) unless <c>AllowOverflow</c> is set, and then
  ///   the message restarts from the beginning and <c>Overflowed</c> becomes true, as the original does.
  ///   A negative number of bits is a signed field of that many bits.</para>
  ///   <para>Differences from the original: the message is an object with its own TBytes buffer
  ///   (<c>Init</c> instead of pointers); <c>common->Error</c> is an exception; the value overflow warnings
  ///   go to the optional <c>IIdLibLog</c> (silent without it); the strings are AnsiString and
  ///   <c>ReadString</c> returns the text instead of filling a buffer; <c>WriteString</c> has no NULL
  ///   form (write an empty string: the same one byte); <c>WriteString</c> with maxLength 0 is an error
  ///   (the original writes one byte outside the space it reserved); the dictionaries are
  ///   <c>TIdDict</c>. The message is not reference counted: the owner frees it, interface references
  ///   to it (<c>IBitMessageWriter</c>, <c>IBitMessageReader</c>) never free it.</para>
  /// </summary>
  TBitMessage = class(TSingletonImplementation, IBitMessageWriter, IBitMessageReader)
  strict private
    FData: TBytes;
    FCanWrite: Boolean;
    FMaxSize: Integer;
    FCurSize: Integer;
    FWriteBit: Integer;
    FReadCount: Integer;
    FReadBit: Integer;
    FAllowOverflow: Boolean;
    FOverflowed: Boolean;
    FLog: IIdLibLog;
    function CheckOverflow(ANumBits: Integer): Boolean;
    function GetByteSpace(ALength: Integer): Integer;
    procedure WriteDelta(AOldValue, ANewValue, ANumBits: Integer);
    function ReadDelta(AOldValue, ANumBits: Integer): Integer;
    procedure WriteDeltaCounter(AOldValue, ANewValue, AMaxBit, ACountBits: Integer);
    function ReadDeltaCounter(AOldValue, ACountBits: Integer): Integer;
    procedure WarnOverflow(AValue, ANumBits: Integer);
  public
    /// <summary>The log gets the "value overflow" warnings of WriteBits; nil keeps the message silent</summary>
    constructor Create(const ALog: IIdLibLog = nil);
    /// <summary>Init(byte*, length): a message that can be read and written. The array is shared, not copied</summary>
    procedure Init(const AData: TBytes; ALength: Integer);
    /// <summary>Init(const byte*, length): a message that can only be read</summary>
    procedure InitReadOnly(const AData: TBytes; ALength: Integer);

    /// <summary>The buffer (the array given to Init)</summary>
    function GetData: TBytes;
    function GetMaxSize: Integer;
    procedure SetAllowOverflow(AValue: Boolean);
    function IsOverflowed: Boolean;
    /// <summary>The size of the message in bytes</summary>
    function GetSize: Integer;
    /// <summary>Sets the size, never more than the maximum</summary>
    procedure SetSize(ASize: Integer);
    function GetWriteBit: Integer;
    /// <summary>Sets the bit of the last written byte; the bits above it are cleared</summary>
    procedure SetWriteBit(ABit: Integer);
    function GetNumBitsWritten: Integer;
    function GetRemainingWriteBits: Integer;
    procedure SaveWriteState(out ASize, ABit: Integer);
    procedure RestoreWriteState(ASize, ABit: Integer);

    function GetReadCount: Integer;
    procedure SetReadCount(ABytes: Integer);
    function GetReadBit: Integer;
    procedure SetReadBit(ABit: Integer);
    function GetNumBitsRead: Integer;
    function GetRemainingReadBits: Integer;
    procedure SaveReadState(out ACount, ABit: Integer);
    procedure RestoreReadState(ACount, ABit: Integer);

    procedure BeginWriting;
    function GetRemainingSpace: Integer;
    procedure WriteByteAlign;
    procedure WriteBits(AValue, ANumBits: Integer);
    procedure WriteChar(AValue: Integer);
    procedure WriteByte(AValue: Integer);
    procedure WriteShort(AValue: Integer);
    procedure WriteUShort(AValue: Integer);
    procedure WriteLong(AValue: Integer);
    procedure WriteFloat(AValue: Single); overload;
    procedure WriteFloat(AValue: Single; AExponentBits, AMantissaBits: Integer); overload;
    procedure WriteAngle8(AValue: Single);
    procedure WriteAngle16(AValue: Single);
    procedure WriteDir(const ADir: TIdVec3; ANumBits: Integer);
    procedure WriteString(const AText: AnsiString; AMaxLength: Integer = -1; AMake7Bit: Boolean = True);
    procedure WriteData(AData: PByte; ALength: Integer); overload;
    procedure WriteData(const AData: TBytes); overload;
    procedure WriteNetAddress(const AAddress: TBitMessageNetAddress);

    procedure WriteDeltaChar(AOldValue, ANewValue: Integer);
    procedure WriteDeltaByte(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShort(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLong(AOldValue, ANewValue: Integer);
    procedure WriteDeltaFloat(AOldValue, ANewValue: Single); overload;
    procedure WriteDeltaFloat(AOldValue, ANewValue: Single; AExponentBits, AMantissaBits: Integer); overload;
    procedure WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
    /// <summary>
    ///   Writes the pairs of ADict that differ from ABase (all of them if ABase is nil), then an empty
    ///   string, then the keys that ABase has and ADict has not, then an empty string. The result is true
    ///   if anything was written besides the two terminators.
    /// </summary>
    function WriteDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;

    procedure BeginReading;
    function GetRemainingData: Integer;
    procedure ReadByteAlign;
    function ReadBits(ANumBits: Integer): Integer;
    function ReadChar: Integer;
    function ReadByte: Integer;
    function ReadShort: Integer;
    function ReadUShort: Integer;
    function ReadLong: Integer;
    function ReadFloat: Single; overload;
    function ReadFloat(AExponentBits, AMantissaBits: Integer): Single; overload;
    function ReadAngle8: Single;
    function ReadAngle16: Single;
    function ReadDir(ANumBits: Integer): TIdVec3;
    function ReadString(ABufferSize: Integer = BITMSG_MAX_STRING_CHARS): AnsiString;
    function ReadData(AData: PByte; ALength: Integer): Integer; overload;
    function ReadData(ALength: Integer): TBytes; overload;
    function ReadNetAddress: TBitMessageNetAddress;

    function ReadDeltaChar(AOldValue: Integer): Integer;
    function ReadDeltaByte(AOldValue: Integer): Integer;
    function ReadDeltaShort(AOldValue: Integer): Integer;
    function ReadDeltaLong(AOldValue: Integer): Integer;
    function ReadDeltaFloat(AOldValue: Single): Single; overload;
    function ReadDeltaFloat(AOldValue: Single; AExponentBits, AMantissaBits: Integer): Single; overload;
    function ReadDeltaByteCounter(AOldValue: Integer): Integer;
    function ReadDeltaShortCounter(AOldValue: Integer): Integer;
    function ReadDeltaLongCounter(AOldValue: Integer): Integer;
    /// <summary>
    ///   Reads a dictionary written by WriteDeltaDict: ADict starts as a copy of ABase (empty if nil),
    ///   gets the pairs, loses the keys of the second list. True if anything was read.
    /// </summary>
    function ReadDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;

    /// <summary>
    ///   Packs a unit vector in ANumBits (6 to 32): a sign bit and a magnitude of ANumBits div 3 - 1 bits per
    ///   component
    /// </summary>
    class function DirToBits(const ADir: TIdVec3; ANumBits: Integer): Integer; static;
    class function BitsToDir(ABits, ANumBits: Integer): TIdVec3; static;

    property AllowOverflow: Boolean write SetAllowOverflow;
    property Overflowed: Boolean read IsOverflowed;
    property Size: Integer read GetSize write SetSize;
    property MaxSize: Integer read GetMaxSize;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

function FloatBits(const AValue: Single): Integer; inline;
begin
  Result := PInteger(@AValue)^;
end;

function BitsFloat(const AValue: Integer): Single; inline;
begin
  Result := PSingle(@AValue)^;
end;

{ TBitMessage }

constructor TBitMessage.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TBitMessage.Init(const AData: TBytes; ALength: Integer);
begin
  if (ALength < 0) or (ALength > System.Length(AData)) then
    raise EBitMessageException.CreateFmt(SBitMessageBufferTooSmall, [ALength, System.Length(AData)]);
  FData := AData;
  FCanWrite := True;
  FMaxSize := ALength;
end;

procedure TBitMessage.InitReadOnly(const AData: TBytes; ALength: Integer);
begin
  Init(AData, ALength);
  FCanWrite := False;
end;

function TBitMessage.GetData: TBytes;
begin
  Result := FData;
end;

function TBitMessage.GetMaxSize: Integer;
begin
  Result := FMaxSize;
end;

procedure TBitMessage.SetAllowOverflow(AValue: Boolean);
begin
  FAllowOverflow := AValue;
end;

function TBitMessage.IsOverflowed: Boolean;
begin
  Result := FOverflowed;
end;

function TBitMessage.GetSize: Integer;
begin
  Result := FCurSize;
end;

procedure TBitMessage.SetSize(ASize: Integer);
begin
  if ASize > FMaxSize then
    FCurSize := FMaxSize
  else
    FCurSize := ASize;
end;

function TBitMessage.GetWriteBit: Integer;
begin
  Result := FWriteBit;
end;

procedure TBitMessage.SetWriteBit(ABit: Integer);
begin
  FWriteBit := ABit and 7;
  if FWriteBit <> 0 then
    FData[FCurSize - 1] := FData[FCurSize - 1] and ((1 shl FWriteBit) - 1);
end;

function TBitMessage.GetNumBitsWritten: Integer;
begin
  Result := (FCurSize shl 3) - ((8 - FWriteBit) and 7);
end;

function TBitMessage.GetRemainingWriteBits: Integer;
begin
  Result := (FMaxSize shl 3) - GetNumBitsWritten;
end;

procedure TBitMessage.SaveWriteState(out ASize, ABit: Integer);
begin
  ASize := FCurSize;
  ABit := FWriteBit;
end;

procedure TBitMessage.RestoreWriteState(ASize, ABit: Integer);
begin
  FCurSize := ASize;
  FWriteBit := ABit and 7;
  if FWriteBit <> 0 then
    FData[FCurSize - 1] := FData[FCurSize - 1] and ((1 shl FWriteBit) - 1);
end;

function TBitMessage.GetReadCount: Integer;
begin
  Result := FReadCount;
end;

procedure TBitMessage.SetReadCount(ABytes: Integer);
begin
  FReadCount := ABytes;
end;

function TBitMessage.GetReadBit: Integer;
begin
  Result := FReadBit;
end;

procedure TBitMessage.SetReadBit(ABit: Integer);
begin
  FReadBit := ABit and 7;
end;

function TBitMessage.GetNumBitsRead: Integer;
begin
  Result := (FReadCount shl 3) - ((8 - FReadBit) and 7);
end;

function TBitMessage.GetRemainingReadBits: Integer;
begin
  Result := (FCurSize shl 3) - GetNumBitsRead;
end;

procedure TBitMessage.SaveReadState(out ACount, ABit: Integer);
begin
  ACount := FReadCount;
  ABit := FReadBit;
end;

procedure TBitMessage.RestoreReadState(ACount, ABit: Integer);
begin
  FReadCount := ACount;
  FReadBit := ABit and 7;
end;

procedure TBitMessage.BeginWriting;
begin
  FCurSize := 0;
  FOverflowed := False;
  FWriteBit := 0;
end;

function TBitMessage.GetRemainingSpace: Integer;
begin
  Result := FMaxSize - FCurSize;
end;

procedure TBitMessage.WriteByteAlign;
begin
  FWriteBit := 0;
end;

function TBitMessage.CheckOverflow(ANumBits: Integer): Boolean;
begin
  Result := False;
  if ANumBits > GetRemainingWriteBits then
  begin
    if not FAllowOverflow then
      raise EBitMessageException.Create(SBitMessageOverflowNotAllowed);
    if ANumBits > (FMaxSize shl 3) then
      raise EBitMessageException.CreateFmt(SBitMessageBitsLargerThanMessage, [ANumBits]);
    if Assigned(FLog) then
      FLog.Printf('idBitMsg: overflow');
    BeginWriting;
    FOverflowed := True;
    Result := True;
  end;
end;

function TBitMessage.GetByteSpace(ALength: Integer): Integer;
begin
  if not FCanWrite then
    raise EBitMessageException.Create(SBitMessageCannotWrite);
  // round up to the next byte
  WriteByteAlign;
  CheckOverflow(ALength shl 3);
  Result := FCurSize;
  Inc(FCurSize, ALength);
end;

procedure TBitMessage.WarnOverflow(AValue, ANumBits: Integer);
begin
  if Assigned(FLog) then
    FLog.Warning(Format('idBitMsg::WriteBits: value overflow %d %d', [AValue, ANumBits]));
end;

procedure TBitMessage.WriteBits(AValue, ANumBits: Integer);
var
  LPut, LFraction, LLimit: Integer;
begin
  if not FCanWrite then
    raise EBitMessageException.Create(SBitMessageCannotWrite);
  if (ANumBits = 0) or (ANumBits < -31) or (ANumBits > 32) then
    raise EBitMessageException.CreateFmt(SBitMessageBadNumBits, [ANumBits]);
  // the value overflows are only reported: the bits that fit are written
  if ANumBits <> 32 then
  begin
    if ANumBits > 0 then
    begin
      if AValue > (1 shl ANumBits) - 1 then
        WarnOverflow(AValue, ANumBits)
      else if AValue < 0 then
        WarnOverflow(AValue, ANumBits);
    end
    else
    begin
      LLimit := 1 shl (-1 - ANumBits);
      if AValue > LLimit - 1 then
        WarnOverflow(AValue, ANumBits)
      else if AValue < -LLimit then
        WarnOverflow(AValue, ANumBits);
    end;
  end;
  if ANumBits < 0 then
    ANumBits := -ANumBits;
  if CheckOverflow(ANumBits) then
    Exit;
  while ANumBits <> 0 do
  begin
    if FWriteBit = 0 then
    begin
      FData[FCurSize] := 0;
      Inc(FCurSize);
    end;
    LPut := 8 - FWriteBit;
    if LPut > ANumBits then
      LPut := ANumBits;
    LFraction := AValue and ((1 shl LPut) - 1);
    FData[FCurSize - 1] := FData[FCurSize - 1] or Byte(LFraction shl FWriteBit);
    Dec(ANumBits, LPut);
    AValue := Integer(Cardinal(AValue) shr LPut);
    FWriteBit := (FWriteBit + LPut) and 7;
  end;
end;

procedure TBitMessage.WriteChar(AValue: Integer);
begin
  WriteBits(AValue, -8);
end;

procedure TBitMessage.WriteByte(AValue: Integer);
begin
  WriteBits(AValue, 8);
end;

procedure TBitMessage.WriteShort(AValue: Integer);
begin
  WriteBits(AValue, -16);
end;

procedure TBitMessage.WriteUShort(AValue: Integer);
begin
  WriteBits(AValue, 16);
end;

procedure TBitMessage.WriteLong(AValue: Integer);
begin
  WriteBits(AValue, 32);
end;

procedure TBitMessage.WriteFloat(AValue: Single);
begin
  WriteBits(FloatBits(AValue), 32);
end;

procedure TBitMessage.WriteFloat(AValue: Single; AExponentBits, AMantissaBits: Integer);
begin
  WriteBits(TIdMath.FloatToBits(AValue, AExponentBits, AMantissaBits), 1 + AExponentBits + AMantissaBits);
end;

procedure TBitMessage.WriteAngle8(AValue: Single);
var
  LScaled: Single;
begin
  // ANGLE2BYTE: FtoiFast( x * 256.0f / 360.0f ) & 255
  LScaled := AValue * 256.0;
  LScaled := LScaled / 360.0;
  WriteByte(TIdMath.FtoiFast(LScaled) and 255);
end;

procedure TBitMessage.WriteAngle16(AValue: Single);
var
  LScaled: Single;
begin
  LScaled := AValue * 65536.0;
  LScaled := LScaled / 360.0;
  WriteShort(TIdMath.FtoiFast(LScaled) and 65535);
end;

procedure TBitMessage.WriteDir(const ADir: TIdVec3; ANumBits: Integer);
begin
  WriteBits(DirToBits(ADir, ANumBits), ANumBits);
end;

procedure TBitMessage.WriteString(const AText: AnsiString; AMaxLength: Integer; AMake7Bit: Boolean);
var
  LLength, LIndex, LOffset: Integer;
  LByte: Byte;
begin
  if AMaxLength = 0 then
    raise EBitMessageException.Create(SBitMessageBadMaxLength);
  // idStr::Length: the C string stops at the first #0
  LLength := 0;
  while (LLength < System.Length(AText)) and (AText[LLength + 1] <> #0) do
    Inc(LLength);
  if (AMaxLength >= 0) and (LLength >= AMaxLength) then
    LLength := AMaxLength - 1;
  LOffset := GetByteSpace(LLength + 1);
  for LIndex := 0 to LLength - 1 do
  begin
    LByte := Byte(AText[LIndex + 1]);
    if AMake7Bit and (LByte > 127) then
      LByte := Ord('.');
    FData[LOffset + LIndex] := LByte;
  end;
  FData[LOffset + LLength] := 0;
end;

procedure TBitMessage.WriteData(AData: PByte; ALength: Integer);
var
  LOffset: Integer;
begin
  LOffset := GetByteSpace(ALength);
  if ALength > 0 then
    Move(AData^, FData[LOffset], ALength);
end;

procedure TBitMessage.WriteData(const AData: TBytes);
begin
  if System.Length(AData) = 0 then
    WriteData(nil, 0)
  else
    WriteData(@AData[0], System.Length(AData));
end;

procedure TBitMessage.WriteNetAddress(const AAddress: TBitMessageNetAddress);
var
  LOffset: Integer;
begin
  LOffset := GetByteSpace(4);
  Move(AAddress.Ip[0], FData[LOffset], 4);
  WriteUShort(AAddress.Port);
end;

procedure TBitMessage.WriteDelta(AOldValue, ANewValue, ANumBits: Integer);
begin
  if AOldValue = ANewValue then
  begin
    WriteBits(0, 1);
    Exit;
  end;
  WriteBits(1, 1);
  WriteBits(ANewValue, ANumBits);
end;

procedure TBitMessage.WriteDeltaChar(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, -8);
end;

procedure TBitMessage.WriteDeltaByte(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, 8);
end;

procedure TBitMessage.WriteDeltaShort(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, -16);
end;

procedure TBitMessage.WriteDeltaLong(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, 32);
end;

procedure TBitMessage.WriteDeltaFloat(AOldValue, ANewValue: Single);
begin
  WriteDelta(FloatBits(AOldValue), FloatBits(ANewValue), 32);
end;

procedure TBitMessage.WriteDeltaFloat(AOldValue, ANewValue: Single; AExponentBits, AMantissaBits: Integer);
var
  LOldBits, LNewBits: Integer;
begin
  LOldBits := TIdMath.FloatToBits(AOldValue, AExponentBits, AMantissaBits);
  LNewBits := TIdMath.FloatToBits(ANewValue, AExponentBits, AMantissaBits);
  WriteDelta(LOldBits, LNewBits, 1 + AExponentBits + AMantissaBits);
end;

procedure TBitMessage.WriteDeltaCounter(AOldValue, ANewValue, AMaxBit, ACountBits: Integer);
var
  LIndex, LDifference: Integer;
begin
  // LIndex ends as the position above the highest bit that differs (0 if only bit 0 or nothing differs).
  // As in the original a difference in the top bit gives a count that does not fit in ACountBits
  LDifference := AOldValue xor ANewValue;
  LIndex := AMaxBit;
  while LIndex > 0 do
  begin
    if (LDifference and (1 shl LIndex)) <> 0 then
    begin
      Inc(LIndex);
      Break;
    end;
    Dec(LIndex);
  end;
  WriteBits(LIndex, ACountBits);
  if LIndex <> 0 then
    WriteBits(((1 shl LIndex) - 1) and ANewValue, LIndex);
end;

procedure TBitMessage.WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
begin
  WriteDeltaCounter(AOldValue, ANewValue, 7, 3);
end;

procedure TBitMessage.WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
begin
  WriteDeltaCounter(AOldValue, ANewValue, 15, 4);
end;

procedure TBitMessage.WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
begin
  WriteDeltaCounter(AOldValue, ANewValue, 31, 5);
end;

function TBitMessage.WriteDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
var
  LIndex: Integer;
  LPair, LBasePair: TIdKeyValue;
begin
  Result := False;
  if Assigned(ABase) then
  begin
    for LIndex := 0 to ADict.GetNumKeyVals - 1 do
    begin
      ADict.TryGetKeyVal(LIndex, LPair);
      if (not ABase.FindKey(LPair.Key, LBasePair)) or (TIdStrings.Icmp(LBasePair.Value, LPair.Value) <> 0) then
      begin
        WriteString(LPair.Key);
        WriteString(LPair.Value);
        Result := True;
      end;
    end;
    WriteString('');
    for LIndex := 0 to ABase.GetNumKeyVals - 1 do
    begin
      ABase.TryGetKeyVal(LIndex, LBasePair);
      if not ADict.FindKey(LBasePair.Key, LPair) then
      begin
        WriteString(LBasePair.Key);
        Result := True;
      end;
    end;
    WriteString('');
  end
  else
  begin
    for LIndex := 0 to ADict.GetNumKeyVals - 1 do
    begin
      ADict.TryGetKeyVal(LIndex, LPair);
      WriteString(LPair.Key);
      WriteString(LPair.Value);
      Result := True;
    end;
    WriteString('');
    WriteString('');
  end;
end;

procedure TBitMessage.BeginReading;
begin
  FReadCount := 0;
  FReadBit := 0;
end;

function TBitMessage.GetRemainingData: Integer;
begin
  Result := FCurSize - FReadCount;
end;

procedure TBitMessage.ReadByteAlign;
begin
  FReadBit := 0;
end;

function TBitMessage.ReadBits(ANumBits: Integer): Integer;
var
  LValueBits, LGet, LFraction: Integer;
  LSigned: Boolean;
begin
  if System.Length(FData) = 0 then
    raise EBitMessageException.Create(SBitMessageCannotRead);
  if (ANumBits = 0) or (ANumBits < -31) or (ANumBits > 32) then
    raise EBitMessageException.CreateFmt(SBitMessageBadNumBits, [ANumBits]);
  Result := 0;
  LValueBits := 0;
  LSigned := ANumBits < 0;
  if LSigned then
    ANumBits := -ANumBits;
  // check for overflow
  if ANumBits > GetRemainingReadBits then
    Exit(-1);
  while LValueBits < ANumBits do
  begin
    if FReadBit = 0 then
      Inc(FReadCount);
    LGet := 8 - FReadBit;
    if LGet > (ANumBits - LValueBits) then
      LGet := ANumBits - LValueBits;
    LFraction := FData[FReadCount - 1];
    LFraction := LFraction shr FReadBit;
    LFraction := LFraction and ((1 shl LGet) - 1);
    Result := Result or (LFraction shl LValueBits);
    Inc(LValueBits, LGet);
    FReadBit := (FReadBit + LGet) and 7;
  end;
  if LSigned then
  begin
    if (Result and (1 shl (ANumBits - 1))) <> 0 then
      Result := Result or (-1 xor ((1 shl ANumBits) - 1));
  end;
end;

function TBitMessage.ReadChar: Integer;
begin
  Result := ShortInt(ReadBits(-8));
end;

function TBitMessage.ReadByte: Integer;
begin
  Result := Byte(ReadBits(8));
end;

function TBitMessage.ReadShort: Integer;
begin
  Result := SmallInt(ReadBits(-16));
end;

function TBitMessage.ReadUShort: Integer;
begin
  Result := Word(ReadBits(16));
end;

function TBitMessage.ReadLong: Integer;
begin
  Result := ReadBits(32);
end;

function TBitMessage.ReadFloat: Single;
begin
  Result := BitsFloat(ReadBits(32));
end;

function TBitMessage.ReadFloat(AExponentBits, AMantissaBits: Integer): Single;
begin
  Result := TIdMath.BitsToFloat(ReadBits(1 + AExponentBits + AMantissaBits), AExponentBits, AMantissaBits);
end;

function TBitMessage.ReadAngle8: Single;
begin
  // BYTE2ANGLE: x * ( 360.0f / 256.0f )
  Result := ReadByte * 1.40625;
end;

function TBitMessage.ReadAngle16: Single;
begin
  // SHORT2ANGLE: x * ( 360.0f / 65536.0f )
  Result := ReadShort * (360.0 / 65536.0);
end;

function TBitMessage.ReadDir(ANumBits: Integer): TIdVec3;
begin
  Result := BitsToDir(ReadBits(ANumBits), ANumBits);
end;

function TBitMessage.ReadString(ABufferSize: Integer): AnsiString;
var
  LCount, LChar: Integer;
  LText: AnsiString;
begin
  ReadByteAlign;
  LCount := 0;
  SetLength(LText, 16);
  while True do
  begin
    LChar := ReadByte;
    if (LChar <= 0) or (LChar >= 255) then
      Break;
    // translate all fmt spec to avoid crash bugs in string routines
    if LChar = Ord('%') then
      LChar := Ord('.');
    // an excessively long string is read to its end, but the text is truncated
    if LCount < ABufferSize - 1 then
    begin
      if LCount = System.Length(LText) then
        SetLength(LText, LCount * 2);
      LText[LCount + 1] := AnsiChar(LChar);
      Inc(LCount);
    end;
  end;
  SetLength(LText, LCount);
  Result := LText;
end;

function TBitMessage.ReadData(AData: PByte; ALength: Integer): Integer;
var
  LStart: Integer;
begin
  ReadByteAlign;
  LStart := FReadCount;
  if FReadCount + ALength > FCurSize then
  begin
    if Assigned(AData) and (GetRemainingData > 0) then
      Move(FData[FReadCount], AData^, GetRemainingData);
    FReadCount := FCurSize;
  end
  else
  begin
    if Assigned(AData) and (ALength > 0) then
      Move(FData[FReadCount], AData^, ALength);
    Inc(FReadCount, ALength);
  end;
  Result := FReadCount - LStart;
end;

function TBitMessage.ReadData(ALength: Integer): TBytes;
var
  LCount: Integer;
begin
  SetLength(Result, ALength);
  if ALength = 0 then
    Exit;
  FillChar(Result[0], ALength, 0);
  LCount := ReadData(@Result[0], ALength);
  SetLength(Result, LCount);
end;

function TBitMessage.ReadNetAddress: TBitMessageNetAddress;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.Ip[LIndex] := Byte(ReadByte);
  Result.Port := Word(ReadUShort);
end;

function TBitMessage.ReadDelta(AOldValue, ANumBits: Integer): Integer;
begin
  if ReadBits(1) <> 0 then
    Result := ReadBits(ANumBits)
  else
    Result := AOldValue;
end;

function TBitMessage.ReadDeltaChar(AOldValue: Integer): Integer;
begin
  Result := ShortInt(ReadDelta(AOldValue, -8));
end;

function TBitMessage.ReadDeltaByte(AOldValue: Integer): Integer;
begin
  Result := Byte(ReadDelta(AOldValue, 8));
end;

function TBitMessage.ReadDeltaShort(AOldValue: Integer): Integer;
begin
  Result := SmallInt(ReadDelta(AOldValue, -16));
end;

function TBitMessage.ReadDeltaLong(AOldValue: Integer): Integer;
begin
  Result := ReadDelta(AOldValue, 32);
end;

function TBitMessage.ReadDeltaFloat(AOldValue: Single): Single;
begin
  Result := BitsFloat(ReadDelta(FloatBits(AOldValue), 32));
end;

function TBitMessage.ReadDeltaFloat(AOldValue: Single; AExponentBits, AMantissaBits: Integer): Single;
var
  LOldBits, LNewBits: Integer;
begin
  LOldBits := TIdMath.FloatToBits(AOldValue, AExponentBits, AMantissaBits);
  LNewBits := ReadDelta(LOldBits, 1 + AExponentBits + AMantissaBits);
  Result := TIdMath.BitsToFloat(LNewBits, AExponentBits, AMantissaBits);
end;

function TBitMessage.ReadDeltaCounter(AOldValue, ACountBits: Integer): Integer;
var
  LIndex, LNewValue: Integer;
begin
  LIndex := ReadBits(ACountBits);
  if LIndex = 0 then
    Exit(AOldValue);
  LNewValue := ReadBits(LIndex);
  Result := (AOldValue and not ((1 shl LIndex) - 1)) or LNewValue;
end;

function TBitMessage.ReadDeltaByteCounter(AOldValue: Integer): Integer;
begin
  Result := ReadDeltaCounter(AOldValue, 3);
end;

function TBitMessage.ReadDeltaShortCounter(AOldValue: Integer): Integer;
begin
  Result := ReadDeltaCounter(AOldValue, 4);
end;

function TBitMessage.ReadDeltaLongCounter(AOldValue: Integer): Integer;
begin
  Result := ReadDeltaCounter(AOldValue, 5);
end;

function TBitMessage.ReadDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
var
  LKey, LValue: AnsiString;
begin
  Result := False;
  if Assigned(ABase) then
    ADict.Assign(ABase)
  else
    ADict.Clear;
  LKey := ReadString(BITMSG_MAX_STRING_CHARS);
  while LKey <> '' do
  begin
    LValue := ReadString(BITMSG_MAX_STRING_CHARS);
    ADict.SetValue(LKey, LValue);
    Result := True;
    LKey := ReadString(BITMSG_MAX_STRING_CHARS);
  end;
  LKey := ReadString(BITMSG_MAX_STRING_CHARS);
  while LKey <> '' do
  begin
    ADict.Delete(LKey);
    Result := True;
    LKey := ReadString(BITMSG_MAX_STRING_CHARS);
  end;
end;

class function TBitMessage.DirToBits(const ADir: TIdVec3; ANumBits: Integer): Integer;
var
  LMax: Integer;
  LBias, LScaled: Single;
  LX, LY, LZ: Single;
begin
  ANumBits := ANumBits div 3;
  LMax := (1 shl (ANumBits - 1)) - 1;
  LBias := 0.5 / LMax;
  LX := ADir.X;
  LY := ADir.Y;
  LZ := ADir.Z;
  // FLOATSIGNBITSET: the sign bit of the float, also for -0.0
  Result := Integer(PCardinal(@LX)^ shr 31) shl (ANumBits * 3 - 1);
  LScaled := TIdMath.Fabs(LX) + LBias;
  LScaled := LScaled * LMax;
  Result := Result or (TIdMath.Ftoi(LScaled) shl (ANumBits * 2));
  Result := Result or (Integer(PCardinal(@LY)^ shr 31) shl (ANumBits * 2 - 1));
  LScaled := TIdMath.Fabs(LY) + LBias;
  LScaled := LScaled * LMax;
  Result := Result or (TIdMath.Ftoi(LScaled) shl (ANumBits * 1));
  Result := Result or (Integer(PCardinal(@LZ)^ shr 31) shl (ANumBits * 1 - 1));
  LScaled := TIdMath.Fabs(LZ) + LBias;
  LScaled := LScaled * LMax;
  Result := Result or (TIdMath.Ftoi(LScaled) shl (ANumBits * 0));
end;

class function TBitMessage.BitsToDir(ABits, ANumBits: Integer): TIdVec3;
const
  SIGNS: array[0..1] of Single = (1.0, -1.0);
var
  LMax: Integer;
  LInvMax, LComponent: Single;
begin
  ANumBits := ANumBits div 3;
  LMax := (1 shl (ANumBits - 1)) - 1;
  LInvMax := 1.0 / LMax;
  LComponent := SIGNS[(ABits shr (ANumBits * 3 - 1)) and 1] * ((ABits shr (ANumBits * 2)) and LMax);
  Result.X := LComponent * LInvMax;
  LComponent := SIGNS[(ABits shr (ANumBits * 2 - 1)) and 1] * ((ABits shr (ANumBits * 1)) and LMax);
  Result.Y := LComponent * LInvMax;
  LComponent := SIGNS[(ABits shr (ANumBits * 1 - 1)) and 1] * ((ABits shr (ANumBits * 0)) and LMax);
  Result.Z := LComponent * LInvMax;
  Result.NormalizeFast;
end;

end.
