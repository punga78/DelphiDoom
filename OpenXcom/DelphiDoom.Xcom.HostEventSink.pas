{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the events of the window as the events of the game      }
{  What the SDL event loop gave: SDL 1.2 key codes, modifiers and buttons       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostEventSink;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGameHostEventSink that puts the events of the window of Libs\GameHost in the queue of the game, as SDL 1.2
  ///   made them: the key is an SDLKey (a key without a name of its own is the lower case ASCII of what it types),
  ///   a turn of the wheel is a press and a release of button 4 or 5 where the mouse of the game is
  /// </summary>
  TXcomHostEventSink = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FEvents: TXcomQueueEventSource;
    class function ModifiersOf(AModifiers: TGameHostModifiers): Integer; static;
    procedure Enqueue(var AEvent: TXcomInputEvent; const ASource: TGameHostEvent);
    procedure PostKeyDown(const AEvent: TGameHostEvent);
    procedure PostKeyUp(const AEvent: TGameHostEvent);
    procedure PostMouse(AKind: TXcomEventKind; const AEvent: TGameHostEvent);
    procedure PostWheel(const AEvent: TGameHostEvent);
    procedure PostActive(const AEvent: TGameHostEvent);
    procedure PostResize(const AEvent: TGameHostEvent);
  public
    /// <param name="AEvents">The queue of the game; not owned</param>
    constructor Create(AEvents: TXcomQueueEventSource);
    procedure Post(const AEvent: TGameHostEvent);
    /// <summary>The SDLKey of SDL 1.2 of a virtual key of Windows that has a name of its own; 0 for the others</summary>
    class function KeyOf(AVirtualKey: Integer): Integer; static;
  end;

implementation

constructor TXcomHostEventSink.Create(AEvents: TXcomQueueEventSource);
begin
  inherited Create;
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FEvents := AEvents;
end;

class function TXcomHostEventSink.KeyOf(AVirtualKey: Integer): Integer;
begin
  // SDLK of SDL 1.2: letters are the lower case ASCII, the function keys 282 on
  case AVirtualKey of
    VK_BACK: Result := 8;
    VK_TAB: Result := 9;
    VK_RETURN: Result := 13;
    VK_ESCAPE: Result := 27;
    VK_SPACE: Result := 32;
    VK_DELETE: Result := 127;
    VK_UP: Result := 273;
    VK_DOWN: Result := 274;
    VK_RIGHT: Result := 275;
    VK_LEFT: Result := 276;
    VK_INSERT: Result := 277;
    VK_HOME: Result := 278;
    VK_END: Result := 279;
    VK_PRIOR: Result := 280;
    VK_NEXT: Result := 281;
    VK_F1..VK_F12: Result := 282 + AVirtualKey - VK_F1;
    Ord('0')..Ord('9'): Result := AVirtualKey;
    Ord('A')..Ord('Z'): Result := AVirtualKey + 32;
  else
    Result := 0;
  end;
end;

class function TXcomHostEventSink.ModifiersOf(AModifiers: TGameHostModifiers): Integer;
begin
  Result := 0;
  if hmShift in AModifiers then
    Result := Result or XCOM_KMOD_SHIFT;
  if hmControl in AModifiers then
    Result := Result or XCOM_KMOD_CTRL;
  if hmAlt in AModifiers then
    Result := Result or XCOM_KMOD_ALT;
end;

procedure TXcomHostEventSink.Enqueue(var AEvent: TXcomInputEvent; const ASource: TGameHostEvent);
begin
  AEvent.Modifiers := ModifiersOf(ASource.Modifiers);
  FEvents.SetModifiers(AEvent.Modifiers);
  FEvents.Enqueue(AEvent);
end;

procedure TXcomHostEventSink.PostKeyDown(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := KeyOf(AEvent.VirtualKey);
  LEvent.Character := AEvent.Character;
  // SDL 1.2: the key of a printable character without a name of its own is its lower case ASCII code
  if (LEvent.Key = 0) and (LEvent.Character >= 32) and (LEvent.Character < 127) then
    LEvent.Key := Ord(LowerCase(string(Char(LEvent.Character)))[1]);
  if (LEvent.Key <> 0) or (LEvent.Character <> 0) then
    Enqueue(LEvent, AEvent);
end;

procedure TXcomHostEventSink.PostKeyUp(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyUp);
  LEvent.Key := KeyOf(AEvent.VirtualKey);
  if LEvent.Key <> 0 then
    Enqueue(LEvent, AEvent);
end;

procedure TXcomHostEventSink.PostMouse(AKind: TXcomEventKind; const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  case AEvent.Button of
    hmbLeft: LEvent.Button := XCOM_BUTTON_LEFT;
    hmbMiddle: LEvent.Button := XCOM_BUTTON_MIDDLE;
    hmbRight: LEvent.Button := XCOM_BUTTON_RIGHT;
  end;
  LEvent.X := AEvent.X;
  LEvent.Y := AEvent.Y;
  Enqueue(LEvent, AEvent);
end;

procedure TXcomHostEventSink.PostWheel(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  // The wheel has no position of its own: it turns where the mouse of the game is, which is already in the
  // coordinates of the picture (it must not be scaled again when the picture is stretched at full screen)
  FEvents.MouseState(LX, LY);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  if AEvent.WheelDelta > 0 then
    LEvent.Button := XCOM_BUTTON_WHEELUP
  else
    LEvent.Button := XCOM_BUTTON_WHEELDOWN;
  LEvent.X := LX;
  LEvent.Y := LY;
  Enqueue(LEvent, AEvent);
  LEvent.Kind := ekMouseUp;
  Enqueue(LEvent, AEvent);
end;

procedure TXcomHostEventSink.PostActive(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  // SDL_ACTIVEEVENT: Key is 1 with the focus, Button is 1 when the window is minimized (pauseMode tells the two
  // apart)
  LEvent := TXcomInputEvent.Make(ekActive);
  LEvent.Key := Ord(AEvent.Focused);
  LEvent.Button := Ord(AEvent.Minimized);
  Enqueue(LEvent, AEvent);
end;

procedure TXcomHostEventSink.PostResize(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  // SDL_VIDEORESIZE; the modifiers of the queue are not touched
  LEvent := TXcomInputEvent.Make(ekResize);
  LEvent.X := AEvent.X;
  LEvent.Y := AEvent.Y;
  FEvents.Enqueue(LEvent);
end;

procedure TXcomHostEventSink.Post(const AEvent: TGameHostEvent);
var
  LEvent: TXcomInputEvent;
begin
  case AEvent.Kind of
    hekQuit:
      begin
        LEvent := TXcomInputEvent.Make(ekQuit);
        Enqueue(LEvent, AEvent);
      end;
    hekKeyDown:
      PostKeyDown(AEvent);
    hekKeyUp:
      PostKeyUp(AEvent);
    hekMouseMotion:
      PostMouse(ekMouseMotion, AEvent);
    hekMouseDown:
      PostMouse(ekMouseDown, AEvent);
    hekMouseUp:
      PostMouse(ekMouseUp, AEvent);
    hekMouseWheel:
      PostWheel(AEvent);
    hekActive:
      PostActive(AEvent);
    hekResize:
      PostResize(AEvent);
  end;
end;

end.
