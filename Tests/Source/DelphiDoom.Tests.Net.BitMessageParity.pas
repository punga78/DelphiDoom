{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the bit messages with idBitMsg of Doom 3              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.BitMessageParity;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Net.BitMessage.Types, DelphiDoom.Net.BitMessage, DelphiDoom.Net.BitMessageDelta;

type
  /// <summary>
  ///   Runs the scenarios of main.cpp (Tools\Verifica\98) with the Delphi classes and compares every line
  ///   with Tests\Data\Net\bitmsg-golden.txt, which the real idBitMsg and idBitMsgDelta of Doom 3 wrote: the
  ///   bytes of the messages in hex, the sizes and bit counts, and every value read back (floats as the
  ///   hex of their bits, so the comparison is exact).
  /// </summary>
  [TestFixture]
  [Category('Net')]
  TTestBitMessageParity = class
  strict private
    FGolden: TDictionary<string, TStringList>;
    FLines: TStringList;
    procedure Put(const ALine: string);
    procedure PutFmt(const AFormat: string; const AArguments: array of const);
    procedure DumpMessage(const ATag: string; const AMessage: TBitMessage);
    function DictText(const ADict: TIdDict): string;
    function HexOf(const AText: AnsiString): string; overload;
    function HexOf(const AData: TBytes; ALength: Integer): string; overload;
    function Bits(const AValue: Single): string;
    procedure Compare(const ASection: string);
    procedure ScenarioBasic;
    procedure ScenarioState;
    procedure ScenarioOverflow;
    procedure ScenarioDelta;
    procedure WriteFields(const ADelta: TBitMessageDelta; ASet: Integer);
    procedure ReadFields(const ATag: string; const ADelta: TBitMessageDelta; ASet: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereELeggereCometIdBitMsg;
    [Test]
    procedure DovrebbeSalvareERipristinareLoStato;
    [Test]
    procedure DovrebbeGestireOverflowEErroriCometIdBitMsg;
    [Test]
    procedure DovrebbeScrivereELeggereIDeltaCometIdBitMsgDelta;
  end;

implementation

type
  TFieldSet = record
    Long: Integer;
    Text: AnsiString;
    Data: array[0..2] of Byte;
    ByteValue: Integer;
    ShortValue: Integer;
    FloatValue: Single;
    ShortOld, ShortNew, LongOld, LongNew, ByteCounterOld, ByteCounterNew: Integer;
    ShortCounterOld, ShortCounterNew, LongCounterOld, LongCounterNew: Integer;
    Key2, Value2: AnsiString;
  end;

function MakeSet(ALong: Integer; const AText: AnsiString; AData0, AData1, AData2, AByte, AShort: Integer;
  AFloat: Single; AShortOld, AShortNew, ALongOld, ALongNew, AByteOld, AByteNew, AShortCounterOld,
  AShortCounterNew, ALongCounterOld, ALongCounterNew: Integer; const AKey, AValue: AnsiString): TFieldSet;
begin
  Result.Long := ALong;
  Result.Text := AText;
  Result.Data[0] := AData0;
  Result.Data[1] := AData1;
  Result.Data[2] := AData2;
  Result.ByteValue := AByte;
  Result.ShortValue := AShort;
  Result.FloatValue := AFloat;
  Result.ShortOld := AShortOld;
  Result.ShortNew := AShortNew;
  Result.LongOld := ALongOld;
  Result.LongNew := ALongNew;
  Result.ByteCounterOld := AByteOld;
  Result.ByteCounterNew := AByteNew;
  Result.ShortCounterOld := AShortCounterOld;
  Result.ShortCounterNew := AShortCounterNew;
  Result.LongCounterOld := ALongCounterOld;
  Result.LongCounterNew := ALongCounterNew;
  Result.Key2 := AKey;
  Result.Value2 := AValue;
end;

function FieldSet(AIndex: Integer): TFieldSet;
begin
  // the same two sets as sets[] of main.cpp
  if AIndex = 0 then
    Result := MakeSet(100, 'alpha', 1, 2, 3, 5, -7, 1.5, 10, 12, 1000, 1000, 3, 4, 300, 301, 70, 71, 'b', '2')
  else
    Result := MakeSet(100, 'beta', 1, 2, 4, 5, -8, 2.5, 12, 12, 1000, 2000, 4, 4, 301, 302, 71, 72, 'b', '3');
end;

function NewBuffer(ASize: Integer; AFill: Byte): TBytes;
begin
  SetLength(Result, ASize);
  FillChar(Result[0], ASize, AFill);
end;

{ TTestBitMessageParity }

procedure TTestBitMessageParity.Setup;
var
  LLine, LSection: string;
  LList: TStringList;
begin
  FGolden := TDictionary<string, TStringList>.Create;
  FLines := TStringList.Create;
  LList := nil;
  for LLine in TFile.ReadAllLines(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Net\bitmsg-golden.txt'))) do
  begin
    if (LLine <> '') and (LLine[1] = '[') then
    begin
      LSection := Copy(LLine, 2, Length(LLine) - 2);
      LList := TStringList.Create;
      FGolden.Add(LSection, LList);
    end
    else if Assigned(LList) then
      LList.Add(LLine);
  end;
end;

procedure TTestBitMessageParity.TearDown;
var
  LList: TStringList;
begin
  for LList in FGolden.Values do
    LList.Free;
  FGolden.Free;
  FLines.Free;
end;

procedure TTestBitMessageParity.Put(const ALine: string);
begin
  FLines.Add(ALine);
end;

procedure TTestBitMessageParity.PutFmt(const AFormat: string; const AArguments: array of const);
begin
  FLines.Add(Format(AFormat, AArguments));
end;

function TTestBitMessageParity.HexOf(const AText: AnsiString): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    Result := Result + LowerCase(IntToHex(Byte(AText[LIndex]), 2));
end;

function TTestBitMessageParity.HexOf(const AData: TBytes; ALength: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to ALength - 1 do
    Result := Result + LowerCase(IntToHex(AData[LIndex], 2));
end;

function TTestBitMessageParity.Bits(const AValue: Single): string;
begin
  Result := LowerCase(IntToHex(PCardinal(@AValue)^, 8));
end;

procedure TTestBitMessageParity.DumpMessage(const ATag: string; const AMessage: TBitMessage);
begin
  PutFmt('%s.hex %s', [ATag, HexOf(AMessage.GetData, AMessage.GetSize)]);
  PutFmt('%s.size %d', [ATag, AMessage.GetSize]);
  PutFmt('%s.bits %d', [ATag, AMessage.GetNumBitsWritten]);
end;

function TTestBitMessageParity.DictText(const ADict: TIdDict): string;
var
  LIndex: Integer;
  LPair: TIdKeyValue;
  LText: AnsiString;
begin
  LText := '';
  for LIndex := 0 to ADict.GetNumKeyVals - 1 do
  begin
    ADict.TryGetKeyVal(LIndex, LPair);
    LText := LText + LPair.Key + '=' + LPair.Value + ';';
  end;
  Result := HexOf(LText);
end;

procedure TTestBitMessageParity.Compare(const ASection: string);
var
  LExpected: TStringList;
  LIndex: Integer;
begin
  Assert.IsTrue(FGolden.TryGetValue(ASection, LExpected), 'sezione assente: ' + ASection);
  for LIndex := 0 to LExpected.Count - 1 do
  begin
    Assert.IsTrue(LIndex < FLines.Count, 'mancano righe dopo la ' + IntToStr(LIndex) + ': ' + LExpected[LIndex]);
    Assert.AreEqual(LExpected[LIndex], FLines[LIndex], 'riga ' + IntToStr(LIndex + 1) + ' di ' + ASection);
  end;
  Assert.AreEqual(LExpected.Count, FLines.Count, 'righe in piu'' di quelle del golden');
end;

procedure TTestBitMessageParity.ScenarioBasic;
var
  LMessage: TBitMessage;
  LBuffer: TBytes;
  LDict1, LBase, LRead1, LRead2: TIdDict;
  LAddress, LReadAddress: TBitMessageNetAddress;
  LData5, LRead5: TBytes;
  LChanged1, LChanged2: Boolean;
  LVector: TIdVec3;
  LText: AnsiString;
  LCount, LBitsValue: Integer;
begin
  LBuffer := NewBuffer(512, 0);
  LMessage := TBitMessage.Create;
  LDict1 := TIdDict.Create;
  LBase := TIdDict.Create;
  LRead1 := TIdDict.Create;
  LRead2 := TIdDict.Create;
  try
    LMessage.Init(LBuffer, 512);
    LMessage.BeginWriting;
    LMessage.WriteBits(5, 3);
    LMessage.WriteBits(-3, -4);
    LMessage.WriteChar(-100);
    LMessage.WriteByte(200);
    LMessage.WriteShort(-12345);
    LMessage.WriteUShort(54321);
    LMessage.WriteLong(-123456789);
    LMessage.WriteFloat(3.14159);
    LMessage.WriteFloat(0.75, 5, 10);
    LMessage.WriteFloat(-123.5, 8, 23);
    LMessage.WriteAngle8(90.0);
    LMessage.WriteAngle16(-45.5);
    LMessage.WriteDir(TIdVec3.Create(0.267261, 0.534522, 0.801784), 30);
    LMessage.WriteDir(TIdVec3.Create(-0.6, 0.0, -0.8), 24);
    LMessage.WriteBits(1, 1);
    LMessage.WriteString('Hello %d w' + AnsiChar($F6) + 'rld');
    LMessage.WriteString('abcdef', 4);
    LMessage.WriteString('raw' + AnsiChar($E9), -1, False);
    LMessage.WriteString('');
    LData5 := TBytes.Create(1, 2, 3, 250, 255);
    LMessage.WriteData(LData5);
    LAddress.Ip[0] := 192;
    LAddress.Ip[1] := 168;
    LAddress.Ip[2] := 1;
    LAddress.Ip[3] := 2;
    LAddress.Port := 27666;
    LMessage.WriteNetAddress(LAddress);
    LMessage.WriteDeltaChar(5, 5);
    LMessage.WriteDeltaChar(5, -9);
    LMessage.WriteDeltaByte(7, 200);
    LMessage.WriteDeltaShort(100, -300);
    LMessage.WriteDeltaLong(1, 1);
    LMessage.WriteDeltaLong(1, 1000000);
    LMessage.WriteDeltaFloat(1.0, 2.0);
    LMessage.WriteDeltaFloat(1.5, 1.5, 5, 10);
    LMessage.WriteDeltaFloat(1.5, 2.5, 5, 10);
    LMessage.WriteDeltaByteCounter($12, $1F);
    LMessage.WriteDeltaByteCounter($12, $12);
    LMessage.WriteDeltaShortCounter($1234, $1F34);
    LMessage.WriteDeltaLongCounter($12345678, $12355678);
    LDict1.SetValue('classname', 'light');
    LDict1.SetValue('origin', '1 2 3');
    LDict1.SetValue('Same', 'Value');
    LBase.SetValue('CLASSNAME', 'LIGHT');
    LBase.SetValue('gone', 'x');
    LBase.SetValue('same', 'value');
    LChanged1 := LMessage.WriteDeltaDict(LDict1, LBase);
    LChanged2 := LMessage.WriteDeltaDict(LDict1, nil);
    PutFmt('dictchanged %d %d', [Ord(LChanged1), Ord(LChanged2)]);
    DumpMessage('w', LMessage);
    PutFmt('remainingspace %d writebit %d', [LMessage.GetRemainingSpace, LMessage.GetWriteBit]);

    LMessage.BeginReading;
    PutFmt('r.bits %d', [LMessage.ReadBits(3)]);
    PutFmt('r.sbits %d', [LMessage.ReadBits(-4)]);
    PutFmt('r.char %d', [LMessage.ReadChar]);
    PutFmt('r.byte %d', [LMessage.ReadByte]);
    PutFmt('r.short %d', [LMessage.ReadShort]);
    PutFmt('r.ushort %d', [LMessage.ReadUShort]);
    PutFmt('r.long %d', [LMessage.ReadLong]);
    PutFmt('r.float %s', [Bits(LMessage.ReadFloat)]);
    PutFmt('r.float510 %s', [Bits(LMessage.ReadFloat(5, 10))]);
    PutFmt('r.float823 %s', [Bits(LMessage.ReadFloat(8, 23))]);
    PutFmt('r.angle8 %s', [Bits(LMessage.ReadAngle8)]);
    PutFmt('r.angle16 %s', [Bits(LMessage.ReadAngle16)]);
    LVector := LMessage.ReadDir(30);
    PutFmt('r.dir30 %s %s %s', [Bits(LVector.X), Bits(LVector.Y), Bits(LVector.Z)]);
    LVector := LMessage.ReadDir(24);
    PutFmt('r.dir24 %s %s %s', [Bits(LVector.X), Bits(LVector.Y), Bits(LVector.Z)]);
    PutFmt('r.bit %d', [LMessage.ReadBits(1)]);
    LText := LMessage.ReadString(64);
    PutFmt('r.str %d %s', [Length(LText), HexOf(LText)]);
    LText := LMessage.ReadString(64);
    PutFmt('r.str %d %s', [Length(LText), HexOf(LText)]);
    LText := LMessage.ReadString(64);
    PutFmt('r.str %d %s', [Length(LText), HexOf(LText)]);
    LText := LMessage.ReadString(3);
    PutFmt('r.str %d %s', [Length(LText), HexOf(LText)]);
    SetLength(LRead5, 5);
    LCount := LMessage.ReadData(@LRead5[0], 5);
    PutFmt('r.data %d %s', [LCount, HexOf(LRead5, 5)]);
    LReadAddress := LMessage.ReadNetAddress;
    PutFmt('r.netadr %d.%d.%d.%d:%d', [LReadAddress.Ip[0], LReadAddress.Ip[1], LReadAddress.Ip[2],
      LReadAddress.Ip[3], LReadAddress.Port]);
    PutFmt('r.dchar %d', [LMessage.ReadDeltaChar(5)]);
    PutFmt('r.dchar %d', [LMessage.ReadDeltaChar(5)]);
    PutFmt('r.dbyte %d', [LMessage.ReadDeltaByte(7)]);
    PutFmt('r.dshort %d', [LMessage.ReadDeltaShort(100)]);
    PutFmt('r.dlong %d', [LMessage.ReadDeltaLong(1)]);
    PutFmt('r.dlong %d', [LMessage.ReadDeltaLong(1)]);
    PutFmt('r.dfloat %s', [Bits(LMessage.ReadDeltaFloat(1.0))]);
    PutFmt('r.dfloat510 %s', [Bits(LMessage.ReadDeltaFloat(1.5, 5, 10))]);
    PutFmt('r.dfloat510 %s', [Bits(LMessage.ReadDeltaFloat(1.5, 5, 10))]);
    PutFmt('r.dbc %d', [LMessage.ReadDeltaByteCounter($12)]);
    PutFmt('r.dbc %d', [LMessage.ReadDeltaByteCounter($12)]);
    PutFmt('r.dsc %d', [LMessage.ReadDeltaShortCounter($1234)]);
    PutFmt('r.dlc %d', [LMessage.ReadDeltaLongCounter($12345678)]);
    LChanged1 := LMessage.ReadDeltaDict(LRead1, LBase);
    LChanged2 := LMessage.ReadDeltaDict(LRead2, nil);
    PutFmt('r.dict1 %d %s', [Ord(LChanged1), DictText(LRead1)]);
    PutFmt('r.dict2 %d %s', [Ord(LChanged2), DictText(LRead2)]);
    PutFmt('r.remaining bits %d bytes %d count %d bit %d', [LMessage.GetRemainingReadBits,
      LMessage.GetRemainingData, LMessage.GetReadCount, LMessage.GetReadBit]);
    PutFmt('r.pastend %d', [LMessage.ReadBits(8)]);
    PutFmt('r.readdata %d', [LMessage.ReadData(nil, 10)]);

    LBitsValue := TBitMessage.DirToBits(TIdVec3.Create(0.0, -1.0, 0.0), 18);
    LVector := TBitMessage.BitsToDir(LBitsValue, 18);
    PutFmt('dir.bits %s back %s %s %s', [LowerCase(IntToHex(LBitsValue, 8)), Bits(LVector.X), Bits(LVector.Y),
      Bits(LVector.Z)]);
  finally
    LRead2.Free;
    LRead1.Free;
    LBase.Free;
    LDict1.Free;
    LMessage.Free;
  end;
end;

procedure TTestBitMessageParity.ScenarioState;
var
  LMessage: TBitMessage;
  LSize, LBit, LCount, LReadBit: Integer;
begin
  LMessage := TBitMessage.Create;
  try
    LMessage.Init(NewBuffer(16, $AA), 16);
    LMessage.BeginWriting;
    LMessage.WriteBits($7FF, 11);
    LMessage.SaveWriteState(LSize, LBit);
    PutFmt('saved %d %d', [LSize, LBit]);
    LMessage.WriteBits($FFFF, 16);
    PutFmt('after %d %d bits %d', [LMessage.GetSize, LMessage.GetWriteBit, LMessage.GetNumBitsWritten]);
    LMessage.RestoreWriteState(LSize, LBit);
    PutFmt('restored %d %d bits %d remaining %d', [LMessage.GetSize, LMessage.GetWriteBit,
      LMessage.GetNumBitsWritten, LMessage.GetRemainingWriteBits]);
    LMessage.WriteBits(0, 2);
    DumpMessage('w', LMessage);
    LMessage.SetWriteBit(3);
    DumpMessage('w3', LMessage);
    LMessage.SetSize(100);
    PutFmt('size %d max %d', [LMessage.GetSize, LMessage.GetMaxSize]);
    LMessage.SetSize(2);
    LMessage.BeginReading;
    PutFmt('a %d', [LMessage.ReadBits(5)]);
    LMessage.SaveReadState(LCount, LReadBit);
    PutFmt('readstate %d %d', [LCount, LReadBit]);
    PutFmt('b %d', [LMessage.ReadBits(7)]);
    LMessage.RestoreReadState(LCount, LReadBit);
    PutFmt('b2 %d', [LMessage.ReadBits(7)]);
    LMessage.SetReadBit(9);
    PutFmt('rbit %d', [LMessage.GetReadBit]);
    LMessage.ReadByteAlign;
    PutFmt('numread %d', [LMessage.GetNumBitsRead]);
    PutFmt('big %d', [LMessage.ReadBits(32)]);
    PutFmt('signed31 %d', [LMessage.ReadBits(-31)]);
    LMessage.BeginReading;
    PutFmt('signed12 %d', [LMessage.ReadBits(-12)]);
  finally
    LMessage.Free;
  end;
end;

procedure TTestBitMessageParity.ScenarioOverflow;
var
  LMessage, LError, LReadOnly: TBitMessage;
  LRead1, LRead2, LRead3, LRead4: Integer;

  procedure Attempt(const AName: string; const AAction: TProc);
  begin
    try
      AAction();
      Put('err none');
    except
      on EBitMessageException do
        Put('err ' + AName);
    end;
  end;

begin
  LMessage := TBitMessage.Create;
  LError := TBitMessage.Create;
  LReadOnly := TBitMessage.Create;
  try
    LMessage.Init(NewBuffer(4, 0), 4);
    LMessage.SetAllowOverflow(True);
    LMessage.BeginWriting;
    LMessage.WriteByte(1);
    LMessage.WriteByte(2);
    LMessage.WriteByte(3);
    LMessage.WriteLong($04030201);
    PutFmt('overflowed %d size %d bits %d', [Ord(LMessage.IsOverflowed), LMessage.GetSize, LMessage.GetNumBitsWritten]);
    LMessage.WriteByte(300);
    DumpMessage('w', LMessage);
    LMessage.BeginWriting;
    PutFmt('overflowed after begin %d', [Ord(LMessage.IsOverflowed)]);

    LError.Init(NewBuffer(4, 0), 4);
    LError.BeginWriting;
    Attempt('badbits0', procedure begin LError.WriteBits(1, 0); end);
    Attempt('badbits33', procedure begin LError.WriteBits(1, 33); end);
    Attempt('badbits-32', procedure begin LError.WriteBits(1, -32); end);
    LError.WriteLong(1);
    Attempt('overflow', procedure begin LError.WriteBits(1, 1); end);
    Attempt('readbits0', procedure begin LError.ReadBits(0); end);

    LReadOnly.InitReadOnly(TBytes.Create($A5, $5A, $FF), 3);
    LReadOnly.SetSize(3);
    LReadOnly.BeginReading;
    LRead1 := LReadOnly.ReadByte;
    LRead2 := LReadOnly.ReadBits(4);
    LRead3 := LReadOnly.ReadBits(4);
    LRead4 := LReadOnly.ReadBits(9);
    PutFmt('ro %d %d %d %d', [LRead1, LRead2, LRead3, LRead4]);
    PutFmt('ro.remaining %d', [LReadOnly.GetRemainingReadBits]);
    PutFmt('ro.past %d', [LReadOnly.ReadBits(16)]);
    Attempt('readonly', procedure begin LReadOnly.WriteBits(1, 1); end);
  finally
    LReadOnly.Free;
    LError.Free;
    LMessage.Free;
  end;
end;

procedure TTestBitMessageParity.WriteFields(const ADelta: TBitMessageDelta; ASet: Integer);
var
  LFields: TFieldSet;
  LDict: TIdDict;
begin
  LFields := FieldSet(ASet);
  ADelta.WriteLong(LFields.Long);
  ADelta.WriteString(LFields.Text);
  ADelta.WriteData(@LFields.Data[0], 3);
  ADelta.WriteByte(LFields.ByteValue);
  ADelta.WriteShort(LFields.ShortValue);
  ADelta.WriteFloat(LFields.FloatValue);
  ADelta.WriteDeltaShort(LFields.ShortOld, LFields.ShortNew);
  ADelta.WriteDeltaLong(LFields.LongOld, LFields.LongNew);
  ADelta.WriteDeltaByteCounter(LFields.ByteCounterOld, LFields.ByteCounterNew);
  ADelta.WriteDeltaShortCounter(LFields.ShortCounterOld, LFields.ShortCounterNew);
  ADelta.WriteDeltaLongCounter(LFields.LongCounterOld, LFields.LongCounterNew);
  LDict := TIdDict.Create;
  try
    LDict.SetValue('a', '1');
    LDict.SetValue(LFields.Key2, LFields.Value2);
    ADelta.WriteDict(LDict);
  finally
    LDict.Free;
  end;
  ADelta.WriteAngle8(45.0);
  ADelta.WriteDir(TIdVec3.Create(0.0, 0.0, 1.0), 15);
end;

procedure TTestBitMessageParity.ReadFields(const ATag: string; const ADelta: TBitMessageDelta; ASet: Integer);
var
  LFields: TFieldSet;
  LData: array[0..2] of Byte;
  LDict: TIdDict;
  LVector: TIdVec3;
begin
  LFields := FieldSet(ASet);
  PutFmt('%s.long %d', [ATag, ADelta.ReadLong]);
  PutFmt('%s.str %s', [ATag, HexOf(ADelta.ReadString(64))]);
  ADelta.ReadData(@LData[0], 3);
  PutFmt('%s.data %s', [ATag, HexOf(TBytes.Create(LData[0], LData[1], LData[2]), 3)]);
  PutFmt('%s.byte %d', [ATag, ADelta.ReadByte]);
  PutFmt('%s.short %d', [ATag, ADelta.ReadShort]);
  PutFmt('%s.float %s', [ATag, Bits(ADelta.ReadFloat)]);
  PutFmt('%s.dshort %d', [ATag, ADelta.ReadDeltaShort(LFields.ShortOld)]);
  PutFmt('%s.dlong %d', [ATag, ADelta.ReadDeltaLong(LFields.LongOld)]);
  PutFmt('%s.bc %d', [ATag, ADelta.ReadDeltaByteCounter(LFields.ByteCounterOld)]);
  PutFmt('%s.sc %d', [ATag, ADelta.ReadDeltaShortCounter(LFields.ShortCounterOld)]);
  PutFmt('%s.lc %d', [ATag, ADelta.ReadDeltaLongCounter(LFields.LongCounterOld)]);
  LDict := TIdDict.Create;
  try
    ADelta.ReadDict(LDict);
    PutFmt('%s.dict %s', [ATag, DictText(LDict)]);
  finally
    LDict.Free;
  end;
  PutFmt('%s.angle %s', [ATag, Bits(ADelta.ReadAngle8)]);
  LVector := ADelta.ReadDir(15);
  PutFmt('%s.dir %s %s %s', [ATag, Bits(LVector.X), Bits(LVector.Y), Bits(LVector.Z)]);
  PutFmt('%s.changed %d', [ATag, Ord(ADelta.HasChanged)]);
end;

procedure TTestBitMessageParity.ScenarioDelta;
var
  LNewBase0, LDelta0, LNewBase1, LDelta1, LNewBase2, LNewBase3, LDelta2: TBitMessage;
  LWriter0, LWriter1, LReader1, LReader0, LWriter2: TBitMessageDelta;
begin
  LNewBase0 := TBitMessage.Create;
  LDelta0 := TBitMessage.Create;
  LNewBase1 := TBitMessage.Create;
  LDelta1 := TBitMessage.Create;
  LNewBase2 := TBitMessage.Create;
  LNewBase3 := TBitMessage.Create;
  LDelta2 := TBitMessage.Create;
  LWriter0 := TBitMessageDelta.Create;
  LWriter1 := TBitMessageDelta.Create;
  LReader1 := TBitMessageDelta.Create;
  LReader0 := TBitMessageDelta.Create;
  LWriter2 := TBitMessageDelta.Create;
  try
    LNewBase0.Init(NewBuffer(256, 0), 256);
    LDelta0.Init(NewBuffer(256, 0), 256);
    LNewBase1.Init(NewBuffer(256, 0), 256);
    LDelta1.Init(NewBuffer(256, 0), 256);
    LNewBase0.BeginWriting;
    LDelta0.BeginWriting;
    LNewBase1.BeginWriting;
    LDelta1.BeginWriting;

    // the first state, without a base
    LWriter0.Init(nil, LNewBase0, LDelta0, LDelta0);
    WriteFields(LWriter0, 0);
    PutFmt('w0.changed %d', [Ord(LWriter0.HasChanged)]);
    DumpMessage('w0.delta', LDelta0);
    DumpMessage('w0.newbase', LNewBase0);

    // the second state against the first
    LNewBase0.BeginReading;
    LWriter1.Init(LNewBase0, LNewBase1, LDelta1, LDelta1);
    WriteFields(LWriter1, 1);
    PutFmt('w1.changed %d', [Ord(LWriter1.HasChanged)]);
    DumpMessage('w1.delta', LDelta1);
    DumpMessage('w1.newbase', LNewBase1);

    // reading the second delta against the first state
    LNewBase0.BeginReading;
    LDelta1.BeginReading;
    LNewBase2.Init(NewBuffer(256, 0), 256);
    LNewBase2.BeginWriting;
    LReader1.Init(LNewBase0, LNewBase2, nil, LDelta1);
    ReadFields('r1', LReader1, 1);
    DumpMessage('r1.newbase', LNewBase2);

    // reading the first delta without a base
    LDelta0.BeginReading;
    LReader0.Init(nil, nil, nil, LDelta0);
    ReadFields('r0', LReader0, 0);

    // the same state again against itself: nothing changed
    LNewBase3.Init(NewBuffer(256, 0), 256);
    LDelta2.Init(NewBuffer(256, 0), 256);
    LNewBase3.BeginWriting;
    LDelta2.BeginWriting;
    LNewBase1.BeginReading;
    LWriter2.Init(LNewBase1, LNewBase3, LDelta2, LDelta2);
    WriteFields(LWriter2, 1);
    PutFmt('w2.changed %d', [Ord(LWriter2.HasChanged)]);
    DumpMessage('w2.delta', LDelta2);
  finally
    LWriter2.Free;
    LReader0.Free;
    LReader1.Free;
    LWriter1.Free;
    LWriter0.Free;
    LDelta2.Free;
    LNewBase3.Free;
    LNewBase2.Free;
    LDelta1.Free;
    LNewBase1.Free;
    LDelta0.Free;
    LNewBase0.Free;
  end;
end;

procedure TTestBitMessageParity.DovrebbeScrivereELeggereCometIdBitMsg;
begin
  ScenarioBasic;
  Compare('basic');
end;

procedure TTestBitMessageParity.DovrebbeSalvareERipristinareLoStato;
begin
  ScenarioState;
  Compare('state');
end;

procedure TTestBitMessageParity.DovrebbeGestireOverflowEErroriCometIdBitMsg;
begin
  ScenarioOverflow;
  Compare('overflow');
end;

procedure TTestBitMessageParity.DovrebbeScrivereELeggereIDeltaCometIdBitMsgDelta;
begin
  ScenarioDelta;
  Compare('delta');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBitMessageParity);

end.
