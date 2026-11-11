{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - "all aliens were killed in     }
{  the crash" (AliensCrashState: a battle with no alien alive does not start)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.AliensCrashState;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>The message shown instead of the battle; OK pops it and calls AOnOk (the debriefing)</summary>
  TXcomAliensCrashState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FOnOk: TProc;
    procedure BtnOkClick(AAction: TXcomAction);
  public
    /// <param name="ABackground">TAC00.SCR (not owned); can be nil</param>
    /// <param name="AOnOk">Called after the state was popped; can be nil</param>
    constructor Create(AHost: TXcomStateHost; ABackground: TXcomSurface; const AOnOk: TProc);
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

constructor TXcomAliensCrashState.Create(AHost: TXcomStateHost; ABackground: TXcomSurface; const AOnOk: TProc);
begin
  inherited Create(AHost);
  FOnOk := AOnOk;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 154);
  FTxtTitle := TXcomText.Create(246, 80, 37, 50);
  SetPalette('PAL_BATTLESCAPE', -1);
  Add(FWindow, 'messageWindowBorder', 'battlescape');
  Add(FBtnOk, 'messageWindowButtons', 'battlescape');
  Add(FTxtTitle, 'messageWindows', 'battlescape');
  CenterAllSurfaces;
  FWindow.SetHighContrast(True);
  if Assigned(ABackground) then
    FWindow.SetBackground(ABackground);
  FBtnOk.SetHighContrast(True);
  FBtnOk.SetText(Tr('STR_OK').Text);
  FBtnOk.OnMouseClick(BtnOkClick);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyCancel);
  FTxtTitle.SetHighContrast(True);
  FTxtTitle.SetText(Tr('STR_ALL_ALIENS_KILLED_IN_CRASH').Text);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetVerticalAlign(vaMiddle);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
end;

procedure TXcomAliensCrashState.BtnOkClick(AAction: TXcomAction);
var
  LOnOk: TProc;
begin
  LOnOk := FOnOk;
  Host.PopState;
  if Assigned(LOnOk) then
    LOnOk();
end;

end.
