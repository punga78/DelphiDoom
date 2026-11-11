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
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomBattleStates.Graphics.Intf;

type
  /// <summary>
  ///   The message shown instead of the battle; OK pops it and calls AOnOk (the debriefing). The state keeps the
  ///   pictures of the battle alive: its window blits their TAC00.SCR at every redraw, and by then the session of
  ///   the battle that was not started is gone
  /// </summary>
  TXcomAliensCrashState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FGraphics: IXcomBattleGraphics;
    FOnOk: TProc;
    FNext: TXcomState;
    procedure BtnOkClick(AAction: TXcomAction);
  public
    /// <param name="AGraphics">The pictures of the battle (TAC00.SCR is the background); can be nil</param>
    /// <param name="AOnOk">Called after the state was popped; can be nil</param>
    constructor Create(AHost: TXcomStateHost; const AGraphics: IXcomBattleGraphics; const AOnOk: TProc);
    destructor Destroy; override;
    /// <summary>
    ///   The state that OK pushes (the debriefing that was made while the battle was still there). The message
    ///   owns it until then: a game that closes with the message on the screen must not leave it behind
    /// </summary>
    procedure SetNext(AState: TXcomState);
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomUi.Types;

const
  BACKGROUND_NAME = 'TAC00.SCR';

constructor TXcomAliensCrashState.Create(AHost: TXcomStateHost; const AGraphics: IXcomBattleGraphics;
  const AOnOk: TProc);
var
  LBackground: TXcomSurface;
begin
  inherited Create(AHost);
  FGraphics := AGraphics;
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
  LBackground := nil;
  if Assigned(FGraphics) then
    LBackground := FGraphics.Surface(BACKGROUND_NAME);
  if Assigned(LBackground) then
    FWindow.SetBackground(LBackground);
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

destructor TXcomAliensCrashState.Destroy;
begin
  FNext.Free;
  inherited Destroy;
end;

procedure TXcomAliensCrashState.SetNext(AState: TXcomState);
begin
  FNext.Free;
  FNext := AState;
end;

procedure TXcomAliensCrashState.BtnOkClick(AAction: TXcomAction);
var
  LOnOk: TProc;
  LNext: TXcomState;
begin
  LOnOk := FOnOk;
  LNext := FNext;
  FNext := nil;
  Host.PopState;
  if Assigned(LNext) then
    Host.PushState(LNext);
  if Assigned(LOnOk) then
    LOnOk();
end;

end.
