{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - the screens that the buttons of the geoscape and of   }
{  the basescape open (part of the composition root: it knows the classes)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.GeoscapeNavigator;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Navigator.Intf,
  DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.SavedGame;

type
  /// <summary>
  ///   Opens the screens that exist (the bases screen from the geoscape); the others do nothing yet. It is the
  ///   navigator of both the geoscape and the basescape; it does not own the host
  /// </summary>
  TXcomGameNavigator = class(TInterfacedObject, IXcomGeoscapeNavigator, IXcomBasescapeNavigator)
  strict private
    FHost: TXcomStateHost;
  public
    constructor Create(AHost: TXcomStateHost);
    procedure OpenIntercept;
    procedure OpenBases(AGlobe: TXcomGlobe);
    procedure OpenGraphs;
    procedure OpenUfopaedia;
    procedure OpenOptions;
    procedure OpenFunding;
    procedure OpenBase(ABase: TXcomBase; AGlobe: TXcomGlobe);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure Open(AScreen: TXcomBaseScreen; ABase: TXcomBase; AFacility: TXcomBaseFacility);
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.BasescapeState, DelphiDoom.XcomBasescape.SoldiersState,
  DelphiDoom.XcomBasescape.CraftsState, DelphiDoom.XcomBasescape.BaseInfoState;

constructor TXcomGameNavigator.Create(AHost: TXcomStateHost);
begin
  inherited Create;
  FHost := AHost;
end;

procedure TXcomGameNavigator.OpenIntercept;
begin
end;

procedure TXcomGameNavigator.OpenBases(AGlobe: TXcomGlobe);
var
  LSave: TXcomSavedGame;
begin
  LSave := TXcomStrategy.SavedGame(FHost);
  if LSave.Bases.Count > 0 then
    FHost.PushState(TXcomBasescapeState.Create(FHost, LSave.Bases.First, AGlobe, Self));
end;

procedure TXcomGameNavigator.OpenBase(ABase: TXcomBase; AGlobe: TXcomGlobe);
begin
  FHost.PushState(TXcomBasescapeState.Create(FHost, ABase, AGlobe, Self));
end;

procedure TXcomGameNavigator.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
  Open(AScreen, ABase, nil);
end;

procedure TXcomGameNavigator.OpenGraphs;
begin
end;

procedure TXcomGameNavigator.OpenUfopaedia;
begin
end;

procedure TXcomGameNavigator.OpenOptions;
begin
end;

procedure TXcomGameNavigator.OpenFunding;
begin
end;

procedure TXcomGameNavigator.Open(AScreen: TXcomBaseScreen; ABase: TXcomBase; AFacility: TXcomBaseFacility);
begin
  case AScreen of
    bsBaseInfo:
      FHost.PushState(TXcomBaseInfoState.Create(FHost, ABase));
    bsSoldiers:
      FHost.PushState(TXcomSoldiersState.Create(FHost, ABase));
    bsCrafts:
      FHost.PushState(TXcomCraftsState.Create(FHost, ABase));
  end;
end;

end.
