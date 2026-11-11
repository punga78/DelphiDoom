{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of a line of the menu of the actions (ActionMenuItem)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.ActionMenuItem;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.ActionMenuItem,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>Opens the mouse events of the line to the tests</summary>
  TTestableActionMenuItem = class(TXcomActionMenuItem)
  public
    procedure Enter(AAction: TXcomAction);
    procedure Leave(AAction: TXcomAction);
  end;

  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomActionMenuItem = class
  strict private
    FWorld: TTestWorld;
    FItem: TTestableActionMenuItem;
    FAction: TXcomAction;
    function NewItem(AId: Integer; ATftd: Boolean): TTestableActionMenuItem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeStareQuarantaPixelSopraLaVocePrecedente;
    [Test]
    procedure DovrebbeNascereSenzaAzione;
    [Test]
    procedure DovrebbeTenereLAzioneEIlSuoCosto;
    [Test]
    procedure DovrebbeDisegnareLaCorniceAttornoAlFondo;
    [Test]
    procedure DovrebbeCambiareIlFondoColMouseSopraERimetterloQuandoEsce;
    [Test]
    procedure DovrebbeEvidenziareDiPiuInModoTftd;
  end;

implementation

const
  // inside the frame (8 pixels thick), above the texts (from row 13)
  INSIDE_X = 136;
  INSIDE_Y = 10;

procedure TTestableActionMenuItem.Enter(AAction: TXcomAction);
begin
  MouseIn(AAction);
end;

procedure TTestableActionMenuItem.Leave(AAction: TXcomAction);
begin
  MouseOut(AAction);
end;

function TTestXcomActionMenuItem.NewItem(AId: Integer; ATftd: Boolean): TTestableActionMenuItem;
var
  LElement: TXcomInterfaceElement;
begin
  LElement := Default(TXcomInterfaceElement);
  LElement.Color := 47;
  LElement.Color2 := 61;
  LElement.Border := 51;
  LElement.TftdMode := ATftd;
  Result := TTestableActionMenuItem.Create(AId, LElement, FWorld.Game.Resources.GetFont('FONT_BIG'),
    FWorld.Game.Resources.GetFont('FONT_SMALL'), FWorld.Game.Language, 0, 160);
  Result.SetPalette(FWorld.Game.Resources.GetPalette('PAL_BATTLESCAPE'), 0, 256);
end;

procedure TTestXcomActionMenuItem.Setup;
begin
  FWorld := TTestWorld.Create;
  FItem := NewItem(0, True);
  FAction := TXcomAction.Create(TXcomInputEvent.Make(ekMouseMotion), 1, 1, 0, 0);
end;

procedure TTestXcomActionMenuItem.TearDown;
begin
  FAction.Free;
  FItem.Free;
  FWorld.Free;
end;

procedure TTestXcomActionMenuItem.DovrebbeStareQuarantaPixelSopraLaVocePrecedente;
var
  LSecond: TTestableActionMenuItem;
begin
  LSecond := NewItem(2, True);
  try
    Assert.AreEqual(24, FItem.X);
    Assert.AreEqual(160, FItem.Y);
    Assert.AreEqual(272, FItem.Width);
    Assert.AreEqual(40, FItem.Height);
    Assert.AreEqual(24, LSecond.X);
    Assert.AreEqual(80, LSecond.Y);
  finally
    LSecond.Free;
  end;
end;

procedure TTestXcomActionMenuItem.DovrebbeNascereSenzaAzione;
begin
  Assert.AreEqual(BA_NONE, FItem.ActionType);
  Assert.AreEqual(0, FItem.TimeUnits);
  Assert.IsFalse(FItem.Highlighted);
end;

procedure TTestXcomActionMenuItem.DovrebbeTenereLAzioneEIlSuoCosto;
begin
  FItem.Redraw := False;
  FItem.SetAction(BA_SNAPSHOT, 'SNAP SHOT', 'ACC>21%', 'TU>20', 20);
  Assert.AreEqual(BA_SNAPSHOT, FItem.ActionType);
  Assert.AreEqual(20, FItem.TimeUnits);
  Assert.IsTrue(FItem.Redraw, 'the line must be drawn again');
end;

procedure TTestXcomActionMenuItem.DovrebbeDisegnareLaCorniceAttornoAlFondo;
begin
  FItem.SetAction(BA_THROW, 'THROW', '', '', 12);
  FItem.Draw;
  Assert.AreNotEqual(0, Integer(FItem.GetPixel(0, 20)), 'the border');
  Assert.AreNotEqual(0, Integer(FItem.GetPixel(INSIDE_X, INSIDE_Y)), 'the background');
  Assert.AreNotEqual(Integer(FItem.GetPixel(0, 20)), Integer(FItem.GetPixel(INSIDE_X, INSIDE_Y)));
end;

procedure TTestXcomActionMenuItem.DovrebbeCambiareIlFondoColMouseSopraERimetterloQuandoEsce;
var
  LNormal, LOver: Integer;
begin
  FItem.SetAction(BA_THROW, 'THROW', '', '', 12);
  FItem.Draw;
  LNormal := FItem.GetPixel(INSIDE_X, INSIDE_Y);
  FItem.Enter(FAction);
  LOver := FItem.GetPixel(INSIDE_X, INSIDE_Y);
  Assert.IsTrue(FItem.Highlighted);
  Assert.AreNotEqual(LNormal, LOver);
  FItem.Leave(FAction);
  Assert.IsFalse(FItem.Highlighted);
  Assert.AreEqual(LNormal, Integer(FItem.GetPixel(INSIDE_X, INSIDE_Y)));
end;

procedure TTestXcomActionMenuItem.DovrebbeEvidenziareDiPiuInModoTftd;
var
  LClassic: TTestableActionMenuItem;
  LNormal, LTftdStep, LClassicStep: Integer;
begin
  FItem.Draw;
  LNormal := FItem.GetPixel(INSIDE_X, INSIDE_Y);
  FItem.Enter(FAction);
  LTftdStep := LNormal - FItem.GetPixel(INSIDE_X, INSIDE_Y);
  LClassic := NewItem(0, False);
  try
    LClassic.Draw;
    LNormal := LClassic.GetPixel(INSIDE_X, INSIDE_Y);
    LClassic.Enter(FAction);
    LClassicStep := LNormal - LClassic.GetPixel(INSIDE_X, INSIDE_Y);
  finally
    LClassic.Free;
  end;
  // ActionMenuItem: _highlightModifier = TFTDMode ? 12 : 3
  Assert.AreEqual(12, LTftdStep);
  Assert.AreEqual(3, LClassicStep);
end;

end.
