{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the types shared by the displays of the game            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.VideoDevice.Types;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>A display cannot be made on this machine (no OpenGL context, for instance); the message says why</summary>
  EXcomVideoDeviceException = class(Exception);

  /// <summary>Makes a display; called when the display is first needed and each time the kind of display changes</summary>
  TXcomVideoDeviceFactory = reference to function: IXcomVideoDevice;

implementation

end.
