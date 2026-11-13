{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - parity with the old code      }
{                                                                              }
{  The file Tests\Data\Serializer\serializer.golden.txt is the answer of the   }
{  OLD TSerializer of the engine (Base\p_serializer.pas before issue #85) on   }
{  60 records of TGoldenRecord: IN is the record, SAVE the bytes that the old  }
{  code wrote, LOAD what it read back (only where the old reader worked: it    }
{  read the texts at two bytes per character, so a record with a text has no   }
{  LOAD line). The library must write the same bytes and read the same values. }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Serializer.Types,
  DelphiDoom.Serializer.Intf, DelphiDoom.Tests.Serializer.Fakes;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerGolden = class(TObject)
  private
    FResolver: TFakeResolver;
    FResolverIntf: ISerializerStateResolver;
    FSerializer: ISerializer;
    FLines: TStringList;
    function Tokens(const ALine: string; ASkip: Integer): TArray<string>;
    class function HexToBytes(const AHex: string): TBytes; static;
    class function BytesToHex(const ABytes: TBytes; ACount: Integer): string; static;
    procedure BuildRecord(const ALine: string; out ARecord: TGoldenRecord);
    function FindLine(const APrefix: string): string;
    class function FieldHex(const ARecord; AOffset, ASize: Integer): string; static;
    class function TextHex(const AText: ShortString): string; static;
    procedure CompareFields(const AId: string; const AActual: TGoldenRecord; const AExpected: TArray<string>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereGliStessiByteDelVecchioCodice;
    [Test]
    procedure DovrebbeLeggereGliStessiValoriDelVecchioCodice;
    [Test]
    procedure DovrebbeApplicareTuttiIDefaultSuUnFlussoVuoto;
  end;

implementation

uses
  DelphiDoom.Serializer.Factory;

const
  FIELD_COUNT = 23;

{ TTestSerializerGolden }

procedure TTestSerializerGolden.Setup;
begin
  FResolver := TFakeResolver.Create;
  FResolverIntf := FResolver;
  FSerializer := TSerializerFactory.Create(FResolver, FResolver, FResolver).CreateSerializer;
  FillGoldenTable(FSerializer);
  FLines := TStringList.Create;
  FLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) +
    '..\..\Tests\Data\Serializer\serializer.golden.txt'));
end;

procedure TTestSerializerGolden.TearDown;
begin
  FLines.Free;
  FSerializer := nil;
  FResolverIntf := nil;
  FResolver := nil;
end;

function TTestSerializerGolden.Tokens(const ALine: string; ASkip: Integer): TArray<string>;
var
  LParts: TArray<string>;
begin
  LParts := ALine.Split([' ']);
  Result := LParts[ASkip].Split([',']);
end;

class function TTestSerializerGolden.HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2));
end;

class function TTestSerializerGolden.BytesToHex(const ABytes: TBytes; ACount: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to ACount - 1 do
    Result := Result + IntToHex(ABytes[LIndex], 2);
end;

procedure TTestSerializerGolden.BuildRecord(const ALine: string; out ARecord: TGoldenRecord);
var
  LTokens: TArray<string>;

  procedure Put(var ADestination; AIndex: Integer);
  var
    LBytes: TBytes;
  begin
    LBytes := HexToBytes(LTokens[AIndex]);
    Move(LBytes[0], ADestination, Length(LBytes));
  end;

  function Reference(AIndex: Integer; ABase: NativeUInt; AStride: NativeUInt; AFirst: Cardinal): Pointer;
  var
    LToken: string;
    LNumber: Cardinal;
  begin
    LToken := LTokens[AIndex];
    if LToken = 'n' then
      Exit(nil);
    LNumber := Cardinal(StrToInt64(Copy(LToken, 2, MaxInt)));
    Result := Pointer(ABase + (LNumber - AFirst) * AStride);
  end;

begin
  LTokens := Tokens(ALine, 2);
  Assert.AreEqual<Integer>(FIELD_COUNT, Length(LTokens));
  FillChar(ARecord, SizeOf(ARecord), 0);
  Put(ARecord.Generic6, 0);
  Put(ARecord.Byte0, 1);
  Put(ARecord.Byte1, 2);
  Put(ARecord.ShortInt0, 3);
  Put(ARecord.ShortInt1, 4);
  Put(ARecord.Word0, 5);
  Put(ARecord.Word1, 6);
  Put(ARecord.SmallInt0, 7);
  Put(ARecord.SmallInt1, 8);
  Put(ARecord.LongWord0, 9);
  Put(ARecord.LongWord1, 10);
  Put(ARecord.Integer0, 11);
  Put(ARecord.Integer1, 12);
  Put(ARecord.Int640, 13);
  Put(ARecord.Int641, 14);
  Put(ARecord.Float0, 15);
  Put(ARecord.Float1, 16);
  ARecord.State := Reference(17, FAKE_STATE_BASE, FAKE_STATE_STRIDE, 0);
  ARecord.Mobj := Reference(18, FAKE_MOBJ_BASE, 1, 0);
  ARecord.Player := Reference(19, FAKE_PLAYER_BASE, FAKE_PLAYER_STRIDE, 0);
  Put(ARecord.Text0, 20);
  Put(ARecord.Text1, 21);
  Put(ARecord.Generic4, 22);
end;

function TTestSerializerGolden.FindLine(const APrefix: string): string;
var
  LLine: string;
begin
  for LLine in FLines do
    if LLine.StartsWith(APrefix) then
      Exit(LLine);
  Result := '';
end;

procedure TTestSerializerGolden.DovrebbeScrivereGliStessiByteDelVecchioCodice;
var
  LIndex, LChecked, LSize: Integer;
  LRecord: TGoldenRecord;
  LBuffer: TBytes;
  LParts: TArray<string>;
begin
  SetLength(LBuffer, 4096);
  LChecked := 0;
  for LIndex := 0 to FLines.Count - 1 do
  begin
    if not FLines[LIndex].StartsWith('IN ') then
      Continue;
    BuildRecord(FLines[LIndex], LRecord);
    LParts := FLines[LIndex + 1].Split([' ']);
    Assert.AreEqual('SAVE', LParts[0]);
    LSize := FSerializer.SaveToMemory(@LBuffer[0], @LRecord, Length(LBuffer));
    Assert.AreEqual(StrToInt(LParts[3]), LSize, 'size of record ' + LParts[1]);
    Assert.AreEqual(LParts[2], BytesToHex(LBuffer, LSize), 'bytes of record ' + LParts[1]);
    Inc(LChecked);
  end;
  Assert.AreEqual(60, LChecked);
end;

class function TTestSerializerGolden.FieldHex(const ARecord; AOffset, ASize: Integer): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ASize);
  Move((PByte(@ARecord) + AOffset)^, LBytes[0], ASize);
  Result := BytesToHex(LBytes, ASize);
end;

class function TTestSerializerGolden.TextHex(const AText: ShortString): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AText) + 1);
  Move(AText, LBytes[0], Length(LBytes));
  Result := BytesToHex(LBytes, Length(LBytes));
end;

procedure TTestSerializerGolden.CompareFields(const AId: string; const AActual: TGoldenRecord;
  const AExpected: TArray<string>);
begin
  Assert.AreEqual<Integer>(FIELD_COUNT, Length(AExpected));
  Assert.AreEqual(AExpected[0], FieldHex(AActual.Generic6, 0, 6), AId + ' generic');
  Assert.AreEqual(AExpected[1], FieldHex(AActual.Byte0, 0, 1), AId + ' byte0');
  Assert.AreEqual(AExpected[2], FieldHex(AActual.Byte1, 0, 1), AId + ' byte1');
  Assert.AreEqual(AExpected[3], FieldHex(AActual.ShortInt0, 0, 1), AId + ' shortint0');
  Assert.AreEqual(AExpected[4], FieldHex(AActual.ShortInt1, 0, 1), AId + ' shortint1');
  Assert.AreEqual(AExpected[5], FieldHex(AActual.Word0, 0, 2), AId + ' word0');
  Assert.AreEqual(AExpected[6], FieldHex(AActual.Word1, 0, 2), AId + ' word1');
  Assert.AreEqual(AExpected[7], FieldHex(AActual.SmallInt0, 0, 2), AId + ' smallint0');
  Assert.AreEqual(AExpected[8], FieldHex(AActual.SmallInt1, 0, 2), AId + ' smallint1');
  Assert.AreEqual(AExpected[9], FieldHex(AActual.LongWord0, 0, 4), AId + ' longword0');
  Assert.AreEqual(AExpected[10], FieldHex(AActual.LongWord1, 0, 4), AId + ' longword1');
  Assert.AreEqual(AExpected[11], FieldHex(AActual.Integer0, 0, 4), AId + ' integer0');
  Assert.AreEqual(AExpected[12], FieldHex(AActual.Integer1, 0, 4), AId + ' integer1');
  Assert.AreEqual(AExpected[13], FieldHex(AActual.Int640, 0, 8), AId + ' int640');
  Assert.AreEqual(AExpected[14], FieldHex(AActual.Int641, 0, 8), AId + ' int641');
  Assert.AreEqual(AExpected[15], FieldHex(AActual.Float0, 0, 4), AId + ' float0');
  Assert.AreEqual(AExpected[16], FieldHex(AActual.Float1, 0, 4), AId + ' float1');
  // the references hold the raw number: the low 32 bits of the slot
  Assert.AreEqual(AExpected[17], FieldHex(AActual.State, 0, 4), AId + ' state');
  Assert.AreEqual(AExpected[18], FieldHex(AActual.Mobj, 0, 4), AId + ' mobj');
  Assert.AreEqual(AExpected[19], FieldHex(AActual.Player, 0, 4), AId + ' player');
  Assert.AreEqual(AExpected[20], TextHex(AActual.Text0), AId + ' text0');
  Assert.AreEqual(AExpected[21], TextHex(AActual.Text1), AId + ' text1');
  Assert.AreEqual(AExpected[22], FieldHex(AActual.Generic4, 0, 4), AId + ' generic4');
end;

procedure TTestSerializerGolden.DovrebbeLeggereGliStessiValoriDelVecchioCodice;
var
  LIndex, LChecked, LSize: Integer;
  LRead: TGoldenRecord;
  LBuffer: TBytes;
  LParts: TArray<string>;
  LSaved: TBytes;
begin
  SetLength(LBuffer, 4096);
  LChecked := 0;
  for LIndex := 0 to FLines.Count - 1 do
  begin
    if not FLines[LIndex].StartsWith('LOAD ') or FLines[LIndex].StartsWith('LOAD EMPTY') then
      Continue;
    LParts := FLines[LIndex].Split([' ']);
    // the stream is the one of the same record in the file
    LSaved := HexToBytes(FindLine('SAVE ' + LParts[1] + ' ').Split([' '])[2]);
    Move(LSaved[0], LBuffer[0], Length(LSaved));
    LSize := Length(LSaved);
    FillChar(LRead, SizeOf(LRead), $CC);
    Assert.AreEqual(LSize, FSerializer.LoadFromMemory(@LBuffer[0], @LRead, LSize));
    CompareFields(LParts[1], LRead, LParts[2].Split([',']));
    Inc(LChecked);
  end;
  Assert.IsTrue(LChecked >= 3);
end;

procedure TTestSerializerGolden.DovrebbeApplicareTuttiIDefaultSuUnFlussoVuoto;
var
  LRead: TGoldenRecord;
  LBuffer: TBytes;
  LLine: string;
begin
  LLine := FindLine('LOAD EMPTY ');
  Assert.IsTrue(LLine <> '');
  // only the end marker
  SetLength(LBuffer, 2);
  FillChar(LRead, SizeOf(LRead), $CC);
  FSerializer.LoadFromMemory(@LBuffer[0], @LRead, 2);
  CompareFields('empty', LRead, LLine.Split([' '])[2].Split([',']));
end;

end.