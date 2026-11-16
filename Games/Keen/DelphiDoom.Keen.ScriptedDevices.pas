{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the mouse and the joystick of a run that a        }
{  script drives                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ScriptedDevices;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

const
  /// <summary>Where the stick of a scripted joystick is at the start: the centre of the game port</summary>
  KEEN_SCRIPT_JOYSTICK_CENTER = 1000;

type
  /// <summary>
  ///   The mouse and the first joystick as a script moves them, so that a run without a player can use them as a
  ///   player does: the mouse gives what it moved since the last look (the DOS driver counts mickeys), the
  ///   joystick gives where the stick is and which buttons are down
  /// </summary>
  TKeenScriptedDevices = class(TInterfacedObject, IKeenMouse, IKeenJoysticks)
  strict private
    FMousePresent: Boolean;
    FJoystickPresent: Boolean;
    FPendingX: Integer;
    FPendingY: Integer;
    FMouseButtons: Word;
    FJoystickX: Word;
    FJoystickY: Word;
    FJoystickButtons: Word;
  public
    /// <param name="AMousePresent">There is a mouse</param>
    /// <param name="AJoystickPresent">There is a first joystick</param>
    constructor Create(AMousePresent, AJoystickPresent: Boolean);
    /// <summary>The mouse moved: the next look gives the sum of the movements since the last one</summary>
    procedure MoveMouse(ADeltaX, ADeltaY: Integer);
    /// <summary>The buttons of the mouse that are down: bit 0 left, bit 1 right, bit 2 middle</summary>
    procedure SetMouseButtons(AButtons: Word);
    /// <summary>The stick is at this place of the game port (about 1000 at the centre)</summary>
    procedure SetJoystickPosition(AX, AY: Word);
    /// <summary>The buttons of the joystick that are down: bit 0 the first, bit 1 the second</summary>
    procedure SetJoystickButtons(AButtons: Word);
    // IKeenMouse
    function IsPresent: Boolean; overload;
    procedure GetDelta(out ADeltaX, ADeltaY: Integer);
    function GetButtons: Word; overload;
    // IKeenJoysticks
    function IsPresent(AJoy: Integer): Boolean; overload;
    procedure GetAbs(AJoy: Integer; out AX, AY: Word);
    function GetButtons(AJoy: Integer): Word; overload;
  end;

implementation

{ TKeenScriptedDevices }

constructor TKeenScriptedDevices.Create(AMousePresent, AJoystickPresent: Boolean);
begin
  inherited Create;
  FMousePresent := AMousePresent;
  FJoystickPresent := AJoystickPresent;
  FJoystickX := KEEN_SCRIPT_JOYSTICK_CENTER;
  FJoystickY := KEEN_SCRIPT_JOYSTICK_CENTER;
end;

procedure TKeenScriptedDevices.MoveMouse(ADeltaX, ADeltaY: Integer);
begin
  Inc(FPendingX, ADeltaX);
  Inc(FPendingY, ADeltaY);
end;

procedure TKeenScriptedDevices.SetMouseButtons(AButtons: Word);
begin
  FMouseButtons := AButtons and 7;
end;

procedure TKeenScriptedDevices.SetJoystickPosition(AX, AY: Word);
begin
  FJoystickX := AX;
  FJoystickY := AY;
end;

procedure TKeenScriptedDevices.SetJoystickButtons(AButtons: Word);
begin
  FJoystickButtons := AButtons and 3;
end;

function TKeenScriptedDevices.IsPresent: Boolean;
begin
  Result := FMousePresent;
end;

procedure TKeenScriptedDevices.GetDelta(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := FPendingX;
  ADeltaY := FPendingY;
  FPendingX := 0;
  FPendingY := 0;
end;

function TKeenScriptedDevices.GetButtons: Word;
begin
  Result := FMouseButtons;
end;

function TKeenScriptedDevices.IsPresent(AJoy: Integer): Boolean;
begin
  Result := FJoystickPresent and (AJoy = 0);
end;

procedure TKeenScriptedDevices.GetAbs(AJoy: Integer; out AX, AY: Word);
begin
  if IsPresent(AJoy) then
  begin
    AX := FJoystickX;
    AY := FJoystickY;
  end
  else
  begin
    AX := 0;
    AY := 0;
  end;
end;

function TKeenScriptedDevices.GetButtons(AJoy: Integer): Word;
begin
  if IsPresent(AJoy) then
    Result := FJoystickButtons
  else
    Result := 0;
end;

end.
