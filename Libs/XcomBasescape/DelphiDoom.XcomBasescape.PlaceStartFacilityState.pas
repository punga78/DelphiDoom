{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - PlaceStartFacilityState of OpenXcom     }
{  (where a facility of the starting base goes, option customInitialBase)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PlaceStartFacilityState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomBasescape.PlaceFacilityState;

type
  /// <summary>
  ///   PlaceFacilityState for a facility of the starting base: it costs nothing and is built at once ("None" as
  ///   cost and as time). A click on a square where it cannot go closes the window with "Cannot build here"; a
  ///   click where it can adds the facility, closes the window and calls ABuilt (the list it came from takes the
  ///   facility off). The C++ keeps a pointer to the SelectStartFacilityState; here a callback
  /// </summary>
  TXcomPlaceStartFacilityState = class(TXcomPlaceFacilityState)
  strict private
    FBuilt: TProc;
    procedure StartViewClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ARule: TXcomRuleBaseFacility; const ABuilt: TProc);
    /// <summary>The click of the view on the selected square of the grid</summary>
    procedure PlaceStart;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomMenu.ErrorMessageState;

constructor TXcomPlaceStartFacilityState.Create(AHost: TXcomStateHost; ABase: TXcomBase;
  ARule: TXcomRuleBaseFacility; const ABuilt: TProc);
begin
  inherited Create(AHost, ABase, ARule);
  FBuilt := ABuilt;
  View.OnMouseClick(StartViewClick);
  CostText.SetText(Tr('STR_NONE'));
  TimeText.SetText(Tr('STR_NONE'));
end;

procedure TXcomPlaceStartFacilityState.StartViewClick(AAction: TXcomAction);
begin
  PlaceStart;
end;

procedure TXcomPlaceStartFacilityState.PlaceStart;
var
  LFacility: TXcomBaseFacility;
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
  LBuilt: TProc;
begin
  if not View.IsPlaceable(Rule, False) then
  begin
    LMessage := Default(TXcomInterfaceElement);
    LPalette := Default(TXcomInterfaceElement);
    LPalette.Color := -1;
    LInterface := Host.Resources.GetInterface('basescape');
    if LInterface <> nil then
    begin
      LInterface.TryGetElement('errorMessage', LMessage);
      LInterface.TryGetElement('errorPalette', LPalette);
    end;
    Host.PopState;
    Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_CANNOT_BUILD_HERE'), Palette, Byte(LMessage.Color),
      'BACK01.SCR', LPalette.Color));
  end
  else
  begin
    LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(Rule));
    LFacility.X := View.GridX;
    LFacility.Y := View.GridY;
    Base.Facilities.Add(LFacility);
    LBuilt := FBuilt;
    Host.PopState;
    if Assigned(LBuilt) then
      LBuilt();
  end;
end;

end.
