{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - InterceptState of OpenXcom (the list of  }
{  the crafts that can be launched)                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.InterceptState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   "Launch interception": a list of the crafts (of one base, or of all) with status, base and weapons / crew /
  ///   vehicles. A click on a craft that can be sent asks for a destination (or, when a target was given, to confirm
  ///   it); a right click on a craft that is out centers the globe on it
  /// </summary>
  TXcomInterceptState = class(TXcomState)
  strict private
    FGlobe: TXcomGlobe;
    FBase: TXcomBase;
    FTarget: TXcomTarget;
    FControl: IXcomGeoscapeControl;
    FOnSelectDestination: TProc<TXcomCraft>;
    FOnConfirmDestination: TProc<TXcomCraft, TXcomTarget>;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FBtnGotoBase: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtCraft: TXcomText;
    FTxtStatus: TXcomText;
    FTxtBase: TXcomText;
    FTxtWeapons: TXcomText;
    FLstCrafts: TXcomTextList;
    FCrafts: TList<TXcomCraft>;
    procedure CancelClick(AAction: TXcomAction);
    procedure GotoBaseClick(AAction: TXcomAction);
    procedure CraftsLeftClick(AAction: TXcomAction);
    procedure CraftsRightClick(AAction: TXcomAction);
    function Counter(ACount: Integer): string;
  public
    /// <param name="ABase">Shows the crafts of this base only (nil: all the crafts)</param>
    /// <param name="ATarget">The target to intercept (nil: the player chooses it afterwards)</param>
    /// <param name="AOnSelectDestination">Pushes SelectDestinationState for the craft</param>
    /// <param name="AOnConfirmDestination">Pushes ConfirmDestinationState for the craft and the target</param>
    constructor Create(AHost: TXcomStateHost; AGlobe: TXcomGlobe; ABase: TXcomBase; ATarget: TXcomTarget;
      const AControl: IXcomGeoscapeControl; const AOnSelectDestination: TProc<TXcomCraft>;
      const AOnConfirmDestination: TProc<TXcomCraft, TXcomTarget>);
    destructor Destroy; override;
    property Crafts: TXcomTextList read FLstCrafts;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.TargetNames,
  DelphiDoom.XcomGeoscape.Keys, DelphiDoom.XcomSave.SavedGame;

{ TXcomInterceptState }

constructor TXcomInterceptState.Create(AHost: TXcomStateHost; AGlobe: TXcomGlobe; ABase: TXcomBase;
  ATarget: TXcomTarget; const AControl: IXcomGeoscapeControl; const AOnSelectDestination: TProc<TXcomCraft>;
  const AOnConfirmDestination: TProc<TXcomCraft, TXcomTarget>);
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LRow: Integer;
begin
  inherited Create(AHost);
  FGlobe := AGlobe;
  FBase := ABase;
  FTarget := ATarget;
  FControl := AControl;
  FOnSelectDestination := AOnSelectDestination;
  FOnConfirmDestination := AOnConfirmDestination;
  FCrafts := TList<TXcomCraft>.Create;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 140, 0, 30, wpHorizontal);
  if Assigned(FBase) then
    FBtnCancel := TXcomTextButton.Create(142, 16, 16, 146)
  else
    FBtnCancel := TXcomTextButton.Create(288, 16, 16, 146);
  FBtnGotoBase := TXcomTextButton.Create(142, 16, 162, 146);
  FTxtTitle := TXcomText.Create(300, 17, 10, 46);
  FTxtCraft := TXcomText.Create(86, 9, 14, 70);
  FTxtStatus := TXcomText.Create(70, 9, 100, 70);
  FTxtBase := TXcomText.Create(80, 9, 170, 70);
  FTxtWeapons := TXcomText.Create(80, 17, 238, 62);
  FLstCrafts := TXcomTextList.Create(Host.Options, Host.Clock, 288, 64, 8, 78);
  SetInterface('intercept');
  Add(FWindow, 'window', 'intercept');
  Add(FBtnCancel, 'button', 'intercept');
  Add(FBtnGotoBase, 'button', 'intercept');
  Add(FTxtTitle, 'text1', 'intercept');
  Add(FTxtCraft, 'text2', 'intercept');
  Add(FTxtStatus, 'text2', 'intercept');
  Add(FTxtBase, 'text2', 'intercept');
  Add(FTxtWeapons, 'text2', 'intercept');
  Add(FLstCrafts, 'list', 'intercept');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FBtnCancel.OnKeyboardPress(CancelClick, KEY_GEO_INTERCEPT);
  FBtnGotoBase.SetText(Tr('STR_GO_TO_BASE'));
  FBtnGotoBase.OnMouseClick(GotoBaseClick);
  FBtnGotoBase.Visible := Assigned(FBase);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_LAUNCH_INTERCEPTION'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  FTxtStatus.SetText(Tr('STR_STATUS'));
  FTxtBase.SetText(Tr('STR_BASE'));
  FTxtWeapons.SetText(Tr('STR_WEAPONS_CREW_HWPS'));
  FLstCrafts.SetColumns([86, 70, 80, 46]);
  FLstCrafts.SetSelectable(True);
  FLstCrafts.SetBackground(FWindow);
  FLstCrafts.SetMargin(6);
  FLstCrafts.OnMouseClick(CraftsLeftClick);
  FLstCrafts.OnMouseClick(CraftsRightClick, XCOM_BUTTON_RIGHT);
  LRow := 0;
  for LBase in TXcomStrategy.SavedGame(AHost).Bases do
  begin
    if Assigned(FBase) and (LBase <> FBase) then
      Continue;
    for LCraft in LBase.Crafts do
    begin
      FCrafts.Add(LCraft);
      FLstCrafts.AddRow([TXcomTargetNames.Name(LCraft, Host.Language), Tr(LCraft.Status).Text, LBase.Name,
        Counter(LCraft.NumWeapons) + '/' + Counter(LCraft.NumSoldiers(LBase.Soldiers)) + '/' +
        Counter(LCraft.NumVehicles)]);
      if LCraft.Status = 'STR_READY' then
        FLstCrafts.SetCellColor(LRow, 1, FLstCrafts.GetSecondaryColor);
      Inc(LRow);
    end;
  end;
end;

destructor TXcomInterceptState.Destroy;
begin
  inherited Destroy;
  FCrafts.Free;
end;

function TXcomInterceptState.Counter(ACount: Integer): string;
begin
  // a number that is not zero is shown in the secondary color
  if ACount > 0 then
    Result := Chr(XCOM_TOKEN_COLOR_FLIP) + IntToStr(ACount) + Chr(XCOM_TOKEN_COLOR_FLIP)
  else
    Result := '0';
end;

procedure TXcomInterceptState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomInterceptState.GotoBaseClick(AAction: TXcomAction);
begin
  Host.PopState;
  FControl.OpenBase(FBase);
end;

procedure TXcomInterceptState.CraftsLeftClick(AAction: TXcomAction);
var
  LCraft: TXcomCraft;
begin
  if (FLstCrafts.GetSelectedRow < 0) or (FLstCrafts.GetSelectedRow >= FCrafts.Count) then
    Exit;
  LCraft := FCrafts[FLstCrafts.GetSelectedRow];
  if (LCraft.Status = 'STR_READY') or (((LCraft.Status = 'STR_OUT') or Host.Options.GetBool('craftLaunchAlways'))
    and not LCraft.LowFuel and not LCraft.MissionComplete) then
  begin
    Host.PopState;
    if FTarget = nil then
    begin
      if Assigned(FOnSelectDestination) then
        FOnSelectDestination(LCraft);
    end
    else if Assigned(FOnConfirmDestination) then
      FOnConfirmDestination(LCraft, FTarget);
  end;
end;

procedure TXcomInterceptState.CraftsRightClick(AAction: TXcomAction);
var
  LCraft: TXcomCraft;
begin
  if (FLstCrafts.GetSelectedRow < 0) or (FLstCrafts.GetSelectedRow >= FCrafts.Count) then
    Exit;
  LCraft := FCrafts[FLstCrafts.GetSelectedRow];
  if LCraft.Status = 'STR_OUT' then
  begin
    FGlobe.Center(LCraft.Longitude, LCraft.Latitude);
    Host.PopState;
  end;
end;

end.
