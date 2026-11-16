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
  System.SysUtils,
  DelphiDoom.Endoom.Types;

type
  /// <summary>
  ///   The text screen that a tool edits: 80x25 cells, the same 4000 bytes as the lump (a character
  ///   and an attribute per cell, row after row). A cell outside of the screen raises
  ///   EEndoomException; so does a color that does not exist (a foreground is 0..15, a background
  ///   0..7: the same indices as ENDOOM_COLORS)
  /// </summary>
  IEndoomScreen = interface
    ['{B4D82A6F-31C7-49E5-8A0B-6F5C9E1D2073}']
    function GetCell(AX, AY: Integer): TEndoomCell;
    procedure SetCell(AX, AY: Integer; const ACell: TEndoomCell);
    function GetCharacter(AX, AY: Integer): Byte;
    procedure SetCharacter(AX, AY: Integer; ACode: Byte);
    function GetForeground(AX, AY: Integer): Integer;
    procedure SetForeground(AX, AY: Integer; AColor: Integer);
    function GetBackground(AX, AY: Integer): Integer;
    procedure SetBackground(AX, AY: Integer; AColor: Integer);
    function GetBlink(AX, AY: Integer): Boolean;
    procedure SetBlink(AX, AY: Integer; ABlink: Boolean);
    /// <summary>Every cell becomes 0, 0: no character, black on black, no blinking</summary>
    procedure Clear;
    /// <summary>The same background (0..7) for the cells of a rectangle; the part outside is ignored</summary>
    procedure FillBackground(const ARect: TEndoomRect; AColor: Integer);
    /// <summary>The same foreground (0..15) for the cells of a rectangle; the part outside is ignored</summary>
    procedure FillForeground(const ARect: TEndoomRect; AColor: Integer);
    /// <summary>The same character for the cells of a rectangle; the part outside is ignored</summary>
    procedure FillCharacter(const ARect: TEndoomRect; ACode: Byte);
    /// <summary>Takes the cells of a rectangle (the part outside of the screen is left out)</summary>
    function CopyBlock(const ARect: TEndoomRect): TEndoomBlock;
    /// <summary>Puts a block with its top left corner in a cell; what falls outside is dropped</summary>
    procedure PasteBlock(const ABlock: TEndoomBlock; AX, AY: Integer);
    /// <summary>The 4000 bytes of the lump</summary>
    function ToBytes: TBytes;
    /// <summary>
    ///   Takes the first 4000 bytes of a lump or of a file; fewer bytes are not a text screen and
    ///   raise EEndoomException (the old tool kept the old cells for the missing bytes)
    /// </summary>
    procedure LoadFromBytes(const ABytes: TBytes);
    /// <summary>This screen becomes a copy of another (the old AssignTo did it the other way round)</summary>
    procedure AssignFrom(const ASource: IEndoomScreen);
    function IsSameAs(const AOther: IEndoomScreen): Boolean;
  end;

  /// <summary>Where the picture of the font (DOSFONT: 128x128 bytes, 0 is the background) comes from</summary>
  IEndoomFontSource = interface
    ['{5A93E0C8-D17B-4F26-92A4-0B7E8C3D6F15}']
    function GetFont: TBytes;
  end;

  /// <summary>
  ///   The picture of a text screen for a window or for a file: 640x200 pixels of $FFRRGGBB with
  ///   the colors of ENDOOM_COLORS
  /// </summary>
  IEndoomScreenImage = interface
    ['{E81F4D37-6A92-4C0B-B5D8-3F2A9C7E1046}']
    /// <summary>
    ///   Draws the screen. ABlinkVisible is the same flag as in IEndoomRenderer: true shows every
    ///   character, false hides those of the cells that blink. The old TEndScreen.GetBitmap had
    ///   the opposite flag: its blink = true was ABlinkVisible = false
    /// </summary>
    procedure Render(const AScreen: IEndoomScreen; const AFont: TBytes; ABlinkVisible: Boolean;
      var APixels: TArray<Cardinal>);
  end;

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
