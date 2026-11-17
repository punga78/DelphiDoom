{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the joystick among the commands of the game      }
{  An extension: xGreed (Jim Valavanis) keeps the settings of                   }
{  the joystick of the DOS game (SC.joystick, SC.joybut1, SC.joybut2, jcenx,    }
{  jceny, xsense, ysense of protos_h.pas and modplay.pas) but never reads one   }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.JoystickControls;

interface

uses
  System.SysUtils, DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.CommandState;

const
  /// <summary>How far from its centre an axis must be to count as pressed, of the 0..65535 of the device</summary>
  GREED_JOYSTICK_THRESHOLD = 8192;

type
  /// <summary>
  ///   What the joystick does: the settings that InitDefaults of modplay.pas gives and nothing of the original
  ///   reads (SC.joybut1 = bt_fire, SC.joybut2 = bt_straf), and the distance from the centre at which an axis is
  ///   a direction (xsense and ysense of the original have no default)
  /// </summary>
  TGreedJoystickOptions = record
    /// <summary>SC.joybut1 and SC.joybut2: the commands of the first two buttons</summary>
    Button1: TGreedCommand;
    Button2: TGreedCommand;
    Threshold: Integer;
    /// <summary>Fire, strafe and GREED_JOYSTICK_THRESHOLD</summary>
    class function Standard: TGreedJoystickOptions; static;
  end;

  /// <summary>
  ///   IGreedCommandSource that adds a joystick of Framework\Input to another source: a command is pressed if the
  ///   other source or the joystick says so. The stick is the four directions (north, south, west, east: with
  ///   the strafe command the game steps aside, as with the arrows), measured from where the stick is at the
  ///   first reading (jcenx and jceny); the first two buttons are the commands of the options. The joystick is
  ///   read once for each reading of the controls; without a device (Initialize says there is none, or a reading
  ///   fails) it presses nothing.
  ///   xGreed does not have this: SC.joystick is 0 and no code reads a joystick (d_ints.pas declares joyinstalled,
  ///   jx, jy, j1, j2 and never uses them). The program turns it on only when it is asked to
  /// </summary>
  TGreedJoystickControls = class(TInterfacedObject, IGreedCommandSource)
  strict private
    type
      TGreedCommandSet = set of TGreedCommand;
    var
      FKeys: IGreedCommandSource;
      FJoystick: IJoystickDevice;
      FOptions: TGreedJoystickOptions;
      FInstalled: Boolean;
      FCentered: Boolean;
      FCenterX: Integer;
      FCenterY: Integer;
      FPressed: TGreedCommandSet;
  public
    /// <summary>Starts the joystick. EArgumentNilException if AKeys or AJoystick is nil</summary>
    constructor Create(const AKeys: IGreedCommandSource; const AJoystick: IJoystickDevice;
      const AOptions: TGreedJoystickOptions);
    destructor Destroy; override;
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
    /// <summary>joyinstalled: the device said that there is a joystick</summary>
    property Installed: Boolean read FInstalled;
  end;

implementation

const
  BUTTON_1 = 1;
  BUTTON_2 = 2;

{ TGreedJoystickOptions }

class function TGreedJoystickOptions.Standard: TGreedJoystickOptions;
begin
  Result.Button1 := gcFire;
  Result.Button2 := gcStrafe;
  Result.Threshold := GREED_JOYSTICK_THRESHOLD;
end;

{ TGreedJoystickControls }

constructor TGreedJoystickControls.Create(const AKeys: IGreedCommandSource; const AJoystick: IJoystickDevice;
  const AOptions: TGreedJoystickOptions);
begin
  inherited Create;
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  if not Assigned(AJoystick) then
    raise EArgumentNilException.Create('AJoystick');
  FKeys := AKeys;
  FJoystick := AJoystick;
  FOptions := AOptions;
  FInstalled := FJoystick.Initialize;
end;

destructor TGreedJoystickControls.Destroy;
begin
  if FInstalled then
    FJoystick.Shutdown;
  inherited Destroy;
end;

procedure TGreedJoystickControls.BeginReading;
var
  LReading: TJoystickReading;
begin
  FKeys.BeginReading;
  FPressed := [];
  if not FInstalled then
    Exit;
  if not FJoystick.Read(LReading) then
    Exit;
  if not FCentered then
  begin
    FCentered := True;
    FCenterX := LReading.X;
    FCenterY := LReading.Y;
  end;
  if LReading.X - FCenterX <= -FOptions.Threshold then
    Include(FPressed, gcWest)
  else if LReading.X - FCenterX >= FOptions.Threshold then
    Include(FPressed, gcEast);
  if LReading.Y - FCenterY <= -FOptions.Threshold then
    Include(FPressed, gcNorth)
  else if LReading.Y - FCenterY >= FOptions.Threshold then
    Include(FPressed, gcSouth);
  if (LReading.Buttons and BUTTON_1) <> 0 then
    Include(FPressed, FOptions.Button1);
  if (LReading.Buttons and BUTTON_2) <> 0 then
    Include(FPressed, FOptions.Button2);
end;

function TGreedJoystickControls.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := (ACommand in FPressed) or FKeys.IsPressed(ACommand);
end;

function TGreedJoystickControls.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := FKeys.TakeTyped(ACharacter);
end;

function TGreedJoystickControls.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := FKeys.IsMousePressed(AButton);
end;

procedure TGreedJoystickControls.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  FKeys.TakeMouseMove(ADeltaX, ADeltaY);
end;

end.
