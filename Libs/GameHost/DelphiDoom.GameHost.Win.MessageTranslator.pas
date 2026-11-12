{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the messages of a window as input events     }
{  Derived from the window of Xcom32 (OpenXcom, the OpenXcom Developers),       }
{  GPL v3 or later: see Libs\XcomFormats\README.md for the license of this unit }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.MessageTranslator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Types, System.SysUtils, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   Turns the keyboard, mouse, focus, close and size messages of a window into events and gives them to the
  ///   sink. It has no window: the window procedure gives it each message with the state of the window at that
  ///   moment, so that it is tested with made up messages
  /// </summary>
  TGameHostWinMessageTranslator = class
  strict private
    FEvents: IGameHostEventSink;
    FKeyboard: IGameHostKeyboard;
    procedure PostKey(AKind: TGameHostEventKind; AWParam: WPARAM; ALParam: LPARAM);
    procedure PostMouse(AKind: TGameHostEventKind; AButton: TGameHostMouseButton; ALParam: LPARAM;
      const AState: TGameHostWindowState);
    procedure PostWheel(AWParam: WPARAM);
    procedure PostActive(AWParam: WPARAM);
    procedure PostResize(AWParam: WPARAM; ALParam: LPARAM; const AState: TGameHostWindowState);
  public
    constructor Create(const AEvents: IGameHostEventSink; const AKeyboard: IGameHostKeyboard);
    /// <summary>
    ///   Posts the events of the message. True when the message is done and AResult is what the window procedure
    ///   answers; false when the default procedure of Windows must still see it (the system keys, the focus, the
    ///   size and every message that is not an input)
    /// </summary>
    function Translate(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM; const AState: TGameHostWindowState;
      out AResult: LRESULT): Boolean;
  end;

implementation

uses
  DelphiDoom.GameHost.PictureLayout;

constructor TGameHostWinMessageTranslator.Create(const AEvents: IGameHostEventSink;
  const AKeyboard: IGameHostKeyboard);
begin
  inherited Create;
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AKeyboard) then
    raise EArgumentNilException.Create('AKeyboard');
  FEvents := AEvents;
  FKeyboard := AKeyboard;
end;

procedure TGameHostWinMessageTranslator.PostKey(AKind: TGameHostEventKind; AWParam: WPARAM; ALParam: LPARAM);
var
  LEvent: TGameHostEvent;
begin
  LEvent := TGameHostEvent.Make(AKind);
  LEvent.VirtualKey := Integer(AWParam);
  if AKind = hekKeyDown then
    LEvent.Character := FKeyboard.CharacterOf(Cardinal(AWParam), (Cardinal(ALParam) shr 16) and $FF);
  LEvent.Modifiers := FKeyboard.Modifiers;
  FEvents.Post(LEvent);
end;

procedure TGameHostWinMessageTranslator.PostMouse(AKind: TGameHostEventKind; AButton: TGameHostMouseButton;
  ALParam: LPARAM; const AState: TGameHostWindowState);
var
  LEvent: TGameHostEvent;
  LPoint: TPoint;
begin
  LEvent := TGameHostEvent.Make(AKind);
  LEvent.Button := AButton;
  LEvent.Modifiers := FKeyboard.Modifiers;
  // the position of a mouse message is signed: the mouse can be captured outside the window
  LPoint := TGameHostPictureLayout.ToPicture(AState, SmallInt(LoWord(ALParam)), SmallInt(HiWord(ALParam)));
  LEvent.X := LPoint.X;
  LEvent.Y := LPoint.Y;
  FEvents.Post(LEvent);
end;

procedure TGameHostWinMessageTranslator.PostWheel(AWParam: WPARAM);
var
  LEvent: TGameHostEvent;
begin
  // The position of a wheel message is in screen coordinates and is not given: the game knows where its mouse
  // is, already in the coordinates of the picture
  LEvent := TGameHostEvent.Make(hekMouseWheel);
  LEvent.WheelDelta := SmallInt(HiWord(AWParam));
  LEvent.Modifiers := FKeyboard.Modifiers;
  FEvents.Post(LEvent);
end;

procedure TGameHostWinMessageTranslator.PostActive(AWParam: WPARAM);
var
  LEvent: TGameHostEvent;
begin
  LEvent := TGameHostEvent.Make(hekActive);
  LEvent.Minimized := HiWord(AWParam) <> 0;
  LEvent.Focused := (LoWord(AWParam) <> WA_INACTIVE) and not LEvent.Minimized;
  LEvent.Modifiers := FKeyboard.Modifiers;
  FEvents.Post(LEvent);
end;

procedure TGameHostWinMessageTranslator.PostResize(AWParam: WPARAM; ALParam: LPARAM;
  const AState: TGameHostWindowState);
var
  LEvent: TGameHostEvent;
begin
  // the player has dragged the border: not the sizes the game itself asks for
  if (not AState.Resizable) or AState.Fullscreen or AState.SettingMode or (AWParam = SIZE_MINIMIZED) then
    Exit;
  if (LoWord(ALParam) = AState.Width) and (HiWord(ALParam) = AState.Height) then
    Exit;
  LEvent := TGameHostEvent.Make(hekResize);
  LEvent.X := LoWord(ALParam);
  LEvent.Y := HiWord(ALParam);
  FEvents.Post(LEvent);
end;

function TGameHostWinMessageTranslator.Translate(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM;
  const AState: TGameHostWindowState; out AResult: LRESULT): Boolean;
var
  LEvent: TGameHostEvent;
begin
  AResult := 0;
  Result := True;
  case AMessage of
    WM_KEYDOWN, WM_SYSKEYDOWN:
      begin
        PostKey(hekKeyDown, AWParam, ALParam);
        // a system key still opens the menu of the window, closes it with Alt+F4 ...
        Result := AMessage = WM_KEYDOWN;
      end;
    WM_KEYUP, WM_SYSKEYUP:
      begin
        PostKey(hekKeyUp, AWParam, ALParam);
        Result := AMessage = WM_KEYUP;
      end;
    WM_MOUSEMOVE:
      PostMouse(hekMouseMotion, hmbNone, ALParam, AState);
    WM_LBUTTONDOWN:
      PostMouse(hekMouseDown, hmbLeft, ALParam, AState);
    WM_LBUTTONUP:
      PostMouse(hekMouseUp, hmbLeft, ALParam, AState);
    WM_MBUTTONDOWN:
      PostMouse(hekMouseDown, hmbMiddle, ALParam, AState);
    WM_MBUTTONUP:
      PostMouse(hekMouseUp, hmbMiddle, ALParam, AState);
    WM_RBUTTONDOWN:
      PostMouse(hekMouseDown, hmbRight, ALParam, AState);
    WM_RBUTTONUP:
      PostMouse(hekMouseUp, hmbRight, ALParam, AState);
    WM_MOUSEWHEEL:
      PostWheel(AWParam);
    WM_ACTIVATE:
      begin
        PostActive(AWParam);
        Result := False;
      end;
    WM_CLOSE:
      begin
        LEvent := TGameHostEvent.Make(hekQuit);
        LEvent.Modifiers := FKeyboard.Modifiers;
        FEvents.Post(LEvent);
      end;
    WM_SIZE:
      begin
        PostResize(AWParam, ALParam, AState);
        Result := False;
      end;
  else
    Result := False;
  end;
end;

end.
