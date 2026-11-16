{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the events of the window as the input of the game }
{                                                                              }
{  Port of war1 (acoto87/war1), war_game.c (getWarKeyFromSDLKey and            }
{  wg_processGameEvent), (c) 2019 Alejandro Coto Gutierrez, zlib License (see  }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.EventAdapter;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Game;

type
  /// <summary>
  ///   Turns the events of a window of Framework\GameHost (IGameHostEventSink) into what wg_processGameEvent does with the
  ///   events of SDL: the position of the mouse and its buttons (left and right; the middle one is ignored), the keys
  ///   (Shift, Ctrl and Alt take their state from the modifiers of the event, not from the key that went down or up), the
  ///   characters that the keys type (SDL_EVENT_TEXT_INPUT: only the ones from 32 to 126 count in the cheat panel) and the
  ///   loss of the focus (nothing is held any more). The window gives positions already in the pixels of the picture
  /// </summary>
  TWarUiEventAdapter = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FGame: TWarUiGame;
    class function KeyOf(AVirtualKey: Integer): TWarKey; static;
  public
    /// <summary>The game is not owned</summary>
    constructor Create(const AGame: TWarUiGame);
    procedure Post(const AEvent: TGameHostEvent);
    /// <summary>getWarKeyFromSDLKey for a virtual key of Windows (wkNone for the keys the game does not use)</summary>
    class function VirtualKeyToKey(AVirtualKey: Integer): TWarKey; static;
  end;

implementation

{ TWarUiEventAdapter }

constructor TWarUiEventAdapter.Create(const AGame: TWarUiGame);
begin
  inherited Create;
  FGame := AGame;
end;

class function TWarUiEventAdapter.KeyOf(AVirtualKey: Integer): TWarKey;
begin
  Result := VirtualKeyToKey(AVirtualKey);
end;

class function TWarUiEventAdapter.VirtualKeyToKey(AVirtualKey: Integer): TWarKey;
begin
  case AVirtualKey of
    $20: Result := wkSpace;
    $DE: Result := wkApostrophe;
    $BC: Result := wkComma;
    $BD, $6D: Result := wkMinus;
    $BE, $6E: Result := wkPeriod;
    $BF, $6F: Result := wkSlash;
    $30..$39: Result := TWarKey(Ord(wk0) + AVirtualKey - $30);
    $60..$69: Result := TWarKey(Ord(wk0) + AVirtualKey - $60);
    $BA: Result := wkSemicolon;
    $BB: Result := wkEqual;
    $41..$5A: Result := TWarKey(Ord(wkA) + AVirtualKey - $41);
    $DB: Result := wkLeftBracket;
    $DC: Result := wkBackslash;
    $DD: Result := wkRightBracket;
    $C0: Result := wkGraveAccent;
    $1B: Result := wkEsc;
    $0D: Result := wkEnter;
    $09: Result := wkTab;
    $08: Result := wkBackspace;
    $2D: Result := wkInsert;
    $2E: Result := wkDelete;
    $27: Result := wkRight;
    $25: Result := wkLeft;
    $28: Result := wkDown;
    $26: Result := wkUp;
    $21: Result := wkPageUp;
    $22: Result := wkPageDown;
    $24: Result := wkHome;
    $23: Result := wkEnd;
    $70..$7B: Result := TWarKey(Ord(wkF1) + AVirtualKey - $70);
    $6A: Result := wkAsterisk;
    $6B: Result := wkPlus;
    $10, $A0, $A1: Result := wkShift;
    $11, $A2, $A3: Result := wkCtrl;
    $12, $A4, $A5: Result := wkAlt;
  else
    Result := wkNone;
  end;
end;

procedure TWarUiEventAdapter.Post(const AEvent: TGameHostEvent);
var
  LKey: TWarKey;
  LDown: Boolean;
begin
  case AEvent.Kind of
    hekQuit:
      FGame.Manager.RequestQuit;
    hekMouseMotion:
      FGame.Input.SetPosition(AEvent.X, AEvent.Y);
    hekMouseDown, hekMouseUp:
    begin
      FGame.Input.SetPosition(AEvent.X, AEvent.Y);
      LDown := AEvent.Kind = hekMouseDown;
      if AEvent.Button = hmbLeft then
        FGame.Input.SetButton(wmbLeft, LDown)
      else if AEvent.Button = hmbRight then
        FGame.Input.SetButton(wmbRight, LDown);
    end;
    hekKeyDown, hekKeyUp:
    begin
      LKey := KeyOf(AEvent.VirtualKey);
      LDown := AEvent.Kind = hekKeyDown;
      if LKey = wkShift then
        FGame.Input.SetKey(wkShift, hmShift in AEvent.Modifiers)
      else if LKey = wkCtrl then
        FGame.Input.SetKey(wkCtrl, hmControl in AEvent.Modifiers)
      else if LKey = wkAlt then
        FGame.Input.SetKey(wkAlt, hmAlt in AEvent.Modifiers)
      else if LKey <> wkNone then
        FGame.Input.SetKey(LKey, LDown);
      // the text of the key, as SDL sends it with the key
      if LDown and (AEvent.Character >= 32) and (AEvent.Character <= 126) then
        FGame.Manager.HandleTextInput(AnsiString(AnsiChar(AEvent.Character)));
    end;
    hekActive:
      if (not AEvent.Focused) or AEvent.Minimized then
      begin
        FGame.Input.ReleaseAll;
      end;
  end;
end;

end.
