{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the contract                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Draws the text screen shown at the end of the game (80x25 cells, a character and an
  ///   attribute each) in a picture of 640x200 pixels. It knows nothing of WADs or of video:
  ///   it gets the bytes of the lump, of the font and the colors, and fills a buffer
  /// </summary>
  IEndoomRenderer = interface
    ['{3E7A9C21-5D84-4B16-A0F3-8C2D61E7B945}']
    /// <summary>
    ///   Draws the picture with the 8 bit colors AColorIndices (one palette index for each of the
    ///   16 text colors). AScreen is the lump: for each cell a character and an attribute (low
    ///   nibble the foreground, bits 4..6 the background, bit 7 the blinking). AFont is the picture
    ///   of DOSFONT, 128x128 bytes, 0 is the background; the character 1 is the first of the
    ///   font. A lump or a font shorter than the normal size reads as zeros. When ABlinkVisible
    ///   is false the cells that blink show only their background. AOutput gets 640x200 bytes
    /// </summary>
    procedure RenderIndexed(const AScreen, AFont: TBytes; const AColorIndices: array of Byte;
      ABlinkVisible: Boolean; var AOutput: TBytes);
    /// <summary>
    ///   Turns the 8 bit picture into colors: APalette has 256 entries, each value is written
    ///   with the alpha $FF. AOutput is made of rows of AStride pixels (at least 640) and 200
    ///   rows; the pixels over the 640th of each row are not touched (zero on a new buffer).
    ///   A buffer smaller than that is made bigger, a bigger one is kept as it is
    /// </summary>
    procedure ConvertToRgb32(const AIndexed: TBytes; const APalette: array of Cardinal;
      AStride: Integer; var AOutput: TArray<Cardinal>);
  end;

  /// <summary>
  ///   The time of the end screen, counted in tics: the blinking (half a second on, half off),
  ///   when a key may close the program (after half a second) and when the program closes by
  ///   itself (after ten seconds). It does not close anything: it says when
  /// </summary>
  IEndoomSession = interface
    ['{6D18F2A4-B39E-4C07-8A51-E2F704C9D3B6}']
    /// <summary>The screen is shown: the count starts and the picture must be drawn</summary>
    procedure Start;
    /// <summary>
    ///   One tic. Nothing happens before Start. True when the ten seconds are over (the program
    ///   should close; it is said again at every tic after that)
    /// </summary>
    function Tick: Boolean;
    /// <summary>True if a key that is released closes the program: half a second after Start</summary>
    function AcceptsKey: Boolean;
    /// <summary>Whether the blinking cells show their character now</summary>
    function IsBlinkVisible: Boolean;
    /// <summary>The picture changed (start or blinking) since it was drawn last</summary>
    function NeedsRedraw: Boolean;
    /// <summary>The picture has been drawn</summary>
    procedure Drawn;
  end;

implementation

end.
