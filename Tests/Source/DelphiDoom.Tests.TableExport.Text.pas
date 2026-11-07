{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the text functions           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.Text;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Text;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportText = class(TObject)
  public
    [Test]
    procedure TestDovrebbeMaiuscolareLeInizialiDelleParole;
    [Test]
    procedure TestDovrebbeDareVuotoPerUnTestoVuoto;
    [Test]
    procedure TestDovrebbeScrivereUnFissoConQuattroDecimali;
    [Test]
    procedure TestDovrebbeScrivereUnFissoNegativo;
    [Test]
    procedure TestDovrebbeElencareISoloIBitAccesiNelOrdineDeiBit;
    [Test]
    procedure TestDovrebbeDareVuotoSenzaBitAccesi;
    [Test]
    procedure TestDovrebbeTrattareIlBitPiuAltoDi32;
    [Test]
    procedure TestDovrebbeTogliereICRESostituireLInvioConBackslashN;
    [Test]
    procedure TestDovrebbeRaddoppiareGliApici;
    [Test]
    procedure TestDovrebbeTagliareIBlankAgliEstremi;
    [Test]
    procedure TestDovrebbeDividereAlPrimoUguale;
    [Test]
    procedure TestDovrebbeDareLaChiaveSenzaUguale;
    [Test]
    procedure TestDovrebbeRiconoscereIlPrefisso;
  end;

implementation

uses
  System.SysUtils;

{ TTestTableExportText }

procedure TTestTableExportText.TestDovrebbeMaiuscolareLeInizialiDelleParole;
begin
  Assert.AreEqual('Initial Frame', TExportText.Capitalize('INITIAL FRAME'));
  Assert.AreEqual('Id #', TExportText.Capitalize('ID #'));
  Assert.AreEqual('Flags_ex', TExportText.Capitalize('FLAGS_EX'));
end;

procedure TTestTableExportText.TestDovrebbeDareVuotoPerUnTestoVuoto;
begin
  Assert.AreEqual('', TExportText.Capitalize(''));
end;

procedure TTestTableExportText.TestDovrebbeScrivereUnFissoConQuattroDecimali;
begin
  Assert.AreEqual('1.0000', TExportText.FixedText(65536));
  Assert.AreEqual('0.5000', TExportText.FixedText(32768));
  Assert.AreEqual('2.2500', TExportText.FixedText(147456));
end;

procedure TTestTableExportText.TestDovrebbeScrivereUnFissoNegativo;
begin
  Assert.AreEqual('-1.5000', TExportText.FixedText(-98304));
end;

procedure TTestTableExportText.TestDovrebbeElencareISoloIBitAccesiNelOrdineDeiBit;
begin
  Assert.AreEqual('A, C', TExportText.FlagList(5, ['A', 'B', 'C'], ', '));
  Assert.AreEqual('A or B or C', TExportText.FlagList(7, ['A', 'B', 'C'], ' or '));
end;

procedure TTestTableExportText.TestDovrebbeDareVuotoSenzaBitAccesi;
begin
  Assert.AreEqual('', TExportText.FlagList(0, ['A', 'B'], ', '));
  Assert.AreEqual('', TExportText.FlagList(8, ['A', 'B', 'C'], ', '));
end;

procedure TTestTableExportText.TestDovrebbeTrattareIlBitPiuAltoDi32;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LNames, 32);
  for LIndex := 0 to 31 do
    LNames[LIndex] := 'F' + IntToStr(LIndex);
  Assert.AreEqual('F31', TExportText.FlagList(Integer($80000000), LNames, ','));
end;

procedure TTestTableExportText.TestDovrebbeTogliereICRESostituireLInvioConBackslashN;
begin
  Assert.AreEqual('one\ntwo', TExportText.ToCString('one'#13#10'two'));
  Assert.AreEqual('', TExportText.ToCString(''));
end;

procedure TTestTableExportText.TestDovrebbeRaddoppiareGliApici;
begin
  Assert.AreEqual('it''''s', TExportText.PascalEscape('it''s'));
end;

procedure TTestTableExportText.TestDovrebbeTagliareIBlankAgliEstremi;
begin
  Assert.AreEqual('a b', TExportText.Trim('  a b '#9));
  Assert.AreEqual('', TExportText.Trim('   '));
end;

procedure TTestTableExportText.TestDovrebbeDividereAlPrimoUguale;
var
  LKey: string;
  LValue: string;
begin
  TExportText.Split(' Key = a = b ', '=', LKey, LValue);
  Assert.AreEqual('Key', LKey);
  Assert.AreEqual('a = b', LValue);
end;

procedure TTestTableExportText.TestDovrebbeDareLaChiaveSenzaUguale;
var
  LKey: string;
  LValue: string;
begin
  TExportText.Split('Key', '=', LKey, LValue);
  Assert.AreEqual('Key', LKey);
  Assert.AreEqual('', LValue);
end;

procedure TTestTableExportText.TestDovrebbeRiconoscereIlPrefisso;
begin
  Assert.IsTrue(TExportText.StartsWith('THING ', 'THING 3'));
  Assert.IsFalse(TExportText.StartsWith('THING ', 'THIN'));
  Assert.IsFalse(TExportText.StartsWith('THING ', 'thing 3'));
end;

end.
