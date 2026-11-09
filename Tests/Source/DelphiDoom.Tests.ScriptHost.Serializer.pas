{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer of the script state                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Serializer;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Factory,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Recorder,
  DelphiDoom.ScriptHost.Serializer.Intf,
  DelphiDoom.Tests.ScriptHost.Interpreter;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostSerializer = class(TObject)
  private
    FRecorder: TLogRecorder;
    FRecorderRef: ILogSink;
    FLog: ILog;
    FTempFile: string;
    function SerializerOf(const AInterpreter: TTestInterpreter): IScriptSerializer;
    function Saved(const AInterpreter: TTestInterpreter): TBytes;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereIByteDelloStatoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDareUnaSaveSizeUgualeAiByteScritti;
    [Test]
    procedure DovrebbeScrivereNellaPosizioneCorrenteDelFlusso;
    [Test]
    procedure DovrebbeRileggereIValoriDiOgniTipo;
    [Test]
    procedure DovrebbeRiscrivereGliStessiByteDopoLaLettura;
    [Test]
    procedure DovrebbeRiscrivereGliStessiByteConITipiPiuPiccoli;
    [Test]
    procedure DovrebbeAvvisareSeUnSetHaUnaDimensioneDiversa;
    [Test]
    procedure DovrebbeFermarsiSeUnElementoDiUnArrayNonCorrisponde;
    [Test]
    procedure DovrebbeAvvisareSeIlNumeroDiVariabiliNonCorrisponde;
    [Test]
    procedure DovrebbeAvvisareSeUnArrayStaticoHaUnaDimensioneDiversa;
    [Test]
    procedure DovrebbeAvvisareSeUnRecordHaUnNumeroDiCampiDiverso;
    [Test]
    procedure DovrebbeAvvisareSeLaLunghezzaDelFlussoNonCorrisponde;
    [Test]
    procedure DovrebbeScrivereERileggereUnFile;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeDareFalsoSeNonPuoScrivereIlFile;
    [Test]
    procedure DovrebbeAccodareEPoiLeggereDallaPosizione;
    [Test]
    procedure DovrebbeDareErroreSeLInterpreteOIlLogSononil;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.ScriptHost.Factory;

const
  SCRIPT_SIMPLE =
    'var A: Integer; S: string;'#13#10 +
    'begin'#13#10 +
    '  A := 258;'#13#10 +
    '  S := ''Hi'';'#13#10 +
    'end.';

  SCRIPT_ALL_TYPES =
    'type'#13#10 +
    '  TRec = record X: Integer; Y: string; end;'#13#10 +
    '  TKind = (kOne, kTwo, kThree);'#13#10 +
    'var'#13#10 +
    '  B: Byte; W: Word; N: Int64; G: Single; D: Double; E: Extended; Str: string;'#13#10 +
    '  U: UnicodeString; Arr: array of Integer; St: array[0..2] of Integer; R: TRec;'#13#10 +
    '  K: TKind; Flags: set of TKind;'#13#10 +
    'begin'#13#10 +
    '  B := 200; W := 60000; N := 5000000000; G := 1.5; D := 2.25; E := 3.125;'#13#10 +
    '  Str := ''text''; U := ''uni'';'#13#10 +
    '  SetLength(Arr, 3); Arr[0] := 7; Arr[1] := 8; Arr[2] := 9;'#13#10 +
    '  St[0] := 1; St[1] := 2; St[2] := 3;'#13#10 +
    '  R.X := 42; R.Y := ''rec'';'#13#10 +
    '  K := kThree; Flags := [kOne, kThree];'#13#10 +
    'end.';

  // the same variables, but the script does not run: they have the default values
  SCRIPT_ALL_TYPES_DECLARATIONS =
    'type'#13#10 +
    '  TRec = record X: Integer; Y: string; end;'#13#10 +
    '  TKind = (kOne, kTwo, kThree);'#13#10 +
    'var'#13#10 +
    '  B: Byte; W: Word; N: Int64; G: Single; D: Double; E: Extended; Str: string;'#13#10 +
    '  U: UnicodeString; Arr: array of Integer; St: array[0..2] of Integer; R: TRec;'#13#10 +
    '  K: TKind; Flags: set of TKind;'#13#10 +
    'begin'#13#10 +
    'end.';

{ TTestScriptHostSerializer }

procedure TTestScriptHostSerializer.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FRecorderRef := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderRef), nil);
  FTempFile := TPath.Combine(TPath.GetTempPath, 'ddscripthost_' + IntToStr(Random(1000000)) + '.sav');
end;

procedure TTestScriptHostSerializer.TearDown;
begin
  if TFile.Exists(FTempFile) then
    TFile.Delete(FTempFile);
  FLog := nil;
  FRecorderRef := nil;
end;

function TTestScriptHostSerializer.SerializerOf(const AInterpreter: TTestInterpreter): IScriptSerializer;
begin
  Result := TScriptHostFactory.CreateSerializer(AInterpreter.Exec, FLog);
end;

function TTestScriptHostSerializer.Saved(const AInterpreter: TTestInterpreter): TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    Assert.IsTrue(SerializerOf(AInterpreter).SaveToStream(LStream));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function TTestScriptHostSerializer.Warnings: string;
begin
  Result := FRecorder.TextOf(TLogChannel.Output);
end;

procedure TTestScriptHostSerializer.DovrebbeScrivereIByteDelloStatoComeIlVecchioCodice;
var
  LInterpreter: TTestInterpreter;
  LBytes: TBytes;
  LExpected: TBytes;
begin
  LInterpreter := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  try
    LBytes := Saved(LInterpreter);
  finally
    LInterpreter.Free;
  end;
  // the length of the data (4 bytes), the number of the variables, then: the integer (4 bytes)
  // and the string with its length and 2 bytes for each character (the format of the savegames)
  LExpected := TBytes.Create(
    16, 0, 0, 0,
    2, 0, 0, 0,
    2, 1, 0, 0,
    2, 0, 0, 0, $48, 0, $69, 0);
  Assert.AreEqual(Length(LExpected), Length(LBytes));
  Assert.IsTrue(CompareMem(@LExpected[0], @LBytes[0], Length(LExpected)));
end;

procedure TTestScriptHostSerializer.DovrebbeDareUnaSaveSizeUgualeAiByteScritti;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := TTestInterpreter.Create(SCRIPT_ALL_TYPES, True);
  try
    Assert.AreEqual(Length(Saved(LInterpreter)), SerializerOf(LInterpreter).SaveSize);
  finally
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeScrivereNellaPosizioneCorrenteDelFlusso;
var
  LInterpreter: TTestInterpreter;
  LStream: TBytesStream;
  LPrefix: TBytes;
  LSize: Integer;
begin
  LInterpreter := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LStream := TBytesStream.Create;
  try
    LPrefix := TBytes.Create(1, 2, 3);
    LStream.WriteBuffer(LPrefix[0], 3);
    Assert.IsTrue(SerializerOf(LInterpreter).SaveToStream(LStream));
    // the data after the 3 bytes, with their own length at the beginning, and the position at the end
    Assert.AreEqual(3 + 20, Integer(LStream.Position));
    Assert.AreEqual(3 + 20, Integer(LStream.Size));
    LStream.Position := 3;
    LStream.ReadBuffer(LSize, SizeOf(LSize));
    Assert.AreEqual(16, LSize);
  finally
    LStream.Free;
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeRileggereIValoriDiOgniTipo;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LTarget := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.AreEqual(0, LTarget.IntegerOf(0));
    Assert.IsTrue(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.AreEqual(258, LTarget.IntegerOf(0));
    Assert.AreEqual('Hi', LTarget.StringOf(1));
    Assert.AreEqual('', Warnings);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeRiscrivereGliStessiByteDopoLaLettura;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
  LBytes: TBytes;
  LAgain: TBytes;
begin
  // every type: integers, floats, strings, dynamic and static arrays, records, sets
  LSource := TTestInterpreter.Create(SCRIPT_ALL_TYPES, True);
  LTarget := TTestInterpreter.Create(SCRIPT_ALL_TYPES_DECLARATIONS, False);
  try
    LBytes := Saved(LSource);
    LStream := TBytesStream.Create(LBytes);
    try
      Assert.IsTrue(SerializerOf(LTarget).LoadFromStream(LStream));
    finally
      LStream.Free;
    end;
    LAgain := Saved(LTarget);
    Assert.AreEqual(Length(LBytes), Length(LAgain));
    Assert.IsTrue(CompareMem(@LBytes[0], @LAgain[0], Length(LBytes)));
    Assert.AreEqual('', Warnings);
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeRiscrivereGliStessiByteConITipiPiuPiccoli;
const
  DECLARATIONS =
    'var A: ShortInt; B: SmallInt; C: LongWord; D: Char; E: WideString; F: Currency; G: WideChar;'#13#10;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
  LBytes: TBytes;
  LAgain: TBytes;
begin
  LSource := TTestInterpreter.Create(DECLARATIONS +
    'begin A := -5; B := -300; C := 4000000000; D := ''x''; E := ''wide text''; F := 12.5; G := ''w''; end.', True);
  LTarget := TTestInterpreter.Create(DECLARATIONS + 'begin end.', False);
  try
    LBytes := Saved(LSource);
    LStream := TBytesStream.Create(LBytes);
    try
      Assert.IsTrue(SerializerOf(LTarget).LoadFromStream(LStream));
    finally
      LStream.Free;
    end;
    LAgain := Saved(LTarget);
    Assert.AreEqual(Length(LBytes), Length(LAgain));
    Assert.IsTrue(CompareMem(@LBytes[0], @LAgain[0], Length(LBytes)));
    Assert.AreEqual(-5, LTarget.IntegerOf(0));
    Assert.AreEqual(-300, LTarget.IntegerOf(1));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAvvisareSeUnSetHaUnaDimensioneDiversa;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create(
    'type TK = (a1, a2, a3);'#13#10'var F: set of TK;'#13#10'begin'#13#10'end.', True);
  LTarget := TTestInterpreter.Create(
    'type TK = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12);'#13#10'var F: set of TK;'#13#10'begin'#13#10'end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.IsTrue(Pos('Set', Warnings) > 0);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeFermarsiSeUnElementoDiUnArrayNonCorrisponde;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  // the element of the array is a record with another number of fields
  LSource := TTestInterpreter.Create(
    'type TR = record X: Integer; end;'#13#10'var D: array of TR; S: array[0..1] of TR;'#13#10 +
    'begin SetLength(D, 2); end.', True);
  LTarget := TTestInterpreter.Create(
    'type TR = record X: Integer; Y: Integer; end;'#13#10'var D: array of TR; S: array[0..1] of TR;'#13#10 +
    'begin end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.IsTrue(Pos('Record', Warnings) > 0);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
  // the same, for the static array
  LSource := TTestInterpreter.Create(
    'type TR = record X: Integer; end;'#13#10'var S: array[0..1] of TR;'#13#10'begin end.', True);
  LTarget := TTestInterpreter.Create(
    'type TR = record X: Integer; Y: Integer; end;'#13#10'var S: array[0..1] of TR;'#13#10'begin end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAvvisareSeIlNumeroDiVariabiliNonCorrisponde;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LTarget := TTestInterpreter.Create('var A: Integer;'#13#10'begin'#13#10'end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.IsTrue(Pos('Variable count (1) does not match saved variables count (2)', Warnings) > 0);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAvvisareSeUnArrayStaticoHaUnaDimensioneDiversa;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create('var St: array[0..2] of Integer;'#13#10'begin'#13#10'end.', True);
  LTarget := TTestInterpreter.Create('var St: array[0..3] of Integer;'#13#10'begin'#13#10'end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.IsTrue(Pos('element count does not match saved count', Warnings) > 0);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAvvisareSeUnRecordHaUnNumeroDiCampiDiverso;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create(
    'type TRec = record X: Integer; Y: Integer; end;'#13#10'var R: TRec;'#13#10'begin'#13#10'end.', True);
  LTarget := TTestInterpreter.Create(
    'type TRec = record X: Integer; Y: Integer; Z: Integer; end;'#13#10'var R: TRec;'#13#10'begin'#13#10'end.', False);
  LStream := TBytesStream.Create(Saved(LSource));
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
    Assert.IsTrue(Pos('element count does not match saved count', Warnings) > 0);
  finally
    LStream.Free;
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAvvisareSeLaLunghezzaDelFlussoNonCorrisponde;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LBytes: TBytes;
  LStream: TBytesStream;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LTarget := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  try
    LBytes := Saved(LSource);
    // the length that the stream says it has
    LBytes[0] := 17;
    LStream := TBytesStream.Create(LBytes);
    try
      Assert.IsFalse(SerializerOf(LTarget).LoadFromStream(LStream));
      Assert.IsTrue(Pos('Invalid stream size', Warnings) > 0);
    finally
      LStream.Free;
    end;
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeScrivereERileggereUnFile;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LTarget := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  try
    Assert.IsTrue(SerializerOf(LSource).SaveToFile(FTempFile));
    Assert.AreEqual(20, Integer(TFile.GetSize(FTempFile)));
    Assert.IsTrue(SerializerOf(LTarget).LoadFromFile(FTempFile));
    Assert.AreEqual(258, LTarget.IntegerOf(0));
    Assert.AreEqual('Hi', LTarget.StringOf(1));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeDareFalsoSeIlFileNonEsiste;
var
  LTarget: TTestInterpreter;
begin
  LTarget := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  try
    Assert.IsFalse(SerializerOf(LTarget).LoadFromFile(FTempFile));
    Assert.IsFalse(SerializerOf(LTarget).AppendToFile(FTempFile));
  finally
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeDareFalsoSeNonPuoScrivereIlFile;
var
  LSource: TTestInterpreter;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  try
    Assert.IsFalse(SerializerOf(LSource).SaveToFile(TPath.Combine(TPath.Combine(TPath.GetTempPath, 'no_such_folder_dd'), 'x.sav')));
  finally
    LSource.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeAccodareEPoiLeggereDallaPosizione;
var
  LSource: TTestInterpreter;
  LTarget: TTestInterpreter;
  LPosition: Integer;
begin
  LSource := TTestInterpreter.Create(SCRIPT_SIMPLE, True);
  LTarget := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  try
    TFile.WriteAllBytes(FTempFile, TBytes.Create(9, 9, 9));
    Assert.IsTrue(SerializerOf(LSource).AppendToFile(FTempFile));
    Assert.AreEqual(3 + 20, Integer(TFile.GetSize(FTempFile)));
    LPosition := 3;
    Assert.IsTrue(SerializerOf(LTarget).LoadFromFilePos(FTempFile, LPosition));
    Assert.AreEqual(23, LPosition);
    Assert.AreEqual(258, LTarget.IntegerOf(0));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestScriptHostSerializer.DovrebbeDareErroreSeLInterpreteOIlLogSononil;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := TTestInterpreter.Create(SCRIPT_SIMPLE, False);
  try
    Assert.WillRaise(
      procedure
      begin
        TScriptHostFactory.CreateSerializer(nil, FLog);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TScriptHostFactory.CreateSerializer(LInterpreter.Exec, nil);
      end, EArgumentNilException);
  finally
    LInterpreter.Free;
  end;
end;

end.
