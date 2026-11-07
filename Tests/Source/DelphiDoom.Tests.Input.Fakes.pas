{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the input library - the fake devices                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.Fakes;

interface

uses
  System.Types, System.Generics.Collections, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>Every call is written in a shared list of calls, to see the order</summary>
  TFakeKeyboard = class(TInterfacedObject, IKeyboardDevice)
  public
    Keys: TKeyStates;
    Available: Boolean;
    Caps: Boolean;
    Active: Integer; // -1 never told, 0 inactive, 1 active
    Calls: TList<string>;
    constructor Create(const ACalls: TList<string>);
    procedure Initialize;
    procedure Shutdown;
    function ReadState(var AStates: TKeyStates): Boolean;
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

  TFakeMouse = class(TInterfacedObject, IMouseDevice)
  public
    X: Integer;
    Y: Integer;
    Buttons: array[TMouseButton] of Boolean;
    Placed: TList<TPoint>;
    Calls: TList<string>;
    constructor Create(const ACalls: TList<string>);
    destructor Destroy; override;
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

  TFakeJoystick = class(TInterfacedObject, IJoystickDevice)
  public
    Present: Boolean;
    Reading: TJoystickReading;
    Calls: TList<string>;
    constructor Create(const ACalls: TList<string>);
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

  TFakeGate = class(TInterfacedObject, IInputGate)
  public
    Allowed: Boolean;
    function IsInputAllowed: Boolean;
  end;

  TFakeScreen = class(TInterfacedObject, IScreenSize)
  public
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

  /// <summary>Key k becomes k + 1000; the modifier 16 (shift) is also 5000</summary>
  TFakeKeyMap = class(TInterfacedObject, IKeyMap)
  public
    function Translate(AVirtualKey: Integer): Integer;
    function TranslateModifier(AVirtualKey: Integer): Integer;
  end;

  TFakeSink = class(TInterfacedObject, IInputEventSink)
  public
    Events: TList<TInputEvent>;
    constructor Create;
    destructor Destroy; override;
    procedure Post(const AEvent: TInputEvent);
  end;

  /// <summary>The calls of the system, written as text in a list; the answers are fields</summary>
  TFakeInputSystem = class(TInterfacedObject, IKeyboardSystem, ICursorSystem, IJoystickSystem)
  public
    Calls: TList<string>;
    Keys: TKeyStates;
    KeyboardAccepted: Boolean;
    KeyStates: array[0..255] of SmallInt;
    CursorX: Integer;
    CursorY: Integer;
    Devices: Cardinal;
    CaptureAccepted: Boolean;
    CapturedWindow: THandle;
    Reading: TJoystickReading;
    ReadingAvailable: Boolean;
    constructor Create;
    destructor Destroy; override;
    function ReadKeyboardState(var AStates: TKeyStates): Boolean;
    function GetKeyState(AVirtualKey: Integer): SmallInt;
    procedure Open;
    procedure Close;
    function GetCursorPosition(out AX, AY: Integer): Boolean;
    function SetCursorPosition(AX, AY: Integer): Boolean;
    function DeviceCount: Cardinal;
    function Capture(AWindow: THandle): Boolean;
    procedure Release;
    function ReadPosition(out AReading: TJoystickReading): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TFakeInputSystem }

constructor TFakeInputSystem.Create;
begin
  inherited Create;
  Calls := TList<string>.Create;
  KeyboardAccepted := True;
end;

destructor TFakeInputSystem.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

function TFakeInputSystem.ReadKeyboardState(var AStates: TKeyStates): Boolean;
begin
  Calls.Add('keyboardstate');
  AStates := Keys;
  Result := KeyboardAccepted;
end;

function TFakeInputSystem.GetKeyState(AVirtualKey: Integer): SmallInt;
begin
  Calls.Add(Format('keystate %d', [AVirtualKey]));
  Result := KeyStates[AVirtualKey];
end;

procedure TFakeInputSystem.Open;
begin
  Calls.Add('open');
end;

procedure TFakeInputSystem.Close;
begin
  Calls.Add('close');
end;

function TFakeInputSystem.GetCursorPosition(out AX, AY: Integer): Boolean;
begin
  AX := CursorX;
  AY := CursorY;
  Result := True;
end;

function TFakeInputSystem.SetCursorPosition(AX, AY: Integer): Boolean;
begin
  Calls.Add(Format('setcursor %d %d', [AX, AY]));
  Result := True;
end;

function TFakeInputSystem.DeviceCount: Cardinal;
begin
  Result := Devices;
end;

function TFakeInputSystem.Capture(AWindow: THandle): Boolean;
begin
  Calls.Add('capture');
  CapturedWindow := AWindow;
  Result := CaptureAccepted;
end;

procedure TFakeInputSystem.Release;
begin
  Calls.Add('release');
end;

function TFakeInputSystem.ReadPosition(out AReading: TJoystickReading): Boolean;
begin
  AReading := Reading;
  Result := ReadingAvailable;
end;

{ TFakeKeyboard }

constructor TFakeKeyboard.Create(const ACalls: TList<string>);
begin
  inherited Create;
  Calls := ACalls;
  Available := True;
  Active := -1;
end;

procedure TFakeKeyboard.Initialize;
begin
  Calls.Add('keyboard.initialize');
end;

procedure TFakeKeyboard.Shutdown;
begin
  Calls.Add('keyboard.shutdown');
end;

function TFakeKeyboard.ReadState(var AStates: TKeyStates): Boolean;
begin
  Result := Available;
  if Result then
    AStates := Keys;
end;

procedure TFakeKeyboard.SetActive(AActive: Boolean);
begin
  Active := Ord(AActive);
end;

function TFakeKeyboard.IsCapsLockOn: Boolean;
begin
  Result := Caps;
end;

{ TFakeMouse }

constructor TFakeMouse.Create(const ACalls: TList<string>);
begin
  inherited Create;
  Calls := ACalls;
  Placed := TList<TPoint>.Create;
end;

destructor TFakeMouse.Destroy;
begin
  Placed.Free;
  inherited Destroy;
end;

procedure TFakeMouse.Initialize;
begin
  Calls.Add('mouse.initialize');
end;

procedure TFakeMouse.Shutdown;
begin
  Calls.Add('mouse.shutdown');
end;

procedure TFakeMouse.GetPosition(out AX, AY: Integer);
begin
  AX := X;
  AY := Y;
end;

procedure TFakeMouse.SetPosition(AX, AY: Integer);
begin
  Placed.Add(Point(AX, AY));
end;

function TFakeMouse.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  Result := Buttons[AButton];
end;

{ TFakeJoystick }

constructor TFakeJoystick.Create(const ACalls: TList<string>);
begin
  inherited Create;
  Calls := ACalls;
end;

function TFakeJoystick.Initialize: Boolean;
begin
  Calls.Add('joystick.initialize');
  Result := Present;
end;

procedure TFakeJoystick.Shutdown;
begin
  Calls.Add('joystick.shutdown');
end;

function TFakeJoystick.Read(out AReading: TJoystickReading): Boolean;
begin
  AReading := Reading;
  Result := True;
end;

{ TFakeGate }

function TFakeGate.IsInputAllowed: Boolean;
begin
  Result := Allowed;
end;

{ TFakeScreen }

function TFakeScreen.GetWidth: Integer;
begin
  Result := 640;
end;

function TFakeScreen.GetHeight: Integer;
begin
  Result := 400;
end;

{ TFakeKeyMap }

function TFakeKeyMap.Translate(AVirtualKey: Integer): Integer;
begin
  if AVirtualKey = 99 then
    Result := 0
  else
    Result := AVirtualKey + 1000;
end;

function TFakeKeyMap.TranslateModifier(AVirtualKey: Integer): Integer;
begin
  if AVirtualKey = 16 then
    Result := 5000
  else
    Result := 0;
end;

{ TFakeSink }

constructor TFakeSink.Create;
begin
  inherited Create;
  Events := TList<TInputEvent>.Create;
end;

destructor TFakeSink.Destroy;
begin
  Events.Free;
  inherited Destroy;
end;

procedure TFakeSink.Post(const AEvent: TInputEvent);
begin
  Events.Add(AEvent);
end;

end.
