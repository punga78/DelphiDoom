{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the settings of the mouse                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the entries mouse,          }
{  menumouse, mousesensitivity, mousesensitivityx, mousesensitivityy,           }
{  invertmouseturn and invertmouselook of the defaults table of m_defs.pas      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MouseSettings;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.PlayerControl, DelphiDoom.Greed.Mouse.Intf;

const
  GREED_SETTING_MOUSE = 'mouse';
  GREED_SETTING_MENU_MOUSE = 'menumouse';
  GREED_SETTING_MOUSE_SENSITIVITY = 'mousesensitivity';
  GREED_SETTING_MOUSE_SENSITIVITY_X = 'mousesensitivityx';
  GREED_SETTING_MOUSE_SENSITIVITY_Y = 'mousesensitivityy';
  GREED_SETTING_INVERT_MOUSE_TURN = 'invertmouseturn';
  GREED_SETTING_INVERT_MOUSE_LOOK = 'invertmouselook';

type
  /// <summary>
  ///   In the original the table of the settings points to the variables that the game reads (SC.mouse,
  ///   SC.mousesensitivity, mousesensitivityx, mousesensitivityy, invertmouseturn, invertmouselook of
  ///   ControlMovement, menuusemouse of the menus): here the values of the settings are given to who reads them
  /// </summary>
  TGreedMouseSettings = class
  public
    /// <summary>
    ///   The settings of the mouse go to the control of the player and to the mouse. Without a mouse (nil) the
    ///   control of the player does not use it, whatever the settings say (mouseinstalled is false).
    ///   EArgumentNilException if ASettings or AControl is nil
    /// </summary>
    class procedure Apply(const ASettings: IGreedSettings; AControl: TGreedPlayerControl;
      const AMouse: IGreedMouse); static;
  end;

implementation

{ TGreedMouseSettings }

class procedure TGreedMouseSettings.Apply(const ASettings: IGreedSettings; AControl: TGreedPlayerControl;
  const AMouse: IGreedMouse);
begin
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AControl) then
    raise EArgumentNilException.Create('AControl');
  AControl.MouseEnabled := Assigned(AMouse) and ASettings.GetBoolean(GREED_SETTING_MOUSE);
  AControl.MouseSensitivity := ASettings.GetInteger(GREED_SETTING_MOUSE_SENSITIVITY);
  AControl.MouseSensitivityX := ASettings.GetInteger(GREED_SETTING_MOUSE_SENSITIVITY_X);
  AControl.MouseSensitivityY := ASettings.GetInteger(GREED_SETTING_MOUSE_SENSITIVITY_Y);
  AControl.InvertMouseTurn := ASettings.GetBoolean(GREED_SETTING_INVERT_MOUSE_TURN);
  AControl.InvertMouseLook := ASettings.GetBoolean(GREED_SETTING_INVERT_MOUSE_LOOK);
  if Assigned(AMouse) then
    AMouse.MenuEnabled := ASettings.GetBoolean(GREED_SETTING_MENU_MOUSE);
end;

end.
