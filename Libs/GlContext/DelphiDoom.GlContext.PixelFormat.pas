{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL context - the pixel format of the game window            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlContext.PixelFormat;

interface

uses
  Winapi.Windows;

type
  /// <summary>The pixel format the OpenGL games ask Windows for</summary>
  TGlPixelFormat = class sealed
  public
    /// <summary>
    ///   Fills the descriptor: double buffered RGBA window, 32 bit colour, 16 bit depth buffer, 16 bit stencil
    ///   buffer, no accumulation buffer and no overlay planes (the values of GL_InitGraphics of gl_main.pas)
    /// </summary>
    class procedure Describe(out ADescriptor: TPixelFormatDescriptor); static;
  end;

implementation

{ TGlPixelFormat }

class procedure TGlPixelFormat.Describe(out ADescriptor: TPixelFormatDescriptor);
begin
  FillChar(ADescriptor, SizeOf(ADescriptor), 0);
  ADescriptor.nSize := SizeOf(TPixelFormatDescriptor);
  ADescriptor.nVersion := 1;
  ADescriptor.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  ADescriptor.iPixelType := PFD_TYPE_RGBA;
  ADescriptor.cColorBits := 32;
  ADescriptor.cDepthBits := 16;
  ADescriptor.cStencilBits := 16;
  ADescriptor.iLayerType := PFD_MAIN_PLANE;
end;

end.
