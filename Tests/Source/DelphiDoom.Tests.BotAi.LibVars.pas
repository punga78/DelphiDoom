{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the library variables of the bots (DUnitX)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.LibVars;

interface

uses
  DUnitX.TestFramework, DelphiDoom.BotAi.LibVars.Table;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotLibVarTable = class
  strict private
    FTable: TBotLibVarTable;
    FTableRef: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('intero', '42,42')]
    [TestCase('decimale', '12.5,12.5')]
    [TestCase('punto iniziale', '.5,0.5')]
    [TestCase('zeri iniziali', '007,7')]
    [TestCase('vuoto', ',0')]
    [TestCase('segno meno non ammesso', '-1,0')]
    [TestCase('esponente non ammesso', '1e3,0')]
    [TestCase('lettere', 'abc,0')]
    [TestCase('due punti', '1.5.2,0')]
    procedure DovrebbeConvertireIlTestoInUnNumeroComeLibVarStringValue(const AText: string; const AExpected: string);
    [Test]
    procedure DovrebbeConvertireIlCarattereDopoIlPuntoSenzaControllarlo;
    [Test]
    procedure DovrebbeDareZeroEIlTestoVuotoPerUnaVariabileCheNonEsiste;
    [Test]
    procedure DovrebbeCreareLaVariabileConIlValorePredefinitoSoloSeManca;
    [Test]
    procedure DovrebbeConfrontareINomiSenzaMaiuscole;
    [Test]
    procedure DovrebbeSegnareLaVariabileComeModificataEPoiNo;
    [Test]
    procedure DovrebbeNonSegnareModificataUnaVariabileCheNonEsiste;
    [Test]
    procedure DovrebbeCambiareIlValoreConSetText;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Text.CFormat;

{ TTestBotLibVarTable }

procedure TTestBotLibVarTable.Setup;
begin
  FTable := TBotLibVarTable.Create;
  FTableRef := FTable;
end;

procedure TTestBotLibVarTable.TearDown;
begin
  FTableRef := nil;
end;

procedure TTestBotLibVarTable.DovrebbeConvertireIlTestoInUnNumeroComeLibVarStringValue(const AText: string;
  const AExpected: string);
begin
  Assert.AreEqual(StrToFloat(AExpected, TFormatSettings.Invariant), Double(TBotLibVarTable.StringValue(AnsiString(AText))), 0.0001);
end;

procedure TTestBotLibVarTable.DovrebbeConvertireIlCarattereDopoIlPuntoSenzaControllarlo;
begin
  // 'x' - '0' = 72, divided by 10
  Assert.AreEqual(Double(8.2), Double(TBotLibVarTable.StringValue('1.x')), 0.0001);
  // at the end of the text the converted character is the terminator: 5 + (0 - 48) / 10
  Assert.AreEqual(Double(0.2), Double(TBotLibVarTable.StringValue('5.')), 0.0001);
end;

procedure TTestBotLibVarTable.DovrebbeDareZeroEIlTestoVuotoPerUnaVariabileCheNonEsiste;
begin
  Assert.AreEqual(Double(0.0), Double(FTable.GetValue('nothing')));
  Assert.AreEqual('', string(FTable.GetString('nothing')));
  Assert.IsFalse(FTable.Changed('nothing'));
end;

procedure TTestBotLibVarTable.DovrebbeCreareLaVariabileConIlValorePredefinitoSoloSeManca;
begin
  Assert.AreEqual(Double(7.25), Double(FTable.GetValueOrCreate('v', '7.25')), 0.0001);
  Assert.AreEqual(Double(7.25), Double(FTable.GetValueOrCreate('v', '9')), 0.0001);
  Assert.AreEqual('hello', string(FTable.GetStringOrCreate('s', 'hello')));
  Assert.AreEqual('hello', string(FTable.GetStringOrCreate('s', 'bye')));
  Assert.IsTrue(FTable.Changed('v'));
end;

procedure TTestBotLibVarTable.DovrebbeConfrontareINomiSenzaMaiuscole;
begin
  FTable.SetText('Name', '3');
  Assert.AreEqual(Double(3.0), Double(FTable.GetValue('NAME')));
  Assert.AreEqual('3', string(FTable.GetString('name')));
end;

procedure TTestBotLibVarTable.DovrebbeSegnareLaVariabileComeModificataEPoiNo;
begin
  FTable.SetText('a', '5');
  Assert.IsTrue(FTable.Changed('a'));
  FTable.SetNotModified('a');
  Assert.IsFalse(FTable.Changed('a'));
  FTable.SetText('a', '6');
  Assert.IsTrue(FTable.Changed('a'));
end;

procedure TTestBotLibVarTable.DovrebbeNonSegnareModificataUnaVariabileCheNonEsiste;
begin
  FTable.SetNotModified('nothing');
  Assert.IsFalse(FTable.Changed('nothing'));
end;

procedure TTestBotLibVarTable.DovrebbeCambiareIlValoreConSetText;
begin
  FTable.SetText('a', '5');
  FTable.SetText('a', '6.5');
  Assert.AreEqual(Double(6.5), Double(FTable.GetValue('a')), 0.0001);
end;

end.
