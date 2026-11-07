{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the factory                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Factory;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeDareVistaENavigatoreSulloStessoStato;
    [Test]
    procedure DovrebbeDareFinestreIndipendenti;
    [Test]
    procedure DovrebbeDareSegniIndipendenti;
  end;

implementation

uses
  DelphiDoom.Automap.Types, DelphiDoom.Automap.Intf, DelphiDoom.Automap.Factory;

{ TTestAutomapFactory }

procedure TTestAutomapFactory.DovrebbeDareVistaENavigatoreSulloStessoStato;
var
  LView: IAutomapView;
  LNavigator: IAutomapNavigator;
begin
  TAutomapFactory.CreateView(LView, LNavigator);
  LView.SetFrame(0, 0, 200, 100);
  LNavigator.StartWindow(False, 0, 0);
  Assert.AreEqual(LView.FrameToMap(200), LView.Window.MapWidth);
  Assert.IsTrue(LView.Window.MapWidth > 0);
end;

procedure TTestAutomapFactory.DovrebbeDareFinestreIndipendenti;
var
  LFirst: IAutomapView;
  LSecond: IAutomapView;
  LFirstNavigator: IAutomapNavigator;
  LSecondNavigator: IAutomapNavigator;
begin
  TAutomapFactory.CreateView(LFirst, LFirstNavigator);
  TAutomapFactory.CreateView(LSecond, LSecondNavigator);
  LFirst.SetFrame(0, 0, 200, 100);
  LSecond.SetFrame(0, 0, 640, 480);
  LFirstNavigator.FollowPlayer := False;
  Assert.AreEqual(200, LFirst.Window.FrameWidth);
  Assert.AreEqual(640, LSecond.Window.FrameWidth);
  Assert.IsTrue(LSecondNavigator.FollowPlayer);
end;

procedure TTestAutomapFactory.DovrebbeDareSegniIndipendenti;
var
  LFirst: IAutomapMarks;
  LSecond: IAutomapMarks;
begin
  LFirst := TAutomapFactory.CreateMarks;
  LSecond := TAutomapFactory.CreateMarks;
  LFirst.Add(1, 2);
  Assert.IsTrue(LFirst.IsUsed(0));
  Assert.IsFalse(LSecond.IsUsed(0));
end;

end.
