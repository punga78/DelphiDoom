{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - TBitMessageDelta, delta of bit messages           }
{  (idBitMsgDelta)                                                             }
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
unit DelphiDoom.Net.BitMessageDelta;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Net.BitMessage.Types, DelphiDoom.Net.BitMessage.Intf;

type
  /// <summary>
  ///   idBitMsgDelta: writes (or reads) a message as the difference from a base message and, at the same
  ///   time, builds the new base. For every field it reads the same field from the base; an unchanged
  ///   field costs one bit in the delta. Without a base (nil) every field is written whole.
  ///   <para>Writing: <c>Init(base, newBase, delta, delta)</c>; reading: <c>Init(base, newBase, nil, delta)</c>.
  ///   The base, the new base and the delta are not owned and not freed; the base and the delta being
  ///   read advance their read position as the fields are read, so call <c>BeginReading</c> on them first.
  ///   <c>HasChanged</c> tells if the new base differs from the base.</para>
  ///   <para>Differences from the original: the three messages are interfaces
  ///   (<c>IBitMessageWriter</c>/<c>IBitMessageReader</c>), <c>ReadString</c> returns the text and
  ///   <c>ReadData</c> fills a buffer that the caller sizes.</para>
  /// </summary>
  TBitMessageDelta = class
  strict private
    FBase: IBitMessageReader;
    FNewBase: IBitMessageWriter;
    FWriteDelta: IBitMessageWriter;
    FReadDelta: IBitMessageReader;
    FChanged: Boolean;
    procedure WriteDelta(AOldValue, ANewValue, ANumBits: Integer);
    function ReadDelta(AOldValue, ANumBits: Integer): Integer;
    function DeltaIsUnchanged: Boolean;
  public
    /// <summary>Any of the four may be nil (no base, no new base, only writing, only reading)</summary>
    procedure Init(const ABase: IBitMessageReader; const ANewBase: IBitMessageWriter;
      const AWriteDelta: IBitMessageWriter; const AReadDelta: IBitMessageReader);
    function HasChanged: Boolean;

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
    procedure WriteString(const AText: AnsiString; AMaxLength: Integer = -1);
    procedure WriteData(AData: PByte; ALength: Integer);
    procedure WriteDict(const ADict: TIdDict);
    procedure WriteDeltaChar(AOldValue, ANewValue: Integer);
    procedure WriteDeltaByte(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShort(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLong(AOldValue, ANewValue: Integer);
    procedure WriteDeltaFloat(AOldValue, ANewValue: Single); overload;
    procedure WriteDeltaFloat(AOldValue, ANewValue: Single; AExponentBits, AMantissaBits: Integer); overload;
    procedure WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLongCounter(AOldValue, ANewValue: Integer);

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
    procedure ReadData(AData: PByte; ALength: Integer);
    procedure ReadDict(const ADict: TIdDict);
    function ReadDeltaChar(AOldValue: Integer): Integer;
    function ReadDeltaByte(AOldValue: Integer): Integer;
    function ReadDeltaShort(AOldValue: Integer): Integer;
    function ReadDeltaLong(AOldValue: Integer): Integer;
    function ReadDeltaFloat(AOldValue: Single): Single; overload;
    function ReadDeltaFloat(AOldValue: Single; AExponentBits, AMantissaBits: Integer): Single; overload;
    function ReadDeltaByteCounter(AOldValue: Integer): Integer;
    function ReadDeltaShortCounter(AOldValue: Integer): Integer;
    function ReadDeltaLongCounter(AOldValue: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Net.BitMessage;

function FloatBits(const AValue: Single): Integer; inline;
begin
  Result := PInteger(@AValue)^;
end;

function BitsFloat(const AValue: Integer): Single; inline;
begin
  Result := PSingle(@AValue)^;
end;

{ TBitMessageDelta }

procedure TBitMessageDelta.Init(const ABase: IBitMessageReader; const ANewBase: IBitMessageWriter;
  const AWriteDelta: IBitMessageWriter; const AReadDelta: IBitMessageReader);
begin
  FBase := ABase;
  FNewBase := ANewBase;
  FWriteDelta := AWriteDelta;
  FReadDelta := AReadDelta;
  FChanged := False;
end;

function TBitMessageDelta.HasChanged: Boolean;
begin
  Result := FChanged;
end;

function TBitMessageDelta.DeltaIsUnchanged: Boolean;
begin
  // "!readDelta || readDelta->ReadBits( 1 ) == 0"
  Result := (not Assigned(FReadDelta)) or (FReadDelta.ReadBits(1) = 0);
end;

procedure TBitMessageDelta.WriteBits(AValue, ANumBits: Integer);
var
  LBaseValue: Integer;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteBits(AValue, ANumBits);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteBits(AValue, ANumBits);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(ANumBits);
    if LBaseValue = AValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteBits(AValue, ANumBits);
      FChanged := True;
    end;
  end;
end;

procedure TBitMessageDelta.WriteDelta(AOldValue, ANewValue, ANumBits: Integer);
var
  LBaseValue: Integer;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteBits(ANewValue, ANumBits);
  if not Assigned(FBase) then
  begin
    if AOldValue = ANewValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteBits(ANewValue, ANumBits);
    end;
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(ANumBits);
    if LBaseValue = ANewValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      if AOldValue = ANewValue then
      begin
        FWriteDelta.WriteBits(0, 1);
        FChanged := True;
      end
      else
      begin
        FWriteDelta.WriteBits(1, 1);
        FWriteDelta.WriteBits(ANewValue, ANumBits);
        FChanged := True;
      end;
    end;
  end;
end;

function TBitMessageDelta.ReadBits(ANumBits: Integer): Integer;
var
  LBaseValue: Integer;
begin
  if not Assigned(FBase) then
  begin
    Result := FReadDelta.ReadBits(ANumBits);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(ANumBits);
    if DeltaIsUnchanged then
      Result := LBaseValue
    else
    begin
      Result := FReadDelta.ReadBits(ANumBits);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteBits(Result, ANumBits);
end;

function TBitMessageDelta.ReadDelta(AOldValue, ANumBits: Integer): Integer;
var
  LBaseValue: Integer;
begin
  if not Assigned(FBase) then
  begin
    if FReadDelta.ReadBits(1) = 0 then
      Result := AOldValue
    else
      Result := FReadDelta.ReadBits(ANumBits);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(ANumBits);
    if DeltaIsUnchanged then
      Result := LBaseValue
    else if FReadDelta.ReadBits(1) = 0 then
    begin
      Result := AOldValue;
      FChanged := True;
    end
    else
    begin
      Result := FReadDelta.ReadBits(ANumBits);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteBits(Result, ANumBits);
end;

procedure TBitMessageDelta.WriteChar(AValue: Integer);
begin
  WriteBits(AValue, -8);
end;

procedure TBitMessageDelta.WriteByte(AValue: Integer);
begin
  WriteBits(AValue, 8);
end;

procedure TBitMessageDelta.WriteShort(AValue: Integer);
begin
  WriteBits(AValue, -16);
end;

procedure TBitMessageDelta.WriteUShort(AValue: Integer);
begin
  WriteBits(AValue, 16);
end;

procedure TBitMessageDelta.WriteLong(AValue: Integer);
begin
  WriteBits(AValue, 32);
end;

procedure TBitMessageDelta.WriteFloat(AValue: Single);
begin
  WriteBits(FloatBits(AValue), 32);
end;

procedure TBitMessageDelta.WriteFloat(AValue: Single; AExponentBits, AMantissaBits: Integer);
begin
  WriteBits(TIdMath.FloatToBits(AValue, AExponentBits, AMantissaBits), 1 + AExponentBits + AMantissaBits);
end;

procedure TBitMessageDelta.WriteAngle8(AValue: Single);
var
  LScaled: Single;
begin
  LScaled := AValue * 256.0;
  LScaled := LScaled / 360.0;
  WriteBits(TIdMath.FtoiFast(LScaled) and 255, 8);
end;

procedure TBitMessageDelta.WriteAngle16(AValue: Single);
var
  LScaled: Single;
begin
  LScaled := AValue * 65536.0;
  LScaled := LScaled / 360.0;
  WriteBits(TIdMath.FtoiFast(LScaled) and 65535, 16);
end;

procedure TBitMessageDelta.WriteDir(const ADir: TIdVec3; ANumBits: Integer);
begin
  WriteBits(TBitMessage.DirToBits(ADir, ANumBits), ANumBits);
end;

procedure TBitMessageDelta.WriteString(const AText: AnsiString; AMaxLength: Integer);
var
  LBaseText: AnsiString;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteString(AText, AMaxLength);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteString(AText, AMaxLength);
    FChanged := True;
  end
  else
  begin
    LBaseText := FBase.ReadString(BITMSG_MAX_DATA_BUFFER);
    if TIdStrings.Cmp(AText, LBaseText) = 0 then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteString(AText, AMaxLength);
      FChanged := True;
    end;
  end;
end;

procedure TBitMessageDelta.WriteData(AData: PByte; ALength: Integer);
var
  LBaseData: TBytes;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteData(AData, ALength);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteData(AData, ALength);
    FChanged := True;
  end
  else
  begin
    // the buffer starts at zero: the original compares what the stack held if the base is shorter
    SetLength(LBaseData, ALength);
    if ALength > 0 then
      FillChar(LBaseData[0], ALength, 0);
    FBase.ReadData(PByte(LBaseData), ALength);
    if (ALength = 0) or CompareMem(AData, @LBaseData[0], ALength) then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteData(AData, ALength);
      FChanged := True;
    end;
  end;
end;

procedure TBitMessageDelta.WriteDict(const ADict: TIdDict);
var
  LBaseDict: TIdDict;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteDeltaDict(ADict, nil);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteDeltaDict(ADict, nil);
    FChanged := True;
  end
  else
  begin
    LBaseDict := TIdDict.Create;
    try
      FBase.ReadDeltaDict(LBaseDict, nil);
      FChanged := FWriteDelta.WriteDeltaDict(ADict, LBaseDict);
    finally
      LBaseDict.Free;
    end;
  end;
end;

procedure TBitMessageDelta.WriteDeltaChar(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, -8);
end;

procedure TBitMessageDelta.WriteDeltaByte(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, 8);
end;

procedure TBitMessageDelta.WriteDeltaShort(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, -16);
end;

procedure TBitMessageDelta.WriteDeltaLong(AOldValue, ANewValue: Integer);
begin
  WriteDelta(AOldValue, ANewValue, 32);
end;

procedure TBitMessageDelta.WriteDeltaFloat(AOldValue, ANewValue: Single);
begin
  WriteDelta(FloatBits(AOldValue), FloatBits(ANewValue), 32);
end;

procedure TBitMessageDelta.WriteDeltaFloat(AOldValue, ANewValue: Single; AExponentBits, AMantissaBits: Integer);
var
  LOldBits, LNewBits: Integer;
begin
  LOldBits := TIdMath.FloatToBits(AOldValue, AExponentBits, AMantissaBits);
  LNewBits := TIdMath.FloatToBits(ANewValue, AExponentBits, AMantissaBits);
  WriteDelta(LOldBits, LNewBits, 1 + AExponentBits + AMantissaBits);
end;

procedure TBitMessageDelta.WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
var
  LBaseValue: Integer;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteBits(ANewValue, 8);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteDeltaByteCounter(AOldValue, ANewValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(8);
    if LBaseValue = ANewValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteDeltaByteCounter(AOldValue, ANewValue);
      FChanged := True;
    end;
  end;
end;

procedure TBitMessageDelta.WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
var
  LBaseValue: Integer;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteBits(ANewValue, 16);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteDeltaShortCounter(AOldValue, ANewValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(16);
    if LBaseValue = ANewValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteDeltaShortCounter(AOldValue, ANewValue);
      FChanged := True;
    end;
  end;
end;

procedure TBitMessageDelta.WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
var
  LBaseValue: Integer;
begin
  if Assigned(FNewBase) then
    FNewBase.WriteBits(ANewValue, 32);
  if not Assigned(FBase) then
  begin
    FWriteDelta.WriteDeltaLongCounter(AOldValue, ANewValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(32);
    if LBaseValue = ANewValue then
      FWriteDelta.WriteBits(0, 1)
    else
    begin
      FWriteDelta.WriteBits(1, 1);
      FWriteDelta.WriteDeltaLongCounter(AOldValue, ANewValue);
      FChanged := True;
    end;
  end;
end;

function TBitMessageDelta.ReadChar: Integer;
begin
  Result := ShortInt(ReadBits(-8));
end;

function TBitMessageDelta.ReadByte: Integer;
begin
  Result := Byte(ReadBits(8));
end;

function TBitMessageDelta.ReadShort: Integer;
begin
  Result := SmallInt(ReadBits(-16));
end;

function TBitMessageDelta.ReadUShort: Integer;
begin
  Result := Word(ReadBits(16));
end;

function TBitMessageDelta.ReadLong: Integer;
begin
  Result := ReadBits(32);
end;

function TBitMessageDelta.ReadFloat: Single;
begin
  Result := BitsFloat(ReadBits(32));
end;

function TBitMessageDelta.ReadFloat(AExponentBits, AMantissaBits: Integer): Single;
begin
  Result := TIdMath.BitsToFloat(ReadBits(1 + AExponentBits + AMantissaBits), AExponentBits, AMantissaBits);
end;

function TBitMessageDelta.ReadAngle8: Single;
begin
  Result := ReadByte * 1.40625;
end;

function TBitMessageDelta.ReadAngle16: Single;
begin
  Result := ReadShort * (360.0 / 65536.0);
end;

function TBitMessageDelta.ReadDir(ANumBits: Integer): TIdVec3;
begin
  Result := TBitMessage.BitsToDir(ReadBits(ANumBits), ANumBits);
end;

function TBitMessageDelta.ReadString(ABufferSize: Integer): AnsiString;
var
  LBaseText: AnsiString;
begin
  if not Assigned(FBase) then
  begin
    Result := FReadDelta.ReadString(ABufferSize);
    FChanged := True;
  end
  else
  begin
    LBaseText := FBase.ReadString(BITMSG_MAX_DATA_BUFFER);
    if DeltaIsUnchanged then
    begin
      // idStr::Copynz: at most ABufferSize - 1 characters
      Result := Copy(LBaseText, 1, ABufferSize - 1);
    end
    else
    begin
      Result := FReadDelta.ReadString(ABufferSize);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteString(Result);
end;

procedure TBitMessageDelta.ReadData(AData: PByte; ALength: Integer);
var
  LBaseData: TBytes;
begin
  if not Assigned(FBase) then
  begin
    FReadDelta.ReadData(AData, ALength);
    FChanged := True;
  end
  else
  begin
    SetLength(LBaseData, ALength);
    if ALength > 0 then
      FillChar(LBaseData[0], ALength, 0);
    FBase.ReadData(PByte(LBaseData), ALength);
    if DeltaIsUnchanged then
    begin
      if ALength > 0 then
        Move(LBaseData[0], AData^, ALength);
    end
    else
    begin
      FReadDelta.ReadData(AData, ALength);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteData(AData, ALength);
end;

procedure TBitMessageDelta.ReadDict(const ADict: TIdDict);
var
  LBaseDict: TIdDict;
begin
  if not Assigned(FBase) then
  begin
    FReadDelta.ReadDeltaDict(ADict, nil);
    FChanged := True;
  end
  else
  begin
    LBaseDict := TIdDict.Create;
    try
      FBase.ReadDeltaDict(LBaseDict, nil);
      if not Assigned(FReadDelta) then
        ADict.Assign(LBaseDict)
      else
        FChanged := FReadDelta.ReadDeltaDict(ADict, LBaseDict);
    finally
      LBaseDict.Free;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteDeltaDict(ADict, nil);
end;

function TBitMessageDelta.ReadDeltaChar(AOldValue: Integer): Integer;
begin
  Result := ShortInt(ReadDelta(AOldValue, -8));
end;

function TBitMessageDelta.ReadDeltaByte(AOldValue: Integer): Integer;
begin
  Result := Byte(ReadDelta(AOldValue, 8));
end;

function TBitMessageDelta.ReadDeltaShort(AOldValue: Integer): Integer;
begin
  Result := SmallInt(ReadDelta(AOldValue, -16));
end;

function TBitMessageDelta.ReadDeltaLong(AOldValue: Integer): Integer;
begin
  Result := ReadDelta(AOldValue, 32);
end;

function TBitMessageDelta.ReadDeltaFloat(AOldValue: Single): Single;
begin
  Result := BitsFloat(ReadDelta(FloatBits(AOldValue), 32));
end;

function TBitMessageDelta.ReadDeltaFloat(AOldValue: Single; AExponentBits, AMantissaBits: Integer): Single;
var
  LOldBits, LNewBits: Integer;
begin
  LOldBits := TIdMath.FloatToBits(AOldValue, AExponentBits, AMantissaBits);
  LNewBits := ReadDelta(LOldBits, 1 + AExponentBits + AMantissaBits);
  Result := TIdMath.BitsToFloat(LNewBits, AExponentBits, AMantissaBits);
end;

function TBitMessageDelta.ReadDeltaByteCounter(AOldValue: Integer): Integer;
var
  LBaseValue: Integer;
begin
  if not Assigned(FBase) then
  begin
    Result := FReadDelta.ReadDeltaByteCounter(AOldValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(8);
    if DeltaIsUnchanged then
      Result := LBaseValue
    else
    begin
      Result := FReadDelta.ReadDeltaByteCounter(AOldValue);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteBits(Result, 8);
end;

function TBitMessageDelta.ReadDeltaShortCounter(AOldValue: Integer): Integer;
var
  LBaseValue: Integer;
begin
  if not Assigned(FBase) then
  begin
    Result := FReadDelta.ReadDeltaShortCounter(AOldValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(16);
    if DeltaIsUnchanged then
      Result := LBaseValue
    else
    begin
      Result := FReadDelta.ReadDeltaShortCounter(AOldValue);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteBits(Result, 16);
end;

function TBitMessageDelta.ReadDeltaLongCounter(AOldValue: Integer): Integer;
var
  LBaseValue: Integer;
begin
  if not Assigned(FBase) then
  begin
    Result := FReadDelta.ReadDeltaLongCounter(AOldValue);
    FChanged := True;
  end
  else
  begin
    LBaseValue := FBase.ReadBits(32);
    if DeltaIsUnchanged then
      Result := LBaseValue
    else
    begin
      Result := FReadDelta.ReadDeltaLongCounter(AOldValue);
      FChanged := True;
    end;
  end;
  if Assigned(FNewBase) then
    FNewBase.WriteBits(Result, 32);
end;

end.
