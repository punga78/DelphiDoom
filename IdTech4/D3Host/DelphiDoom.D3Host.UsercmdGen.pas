{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the usercmd generator                     }
{                                                                              }
{  Port of Doom 3 (id Software): framework\UsercmdGen.cpp (idUsercmdGenLocal), }
{  without devices: the keyboard and the mouse arrive through                  }
{  ID3InputDevices.                                                            }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.UsercmdGen;

interface

uses
  System.SysUtils, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Input.Types,
  DelphiDoom.D3Host.Input.Intf;

type
  /// <summary>
  ///   Samples a set of user commands from the player input: the key and mouse states are updated by the events of
  ///   the devices (UsercmdInterrupt, called 60 times a second by the async code), and every tic gets a command
  ///   that is kept in a ring of 64. The cvars of D3_USERCMD_CVARS are read through ID3CVarValues. The function
  ///   statics of the original (the history of the mouse) are fields. The debug print of m_showMouseRate is not
  ///   ported.
  /// </summary>
  TD3UsercmdGen = class(TInterfacedObject, ID3UsercmdGenerator, ID3UsercmdControl)
  strict private
    type
      TButtonState = record
        On_: Integer;
        Held: Boolean;
        procedure Clear;
        procedure SetKeyState(const AKeyState: Integer; const AToggle: Boolean);
      end;
    var
      FState: TD3CommonState;
      FCVars: ID3CVarValues;
      FActions: ID3UsercmdActions;
      FDevices: ID3InputDevices;
      FAsync: ID3AsyncState;
      FErrors: ID3ErrorReporter;
      FDebug: ID3DebugOutput;
      FViewAngles: array[0..2] of Single;
      FFlags: Integer;
      FImpulse: Integer;
      FToggledCrouch: TButtonState;
      FToggledRun: TButtonState;
      FToggledZoom: TButtonState;
      FButtonState: array[0..UB_MAX_BUTTONS - 1] of Integer;
      FKeyState: array[0..D3_MAX_KEYS - 1] of Boolean;
      FInhibitCommands: Integer;
      FInitialized: Boolean;
      FCmd: TD3Usercmd;
      FBuffered: array[0..D3_MAX_BUFFERED_USERCMD - 1] of TD3Usercmd;
      FContinuousMouseX: Integer;
      FContinuousMouseY: Integer;
      FMouseButton: Integer;
      FMouseDown: Boolean;
      FMouseDx: Integer;
      FMouseDy: Integer;
      FJoystickAxis: array[0..MAX_JOYSTICK_AXIS - 1] of Integer;
      FHistory: array[0..7, 0..1] of Integer;
      FHistoryCounter: Integer;
    function Inhibited: Boolean;
    function AlwaysRunNetwork: Boolean;
    function RunActive: Boolean;
    procedure AdjustAngles;
    procedure KeyMove;
    procedure MouseMove;
    procedure JoystickMove;
    procedure CmdButtons;
    procedure InitCurrent;
    procedure MakeCurrent;
    procedure Key(const AKey: Integer; const ADown: Boolean);
    procedure Mouse;
    procedure Keyboard;
    procedure Joystick;
    class function ClampChar(const AValue: Integer): ShortInt; static;
    class function AngleToShort(const AAngle: Single): SmallInt; static;
  public
    constructor Create(const AState: TD3CommonState; const ACVars: ID3CVarValues; const AActions: ID3UsercmdActions;
      const ADevices: ID3InputDevices; const AAsync: ID3AsyncState; const AErrors: ID3ErrorReporter;
      const ADebug: ID3DebugOutput);
    procedure Init;
    procedure InitForNewMap;
    procedure Shutdown;
    /// <summary>idUsercmdGenLocal::Clear: all the key and button states, the inhibit mask and the mouse state</summary>
    procedure Clear;
    procedure ClearAngles;
    procedure InhibitUsercmd(const ASubsystem: Integer; const AInhibit: Boolean);
    /// <summary>The buffered command of a tic; asking for a tic after the next one is an Error of the engine</summary>
    function TicCmd(const ATicNumber: Integer): TD3Usercmd;
    /// <summary>idUsercmdGenLocal::UsercmdInterrupt: builds the command for com_ticNumber + 1 (nothing if not initialized)</summary>
    procedure UsercmdInterrupt;
    /// <summary>The button of a user command text (_forward, _impulse5...) without regard to case; UB_NONE if it is none</summary>
    function CommandStringUsercmdData(const ACommand: AnsiString): Integer;
    /// <summary>The number of user commands, with the terminator of the table of the original</summary>
    function GetNumUserCommands: Integer;
    /// <summary>The name of a user command; empty for the terminator and for an index out of range</summary>
    function GetUserCommandName(const AIndex: Integer): AnsiString;
    procedure MouseState(out AX, AY, AButton: Integer; out ADown: Boolean);
    function ButtonState(const AKey: Integer): Integer;
    function KeyState(const AKey: Integer): Integer;
    function GetDirectUsercmd: TD3Usercmd;
    /// <summary>The view angles (pitch, yaw, roll) in degrees</summary>
    function ViewAngle(const AIndex: Integer): Single;
    function Flags: Integer;
    function Impulse: Integer;
    function InhibitMask: Integer;
    function IsInitialized: Boolean;
    function ToggledRun: Integer;
    function ToggledRunHeld: Boolean;
    function ToggledCrouch: Integer;
    function ToggledCrouchHeld: Boolean;
    function ToggledZoom: Integer;
    function ToggledZoomHeld: Boolean;
    function MouseDeltaX: Integer;
    function MouseDeltaY: Integer;
  end;

implementation

const
  PITCH = 0;
  YAW = 1;
  MS2SEC: Single = 0.001;
  SRidiculousDelta = 'idUsercmdGenLocal::MouseMove: Ignoring ridiculous mouse delta.' + #10;
  STicTooNew = 'idUsercmdGenLocal::TicCmd ticNumber > com_ticNumber';

procedure TD3UsercmdGen.TButtonState.Clear;
begin
  Held := False;
  On_ := 0;
end;

procedure TD3UsercmdGen.TButtonState.SetKeyState(const AKeyState: Integer; const AToggle: Boolean);
begin
  if not AToggle then
  begin
    Held := False;
    On_ := AKeyState;
  end
  else if AKeyState = 0 then
    Held := False
  else if not Held then
  begin
    Held := True;
    On_ := On_ xor 1;
  end;
end;

constructor TD3UsercmdGen.Create(const AState: TD3CommonState; const ACVars: ID3CVarValues;
  const AActions: ID3UsercmdActions; const ADevices: ID3InputDevices; const AAsync: ID3AsyncState;
  const AErrors: ID3ErrorReporter; const ADebug: ID3DebugOutput);
begin
  inherited Create;
  FState := AState;
  FCVars := ACVars;
  FActions := AActions;
  FDevices := ADevices;
  FAsync := AAsync;
  FErrors := AErrors;
  FDebug := ADebug;
  FFlags := 0;
  FImpulse := 0;
  FToggledCrouch.Clear;
  FToggledRun.Clear;
  FToggledZoom.Clear;
  if FCVars.GetBool('in_alwaysRun') then
    FToggledRun.On_ := 1;
  ClearAngles;
  Clear;
end;

class function TD3UsercmdGen.ClampChar(const AValue: Integer): ShortInt;
begin
  if AValue < -128 then
    Result := -128
  else if AValue > 127 then
    Result := 127
  else
    Result := ShortInt(AValue);
end;

class function TD3UsercmdGen.AngleToShort(const AAngle: Single): SmallInt;
var
  LRounded: Single;
begin
  // ANGLE2SHORT: the product goes to FtoiFast as a float, which rounds to nearest even
  LRounded := Double(AAngle) * 65536.0 / 360.0;
  Result := SmallInt(Word(Round(LRounded) and 65535));
end;

procedure TD3UsercmdGen.InhibitUsercmd(const ASubsystem: Integer; const AInhibit: Boolean);
begin
  if AInhibit then
    FInhibitCommands := FInhibitCommands or (1 shl ASubsystem)
  else
    FInhibitCommands := FInhibitCommands and (not (1 shl ASubsystem));
end;

function TD3UsercmdGen.ButtonState(const AKey: Integer): Integer;
begin
  if (AKey < 0) or (AKey >= UB_MAX_BUTTONS) then
    Exit(-1);
  if FButtonState[AKey] > 0 then
    Result := 1
  else
    Result := 0;
end;

function TD3UsercmdGen.KeyState(const AKey: Integer): Integer;
begin
  if (AKey < 0) or (AKey >= K_LAST_KEY) then
    Exit(-1);
  if FKeyState[AKey] then
    Result := 1
  else
    Result := 0;
end;

function TD3UsercmdGen.GetNumUserCommands: Integer;
begin
  Result := Length(D3_USER_COMMANDS) + 1;
end;

function TD3UsercmdGen.GetUserCommandName(const AIndex: Integer): AnsiString;
begin
  if (AIndex >= 0) and (AIndex < Length(D3_USER_COMMANDS)) then
    Result := D3_USER_COMMANDS[AIndex].Name
  else
    Result := '';
end;

function TD3UsercmdGen.Inhibited: Boolean;
begin
  Result := FInhibitCommands <> 0;
end;

function TD3UsercmdGen.AlwaysRunNetwork: Boolean;
begin
  Result := FCVars.GetBool('in_alwaysRun') and FAsync.IsActive;
end;

function TD3UsercmdGen.RunActive: Boolean;
begin
  Result := (FToggledRun.On_ xor Ord(AlwaysRunNetwork)) <> 0;
end;

procedure TD3UsercmdGen.AdjustAngles;
var
  LSpeed: Single;
begin
  if RunActive then
    LSpeed := Double(MS2SEC) * USERCMD_MSEC * FCVars.GetFloat('in_anglespeedkey')
  else
    LSpeed := Double(MS2SEC) * USERCMD_MSEC;
  if ButtonState(UB_STRAFE) = 0 then
  begin
    FViewAngles[YAW] := Double(FViewAngles[YAW]) - Double(LSpeed) * FCVars.GetFloat('in_yawspeed') *
      ButtonState(UB_RIGHT);
    FViewAngles[YAW] := Double(FViewAngles[YAW]) + Double(LSpeed) * FCVars.GetFloat('in_yawspeed') *
      ButtonState(UB_LEFT);
  end;
  FViewAngles[PITCH] := Double(FViewAngles[PITCH]) - Double(LSpeed) * FCVars.GetFloat('in_pitchspeed') *
    ButtonState(UB_LOOKUP);
  FViewAngles[PITCH] := Double(FViewAngles[PITCH]) + Double(LSpeed) * FCVars.GetFloat('in_pitchspeed') *
    ButtonState(UB_LOOKDOWN);
end;

procedure TD3UsercmdGen.KeyMove;
var
  LForward: Integer;
  LSide: Integer;
  LUp: Integer;
begin
  LForward := 0;
  LSide := 0;
  LUp := 0;
  if ButtonState(UB_STRAFE) <> 0 then
  begin
    Inc(LSide, D3_KEY_MOVESPEED * ButtonState(UB_RIGHT));
    Dec(LSide, D3_KEY_MOVESPEED * ButtonState(UB_LEFT));
  end;
  Inc(LSide, D3_KEY_MOVESPEED * ButtonState(UB_MOVERIGHT));
  Dec(LSide, D3_KEY_MOVESPEED * ButtonState(UB_MOVELEFT));
  Dec(LUp, D3_KEY_MOVESPEED * FToggledCrouch.On_);
  Inc(LUp, D3_KEY_MOVESPEED * ButtonState(UB_UP));
  Inc(LForward, D3_KEY_MOVESPEED * ButtonState(UB_FORWARD));
  Dec(LForward, D3_KEY_MOVESPEED * ButtonState(UB_BACK));
  FCmd.ForwardMove := ClampChar(LForward);
  FCmd.RightMove := ClampChar(LSide);
  FCmd.UpMove := ClampChar(LUp);
end;

procedure TD3UsercmdGen.MouseMove;
var
  LMx, LMy, LStrafeMx, LStrafeMy, LLength: Single;
  LSmooth: Integer;
  LIndex: Integer;
begin
  FHistory[FHistoryCounter and 7][0] := FMouseDx;
  FHistory[FHistoryCounter and 7][1] := FMouseDy;
  // allow mouse movement to be smoothed together
  LSmooth := FCVars.GetInteger('m_smooth');
  if LSmooth < 1 then
    LSmooth := 1;
  if LSmooth > 8 then
    LSmooth := 8;
  LMx := 0;
  LMy := 0;
  for LIndex := 0 to LSmooth - 1 do
  begin
    LMx := LMx + FHistory[(FHistoryCounter - LIndex + 8) and 7][0];
    LMy := LMy + FHistory[(FHistoryCounter - LIndex + 8) and 7][1];
  end;
  LMx := LMx / LSmooth;
  LMy := LMy / LSmooth;
  // use a larger smoothing for strafing
  LSmooth := FCVars.GetInteger('m_strafeSmooth');
  if LSmooth < 1 then
    LSmooth := 1;
  if LSmooth > 8 then
    LSmooth := 8;
  LStrafeMx := 0;
  LStrafeMy := 0;
  for LIndex := 0 to LSmooth - 1 do
  begin
    LStrafeMx := LStrafeMx + FHistory[(FHistoryCounter - LIndex + 8) and 7][0];
    LStrafeMy := LStrafeMy + FHistory[(FHistoryCounter - LIndex + 8) and 7][1];
  end;
  LStrafeMx := LStrafeMx / LSmooth;
  LStrafeMy := LStrafeMy / LSmooth;
  Inc(FHistoryCounter);
  if (Abs(LMx) > 1000) or (Abs(LMy) > 1000) then
  begin
    FDebug.DebugPrintf(SRidiculousDelta);
    LMx := 0;
    LMy := 0;
  end;
  LMx := LMx * FCVars.GetFloat('sensitivity');
  LMy := LMy * FCVars.GetFloat('sensitivity');
  FMouseDx := 0;
  FMouseDy := 0;
  if (LStrafeMx = 0) and (LStrafeMy = 0) then
    Exit;
  if (ButtonState(UB_STRAFE) <> 0) or ((FCmd.Buttons and BUTTON_MLOOK) = 0) then
  begin
    // add mouse X/Y movement to cmd
    LStrafeMx := LStrafeMx * FCVars.GetFloat('m_strafeScale');
    LStrafeMy := LStrafeMy * FCVars.GetFloat('m_strafeScale');
    // clamp as a vector, instead of separate floats
    LLength := Sqrt(Double(LStrafeMx) * LStrafeMx + Double(LStrafeMy) * LStrafeMy);
    if LLength > 127 then
    begin
      LStrafeMx := LStrafeMx * 127 / LLength;
      LStrafeMy := LStrafeMy * 127 / LLength;
    end;
  end;
  if ButtonState(UB_STRAFE) = 0 then
    FViewAngles[YAW] := Double(FViewAngles[YAW]) - Double(FCVars.GetFloat('m_yaw')) * LMx
  else
    FCmd.RightMove := ClampChar(Trunc(Double(FCmd.RightMove) + LStrafeMx));
  if (ButtonState(UB_STRAFE) = 0) and ((FCmd.Buttons and BUTTON_MLOOK) <> 0) then
    FViewAngles[PITCH] := Double(FViewAngles[PITCH]) + Double(FCVars.GetFloat('m_pitch')) * LMy
  else
    FCmd.ForwardMove := ClampChar(Trunc(Double(FCmd.ForwardMove) - LStrafeMy));
end;

procedure TD3UsercmdGen.JoystickMove;
var
  LAngleSpeed: Single;
begin
  if RunActive then
    LAngleSpeed := Double(MS2SEC) * USERCMD_MSEC * FCVars.GetFloat('in_anglespeedkey')
  else
    LAngleSpeed := Double(MS2SEC) * USERCMD_MSEC;
  if ButtonState(UB_STRAFE) = 0 then
  begin
    FViewAngles[YAW] := Double(FViewAngles[YAW]) + Double(LAngleSpeed) * FCVars.GetFloat('in_yawspeed') *
      FJoystickAxis[AXIS_SIDE];
    FViewAngles[PITCH] := Double(FViewAngles[PITCH]) + Double(LAngleSpeed) * FCVars.GetFloat('in_pitchspeed') *
      FJoystickAxis[AXIS_FORWARD];
  end
  else
  begin
    FCmd.RightMove := ClampChar(FCmd.RightMove + FJoystickAxis[AXIS_SIDE]);
    FCmd.ForwardMove := ClampChar(FCmd.ForwardMove + FJoystickAxis[AXIS_FORWARD]);
  end;
  FCmd.UpMove := ClampChar(FCmd.UpMove + FJoystickAxis[AXIS_UP]);
end;

procedure TD3UsercmdGen.CmdButtons;
var
  LIndex: Integer;
  LButtons: Integer;
begin
  LButtons := 0;
  // figure button bits
  for LIndex := 0 to 7 do
    if ButtonState(UB_BUTTON0 + LIndex) <> 0 then
      LButtons := LButtons or (1 shl LIndex);
  if ButtonState(UB_ATTACK) <> 0 then
    LButtons := LButtons or BUTTON_ATTACK;
  if RunActive then
    LButtons := LButtons or BUTTON_RUN;
  if FToggledZoom.On_ <> 0 then
    LButtons := LButtons or BUTTON_ZOOM;
  // the button is toggled in SP mode as well but without effect
  if (ButtonState(UB_SHOWSCORES) <> 0) or (ButtonState(UB_IMPULSE19) <> 0) then
    LButtons := LButtons or BUTTON_SCORES;
  if (ButtonState(UB_MLOOK) xor FCVars.GetInteger('in_freeLook')) <> 0 then
    LButtons := LButtons or BUTTON_MLOOK;
  FCmd.Buttons := Byte(LButtons);
end;

procedure TD3UsercmdGen.InitCurrent;
var
  LButtons: Integer;
begin
  FCmd := Default(TD3Usercmd);
  FCmd.Flags := Byte(FFlags);
  FCmd.Impulse := ShortInt(FImpulse);
  LButtons := 0;
  if AlwaysRunNetwork then
    LButtons := LButtons or BUTTON_RUN;
  if FCVars.GetBool('in_freeLook') then
    LButtons := LButtons or BUTTON_MLOOK;
  FCmd.Buttons := Byte(LButtons);
end;

procedure TD3UsercmdGen.MakeCurrent;
var
  LOldPitch: Single;
  LIndex: Integer;
begin
  LOldPitch := FViewAngles[PITCH];
  if not Inhibited then
  begin
    // update toggled key states
    FToggledCrouch.SetKeyState(ButtonState(UB_DOWN), FCVars.GetBool('in_toggleCrouch'));
    FToggledRun.SetKeyState(ButtonState(UB_SPEED), FCVars.GetBool('in_toggleRun') and FAsync.IsActive);
    FToggledZoom.SetKeyState(ButtonState(UB_ZOOM), FCVars.GetBool('in_toggleZoom'));
    AdjustAngles;
    CmdButtons;
    KeyMove;
    MouseMove;
    JoystickMove;
    // check to make sure the angles haven't wrapped
    if Double(FViewAngles[PITCH]) - LOldPitch > 90 then
      FViewAngles[PITCH] := Double(LOldPitch) + 90
    else if Double(LOldPitch) - FViewAngles[PITCH] > 90 then
      FViewAngles[PITCH] := Double(LOldPitch) - 90;
  end
  else
  begin
    FMouseDx := 0;
    FMouseDy := 0;
  end;
  for LIndex := 0 to 2 do
    FCmd.Angles[LIndex] := AngleToShort(FViewAngles[LIndex]);
  FCmd.Mx := SmallInt(FContinuousMouseX);
  FCmd.My := SmallInt(FContinuousMouseY);
  FFlags := FCmd.Flags;
  FImpulse := FCmd.Impulse;
end;

function TD3UsercmdGen.CommandStringUsercmdData(const ACommand: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(D3_USER_COMMANDS) to High(D3_USER_COMMANDS) do
    if SameText(string(ACommand), string(D3_USER_COMMANDS[LIndex].Name)) then
      Exit(D3_USER_COMMANDS[LIndex].Button);
  Result := UB_NONE;
end;

procedure TD3UsercmdGen.Init;
begin
  FInitialized := True;
end;

procedure TD3UsercmdGen.InitForNewMap;
begin
  FFlags := 0;
  FImpulse := 0;
  FToggledCrouch.Clear;
  FToggledRun.Clear;
  FToggledZoom.Clear;
  if FCVars.GetBool('in_alwaysRun') then
    FToggledRun.On_ := 1;
  Clear;
  ClearAngles;
end;

procedure TD3UsercmdGen.Shutdown;
begin
  FInitialized := False;
end;

procedure TD3UsercmdGen.Clear;
begin
  // clears all key states
  FillChar(FButtonState, SizeOf(FButtonState), 0);
  FillChar(FKeyState, SizeOf(FKeyState), 0);
  FInhibitCommands := 0;
  FMouseDx := 0;
  FMouseDy := 0;
  FMouseButton := 0;
  FMouseDown := False;
end;

procedure TD3UsercmdGen.ClearAngles;
begin
  FViewAngles[0] := 0;
  FViewAngles[1] := 0;
  FViewAngles[2] := 0;
end;

function TD3UsercmdGen.TicCmd(const ATicNumber: Integer): TD3Usercmd;
begin
  // the packet client code can legally ask for com_ticNumber + 1, because it is in the async code and
  // com_ticNumber has not been updated yet, but all other code should never ask for anything greater
  if ATicNumber > FState.TicNumber + 1 then
    FErrors.Error(STicTooNew);
  Result := FBuffered[ATicNumber and (D3_MAX_BUFFERED_USERCMD - 1)];
end;

procedure TD3UsercmdGen.Key(const AKey: Integer; const ADown: Boolean);
var
  LAction: Integer;
begin
  // sanity check, sometimes we get double message
  if FKeyState[AKey] = ADown then
    Exit;
  FKeyState[AKey] := ADown;
  LAction := FActions.GetUsercmdAction(AKey);
  if ADown then
  begin
    Inc(FButtonState[LAction]);
    if not Inhibited then
      if (LAction >= UB_IMPULSE0) and (LAction <= UB_IMPULSE61) then
      begin
        FCmd.Impulse := ShortInt(LAction - UB_IMPULSE0);
        FCmd.Flags := FCmd.Flags xor UCF_IMPULSE_SEQUENCE;
      end;
  end
  else
  begin
    Dec(FButtonState[LAction]);
    // we might have one held down across an app active transition
    if FButtonState[LAction] < 0 then
      FButtonState[LAction] := 0;
  end;
end;

procedure TD3UsercmdGen.Mouse;
var
  LCount: Integer;
  LIndex: Integer;
  LAction: Integer;
  LValue: Integer;
  LKey: Integer;
begin
  LCount := FDevices.PollMouseEvents;
  for LIndex := 0 to LCount - 1 do
    if FDevices.ReturnMouseEvent(LIndex, LAction, LValue) then
    begin
      if (LAction >= M_ACTION1) and (LAction <= M_ACTION8) then
      begin
        FMouseButton := K_MOUSE1 + (LAction - M_ACTION1);
        FMouseDown := LValue <> 0;
        Key(FMouseButton, FMouseDown);
      end
      else
        case LAction of
          M_DELTAX:
            begin
              Inc(FMouseDx, LValue);
              Inc(FContinuousMouseX, LValue);
            end;
          M_DELTAY:
            begin
              Inc(FMouseDy, LValue);
              Inc(FContinuousMouseY, LValue);
            end;
          M_DELTAZ:
            begin
              if LValue < 0 then
                LKey := K_MWHEELDOWN
              else
                LKey := K_MWHEELUP;
              LValue := Abs(LValue);
              while LValue > 0 do
              begin
                Dec(LValue);
                Key(LKey, True);
                Key(LKey, False);
                FMouseButton := LKey;
                FMouseDown := True;
              end;
            end;
        end;
    end;
  FDevices.EndMouseEvents;
end;

procedure TD3UsercmdGen.Keyboard;
var
  LCount: Integer;
  LIndex: Integer;
  LKey: Integer;
  LState: Boolean;
begin
  LCount := FDevices.PollKeyboardEvents;
  for LIndex := 0 to LCount - 1 do
    if FDevices.ReturnKeyboardEvent(LIndex, LKey, LState) then
      Key(LKey, LState);
  FDevices.EndKeyboardEvents;
end;

procedure TD3UsercmdGen.Joystick;
begin
  FillChar(FJoystickAxis, SizeOf(FJoystickAxis), 0);
end;

procedure TD3UsercmdGen.UsercmdInterrupt;
begin
  // dedicated servers won't create usercmds
  if not FInitialized then
    Exit;
  InitCurrent;
  Mouse;
  Keyboard;
  Joystick;
  MakeCurrent;
  // save a number for debugging cmdDemos and networking
  FCmd.Sequence := FState.TicNumber + 1;
  FBuffered[(FState.TicNumber + 1) and (D3_MAX_BUFFERED_USERCMD - 1)] := FCmd;
end;

procedure TD3UsercmdGen.MouseState(out AX, AY, AButton: Integer; out ADown: Boolean);
begin
  AX := FContinuousMouseX;
  AY := FContinuousMouseY;
  AButton := FMouseButton;
  ADown := FMouseDown;
end;

function TD3UsercmdGen.GetDirectUsercmd: TD3Usercmd;
begin
  InitCurrent;
  Mouse;
  Keyboard;
  Joystick;
  MakeCurrent;
  FCmd.DuplicateCount := 0;
  Result := FCmd;
end;

function TD3UsercmdGen.ViewAngle(const AIndex: Integer): Single;
begin
  Result := FViewAngles[AIndex];
end;

function TD3UsercmdGen.Flags: Integer;
begin
  Result := FFlags;
end;

function TD3UsercmdGen.Impulse: Integer;
begin
  Result := FImpulse;
end;

function TD3UsercmdGen.InhibitMask: Integer;
begin
  Result := FInhibitCommands;
end;

function TD3UsercmdGen.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

function TD3UsercmdGen.ToggledRun: Integer;
begin
  Result := FToggledRun.On_;
end;

function TD3UsercmdGen.ToggledRunHeld: Boolean;
begin
  Result := FToggledRun.Held;
end;

function TD3UsercmdGen.ToggledCrouch: Integer;
begin
  Result := FToggledCrouch.On_;
end;

function TD3UsercmdGen.ToggledCrouchHeld: Boolean;
begin
  Result := FToggledCrouch.Held;
end;

function TD3UsercmdGen.ToggledZoom: Integer;
begin
  Result := FToggledZoom.On_;
end;

function TD3UsercmdGen.ToggledZoomHeld: Boolean;
begin
  Result := FToggledZoom.Held;
end;

function TD3UsercmdGen.MouseDeltaX: Integer;
begin
  Result := FMouseDx;
end;

function TD3UsercmdGen.MouseDeltaY: Integer;
begin
  Result := FMouseDy;
end;

end.
