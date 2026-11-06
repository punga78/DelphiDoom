{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - FLATINFO             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.FlatInfoParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.TextureDefs.Types,
  DelphiDoom.Tests.TextureDefs.Fakes;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsFlatInfoParser = class(TObject)
  private
    FLog: TFakeLog;
    FLogIntf: ILog;
    function Parse(const AText: string; const AFlats: TArray<string>): TArray<TTextureDefsFlatSize>;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestGivesTheSizeOfAFlat;
    [Test]
    procedure TestGivesTheIndexAndTheNameOfTheFlat;
    [Test]
    procedure TestIgnoresTheCaseOfTheWords;
    [Test]
    procedure TestIgnoresComments;
    [Test]
    procedure TestAFlatNamedTwiceAppearsTwice;
    [Test]
    procedure TestUsesTheLastFlatWithTheName;
    [Test]
    procedure TestAnUnknownSizeIsSixtyFour;
    [Test]
    procedure TestAnUnknownFlatIsAWarning;
    [Test]
    procedure TestAfterAnUnknownFlatTheNextWordsAreUnknownTokens;
    [Test]
    procedure TestAnUnknownTokenIsAWarning;
    [Test]
    procedure TestAFlatWithoutSizeGivesTheWordBack;
    [Test]
    procedure TestEmptyTextGivesNothing;
    [Test]
    procedure TestWorksWithoutLog;
    [Test]
    procedure TestTwoParsesDoNotShareState;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Factory, DelphiDoom.TextureDefs.Intf;

{ TTestTextureDefsFlatInfoParser }

procedure TTestTextureDefsFlatInfoParser.Setup;
begin
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
end;

function TTestTextureDefsFlatInfoParser.Parse(const AText: string;
  const AFlats: TArray<string>): TArray<TTextureDefsFlatSize>;
begin
  Result := TTextureDefsFactory.CreateFlatInfoParser(FLogIntf).Parse(AText,
    TFakeFlatCatalog.Create(AFlats));
end;

procedure TTestTextureDefsFlatInfoParser.TestGivesTheSizeOfAFlat;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F1 SIZE 256', ['F1']);
  Assert.AreEqual(1, Length(LSizes), 'dovrebbe dare una voce');
  Assert.AreEqual(FLAT_SIZE_256, LSizes[0].SizeCode, 'dovrebbe dare il codice 256');
end;

procedure TTestTextureDefsFlatInfoParser.TestGivesTheIndexAndTheNameOfTheFlat;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F2 SIZE 128', ['F1', 'F2']);
  Assert.AreEqual(1, LSizes[0].FlatIndex, 'dovrebbe dare l''indice');
  Assert.AreEqual('F2', LSizes[0].FlatName, 'dovrebbe dare il nome');
end;

procedure TTestTextureDefsFlatInfoParser.TestIgnoresTheCaseOfTheWords;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('flat floor0_1 Size 512', ['FLOOR0_1']);
  Assert.AreEqual(1, Length(LSizes), 'dovrebbe ignorare le maiuscole');
  Assert.AreEqual(FLAT_SIZE_512, LSizes[0].SizeCode);
end;

procedure TTestTextureDefsFlatInfoParser.TestIgnoresComments;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('// niente'#13#10'FLAT F1 SIZE 128 // altro'#13#10, ['F1']);
  Assert.AreEqual(1, Length(LSizes), 'dovrebbe ignorare i commenti');
  Assert.AreEqual(0, FLog.Warnings.Count, 'non dovrebbe avvisare');
end;

procedure TTestTextureDefsFlatInfoParser.TestAFlatNamedTwiceAppearsTwice;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F1 SIZE 128 FLAT F1 SIZE 512', ['F1']);
  Assert.AreEqual(2, Length(LSizes), 'dovrebbe dare due voci');
  Assert.AreEqual(FLAT_SIZE_128, LSizes[0].SizeCode, 'dovrebbe tenere l''ordine del testo');
  Assert.AreEqual(FLAT_SIZE_512, LSizes[1].SizeCode);
end;

procedure TTestTextureDefsFlatInfoParser.TestUsesTheLastFlatWithTheName;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F1 SIZE 256', ['F1', 'F2', 'F1']);
  Assert.AreEqual(2, LSizes[0].FlatIndex, 'dovrebbe usare l''ultimo flat con il nome');
end;

procedure TTestTextureDefsFlatInfoParser.TestAnUnknownSizeIsSixtyFour;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F1 SIZE 100', ['F1']);
  Assert.AreEqual(FLAT_SIZE_64, LSizes[0].SizeCode, 'dovrebbe dare 64x64');
end;

procedure TTestTextureDefsFlatInfoParser.TestAnUnknownFlatIsAWarning;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT NOPE', ['F1']);
  Assert.AreEqual(0, Length(LSizes), 'non dovrebbe dare voci');
  Assert.IsTrue(FLog.Warnings.Contains('R_ParseFlatInfo(): Unknown flat "NOPE"'#13#10),
    'dovrebbe avvisare del flat');
end;

procedure TTestTextureDefsFlatInfoParser.TestAfterAnUnknownFlatTheNextWordsAreUnknownTokens;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT NOPE SIZE 128', ['F1']);
  Assert.AreEqual(0, Length(LSizes));
  Assert.IsTrue(FLog.Warnings.Contains('R_ParseFlatInfo(): Unknown token "SIZE"'#13#10),
    'dovrebbe leggere SIZE come parola sconosciuta');
  Assert.IsTrue(FLog.Warnings.Contains('R_ParseFlatInfo(): Unknown token "128"'#13#10),
    'dovrebbe leggere 128 come parola sconosciuta');
end;

procedure TTestTextureDefsFlatInfoParser.TestAnUnknownTokenIsAWarning;
begin
  Parse('WHAT', ['F1']);
  Assert.IsTrue(FLog.Warnings.Contains('R_ParseFlatInfo(): Unknown token "WHAT"'#13#10),
    'dovrebbe avvisare della parola');
end;

procedure TTestTextureDefsFlatInfoParser.TestAFlatWithoutSizeGivesTheWordBack;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := Parse('FLAT F1 FLAT F2 SIZE 512', ['F1', 'F2']);
  Assert.AreEqual(1, Length(LSizes), 'dovrebbe dare solo la voce con SIZE');
  Assert.AreEqual(1, LSizes[0].FlatIndex, 'dovrebbe rileggere FLAT');
  Assert.AreEqual(0, FLog.Warnings.Count, 'non dovrebbe avvisare');
end;

procedure TTestTextureDefsFlatInfoParser.TestEmptyTextGivesNothing;
begin
  Assert.AreEqual(0, Length(Parse('', ['F1'])), 'dovrebbe dare zero voci');
end;

procedure TTestTextureDefsFlatInfoParser.TestWorksWithoutLog;
var
  LSizes: TArray<TTextureDefsFlatSize>;
begin
  LSizes := TTextureDefsFactory.CreateFlatInfoParser(nil).Parse('FLAT NOPE FLAT F1 SIZE 128 X',
    TFakeFlatCatalog.Create(['F1']));
  Assert.AreEqual(1, Length(LSizes), 'dovrebbe funzionare senza log');
end;

procedure TTestTextureDefsFlatInfoParser.TestTwoParsesDoNotShareState;
var
  LParser: ITextureDefsFlatInfoParser;
  LCatalog: ITextureDefsFlatCatalog;
begin
  LParser := TTextureDefsFactory.CreateFlatInfoParser(FLogIntf);
  LCatalog := TFakeFlatCatalog.Create(['F1']);
  Assert.AreEqual(1, Length(LParser.Parse('FLAT F1 SIZE 128', LCatalog)));
  Assert.AreEqual(1, Length(LParser.Parse('FLAT F1 SIZE 256', LCatalog)), 'dovrebbe ripartire da zero');
end;

end.
