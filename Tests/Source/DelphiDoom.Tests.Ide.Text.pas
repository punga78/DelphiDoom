{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeText                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Text;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Text;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeText = class(TObject)
  public
    [Test]
    procedure DovrebbeTagliareAlPrimoSeparatoreEPulireLeDueMeta;
    [Test]
    procedure DovrebbeLasciareLaRigaIntatteSenzaSeparatore;
    [Test]
    procedure DovrebbeDareSecondaMetaVuotaSeIlSeparatoreEInFondo;
    [Test]
    procedure DovrebbeTagliareSoloAlPrimoSeparatore;
    [Test]
    procedure DovrebbeSaltareUnSoloCarattereDopoUnSeparatoreLungo;
    [Test]
    procedure DovrebbeDareLaPrimaEL2aParola;
  end;

implementation

{ TTestIdeText }

procedure TTestIdeText.DovrebbeTagliareAlPrimoSeparatoreEPulireLeDueMeta;
var
  LFirst, LSecond: string;
begin
  TIdeText.SplitPair('  game  |  doom  ', '|', LFirst, LSecond);
  Assert.AreEqual('game', LFirst);
  Assert.AreEqual('doom', LSecond);
end;

procedure TTestIdeText.DovrebbeLasciareLaRigaIntatteSenzaSeparatore;
var
  LFirst, LSecond: string;
begin
  TIdeText.SplitPair('  no separator  ', '|', LFirst, LSecond);
  Assert.AreEqual('  no separator  ', LFirst);
  Assert.AreEqual('', LSecond);
end;

procedure TTestIdeText.DovrebbeDareSecondaMetaVuotaSeIlSeparatoreEInFondo;
var
  LFirst, LSecond: string;
begin
  TIdeText.SplitPair('name=', '=', LFirst, LSecond);
  Assert.AreEqual('name', LFirst);
  Assert.AreEqual('', LSecond);
end;

procedure TTestIdeText.DovrebbeTagliareSoloAlPrimoSeparatore;
var
  LFirst, LSecond: string;
begin
  TIdeText.SplitPair('a=b=c', '=', LFirst, LSecond);
  Assert.AreEqual('a', LFirst);
  Assert.AreEqual('b=c', LSecond);
end;

procedure TTestIdeText.DovrebbeSaltareUnSoloCarattereDopoUnSeparatoreLungo;
var
  LFirst, LSecond: string;
begin
  // as the old splitstring did: one character after the start of the separator
  TIdeText.SplitPair('left::right', '::', LFirst, LSecond);
  Assert.AreEqual('left', LFirst);
  Assert.AreEqual(':right', LSecond);
end;

procedure TTestIdeText.DovrebbeDareLaPrimaEL2aParola;
begin
  Assert.AreEqual('function', TIdeText.FirstWord('function Name(a: Integer)', ' '));
  Assert.AreEqual('Name(a: Integer)', TIdeText.SecondWord('function Name(a: Integer)', ' '));
end;

end.
