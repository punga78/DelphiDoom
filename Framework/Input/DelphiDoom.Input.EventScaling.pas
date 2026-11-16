{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - mouse and joystick events as the game wants them}
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.EventScaling;

// The scaling wraps as the old code did (the products of the mouse are small)
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The numbers G_Responder of g_game takes from the events of the mouse and of the joystick
  ///   (the same code was in each game)
  /// </summary>
  TInputEventScaling = class sealed
  public
    /// <summary>How much a motion of the mouse moves the player</summary>
    /// <param name="AMotion">The motion of the event, in mickeys</param>
    /// <param name="ASensitivity">The sensitivity of the options (mouseSensitivity)</param>
    /// <param name="AAxisSensitivity">The sensitivity of the axis (mouseSensitivityX or Y)</param>
    class function MouseMotion(const AMotion, ASensitivity, AAxisSensitivity: Integer): Integer; static;

    /// <summary>Writes the state of the buttons of the joystick from the mask of an event</summary>
    /// <param name="AMask">Bit n is the button n</param>
    /// <param name="AButtons">The first of the booleans of the buttons (joybuttons)</param>
    /// <param name="ACount">How many buttons</param>
    class procedure JoystickButtons(const AMask: Integer; const AButtons: PBoolean;
      const ACount: Integer); static;
  end;

implementation

{ TInputEventScaling }

class function TInputEventScaling.MouseMotion(const AMotion, ASensitivity,
  AAxisSensitivity: Integer): Integer;
begin
  Result := ((AMotion * (ASensitivity + 5)) div 10) * AAxisSensitivity div 5;
end;

class procedure TInputEventScaling.JoystickButtons(const AMask: Integer; const AButtons: PBoolean;
  const ACount: Integer);
var
  LButton: PBoolean;
  LIndex: Integer;
  LBit: Integer;
begin
  LButton := AButtons;
  LBit := 1;
  for LIndex := 0 to ACount - 1 do
  begin
    LButton^ := (AMask and LBit) <> 0;
    Inc(LButton);
    LBit := LBit * 2;
  end;
end;

end.
