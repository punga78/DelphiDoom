{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsConfirmState of OpenXcom (the         }
{  question "keep the video options?" with a countdown)                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsConfirmState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf;

type
  /// <summary>
  ///   After a change of the video options: Yes keeps them, No (or 15 seconds without an answer) goes back to the
  ///   old ones
  /// </summary>
  TXcomOptionsConfirmState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FNavigator: IXcomOptionsNavigator;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtTimer: TXcomText;
    FTimer: TXcomTimer;
    FCountdown: Integer;
    procedure DoCountdown;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    destructor Destroy; override;
    procedure Think; override;
    property Countdown: Integer read FCountdown;
  end;

implementation

uses
  DelphiDoom.XcomMenu.BattlescapeTheme,
  DelphiDoom.XcomEngine.Screen;

constructor TXcomOptionsConfirmState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FNavigator := ANavigator;
  FCountdown := 15;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 216, 100, 52, 50, wpBoth);
  FBtnYes := TXcomTextButton.Create(50, 20, 70, 120);
  FBtnNo := TXcomTextButton.Create(50, 20, 200, 120);
  FTxtTitle := TXcomText.Create(206, 20, 57, 70);
  FTxtTimer := TXcomText.Create(206, 20, 57, 100);
  FTimer := TXcomTimer.Create(Host.Clock, 1000);
  SetInterface('optionsMenu', False, True);
  Add(FWindow, 'confirmVideo', 'optionsMenu');
  Add(FBtnYes, 'confirmVideo', 'optionsMenu');
  Add(FBtnNo, 'confirmVideo', 'optionsMenu');
  Add(FTxtTitle, 'confirmVideo', 'optionsMenu');
  Add(FTxtTimer, 'confirmVideo', 'optionsMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  // no keyboard shortcuts, to make sure the user sees the message
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr('STR_DISPLAY_OPTIONS_CONFIRM'));
  FTxtTimer.SetAlign(haCenter);
  FTxtTimer.SetWordWrap(True);
  FTxtTimer.SetText(Tr('STR_DISPLAY_OPTIONS_REVERT').Arg(FCountdown));
  FTimer.OnTimerState(
    procedure
    begin
      DoCountdown;
    end);
  FTimer.Start;
  if FOrigin = ooBattlescape then
    TXcomBattlescapeTheme.Apply(Self);
end;

destructor TXcomOptionsConfirmState.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomOptionsConfirmState.Think;
begin
  inherited Think;
  FTimer.Think(True, False,
    function: Boolean
    begin
      Result := Host.IsState(Self);
    end);
end;

procedure TXcomOptionsConfirmState.DoCountdown;
begin
  Dec(FCountdown);
  FTxtTimer.SetText(Tr('STR_DISPLAY_OPTIONS_REVERT').Arg(Format('%.2d', [FCountdown])));
  if FCountdown = 0 then
    NoClick(nil);
end;

procedure TXcomOptionsConfirmState.YesClick(AAction: TXcomAction);
begin
  Host.PopState;
  FNavigator.Restart(FOrigin, Host);
end;

procedure TXcomOptionsConfirmState.NoClick(AAction: TXcomAction);
begin
  Host.Options.SwitchDisplay;
  TXcomScreen.UpdateScale(Host.Options, Host.Options.BattlescapeScale, Host.Options.BaseXBattlescape,
    Host.Options.BaseYBattlescape, FOrigin = ooBattlescape);
  TXcomScreen.UpdateScale(Host.Options, Host.Options.GeoscapeScale, Host.Options.BaseXGeoscape,
    Host.Options.BaseYGeoscape, FOrigin <> ooBattlescape);
  if (Host.OptionsStore <> nil) then
    Host.OptionsStore.Save(Host.Options);
  Host.Screen.ResetDisplay;
  Host.PopState;
  FNavigator.Restart(FOrigin, Host);
end;

end.
