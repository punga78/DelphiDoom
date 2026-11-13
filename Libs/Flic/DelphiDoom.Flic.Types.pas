{******************************************************************************}
{                                                                              }
{  DelphiDoom: flic library - shared types (issue #229)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Flic.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The bytes are not a FLI/FLC animation, or a chunk reads past the end of the file or writes outside the
  ///   picture (what the C++ of OpenXcom leaves undefined)
  /// </summary>
  EFlicFormatException = class(Exception);

  /// <summary>One color of the palette of an animation (8 bit per channel, Alpha is 255 for a color that was set)</summary>
  TFlicColor = packed record
    Red: Byte;
    Green: Byte;
    Blue: Byte;
    Alpha: Byte;
  end;

implementation

end.
