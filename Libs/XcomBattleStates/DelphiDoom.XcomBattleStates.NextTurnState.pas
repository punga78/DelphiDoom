{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screen between two turns   }
{  (NextTurnState: "Turn 2 - Side: X-Com - Press button to continue")           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.NextTurnState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomBattleStates.BattlescapeState;

type
  /// <summary>
  ///   Hides the battle while the side changes and waits for a key or a click (or half a second with
  ///   Options::skipNextTurnScreen). When it closes, a battle without aliens or without soldiers is over; otherwise
  ///   the camera goes to the selected unit. Not ported: the autosave
  /// </summary>
  TXcomNextTurnState = class(TXcomState)
  strict private
    FParent: TXcomBattlescapeState;
    FWindow: TXcomWindow;
    FTxtTitle, FTxtTurn, FTxtSide, FTxtMessage: TXcomText;
    FBackground: TXcomWidget;
    FTimer: TXcomTimer;
    FClosed: Boolean;
    procedure Close;
  public
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
    destructor Destroy; override;
    procedure Handle(AAction: TXcomAction); override;
    procedure Think; override;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomUi.Types, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.SavedBattleGame;

const
  NEXT_TURN_DELAY = 500;
  MUST_DESTROY = 14;

constructor TXcomNextTurnState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
var
  LY: Integer;
  LBattle: TXcomSavedBattleGame;
  LTurn: string;
  LElement: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
  LSide: string;
begin
  inherited Create(AHost);
  FParent := AParent;
  LBattle := AParent.Session.Battle;
  LY := AParent.Map.MessageY;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TXcomText.Create(320, 17, 0, 68);
  FTxtTurn := TXcomText.Create(320, 17, 0, 92);
  FTxtSide := TXcomText.Create(320, 17, 0, 108);
  FTxtMessage := TXcomText.Create(320, 17, 0, 132);
  // the C++ makes it as high as the screen is wide
  FBackground := TXcomWidget.Create(Host.Screen.Width, Host.Screen.Width, 0, 0);
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(AParent.Session.Graphics.Palette(LBattle.Depth), 0, 256);
  Add(FBackground);
  Add(FWindow);
  Add(FTxtTitle, 'messageWindows', 'battlescape');
  Add(FTxtTurn, 'messageWindows', 'battlescape');
  Add(FTxtSide, 'messageWindows', 'battlescape');
  Add(FTxtMessage, 'messageWindows', 'battlescape');
  CenterAllSurfaces;
  FBackground.X := 0;
  FBackground.Y := 0;
  FBackground.DrawRect(0, 0, FBackground.Width, FBackground.Height, 15);
  // make this screen line up with the hidden movement screen
  FWindow.Y := LY;
  FTxtTitle.Y := LY + 68;
  FTxtTurn.Y := LY + 92;
  FTxtSide.Y := LY + 108;
  FTxtMessage.Y := LY + 132;
  // Palette::blockOffset(0) - 1 as a Uint8
  FWindow.SetColor(255);
  FWindow.SetHighContrast(True);
  FWindow.SetBackground(AParent.Session.Graphics.Surface('TAC00.SCR'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetHighContrast(True);
  FTxtTitle.SetText(Tr('STR_OPENXCOM').Text);
  FTxtTurn.SetBig;
  FTxtTurn.SetAlign(haCenter);
  FTxtTurn.SetHighContrast(True);
  LTurn := Tr('STR_TURN').Arg(LBattle.Turn).Text;
  if LBattle.TurnLimit > 0 then
  begin
    LTurn := LTurn + '/' + IntToStr(LBattle.TurnLimit);
    // the "over weight" color of the inventory for the last three turns
    LInterface := Host.Resources.GetInterface('inventory');
    if (LBattle.TurnLimit - LBattle.Turn <= 3) and Assigned(LInterface) and
      LInterface.TryGetElement('weight', LElement) then
      FTxtTurn.SetColor(Byte(LElement.Color2));
  end;
  FTxtTurn.SetText(LTurn);
  FTxtSide.SetBig;
  FTxtSide.SetAlign(haCenter);
  FTxtSide.SetHighContrast(True);
  if LBattle.Side = FACTION_PLAYER then
    LSide := Tr('STR_XCOM').Text
  else
    LSide := Tr('STR_ALIENS').Text;
  FTxtSide.SetText(Tr('STR_SIDE').Arg(LSide).Text);
  FTxtMessage.SetBig;
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetHighContrast(True);
  FTxtMessage.SetText(Tr('STR_PRESS_BUTTON_TO_CONTINUE').Text);
  if Host.Options.GetBool('skipNextTurnScreen') then
  begin
    FTimer := TXcomTimer.Create(Host.Clock, NEXT_TURN_DELAY);
    FTimer.OnTimerState(Close);
    FTimer.Start;
  end;
end;

destructor TXcomNextTurnState.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomNextTurnState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekKeyDown) or (AAction.Details.Kind = ekMouseDown) then
    Close;
end;

procedure TXcomNextTurnState.Think;
begin
  if Assigned(FTimer) then
    FTimer.Think(True, False);
end;

procedure TXcomNextTurnState.Close;
var
  LLiveAliens: Integer;
  LLiveSoldiers: Integer;
  LParent: TXcomBattlescapeState;
  LFrequency: Integer;
begin
  if FClosed then
    Exit;
  FClosed := True;
  LFrequency := Host.Options.GetValue('autosaveFrequency');
  // this state is freed by the game after the pop: nothing of it is touched afterwards
  LParent := FParent;
  Host.PopState;
  LParent.Game.TallyUnits(LLiveAliens, LLiveSoldiers);
  // not the final mission and all aliens dead
  if ((LParent.Session.Battle.ObjectiveType <> MUST_DESTROY) and (LLiveAliens = 0)) or (LLiveSoldiers = 0) then
    LParent.FinishBattle(False, LLiveSoldiers)
  else
  begin
    LParent.CenterOnSelectedUnit;
    // autosave every set amount of turns
    if (LParent.Session.Battle.Side = FACTION_PLAYER) and ((LParent.Session.Battle.Turn = 1) or
      ((LFrequency > 0) and (LParent.Session.Battle.Turn mod LFrequency = 0))) then
      LParent.Autosave;
  end;
end;

end.
