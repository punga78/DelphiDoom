{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the screens and the palette, without the drawing       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Video.Screens.Intf;

interface

uses
  d_delphi;

type
  /// <summary>
  ///   What a class of the engine asks of the screens of v_video.pas when it is not drawing
  ///   pixel by pixel: the palette, the nearest color of a palette and a whole picture put on
  ///   a screen. The drawing of patches, rectangles and blocks, and what the renderer calls at
  ///   each frame, stay in v_video.pas
  /// </summary>
  IEngineScreens = interface
    ['{A3D94E17-6B28-4C05-8F1A-71E0B5C92D64}']
    /// <summary>
    ///   Sets the palette of the screens and of the display (V_SetPalette, then I_SetPalette).
    ///   The palette is 768 bytes, R, G, B
    /// </summary>
    procedure SetPalette(const APalette: PByteArray);
    /// <summary>
    ///   The index of the color of the palette of the display (the one of the last SetPalette,
    ///   with the gamma) that is nearest to AColor, $00RRGGBB (V_FindAproxColorIndex on curpal)
    /// </summary>
    function NearestColorInCurrentPalette(const AColor: LongWord): Integer;
    /// <summary>
    ///   The index of the color of the palette of the game (default_palette, read at each call)
    ///   that is nearest to AColor, $00RRGGBB (V_FindAproxColorIndex on default_palette)
    /// </summary>
    function NearestColorInDefaultPalette(const AColor: LongWord): Integer;
    /// <summary>
    ///   Copies the 256 colors of the palette of the video, $00RRGGBB (videopal), to
    ///   ADestination, which holds 256 values
    /// </summary>
    procedure CopyVideoPalette(const ADestination: PLongWordArray);
    /// <summary>
    ///   Copies a picture of AWidth x AHeight pixels, one byte each, on the screen ADestination
    ///   (V_CopyCustomScreen)
    /// </summary>
    procedure CopyCustomScreen(const ASource: PByteArray; const AWidth: Integer;
      const AHeight: Integer; const ADestination: Integer);
  end;

implementation

end.
