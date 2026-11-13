{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TBitMessage and TBitMessageDelta (idBitMsg)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.BitMessage;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Net.BitMessage.Types, DelphiDoom.Net.BitMessage.Intf, DelphiDoom.Net.BitMessage,
  DelphiDoom.Net.BitMessageDelta;

type
  /// <summary>A log that keeps what it is told</summary>
  TRecordingLog = class(TInterfacedObject, IIdLibLog)
  public
    Messages: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  /// <summary>A writer that records the calls it gets</summary>
  TFakeWriter = class(TInterfacedObject, IBitMessageWriter)
  public
    Calls: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure WriteBits(AValue, ANumBits: Integer);
    procedure WriteString(const AText: AnsiString; AMaxLength: Integer = -1; AMake7Bit: Boolean = True);
    procedure WriteData(AData: PByte; ALength: Integer);
    function WriteDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
    procedure WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
  end;

  /// <summary>A reader that gives the bits it was told, in order</summary>
  TFakeReader = class(TInterfacedObject, IBitMessageReader)
  public
    Bits: TList<Integer>;
    Position: Integer;
    constructor Create;
    destructor Destroy; override;
    function ReadBits(ANumBits: Integer): Integer;
    function ReadString(ABufferSize: Integer = 1024): AnsiString;
    function ReadData(AData: PByte; ALength: Integer): Integer;
    function ReadDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
    function ReadDeltaByteCounter(AOldValue: Integer): Integer;
    function ReadDeltaShortCounter(AOldValue: Integer): Integer;
    function ReadDeltaLongCounter(AOldValue: Integer): Integer;
  end;

  [TestFixture]
  [Category('Net')]
  TTestBitMessage = class
  strict private
    FMessage: TBitMessage;
    FLog: TRecordingLog;
    FLogRef: IIdLibLog;
    procedure NewMessage(ASize: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaMaggioreDelBuffer;
    [Test]
    procedure DovrebbeRifiutareLaLetturaSenzaBuffer;
    [Test]
    procedure DovrebbeScrivereIBitDalMenoSignificativo;
    [Test]
    procedure DovrebbeEstendereIlSegnoDeiCampiConSegno;
    [Test]
    procedure DovrebbeDareMenoUnoOltreLaFine;
    [Test]
    procedure DovrebbeSegnalareIlValoreCheNonEntra;
    [Test]
    procedure DovrebbeRicominciareInCasoDiOverflowConsentito;
    [Test]
    procedure DovrebbeTroncareUnaStringaAllaLunghezzaMassima;
    [Test]
    procedure DovrebbeFermareLaStringaAlPrimoZero;
    [Test]
    procedure DovrebbeRifiutareLunghezzaMassimaZero;
    [Test]
    procedure DovrebbeSostituireIlPercentoELaVersioneASetteBit;
    [Test]
    procedure DovrebbeTroncareLaLetturaDiUnaStringaLunga;
    [Test]
    procedure DovrebbeLeggereEScrivereBlocchiDiByte;
    [Test]
    procedure DovrebbeLeggereMenoByteDelPrevisto;
    [Test]
    procedure DovrebbeLeggereEScrivereUnIndirizzoDiRete;
    [Test]
    procedure DovrebbeFareAndataERitornoDiUnaDirezione;
    [Test]
    procedure DovrebbeUsareIlBitDiSegnoDelloZeroNegativoNelleDirezioni;
    [Test]
    procedure DovrebbeFareAndataERitornoDegliAngoli;
    [Test]
    procedure DovrebbeFareAndataERitornoDeiFloatCompatti;
    [Test]
    procedure DovrebbeScrivereIContatoriDelta;
    [Test]
    procedure DovrebbeRiprodurreIlDifettoDelContatoreConIlBitAlto;
    [Test]
    procedure DovrebbeFareAndataERitornoDiUnDizionarioDelta;
    [Test]
    procedure DovrebbeRiportareDizionariInvariatiComeNonCambiati;
    [Test]
    procedure DovrebbeRiferireLeProprieta;
    [Test]
    procedure DovrebbeScrivereByteVuotiConDatiVuoti;
  end;

  [TestFixture]
  [Category('Net')]
  TTestBitMessageDelta = class
  public
    [Test]
    procedure SenzaBaseDovrebbeScrivereTuttoNelDelta;
    [Test]
    procedure ConBaseUgualeDovrebbeScrivereUnSoloBit;
    [Test]
    procedure ConBaseDiversaDovrebbeScrivereUnoEIlValore;
    [Test]
    procedure DovrebbeScrivereAncheLaNuovaBase;
    [Test]
    procedure DovrebbeLeggereDallaBaseSeIlDeltaDiceInvariato;
    [Test]
    procedure DovrebbeLeggereDalDeltaSeCambiato;
    [Test]
    procedure DovrebbeLeggereDallaBaseSenzaDelta;
    [Test]
    procedure DovrebbeLeggereIValoriDeltaConIlVecchioValore;
    [Test]
    procedure DovrebbeFareAndataERitornoDiTuttiITipiConUnaBase;
  end;

implementation

{ TRecordingLog }

constructor TRecordingLog.Create;
begin
  inherited Create;
  Messages := TStringList.Create;
end;

destructor TRecordingLog.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;

procedure TRecordingLog.Printf(const AMessage: string);
begin
  Messages.Add('P:' + AMessage);
end;

procedure TRecordingLog.Warning(const AMessage: string);
begin
  Messages.Add('W:' + AMessage);
end;

{ TFakeWriter }

constructor TFakeWriter.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
end;

destructor TFakeWriter.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

procedure TFakeWriter.WriteBits(AValue, ANumBits: Integer);
begin
  Calls.Add(Format('bits %d %d', [AValue, ANumBits]));
end;

procedure TFakeWriter.WriteString(const AText: AnsiString; AMaxLength: Integer; AMake7Bit: Boolean);
begin
  Calls.Add('string ' + string(AText));
end;

procedure TFakeWriter.WriteData(AData: PByte; ALength: Integer);
begin
  Calls.Add('data ' + IntToStr(ALength));
end;

function TFakeWriter.WriteDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
begin
  Calls.Add(Format('dict %d %d', [ADict.GetNumKeyVals, Ord(Assigned(ABase))]));
  Result := True;
end;

procedure TFakeWriter.WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
begin
  Calls.Add(Format('bc %d %d', [AOldValue, ANewValue]));
end;

procedure TFakeWriter.WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
begin
  Calls.Add(Format('sc %d %d', [AOldValue, ANewValue]));
end;

procedure TFakeWriter.WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
begin
  Calls.Add(Format('lc %d %d', [AOldValue, ANewValue]));
end;

{ TFakeReader }

constructor TFakeReader.Create;
begin
  inherited Create;
  Bits := TList<Integer>.Create;
end;

destructor TFakeReader.Destroy;
begin
  Bits.Free;
  inherited Destroy;
end;

function TFakeReader.ReadBits(ANumBits: Integer): Integer;
begin
  if Position < Bits.Count then
    Result := Bits[Position]
  else
    Result := -1;
  Inc(Position);
end;

function TFakeReader.ReadString(ABufferSize: Integer): AnsiString;
begin
  Result := 'fake';
end;

function TFakeReader.ReadData(AData: PByte; ALength: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ALength - 1 do
    AData[LIndex] := Byte(LIndex + 1);
  Result := ALength;
end;

function TFakeReader.ReadDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
begin
  ADict.SetValue('fake', 'dict');
  Result := True;
end;

function TFakeReader.ReadDeltaByteCounter(AOldValue: Integer): Integer;
begin
  Result := AOldValue + 1;
end;

function TFakeReader.ReadDeltaShortCounter(AOldValue: Integer): Integer;
begin
  Result := AOldValue + 2;
end;

function TFakeReader.ReadDeltaLongCounter(AOldValue: Integer): Integer;
begin
  Result := AOldValue + 3;
end;

{ TTestBitMessage }

procedure TTestBitMessage.Setup;
begin
  FLog := TRecordingLog.Create;
  FLogRef := FLog;
  FMessage := TBitMessage.Create(FLogRef);
end;

procedure TTestBitMessage.TearDown;
begin
  FMessage.Free;
  FLogRef := nil;
end;

procedure TTestBitMessage.NewMessage(ASize: Integer);
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, ASize);
  FillChar(LBuffer[0], ASize, 0);
  FMessage.Init(LBuffer, ASize);
  FMessage.BeginWriting;
end;

procedure TTestBitMessage.DovrebbeRifiutareUnaLunghezzaMaggioreDelBuffer;
begin
  Assert.WillRaise(
    procedure
    begin
      FMessage.Init(TBytes.Create(1, 2), 3);
    end, EBitMessageException);
end;

procedure TTestBitMessage.DovrebbeRifiutareLaLetturaSenzaBuffer;
begin
  Assert.WillRaise(
    procedure
    begin
      FMessage.ReadBits(8);
    end, EBitMessageException);
  Assert.WillRaise(
    procedure
    begin
      FMessage.WriteBits(1, 1);
    end, EBitMessageException);
end;

procedure TTestBitMessage.DovrebbeScrivereIBitDalMenoSignificativo;
begin
  NewMessage(8);
  FMessage.WriteBits(1, 1);
  FMessage.WriteBits(0, 2);
  FMessage.WriteBits(3, 2);
  Assert.AreEqual(Integer($19), Integer(FMessage.GetData[0]));
  Assert.AreEqual(1, FMessage.GetSize);
  Assert.AreEqual(5, FMessage.GetNumBitsWritten);
  Assert.AreEqual(5, FMessage.GetWriteBit);
  FMessage.WriteByteAlign;
  FMessage.WriteBits($AB, 8);
  Assert.AreEqual(Integer($AB), Integer(FMessage.GetData[1]));
end;

procedure TTestBitMessage.DovrebbeEstendereIlSegnoDeiCampiConSegno;
begin
  NewMessage(12);
  FMessage.WriteBits(-5, -4);
  FMessage.WriteBits(7, -4);
  FMessage.WriteBits(-1, 32);
  FMessage.WriteBits(Integer($80000000), 32);
  FMessage.BeginReading;
  Assert.AreEqual(-5, FMessage.ReadBits(-4));
  Assert.AreEqual(7, FMessage.ReadBits(-4));
  Assert.AreEqual(-1, FMessage.ReadBits(32));
  Assert.AreEqual(Integer($80000000), FMessage.ReadBits(32));
end;

procedure TTestBitMessage.DovrebbeDareMenoUnoOltreLaFine;
begin
  NewMessage(4);
  FMessage.WriteByte(9);
  FMessage.BeginReading;
  Assert.AreEqual(9, FMessage.ReadByte);
  Assert.AreEqual(-1, FMessage.ReadBits(1));
  Assert.AreEqual(255, FMessage.ReadByte);
  Assert.AreEqual(1, FMessage.GetReadCount);
  Assert.AreEqual(0, FMessage.GetRemainingReadBits);
end;

procedure TTestBitMessage.DovrebbeSegnalareIlValoreCheNonEntra;
begin
  NewMessage(8);
  FMessage.WriteBits(300, 8);
  FMessage.WriteBits(-1, 8);
  FMessage.WriteBits(200, -8);
  FMessage.WriteBits(-200, -8);
  Assert.AreEqual(4, FLog.Messages.Count);
  Assert.IsTrue(FLog.Messages[0].StartsWith('W:idBitMsg::WriteBits: value overflow 300 8'));
  Assert.AreEqual(Integer($2C), Integer(FMessage.GetData[0]));
end;

procedure TTestBitMessage.DovrebbeRicominciareInCasoDiOverflowConsentito;
begin
  NewMessage(2);
  FMessage.AllowOverflow := True;
  FMessage.WriteByte(1);
  FMessage.WriteByte(2);
  FMessage.WriteByte(3);
  Assert.IsTrue(FMessage.Overflowed);
  Assert.AreEqual(0, FMessage.Size);
  Assert.AreEqual('P:idBitMsg: overflow', FLog.Messages[0]);
  FMessage.BeginWriting;
  Assert.IsFalse(FMessage.Overflowed);
  FMessage.WriteByte(4);
  Assert.AreEqual(1, FMessage.Size);
  Assert.WillRaise(
    procedure
    begin
      FMessage.WriteString('abcdefghijklmnopqrstuvwxyz');
    end, EBitMessageException);
end;

procedure TTestBitMessage.DovrebbeTroncareUnaStringaAllaLunghezzaMassima;
begin
  NewMessage(32);
  FMessage.WriteString('abcdef', 4);
  FMessage.BeginReading;
  Assert.AreEqual(AnsiString('abc'), FMessage.ReadString);
  Assert.AreEqual(4, FMessage.Size);
end;

procedure TTestBitMessage.DovrebbeFermareLaStringaAlPrimoZero;
begin
  NewMessage(32);
  FMessage.WriteString('ab' + #0 + 'cd');
  Assert.AreEqual(3, FMessage.Size);
  FMessage.BeginReading;
  Assert.AreEqual(AnsiString('ab'), FMessage.ReadString);
end;

procedure TTestBitMessage.DovrebbeRifiutareLunghezzaMassimaZero;
begin
  NewMessage(32);
  Assert.WillRaise(
    procedure
    begin
      FMessage.WriteString('abc', 0);
    end, EBitMessageException);
end;

procedure TTestBitMessage.DovrebbeSostituireIlPercentoELaVersioneASetteBit;
begin
  NewMessage(32);
  FMessage.WriteString('100%' + AnsiChar($E9));
  FMessage.WriteString('keep' + AnsiChar($E9), -1, False);
  FMessage.BeginReading;
  Assert.AreEqual(AnsiString('100..'), FMessage.ReadString);
  Assert.AreEqual(AnsiString('keep' + AnsiChar($E9)), FMessage.ReadString);
end;

procedure TTestBitMessage.DovrebbeTroncareLaLetturaDiUnaStringaLunga;
begin
  NewMessage(32);
  FMessage.WriteString('abcdefgh');
  FMessage.WriteByte(77);
  FMessage.BeginReading;
  Assert.AreEqual(AnsiString('abc'), FMessage.ReadString(4));
  // the whole string was consumed, the next field follows
  Assert.AreEqual(77, FMessage.ReadByte);
end;

procedure TTestBitMessage.DovrebbeLeggereEScrivereBlocchiDiByte;
var
  LRead: TBytes;
begin
  NewMessage(16);
  FMessage.WriteBits(1, 3);
  FMessage.WriteData(TBytes.Create(10, 20, 30));
  Assert.AreEqual(4, FMessage.Size);
  FMessage.BeginReading;
  Assert.AreEqual(1, FMessage.ReadBits(3));
  LRead := FMessage.ReadData(3);
  Assert.AreEqual<Integer>(3, Length(LRead));
  Assert.AreEqual(Integer(20), Integer(LRead[1]));
  Assert.AreEqual(0, FMessage.GetRemainingData);
end;

procedure TTestBitMessage.DovrebbeLeggereMenoByteDelPrevisto;
var
  LRead: TBytes;
begin
  NewMessage(16);
  FMessage.WriteData(TBytes.Create(1, 2));
  FMessage.BeginReading;
  LRead := FMessage.ReadData(10);
  Assert.AreEqual<Integer>(2, Length(LRead));
  FMessage.BeginReading;
  Assert.AreEqual(2, FMessage.ReadData(nil, 5));
  FMessage.BeginReading;
  Assert.AreEqual<Integer>(0, Length(FMessage.ReadData(0)));
  FMessage.WriteData(nil, 0);
end;

procedure TTestBitMessage.DovrebbeLeggereEScrivereUnIndirizzoDiRete;
var
  LAddress, LRead: TBitMessageNetAddress;
begin
  Assert.AreEqual(6, SizeOf(TBitMessageNetAddress));
  LAddress.Ip[0] := 10;
  LAddress.Ip[1] := 0;
  LAddress.Ip[2] := 0;
  LAddress.Ip[3] := 7;
  LAddress.Port := 27960;
  NewMessage(16);
  FMessage.WriteNetAddress(LAddress);
  Assert.AreEqual(6, FMessage.Size);
  FMessage.BeginReading;
  LRead := FMessage.ReadNetAddress;
  Assert.AreEqual(7, Integer(LRead.Ip[3]));
  Assert.AreEqual(27960, Integer(LRead.Port));
end;

procedure TTestBitMessage.DovrebbeFareAndataERitornoDiUnaDirezione;
var
  LDirection, LRead: TIdVec3;
begin
  LDirection := TIdVec3.Create(0.6, -0.64, 0.48);
  NewMessage(16);
  FMessage.WriteDir(LDirection, 30);
  FMessage.BeginReading;
  LRead := FMessage.ReadDir(30);
  Assert.AreEqual(Double(0.6), Double(LRead.X), 0.01);
  Assert.AreEqual(Double(-0.64), Double(LRead.Y), 0.01);
  Assert.AreEqual(Double(0.48), Double(LRead.Z), 0.01);
end;

procedure TTestBitMessage.DovrebbeUsareIlBitDiSegnoDelloZeroNegativoNelleDirezioni;
var
  LZero: Single;
  LBits: Integer;
begin
  // FLOATSIGNBITSET( -0.0f ) is 1
  LZero := 0.0;
  PCardinal(@LZero)^ := $80000000;
  LBits := TBitMessage.DirToBits(TIdVec3.Create(LZero, 0.0, 1.0), 12);
  Assert.AreEqual(1, (LBits shr 11) and 1);
end;

procedure TTestBitMessage.DovrebbeFareAndataERitornoDegliAngoli;
begin
  NewMessage(8);
  FMessage.WriteAngle8(90.0);
  FMessage.WriteAngle16(-45.5);
  FMessage.BeginReading;
  Assert.AreEqual(Double(90.0), Double(FMessage.ReadAngle8), 1.5);
  Assert.AreEqual(Double(-45.5), Double(FMessage.ReadAngle16), 0.01);
end;

procedure TTestBitMessage.DovrebbeFareAndataERitornoDeiFloatCompatti;
begin
  NewMessage(16);
  FMessage.WriteFloat(0.75, 5, 10);
  FMessage.WriteFloat(1.5);
  FMessage.WriteDeltaFloat(1.5, 2.5);
  FMessage.WriteDeltaFloat(2.5, 2.5, 8, 23);
  FMessage.BeginReading;
  Assert.AreEqual(Double(0.75), Double(FMessage.ReadFloat(5, 10)), 0.0001);
  Assert.AreEqual(Double(1.5), Double(FMessage.ReadFloat), 0.0);
  Assert.AreEqual(Double(2.5), Double(FMessage.ReadDeltaFloat(1.5)), 0.0);
  Assert.AreEqual(Double(2.5), Double(FMessage.ReadDeltaFloat(2.5, 8, 23)), 0.0);
end;

procedure TTestBitMessage.DovrebbeScrivereIContatoriDelta;
begin
  NewMessage(16);
  FMessage.WriteDeltaByteCounter($12, $14);
  FMessage.WriteDeltaShortCounter($1234, $1434);
  FMessage.WriteDeltaLongCounter($100, $104);
  FMessage.BeginReading;
  Assert.AreEqual($14, FMessage.ReadDeltaByteCounter($12));
  Assert.AreEqual($1434, FMessage.ReadDeltaShortCounter($1234));
  Assert.AreEqual($104, FMessage.ReadDeltaLongCounter($100));
  // the same value costs only the count of zero; so does a difference in bit 0 alone (the original
  // never tests bit 0, so the new value is lost)
  NewMessage(16);
  FMessage.WriteDeltaByteCounter(5, 5);
  Assert.AreEqual(3, FMessage.GetNumBitsWritten);
  NewMessage(16);
  FMessage.WriteDeltaByteCounter(4, 5);
  Assert.AreEqual(3, FMessage.GetNumBitsWritten);
  FMessage.BeginReading;
  Assert.AreEqual(4, FMessage.ReadDeltaByteCounter(4));
end;

procedure TTestBitMessage.DovrebbeRiprodurreIlDifettoDelContatoreConIlBitAlto;
begin
  // a difference in bit 7 gives the count 8, which does not fit in 3 bits: the original writes 0
  // (with a warning) and then the 8 low bits
  NewMessage(16);
  FMessage.WriteDeltaByteCounter(0, $80);
  Assert.IsTrue(FLog.Messages.Count > 0);
  Assert.AreEqual(11, FMessage.GetNumBitsWritten);
  FMessage.BeginReading;
  Assert.AreEqual(0, FMessage.ReadBits(3));
  Assert.AreEqual($80, FMessage.ReadBits(8));
end;

procedure TTestBitMessage.DovrebbeFareAndataERitornoDiUnDizionarioDelta;
var
  LDict, LBase, LRead: TIdDict;
begin
  LDict := TIdDict.Create;
  LBase := TIdDict.Create;
  LRead := TIdDict.Create;
  try
    LDict.SetValue('a', '1');
    LDict.SetValue('b', '22');
    LBase.SetValue('b', '2');
    LBase.SetValue('c', '3');
    NewMessage(128);
    Assert.IsTrue(FMessage.WriteDeltaDict(LDict, LBase));
    FMessage.BeginReading;
    Assert.IsTrue(FMessage.ReadDeltaDict(LRead, LBase));
    Assert.AreEqual(AnsiString('1'), LRead.GetString('a'));
    Assert.AreEqual(AnsiString('22'), LRead.GetString('b'));
    Assert.AreEqual(2, LRead.GetNumKeyVals);
    NewMessage(128);
    Assert.IsTrue(FMessage.WriteDeltaDict(LDict, nil));
    FMessage.BeginReading;
    Assert.IsTrue(FMessage.ReadDeltaDict(LRead, nil));
    Assert.AreEqual(2, LRead.GetNumKeyVals);
  finally
    LRead.Free;
    LBase.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessage.DovrebbeRiportareDizionariInvariatiComeNonCambiati;
var
  LDict, LRead: TIdDict;
begin
  LDict := TIdDict.Create;
  LRead := TIdDict.Create;
  try
    LDict.SetValue('a', '1');
    NewMessage(32);
    Assert.IsFalse(FMessage.WriteDeltaDict(LDict, LDict));
    Assert.AreEqual(2, FMessage.Size);
    FMessage.BeginReading;
    Assert.IsFalse(FMessage.ReadDeltaDict(LRead, LDict));
    Assert.AreEqual(1, LRead.GetNumKeyVals);
  finally
    LRead.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessage.DovrebbeRiferireLeProprieta;
begin
  NewMessage(16);
  Assert.AreEqual(16, FMessage.MaxSize);
  Assert.AreEqual(16, FMessage.GetRemainingSpace);
  Assert.AreEqual(128, FMessage.GetRemainingWriteBits);
  FMessage.Size := 100;
  Assert.AreEqual(16, FMessage.Size);
  FMessage.Size := 3;
  FMessage.SetWriteBit(3);
  Assert.AreEqual(3, FMessage.GetWriteBit);
  FMessage.SetReadCount(2);
  FMessage.SetReadBit(10);
  Assert.AreEqual(2, FMessage.GetReadCount);
  Assert.AreEqual(2, FMessage.GetReadBit);
  Assert.AreEqual(2 * 8 - 6 , FMessage.GetNumBitsRead);
end;

procedure TTestBitMessage.DovrebbeScrivereByteVuotiConDatiVuoti;
begin
  NewMessage(4);
  FMessage.WriteData(TBytes.Create());
  Assert.AreEqual(0, FMessage.Size);
  FMessage.InitReadOnly(TBytes.Create(1), 1);
  Assert.AreEqual(1, FMessage.MaxSize);
end;

{ TTestBitMessageDelta }

procedure TTestBitMessageDelta.SenzaBaseDovrebbeScrivereTuttoNelDelta;
var
  LDelta: TBitMessageDelta;
  LWriter: TFakeWriter;
  LRef: IBitMessageWriter;
begin
  LWriter := TFakeWriter.Create;
  LRef := LWriter;
  LDelta := TBitMessageDelta.Create;
  try
    LDelta.Init(nil, nil, LRef, nil);
    LDelta.WriteLong(5);
    LDelta.WriteString('x');
    LDelta.WriteDeltaShort(3, 3);
    LDelta.WriteDeltaByteCounter(1, 2);
    Assert.AreEqual('bits 5 32', LWriter.Calls[0]);
    Assert.AreEqual('string x', LWriter.Calls[1]);
    Assert.AreEqual('bits 0 1', LWriter.Calls[2]);
    Assert.AreEqual('bc 1 2', LWriter.Calls[3]);
    Assert.IsTrue(LDelta.HasChanged);
  finally
    LDelta.Free;
  end;
end;

procedure TTestBitMessageDelta.ConBaseUgualeDovrebbeScrivereUnSoloBit;
var
  LDelta: TBitMessageDelta;
  LWriter: TFakeWriter;
  LBase: TFakeReader;
  LWriterRef: IBitMessageWriter;
  LBaseRef: IBitMessageReader;
begin
  LWriter := TFakeWriter.Create;
  LWriterRef := LWriter;
  LBase := TFakeReader.Create;
  LBaseRef := LBase;
  LBase.Bits.Add(5);
  LBase.Bits.Add(7);
  LDelta := TBitMessageDelta.Create;
  try
    LDelta.Init(LBaseRef, nil, LWriterRef, nil);
    LDelta.WriteLong(5);
    LDelta.WriteShort(7);
    Assert.AreEqual('bits 0 1', LWriter.Calls[0]);
    Assert.AreEqual('bits 0 1', LWriter.Calls[1]);
    Assert.IsFalse(LDelta.HasChanged);
  finally
    LDelta.Free;
  end;
end;

procedure TTestBitMessageDelta.ConBaseDiversaDovrebbeScrivereUnoEIlValore;
var
  LDelta: TBitMessageDelta;
  LWriter: TFakeWriter;
  LBase: TFakeReader;
  LWriterRef: IBitMessageWriter;
  LBaseRef: IBitMessageReader;
begin
  LWriter := TFakeWriter.Create;
  LWriterRef := LWriter;
  LBase := TFakeReader.Create;
  LBaseRef := LBase;
  LBase.Bits.Add(1);
  LBase.Bits.Add(1);
  LBase.Bits.Add(1);
  LDelta := TBitMessageDelta.Create;
  try
    LDelta.Init(LBaseRef, nil, LWriterRef, nil);
    LDelta.WriteLong(5);
    // WriteDelta: the base differs from the new value, and the old value is the new one
    LDelta.WriteDeltaLong(9, 9);
    // the base differs, the old value is not the new one
    LDelta.WriteDeltaLong(9, 8);
    Assert.AreEqual('bits 1 1', LWriter.Calls[0]);
    Assert.AreEqual('bits 5 32', LWriter.Calls[1]);
    Assert.AreEqual('bits 1 1', LWriter.Calls[2]);
    Assert.AreEqual('bits 0 1', LWriter.Calls[3]);
    Assert.AreEqual('bits 1 1', LWriter.Calls[4]);
    Assert.AreEqual('bits 1 1', LWriter.Calls[5]);
    Assert.AreEqual('bits 8 32', LWriter.Calls[6]);
    Assert.IsTrue(LDelta.HasChanged);
  finally
    LDelta.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeScrivereAncheLaNuovaBase;
var
  LDelta: TBitMessageDelta;
  LWriter, LNewBase: TFakeWriter;
  LWriterRef, LNewBaseRef: IBitMessageWriter;
  LDict: TIdDict;
begin
  LWriter := TFakeWriter.Create;
  LWriterRef := LWriter;
  LNewBase := TFakeWriter.Create;
  LNewBaseRef := LNewBase;
  LDict := TIdDict.Create;
  LDelta := TBitMessageDelta.Create;
  try
    LDict.SetValue('k', 'v');
    LDelta.Init(nil, LNewBaseRef, LWriterRef, nil);
    LDelta.WriteByte(3);
    LDelta.WriteData(nil, 0);
    LDelta.WriteDict(LDict);
    LDelta.WriteDeltaShortCounter(1, 2);
    LDelta.WriteDeltaLongCounter(1, 2);
    Assert.AreEqual('bits 3 8', LNewBase.Calls[0]);
    Assert.AreEqual('data 0', LNewBase.Calls[1]);
    Assert.AreEqual('dict 1 0', LNewBase.Calls[2]);
    Assert.AreEqual('bits 2 16', LNewBase.Calls[3]);
    Assert.AreEqual('bits 2 32', LNewBase.Calls[4]);
    Assert.AreEqual('sc 1 2', LWriter.Calls[3]);
    Assert.AreEqual('lc 1 2', LWriter.Calls[4]);
  finally
    LDelta.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeLeggereDallaBaseSeIlDeltaDiceInvariato;
var
  LDelta: TBitMessageDelta;
  LBase, LDeltaReader: TFakeReader;
  LBaseRef, LDeltaRef: IBitMessageReader;
  LNewBase: TFakeWriter;
  LNewBaseRef: IBitMessageWriter;
  LDict: TIdDict;
  LData: array[0..1] of Byte;
begin
  LBase := TFakeReader.Create;
  LBaseRef := LBase;
  LDeltaReader := TFakeReader.Create;
  LDeltaRef := LDeltaReader;
  LNewBase := TFakeWriter.Create;
  LNewBaseRef := LNewBase;
  LDict := TIdDict.Create;
  LDelta := TBitMessageDelta.Create;
  try
    LBase.Bits.Add(7);
    LBase.Bits.Add(8);
    LBase.Bits.Add(9);
    LBase.Bits.Add(10);
    LBase.Bits.Add(11);
    LBase.Bits.Add(12);
    // "unchanged" bits for the long, the string, the data, the counters
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(0);
    LDelta.Init(LBaseRef, LNewBaseRef, nil, LDeltaRef);
    Assert.AreEqual(7, LDelta.ReadLong);
    Assert.AreEqual(AnsiString('fake'), LDelta.ReadString);
    LDelta.ReadData(@LData[0], 2);
    Assert.AreEqual(1, Integer(LData[0]));
    Assert.AreEqual(8, LDelta.ReadDeltaByteCounter(0));
    Assert.AreEqual(9, LDelta.ReadDeltaShortCounter(0));
    Assert.AreEqual(10, LDelta.ReadDeltaLongCounter(0));
    Assert.IsFalse(LDelta.HasChanged);
    Assert.AreEqual('bits 7 32', LNewBase.Calls[0]);
  finally
    LDelta.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeLeggereDalDeltaSeCambiato;
var
  LDelta: TBitMessageDelta;
  LBase, LDeltaReader: TFakeReader;
  LBaseRef, LDeltaRef: IBitMessageReader;
  LDict: TIdDict;
begin
  LBase := TFakeReader.Create;
  LBaseRef := LBase;
  LDeltaReader := TFakeReader.Create;
  LDeltaRef := LDeltaReader;
  LDict := TIdDict.Create;
  LDelta := TBitMessageDelta.Create;
  try
    LBase.Bits.Add(7);
    LBase.Bits.Add(8);
    LBase.Bits.Add(9);
    LBase.Bits.Add(10);
    // changed: the flag is 1 and the value follows
    LDeltaReader.Bits.Add(1);
    LDeltaReader.Bits.Add(42);
    LDeltaReader.Bits.Add(1);
    LDeltaReader.Bits.Add(1);
    LDeltaReader.Bits.Add(1);
    LDeltaReader.Bits.Add(1);
    LDelta.Init(LBaseRef, nil, nil, LDeltaRef);
    Assert.AreEqual(42, LDelta.ReadLong);
    Assert.AreEqual(9, LDelta.ReadDeltaByteCounter(8));
    Assert.AreEqual(11, LDelta.ReadDeltaShortCounter(9));
    LDelta.ReadDict(LDict);
    Assert.AreEqual(AnsiString('dict'), LDict.GetString('fake'));
    Assert.IsTrue(LDelta.HasChanged);
  finally
    LDelta.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeLeggereDallaBaseSenzaDelta;
var
  LDelta: TBitMessageDelta;
  LBase: TFakeReader;
  LBaseRef: IBitMessageReader;
  LDict: TIdDict;
begin
  LBase := TFakeReader.Create;
  LBaseRef := LBase;
  LDict := TIdDict.Create;
  LDelta := TBitMessageDelta.Create;
  try
    LBase.Bits.Add(33);
    LDelta.Init(LBaseRef, nil, nil, nil);
    Assert.AreEqual(33, LDelta.ReadLong);
    LDelta.ReadDict(LDict);
    // without a delta the dictionary is the one of the base message
    Assert.AreEqual(1, LDict.GetNumKeyVals);
    Assert.IsFalse(LDelta.HasChanged);
  finally
    LDelta.Free;
    LDict.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeLeggereIValoriDeltaConIlVecchioValore;
var
  LDelta: TBitMessageDelta;
  LDeltaReader: TFakeReader;
  LDeltaRef: IBitMessageReader;
begin
  LDeltaReader := TFakeReader.Create;
  LDeltaRef := LDeltaReader;
  LDelta := TBitMessageDelta.Create;
  try
    // without a base: the flag 0 keeps the old value, the flag 1 reads a new one
    LDeltaReader.Bits.Add(0);
    LDeltaReader.Bits.Add(1);
    LDeltaReader.Bits.Add(-30000);
    LDelta.Init(nil, nil, nil, LDeltaRef);
    Assert.AreEqual(1234, LDelta.ReadDeltaShort(1234));
    Assert.AreEqual(-30000, LDelta.ReadDeltaShort(1234));
    Assert.IsTrue(LDelta.HasChanged);
  finally
    LDelta.Free;
  end;
end;

procedure TTestBitMessageDelta.DovrebbeFareAndataERitornoDiTuttiITipiConUnaBase;
type
  TWriteAll = reference to procedure(const ADelta: TBitMessageDelta; AVariant: Integer);
var
  LWrite: TWriteAll;
  LBases: array[0..2] of TBitMessage;
  LDeltas: array[0..1] of TBitMessage;
  LDelta: TBitMessageDelta;
  LIndex: Integer;
  LData: array[0..1] of Byte;
  LRead: TIdDict;

  function Buffer: TBytes;
  begin
    SetLength(Result, 512);
    FillChar(Result[0], 512, 0);
  end;

begin
  LWrite :=
    procedure(const ADelta: TBitMessageDelta; AVariant: Integer)
    var
      LBytes: array[0..1] of Byte;
      LPair: TIdDict;
    begin
      LBytes[0] := AVariant;
      LBytes[1] := 9;
      ADelta.WriteBits(AVariant, 4);
      ADelta.WriteChar(-AVariant);
      ADelta.WriteByte(AVariant * 3);
      ADelta.WriteShort(-AVariant * 100);
      ADelta.WriteUShort(AVariant * 1000);
      ADelta.WriteLong(AVariant * 100000);
      ADelta.WriteFloat(AVariant * 1.5);
      ADelta.WriteFloat(AVariant * 0.5, 5, 10);
      ADelta.WriteAngle8(AVariant * 10.0);
      ADelta.WriteAngle16(AVariant * 10.0);
      ADelta.WriteDir(TIdVec3.Create(0.0, 1.0, 0.0), 24);
      ADelta.WriteString(AnsiString('v' + IntToStr(AVariant)));
      ADelta.WriteData(@LBytes[0], 2);
      LPair := TIdDict.Create;
      try
        LPair.SetValue('k', AnsiString(IntToStr(AVariant)));
        ADelta.WriteDict(LPair);
      finally
        LPair.Free;
      end;
      ADelta.WriteDeltaChar(1, AVariant);
      ADelta.WriteDeltaByte(1, AVariant);
      ADelta.WriteDeltaShort(1, AVariant);
      ADelta.WriteDeltaLong(1, AVariant);
      ADelta.WriteDeltaFloat(1.0, AVariant);
      ADelta.WriteDeltaFloat(1.0, AVariant, 5, 10);
      ADelta.WriteDeltaByteCounter(0, AVariant);
      ADelta.WriteDeltaShortCounter(0, AVariant);
      ADelta.WriteDeltaLongCounter(0, AVariant);
    end;
  LDelta := TBitMessageDelta.Create;
  LRead := TIdDict.Create;
  for LIndex := 0 to 2 do
  begin
    LBases[LIndex] := TBitMessage.Create;
    LBases[LIndex].Init(Buffer, 512);
    LBases[LIndex].BeginWriting;
  end;
  for LIndex := 0 to 1 do
  begin
    LDeltas[LIndex] := TBitMessage.Create;
    LDeltas[LIndex].Init(Buffer, 512);
    LDeltas[LIndex].BeginWriting;
  end;
  try
    // state 1 without a base, then state 2 against it (everything changes), then state 2 again
    LDelta.Init(nil, LBases[0], LDeltas[0], LDeltas[0]);
    LWrite(LDelta, 3);
    LBases[0].BeginReading;
    LDelta.Init(LBases[0], LBases[1], LDeltas[1], LDeltas[1]);
    LWrite(LDelta, 5);
    Assert.IsTrue(LDelta.HasChanged);
    // the new base written while writing equals the one written without a base
    LBases[2].Init(Buffer, 512);
    LBases[2].BeginWriting;
    LDelta.Init(nil, LBases[2], LDeltas[0], LDeltas[0]);
    LDeltas[0].BeginWriting;
    LWrite(LDelta, 5);
    Assert.AreEqual(LBases[2].GetSize, LBases[1].GetSize);
    Assert.IsTrue(CompareMem(@LBases[2].GetData[0], @LBases[1].GetData[0], LBases[2].GetSize));
    // writing state 2 against state 2: nothing changed
    LBases[1].BeginReading;
    LDeltas[0].BeginWriting;
    LDelta.Init(LBases[1], nil, LDeltas[0], LDeltas[0]);
    LWrite(LDelta, 5);
    Assert.IsFalse(LDelta.HasChanged);
    // reading state 2 from its delta and the base
    begin
      LBases[0].BeginReading;
      LDeltas[1].BeginReading;
      LDelta.Init(LBases[0], nil, nil, LDeltas[1]);
      begin
        Assert.AreEqual(5, LDelta.ReadBits(4));
        Assert.AreEqual(-5, LDelta.ReadChar);
        Assert.AreEqual(15, LDelta.ReadByte);
        Assert.AreEqual(-500, LDelta.ReadShort);
        Assert.AreEqual(5000, LDelta.ReadUShort);
        Assert.AreEqual(500000, LDelta.ReadLong);
        Assert.AreEqual(Double(7.5), Double(LDelta.ReadFloat), 0.0);
        Assert.AreEqual(Double(2.5), Double(LDelta.ReadFloat(5, 10)), 0.001);
        Assert.AreEqual(Double(50.0), Double(LDelta.ReadAngle8), 2.0);
        Assert.AreEqual(Double(50.0), Double(LDelta.ReadAngle16), 0.1);
        Assert.AreEqual(Double(1.0), Double(LDelta.ReadDir(24).Y), 0.01);
        Assert.AreEqual(AnsiString('v5'), LDelta.ReadString);
        LDelta.ReadData(@LData[0], 2);
        Assert.AreEqual(5, Integer(LData[0]));
        LDelta.ReadDict(LRead);
        Assert.AreEqual(AnsiString('5'), LRead.GetString('k'));
        Assert.AreEqual(5, LDelta.ReadDeltaChar(1));
        Assert.AreEqual(5, LDelta.ReadDeltaByte(1));
        Assert.AreEqual(5, LDelta.ReadDeltaShort(1));
        Assert.AreEqual(5, LDelta.ReadDeltaLong(1));
        Assert.AreEqual(Double(5.0), Double(LDelta.ReadDeltaFloat(1.0)), 0.0);
        Assert.AreEqual(Double(5.0), Double(LDelta.ReadDeltaFloat(1.0, 5, 10)), 0.001);
      end;
    end;
  finally
    LRead.Free;
    LDelta.Free;
    for LIndex := 0 to 1 do
      LDeltas[LIndex].Free;
    for LIndex := 0 to 2 do
      LBases[LIndex].Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBitMessage);
  TDUnitX.RegisterTestFixture(TTestBitMessageDelta);

end.
