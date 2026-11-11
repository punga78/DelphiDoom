{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of Xcom32 - the arguments of the export                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.ExportArguments;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomExportArguments = class(TObject)
  public
    [Test]
    procedure DovrebbeScegliereIlGiocoSenzaArgomenti;
    [Test]
    procedure DovrebbeScegliereIlGiocoConISoliArgomentiDelGioco;
    [Test]
    [TestCase('pck', '-pck')]
    [TestCase('dat', '-dat')]
    [TestCase('scr', '-scr')]
    [TestCase('map', '-map')]
    [TestCase('maiuscole', '-PCK')]
    procedure DovrebbeScegliereLEsportazioneSeDiceCosaEsportare(const AName: string);
    [Test]
    procedure DovrebbeLeggereLaRigaDiComandoDegliScript;
    [Test]
    procedure DovrebbeDareIValoriPredefiniti;
    [Test]
    procedure DovrebbeRipetereDataETrattareGameAlloStessoModo;
    [Test]
    procedure DovrebbeLeggereUnaMappaConLeSueRotte;
    [Test]
    procedure DovrebbeDareFalsoConUnArgomentoDelGioco;
    [Test]
    procedure DovrebbeDareFalsoSenzaNienteDaEsportare;
    [Test]
    procedure DovrebbeSollevareSeMancaIlValore;
  end;

implementation

uses
  DelphiDoom.Xcom.ExportArguments;

{ TTestXcomExportArguments }

procedure TTestXcomExportArguments.DovrebbeScegliereIlGiocoSenzaArgomenti;
begin
  Assert.IsFalse(TXcomExportArguments.IsExport([]));
end;

procedure TTestXcomExportArguments.DovrebbeScegliereIlGiocoConISoliArgomentiDelGioco;
begin
  // -data alone does not choose the export: in the game it is the folder with common\ and standard\
  Assert.IsFalse(TXcomExportArguments.IsExport(['-data', 'C:\openxcom', '-game', 'C:\TFTD', '-user', 'C:\user',
    '-shot', 'menu.png', '-script', 'wait:5000', '-seed', '1', '-quitafter', '5000', '-hold']));
end;

procedure TTestXcomExportArguments.DovrebbeScegliereLEsportazioneSeDiceCosaEsportare(const AName: string);
begin
  Assert.IsTrue(TXcomExportArguments.IsExport(['-data', 'C:\TFTD', AName, 'FILE']));
end;

procedure TTestXcomExportArguments.DovrebbeLeggereLaRigaDiComandoDegliScript;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsTrue(TXcomExportArguments.TryParse(['-data', 'C:\TFTD', '-pal', '0', '-pck', 'TERRAIN\PORT01.PCK',
    '-png', 'x.png'], LArguments));
  Assert.AreEqual(xmPck, LArguments.Mode);
  Assert.AreEqual('TERRAIN\PORT01.PCK', LArguments.InputFile);
  Assert.AreEqual('x.png', LArguments.PngFile);
  Assert.AreEqual(0, LArguments.PaletteIndex);
  Assert.AreEqual<Integer>(1, Length(LArguments.Folders));
  Assert.AreEqual('C:\TFTD', LArguments.Folders[0]);
end;

procedure TTestXcomExportArguments.DovrebbeDareIValoriPredefiniti;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsTrue(TXcomExportArguments.TryParse(['-scr', 'GEOGRAPH\BACK01.SCR'], LArguments));
  Assert.AreEqual(xmScr, LArguments.Mode);
  Assert.AreEqual('xcom.png', LArguments.PngFile);
  Assert.AreEqual(16, LArguments.Columns);
  Assert.AreEqual(0, LArguments.Width);
  Assert.AreEqual(0, LArguments.Height);
  Assert.AreEqual(0, LArguments.Layer);
  Assert.AreEqual<Integer>(0, Length(LArguments.Folders));
end;

procedure TTestXcomExportArguments.DovrebbeRipetereDataETrattareGameAlloStessoModo;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsTrue(TXcomExportArguments.TryParse(['-data', 'A', '-game', 'B', '-DATA', 'C', '-dat', 'X.DAT', '-w', '8',
    '-h', '9', '-columns', '4', '-tab', 'X.TAB'], LArguments));
  Assert.AreEqual<Integer>(3, Length(LArguments.Folders));
  Assert.AreEqual('A', LArguments.Folders[0]);
  Assert.AreEqual('B', LArguments.Folders[1]);
  Assert.AreEqual('C', LArguments.Folders[2]);
  Assert.AreEqual(xmDat, LArguments.Mode);
  Assert.AreEqual(8, LArguments.Width);
  Assert.AreEqual(9, LArguments.Height);
  Assert.AreEqual(4, LArguments.Columns);
  Assert.AreEqual('X.TAB', LArguments.TabFile);
end;

procedure TTestXcomExportArguments.DovrebbeLeggereUnaMappaConLeSueRotte;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsTrue(TXcomExportArguments.TryParse(['-pal', '4', '-map', 'MAPS\A.MAP', '-rmp', 'ROUTES\A.RMP', '-z', '2'],
    LArguments));
  Assert.AreEqual(xmMap, LArguments.Mode);
  Assert.AreEqual('MAPS\A.MAP', LArguments.InputFile);
  Assert.AreEqual('ROUTES\A.RMP', LArguments.RouteFile);
  Assert.AreEqual(2, LArguments.Layer);
  Assert.AreEqual(4, LArguments.PaletteIndex);
end;

procedure TTestXcomExportArguments.DovrebbeDareFalsoConUnArgomentoDelGioco;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsFalse(TXcomExportArguments.TryParse(['-pck', 'A.PCK', '-user', 'C:\user'], LArguments));
end;

procedure TTestXcomExportArguments.DovrebbeDareFalsoSenzaNienteDaEsportare;
var
  LArguments: TXcomExportArguments;
begin
  Assert.IsFalse(TXcomExportArguments.TryParse(['-data', 'C:\TFTD', '-png', 'x.png'], LArguments));
end;

procedure TTestXcomExportArguments.DovrebbeSollevareSeMancaIlValore;
begin
  Assert.WillRaise(
    procedure
    var
      LArguments: TXcomExportArguments;
    begin
      TXcomExportArguments.TryParse(['-data', 'C:\TFTD', '-pck'], LArguments);
    end, EXcomExportArgumentException);
end;

end.
