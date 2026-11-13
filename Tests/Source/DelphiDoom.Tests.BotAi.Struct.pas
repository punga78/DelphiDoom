{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the structures of the configuration files (DUnitX)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Struct;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Struct.Types,
  DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotStruct = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    FDefinition: TBotStructDefinition;
    function Read(const AText: AnsiString; var ABuffer: TBytes; const AOffset: Integer = 0): Boolean;
    function IntegerAt(const ABuffer: TBytes; const AOffset: Integer): Integer;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareUnCampoPerNome;
    [Test]
    procedure DovrebbeLeggereIlCaricatoDalFile;
    [Test]
    procedure DovrebbeLeggereUnaStrutturaDopoUnOffset;
    [Test]
    procedure DovrebbeFinireUnArrayCorto;
    [Test]
    procedure DovrebbeTroncareUnaStringaA79Caratteri;
    [Test]
    procedure DovrebbeDareFalsoESegnalareUnCampoSconosciuto;
    [Test]
    procedure DovrebbeDareFalsoPerUnValoreFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnRealeInUnCampoIntero;
    [Test]
    procedure DovrebbeAccettareUnaLetteraTraApici;
    [Test]
    procedure DovrebbeLeggereUnaStrutturaAnnidataIgnorandoLErrore;
    [Test]
    procedure DovrebbeAlzareUnErroreSeIlCampoStaFuoriDalBuffer;
    [Test]
    procedure DovrebbeScrivereLaStrutturaComeIlFileDiConfigurazione;
    [Test]
    procedure DovrebbeAlzareUnErroreSeScriveUnCampoFuoriDalBuffer;
    [TestCase('intero', '2,2')]
    [TestCase('decimale', '1.5,1.5')]
    [TestCase('zeri finali', '0.100000,0.1')]
    [TestCase('negativo', '-3.25,-3.25')]
    [TestCase('zero', '0,0')]
    [TestCase('centinaia', '100,100')]
    procedure DovrebbeScrivereUnRealeSenzaZeriFinali(const AValue: string; const AExpected: string);
    [Test]
    procedure DovrebbeScrivereMenoZeroPerUnNegativoCheArrotondaAZero;
    [Test]
    procedure DovrebbeScrivereLeTabulazioni;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Struct.Reader, DelphiDoom.BotAi.Struct.Writer,
  DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Text.CFormat;

const
  // the structure of the tests: number (4), real (4), text (80), array of 3 integers (12), a char (1)
  OFFSET_NUMBER = 0;
  OFFSET_REAL = 4;
  OFFSET_TEXT = 8;
  OFFSET_ARRAY = 88;
  OFFSET_CHAR = 100;
  TEST_SIZE = 101;

{ TTestBotStruct }

procedure TTestBotStruct.Setup;
var
  LFields: TArray<TBotFieldDefinition>;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
  LFields := [
    TBotFieldDefinition.Make('number', OFFSET_NUMBER, FT_INT or FT_BOUNDED),
    TBotFieldDefinition.Make('real', OFFSET_REAL, FT_FLOAT),
    TBotFieldDefinition.Make('text', OFFSET_TEXT, FT_STRING),
    TBotFieldDefinition.Make('array', OFFSET_ARRAY, FT_INT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('char', OFFSET_CHAR, FT_CHAR)];
  LFields[0].FloatMin := 0;
  LFields[0].FloatMax := 1000;
  FDefinition := TBotStructDefinition.Create(TEST_SIZE, LFields);
end;

procedure TTestBotStruct.TearDown;
begin
  FDefinition.Free;
  FFilesRef := nil;
  FImportRef := nil;
end;

function TTestBotStruct.Read(const AText: AnsiString; var ABuffer: TBytes; const AOffset: Integer): Boolean;
var
  LSource: TBotChatSource;
begin
  FFiles.Add('botfiles/s.c', AText);
  LSource := TBotChatSource.Open(FImport, FFiles, 's.c');
  try
    Result := TBotStructReader.ReadStructure(LSource, FDefinition, ABuffer, AOffset);
  finally
    LSource.Free;
  end;
end;

function TTestBotStruct.IntegerAt(const ABuffer: TBytes; const AOffset: Integer): Integer;
begin
  Move(ABuffer[AOffset], Result, SizeOf(Integer));
end;

function TTestBotStruct.Printed: string;
begin
  Result := FImport.Lines.Text;
end;

procedure TTestBotStruct.DovrebbeTrovareUnCampoPerNome;
var
  LField: TBotFieldDefinition;
begin
  Assert.IsTrue(FDefinition.FindField('real', LField));
  Assert.AreEqual(OFFSET_REAL, LField.Offset);
  Assert.IsFalse(FDefinition.FindField('nothing', LField));
  Assert.AreEqual(0, LField.Offset);
end;

procedure TTestBotStruct.DovrebbeLeggereIlCaricatoDalFile;
var
  LBuffer: TBytes;
  LReal: Single;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsTrue(Read('{ number 25 real 1.5 text "hello" array {1, 2, 3} char 65 }', LBuffer));
  Assert.AreEqual(25, IntegerAt(LBuffer, OFFSET_NUMBER));
  Move(LBuffer[OFFSET_REAL], LReal, SizeOf(Single));
  Assert.AreEqual(Double(1.5), Double(LReal));
  Assert.AreEqual('hello', string(PAnsiChar(@LBuffer[OFFSET_TEXT])));
  Assert.AreEqual(2, IntegerAt(LBuffer, OFFSET_ARRAY + 4));
  Assert.AreEqual(3, IntegerAt(LBuffer, OFFSET_ARRAY + 8));
  Assert.AreEqual(65, Integer(LBuffer[OFFSET_CHAR]));
end;

procedure TTestBotStruct.DovrebbeLeggereUnaStrutturaDopoUnOffset;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE + 10);
  Assert.IsTrue(Read('{ number 7 }', LBuffer, 10));
  Assert.AreEqual(0, IntegerAt(LBuffer, 0));
  Assert.AreEqual(7, IntegerAt(LBuffer, 10));
end;

procedure TTestBotStruct.DovrebbeFinireUnArrayCorto;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsTrue(Read('{ array {5, 6} number 9 }', LBuffer));
  Assert.AreEqual(5, IntegerAt(LBuffer, OFFSET_ARRAY));
  Assert.AreEqual(6, IntegerAt(LBuffer, OFFSET_ARRAY + 4));
  Assert.AreEqual(0, IntegerAt(LBuffer, OFFSET_ARRAY + 8));
  Assert.AreEqual(9, IntegerAt(LBuffer, OFFSET_NUMBER));
end;

procedure TTestBotStruct.DovrebbeTroncareUnaStringaA79Caratteri;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsTrue(Read(AnsiString('{ text "' + StringOfChar('x', 100) + '" }'), LBuffer));
  Assert.AreEqual(79, Integer(Length(string(PAnsiChar(@LBuffer[OFFSET_TEXT])))));
  Assert.AreEqual(0, Integer(LBuffer[OFFSET_TEXT + 79]));
end;

procedure TTestBotStruct.DovrebbeDareFalsoESegnalareUnCampoSconosciuto;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsFalse(Read('{ nothing 1 }', LBuffer));
  Assert.Contains(Printed, 'unknown structure field nothing');
end;

procedure TTestBotStruct.DovrebbeDareFalsoPerUnValoreFuoriIntervallo;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsFalse(Read('{ number 1001 }', LBuffer));
  Assert.Contains(Printed, 'value 1001 out of range [0, 1000]');
end;

procedure TTestBotStruct.DovrebbeRifiutareUnRealeInUnCampoIntero;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsFalse(Read('{ number 1.5 }', LBuffer));
  Assert.Contains(Printed, 'unexpected float');
end;

procedure TTestBotStruct.DovrebbeAccettareUnaLetteraTraApici;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, TEST_SIZE);
  Assert.IsTrue(Read('{ char ''z'' }', LBuffer));
  Assert.AreEqual(Ord('z'), Integer(LBuffer[OFFSET_CHAR]));
end;

procedure TTestBotStruct.DovrebbeLeggereUnaStrutturaAnnidataIgnorandoLErrore;
var
  LSubFields: TArray<TBotFieldDefinition>;
  LFields: TArray<TBotFieldDefinition>;
  LSub: TBotStructDefinition;
  LOuter: TBotStructDefinition;
  LSource: TBotChatSource;
  LBuffer: TBytes;
begin
  LSubFields := [TBotFieldDefinition.Make('x', 0, FT_INT)];
  LSub := TBotStructDefinition.Create(4, LSubFields);
  LFields := [TBotFieldDefinition.Make('sub', 0, FT_STRUCT), TBotFieldDefinition.Make('after', 4, FT_INT)];
  LFields[0].SubStruct := LSub;
  LOuter := TBotStructDefinition.Create(8, LFields);
  try
    SetLength(LBuffer, 8);
    // the error of the nested structure (an unknown field) is printed and the outer one goes on
    FFiles.Add('botfiles/n.c', '{ sub { x 5 } after 6 }');
    LSource := TBotChatSource.Open(FImport, FFiles, 'n.c');
    try
      Assert.IsTrue(TBotStructReader.ReadStructure(LSource, LOuter, LBuffer));
    finally
      LSource.Free;
    end;
    Assert.AreEqual(5, IntegerAt(LBuffer, 0));
    Assert.AreEqual(6, IntegerAt(LBuffer, 4));
    FFiles.Add('botfiles/n.c', '{ sub { y 5 } after 6 }');
    LSource := TBotChatSource.Open(FImport, FFiles, 'n.c');
    try
      TBotStructReader.ReadStructure(LSource, LOuter, LBuffer);
    finally
      LSource.Free;
    end;
    Assert.Contains(Printed, 'unknown structure field y');
  finally
    LOuter.Free;
    LSub.Free;
  end;
end;

procedure TTestBotStruct.DovrebbeAlzareUnErroreSeIlCampoStaFuoriDalBuffer;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 10);
  Assert.WillRaise(
    procedure
    begin
      Read('{ char 1 }', LBuffer);
    end,
    EBotAiException);
end;

procedure TTestBotStruct.DovrebbeScrivereLaStrutturaComeIlFileDiConfigurazione;
var
  LBuffer: TBytes;
  LText: string;
begin
  SetLength(LBuffer, TEST_SIZE);
  Read('{ number 25 real 1.5 text "hi" array {1, 2, 3} char 65 }', LBuffer);
  LText := string(TBotStructWriter.WriteStructure(FDefinition, LBuffer));
  Assert.AreEqual('{'#13#10#9'number'#9'25'#13#10#9'real'#9'1.5'#13#10#9'text'#9'"hi"'#13#10 +
    #9'array'#9'{1,2,3}'#13#10#9'char'#9'65'#13#10'}'#13#10, LText);
end;

procedure TTestBotStruct.DovrebbeAlzareUnErroreSeScriveUnCampoFuoriDalBuffer;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 3);
  Assert.WillRaise(
    procedure
    begin
      TBotStructWriter.WriteStructure(FDefinition, LBuffer);
    end,
    EBotAiException);
  SetLength(LBuffer, 6);
  Assert.WillRaise(
    procedure
    begin
      TBotStructWriter.WriteStructure(FDefinition, LBuffer);
    end,
    EBotAiException);
  SetLength(LBuffer, 20);
  Assert.WillRaise(
    procedure
    begin
      TBotStructWriter.WriteStructure(FDefinition, LBuffer);
    end,
    EBotAiException);
  SetLength(LBuffer, 90);
  Assert.WillRaise(
    procedure
    begin
      TBotStructWriter.WriteStructure(FDefinition, LBuffer);
    end,
    EBotAiException);
  SetLength(LBuffer, 100);
  Assert.WillRaise(
    procedure
    begin
      TBotStructWriter.WriteStructure(FDefinition, LBuffer);
    end,
    EBotAiException);
end;

procedure TTestBotStruct.DovrebbeScrivereUnRealeSenzaZeriFinali(const AValue: string; const AExpected: string);
begin
  Assert.AreEqual(AExpected, string(TBotStructWriter.WriteFloat(StrToFloat(AValue, TFormatSettings.Invariant))));
end;

procedure TTestBotStruct.DovrebbeScrivereMenoZeroPerUnNegativoCheArrotondaAZero;
begin
  Assert.AreEqual('-0', string(TBotStructWriter.WriteFloat(-0.0000001)));
  Assert.AreEqual('-0.000000', string(TBotCFormat.Fixed6(-0.0000001)));
end;

procedure TTestBotStruct.DovrebbeScrivereLeTabulazioni;
begin
  Assert.AreEqual(#9#9#9, string(TBotStructWriter.WriteIndent(3)));
  Assert.AreEqual('', string(TBotStructWriter.WriteIndent(0)));
end;

end.
