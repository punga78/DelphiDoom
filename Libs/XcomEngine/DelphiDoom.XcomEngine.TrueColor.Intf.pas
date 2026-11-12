{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the contracts of the composition of the    }
{  frame in true color (issue 183): the content of the game stays at 8 bits,    }
{  the last step of the screen can make a picture of colors                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.TrueColor.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>A frame of colors: one $FFRRGGBB value per pixel, rows from the top</summary>
  TXcomTrueColorPixels = TArray<Cardinal>;

  /// <summary>
  ///   What a display that shows a picture of colors also does (an optional interface of the device, as
  ///   IXcomWindowStyle): the picture has the size of the display, nothing is left to scale or to convert
  /// </summary>
  IXcomTrueColorDisplay = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000001}']
    /// <summary>False when the device cannot show it (the screen then presents the 8 bit picture as before)</summary>
    function PresentTrueColor(const APixels: TXcomTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

  /// <summary>
  ///   Where a widget that can draw itself finer than the game picture leaves that drawing. The game picture
  ///   (the base surface, 8 bits) is shown DetailScale times larger; a widget that draws vectors (the globe)
  ///   also draws them on a surface of its own DetailScale times larger, with the same palette indexes, and
  ///   brackets its blit on the base surface with BeginLayer and EndLayer. When the frame is composed, the pixels
  ///   of the base surface that still are the ones the widget left take the detail; the ones that something drawn
  ///   later covered do not. The order of the blits of the game is therefore kept
  /// </summary>
  IXcomDetailLayers = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000002}']
    /// <summary>How many pixels of the display a pixel of the game picture takes on each side; 1: no detail is used</summary>
    function DetailScale: Integer;
    /// <summary>Before the widget blits: the rectangle of the base surface (in its pixels) it is going to draw on</summary>
    procedure BeginLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
    /// <summary>
    ///   After the widget has blitted. ADetail is DetailScale times the rectangle, color 0 where the widget draws
    ///   nothing; it is not owned and must live until the frame is flipped
    /// </summary>
    procedure EndLayer(ABase, ADetail: TXcomSurface);
  end;

  /// <summary>
  ///   The strategy the screen flips with when it is given one: it makes the final frame of colors from the base
  ///   surface and the palette (applied here, at the composition) and shows it. Without one the screen scales the
  ///   indexes and gives them to the device with the palette, as OpenXcom does
  /// </summary>
  IXcomFrameComposer = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000003}']
    /// <summary>Screen::resetDisplay: the sizes of the game picture and of the display, and the bands around the picture</summary>
    procedure SetGeometry(ABaseWidth, ABaseHeight, ADisplayWidth, ADisplayHeight: Integer;
      const ABands: TXcomBlackBands);
    /// <summary>Composes and shows the frame; false when it could not (the screen goes on as without a composer)</summary>
    function Present(ABase: TXcomSurface; const APalette: TXcomColors): Boolean;
    /// <summary>Where the widgets leave their finer drawings</summary>
    function DetailLayers: IXcomDetailLayers;
  end;

  /// <summary>
  ///   Gives the screen its composer each time the display is reset (the options can turn the composition in true
  ///   color on and off while the game runs); nil: the 8 bit path
  /// </summary>
  TXcomFrameComposerSource = reference to function: IXcomFrameComposer;

implementation

end.
