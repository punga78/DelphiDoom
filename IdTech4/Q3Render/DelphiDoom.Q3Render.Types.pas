{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - shared types     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): renderer\       }
{  tr_local.h, tr_image.c. Copyright (C) 1999-2005 Id Software, Inc. This unit  }
{  is derived from the Quake III Arena source code and is therefore available   }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_QPATH of q_shared.h</summary>
  Q3_RENDER_MAX_QPATH = 64;
  /// <summary>MD3_MAX_LODS of qfiles.h</summary>
  Q3_RENDER_MD3_MAX_LODS = 3;
  /// <summary>The largest image side the loaders accept (the C allocates what the header says)</summary>
  Q3_RENDER_MAX_IMAGE_SIDE = 8192;

type
  /// <summary>vec3_t</summary>
  TQ3RenderVec3 = array[0..2] of Single;
  /// <summary>vec3_t axis[3]</summary>
  TQ3RenderAxis = array[0..2] of TQ3RenderVec3;

  /// <summary>
  ///   The result of R_LoadImage: width, height and 4 bytes (R, G, B, A) per pixel, the rows in the order the C
  ///   writes them into the buffer (row 0 is the first row of the buffer, which for a TGA is the last row of the file)
  /// </summary>
  TQ3RenderImage = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
  end;

  /// <summary>Raised for what the C reports with ri.Error(ERR_DROP) and for data that the C would read past</summary>
  EQ3RenderException = class(Exception);

resourcestring
  SQ3RenderBadImageSize = 'Image %s: the size %d x %d is not valid';
  SQ3RenderTruncated = 'Image %s: the file ends before the image does';

implementation

end.
