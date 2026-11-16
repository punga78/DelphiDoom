{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the input manager                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  id_in.c                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Input;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.DemoTape;

type
  /// <summary>
  ///   ID_IN. The keyboard interrupt, the mouse driver and the game port of the DOS are interfaces: the
  ///   scan codes come in through KeyService (what the interrupt did), the mouse and the joysticks are asked
  ///   when a control is read. The 16 bit arithmetic of the joystick is kept (a Word that wraps). The loops that
  ///   wait for a key call the pump (the devices are read) and the clock (which, in a test, moves on)
  /// </summary>
  TKeenInput = class(TInterfacedObject, IKeenInput)
  strict private
    const
      DIRECTION_TABLE: array[0..8] of TKeenDirection = (kdNorthWest, kdNorth, kdNorthEast, kdWest, kdNone, kdEast,
        kdSouthWest, kdSouth, kdSouthEast);
    var
      FClock: IKeenClock;
      FMouse: IKeenMouse;
      FJoysticks: IKeenJoysticks;
      FPump: IKeenInputPump;
      FKeyboard: array[0..KEEN_NUM_CODES - 1] of Boolean;
      FLastScan: Byte;
      FLastAscii: Byte;
      FCurCode: Byte;
      FLastCode: Byte;
      FSpecial: Boolean;
      FCapsLock: Boolean;
      FPaused: Boolean;
      FMousePresent: Boolean;
      FJoysPresent: array[0..KEEN_MAX_JOYSTICKS - 1] of Boolean;
      FKeyboardDefs: array[0..KEEN_MAX_KEYBOARDS - 1] of TKeenKeyboardDef;
      FJoystickDefs: array[0..KEEN_MAX_JOYSTICKS - 1] of TKeenJoystickDef;
      FControls: array[0..KEEN_MAX_PLAYERS - 1] of TKeenControlType;
      FKeyHook: TProc;
      FStarted: Boolean;
      FTape: TKeenDemoTape;
      FDemoMode: TKeenDemoMode;
      FJoyLastTime: Integer;
    procedure Wait;
    procedure SetupJoystickScale(AJoy: Integer);
    procedure GetJoystickDelta(AJoy: Integer; AAdaptive: Boolean; out ADeltaX, ADeltaY: Integer);
    function StartJoystick(AJoy: Integer): Boolean;
    function GetMouseButtons: Word;
    function GetJoystickButtons(AJoy: Integer): Word;
    procedure AdjustCursor(var AInfo: TKeenControlInfo; AButtons: Word; ADeltaX, ADeltaY: Integer);
    procedure CheckJoystick(AJoy: Integer);
    procedure CheckPlayer(APlayer: Integer);
  public
    /// <param name="AClock">TimeCount, for the loops that wait and for the joystick</param>
    /// <param name="AMouse">The mouse; nil for a machine without one</param>
    /// <param name="AJoysticks">The joysticks; nil for none</param>
    /// <param name="APump">Reads the devices while a loop waits; nil if the scan codes come from somewhere else</param>
    constructor Create(const AClock: IKeenClock; const AMouse: IKeenMouse; const AJoysticks: IKeenJoysticks;
      const APump: IKeenInputPump);
    destructor Destroy; override;
    function GetLastScan: Byte;
    procedure SetLastScan(AValue: Byte);
    function GetLastAscii: Byte;
    procedure SetLastAscii(AValue: Byte);
    function GetPaused: Boolean;
    procedure SetPaused(AValue: Boolean);
    function GetDemoMode: TKeenDemoMode;
    function GetMousePresent: Boolean;
    function GetKeyboardDef(AIndex: Integer): TKeenKeyboardDef;
    procedure SetKeyboardDef(AIndex: Integer; const AValue: TKeenKeyboardDef);
    function GetJoystickDef(AJoy: Integer): TKeenJoystickDef;
    function GetControl(APlayer: Integer): TKeenControlType;
    function GetJoystickPresent(AJoy: Integer): Boolean;
    procedure KeyService(AByte: Byte);
    procedure Startup(AUseMouse, AUseJoysticks: Boolean);
    procedure Shutdown;
    procedure SetDefault(AGotIt: Boolean; AControl: TKeenControlType);
    procedure SetKeyHook(const AHook: TProc);
    function IsKeyDown(AScan: Integer): Boolean;
    procedure ClearKey(AScan: Integer);
    procedure ClearKeysDown;
    procedure SetControlType(APlayer: Integer; AType: TKeenControlType);
    procedure SetupJoystick(AJoy: Integer; AMinX, AMaxX, AMinY, AMaxY: Word);
    function ReadControl(APlayer: Integer): TKeenControlInfo;
    function ReadCursor: TKeenControlInfo;
    function IsUserInput: Boolean;
    function UserInput(ADelay: Integer; AClear: Boolean): Boolean;
    procedure AckBack;
    procedure Ack;
    function WaitForKey: Byte;
    function WaitForAscii: Byte;
    function GetJoystickButtonsDebounced(AJoy: Integer): Word;
    function StartDemoRecord(ASize: Integer): Boolean;
    procedure StartDemoPlayback(const ABytes: TBytes; ASize: Integer);
    procedure StopDemo;
    function DemoBytes: TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.ScanTables;

{ TKeenInput }

constructor TKeenInput.Create(const AClock: IKeenClock; const AMouse: IKeenMouse; const AJoysticks: IKeenJoysticks;
  const APump: IKeenInputPump);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FClock := AClock;
  FMouse := AMouse;
  FJoysticks := AJoysticks;
  FPump := APump;
  // KbdDefs[0] of id_in.c: control and alt for the buttons, the keys of the numeric keypad for the directions;
  // the second keyboard has no keys (the scan code 0 is never down)
  FillChar(FKeyboardDefs, SizeOf(FKeyboardDefs), 0);
  FKeyboardDefs[0].Button0 := $1D;
  FKeyboardDefs[0].Button1 := $38;
  FKeyboardDefs[0].UpLeft := $47;
  FKeyboardDefs[0].Up := $48;
  FKeyboardDefs[0].UpRight := $49;
  FKeyboardDefs[0].Left := $4B;
  FKeyboardDefs[0].Right := $4D;
  FKeyboardDefs[0].DownLeft := $4F;
  FKeyboardDefs[0].Down := $50;
  FKeyboardDefs[0].DownRight := $51;
  FDemoMode := kdmOff;
end;

destructor TKeenInput.Destroy;
begin
  FTape.Free;
  inherited Destroy;
end;

procedure TKeenInput.Wait;
begin
  if Assigned(FPump) then
    FPump.Pump;
  FClock.Idle;
end;

function TKeenInput.GetLastScan: Byte;
begin
  Result := FLastScan;
end;

procedure TKeenInput.SetLastScan(AValue: Byte);
begin
  FLastScan := AValue;
end;

function TKeenInput.GetLastAscii: Byte;
begin
  Result := FLastAscii;
end;

procedure TKeenInput.SetLastAscii(AValue: Byte);
begin
  FLastAscii := AValue;
end;

function TKeenInput.GetPaused: Boolean;
begin
  Result := FPaused;
end;

procedure TKeenInput.SetPaused(AValue: Boolean);
begin
  FPaused := AValue;
end;

function TKeenInput.GetDemoMode: TKeenDemoMode;
begin
  Result := FDemoMode;
end;

function TKeenInput.GetMousePresent: Boolean;
begin
  Result := FMousePresent;
end;

function TKeenInput.GetKeyboardDef(AIndex: Integer): TKeenKeyboardDef;
begin
  if (AIndex < 0) or (AIndex >= KEEN_MAX_KEYBOARDS) then
    raise EKeenException.CreateFmt(SKeenInputBadScan, [AIndex]);
  Result := FKeyboardDefs[AIndex];
end;

procedure TKeenInput.SetKeyboardDef(AIndex: Integer; const AValue: TKeenKeyboardDef);
begin
  if (AIndex < 0) or (AIndex >= KEEN_MAX_KEYBOARDS) then
    raise EKeenException.CreateFmt(SKeenInputBadScan, [AIndex]);
  FKeyboardDefs[AIndex] := AValue;
end;

function TKeenInput.GetJoystickDef(AJoy: Integer): TKeenJoystickDef;
begin
  CheckJoystick(AJoy);
  Result := FJoystickDefs[AJoy];
end;

function TKeenInput.GetControl(APlayer: Integer): TKeenControlType;
begin
  CheckPlayer(APlayer);
  Result := FControls[APlayer];
end;

function TKeenInput.GetJoystickPresent(AJoy: Integer): Boolean;
begin
  CheckJoystick(AJoy);
  Result := FJoysPresent[AJoy];
end;

procedure TKeenInput.CheckJoystick(AJoy: Integer);
begin
  if (AJoy < 0) or (AJoy >= KEEN_MAX_JOYSTICKS) then
    raise EKeenException.CreateFmt(SKeenInputBadScan, [AJoy]);
end;

procedure TKeenInput.CheckPlayer(APlayer: Integer);
begin
  if (APlayer < 0) or (APlayer >= KEEN_MAX_PLAYERS) then
    raise EKeenException.CreateFmt(SKeenInputBadScan, [APlayer]);
end;

// ---------------------------------------------------------------------------
// the keyboard
// ---------------------------------------------------------------------------

procedure TKeenInput.KeyService(AByte: Byte);
var
  LKey: Byte;
  LAscii: Byte;
begin
  if AByte = $E0 then
    // the prefix of the special keys: the next code is one of them
    FSpecial := True
  else if AByte = $E1 then
    // the pause key
    FPaused := True
  else
  begin
    if (AByte and $80) <> 0 then
    begin
      // a break code: the key goes up
      LKey := AByte and $7F;
      FKeyboard[LKey] := False;
    end
    else
    begin
      // a make code
      FLastCode := FCurCode;
      FCurCode := AByte;
      FLastScan := AByte;
      FKeyboard[AByte] := True;
      if FSpecial then
        LAscii := TKeenScanTables.SpecialAscii(AByte)
      else
      begin
        if AByte = KEEN_SC_CAPSLOCK then
          FCapsLock := not FCapsLock;
        if FKeyboard[KEEN_SC_LSHIFT] or FKeyboard[KEEN_SC_RSHIFT] then
        begin
          LAscii := TKeenScanTables.ShiftedAscii(AByte);
          // the shift and the caps lock together make the letters small
          if (LAscii >= Ord('A')) and (LAscii <= Ord('Z')) and FCapsLock then
            Inc(LAscii, Ord('a') - Ord('A'));
        end
        else
        begin
          LAscii := TKeenScanTables.PlainAscii(AByte);
          if (LAscii >= Ord('a')) and (LAscii <= Ord('z')) and FCapsLock then
            Dec(LAscii, Ord('a') - Ord('A'));
        end;
      end;
      if LAscii <> 0 then
        FLastAscii := LAscii;
    end;
    FSpecial := False;
  end;
  // the hook is not called after the prefix
  if Assigned(FKeyHook) and not FSpecial then
    FKeyHook();
end;

procedure TKeenInput.SetKeyHook(const AHook: TProc);
begin
  FKeyHook := AHook;
end;

function TKeenInput.IsKeyDown(AScan: Integer): Boolean;
begin
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit(False);
  Result := FKeyboard[AScan];
end;

procedure TKeenInput.ClearKey(AScan: Integer);
begin
  if (AScan < 0) or (AScan >= KEEN_NUM_CODES) then
    Exit;
  FKeyboard[AScan] := False;
  if AScan = FLastScan then
    FLastScan := KEEN_SC_NONE;
end;

procedure TKeenInput.ClearKeysDown;
begin
  FLastScan := KEEN_SC_NONE;
  FLastAscii := KEEN_KEY_NONE;
  FillChar(FKeyboard, SizeOf(FKeyboard), 0);
end;

// ---------------------------------------------------------------------------
// the mouse and the joysticks
// ---------------------------------------------------------------------------

function TKeenInput.GetMouseButtons: Word;
begin
  Result := 0;
  if Assigned(FMouse) then
    Result := FMouse.GetButtons;
end;

function TKeenInput.GetJoystickButtons(AJoy: Integer): Word;
begin
  Result := 0;
  if Assigned(FJoysticks) then
    Result := FJoysticks.GetButtons(AJoy) and 3;
end;

procedure TKeenInput.SetupJoystickScale(AJoy: Integer);
var
  LDef: ^TKeenJoystickDef;

  function Divide(ARange: Word): Word;
  begin
    // the C divides by the range: a range of 0 stops the program with a divide error
    if ARange = 0 then
      raise EKeenException.CreateFmt(SKeenSizeInvalid, [AJoy, 0]);
    Result := Word(KEEN_JOY_SCALE_MAX div ARange);
  end;

begin
  LDef := @FJoystickDefs[AJoy];
  LDef^.JoyMultXL := Divide(Word(LDef^.ThreshMinX - LDef^.JoyMinX));
  LDef^.JoyMultXH := Divide(Word(LDef^.JoyMaxX - LDef^.ThreshMaxX));
  LDef^.JoyMultYL := Divide(Word(LDef^.ThreshMinY - LDef^.JoyMinY));
  LDef^.JoyMultYH := Divide(Word(LDef^.JoyMaxY - LDef^.ThreshMaxY));
end;

procedure TKeenInput.SetupJoystick(AJoy: Integer; AMinX, AMaxX, AMinY, AMaxY: Word);
var
  LRange: Word;
  LDelta: Word;
begin
  CheckJoystick(AJoy);
  FJoystickDefs[AJoy].JoyMinX := AMinX;
  FJoystickDefs[AJoy].JoyMaxX := AMaxX;
  LRange := Word(AMaxX - AMinX);
  LDelta := LRange div 5;
  FJoystickDefs[AJoy].ThreshMinX := Word(((LRange div 2) - LDelta) + AMinX);
  FJoystickDefs[AJoy].ThreshMaxX := Word(((LRange div 2) + LDelta) + AMinX);
  FJoystickDefs[AJoy].JoyMinY := AMinY;
  FJoystickDefs[AJoy].JoyMaxY := AMaxY;
  LRange := Word(AMaxY - AMinY);
  LDelta := LRange div 5;
  FJoystickDefs[AJoy].ThreshMinY := Word(((LRange div 2) - LDelta) + AMinY);
  FJoystickDefs[AJoy].ThreshMaxY := Word(((LRange div 2) + LDelta) + AMinY);
  SetupJoystickScale(AJoy);
end;

function TKeenInput.StartJoystick(AJoy: Integer): Boolean;
var
  LX: Word;
  LY: Word;
begin
  // INL_StartJoy: a joystick is there if the two axes read a value that is neither 0 nor near the limit of the
  // timing loop; its range is taken from the position it has now (assumed to be the centre)
  Result := False;
  if (not Assigned(FJoysticks)) or (not FJoysticks.IsPresent(AJoy)) then
    Exit;
  FJoysticks.GetAbs(AJoy, LX, LY);
  if (LX = 0) or (LX > KEEN_MAX_JOY_VALUE - 10) or (LY = 0) or (LY > KEEN_MAX_JOY_VALUE - 10) then
    Exit;
  SetupJoystick(AJoy, 0, Word(LX * 2), 0, Word(LY * 2));
  Result := True;
end;

procedure TKeenInput.GetJoystickDelta(AJoy: Integer; AAdaptive: Boolean; out ADeltaX, ADeltaY: Integer);
var
  LX: Word;
  LY: Word;
  LTime: Integer;
  LDef: TKeenJoystickDef;
begin
  FJoysticks.GetAbs(AJoy, LX, LY);
  LDef := FJoystickDefs[AJoy];
  if LX < LDef.ThreshMinX then
  begin
    if LX < LDef.JoyMinX then
      LX := LDef.JoyMinX;
    LX := Word(-(LX - LDef.ThreshMinX));
    LX := Word(LX * LDef.JoyMultXL);
    LX := LX shr KEEN_JOY_SCALE_SHIFT;
    if LX > KEEN_JOY_MAX_DELTA then
      ADeltaX := -KEEN_JOY_MAX_DELTA
    else
      ADeltaX := -LX;
  end
  else if LX > LDef.ThreshMaxX then
  begin
    if LX > LDef.JoyMaxX then
      LX := LDef.JoyMaxX;
    LX := Word(LX - LDef.ThreshMaxX);
    LX := Word(LX * LDef.JoyMultXH);
    LX := LX shr KEEN_JOY_SCALE_SHIFT;
    if LX > KEEN_JOY_MAX_DELTA then
      ADeltaX := KEEN_JOY_MAX_DELTA
    else
      ADeltaX := LX;
  end
  else
    ADeltaX := 0;
  if LY < LDef.ThreshMinY then
  begin
    if LY < LDef.JoyMinY then
      LY := LDef.JoyMinY;
    LY := Word(-(LY - LDef.ThreshMinY));
    LY := Word(LY * LDef.JoyMultYL);
    LY := LY shr KEEN_JOY_SCALE_SHIFT;
    if LY > KEEN_JOY_MAX_DELTA then
      ADeltaY := -KEEN_JOY_MAX_DELTA
    else
      ADeltaY := -LY;
  end
  else if LY > LDef.ThreshMaxY then
  begin
    if LY > LDef.JoyMaxY then
      LY := LDef.JoyMaxY;
    LY := Word(LY - LDef.ThreshMaxY);
    LY := Word(LY * LDef.JoyMultYH);
    LY := LY shr KEEN_JOY_SCALE_SHIFT;
    if LY > KEEN_JOY_MAX_DELTA then
      ADeltaY := KEEN_JOY_MAX_DELTA
    else
      ADeltaY := LY;
  end
  else
    ADeltaY := 0;
  if AAdaptive then
  begin
    // the faster the readings come, the smaller the steps: a step is multiplied by the half tics since the last
    // reading, to 8
    LTime := (FClock.TimeCount - FJoyLastTime) div 2;
    if LTime <> 0 then
    begin
      if LTime > 8 then
        LTime := 8;
      ADeltaX := ADeltaX * LTime;
      ADeltaY := ADeltaY * LTime;
    end;
  end;
  FJoyLastTime := FClock.TimeCount;
end;

function TKeenInput.GetJoystickButtonsDebounced(AJoy: Integer): Word;
var
  LFirst: Word;
  LSecond: Word;
  LLastTime: Integer;
begin
  repeat
    LFirst := GetJoystickButtons(AJoy);
    LLastTime := FClock.TimeCount;
    while FClock.TimeCount = LLastTime do
      Wait;
    LSecond := GetJoystickButtons(AJoy);
  until LFirst = LSecond;
  Result := LFirst;
end;

procedure TKeenInput.Startup(AUseMouse, AUseJoysticks: Boolean);
var
  LJoy: Integer;
begin
  if FStarted then
    Exit;
  FMousePresent := AUseMouse and Assigned(FMouse) and FMouse.IsPresent;
  for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
    FJoysPresent[LJoy] := AUseJoysticks and StartJoystick(LJoy);
  FStarted := True;
end;

procedure TKeenInput.Shutdown;
var
  LJoy: Integer;
begin
  if not FStarted then
    Exit;
  FMousePresent := False;
  for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
    FJoysPresent[LJoy] := False;
  FStarted := False;
end;

procedure TKeenInput.SetDefault(AGotIt: Boolean; AControl: TKeenControlType);
begin
  if (not AGotIt) or ((AControl = kctJoystick1) and not FJoysPresent[0]) or
    ((AControl = kctJoystick2) and not FJoysPresent[1]) or ((AControl = kctMouse) and not FMousePresent) then
    AControl := kctKeyboard1;
  SetControlType(0, AControl);
end;

procedure TKeenInput.SetControlType(APlayer: Integer; AType: TKeenControlType);
begin
  CheckPlayer(APlayer);
  FControls[APlayer] := AType;
end;

// ---------------------------------------------------------------------------
// the controls
// ---------------------------------------------------------------------------

procedure TKeenInput.AdjustCursor(var AInfo: TKeenControlInfo; AButtons: Word; ADeltaX, ADeltaY: Integer);
begin
  if (AButtons and 1) <> 0 then
    AInfo.Button0 := True;
  if (AButtons and 2) <> 0 then
    AInfo.Button1 := True;
  Inc(AInfo.X, ADeltaX);
  Inc(AInfo.Y, ADeltaY);
end;

function TKeenInput.ReadCursor: TKeenControlInfo;
var
  LJoy: Integer;
  LButtons: Word;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Direction := kdNone;
  if FMousePresent then
  begin
    LButtons := GetMouseButtons;
    FMouse.GetDelta(LDeltaX, LDeltaY);
    AdjustCursor(Result, LButtons, LDeltaX, LDeltaY);
  end;
  for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
  begin
    if not FJoysPresent[LJoy] then
      Continue;
    LButtons := GetJoystickButtons(LJoy);
    GetJoystickDelta(LJoy, True, LDeltaX, LDeltaY);
    // the C divides with /, that truncates toward 0
    AdjustCursor(Result, LButtons, LDeltaX div 64, LDeltaY div 64);
  end;
end;

function TKeenInput.ReadControl(APlayer: Integer): TKeenControlInfo;
var
  LRealDelta: Boolean;
  LDemoByte: Byte;
  LButtons: Word;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LMotionX: Integer;
  LMotionY: Integer;
  LType: TKeenControlType;
  LDef: TKeenKeyboardDef;
begin
  CheckPlayer(APlayer);
  LDeltaX := 0;
  LDeltaY := 0;
  LMotionX := 0;
  LMotionY := 0;
  LButtons := 0;
  LRealDelta := False;
  if FDemoMode = kdmPlayback then
  begin
    LDemoByte := FTape.PlayReading;
    LDeltaY := (LDemoByte and 3) - 1;
    LDeltaX := ((LDemoByte shr 2) and 3) - 1;
    LButtons := (LDemoByte shr 4) and 3;
    if FTape.Finished then
      FDemoMode := kdmPlayDone;
    // the C does not set realdelta for a demo: the variable has what was on the stack, and with 0 the readings
    // of the demo would be lost (the motion would be 0). They are the motion, as it was meant
    LRealDelta := True;
  end
  else if FDemoMode = kdmPlayDone then
    raise EKeenException.Create(SKeenDemoExceeded)
  else
  begin
    LType := FControls[APlayer];
    case LType of
      kctKeyboard1, kctKeyboard2:
        begin
          LDef := FKeyboardDefs[Ord(LType) - Ord(kctKeyboard1)];
          if FKeyboard[LDef.UpLeft and $7F] then
          begin
            LMotionX := -1;
            LMotionY := -1;
          end
          else if FKeyboard[LDef.UpRight and $7F] then
          begin
            LMotionX := 1;
            LMotionY := -1;
          end
          else if FKeyboard[LDef.DownLeft and $7F] then
          begin
            LMotionX := -1;
            LMotionY := 1;
          end
          else if FKeyboard[LDef.DownRight and $7F] then
          begin
            LMotionX := 1;
            LMotionY := 1;
          end;
          if FKeyboard[LDef.Up and $7F] then
            LMotionY := -1
          else if FKeyboard[LDef.Down and $7F] then
            LMotionY := 1;
          if FKeyboard[LDef.Left and $7F] then
            LMotionX := -1
          else if FKeyboard[LDef.Right and $7F] then
            LMotionX := 1;
          if FKeyboard[LDef.Button0 and $7F] then
            Inc(LButtons, 1);
          if FKeyboard[LDef.Button1 and $7F] then
            Inc(LButtons, 2);
          LRealDelta := False;
        end;
      kctJoystick1, kctJoystick2:
        begin
          if Assigned(FJoysticks) then
          begin
            GetJoystickDelta(Ord(LType) - Ord(kctJoystick1), False, LDeltaX, LDeltaY);
            LButtons := GetJoystickButtons(Ord(LType) - Ord(kctJoystick1));
          end;
          LRealDelta := True;
        end;
      kctMouse:
        begin
          if Assigned(FMouse) then
          begin
            FMouse.GetDelta(LDeltaX, LDeltaY);
            LButtons := GetMouseButtons;
          end;
          LRealDelta := True;
        end;
    end;
  end;
  if LRealDelta then
  begin
    if LDeltaX < 0 then
      LMotionX := -1
    else if LDeltaX > 0 then
      LMotionX := 1
    else
      LMotionX := 0;
    if LDeltaY < 0 then
      LMotionY := -1
    else if LDeltaY > 0 then
      LMotionY := 1
    else
      LMotionY := 0;
  end
  else
  begin
    LDeltaX := LMotionX * 127;
    LDeltaY := LMotionY * 127;
  end;
  Result.X := LDeltaX;
  Result.XAxis := LMotionX;
  Result.Y := LDeltaY;
  Result.YAxis := LMotionY;
  Result.Button0 := (LButtons and 1) <> 0;
  Result.Button1 := (LButtons and 2) <> 0;
  Result.Direction := DIRECTION_TABLE[(LMotionY + 1) * 3 + (LMotionX + 1)];
  if FDemoMode = kdmRecord then
    // the control packed in a byte (a byte: what does not fit is lost, as in the C)
    FTape.RecordReading(Byte((LButtons shl 4) or ((LDeltaX + 1) shl 2) or (LDeltaY + 1)));
end;

// ---------------------------------------------------------------------------
// waiting for the user
// ---------------------------------------------------------------------------

function TKeenInput.IsUserInput: Boolean;
var
  LJoy: Integer;
begin
  Result := FLastScan <> 0;
  if FMousePresent and (GetMouseButtons <> 0) then
    Result := True;
  for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
    if FJoysPresent[LJoy] and (GetJoystickButtons(LJoy) <> 0) then
      Result := True;
end;

procedure TKeenInput.AckBack;
var
  LJoy: Integer;
begin
  while FLastScan = 0 do
  begin
    if FMousePresent and (GetMouseButtons <> 0) then
    begin
      while GetMouseButtons <> 0 do
        Wait;
      Exit;
    end;
    for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
      if FJoysPresent[LJoy] and (GetJoystickButtonsDebounced(LJoy) <> 0) then
      begin
        while GetJoystickButtonsDebounced(LJoy) <> 0 do
          Wait;
        Exit;
      end;
    Wait;
  end;
  ClearKey(FLastScan);
  FLastScan := KEEN_SC_NONE;
end;

procedure TKeenInput.Ack;
var
  LJoy: Integer;
begin
  ClearKey(FLastScan);
  FLastScan := KEEN_SC_NONE;
  if FMousePresent then
    while GetMouseButtons <> 0 do
      Wait;
  for LJoy := 0 to KEEN_MAX_JOYSTICKS - 1 do
    if FJoysPresent[LJoy] then
      while GetJoystickButtonsDebounced(LJoy) <> 0 do
        Wait;
  AckBack;
end;

function TKeenInput.UserInput(ADelay: Integer; AClear: Boolean): Boolean;
var
  LLastTime: Integer;
begin
  LLastTime := FClock.TimeCount;
  repeat
    if IsUserInput then
    begin
      if AClear then
        AckBack;
      Exit(True);
    end;
    Wait;
  until FClock.TimeCount - LLastTime >= ADelay;
  Result := False;
end;

function TKeenInput.WaitForKey: Byte;
begin
  while FLastScan = 0 do
    Wait;
  Result := FLastScan;
  FLastScan := 0;
end;

function TKeenInput.WaitForAscii: Byte;
begin
  while FLastAscii = 0 do
    Wait;
  Result := FLastAscii;
  FLastAscii := 0;
end;

// ---------------------------------------------------------------------------
// demos
// ---------------------------------------------------------------------------

function TKeenInput.StartDemoRecord(ASize: Integer): Boolean;
begin
  if ASize <= 0 then
    Exit(False);
  FreeAndNil(FTape);
  FTape := TKeenDemoTape.CreateForRecording(ASize);
  FDemoMode := kdmRecord;
  Result := True;
end;

procedure TKeenInput.StartDemoPlayback(const ABytes: TBytes; ASize: Integer);
begin
  FreeAndNil(FTape);
  FTape := TKeenDemoTape.CreateForPlayback(ABytes, ASize);
  FDemoMode := kdmPlayback;
end;

procedure TKeenInput.StopDemo;
begin
  FDemoMode := kdmOff;
end;

function TKeenInput.DemoBytes: TBytes;
begin
  if not Assigned(FTape) then
    raise EKeenException.Create(SKeenDemoNotRecording);
  Result := FTape.RecordedBytes;
end;

end.
