{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the poller                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.Poller;

interface

uses
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Once for every tic it reads the keyboard, the mouse and the joystick and posts the
  ///   events of what changed: a key goes down or up, the mouse moved, the joystick is not
  ///   where it was at the start. After a focus change it waits a number of tics before it
  ///   listens again
  /// </summary>
  TInputPoller = class(TInterfacedObject, IInputPoller)
  public
    const
      /// <summary>About half a second</summary>
      IGNORE_TICS = 15;
  private
    FKeyboard: IKeyboardDevice;
    FMouse: IMouseDevice;
    FJoystick: IJoystickDevice;
    FGate: IInputGate;
    FScreen: IScreenSize;
    FKeyMap: IKeyMap;
    FSink: IInputEventSink;
    FLog: ILog;
    FJoystickButtonMask: Cardinal;
    FIgnoreTics: Integer;
    FCurrentKeys: TKeyStates;
    FOldKeys: TKeyStates;
    FMouseLastX: Integer;
    FMouseLastY: Integer;
    FMouseButtons: Integer;
    FJoystickPresent: Boolean;
    FJoystickX: Integer;
    FJoystickY: Integer;
    FInitialized: Boolean;
    procedure ResetMouse;
    procedure PostKeys;
    procedure PostMouse;
    procedure PostJoystick;
    procedure PostKey(AKind: TInputEventKind; AKey: Integer);
  public
    /// <param name="AJoystickButtons">How many buttons of the joystick are used, the first ones</param>
    constructor Create(const AKeyboard: IKeyboardDevice; const AMouse: IMouseDevice;
      const AJoystick: IJoystickDevice; const AGate: IInputGate; const AScreen: IScreenSize;
      const AKeyMap: IKeyMap; const ASink: IInputEventSink; const ALog: ILog;
      AJoystickButtons: Integer);
    procedure Initialize;
    procedure Shutdown;
    procedure Process;
    procedure Synchronize(AActive: Boolean);
    procedure SetMouseClicks(AValue: Integer);
    function IsCapsLockOn: Boolean;
    function IsInitialized: Boolean;
  end;

implementation

const
  SKeyboardInitialized = ' Keyboard initialized'#13#10;
  SMouseInitialized = ' Mouse initialized'#13#10;
  SJoystickInitialized = ' Joystick initialized'#13#10;
  SJoystickNotFound = ' Joystick not found'#13#10;

{ TInputPoller }

constructor TInputPoller.Create(const AKeyboard: IKeyboardDevice; const AMouse: IMouseDevice;
  const AJoystick: IJoystickDevice; const AGate: IInputGate; const AScreen: IScreenSize;
  const AKeyMap: IKeyMap; const ASink: IInputEventSink; const ALog: ILog;
  AJoystickButtons: Integer);
begin
  inherited Create;
  FKeyboard := AKeyboard;
  FMouse := AMouse;
  FJoystick := AJoystick;
  FGate := AGate;
  FScreen := AScreen;
  FKeyMap := AKeyMap;
  FSink := ASink;
  FLog := ALog;
  FJoystickButtonMask := (Cardinal(1) shl AJoystickButtons) - 1;
end;

procedure TInputPoller.ResetMouse;
begin
  FMouseLastX := FScreen.Width div 2;
  FMouseLastY := FScreen.Height div 2;
  FMouse.SetPosition(FMouseLastX, FMouseLastY);
  FMouseButtons := 0;
end;

procedure TInputPoller.Initialize;
var
  LReading: TJoystickReading;
begin
  FIgnoreTics := 0;
  FMouse.Initialize;
  FKeyboard.Initialize;
  FillChar(FCurrentKeys, SizeOf(FCurrentKeys), 0);
  FillChar(FOldKeys, SizeOf(FOldKeys), 0);
  if Assigned(FLog) then
    FLog.Info(SKeyboardInitialized);

  ResetMouse;
  if Assigned(FLog) then
    FLog.Info(SMouseInitialized);

  FJoystickPresent := FJoystick.Initialize;
  if FJoystickPresent then
  begin
    // the position at the start is the centre: the events tell how far it is from there
    if FJoystick.Read(LReading) then
    begin
      FJoystickX := LReading.X;
      FJoystickY := LReading.Y;
    end;
    if Assigned(FLog) then
      FLog.Info(SJoystickInitialized);
  end
  else if Assigned(FLog) then
    FLog.Info(SJoystickNotFound);
  FInitialized := True;
end;

procedure TInputPoller.Shutdown;
begin
  if not FInitialized then
    Exit;
  FInitialized := False;
  FKeyboard.Shutdown;
  FJoystick.Shutdown;
  FMouse.Shutdown;
end;

procedure TInputPoller.PostKey(AKind: TInputEventKind; AKey: Integer);
var
  LEvent: TInputEvent;
begin
  LEvent.Kind := AKind;
  LEvent.Data1 := AKey;
  LEvent.Data2 := 0;
  LEvent.Data3 := 0;
  FSink.Post(LEvent);
end;

procedure TInputPoller.PostKeys;
var
  LIndex: Integer;
  LKind: TInputEventKind;
  LKey: Integer;
begin
  for LIndex := 0 to KEYSTATE_COUNT - 1 do
  begin
    if (FOldKeys[LIndex] and KEYSTATE_DOWN) = (FCurrentKeys[LIndex] and KEYSTATE_DOWN) then
      Continue;

    if (FCurrentKeys[LIndex] and KEYSTATE_DOWN) <> 0 then
      LKind := TInputEventKind.KeyDown
    else
      LKind := TInputEventKind.KeyUp;

    LKey := FKeyMap.Translate(LIndex);
    if LKey <> 0 then
      PostKey(LKind, LKey);

    LKey := FKeyMap.TranslateModifier(LIndex);
    if LKey <> 0 then
      PostKey(LKind, LKey);
  end;

  FOldKeys := FCurrentKeys;
end;

procedure TInputPoller.PostMouse;
var
  LEvent: TInputEvent;
  LX: Integer;
  LY: Integer;
begin
  if FMouse.IsButtonDown(TMouseButton.Left) then
    FMouseButtons := FMouseButtons or MOUSEBUTTON_LEFT;
  if FMouse.IsButtonDown(TMouseButton.Right) then
    FMouseButtons := FMouseButtons or MOUSEBUTTON_RIGHT;
  if FMouse.IsButtonDown(TMouseButton.Middle) then
    FMouseButtons := FMouseButtons or MOUSEBUTTON_MIDDLE;

  FMouse.GetPosition(LX, LY);

  LEvent.Kind := TInputEventKind.Mouse;
  LEvent.Data1 := FMouseButtons;
  LEvent.Data2 := FMouseLastX - LX;
  LEvent.Data3 := FMouseLastY - LY;
  FSink.Post(LEvent);

  ResetMouse;
end;

procedure TInputPoller.PostJoystick;
var
  LReading: TJoystickReading;
  LEvent: TInputEvent;
begin
  if not FJoystick.Read(LReading) then
    Exit;

  LEvent.Kind := TInputEventKind.Joystick;
  if LReading.ButtonCount > 0 then
    LEvent.Data1 := Integer(LReading.Buttons and FJoystickButtonMask)
  else
    LEvent.Data1 := 0;
  LEvent.Data2 := LReading.X - FJoystickX;
  LEvent.Data3 := LReading.Y - FJoystickY;
  FSink.Post(LEvent);
end;

procedure TInputPoller.Process;
begin
  if not FInitialized then
    Exit;

  if FIgnoreTics > 0 then
  begin
    Dec(FIgnoreTics);
    Exit;
  end;

  if not FGate.IsInputAllowed then
    Exit;

  if not FKeyboard.ReadState(FCurrentKeys) then
    Exit;

  PostKeys;
  PostMouse;

  if FJoystickPresent then
    PostJoystick;
end;

procedure TInputPoller.Synchronize(AActive: Boolean);
begin
  if not FInitialized then
    Exit;

  if AActive then
    FIgnoreTics := IGNORE_TICS;
  FKeyboard.SetActive(AActive);
end;

procedure TInputPoller.SetMouseClicks(AValue: Integer);
begin
  if AValue > 0 then
    FMouseButtons := FMouseButtons or AValue
  else
    FMouseButtons := FMouseButtons and not (-AValue);
end;

function TInputPoller.IsCapsLockOn: Boolean;
begin
  Result := FInitialized and FKeyboard.IsCapsLockOn;
end;

function TInputPoller.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

end.
