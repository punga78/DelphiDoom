{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the marks on the map             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Marks;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Automap.Intf;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapMarks = class(TObject)
  private
    FMarks: IAutomapMarks;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbePartireSenzaSegni;
    [Test]
    procedure DovrebbeMettereUnSegnoEAvanzare;
    [Test]
    procedure DovrebbeSostituireIlPiuVecchioQuandoSonoTuttiUsati;
    [Test]
    procedure DovrebbeCancellareTuttiISegni;
    [Test]
    procedure DovrebbeRipartireDaZeroDopoLaCancellazione;
    [Test]
    procedure DovrebbeSollevareSeIlSegnoNonEsiste;
  end;

implementation

uses
  DelphiDoom.Automap.Types, DelphiDoom.Automap.Factory;

{ TTestAutomapMarks }

procedure TTestAutomapMarks.Setup;
begin
  FMarks := TAutomapFactory.CreateMarks;
end;

procedure TTestAutomapMarks.DovrebbePartireSenzaSegni;
var
  LIndex: Integer;
begin
  Assert.AreEqual(AUTOMAP_MAX_MARKS, FMarks.Count);
  Assert.AreEqual(0, FMarks.NextIndex);
  for LIndex := 0 to FMarks.Count - 1 do
    Assert.IsFalse(FMarks.IsUsed(LIndex));
end;

procedure TTestAutomapMarks.DovrebbeMettereUnSegnoEAvanzare;
begin
  FMarks.Add(1000, 2000);
  Assert.AreEqual(1, FMarks.NextIndex);
  Assert.IsTrue(FMarks.IsUsed(0));
  Assert.AreEqual(1000, FMarks.Point(0).X);
  Assert.AreEqual(2000, FMarks.Point(0).Y);
  Assert.IsFalse(FMarks.IsUsed(1));
end;

procedure TTestAutomapMarks.DovrebbeSostituireIlPiuVecchioQuandoSonoTuttiUsati;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AUTOMAP_MAX_MARKS do
    FMarks.Add(LIndex * 10, LIndex);
  // the eleventh mark went to the place of the first one
  Assert.AreEqual(1, FMarks.NextIndex);
  Assert.AreEqual(AUTOMAP_MAX_MARKS * 10, FMarks.Point(0).X);
  Assert.AreEqual(10, FMarks.Point(1).X);
end;

procedure TTestAutomapMarks.DovrebbeCancellareTuttiISegni;
var
  LIndex: Integer;
begin
  FMarks.Add(5, 5);
  FMarks.Add(6, 6);
  FMarks.Clear;
  for LIndex := 0 to FMarks.Count - 1 do
    Assert.IsFalse(FMarks.IsUsed(LIndex));
end;

procedure TTestAutomapMarks.DovrebbeRipartireDaZeroDopoLaCancellazione;
begin
  FMarks.Add(5, 5);
  FMarks.Add(6, 6);
  FMarks.Clear;
  Assert.AreEqual(0, FMarks.NextIndex);
  FMarks.Add(7, 7);
  Assert.AreEqual(7, FMarks.Point(0).X);
end;

procedure TTestAutomapMarks.DovrebbeSollevareSeIlSegnoNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FMarks.Point(-1);
    end, EAutomapException);
  Assert.WillRaise(
    procedure
    begin
      FMarks.Point(AUTOMAP_MAX_MARKS);
    end, EAutomapException);
  Assert.WillRaise(
    procedure
    begin
      FMarks.IsUsed(AUTOMAP_MAX_MARKS);
    end, EAutomapException);
end;

end.
