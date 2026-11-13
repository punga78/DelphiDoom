{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the messages of Quake III (msg_t)                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c,          }
{  qcommon.h. Copyright (C) 1999-2005 id Software, Inc.                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.Message;

// The arithmetic of the original is the wrapping arithmetic of a 32 bit x86 compiler: shifts take
// their count modulo 32 and sums wrap around.
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf;

type
  /// <summary>
  ///   msg_t: a buffer of bytes with a write position and a read position. In bit stream mode every value
  ///   goes through the Huffman coder; in out-of-band mode (<c>oob</c>) bytes, shorts and longs are plain
  ///   little endian. The buffer belongs to the caller (<c>Init</c> shares it, it is not copied); the
  ///   message is not reference counted: whoever creates it frees it
  /// </summary>
  TQ3Message = class
  strict private
    FCoder: IQ3HuffmanCoder;
    FLog: ILog;
    FData: TBytes;
    FAllowOverflow: Boolean;
    FOverflowed: Boolean;
    FOob: Boolean;
    FMaxSize: Integer;
    FCurSize: Integer;
    FReadCount: Integer;
    FBit: Integer;
    FOverflows: Integer;
    function ByteAt(AIndex: Integer): Integer;
    function ReadTextLimited(ALimit: Integer; AMask7Bit, AStopAtNewline: Boolean): AnsiString;
    procedure WriteText(const AText: AnsiString; ALimit: Integer; const ALimitName: string);
    procedure ReadyForBitStream;
  public
    /// <summary>
    ///   ACoder may be nil for a message that is only out of band (the packets of the network channel
    ///   never touch the Huffman tree); ALog gets the warnings (nil = silence)
    /// </summary>
    constructor Create(const ACoder: IQ3HuffmanCoder; const ALog: ILog = nil);

    /// <summary>(int)f of a 32 bit x86 compiler: a value out of range (or a NaN) is $80000000</summary>
    class function TruncToInteger(AValue: Single): Integer; static;
    class function FloatToBits(AValue: Single): Integer; static; inline;
    class function BitsToFloat(AValue: Integer): Single; static; inline;
    /// <summary>The comparison of the floats of the original (a NaN is different from everything, -0 equals 0)</summary>
    class function FloatsEqual(AValue1, AValue2: Single): Boolean; static;
    /// <summary>ANGLE2SHORT</summary>
    class function AngleToShort(AValue: Single): Integer; static;
    /// <summary>SHORT2ANGLE</summary>
    class function ShortToAngle(AValue: Integer): Single; static;

    /// <summary>MSG_Init: an empty bit stream message over the buffer; ALength is the size it may fill</summary>
    procedure Init(const AData: TBytes; ALength: Integer);
    /// <summary>MSG_InitOOB</summary>
    procedure InitOOB(const AData: TBytes; ALength: Integer);
    /// <summary>MSG_Clear</summary>
    procedure Clear;
    /// <summary>MSG_Bitstream: back to the bit stream mode</summary>
    procedure Bitstream;
    /// <summary>MSG_BeginReading</summary>
    procedure BeginReading;
    /// <summary>MSG_BeginReadingOOB</summary>
    procedure BeginReadingOOB;
    /// <summary>MSG_Copy: copies the state and the used bytes of ASource over a new buffer</summary>
    procedure CopyFrom(const ASource: TQ3Message; const AData: TBytes; ALength: Integer);

    /// <summary>
    ///   MSG_WriteBits: a negative number of bits writes a signed value. A message that has fewer than 4
    ///   bytes left sets <c>Overflowed</c> and writes nothing
    /// </summary>
    procedure WriteBits(AValue, ABits: Integer);
    /// <summary>MSG_ReadBits</summary>
    function ReadBits(ABits: Integer): Integer;

    procedure WriteChar(AValue: Integer);
    procedure WriteByte(AValue: Integer);
    procedure WriteData(const AData: TBytes; ALength: Integer);
    procedure WriteShort(AValue: Integer);
    procedure WriteLong(AValue: Integer);
    procedure WriteFloat(AValue: Single);
    /// <summary>
    ///   MSG_WriteString: stops at the first NUL, writes the terminator, turns every byte above 127 into a
    ///   '.'. A string of 1024 characters or more is not written (a lone terminator goes out, with a warning)
    /// </summary>
    procedure WriteString(const AText: AnsiString);
    /// <summary>MSG_WriteBigString: as WriteString with the limit of 8192 characters</summary>
    procedure WriteBigString(const AText: AnsiString);
    /// <summary>MSG_WriteAngle: a byte</summary>
    procedure WriteAngle(AValue: Single);
    /// <summary>MSG_WriteAngle16</summary>
    procedure WriteAngle16(AValue: Single);

    /// <summary>-1 once the read position is past the used bytes (as the Read functions of the original)</summary>
    function ReadChar: Integer;
    function ReadByte: Integer;
    function ReadShort: Integer;
    function ReadLong: Integer;
    function ReadFloat: Single;
    /// <summary>
    ///   MSG_ReadString: up to 1023 characters (the rest of a longer string is left in the message), '%' and
    ///   bytes above 127 become '.'
    /// </summary>
    function ReadString: AnsiString;
    /// <summary>MSG_ReadBigString: up to 8191 characters, '%' becomes '.' (bytes above 127 are kept)</summary>
    function ReadBigString: AnsiString;
    /// <summary>MSG_ReadStringLine: as ReadString but also ends at a newline and keeps bytes above 127</summary>
    function ReadStringLine: AnsiString;
    function ReadAngle16: Single;
    /// <summary>MSG_ReadData: ALength bytes (-1 where the message has no more)</summary>
    procedure ReadData(var AData: TBytes; ALength: Integer);

    /// <summary>MSG_WriteDelta: one bit, and the new value if it changed</summary>
    procedure WriteDelta(AOldValue, ANewValue, ABits: Integer);
    function ReadDelta(AOldValue, ABits: Integer): Integer;
    procedure WriteDeltaFloat(AOldValue, ANewValue: Single);
    function ReadDeltaFloat(AOldValue: Single): Single;
    /// <summary>MSG_WriteDeltaKey: the new value goes out xored with the key</summary>
    procedure WriteDeltaKey(AKey, AOldValue, ANewValue, ABits: Integer);
    /// <summary>
    ///   MSG_ReadDeltaKey. Defect of the original, kept: the key is masked with kbitmask[bits], which has
    ///   bits + 1 bits (a 16 bit value is xored with 17 bits of the key)
    /// </summary>
    function ReadDeltaKey(AKey, AOldValue, ABits: Integer): Integer;
    procedure WriteDeltaKeyFloat(AKey: Integer; AOldValue, ANewValue: Single);
    function ReadDeltaKeyFloat(AKey: Integer; AOldValue: Single): Single;

    /// <summary>The buffer (shared with the caller)</summary>
    property Data: TBytes read FData;
    property AllowOverflow: Boolean read FAllowOverflow write FAllowOverflow;
    /// <summary>A write found the message full</summary>
    property Overflowed: Boolean read FOverflowed write FOverflowed;
    property Oob: Boolean read FOob write FOob;
    property MaxSize: Integer read FMaxSize write FMaxSize;
    /// <summary>The bytes in the message</summary>
    property CurSize: Integer read FCurSize write FCurSize;
    property ReadCount: Integer read FReadCount write FReadCount;
    /// <summary>The bit position (in bit stream mode the next bit to write or read)</summary>
    property Bit: Integer read FBit write FBit;
    /// <summary>How many values did not fit the bits they were written with (the <c>overflows</c> counter of msg.c)</summary>
    property Overflows: Integer read FOverflows write FOverflows;
  end;

implementation

{ TQ3Message }

constructor TQ3Message.Create(const ACoder: IQ3HuffmanCoder; const ALog: ILog);
begin
  inherited Create;
  FCoder := ACoder;
  FLog := ALog;
end;

class function TQ3Message.TruncToInteger(AValue: Single): Integer;
begin
  // a NaN is never compared (Delphi raises an invalid operation for it)
  if (not IsNan(AValue)) and (AValue >= -2147483648.0) and (AValue < 2147483648.0) then
    Result := Trunc(AValue)
  else
    Result := Low(Integer);
end;

class function TQ3Message.FloatToBits(AValue: Single): Integer;
var
  LBits: TQ3FloatBits;
begin
  LBits.AsSingle := AValue;
  Result := LBits.AsInteger;
end;

class function TQ3Message.BitsToFloat(AValue: Integer): Single;
var
  LBits: TQ3FloatBits;
begin
  LBits.AsInteger := AValue;
  Result := LBits.AsSingle;
end;

class function TQ3Message.FloatsEqual(AValue1, AValue2: Single): Boolean;
begin
  Result := (not IsNan(AValue1)) and (not IsNan(AValue2)) and (AValue1 = AValue2);
end;

class function TQ3Message.AngleToShort(AValue: Single): Integer;
var
  LScaled: Single;
begin
  LScaled := AValue * 65536;
  LScaled := Double(LScaled) / 360;
  Result := TruncToInteger(LScaled) and 65535;
end;

class function TQ3Message.ShortToAngle(AValue: Integer): Single;
begin
  // 360 / 65536 is exact in a double
  Result := AValue * (360.0 / 65536.0);
end;

procedure TQ3Message.Init(const AData: TBytes; ALength: Integer);
begin
  if ALength > Length(AData) then
    raise EQ3MessageException.CreateFmt(SQ3MessageBufferTooSmall, [ALength, Length(AData)]);
  FData := AData;
  FMaxSize := ALength;
  FCurSize := 0;
  FReadCount := 0;
  FBit := 0;
  FOverflowed := False;
  FAllowOverflow := False;
  FOob := False;
  FOverflows := 0;
end;

procedure TQ3Message.InitOOB(const AData: TBytes; ALength: Integer);
begin
  Init(AData, ALength);
  FOob := True;
end;

procedure TQ3Message.Clear;
begin
  FCurSize := 0;
  FOverflowed := False;
  FBit := 0;
end;

procedure TQ3Message.Bitstream;
begin
  FOob := False;
end;

procedure TQ3Message.BeginReading;
begin
  FReadCount := 0;
  FBit := 0;
  FOob := False;
end;

procedure TQ3Message.BeginReadingOOB;
begin
  FReadCount := 0;
  FBit := 0;
  FOob := True;
end;

procedure TQ3Message.CopyFrom(const ASource: TQ3Message; const AData: TBytes; ALength: Integer);
begin
  if ALength < ASource.FCurSize then
    raise EQ3MessageException.Create('MSG_Copy: can''t copy into a smaller msg_t buffer');
  if Length(AData) < ASource.FCurSize then
    raise EQ3MessageOverflowException.CreateFmt(SQ3MessageBufferTooSmall, [ASource.FCurSize, Length(AData)]);
  FCoder := ASource.FCoder;
  FLog := ASource.FLog;
  FAllowOverflow := ASource.FAllowOverflow;
  FOverflowed := ASource.FOverflowed;
  FOob := ASource.FOob;
  FMaxSize := ASource.FMaxSize;
  FCurSize := ASource.FCurSize;
  FReadCount := ASource.FReadCount;
  FBit := ASource.FBit;
  FOverflows := ASource.FOverflows;
  FData := AData;
  if ASource.FCurSize > 0 then
    Move(ASource.FData[0], FData[0], ASource.FCurSize);
end;

function TQ3Message.ByteAt(AIndex: Integer): Integer;
begin
  // the original reads whatever is in memory there; a byte outside the buffer is 0
  if (AIndex >= 0) and (AIndex < Length(FData)) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TQ3Message.ReadyForBitStream;
begin
  if not Assigned(FCoder) then
    raise EQ3MessageException.Create('A message without a Huffman coder can only be out of band');
end;

procedure TQ3Message.WriteBits(AValue, ABits: Integer);
var
  LIndex, LBitCount, LLimit: Integer;
  LValue: Cardinal;
begin
  // this isn't an exact overflow check, but close enough
  if FMaxSize - FCurSize < 4 then
  begin
    FOverflowed := True;
    Exit;
  end;

  if (ABits = 0) or (ABits < -31) or (ABits > 32) then
    raise EQ3MessageException.CreateFmt(SQ3MessageBadBits, [ABits]);

  // check for overflows (the shifts are modulo 32 as on the x86)
  if ABits <> 32 then
  begin
    if ABits > 0 then
    begin
      if (AValue > ((1 shl ABits) - 1)) or (AValue < 0) then
        Inc(FOverflows);
    end
    else
    begin
      LLimit := 1 shl ((ABits - 1) and 31);
      if (AValue > LLimit - 1) or (AValue < -LLimit) then
        Inc(FOverflows);
    end;
  end;
  if ABits < 0 then
    ABits := -ABits;

  if FOob then
  begin
    if ABits = 8 then
    begin
      FData[FCurSize] := Byte(AValue);
      Inc(FCurSize);
      Inc(FBit, 8);
    end
    else if ABits = 16 then
    begin
      FData[FCurSize] := Byte(AValue);
      FData[FCurSize + 1] := Byte(AValue shr 8);
      Inc(FCurSize, 2);
      Inc(FBit, 16);
    end
    else if ABits = 32 then
    begin
      FData[FCurSize] := Byte(AValue);
      FData[FCurSize + 1] := Byte(AValue shr 8);
      FData[FCurSize + 2] := Byte(AValue shr 16);
      FData[FCurSize + 3] := Byte(AValue shr 24);
      Inc(FCurSize, 4);
      // defect of the original, kept: a long moves the bit position by 8, not by 32
      Inc(FBit, 8);
    end
    else
      raise EQ3MessageException.CreateFmt(SQ3MessageCannotReadBits, [ABits]);
  end
  else
  begin
    ReadyForBitStream;
    LValue := Cardinal(AValue) and (Cardinal($FFFFFFFF) shr (32 - ABits));
    if (ABits and 7) <> 0 then
    begin
      LBitCount := ABits and 7;
      for LIndex := 0 to LBitCount - 1 do
      begin
        FCoder.PutBit(Integer(LValue and 1), FData, FBit);
        LValue := LValue shr 1;
      end;
      ABits := ABits - LBitCount;
    end;
    if ABits <> 0 then
    begin
      LIndex := 0;
      while LIndex < ABits do
      begin
        FCoder.Transmit(Integer(LValue and $FF), FData, FBit);
        LValue := LValue shr 8;
        Inc(LIndex, 8);
      end;
    end;
    FCurSize := (FBit shr 3) + 1;
  end;
end;

function TQ3Message.ReadBits(ABits: Integer): Integer;
var
  LValue, LGet, LIndex, LBitCount: Integer;
  LSigned: Boolean;
begin
  LValue := 0;
  if ABits < 0 then
  begin
    ABits := -ABits;
    LSigned := True;
  end
  else
    LSigned := False;

  if FOob then
  begin
    if ABits = 8 then
    begin
      LValue := ByteAt(FReadCount);
      Inc(FReadCount);
      Inc(FBit, 8);
    end
    else if ABits = 16 then
    begin
      LValue := SmallInt(Word(ByteAt(FReadCount) or (ByteAt(FReadCount + 1) shl 8)));
      LValue := LValue and $FFFF;
      Inc(FReadCount, 2);
      Inc(FBit, 16);
    end
    else if ABits = 32 then
    begin
      LValue := ByteAt(FReadCount) or (ByteAt(FReadCount + 1) shl 8) or (ByteAt(FReadCount + 2) shl 16)
        or (ByteAt(FReadCount + 3) shl 24);
      Inc(FReadCount, 4);
      Inc(FBit, 32);
    end
    else
      raise EQ3MessageException.CreateFmt(SQ3MessageCannotReadBits, [ABits]);
  end
  else
  begin
    ReadyForBitStream;
    LBitCount := 0;
    if (ABits and 7) <> 0 then
    begin
      LBitCount := ABits and 7;
      for LIndex := 0 to LBitCount - 1 do
        LValue := LValue or (FCoder.GetBit(FData, FBit) shl LIndex);
      ABits := ABits - LBitCount;
    end;
    if ABits <> 0 then
    begin
      LIndex := 0;
      while LIndex < ABits do
      begin
        LGet := FCoder.Receive(FData, FBit);
        LValue := LValue or (LGet shl ((LIndex + LBitCount) and 31));
        Inc(LIndex, 8);
      end;
    end;
    FReadCount := (FBit shr 3) + 1;
  end;
  if LSigned then
  begin
    // defect of the original, kept: ABits is what is left after the bits below a byte
    if (LValue and (1 shl ((ABits - 1) and 31))) <> 0 then
      LValue := LValue or (-1 xor ((1 shl (ABits and 31)) - 1));
  end;
  Result := LValue;
end;

procedure TQ3Message.WriteChar(AValue: Integer);
begin
  WriteBits(AValue, 8);
end;

procedure TQ3Message.WriteByte(AValue: Integer);
begin
  WriteBits(AValue, 8);
end;

procedure TQ3Message.WriteData(const AData: TBytes; ALength: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ALength - 1 do
    WriteByte(AData[LIndex]);
end;

procedure TQ3Message.WriteShort(AValue: Integer);
begin
  WriteBits(AValue, 16);
end;

procedure TQ3Message.WriteLong(AValue: Integer);
begin
  WriteBits(AValue, 32);
end;

procedure TQ3Message.WriteFloat(AValue: Single);
begin
  WriteBits(FloatToBits(AValue), 32);
end;

procedure TQ3Message.WriteText(const AText: AnsiString; ALimit: Integer; const ALimitName: string);
var
  LLength, LIndex: Integer;
  LBytes: TBytes;
begin
  LLength := 0;
  while (LLength < Length(AText)) and (AText[LLength + 1] <> #0) do
    Inc(LLength);
  if LLength >= ALimit then
  begin
    if Assigned(FLog) then
      FLog.Warning('MSG_WriteString: ' + ALimitName);
    SetLength(LBytes, 1);
    LBytes[0] := 0;
    WriteData(LBytes, 1);
    Exit;
  end;
  SetLength(LBytes, LLength + 1);
  for LIndex := 0 to LLength - 1 do
  begin
    // get rid of 0xff chars, because old clients don't like them
    if Byte(AText[LIndex + 1]) > 127 then
      LBytes[LIndex] := Ord('.')
    else
      LBytes[LIndex] := Byte(AText[LIndex + 1]);
  end;
  LBytes[LLength] := 0;
  WriteData(LBytes, LLength + 1);
end;

procedure TQ3Message.WriteString(const AText: AnsiString);
begin
  WriteText(AText, Q3_MAX_STRING_CHARS, 'MAX_STRING_CHARS');
end;

procedure TQ3Message.WriteBigString(const AText: AnsiString);
begin
  WriteText(AText, Q3_BIG_INFO_STRING, 'BIG_INFO_STRING');
end;

procedure TQ3Message.WriteAngle(AValue: Single);
var
  LScaled: Single;
begin
  LScaled := AValue * 256;
  LScaled := Double(LScaled) / 360;
  WriteByte(TruncToInteger(LScaled) and 255);
end;

procedure TQ3Message.WriteAngle16(AValue: Single);
begin
  WriteShort(AngleToShort(AValue));
end;

function TQ3Message.ReadChar: Integer;
begin
  Result := ShortInt(ReadBits(8));
  if FReadCount > FCurSize then
    Result := -1;
end;

function TQ3Message.ReadByte: Integer;
begin
  Result := Byte(ReadBits(8));
  if FReadCount > FCurSize then
    Result := -1;
end;

function TQ3Message.ReadShort: Integer;
begin
  Result := SmallInt(ReadBits(16));
  if FReadCount > FCurSize then
    Result := -1;
end;

function TQ3Message.ReadLong: Integer;
begin
  Result := ReadBits(32);
  if FReadCount > FCurSize then
    Result := -1;
end;

function TQ3Message.ReadFloat: Single;
var
  LBits: Integer;
begin
  LBits := ReadBits(32);
  if FReadCount > FCurSize then
    Result := -1
  else
    Result := BitsToFloat(LBits);
end;

function TQ3Message.ReadTextLimited(ALimit: Integer; AMask7Bit, AStopAtNewline: Boolean): AnsiString;
var
  LBuffer: TBytes;
  LLength, LChar: Integer;
begin
  SetLength(LBuffer, ALimit);
  LLength := 0;
  repeat
    LChar := ReadByte; // ReadByte so -1 is out of bounds
    if (LChar = -1) or (LChar = 0) or (AStopAtNewline and (LChar = 10)) then
      Break;
    // translate all fmt spec to avoid crash bugs
    if LChar = Ord('%') then
      LChar := Ord('.');
    // don't allow higher ascii values
    if AMask7Bit and (LChar > 127) then
      LChar := Ord('.');
    LBuffer[LLength] := Byte(LChar);
    Inc(LLength);
  until LLength >= ALimit - 1;
  SetString(Result, PAnsiChar(@LBuffer[0]), LLength);
end;

function TQ3Message.ReadString: AnsiString;
begin
  Result := ReadTextLimited(Q3_MAX_STRING_CHARS, True, False);
end;

function TQ3Message.ReadBigString: AnsiString;
begin
  Result := ReadTextLimited(Q3_BIG_INFO_STRING, False, False);
end;

function TQ3Message.ReadStringLine: AnsiString;
begin
  Result := ReadTextLimited(Q3_MAX_STRING_CHARS, False, True);
end;

function TQ3Message.ReadAngle16: Single;
begin
  Result := ShortToAngle(ReadShort);
end;

procedure TQ3Message.ReadData(var AData: TBytes; ALength: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ALength - 1 do
    AData[LIndex] := Byte(ReadByte);
end;

procedure TQ3Message.WriteDelta(AOldValue, ANewValue, ABits: Integer);
begin
  if AOldValue = ANewValue then
  begin
    WriteBits(0, 1);
    Exit;
  end;
  WriteBits(1, 1);
  WriteBits(ANewValue, ABits);
end;

function TQ3Message.ReadDelta(AOldValue, ABits: Integer): Integer;
begin
  if ReadBits(1) <> 0 then
    Result := ReadBits(ABits)
  else
    Result := AOldValue;
end;

procedure TQ3Message.WriteDeltaFloat(AOldValue, ANewValue: Single);
begin
  // the original compares the floats, not their bits: -0 equals 0
  if FloatsEqual(AOldValue, ANewValue) then
  begin
    WriteBits(0, 1);
    Exit;
  end;
  WriteBits(1, 1);
  WriteBits(FloatToBits(ANewValue), 32);
end;

function TQ3Message.ReadDeltaFloat(AOldValue: Single): Single;
begin
  if ReadBits(1) <> 0 then
    Result := BitsToFloat(ReadBits(32))
  else
    Result := AOldValue;
end;

procedure TQ3Message.WriteDeltaKey(AKey, AOldValue, ANewValue, ABits: Integer);
begin
  if AOldValue = ANewValue then
  begin
    WriteBits(0, 1);
    Exit;
  end;
  WriteBits(1, 1);
  WriteBits(ANewValue xor AKey, ABits);
end;

function TQ3Message.ReadDeltaKey(AKey, AOldValue, ABits: Integer): Integer;
var
  LMask: Integer;
begin
  if ReadBits(1) <> 0 then
  begin
    // kbitmask[bits]: bits + 1 ones
    if ABits >= 31 then
      LMask := -1
    else if ABits < 0 then
      LMask := 0
    else
      LMask := (1 shl (ABits + 1)) - 1;
    Result := ReadBits(ABits) xor (AKey and LMask);
  end
  else
    Result := AOldValue;
end;

procedure TQ3Message.WriteDeltaKeyFloat(AKey: Integer; AOldValue, ANewValue: Single);
begin
  if FloatsEqual(AOldValue, ANewValue) then
  begin
    WriteBits(0, 1);
    Exit;
  end;
  WriteBits(1, 1);
  WriteBits(FloatToBits(ANewValue) xor AKey, 32);
end;

function TQ3Message.ReadDeltaKeyFloat(AKey: Integer; AOldValue: Single): Single;
begin
  if ReadBits(1) <> 0 then
    Result := BitsToFloat(ReadBits(32) xor AKey)
  else
    Result := AOldValue;
end;

end.
