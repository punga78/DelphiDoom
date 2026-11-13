{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SelectStartFacilityState of OpenXcom    }
{  (the facilities of the starting base that the player still has to place,     }
{  option customInitialBase)                                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SelectStartFacilityState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.BaseNavigator.Intf,
  DelphiDoom.XcomBasescape.BuildFacilitiesState;

type
  /// <summary>
  ///   The "Installation" window with the facilities of the starting base of the rules (not the lift): a click
  ///   chooses where one goes (PlaceStartFacilityState, no cost and no construction time) and takes it off the
  ///   list; when the list is empty this window and the basescape below close and the game starts. Reset
  ///   removes every facility of the base and goes back to the place of the access lift
  /// </summary>
  TXcomSelectStartFacilityState = class(TXcomBuildFacilitiesState)
  strict private
    FGlobe: TXcomGlobe;
    FNavigator: IXcomBasescapeNavigator;
    procedure ResetClick(AAction: TXcomAction);
    procedure StartFacilitiesClick(AAction: TXcomAction);
  public
    /// <param name="AParent">The basescape that is below (not owned): it is refreshed when this window is on top</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AParent: TXcomState; AGlobe: TXcomGlobe;
      const ANavigator: IXcomBasescapeNavigator);
    /// <summary>Mod::getCustomBaseFacilities: the facilities of "startingBase" in their order, without the lifts</summary>
    class function CustomBaseFacilities(ARuleset: TXcomRuleset): TArray<TXcomRuleBaseFacility>; static;
    /// <summary>SelectStartFacilityState::facilityBuilt: the facility of the selected row is placed</summary>
    procedure FacilityBuilt;
    /// <summary>The facilities still to place</summary>
    function Remaining: Integer;
  end;

implementation

uses
  DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomBasescape.PlaceLiftState, DelphiDoom.XcomBasescape.PlaceStartFacilityState;

constructor TXcomSelectStartFacilityState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AParent: TXcomState;
  AGlobe: TXcomGlobe; const ANavigator: IXcomBasescapeNavigator);
begin
  inherited Create(AHost, ABase, AParent);
  FGlobe := AGlobe;
  FNavigator := ANavigator;
  Facilities.Clear;
  Facilities.AddRange(CustomBaseFacilities(TXcomStrategy.Ruleset(AHost)));
  OkButton.SetText(Tr('STR_RESET'));
  OkButton.OnMouseClick(ResetClick);
  // no key closes this window
  OkButton.OnKeyboardPress(nil, Host.Options.KeyCancel);
  List.OnMouseClick(StartFacilitiesClick);
  PopulateBuildList;
end;

class function TXcomSelectStartFacilityState.CustomBaseFacilities(
  ARuleset: TXcomRuleset): TArray<TXcomRuleBaseFacility>;
var
  LNode, LItem: IYamlNode;
  LRule: TXcomRuleBaseFacility;
  LList: TList<TXcomRuleBaseFacility>;
begin
  Result := nil;
  if not ARuleset.StartingBase.TryGetValue('facilities', LNode) then
    Exit;
  LList := TList<TXcomRuleBaseFacility>.Create;
  try
    for LItem in LNode.Items do
    begin
      LRule := ARuleset.Facilities.Find(TXcomNodeReader.ReadString(LItem, 'type', ''));
      if (LRule <> nil) and (not LRule.IsLift) then
        LList.Add(LRule);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomSelectStartFacilityState.Remaining: Integer;
begin
  Result := Facilities.Count;
end;

procedure TXcomSelectStartFacilityState.ResetClick(AAction: TXcomAction);
var
  LBase: TXcomBase;
  LGlobe: TXcomGlobe;
  LNavigator: IXcomBasescapeNavigator;
  LHost: TXcomStateHost;
begin
  // this window and the basescape go away: what is needed after that is kept in locals
  LBase := Base;
  LGlobe := FGlobe;
  LNavigator := FNavigator;
  LHost := Host;
  LBase.Facilities.Clear;
  LHost.PopState;
  LHost.PopState;
  LHost.PushState(TXcomPlaceLiftState.Create(LHost, LBase, LGlobe, LNavigator, True));
end;

procedure TXcomSelectStartFacilityState.StartFacilitiesClick(AAction: TXcomAction);
begin
  if (List.GetSelectedRow >= 0) and (List.GetSelectedRow < Facilities.Count) then
    Host.PushState(TXcomPlaceStartFacilityState.Create(Host, Base, Facilities[List.GetSelectedRow],
      procedure
      begin
        FacilityBuilt;
      end));
end;

procedure TXcomSelectStartFacilityState.FacilityBuilt;
begin
  if (List.GetSelectedRow >= 0) and (List.GetSelectedRow < Facilities.Count) then
    Facilities.Delete(List.GetSelectedRow);
  if Facilities.Count = 0 then
  begin
    Host.PopState;
    // return to geoscape, force timer to start
    Host.PopState;
  end
  else
    PopulateBuildList;
end;

end.
