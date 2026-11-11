{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ConfirmDestinationState of OpenXcom (the }
{  target chosen for a craft)                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ConfirmDestinationState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   "Target: X" with OK and Cancel: OK sets the destination of the craft (a new waypoint, that has no id yet, is
  ///   given one and added to the game) and closes this popup and the one below it. A new waypoint belongs to this
  ///   state until OK hands it to the game; Cancel (or the end of the game) frees it
  /// </summary>
  TXcomConfirmDestinationState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FTarget: TXcomTarget;
    FOwnsTarget: Boolean;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTarget: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    function IsNewWaypoint: Boolean;
  public
    /// <param name="ACraft">The craft (not owned)</param>
    /// <param name="ATarget">The target; a waypoint with id 0 is new and is owned by this state until accepted</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; ATarget: TXcomTarget);
    destructor Destroy; override;
  end;

implementation

uses
  DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.TargetNames;

{ TXcomConfirmDestinationState }

constructor TXcomConfirmDestinationState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft; ATarget: TXcomTarget);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FTarget := ATarget;
  FOwnsTarget := IsNewWaypoint;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 244, 72, 6, 64, wpNone);
  FBtnOk := TXcomTextButton.Create(50, 12, 68, 104);
  FBtnCancel := TXcomTextButton.Create(50, 12, 138, 104);
  FTxtTarget := TXcomText.Create(232, 32, 12, 72);
  SetInterface('confirmDestination', IsNewWaypoint);
  Add(FWindow, 'window', 'confirmDestination');
  Add(FBtnOk, 'button', 'confirmDestination');
  Add(FBtnCancel, 'button', 'confirmDestination');
  Add(FTxtTarget, 'text', 'confirmDestination');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTarget.SetBig;
  FTxtTarget.SetAlign(haCenter);
  FTxtTarget.SetVerticalAlign(vaMiddle);
  FTxtTarget.SetWordWrap(True);
  if IsNewWaypoint then
    FTxtTarget.SetText(Tr('STR_TARGET').Arg(Tr('STR_WAY_POINT').Text))
  else
    FTxtTarget.SetText(Tr('STR_TARGET').Arg(TXcomTargetNames.Name(FTarget, Host.Language)));
end;

destructor TXcomConfirmDestinationState.Destroy;
begin
  if FOwnsTarget then
    FTarget.Free;
  inherited Destroy;
end;

function TXcomConfirmDestinationState.IsNewWaypoint: Boolean;
begin
  Result := (FTarget is TXcomWaypoint) and (FTarget.Id = 0);
end;

procedure TXcomConfirmDestinationState.OkClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
begin
  if IsNewWaypoint then
  begin
    LSave := TXcomStrategy.SavedGame(Host);
    FTarget.Id := LSave.GetId('STR_WAY_POINT');
    LSave.Waypoints.Add(TXcomWaypoint(FTarget));
    FOwnsTarget := False;
  end;
  FCraft.SetDestination(FTarget);
  FCraft.Status := 'STR_OUT';
  Host.PopState;
  Host.PopState;
end;

procedure TXcomConfirmDestinationState.CancelClick(AAction: TXcomAction);
begin
  // a new waypoint that is not accepted is freed by the destructor
  Host.PopState;
end;

end.
