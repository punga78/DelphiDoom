{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - "View reports" of a   }
{  finished research asks for the articles of the Ufopaedia                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.Report;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf, DelphiDoom.XcomGeoscape.BaseNavigator.Intf,
  DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomUfopaedia.Fakes;

type
  /// <summary>A geoscape that pushes the popups on the game at once</summary>
  TPushingControl = class(TInterfacedObject, IXcomGeoscapeControl)
  strict private
    FGame: TXcomGame;
  public
    constructor Create(AGame: TXcomGame);
    procedure TimerReset;
    function Globe: TXcomGlobe;
    procedure Popup(AState: TXcomState);
    procedure OpenBase(ABase: TXcomBase);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure PlaceLift(ABase: TXcomBase; AFirst: Boolean);
    function Screens: IXcomGeoscapeScreens;
    function Palette: PXcomColors;
  end;

  [TestFixture]
  [Category('xcom-ufopaedia')]
  TTestXcomUfopaediaReport = class(TObject)
  strict private
    FWorld: TTestWorld;
    FResourcesRef: IXcomResources;
    FControl: IXcomGeoscapeControl;
    procedure ClickBase(AX, AY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeChiedereLArticoloDellaRicercaConIlPulsanteDeiRapporti;
    [Test]
    procedure DovrebbeNonChiedereNullaConOk;
    [Test]
    procedure DovrebbeChiudereIlPopupSenzaApritoreDiArticoli;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.PopupEvents, DelphiDoom.XcomStrategy.Events.Intf;

{ TPushingControl }

constructor TPushingControl.Create(AGame: TXcomGame);
begin
  inherited Create;
  FGame := AGame;
end;

procedure TPushingControl.TimerReset;
begin
end;

function TPushingControl.Globe: TXcomGlobe;
begin
  Result := nil;
end;

procedure TPushingControl.Popup(AState: TXcomState);
begin
  FGame.PushState(AState);
end;

procedure TPushingControl.OpenBase(ABase: TXcomBase);
begin
end;

procedure TPushingControl.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
end;

procedure TPushingControl.PlaceLift(ABase: TXcomBase; AFirst: Boolean);
begin
end;

function TPushingControl.Screens: IXcomGeoscapeScreens;
begin
  Result := nil;
end;

function TPushingControl.Palette: PXcomColors;
begin
  Result := nil;
end;

{ TTestXcomUfopaediaReport }

procedure TTestXcomUfopaediaReport.Setup;
begin
  FWorld := TTestWorld.Create;
  FResourcesRef := TUfopaediaResources.Create(FWorld.Game.Resources);
  FWorld.Game.AdoptData(FResourcesRef, nil);
  FControl := TPushingControl.Create(FWorld.Game);
end;

procedure TTestXcomUfopaediaReport.TearDown;
begin
  FWorld.Free;
  FControl := nil;
  FResourcesRef := nil;
end;

procedure TTestXcomUfopaediaReport.ClickBase(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

procedure TTestXcomUfopaediaReport.DovrebbeChiedereLArticoloDellaRicercaConIlPulsanteDeiRapporti;
var
  LEvents: IXcomGeoscapeEvents;
  LAsked: string;
  LPopup: TXcomState;
begin
  LAsked := '';
  LEvents := TXcomPopupGeoscapeEvents.Create(FWorld.Game, nil,
    procedure(AArticleIds: TArray<string>)
    begin
      LAsked := LAsked + string.Join(',', AArticleIds) + ';';
    end);
  (LEvents as IXcomGeoscapeAware).AttachGeoscape(FControl);
  // a state under the popup: the game has no top state when it is empty
  LEvents.ResearchFinished(nil, 'STR_UNDER');
  LEvents.ResearchFinished(nil, 'STR_GAUSS_PISTOL');
  LPopup := FWorld.Game.TopState;
  FWorld.Wait(400);
  // "View reports": 80 x 16 at (176, 146)
  ClickBase(176 + 40, 146 + 8);
  FWorld.Wait(40);
  Assert.AreEqual('STR_GAUSS_PISTOL;', LAsked);
  Assert.AreNotSame(LPopup, FWorld.Game.TopState);
end;

procedure TTestXcomUfopaediaReport.DovrebbeNonChiedereNullaConOk;
var
  LEvents: IXcomGeoscapeEvents;
  LAsked: string;
begin
  LAsked := '';
  LEvents := TXcomPopupGeoscapeEvents.Create(FWorld.Game, nil,
    procedure(AArticleIds: TArray<string>)
    begin
      LAsked := LAsked + string.Join(',', AArticleIds) + ';';
    end);
  (LEvents as IXcomGeoscapeAware).AttachGeoscape(FControl);
  // a state under the popup: the game has no top state when it is empty
  LEvents.ResearchFinished(nil, 'STR_UNDER');
  LEvents.ResearchFinished(nil, 'STR_GAUSS_PISTOL');
  FWorld.Wait(400);
  // OK: 80 x 16 at (64, 146)
  ClickBase(64 + 40, 146 + 8);
  FWorld.Wait(40);
  Assert.AreEqual('', LAsked);
end;

procedure TTestXcomUfopaediaReport.DovrebbeChiudereIlPopupSenzaApritoreDiArticoli;
var
  LEvents: IXcomGeoscapeEvents;
  LPopup: TXcomState;
begin
  LEvents := TXcomPopupGeoscapeEvents.Create(FWorld.Game);
  (LEvents as IXcomGeoscapeAware).AttachGeoscape(FControl);
  LEvents.ResearchFinished(nil, 'STR_UNDER');
  LEvents.ResearchFinished(nil, 'STR_GAUSS_PISTOL');
  LPopup := FWorld.Game.TopState;
  FWorld.Wait(400);
  ClickBase(176 + 40, 146 + 8);
  FWorld.Wait(40);
  Assert.AreNotSame(LPopup, FWorld.Game.TopState);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomUfopaediaReport);

end.
