{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - PlaceLiftState of OpenXcom (where the   }
{  access lift of a new base goes)                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PlaceLiftState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text, DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.XcomBasescape.BaseView, DelphiDoom.XcomGeoscape.BaseNavigator.Intf, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>
  ///   The base grid with "Select position for access lift": a click puts the lift there, closes this screen and
  ///   opens the basescape of the base. The base is not owned (the saved game has it). For the first base of a game
  ///   (AFirst, option customInitialBase) the list of the starting facilities to place opens over the basescape
  /// </summary>
  TXcomPlaceLiftState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FNavigator: IXcomBasescapeNavigator;
    FLift: TXcomRuleBaseFacility;
    FView: TXcomBaseView;
    FTxtTitle: TXcomText;
    FFirst: Boolean;
    procedure ViewClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
      const ANavigator: IXcomBasescapeNavigator; AFirst: Boolean = False);
    property View: TXcomBaseView read FView;
    /// <summary>Puts the lift at the selected square (the click of the view)</summary>
    procedure PlaceAt(AX, AY: Integer);
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomBasescape.BasescapeState, DelphiDoom.XcomBasescape.SelectStartFacilityState;

{ TXcomPlaceLiftState }

constructor TXcomPlaceLiftState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
  const ANavigator: IXcomBasescapeNavigator; AFirst: Boolean);
var
  LName: string;
  LRuleset: TXcomRuleset;
begin
  inherited Create(AHost);
  FBase := ABase;
  FGlobe := AGlobe;
  FNavigator := ANavigator;
  FFirst := AFirst;
  LRuleset := TXcomStrategy.Ruleset(AHost);
  FView := TXcomBaseView.Create(Host.Clock, LRuleset, 192, 192, 0, 8);
  FTxtTitle := TXcomText.Create(320, 9, 0, 0);
  SetInterface('placeFacility');
  Add(FView, 'baseView', 'basescape');
  Add(FTxtTitle, 'text', 'placeFacility');
  CenterAllSurfaces;
  FView.SetTexture(TXcomStrategy.Rules(AHost).GetSurfaceSet('BASEBITS.PCK'));
  FView.SetBase(FBase);
  for LName in LRuleset.Facilities.Index do
    if LRuleset.Facilities.Find(LName).IsLift then
    begin
      FLift := LRuleset.Facilities.Find(LName);
      Break;
    end;
  FView.SetSelectable(FLift.Size);
  FView.OnMouseClick(ViewClick);
  FTxtTitle.SetText(Tr('STR_SELECT_POSITION_FOR_ACCESS_LIFT'));
end;

procedure TXcomPlaceLiftState.ViewClick(AAction: TXcomAction);
begin
  PlaceAt(FView.GridX, FView.GridY);
end;

procedure TXcomPlaceLiftState.PlaceAt(AX, AY: Integer);
var
  LFacility: TXcomBaseFacility;
  LHost: TXcomStateHost;
  LBase: TXcomBase;
  LGlobe: TXcomGlobe;
  LNavigator: IXcomBasescapeNavigator;
  LFirst: Boolean;
  LBasescape: TXcomBasescapeState;
begin
  LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(FLift));
  LFacility.X := AX;
  LFacility.Y := AY;
  FBase.Facilities.Add(LFacility);
  Host.PopState;
  LHost := Host;
  LBase := FBase;
  LGlobe := FGlobe;
  LNavigator := FNavigator;
  LFirst := FFirst;
  LBasescape := TXcomBasescapeState.Create(LHost, LBase, LGlobe, LNavigator);
  LHost.PushState(LBasescape);
  // the first base of a game with customInitialBase: the player places the facilities of the starting base
  if LFirst then
    LHost.PushState(TXcomSelectStartFacilityState.Create(LHost, LBase, LBasescape, LGlobe, LNavigator));
end;

end.
