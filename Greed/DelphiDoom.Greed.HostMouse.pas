{******************************************************************************}
{                                                                              }
{  Greed32: the mouse of the system as the game wants it, inside the window     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): lbuttondown, rbuttondown    }
{  and mbuttondown of d_ints.pas (set by the window procedure of i_main.pas),   }
{  getcursorposfunc, setcursorposfunc, I_WindowWidth, I_WindowHeight and the    }
{  test of the window in the foreground of INT_ReadControls                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HostMouse;

interface

uses
  DelphiDoom.GameHost.WindowMouse;

type
  /// <summary>
  ///   The device that the mouse of Greed32 reads: the mouse of the system inside the window of Libs\GameHost.
  ///   The class moved to Libs\GameHost (TGameHostWindowMouse, issue #165) when Keen32 needed the same device;
  ///   here it keeps the name that Greed32 and its tests use
  /// </summary>
  TGreedHostMouse = TGameHostWindowMouse;

implementation

end.
