{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contract of the keys that the player chose   }
{  Port of xGreed (Jim Valavanis): scanbuttons of d_ints.pas, loaded by the     }
{  bt_* settings of m_defs.pas                                                  }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.KeyBindings.Intf;

interface

uses
  DelphiDoom.Greed.PlayerControl.Intf;

type
  /// <summary>
  ///   The keys that xGreed.ini binds to the 19 buttons of the game (bt_north ... bt_motionmode, the first 19
  ///   commands of TGreedCommand). The other commands (the menu, the function keys, the digits, the map, the pause)
  ///   are fixed keys in the original and have no binding
  /// </summary>
  IGreedKeyBindings = interface
    ['{6A1F3C58-9D24-4E7B-B0C5-28E4D917A3F6}']
    /// <summary>True for the 19 commands that the player can bind</summary>
    function IsBindable(ACommand: TGreedCommand): Boolean;
    /// <summary>
    ///   The virtual key that the player chose for a bindable command; 0 if the scan code of the file is not a key
    ///   of the table (the command is then never pressed, as the original reads a key that does not exist). 0 also
    ///   for a command that is not bindable
    /// </summary>
    function VirtualKeyOf(ACommand: TGreedCommand): Integer;
  end;

implementation

end.
