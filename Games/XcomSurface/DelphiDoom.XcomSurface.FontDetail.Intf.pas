{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the contracts of the text drawn at the    }
{  resolution of the display (issue 184): the finer characters of a font and    }
{  where a widget leaves the ink of its text                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.FontDetail.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Ink.Types;

type
  /// <summary>
  ///   Where a widget leaves the ink of its text for the frame that is being drawn. The widget draws its text on
  ///   the picture of the game as always and brackets that blit with BeginInk and EndInk: when the frame is
  ///   composed, the pixels of the picture that still are the ones the widget left show the ink instead of the
  ///   text of the picture; what was drawn later covers it. The ink is of one frame
  /// </summary>
  IXcomInkLayers = interface
    ['{5E0C7A41-2B9D-4F83-9A16-184000000001}']
    /// <summary>
    ///   Before the widget blits on ABase at this rectangle (pixels of the game; it may go out of the picture).
    ///   False when ABase is not the picture of the screen or no ink is used: then EndInk must not be called
    /// </summary>
    function BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
    /// <summary>
    ///   After the widget has blitted. AInk has the size of the rectangle. AUnder, when given, is the widget
    ///   without its text (one index per pixel of the rectangle, 0 where it draws nothing): it is what shows
    ///   where the text of the picture is taken away; without it, what was on the picture before the widget
    /// </summary>
    procedure EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
  end;

  /// <summary>
  ///   The characters of a font of the game at the resolution of the display: a font that was laid over the
  ///   pictures of the game (a font of the system) can draw them again, finer, for the same cells
  /// </summary>
  IXcomFontDetail = interface
    ['{5E0C7A41-2B9D-4F83-9A16-184000000002}']
    /// <summary>How many pixels of the display a pixel of the game takes; less than 2: the text is not drawn finer</summary>
    function Scale: Integer;
    /// <summary>
    ///   The character at the current scale; false when the font of the system does not draw it (it is then the
    ///   picture of the game, enlarged)
    /// </summary>
    function TryGetGlyph(ACode: Cardinal; out AGlyph: TXcomDetailGlyph): Boolean;
    /// <summary>Where the ink goes</summary>
    function Layers: IXcomInkLayers;
  end;

implementation

end.
