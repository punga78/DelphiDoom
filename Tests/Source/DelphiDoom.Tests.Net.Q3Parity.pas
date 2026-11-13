{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the network of Quake III with msg.c, huffman.c and    }
{  net_chan.c                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3Parity;

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message,
  DelphiDoom.Net.Q3.MessageHuffman, DelphiDoom.Net.Q3.HuffmanCompressor, DelphiDoom.Net.Q3.NetFieldTable,
  DelphiDoom.Net.Q3.UserCmdCodec, DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec,
  DelphiDoom.Net.Q3.Netchan, DelphiDoom.Tests.Net.Q3Fakes;

type
  /// <summary>
  ///   Runs the scenarios of netgen.c (Tools\Verifica\121) with the Delphi classes and compares every
  ///   line with Tests\Data\Net\q3net-golden.txt, which the real huffman.c, msg.c and net_chan.c of Quake III
  ///   wrote: message bytes in hex, sizes, bit positions, every value read back, hashes of the encoded states.
  /// </summary>
  [TestFixture]
  [Category('Net')]
  TTestQ3Parity = class
  strict private
    FCoder: IQ3HuffmanCoder;
    FSections: TDictionary<string, TStringList>;
    FLines: TStringList;
    FLog: TFakeQ3Log;
    FLogIntf: ILog;
    FRandom: Cardinal;
    FTransport: TFakeQ3Transport;
    FTransportIntf: IQ3NetTransport;
    FProcessBuffer: TBytes;
    function NextRandom: Cardinal;
    procedure Emit(const ALine: string);
    procedure EmitFmt(const AFormat: string; const AArguments: array of const);
    function Hex(const AData: TBytes; AStart, ACount: Integer): string;
    function Fnv(const AData: TBytes; AStart, ACount: Integer): Cardinal;
    function FnvRecord(const ARecord; ASize: Integer): Cardinal;
    function Hex32(AValue: Cardinal): string;
    function NewMessage(const ABuffer: TBytes; ALength: Integer; AOob: Boolean = False): TQ3Message;
    procedure Dump(const ATag: string; AMessage: TQ3Message);
    procedure FlushLog(const ATag: string);
    procedure Compare(const ASection: string);
    procedure RandomField(AField: PInteger; ABits: Integer);
    // appenders of values read one at a time
    procedure AppendBits(var ALine: string; AMessage: TQ3Message; const AName: string; ABits: Integer);
    procedure AppendByte(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendChar(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendShort(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendLong(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendFloat(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendString(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendLine(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendBig(var ALine: string; AMessage: TQ3Message; const AName: string);
    procedure AppendDelta(var ALine: string; AMessage: TQ3Message; const AName: string; AOld, ABits: Integer);
    procedure AppendDeltaFloat(var ALine: string; AMessage: TQ3Message; const AName: string; AOld: Single);
    procedure AppendDeltaKey(var ALine: string; AMessage: TQ3Message; const AName: string; AKey, AOld, ABits: Integer);
    procedure AppendDeltaKeyFloat(var ALine: string; AMessage: TQ3Message; const AName: string; AKey: Integer;
      AOld: Single);
    procedure ScenarioBits;
    procedure ScenarioOob;
    procedure ScenarioDelta;
    procedure ScenarioEntity;
    procedure ScenarioPlayer;
    procedure ScenarioHuffman;
    procedure ScenarioNetchan;
    procedure HuffmanCase(const ATag: string; const APayload: TBytes; ALength, AOffset: Integer);
    procedure PrintFields(const AName: string; const ATable: IQ3NetFieldTable);
    procedure PrintCaptured(const ATag: string);
    function ProcessPacket(const ATag: string; AChannel: TQ3Netchan; AIndex: Integer): Boolean;
    procedure SendAll(AChannel: TQ3Netchan; ALength, ASeed: Integer);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereELeggereIBitCometIlC;
    [Test]
    procedure DovrebbeGestireIMessaggiOutOfBandCometIlC;
    [Test]
    procedure DovrebbeScrivereIDeltaECometIlC;
    [Test]
    procedure DovrebbeScrivereIDeltaDelleEntitaCometIlC;
    [Test]
    procedure DovrebbeScrivereIDeltaDelPlayerstateCometIlC;
    [Test]
    procedure DovrebbeComprimereConLHuffmanAdattivoCometIlC;
    [Test]
    procedure DovrebbeFrammentareERiassemblareCometIlNetchan;
  end;

implementation

const
  FloatPalette: array[0..15] of Single = (0.0, 0.0, 1.0, -1.0, 100.0, 4095.0, -4096.0, 4096.0, -4097.0,
    3.14159, 1e10, -2.5, 0.5, 123456.0, 2147483648.0, -2147483648.0);

function SectionOfLine(const ALine, ACurrent: string): string;
begin
  if (ALine = '') or (ALine[1] = ' ') then
    Result := ACurrent
  else if ALine.StartsWith('bits.') then
    Result := 'bits'
  else if ALine.StartsWith('oob.') then
    Result := 'oob'
  else if ALine.StartsWith('delta.') or ALine.StartsWith('usercmd') then
    Result := 'delta'
  else if ALine.StartsWith('entity') then
    Result := 'entity'
  else if ALine.StartsWith('player') then
    Result := 'player'
  else if ALine.StartsWith('huffman.') then
    Result := 'huffman'
  else
    Result := 'netchan';
end;

function NewBuffer(ALength: Integer): TBytes;
begin
  SetLength(Result, ALength);
  if ALength > 0 then
    FillChar(Result[0], ALength, 0);
end;

{ TTestQ3Parity }

procedure TTestQ3Parity.SetupFixture;
var
  LLine, LSection, LCurrent: string;
  LList: TStringList;
begin
  FCoder := TQ3MessageHuffman.Create;
  FSections := TDictionary<string, TStringList>.Create;
  LCurrent := '';
  for LLine in TFile.ReadAllLines(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Net\q3net-golden.txt'))) do
  begin
    LSection := SectionOfLine(LLine, LCurrent);
    LCurrent := LSection;
    if not FSections.TryGetValue(LSection, LList) then
    begin
      LList := TStringList.Create;
      FSections.Add(LSection, LList);
    end;
    LList.Add(LLine);
  end;
end;

procedure TTestQ3Parity.TearDownFixture;
var
  LList: TStringList;
begin
  for LList in FSections.Values do
    LList.Free;
  FSections.Free;
  FCoder := nil;
end;

procedure TTestQ3Parity.Setup;
begin
  FLines := TStringList.Create;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FTransport := TFakeQ3Transport.Create;
  FTransportIntf := FTransport;
  SetLength(FProcessBuffer, Q3_MAX_MSGLEN + 16);
end;

procedure TTestQ3Parity.TearDown;
begin
  FTransportIntf := nil;
  FLogIntf := nil;
  FLines.Free;
end;

function TTestQ3Parity.NextRandom: Cardinal;
begin
  FRandom := FRandom xor (FRandom shl 13);
  FRandom := FRandom xor (FRandom shr 17);
  FRandom := FRandom xor (FRandom shl 5);
  Result := FRandom;
end;

procedure TTestQ3Parity.Emit(const ALine: string);
begin
  FLines.Add(ALine);
end;

procedure TTestQ3Parity.EmitFmt(const AFormat: string; const AArguments: array of const);
begin
  FLines.Add(Format(AFormat, AArguments));
end;

function TTestQ3Parity.Hex(const AData: TBytes; AStart, ACount: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := AStart to AStart + ACount - 1 do
    Result := Result + LowerCase(IntToHex(AData[LIndex], 2));
end;

function TTestQ3Parity.Fnv(const AData: TBytes; AStart, ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := AStart to AStart + ACount - 1 do
  begin
    Result := Result xor AData[LIndex];
    Result := Result * 16777619;
  end;
end;

function TTestQ3Parity.FnvRecord(const ARecord; ASize: Integer): Cardinal;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ASize);
  Move(ARecord, LBytes[0], ASize);
  Result := Fnv(LBytes, 0, ASize);
end;

function TTestQ3Parity.Hex32(AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

function TTestQ3Parity.NewMessage(const ABuffer: TBytes; ALength: Integer; AOob: Boolean): TQ3Message;
begin
  Result := TQ3Message.Create(FCoder, FLogIntf);
  if AOob then
    Result.InitOOB(ABuffer, ALength)
  else
    Result.Init(ABuffer, ALength);
end;

procedure TTestQ3Parity.FlushLog(const ATag: string);
begin
  if FLog.Text <> '' then
  begin
    EmitFmt('%s print %s', [ATag, FLog.Text]);
    FLog.Clear;
  end;
end;

procedure TTestQ3Parity.Dump(const ATag: string; AMessage: TQ3Message);
begin
  EmitFmt('%s size=%d bit=%d overflowed=%d hex=%s', [ATag, AMessage.CurSize, AMessage.Bit,
    Ord(AMessage.Overflowed), Hex(AMessage.Data, 0, AMessage.CurSize)]);
  FlushLog(ATag);
end;

procedure TTestQ3Parity.Compare(const ASection: string);
var
  LExpected: TStringList;
  LIndex: Integer;
begin
  Assert.IsTrue(FSections.TryGetValue(ASection, LExpected), 'sezione assente: ' + ASection);
  for LIndex := 0 to LExpected.Count - 1 do
  begin
    Assert.IsTrue(LIndex < FLines.Count, 'mancano righe dopo la ' + IntToStr(LIndex) + ': ' + LExpected[LIndex]);
    Assert.AreEqual(LExpected[LIndex], FLines[LIndex], 'riga ' + IntToStr(LIndex + 1) + ' di ' + ASection);
  end;
  Assert.AreEqual(LExpected.Count, FLines.Count, 'righe in piu'' di quelle del golden');
end;

procedure TTestQ3Parity.RandomField(AField: PInteger; ABits: Integer);
var
  LValue: Cardinal;
  LBits, LSigned, LIndex: Integer;
begin
  if ABits = 0 then
  begin
    LIndex := NextRandom mod 16;
    if LIndex = 1 then
      AField^ := Integer($80000000) // -0.0
    else
      AField^ := TQ3Message.FloatToBits(FloatPalette[LIndex]);
    Exit;
  end;
  if NextRandom mod 4 = 0 then
  begin
    AField^ := 0;
    Exit;
  end;
  LValue := NextRandom;
  if ABits = 32 then
    AField^ := Integer(LValue)
  else if ABits > 0 then
    AField^ := Integer(LValue and ((Cardinal(1) shl ABits) - 1))
  else
  begin
    LBits := -ABits;
    LSigned := Integer(LValue and ((Cardinal(1) shl LBits) - 1));
    if (LSigned and (1 shl (LBits - 1))) <> 0 then
      LSigned := LSigned or (-1 xor ((1 shl LBits) - 1));
    AField^ := LSigned;
  end;
end;

procedure TTestQ3Parity.AppendBits(var ALine: string; AMessage: TQ3Message; const AName: string; ABits: Integer);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadBits(ABits)]);
end;

procedure TTestQ3Parity.AppendByte(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadByte]);
end;

procedure TTestQ3Parity.AppendChar(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadChar]);
end;

procedure TTestQ3Parity.AppendShort(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadShort]);
end;

procedure TTestQ3Parity.AppendLong(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadLong]);
end;

procedure TTestQ3Parity.AppendFloat(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=%s', [AName, Hex32(Cardinal(TQ3Message.FloatToBits(AMessage.ReadFloat)))]);
end;

procedure TTestQ3Parity.AppendString(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=[%s]', [AName, string(AMessage.ReadString)]);
end;

procedure TTestQ3Parity.AppendLine(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=[%s]', [AName, string(AMessage.ReadStringLine)]);
end;

procedure TTestQ3Parity.AppendBig(var ALine: string; AMessage: TQ3Message; const AName: string);
begin
  ALine := ALine + Format(' %s=[%s]', [AName, string(AMessage.ReadBigString)]);
end;

procedure TTestQ3Parity.AppendDelta(var ALine: string; AMessage: TQ3Message; const AName: string; AOld, ABits: Integer);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadDelta(AOld, ABits)]);
end;

procedure TTestQ3Parity.AppendDeltaFloat(var ALine: string; AMessage: TQ3Message; const AName: string; AOld: Single);
begin
  ALine := ALine + Format(' %s=%s', [AName, Hex32(Cardinal(TQ3Message.FloatToBits(AMessage.ReadDeltaFloat(AOld))))]);
end;

procedure TTestQ3Parity.AppendDeltaKey(var ALine: string; AMessage: TQ3Message; const AName: string;
  AKey, AOld, ABits: Integer);
begin
  ALine := ALine + Format(' %s=%d', [AName, AMessage.ReadDeltaKey(AKey, AOld, ABits)]);
end;

procedure TTestQ3Parity.AppendDeltaKeyFloat(var ALine: string; AMessage: TQ3Message; const AName: string;
  AKey: Integer; AOld: Single);
begin
  ALine := ALine + Format(' %s=%s', [AName,
    Hex32(Cardinal(TQ3Message.FloatToBits(AMessage.ReadDeltaKeyFloat(AKey, AOld))))]);
end;

procedure TTestQ3Parity.ScenarioBits;
var
  LBuffer, LBig, LGot, LData: TBytes;
  LMessage, LOther: TQ3Message;
  LLine, LLong: string;
  LLongText: AnsiString;
  LSize, LIndex: Integer;
begin
  LBuffer := NewBuffer(160);
  LMessage := NewMessage(LBuffer, 128);
  try
    LMessage.WriteByte($AB);
    LMessage.WriteChar(-5);
    LMessage.WriteShort(-1234);
    LMessage.WriteLong($12345678);
    LMessage.WriteFloat(3.5);
    LMessage.WriteFloat(TQ3Message.BitsToFloat(Integer($80000000)));
    LMessage.WriteString(AnsiString('hello%') + AnsiChar($FF) + AnsiString(' world'));
    LMessage.WriteBigString(AnsiString('big') + AnsiChar($FF) + AnsiString('%s'));
    LMessage.WriteAngle(90.0);
    LMessage.WriteAngle(-45.5);
    LMessage.WriteAngle16(180.0);
    LMessage.WriteBits(5, 3);
    LMessage.WriteBits(-3, -4);
    LMessage.WriteBits($1234, 13);
    LMessage.WriteBits($7FFFFFFF, 31);
    LMessage.WriteBits(-1, 32);
    LMessage.WriteBits(1000, -12);
    LMessage.WriteBits(2047, -12);
    LMessage.WriteBits(-3, -12);
    LMessage.WriteBits(40000, -16);
    LMessage.WriteBits(200, -8);
    LMessage.WriteBits(300, 8);
    LData := TBytes.Create(1, 2, $FF);
    LMessage.WriteData(LData, 3);
    LMessage.WriteString('');
    Dump('bits.write', LMessage);

    LMessage.BeginReading;
    LLine := 'bits.read';
    AppendByte(LLine, LMessage, 'byte');
    AppendChar(LLine, LMessage, 'char');
    AppendShort(LLine, LMessage, 'short');
    AppendLong(LLine, LMessage, 'long');
    AppendFloat(LLine, LMessage, 'f1');
    AppendFloat(LLine, LMessage, 'f2');
    AppendString(LLine, LMessage, 'str');
    AppendBig(LLine, LMessage, 'big');
    AppendByte(LLine, LMessage, 'angle1');
    AppendByte(LLine, LMessage, 'angle2');
    AppendShort(LLine, LMessage, 'a16');
    AppendBits(LLine, LMessage, 'b3', 3);
    AppendBits(LLine, LMessage, 'b4s', -4);
    AppendBits(LLine, LMessage, 'b13', 13);
    AppendBits(LLine, LMessage, 'b31', 31);
    AppendBits(LLine, LMessage, 'b32', 32);
    AppendBits(LLine, LMessage, 's12a', -12);
    AppendBits(LLine, LMessage, 's12b', -12);
    AppendBits(LLine, LMessage, 's12c', -12);
    AppendBits(LLine, LMessage, 's16', -16);
    AppendBits(LLine, LMessage, 's8', -8);
    AppendBits(LLine, LMessage, 'u8', 8);
    LGot := NewBuffer(3);
    LMessage.ReadData(LGot, 3);
    LLine := LLine + Format(' data=%d,%d,%d', [LGot[0], LGot[1], LGot[2]]);
    AppendString(LLine, LMessage, 'empty');
    LLine := LLine + Format(' readcount=%d bit=%d', [LMessage.ReadCount, LMessage.Bit]);
    Emit(LLine);
    LLine := 'bits.end';
    AppendByte(LLine, LMessage, 'byte');
    AppendChar(LLine, LMessage, 'char');
    AppendShort(LLine, LMessage, 'short');
    AppendLong(LLine, LMessage, 'long');
    AppendFloat(LLine, LMessage, 'float');
    AppendString(LLine, LMessage, 'str');
    AppendLine(LLine, LMessage, 'line');
    Emit(LLine);

    // a line with a newline
    LMessage.Init(LBuffer, 128);
    LData := TBytes.Create(Ord('a'), Ord('b'), 10, Ord('c'), Ord('d'), Ord('%'), Ord('e'), 0);
    LMessage.WriteData(LData, 8);
    LMessage.BeginReading;
    LLine := 'bits.line';
    LLine := LLine + Format(' [%s]', [string(LMessage.ReadStringLine)]);
    LLine := LLine + Format(' [%s]', [string(LMessage.ReadStringLine)]);
    Emit(LLine);

    // a long string is refused with a warning, the next one is cut by the reader
    LBig := NewBuffer(4000);
    LLongText := AnsiString(StringOfChar('x', 1100));
    LOther := NewMessage(LBig, 4000);
    try
      LOther.WriteString(LLongText);
      EmitFmt('bits.longstring size=%d bit=%d', [LOther.CurSize, LOther.Bit]);
      LOther.WriteBigString(LLongText);
      LOther.BeginReading;
      LLong := string(LOther.ReadBigString);
      EmitFmt('bits.longbig len=%d size=%d bit=%d', [Length(LLong), LOther.CurSize, LOther.Bit]);
      FlushLog('bits.long');
      LLongText := AnsiString(StringOfChar('y', 1100));
      LOther.Init(LBig, 4000);
      LOther.WriteBigString(LLongText);
      LOther.BeginReading;
      LLong := string(LOther.ReadString);
      EmitFmt(' readstring len=%d readcount=%d', [Length(LLong), LOther.ReadCount]);
    finally
      LOther.Free;
    end;

    // the error and the overflow of WriteBits
    LMessage.Init(LBuffer, 128);
    for LIndex in TArray<Integer>.Create(0, 33, -32) do
      try
        LMessage.WriteBits(1, LIndex);
      except
        on E: EQ3MessageException do
          EmitFmt('bits.err%d %s', [LIndex, E.Message]);
      end;
    LMessage.WriteBits(8, 3);
    LMessage.WriteBits(-1, 8);
    LMessage.WriteBits(40000, -16);
    LMessage.WriteBits(-40000, -16);
    LMessage.WriteBits(300, -8);
    EmitFmt('bits.overflows %d', [LMessage.Overflows]);

    // overflow of a small buffer: writes until the message refuses
    LSize := 8;
    while LSize <= 24 do
    begin
      LBuffer := NewBuffer(160);
      LMessage.Init(LBuffer, LSize);
      for LIndex := 0 to 39 do
        LMessage.WriteByte(LIndex * 7);
      Emit(Format('bits.small%d ', [LSize]) + Format(' size=%d bit=%d overflowed=%d hex=%s',
        [LMessage.CurSize, LMessage.Bit, Ord(LMessage.Overflowed), Hex(LMessage.Data, 0, LMessage.CurSize)]));
      Inc(LSize, 8);
    end;
    LMessage.Init(LBuffer, 16);
    LMessage.WriteLong(1);
    LMessage.Clear;
    EmitFmt('bits.clear size=%d bit=%d ovf=%d', [LMessage.CurSize, LMessage.Bit, Ord(LMessage.Overflowed)]);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.ScenarioOob;
var
  LBuffer: TBytes;
  LMessage: TQ3Message;
  LLine: string;
begin
  LBuffer := NewBuffer(64);
  LMessage := NewMessage(LBuffer, 64, True);
  try
    LMessage.WriteBits($1FF, 8);
    LMessage.WriteBits($12345, 16);
    LMessage.WriteBits(Integer($DEADBEEF), 32);
    LMessage.WriteByte(7);
    LMessage.WriteShort(-2);
    LMessage.WriteLong(-3);
    LMessage.WriteFloat(1.5);
    try
      LMessage.WriteBits(1, 12);
    except
      on E: EQ3MessageException do
      begin
        EmitFmt('oob.err12 %s', [E.Message]);
        Emit('');
      end;
    end;
    Dump('oob.write', LMessage);
    LMessage.BeginReadingOOB;
    LLine := 'oob.read';
    AppendBits(LLine, LMessage, 'b', 8);
    AppendBits(LLine, LMessage, 's', 16);
    AppendBits(LLine, LMessage, 'l', 32);
    AppendByte(LLine, LMessage, 'byte');
    AppendShort(LLine, LMessage, 'short');
    AppendLong(LLine, LMessage, 'long');
    AppendFloat(LLine, LMessage, 'float');
    LLine := LLine + Format(' readcount=%d bit=%d', [LMessage.ReadCount, LMessage.Bit]);
    Emit(LLine);
    try
      LMessage.ReadBits(12);
    except
      on E: EQ3MessageException do
      begin
        EmitFmt('oob.errread12 %s', [E.Message]);
        Emit('');
      end;
    end;
    LMessage.BeginReadingOOB;
    LLine := 'oob.signed';
    AppendBits(LLine, LMessage, 'a', -8);
    AppendBits(LLine, LMessage, 'b', -16);
    Emit(LLine);
    // bit stream after out of band
    LMessage.Init(LBuffer, 64);
    LMessage.WriteByte(1);
    LMessage.Bitstream;
    LMessage.WriteByte(2);
    Dump('oob.bitstream', LMessage);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.ScenarioDelta;
var
  LBuffer: TBytes;
  LMessage: TQ3Message;
  LLine: string;
  LFrom, LTo1, LTo2, LTo3: TQ3UserCmd;
  LRead: array[0..2] of TQ3UserCmd;
  LIndex, LKey: Integer;
begin
  LBuffer := NewBuffer(512);
  LMessage := NewMessage(LBuffer, 512);
  try
    LMessage.WriteDelta(5, 5, 8);
    LMessage.WriteDelta(5, 9, 8);
    LMessage.WriteDelta(5, 300, 16);
    LMessage.WriteDeltaFloat(1.0, 1.0);
    LMessage.WriteDeltaFloat(1.0, 2.5);
    LMessage.WriteDeltaKey($5A5A, 3, 3, 12);
    LMessage.WriteDeltaKey($5A5A, 3, 4, 12);
    LMessage.WriteDeltaKey($12345678, 3, 4, 31);
    LMessage.WriteDeltaKeyFloat($1234, 1.0, 1.0);
    LMessage.WriteDeltaKeyFloat($1234, 1.0, -7.25);
    Dump('delta.write', LMessage);
    LMessage.BeginReading;
    LLine := 'delta.read';
    AppendDelta(LLine, LMessage, 'a', 5, 8);
    AppendDelta(LLine, LMessage, 'b', 5, 8);
    AppendDelta(LLine, LMessage, 'c', 5, 16);
    AppendDeltaFloat(LLine, LMessage, 'd', 1.0);
    AppendDeltaFloat(LLine, LMessage, 'e', 1.0);
    AppendDeltaKey(LLine, LMessage, 'f', $5A5A, 3, 12);
    AppendDeltaKey(LLine, LMessage, 'g', $5A5A, 3, 12);
    AppendDeltaKey(LLine, LMessage, 'h', $12345678, 3, 31);
    AppendDeltaKeyFloat(LLine, LMessage, 'i', $1234, 1.0);
    AppendDeltaKeyFloat(LLine, LMessage, 'j', $1234, 1.0);
    Emit(LLine);

    FillChar(LFrom, SizeOf(LFrom), 0);
    LFrom.ServerTime := 1000;
    LFrom.Angles[0] := 100;
    LFrom.Angles[1] := 200;
    LFrom.Buttons := 1;
    LFrom.Weapon := 3;
    LFrom.ForwardMove := 127;
    LFrom.RightMove := -128;
    LTo1 := LFrom;
    LTo1.ServerTime := 1050;
    LTo1.Angles[1] := 65535;
    LTo1.Buttons := 3;
    LTo1.ForwardMove := -1;
    LTo2 := LFrom;
    LTo2.ServerTime := 5000;
    LTo2.Weapon := 9;
    LTo2.UpMove := -90;
    LTo3 := LFrom;
    EmitFmt('usercmd size=%d', [SizeOf(TQ3UserCmd)]);

    LMessage.Init(LBuffer, 512);
    TQ3UserCmdCodec.WriteDelta(LMessage, LFrom, LTo1);
    TQ3UserCmdCodec.WriteDelta(LMessage, LFrom, LTo2);
    TQ3UserCmdCodec.WriteDelta(LMessage, LFrom, LTo3);
    Dump('usercmd.write', LMessage);
    LMessage.BeginReading;
    for LIndex := 0 to 2 do
      TQ3UserCmdCodec.ReadDelta(LMessage, LFrom, LRead[LIndex]);
    for LIndex := 0 to 2 do
      EmitFmt('usercmd.read %d t=%d a=%d,%d,%d b=%d w=%d m=%d,%d,%d', [LIndex, LRead[LIndex].ServerTime,
        LRead[LIndex].Angles[0], LRead[LIndex].Angles[1], LRead[LIndex].Angles[2], LRead[LIndex].Buttons,
        LRead[LIndex].Weapon, LRead[LIndex].ForwardMove, LRead[LIndex].RightMove, LRead[LIndex].UpMove]);

    LKey := $6D2B79F5;
    LMessage.Init(LBuffer, 512);
    TQ3UserCmdCodec.WriteDeltaKey(LMessage, LKey, LFrom, LTo1);
    TQ3UserCmdCodec.WriteDeltaKey(LMessage, LKey, LFrom, LTo2);
    TQ3UserCmdCodec.WriteDeltaKey(LMessage, LKey, LFrom, LTo3);
    Dump('usercmdkey.write', LMessage);
    LMessage.BeginReading;
    for LIndex := 0 to 2 do
      TQ3UserCmdCodec.ReadDeltaKey(LMessage, LKey, LFrom, LRead[LIndex]);
    for LIndex := 0 to 2 do
      EmitFmt('usercmdkey.read %d t=%d a=%d,%d,%d b=%d w=%d m=%d,%d,%d', [LIndex, LRead[LIndex].ServerTime,
        LRead[LIndex].Angles[0], LRead[LIndex].Angles[1], LRead[LIndex].Angles[2], LRead[LIndex].Buttons,
        LRead[LIndex].Weapon, LRead[LIndex].ForwardMove, LRead[LIndex].RightMove, LRead[LIndex].UpMove]);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.ScenarioEntity;
var
  LTable: IQ3NetFieldTable;
  LCodec: TQ3EntityStateCodec;
  LBuffer: TBytes;
  LMessage: TQ3Message;
  LFrom, LTo, LDec: TQ3EntityState;
  LI, LK, LJ, LNum, LForce, LN, LCount: Integer;
  LLine: string;
begin
  LTable := TQ3NetFieldTable.ForEntityState;
  LCount := LTable.Count;
  LCodec := TQ3EntityStateCodec.Create(LTable);
  LBuffer := NewBuffer(4096);
  LMessage := NewMessage(LBuffer, 4096);
  try
    EmitFmt('entity sizeof=%d fields=%d', [SizeOf(TQ3EntityState), LCount]);
    PrintFields('entity.field', LTable);
    FRandom := $2545F491;
    for LI := 0 to 79 do
    begin
      FillChar(LFrom, SizeOf(LFrom), 0);
      for LJ := 0 to LCount - 1 do
      begin
        if NextRandom mod 3 = 0 then
          Continue;
        RandomField(PInteger(PByte(@LFrom) + LTable[LJ].Offset), LTable[LJ].Bits);
      end;
      LTo := LFrom;
      if LI < 10 then
        LK := LI
      else
        LK := NextRandom mod 8;
      if LI >= 60 then
        LK := 51;
      for LJ := 0 to LK - 1 do
      begin
        LN := Integer(NextRandom mod Cardinal(LCount));
        if LI >= 60 then
          LN := LJ;
        RandomField(PInteger(PByte(@LTo) + LTable[LN].Offset), LTable[LN].Bits);
      end;
      LNum := NextRandom mod 1023;
      LFrom.Number := LNum;
      LTo.Number := LNum;
      LForce := NextRandom and 1;
      FillChar(LBuffer[0], Length(LBuffer), 0);
      LMessage.Init(LBuffer, 4096);
      LCodec.WriteDelta(LMessage, @LFrom, @LTo, LForce <> 0);
      LLine := Format('entity.case %d num=%d force=%d size=%d bit=%d fnv=%s', [LI, LNum, LForce,
        LMessage.CurSize, LMessage.Bit, Hex32(Fnv(LBuffer, 0, LMessage.CurSize))]);
      if LMessage.CurSize > 0 then
      begin
        FillChar(LDec, SizeOf(LDec), $AA);
        LMessage.BeginReading;
        LN := LMessage.ReadBits(Q3_GENTITYNUM_BITS);
        LCodec.ReadDelta(LMessage, @LFrom, @LDec, LN);
        LLine := LLine + Format(' n=%d dec=%s eq=%d readcount=%d bit=%d', [LN,
          Hex32(FnvRecord(LDec, SizeOf(LDec))), Ord(CompareMem(@LDec, @LTo, SizeOf(LDec))), LMessage.ReadCount,
          LMessage.Bit]);
      end;
      Emit(LLine);
    end;

    // removal
    FillChar(LFrom, SizeOf(LFrom), 0);
    LFrom.Number := 77;
    LMessage.Init(LBuffer, 4096);
    LCodec.WriteDelta(LMessage, @LFrom, nil, False);
    LCodec.WriteDelta(LMessage, nil, nil, False);
    Dump('entity.remove', LMessage);
    LMessage.BeginReading;
    LN := LMessage.ReadBits(Q3_GENTITYNUM_BITS);
    FillChar(LDec, SizeOf(LDec), $AA);
    LCodec.ReadDelta(LMessage, @LFrom, @LDec, LN);
    EmitFmt('entity.removed n=%d number=%d fnv=%s', [LN, LDec.Number, Hex32(FnvRecord(LDec, SizeOf(LDec)))]);

    // hand made floats
    FillChar(LFrom, SizeOf(LFrom), 0);
    LTo := LFrom;
    LFrom.Number := 5;
    LTo.Number := 5;
    LTo.Origin[0] := 3.0;
    LTo.Origin[1] := -4096.0;
    LTo.Origin[2] := 4096.0;
    LTo.Angles[0] := TQ3Message.BitsToFloat(Integer($80000000));
    LTo.Angles[1] := 2.5;
    LTo.Pos.TrBase[0] := 8191.0;
    LTo.Pos.TrBase[1] := -4095.0;
    LTo.Angles2[2] := TQ3Message.BitsToFloat($7FC00000);
    LTo.Pos.TrBase[2] := 1e30;
    LTo.Apos.TrBase[0] := -2147483648.0;
    LTo.Apos.TrBase[1] := 2147483648.0;
    LMessage.Init(LBuffer, 4096);
    LCodec.WriteDelta(LMessage, @LFrom, @LTo, True);
    Dump('entity.floats', LMessage);
    LMessage.BeginReading;
    LN := LMessage.ReadBits(Q3_GENTITYNUM_BITS);
    LCodec.ReadDelta(LMessage, @LFrom, @LDec, LN);
    EmitFmt('entity.floats.dec fnv=%s', [Hex32(FnvRecord(LDec, SizeOf(LDec)))]);

    // an entity number out of range
    LTo.Number := 1024;
    LMessage.Init(LBuffer, 4096);
    try
      LCodec.WriteDelta(LMessage, @LFrom, @LTo, True);
    except
      on E: EQ3MessageException do
        Emit('entity.err MSG_WriteDeltaEntity: ' + E.Message);
    end;
    try
      LCodec.ReadDelta(LMessage, @LFrom, @LDec, -1);
    except
      on E: EQ3MessageException do
        Emit('entity.errread ' + E.Message);
    end;
  finally
    LMessage.Free;
    LCodec.Free;
  end;
end;

procedure TTestQ3Parity.ScenarioPlayer;
var
  LTable: IQ3NetFieldTable;
  LCodec: TQ3PlayerStateCodec;
  LBuffer: TBytes;
  LMessage: TQ3Message;
  LFrom, LTo, LDec, LZero: TQ3PlayerState;
  LI, LK, LJ, LN, LCount: Integer;
  LLine: string;
begin
  LTable := TQ3NetFieldTable.ForPlayerState;
  LCount := LTable.Count;
  LCodec := TQ3PlayerStateCodec.Create(LTable);
  LBuffer := NewBuffer(4096);
  LMessage := NewMessage(LBuffer, 4096);
  try
    EmitFmt('player sizeof=%d fields=%d', [SizeOf(TQ3PlayerState), LCount]);
    PrintFields('player.field', LTable);
    FRandom := $9E3779B9;
    for LI := 0 to 79 do
    begin
      FillChar(LFrom, SizeOf(LFrom), 0);
      for LJ := 0 to LCount - 1 do
      begin
        if NextRandom mod 3 = 0 then
          Continue;
        RandomField(PInteger(PByte(@LFrom) + LTable[LJ].Offset), LTable[LJ].Bits);
      end;
      for LJ := 0 to 15 do
      begin
        if NextRandom mod 3 = 0 then
          LFrom.Stats[LJ] := Integer(NextRandom and $7FFF);
        if NextRandom mod 3 = 0 then
          LFrom.Persistant[LJ] := Integer(NextRandom and $7FFF) - 100;
        if NextRandom mod 3 = 0 then
          LFrom.Ammo[LJ] := Integer(NextRandom and $3FF);
        if NextRandom mod 3 = 0 then
          LFrom.Powerups[LJ] := Integer(NextRandom);
      end;
      LTo := LFrom;
      if LI < 10 then
        LK := LI
      else
        LK := NextRandom mod 8;
      if LI >= 60 then
        LK := LCount;
      for LJ := 0 to LK - 1 do
      begin
        LN := Integer(NextRandom mod Cardinal(LCount));
        if LI >= 60 then
          LN := LJ;
        RandomField(PInteger(PByte(@LTo) + LTable[LN].Offset), LTable[LN].Bits);
      end;
      if LI mod 4 <> 0 then
        for LJ := 0 to 15 do
        begin
          if NextRandom mod 6 = 0 then
            LTo.Stats[LJ] := Integer(NextRandom and $7FFF);
          if NextRandom mod 6 = 0 then
            LTo.Persistant[LJ] := Integer(NextRandom and $7FFF) - 100;
          if NextRandom mod 6 = 0 then
            LTo.Ammo[LJ] := Integer(NextRandom and $3FF);
          if NextRandom mod 6 = 0 then
            LTo.Powerups[LJ] := Integer(NextRandom);
        end;
      // fields that are not transmitted
      LTo.Ping := Integer(NextRandom);
      LTo.PmoveFramecount := 9;
      LTo.JumppadFrame := 3;
      LTo.EntityEventSequence := 4;
      LTo.ExternalEventTime := 11;
      FillChar(LBuffer[0], Length(LBuffer), 0);
      LMessage.Init(LBuffer, 4096);
      LCodec.WriteDelta(LMessage, @LFrom, @LTo);
      FillChar(LDec, SizeOf(LDec), $AA);
      LLine := Format('player.case %d size=%d bit=%d fnv=%s', [LI, LMessage.CurSize, LMessage.Bit,
        Hex32(Fnv(LBuffer, 0, LMessage.CurSize))]);
      LMessage.BeginReading;
      LCodec.ReadDelta(LMessage, @LFrom, @LDec);
      Emit(LLine + Format(' dec=%s readcount=%d bit=%d', [Hex32(FnvRecord(LDec, SizeOf(LDec))),
        LMessage.ReadCount, LMessage.Bit]));
    end;

    // from nil (a zero state)
    FillChar(LZero, SizeOf(LZero), 0);
    LTo := LZero;
    LTo.CommandTime := 1234;
    LTo.Origin[0] := 100.0;
    LTo.ViewAngles[1] := 90.5;
    LTo.Stats[1] := 100;
    LTo.Powerups[3] := 99999;
    LMessage.Init(LBuffer, 4096);
    LCodec.WriteDelta(LMessage, nil, @LTo);
    Dump('player.fromnull', LMessage);
    LMessage.BeginReading;
    LCodec.ReadDelta(LMessage, nil, @LDec);
    EmitFmt('player.fromnull.dec fnv=%s', [Hex32(FnvRecord(LDec, SizeOf(LDec)))]);
    // nothing changed
    LMessage.Init(LBuffer, 4096);
    LCodec.WriteDelta(LMessage, @LTo, @LTo);
    Dump('player.same', LMessage);
  finally
    LMessage.Free;
    LCodec.Free;
  end;
end;

procedure TTestQ3Parity.HuffmanCase(const ATag: string; const APayload: TBytes; ALength, AOffset: Integer);
var
  LData: TBytes;
  LMessage: TQ3Message;
  LCompressed: Integer;
begin
  LData := NewBuffer(20000);
  FillChar(LData[0], Length(LData), $77);
  Move(APayload[0], LData[AOffset], ALength);
  LMessage := NewMessage(LData, 16384);
  try
    LMessage.CurSize := ALength + AOffset;
    TQ3HuffmanCompressor.Compress(LMessage, AOffset);
    LCompressed := LMessage.CurSize;
    EmitFmt('%s compressed size=%d fnv=%s head=%s', [ATag, LCompressed, Hex32(Fnv(LData, 0, LCompressed)),
      Hex(LData, 0, Min(LCompressed, 24))]);
    TQ3HuffmanCompressor.Decompress(LMessage, AOffset);
    EmitFmt('%s decompressed size=%d fnv=%s same=%d', [ATag, LMessage.CurSize,
      Hex32(Fnv(LData, AOffset, LMessage.CurSize - AOffset)),
      Ord((LMessage.CurSize = ALength + AOffset) and CompareMem(@LData[AOffset], @APayload[0], ALength))]);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.ScenarioHuffman;
var
  LBuffer, LPayload, LData: TBytes;
  LMessage: TQ3Message;
  LLine: string;
  LIndex, LSum: Integer;
  LText: TBytes;
begin
  LBuffer := NewBuffer(1024);
  LMessage := NewMessage(LBuffer, 64);
  try
    // code lengths of the static tree
    LLine := 'huffman.bits';
    for LIndex := 0 to 255 do
    begin
      LMessage.Init(LBuffer, 64);
      LMessage.WriteBits(LIndex, 8);
      LLine := LLine + Format(' %d', [LMessage.Bit]);
    end;
    Emit(LLine);
    LMessage.Init(LBuffer, 1024);
    for LIndex := 0 to 99 do
      LMessage.WriteByte(LIndex * 2);
    for LIndex := 0 to 99 do
      LMessage.WriteByte(255 - LIndex);
    Dump('huffman.run', LMessage);
    LMessage.BeginReading;
    LSum := 0;
    for LIndex := 0 to 199 do
      LSum := LSum + LMessage.ReadByte * (LIndex + 1);
    EmitFmt('huffman.runread %d readcount=%d bit=%d', [LSum, LMessage.ReadCount, LMessage.Bit]);

    LPayload := NewBuffer(5000);
    LText := TEncoding.ASCII.GetBytes('Hello, Quake III Arena! Hello, Quake III Arena!');
    Move(LText[0], LPayload[0], Length(LText));
    HuffmanCase('huffman.text', LPayload, 47, 0);
    FillChar(LPayload[0], 300, 0);
    HuffmanCase('huffman.zeros', LPayload, 300, 5);
    for LIndex := 0 to 511 do
      LPayload[LIndex] := Byte(LIndex);
    HuffmanCase('huffman.ramp', LPayload, 512, 0);
    FRandom := $CAFEBABE;
    for LIndex := 0 to 2999 do
      LPayload[LIndex] := Byte(NextRandom shr 24);
    HuffmanCase('huffman.random', LPayload, 3000, 0);
    for LIndex := 0 to 4999 do
      LPayload[LIndex] := Byte((NextRandom shr 24) mod 7);
    HuffmanCase('huffman.skewed', LPayload, 5000, 12);
    LPayload[0] := 0;
    HuffmanCase('huffman.one', LPayload, 1, 0);
  finally
    LMessage.Free;
  end;

  // empty and truncated
  LData := NewBuffer(64);
  LMessage := NewMessage(LData, 64);
  try
    LMessage.CurSize := 4;
    TQ3HuffmanCompressor.Compress(LMessage, 4);
    EmitFmt('huffman.empty size=%d', [LMessage.CurSize]);
    TQ3HuffmanCompressor.Decompress(LMessage, 4);
    EmitFmt('huffman.emptyd size=%d', [LMessage.CurSize]);
    // a truncated stream: claims 100 bytes but carries 3
    FillChar(LData[0], 64, 0);
    LData[1] := 100;
    LData[2] := $FF;
    LData[3] := $13;
    LData[4] := $55;
    LMessage.Init(LData, 64);
    LMessage.CurSize := 5;
    TQ3HuffmanCompressor.Decompress(LMessage, 0);
    EmitFmt('huffman.truncated size=%d fnv=%s', [LMessage.CurSize, Hex32(Fnv(LData, 0, LMessage.CurSize))]);
    // claims more than the buffer
    FillChar(LData[0], 64, 0);
    LData[0] := $FF;
    LData[1] := $FF;
    LData[2] := $80;
    LMessage.Init(LData, 64);
    LMessage.CurSize := 3;
    TQ3HuffmanCompressor.Decompress(LMessage, 0);
    EmitFmt('huffman.huge size=%d fnv=%s', [LMessage.CurSize, Hex32(Fnv(LData, 0, LMessage.CurSize))]);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.PrintFields(const AName: string; const ATable: IQ3NetFieldTable);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ATable.Count - 1 do
    EmitFmt('%s %d %s %d %d', [AName, LIndex, ATable[LIndex].Name, ATable[LIndex].Offset, ATable[LIndex].Bits]);
end;

procedure TTestQ3Parity.PrintCaptured(const ATag: string);
var
  LIndex: Integer;
  LPacket: TFakeQ3Packet;
begin
  for LIndex := 0 to FTransport.Packets.Count - 1 do
  begin
    LPacket := FTransport.Packets[LIndex];
    EmitFmt('%s packet %d sock=%d len=%d fnv=%s head=%s', [ATag, LIndex, Ord(LPacket.Source),
      Length(LPacket.Data), Hex32(Fnv(LPacket.Data, 0, Length(LPacket.Data))),
      Hex(LPacket.Data, 0, Min(Length(LPacket.Data), 16))]);
  end;
end;

function TTestQ3Parity.ProcessPacket(const ATag: string; AChannel: TQ3Netchan; AIndex: Integer): Boolean;
var
  LMessage: TQ3Message;
  LPacket: TFakeQ3Packet;
begin
  FillChar(FProcessBuffer[0], Length(FProcessBuffer), 0);
  LMessage := NewMessage(FProcessBuffer, Q3_MAX_MSGLEN);
  try
    LPacket := FTransport.Packets[AIndex];
    Move(LPacket.Data[0], FProcessBuffer[0], Length(LPacket.Data));
    LMessage.CurSize := Length(LPacket.Data);
    Result := AChannel.Process(LMessage);
    EmitFmt('%s process %d -> %d dropped=%d in=%d fragseq=%d fraglen=%d size=%d readcount=%d bit=%d fnv=%s',
      [ATag, AIndex, Ord(Result), AChannel.Dropped, AChannel.IncomingSequence, AChannel.FragmentSequence,
      AChannel.FragmentLength, LMessage.CurSize, LMessage.ReadCount, LMessage.Bit,
      Hex32(Fnv(FProcessBuffer, 0, LMessage.CurSize))]);
    FlushLog(ATag);
  finally
    LMessage.Free;
  end;
end;

procedure TTestQ3Parity.SendAll(AChannel: TQ3Netchan; ALength, ASeed: Integer);
var
  LPayload: TBytes;
  LIndex: Integer;
begin
  LPayload := NewBuffer(Q3_MAX_MSGLEN + 100);
  for LIndex := 0 to ALength - 1 do
    LPayload[LIndex] := Byte(ASeed * 31 + LIndex * 7 + (LIndex shr 8));
  AChannel.Transmit(LPayload, ALength);
  while AChannel.UnsentFragments do
    AChannel.TransmitNextFragment;
end;

procedure TTestQ3Parity.ScenarioNetchan;
var
  LClient, LServer: TQ3Netchan;
  LAddress: TQ3NetAddress;
  LIndex, LStart: Integer;
  LPacket: TFakeQ3Packet;
begin
  FillChar(LAddress, SizeOf(LAddress), 0);
  LAddress.AddressType := Ord(natIp);
  LAddress.Ip[0] := 127;
  LAddress.Ip[3] := 1;
  LAddress.Port := 27960;
  LClient := TQ3Netchan.Create(FTransportIntf, FLogIntf);
  LServer := TQ3Netchan.Create(FTransportIntf, FLogIntf);
  try
    LClient.Setup(nsClient, LAddress, 4242);
    LServer.Setup(nsServer, LAddress, 0);
    EmitFmt('netchan.setup sock=%d qport=%d in=%d out=%d unsent=%d', [Ord(LClient.Source), LClient.QPort,
      LClient.IncomingSequence, LClient.OutgoingSequence, Ord(LClient.UnsentFragments)]);

    // small messages in order, a duplicate, an empty one
    FTransport.Packets.Clear;
    SendAll(LClient, 100, 1);
    SendAll(LClient, 0, 2);
    SendAll(LClient, 1299, 3);
    PrintCaptured('small');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('small', LServer, LIndex);
    ProcessPacket('small.dup', LServer, 1);
    EmitFmt('netchan.state out=%d unsentStart=%d', [LClient.OutgoingSequence, LClient.UnsentFragmentStart]);

    // dropped packets: three sent, the last delivered
    FTransport.Packets.Clear;
    SendAll(LClient, 10, 4);
    SendAll(LClient, 10, 5);
    SendAll(LClient, 10, 6);
    ProcessPacket('drop', LServer, 2);

    // a big message in fragments
    FTransport.Packets.Clear;
    SendAll(LClient, 3000, 7);
    PrintCaptured('big');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('big', LServer, LIndex);
    EmitFmt('netchan.state out=%d unsent=%d unsentStart=%d unsentLength=%d', [LClient.OutgoingSequence,
      Ord(LClient.UnsentFragments), LClient.UnsentFragmentStart, LClient.UnsentLength]);

    // exact multiples of the fragment size
    FTransport.Packets.Clear;
    SendAll(LClient, 2600, 8);
    PrintCaptured('exact');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('exact', LServer, LIndex);
    FTransport.Packets.Clear;
    SendAll(LClient, 1300, 9);
    PrintCaptured('one');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('one', LServer, LIndex);
    FTransport.Packets.Clear;
    SendAll(LClient, 16384, 10);
    EmitFmt('netchan.max packets=%d', [FTransport.Packets.Count]);
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('max', LServer, LIndex);

    // fragments out of order
    FTransport.Packets.Clear;
    SendAll(LClient, 3000, 11);
    ProcessPacket('order', LServer, 1);
    ProcessPacket('order', LServer, 0);
    ProcessPacket('order', LServer, 2);
    ProcessPacket('order', LServer, 1);
    ProcessPacket('order', LServer, 2);
    ProcessPacket('order', LServer, 2);

    // a lost fragment, then the next message completes
    FTransport.Packets.Clear;
    SendAll(LClient, 3000, 12);
    LStart := FTransport.Packets.Count;
    SendAll(LClient, 500, 13);
    ProcessPacket('lost', LServer, 0);
    ProcessPacket('lost', LServer, 2);
    ProcessPacket('lost', LServer, LStart);

    // a bogus fragment length
    FTransport.Packets.Clear;
    SendAll(LClient, 3000, 14);
    LPacket := FTransport.Packets[0];
    LPacket.Data[8] := $FF;
    LPacket.Data[9] := $7F;
    ProcessPacket('bogus', LServer, 0);
    LPacket := FTransport.Packets[1];
    LPacket.Data[6] := $FF;
    ProcessPacket('bogus2', LServer, 1);
    LPacket := FTransport.Packets[0];
    LPacket.Data[8] := $FF;
    LPacket.Data[9] := $FF;
    ProcessPacket('bogus3', LServer, 0);

    // the server sends to the client: no qport
    FTransport.Packets.Clear;
    SendAll(LServer, 50, 15);
    SendAll(LServer, 2000, 16);
    PrintCaptured('server');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('client', LClient, LIndex);

    // a too long message
    try
      LClient.Transmit(FProcessBuffer, Q3_MAX_MSGLEN + 1);
    except
      on E: EQ3NetchanException do
        Emit('netchan.err ' + E.Message);
    end;
    // a packet shorter than the header
    FTransport.Packets.Clear;
    FTransport.AddPacket(nsClient, TBytes.Create(0, 0, 0));
    LServer.Setup(nsServer, LAddress, 0);
    ProcessPacket('short', LServer, 0);
    LServer.IncomingSequence := 2147483646;
    FTransport.Packets.Clear;
    LClient.OutgoingSequence := 2147483646;
    SendAll(LClient, 5, 17);
    SendAll(LClient, 5, 18);
    PrintCaptured('wrap');
    for LIndex := 0 to FTransport.Packets.Count - 1 do
      ProcessPacket('wrap', LServer, LIndex);
  finally
    LServer.Free;
    LClient.Free;
  end;
end;

procedure TTestQ3Parity.DovrebbeScrivereELeggereIBitCometIlC;
begin
  ScenarioBits;
  Compare('bits');
end;

procedure TTestQ3Parity.DovrebbeGestireIMessaggiOutOfBandCometIlC;
begin
  ScenarioOob;
  Compare('oob');
end;

procedure TTestQ3Parity.DovrebbeScrivereIDeltaECometIlC;
begin
  ScenarioDelta;
  Compare('delta');
end;

procedure TTestQ3Parity.DovrebbeScrivereIDeltaDelleEntitaCometIlC;
begin
  ScenarioEntity;
  Compare('entity');
end;

procedure TTestQ3Parity.DovrebbeScrivereIDeltaDelPlayerstateCometIlC;
begin
  ScenarioPlayer;
  Compare('player');
end;

procedure TTestQ3Parity.DovrebbeComprimereConLHuffmanAdattivoCometIlC;
begin
  ScenarioHuffman;
  Compare('huffman');
end;

procedure TTestQ3Parity.DovrebbeFrammentareERiassemblareCometIlNetchan;
begin
  ScenarioNetchan;
  Compare('netchan');
end;

end.
