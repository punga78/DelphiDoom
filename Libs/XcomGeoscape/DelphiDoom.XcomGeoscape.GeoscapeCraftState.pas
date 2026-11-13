{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - GeoscapeCraftState of OpenXcom (the      }
{  window of a craft that is out: status and new orders)                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GeoscapeCraftState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomGeoscape.Globe;

type
  /// <summary>
  ///   The status of a craft that is out (destination, speed, fuel, damage, weapons) and its orders: return to base,
  ///   select a new target, patrol. When it comes from a UFO that was lost it has the waypoint at the last position
  ///   of the UFO: "go to the last known position" (the cancel button) adds the waypoint to the game
  /// </summary>
  TXcomGeoscapeCraftState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FWaypoint: TXcomWaypoint;
    FOnSelectTarget: TProc<TXcomCraft>;
    FWindow: TXcomWindow;
    FBtnBase: TXcomTextButton;
    FBtnTarget: TXcomTextButton;
    FBtnPatrol: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtStatus: TXcomText;
    FTxtBase: TXcomText;
    FTxtSpeed: TXcomText;
    FTxtMaxSpeed: TXcomText;
    FTxtAltitude: TXcomText;
    FTxtFuel: TXcomText;
    FTxtDamage: TXcomText;
    FTxtW1Name: TXcomText;
    FTxtW1Ammo: TXcomText;
    FTxtW2Name: TXcomText;
    FTxtW2Ammo: TXcomText;
    FTxtRedirect: TXcomText;
    FTxtSoldier: TXcomText;
    FTxtHWP: TXcomText;
    procedure BaseClick(AAction: TXcomAction);
    procedure TargetClick(AAction: TXcomAction);
    procedure PatrolClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    function StatusText: string;
    procedure SetWeapon(AIndex: Integer; AName, AAmmo: TXcomText; const AKey: string);
  public
    /// <param name="ACraft">The craft (not owned)</param>
    /// <param name="AGlobe">The globe (not owned)</param>
    /// <param name="AWaypoint">The last position of the UFO (this state owns it until an order hands it over); nil when there is none</param>
    /// <param name="AOnSelectTarget">Pushes the screen that chooses a new destination (nil: the button only closes)</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; AGlobe: TXcomGlobe; AWaypoint: TXcomWaypoint;
      const AOnSelectTarget: TProc<TXcomCraft>);
    destructor Destroy; override;
  end;

implementation

uses
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomSave.Target;

{ TXcomGeoscapeCraftState }

constructor TXcomGeoscapeCraftState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft; AGlobe: TXcomGlobe;
  AWaypoint: TXcomWaypoint; const AOnSelectTarget: TProc<TXcomCraft>);
var
  LSpeed: Integer;
  LAltitude: string;
  LUfo: TXcomUfo;
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FWaypoint := AWaypoint;
  FOnSelectTarget := AOnSelectTarget;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 240, 184, 8, 8, wpBoth);
  FBtnBase := TXcomTextButton.Create(212, 12, 22, 124);
  FBtnTarget := TXcomTextButton.Create(212, 12, 22, 140);
  FBtnPatrol := TXcomTextButton.Create(212, 12, 22, 156);
  FBtnCancel := TXcomTextButton.Create(212, 12, 22, 172);
  FTxtTitle := TXcomText.Create(210, 17, 32, 20);
  FTxtStatus := TXcomText.Create(210, 17, 32, 36);
  FTxtBase := TXcomText.Create(210, 9, 32, 52);
  FTxtSpeed := TXcomText.Create(210, 9, 32, 60);
  FTxtMaxSpeed := TXcomText.Create(210, 9, 32, 68);
  FTxtAltitude := TXcomText.Create(210, 9, 32, 76);
  FTxtFuel := TXcomText.Create(130, 9, 32, 84);
  FTxtDamage := TXcomText.Create(80, 9, 164, 84);
  FTxtW1Name := TXcomText.Create(130, 9, 32, 92);
  FTxtW1Ammo := TXcomText.Create(80, 9, 164, 92);
  FTxtW2Name := TXcomText.Create(130, 9, 32, 100);
  FTxtW2Ammo := TXcomText.Create(80, 9, 164, 100);
  FTxtRedirect := TXcomText.Create(230, 17, 13, 108);
  FTxtSoldier := TXcomText.Create(80, 9, 164, 68);
  FTxtHWP := TXcomText.Create(80, 9, 164, 76);
  SetInterface('geoCraft');
  Add(FWindow, 'window', 'geoCraft');
  Add(FBtnBase, 'button', 'geoCraft');
  Add(FBtnTarget, 'button', 'geoCraft');
  Add(FBtnPatrol, 'button', 'geoCraft');
  Add(FBtnCancel, 'button', 'geoCraft');
  Add(FTxtTitle, 'text1', 'geoCraft');
  Add(FTxtStatus, 'text1', 'geoCraft');
  Add(FTxtBase, 'text3', 'geoCraft');
  Add(FTxtSpeed, 'text3', 'geoCraft');
  Add(FTxtMaxSpeed, 'text3', 'geoCraft');
  Add(FTxtAltitude, 'text3', 'geoCraft');
  Add(FTxtFuel, 'text3', 'geoCraft');
  Add(FTxtDamage, 'text3', 'geoCraft');
  Add(FTxtW1Name, 'text3', 'geoCraft');
  Add(FTxtW1Ammo, 'text3', 'geoCraft');
  Add(FTxtW2Name, 'text3', 'geoCraft');
  Add(FTxtW2Ammo, 'text3', 'geoCraft');
  Add(FTxtRedirect, 'text3', 'geoCraft');
  Add(FTxtSoldier, 'text3', 'geoCraft');
  Add(FTxtHWP, 'text3', 'geoCraft');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnBase.SetText(Tr('STR_RETURN_TO_BASE'));
  FBtnBase.OnMouseClick(BaseClick);
  FBtnTarget.SetText(Tr('STR_SELECT_NEW_TARGET'));
  FBtnTarget.OnMouseClick(TargetClick);
  FBtnPatrol.SetText(Tr('STR_PATROL'));
  FBtnPatrol.OnMouseClick(PatrolClick);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(TXcomTargetNames.Name(FCraft, Host.Language));
  FTxtStatus.SetWordWrap(True);
  FTxtStatus.SetText(Tr('STR_STATUS_').Arg(StatusText));
  FTxtBase.SetText(Tr('STR_BASE_UC').Arg(FCraft.Base.Name));
  LSpeed := FCraft.Speed;
  if FCraft.InDogfight and (FCraft.Destination is TXcomUfo) then
    LSpeed := TXcomUfo(FCraft.Destination).Speed;
  FTxtSpeed.SetText(Tr('STR_SPEED_').Arg(TXcomFunding.FormatNumber(LSpeed, '')));
  FTxtMaxSpeed.SetText(Tr('STR_MAXIMUM_SPEED_UC').Arg(TXcomFunding.FormatNumber(FCraft.Rules.MaxSpeed, '')));
  // Craft::getAltitude: the altitude of the UFO it follows, else very low
  LAltitude := 'STR_VERY_LOW';
  if FCraft.Destination is TXcomUfo then
  begin
    LUfo := TXcomUfo(FCraft.Destination);
    if LUfo.Altitude <> 'STR_GROUND' then
      LAltitude := LUfo.Altitude;
  end;
  if (FCraft.Rules.MaxAltitude > -1) and not AGlobe.InsideLand(FCraft.Longitude, FCraft.Latitude) then
    LAltitude := 'STR_AIRBORNE';
  FTxtAltitude.SetText(Tr('STR_ALTITUDE_').Arg(Tr(LAltitude).Text));
  FTxtFuel.SetText(Tr('STR_FUEL').Arg(IntToStr(FCraft.FuelPercentage) + '%'));
  FTxtDamage.SetText(Tr('STR_DAMAGE_UC_').Arg(IntToStr(FCraft.DamagePercentage) + '%'));
  SetWeapon(0, FTxtW1Name, FTxtW1Ammo, 'STR_WEAPON_ONE');
  SetWeapon(1, FTxtW2Name, FTxtW2Ammo, 'STR_WEAPON_TWO');
  FTxtRedirect.SetBig;
  FTxtRedirect.SetAlign(haCenter);
  FTxtRedirect.SetText(Tr('STR_REDIRECT_CRAFT'));
  FTxtSoldier.SetText(Tr('STR_SOLDIERS_UC').Text + '>' + Chr(XCOM_TOKEN_COLOR_FLIP) +
    IntToStr(FCraft.NumSoldiers(TXcomBase(FCraft.Base).Soldiers)));
  FTxtHWP.SetText(Tr('STR_HWPS').Text + '>' + Chr(XCOM_TOKEN_COLOR_FLIP) + IntToStr(FCraft.NumVehicles));
  if not Assigned(FWaypoint) then
    FTxtRedirect.Visible := False
  else
    FBtnCancel.SetText(Tr('STR_GO_TO_LAST_KNOWN_UFO_POSITION'));
  if FCraft.LowFuel or FCraft.MissionComplete then
  begin
    FBtnBase.Visible := False;
    FBtnTarget.Visible := False;
    FBtnPatrol.Visible := False;
  end;
  if FCraft.Rules.Soldiers = 0 then
    FTxtSoldier.Visible := False;
  if FCraft.Rules.Vehicles = 0 then
    FTxtHWP.Visible := False;
end;

destructor TXcomGeoscapeCraftState.Destroy;
begin
  // a waypoint that no order took stays ours
  FWaypoint.Free;
  inherited Destroy;
end;

function TXcomGeoscapeCraftState.StatusText: string;
var
  LUfo: TXcomUfo;
begin
  if Assigned(FWaypoint) then
    Result := Tr('STR_INTERCEPTING_UFO').Arg(FWaypoint.Id).Text
  else if FCraft.LowFuel then
    Result := Tr('STR_LOW_FUEL_RETURNING_TO_BASE').Text
  else if FCraft.MissionComplete then
    Result := Tr('STR_MISSION_COMPLETE_RETURNING_TO_BASE').Text
  else if not Assigned(FCraft.Destination) then
    Result := Tr('STR_PATROLLING').Text
  else if FCraft.Destination = FCraft.Base then
    Result := Tr('STR_RETURNING_TO_BASE').Text
  else if FCraft.Destination is TXcomUfo then
  begin
    LUfo := TXcomUfo(FCraft.Destination);
    if FCraft.InDogfight then
      Result := Tr('STR_TAILING_UFO').Text
    else if LUfo.Status = TXcomUfo.STATUS_FLYING then
      Result := Tr('STR_INTERCEPTING_UFO').Arg(LUfo.Id).Text
    else
      Result := Tr('STR_DESTINATION_UC_').Arg(TXcomTargetNames.Name(LUfo, Host.Language)).Text;
  end
  else
    Result := Tr('STR_DESTINATION_UC_').Arg(TXcomTargetNames.Name(FCraft.Destination, Host.Language)).Text;
end;

procedure TXcomGeoscapeCraftState.SetWeapon(AIndex: Integer; AName, AAmmo: TXcomText; const AKey: string);
begin
  if (FCraft.Rules.Weapons > AIndex) and (AIndex < FCraft.Weapons.Count) and Assigned(FCraft.Weapons[AIndex]) then
  begin
    AName.SetText(Tr(AKey).Arg(Tr(FCraft.Weapons[AIndex].Rules.WeaponType).Text));
    AAmmo.SetText(Tr('STR_ROUNDS_').Arg(FCraft.Weapons[AIndex].Ammo));
  end
  else
  begin
    AName.SetText(Tr(AKey).Arg(Tr('STR_NONE_UC').Text));
    AAmmo.Visible := False;
  end;
end;

procedure TXcomGeoscapeCraftState.BaseClick(AAction: TXcomAction);
begin
  Host.PopState;
  FCraft.ReturnToBase;
  FreeAndNil(FWaypoint);
end;

procedure TXcomGeoscapeCraftState.TargetClick(AAction: TXcomAction);
begin
  Host.PopState;
  if Assigned(FOnSelectTarget) then
    FOnSelectTarget(FCraft);
  FreeAndNil(FWaypoint);
end;

procedure TXcomGeoscapeCraftState.PatrolClick(AAction: TXcomAction);
begin
  Host.PopState;
  FCraft.SetDestination(nil);
  FreeAndNil(FWaypoint);
end;

procedure TXcomGeoscapeCraftState.CancelClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
begin
  // go to the last known UFO position
  if Assigned(FWaypoint) then
  begin
    LSave := TXcomStrategy.SavedGame(Host);
    FWaypoint.Id := LSave.GetId('STR_WAY_POINT');
    LSave.Waypoints.Add(FWaypoint);
    FCraft.SetDestination(FWaypoint);
    FWaypoint := nil;
  end;
  Host.PopState;
end;

end.
