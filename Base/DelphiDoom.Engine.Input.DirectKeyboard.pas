{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the keyboard read with DirectInput                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Input.DirectKeyboard;

interface

uses
  System.SysUtils,
  Windows,
  DirectX,
  DelphiDoom.Input.Types,
  DelphiDoom.Input.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The keyboard through DirectInput (usedirectinput). It was already marked as not working:
  ///   only the keys that are down are set in the table, and the table is cleared before
  /// </summary>
  TDirectKeyboard = class(TInterfacedObject, IKeyboardDevice)
  private
    FWindow: TFunc<THandle>;
    FLog: ILog;
    FDirectInput: IDirectInputA;
    FDevice: IDirectInputDevice;
    FState: TDIKeyboardState;
  public
    /// <param name="AWindow">The window that owns the keyboard, asked when the device starts</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AWindow: TFunc<THandle>; const ALog: ILog);
    procedure Initialize;
    procedure Shutdown;
    function ReadState(var AStates: TKeyStates): Boolean;
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

implementation

const
  SUsingDirectInput = ' Using DirectInput'#13#10;
  SStepFailed = 'I_InitInput(): %s failed, result = %d';
function DIKEYtoVK(Key: Byte): Integer;
begin
  result := 0;
  case Key of
    DIK_ESCAPE       : result := VK_ESCAPE;
    DIK_1            : result := Ord('1');
    DIK_2            : result := Ord('2');
    DIK_3            : result := Ord('3');
    DIK_4            : result := Ord('4');
    DIK_5            : result := Ord('5');
    DIK_6            : result := Ord('6');
    DIK_7            : result := Ord('7');
    DIK_8            : result := Ord('8');
    DIK_9            : result := Ord('9');
    DIK_0            : result := Ord('0');
    DIK_EQUALS       : result := Ord('=');
    DIK_BACK         : result := VK_BACK;
    DIK_TAB          : result := VK_TAB;
    DIK_Q            : result := Ord('Q');
    DIK_W            : result := Ord('W');
    DIK_E            : result := Ord('E');
    DIK_R            : result := Ord('R');
    DIK_T            : result := Ord('T');
    DIK_Y            : result := Ord('Y');
    DIK_U            : result := Ord('U');
    DIK_I            : result := Ord('I');
    DIK_O            : result := Ord('O');
    DIK_P            : result := Ord('P');
    DIK_LBRACKET     : result := Ord('[');
    DIK_RBRACKET     : result := Ord(']');
    DIK_RETURN       : result := VK_RETURN;
    DIK_LCONTROL     : result := VK_CONTROL;
    DIK_A            : result := Ord('A');
    DIK_S            : result := Ord('S');
    DIK_D            : result := Ord('D');
    DIK_F            : result := Ord('F');
    DIK_G            : result := Ord('G');
    DIK_H            : result := Ord('H');
    DIK_J            : result := Ord('J');
    DIK_K            : result := Ord('K');
    DIK_L            : result := Ord('L');
    DIK_SEMICOLON    : result := Ord(';');
    DIK_APOSTROPHE   : result := Ord('''');
    DIK_LSHIFT       : result := VK_SHIFT;
    DIK_BACKSLASH    : result := Ord('\');
    DIK_Z            : result := Ord('Z');
    DIK_X            : result := Ord('X');
    DIK_C            : result := Ord('C');
    DIK_V            : result := Ord('V');
    DIK_B            : result := Ord('B');
    DIK_N            : result := Ord('N');
    DIK_M            : result := Ord('M');
    DIK_COMMA        : result := Ord(',');
    DIK_PERIOD       : result := Ord('.');
    DIK_SLASH        : result := Ord('/');
    DIK_RSHIFT       : result := VK_SHIFT;
    DIK_MULTIPLY     : result := Ord('*');
    DIK_LMENU        : result := VK_MENU;
    DIK_SPACE        : result := VK_SPACE;
    DIK_CAPITAL      : result := VK_CAPITAL;
    DIK_F1           : result := VK_F1;
    DIK_F2           : result := VK_F2;
    DIK_F3           : result := VK_F3;
    DIK_F4           : result := VK_F4;
    DIK_F5           : result := VK_F5;
    DIK_F6           : result := VK_F6;
    DIK_F7           : result := VK_F7;
    DIK_F8           : result := VK_F8;
    DIK_F9           : result := VK_F9;
    DIK_F10          : result := VK_F10;
    DIK_NUMLOCK      : result := VK_NUMLOCK;
    DIK_SCROLL       : result := VK_SCROLL;
    DIK_NUMPAD7      : result := VK_NUMPAD7;
    DIK_NUMPAD8      : result := VK_NUMPAD8;
    DIK_NUMPAD9      : result := VK_NUMPAD9;
    DIK_SUBTRACT     : result := VK_SUBTRACT;
    DIK_NUMPAD4      : result := VK_NUMPAD4;
    DIK_NUMPAD5      : result := VK_NUMPAD5;
    DIK_NUMPAD6      : result := VK_NUMPAD6;
    DIK_ADD          : result := VK_ADD;
    DIK_NUMPAD1      : result := VK_NUMPAD1;
    DIK_NUMPAD2      : result := VK_NUMPAD2;
    DIK_NUMPAD3      : result := VK_NUMPAD3;
    DIK_NUMPAD0      : result := VK_NUMPAD0;
    DIK_DECIMAL      : result := VK_DECIMAL;
    DIK_F11          : result := VK_F11;
    DIK_F12          : result := VK_F12;
    DIK_NUMPADENTER  : result := VK_RETURN;
    DIK_RCONTROL     : result := VK_CONTROL;
    DIK_DIVIDE       : result := VK_DIVIDE;
    DIK_RMENU        : result := VK_MENU;
    DIK_HOME         : result := VK_HOME;
    DIK_UP           : result := VK_UP;
    DIK_PRIOR        : result := VK_PRIOR;
    DIK_LEFT         : result := VK_LEFT;
    DIK_RIGHT        : result := VK_RIGHT;
    DIK_END          : result := VK_END;
    DIK_DOWN         : result := VK_DOWN;
    DIK_NEXT         : result := VK_NEXT;
    DIK_INSERT       : result := VK_INSERT;
    DIK_DELETE       : result := VK_DELETE;
    DIK_LWIN         : result := VK_LWIN;
    DIK_RWIN         : result := VK_RWIN;
    DIK_APPS         : result := VK_APPS;
  end;
end;

{ TDirectKeyboard }

constructor TDirectKeyboard.Create(const AWindow: TFunc<THandle>; const ALog: ILog);
begin
  inherited Create;
  FWindow := AWindow;
  FLog := ALog;
end;

procedure TDirectKeyboard.Initialize;
var
  LResult: HRESULT;
  LProperty: TDIPropDWORD;

  procedure CheckStep(const AName: string);
  begin
    if LResult <> DD_OK then
      raise EInputDeviceException.CreateFmt(SStepFailed, [AName, LResult]);
  end;

begin
  // Register with the DirectInput subsystem and get a pointer to a IDirectInput interface
  LResult := DirectInputCreate(hInstance, DIRECTINPUT_VERSION, FDirectInput, nil);
  CheckStep('DirectInputCreate');

  // Obtain an interface to the keybord device
  LResult := FDirectInput.CreateDevice(GUID_SysKeyboard, FDevice, nil);
  CheckStep('CreateDevice');

  // The data format is "keyboard format": an array of 256 bytes for GetDeviceState
  LResult := FDevice.SetDataFormat(c_dfDIKeyboard);
  CheckStep('SetDataFormat');

  // DISCL_NONEXCLUSIVE: do not interfere with other applications reading the device.
  // DISCL_FOREGROUND: if the user switches away the device goes back to the system
  LResult := FDevice.SetCooperativeLevel(FWindow(), DISCL_NONEXCLUSIVE or DISCL_FOREGROUND);
  CheckStep('SetCooperativeLevel');

  ZeroMemory(@LProperty, SizeOf(LProperty));
  LProperty.diph.dwSize := SizeOf(LProperty);
  LProperty.diph.dwHeaderSize := SizeOf(LProperty.diph);
  LProperty.diph.dwObj := 0;
  LProperty.diph.dwHow := DIPH_DEVICE;
  LProperty.dwData := SizeOf(TKeyboardState);
  LResult := FDevice.SetProperty(DIPROP_BUFFERSIZE, LProperty.diph);
  CheckStep('SetCooperativeLevel');

  if Assigned(FLog) then
    FLog.Info(SUsingDirectInput);
end;

procedure TDirectKeyboard.Shutdown;
begin
  if Assigned(FDirectInput) then
  begin
    if Assigned(FDevice) then
    begin
      // Unacquire the device (just in case) before exiting
      FDevice.Unacquire;
      FDevice._Release;
    end;
    FDirectInput._Release;
  end;
end;

function TDirectKeyboard.ReadState(var AStates: TKeyStates): Boolean;
var
  LResult: HRESULT;
  LIndex: Integer;
begin
  Result := False;
  if not Assigned(FDevice) then
    Exit;

  LResult := FDevice.GetDeviceState(SizeOf(FState), FState);
  if LResult = DIERR_INPUTLOST then
  begin
    // The input stream has been interrupted: acquire again and try once more
    if FDevice.Acquire <> DD_OK then
      Exit;
    LResult := FDevice.GetDeviceState(SizeOf(FState), FState);
    if LResult = DIERR_INPUTLOST then
      Exit;
  end;

  // The DirectInput key code is converted into the Windows virtual key code
  FillChar(AStates, SizeOf(AStates), 0);
  for LIndex := Low(FState) to High(FState) do
    if (FState[LIndex] and $80) <> 0 then
      AStates[Byte(DIKEYtoVK(LIndex))] := KEYSTATE_DOWN;
  Result := True;
end;

procedure TDirectKeyboard.SetActive(AActive: Boolean);
begin
  if Assigned(FDevice) then
  begin
    if AActive then
      FDevice.Acquire
    else
      FDevice.Unacquire;
  end;
end;

function TDirectKeyboard.IsCapsLockOn: Boolean;
begin
  Result := (GetKeyState(VK_CAPITAL) and 1) <> 0;
end;

end.