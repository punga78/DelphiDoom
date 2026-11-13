{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the drawing                              }
{                                                                              }
{  Port of war1 (acoto87/war1), war_render.c and war.h (WarRenderState),       }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\              }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Render.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_RENDER_STATE_STACK of war.h: the states a drawing can save</summary>
  WAR_MAX_RENDER_STATE_STACK = 32;

type
  /// <summary>WarColor: one byte for each channel</summary>
  TWarRgba = record
    R: Byte;
    G: Byte;
    B: Byte;
    A: Byte;
  end;

  /// <summary>A rectangle of floating point numbers (rect of war_math.h, SDL_FRect)</summary>
  TWarRectF = record
    X: Single;
    Y: Single;
    Width: Single;
    Height: Single;
  end;

  /// <summary>WarRenderState: where the origin is, how large a unit is and how opaque what is drawn</summary>
  TWarRenderState = record
    OffsetX: Single;
    OffsetY: Single;
    ScaleX: Single;
    ScaleY: Single;
    Alpha: Single;
  end;

  /// <summary>
  ///   One call of wr_subImage as it reaches SDL_RenderTexture (or SDL_RenderTextureRotated when it is flipped): the
  ///   part of the image, the rectangle it goes to after the transform, the flip, the color of the image (the color mod
  ///   of the texture) and its opacity
  /// </summary>
  TWarBlit = record
    Source: TWarRectF;
    Destination: TWarRectF;
    FlipHorizontal: Boolean;
    FlipVertical: Boolean;
    Color: TWarRgba;
  end;

resourcestring
  SWarRenderStackFull = 'The render state stack is full (%d states)';
  SWarRenderStackEmpty = 'The render state stack has no state to restore';
  SWarRenderImageSize = 'The image has %d bytes, %d x %d pixels need %d';

implementation

end.
