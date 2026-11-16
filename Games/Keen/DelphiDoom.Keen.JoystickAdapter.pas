{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the joystick of Windows as the game port of DOS   }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.JoystickAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   The game port gives a count of the timing loop for each axis: about 1000 with the stick at the centre,
  ///   at most MaxJoyValue. The joystick of Windows reports 0..65535 on each axis; here the reading is scaled to
  ///   1..2000 so that the centre is where INL_StartJoy expects it. Only the first joystick exists. While the gate
  ///   is closed the stick is at the centre with no button pressed: a window in the background is not moved by it
  /// </summary>
  TKeenJoystickAdapter = class(TInterfacedObject, IKeenJoysticks)
  strict private
    FJoystick: IJoystickDevice;
    FGate: IInputGate;
    FPresent: Boolean;
    function Scale(AValue: Integer): Word;
    function IsAllowed: Boolean;
  public
    /// <param name="AJoystick">The joystick; it is started here</param>
    /// <param name="AGate">When the program listens to the joystick (the window in the foreground); nil for always</param>
    constructor Create(const AJoystick: IJoystickDevice; const AGate: IInputGate = nil);
    function IsPresent(AJoy: Integer): Boolean;
    procedure GetAbs(AJoy: Integer; out AX, AY: Word);
    function GetButtons(AJoy: Integer): Word;
  end;

implementation

{ TKeenJoystickAdapter }

constructor TKeenJoystickAdapter.Create(const AJoystick: IJoystickDevice; const AGate: IInputGate);
begin
  inherited Create;
  if not Assigned(AJoystick) then
    raise EArgumentNilException.Create('AJoystick');
  FJoystick := AJoystick;
  FGate := AGate;
  FPresent := FJoystick.Initialize;
end;

function TKeenJoystickAdapter.Scale(AValue: Integer): Word;
begin
  if AValue < 0 then
    AValue := 0
  else if AValue > 65535 then
    AValue := 65535;
  Result := Word(1 + (Int64(AValue) * 1999) div 65535);
end;

function TKeenJoystickAdapter.IsAllowed: Boolean;
begin
  Result := (not Assigned(FGate)) or FGate.IsInputAllowed;
end;

function TKeenJoystickAdapter.IsPresent(AJoy: Integer): Boolean;
begin
  Result := FPresent and (AJoy = 0);
end;

procedure TKeenJoystickAdapter.GetAbs(AJoy: Integer; out AX, AY: Word);
var
  LReading: TJoystickReading;
begin
  AX := 0;
  AY := 0;
  if not IsPresent(AJoy) then
    Exit;
  if not IsAllowed then
  begin
    // the centre of the stick
    AX := Scale(32768);
    AY := Scale(32768);
    Exit;
  end;
  if FJoystick.Read(LReading) then
  begin
    AX := Scale(LReading.X);
    AY := Scale(LReading.Y);
  end;
end;

function TKeenJoystickAdapter.GetButtons(AJoy: Integer): Word;
var
  LReading: TJoystickReading;
begin
  Result := 0;
  if (not IsPresent(AJoy)) or (not IsAllowed) then
    Exit;
  if FJoystick.Read(LReading) then
    Result := Word(LReading.Buttons and 3);
end;

end.
