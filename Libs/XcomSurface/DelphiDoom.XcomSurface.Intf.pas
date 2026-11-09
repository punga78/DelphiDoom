{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - contracts                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   The function that ShaderDraw applies to every pixel of a shaded blit: it changes the destination pixel
  ///   using the source pixel (the color functions of Surface.cpp)
  /// </summary>
  IXcomShadeFunction = interface
    ['{C3A1D5E2-7B44-4F0A-9E16-2D8B5A7C91F3}']
    /// <param name="AShade">The shade to add to the low four bits of the pixel</param>
    /// <param name="ANewColor">The color group to use (already shifted by four bits); ignored by the standard shade</param>
    procedure Apply(var ADest: Byte; ASource: Byte; AShade, ANewColor: Integer);
  end;

  /// <summary>Loads a picture of the game (a file of Language\, a .BMP, .PNG...) into a surface (Surface::loadImage)</summary>
  IXcomSurfaceLoader = interface
    ['{5E7F2A91-3C68-4B1D-A4E0-8F6D1B9C0A27}']
    /// <param name="AWidth">The size the surface is created with before the file is loaded</param>
    function LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
  end;

implementation

end.
