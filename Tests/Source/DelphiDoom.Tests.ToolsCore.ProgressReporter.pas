{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TProgressReporter                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.ProgressReporter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf, DelphiDoom.Tests.ToolsCore.Fakes;

type
  [TestFixture]
  [Category('toolscore')]
  TTestToolsProgressReporter = class(TObject)
  strict private
    FObserver: TFakeProgressObserver;
    FObserverIntf: IProgressObserver;
    FReporter: IProgressReporter;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbePartireDaZero;
    [Test]
    procedure DovrebbeDireLaPercentualeAdOgniPasso;
    [Test]
    procedure DovrebbeDireSoloLeVariazioni;
    [Test]
    procedure DovrebbeFinireACento;
    [Test]
    procedure DovrebbeNonSuperareCento;
    [Test]
    procedure DovrebbeNonAvereUnaPercentualeSenzaLunghezza;
    [Test]
    procedure DovrebbeRicordareLAnnullamentoEAzzerarloAlNuovoLavoro;
    [Test]
    procedure DovrebbeFunzionareSenzaOsservatore;
    [Test]
    procedure DovrebbeRifiutareUnTotaleNegativo;
  end;

implementation

uses
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.Types;

{ TTestToolsProgressReporter }

procedure TTestToolsProgressReporter.Setup;
begin
  FObserver := TFakeProgressObserver.Create;
  FObserverIntf := FObserver;
  FReporter := TToolsFactory.CreateProgressReporter(FObserverIntf);
end;

procedure TTestToolsProgressReporter.DovrebbePartireDaZero;
begin
  FReporter.Start('lavoro', 10);
  Assert.AreEqual(0, FReporter.Percent);
  Assert.AreEqual(1, FObserver.Percents.Count);
  Assert.AreEqual('lavoro', FObserver.LastText);
end;

procedure TTestToolsProgressReporter.DovrebbeDireLaPercentualeAdOgniPasso;
begin
  FReporter.Start('lavoro', 4);
  FReporter.Advance(1);
  Assert.AreEqual(25, FReporter.Percent);
  FReporter.Advance(2);
  Assert.AreEqual(75, FReporter.Percent);
end;

procedure TTestToolsProgressReporter.DovrebbeDireSoloLeVariazioni;
begin
  FReporter.Start('lavoro', 1000);
  FReporter.Advance(1);
  FReporter.Advance(1);
  // 0 at the start, nothing while it still rounds to 0
  Assert.AreEqual(1, FObserver.Percents.Count);
end;

procedure TTestToolsProgressReporter.DovrebbeFinireACento;
begin
  FReporter.Start('lavoro', 10);
  FReporter.Finish;
  Assert.AreEqual(100, FReporter.Percent);
  Assert.AreEqual(100, FObserver.Percents[FObserver.Percents.Count - 1]);
end;

procedure TTestToolsProgressReporter.DovrebbeNonSuperareCento;
begin
  FReporter.Start('lavoro', 2);
  FReporter.Advance(5);
  Assert.AreEqual(100, FReporter.Percent);
end;

procedure TTestToolsProgressReporter.DovrebbeNonAvereUnaPercentualeSenzaLunghezza;
begin
  FReporter.Start('lavoro', 0);
  FReporter.Advance(3);
  Assert.AreEqual(0, FReporter.Percent);
  FReporter.Finish;
  Assert.AreEqual(100, FReporter.Percent);
end;

procedure TTestToolsProgressReporter.DovrebbeRicordareLAnnullamentoEAzzerarloAlNuovoLavoro;
begin
  Assert.IsFalse(FReporter.IsCancelled);
  FReporter.Cancel;
  Assert.IsTrue(FReporter.IsCancelled);
  FReporter.Start('altro', 3);
  Assert.IsFalse(FReporter.IsCancelled);
end;

procedure TTestToolsProgressReporter.DovrebbeFunzionareSenzaOsservatore;
var
  LReporter: IProgressReporter;
begin
  LReporter := TToolsFactory.CreateProgressReporter(nil);
  LReporter.Start('x', 2);
  LReporter.Advance(1);
  Assert.AreEqual(50, LReporter.Percent);
end;

procedure TTestToolsProgressReporter.DovrebbeRifiutareUnTotaleNegativo;
begin
  Assert.WillRaise(
    procedure
    begin
      FReporter.Start('x', -1);
    end, EToolsException);
end;

end.
