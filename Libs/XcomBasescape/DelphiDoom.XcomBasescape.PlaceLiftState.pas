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
  DelphiDoom.XcomBasescape.BaseView, DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>
  ///   The base grid with "Select position for access lift": a click puts the lift there, closes this screen and
  ///   opens the basescape of the base. The base is not owned (the saved game has it). Not ported: the choice of the
  ///   starting facilities of a custom initial base (SelectStartFacilityState, option customInitialBase)
  /// </summary>
  TXcomPlaceLiftState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FNavigator: IXcomBasescapeNavigator;
    FLift: TXcomRuleBaseFacility;
    FView: TXcomBaseView;
    FTxtTitle: TXcomText;
    procedure ViewClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
      const ANavigator: IXcomBasescapeNavigator);
    property View: TXcomBaseView read FView;
    /// <summary>Puts the lift at the selected square (the click of the view)</summary>
    procedure PlaceAt(AX, AY: Integer);
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomBasescape.BasescapeState;

{ TXcomPlaceLiftState }

constructor TXcomPlaceLiftState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
  const ANavigator: IXcomBasescapeNavigator);
var
  LName: string;
  LRuleset: TXcomRuleset;
begin
  inherited Create(AHost);
  FBase := ABase;
  FGlobe := AGlobe;
  FNavigator := ANavigator;
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
begin
  LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(FLift));
  LFacility.X := AX;
  LFacility.Y := AY;
  FBase.Facilities.Add(LFacility);
  Host.PopState;
  Host.PushState(TXcomBasescapeState.Create(Host, FBase, FGlobe, FNavigator));
end;

end.
