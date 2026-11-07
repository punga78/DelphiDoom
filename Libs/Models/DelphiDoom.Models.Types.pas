{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the shared types and constants              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The first four bytes of an MD2 file: 'IDP2'</summary>
  MD2_MAGIC = $32504449;
  /// <summary>The size in bytes of the header of an MD2 file</summary>
  MD2_HEADER_SIZE = 68;
  /// <summary>The size in bytes of a triangle of an MD2 file: 3 vertexes and 3 texture points of 16 bit</summary>
  MD2_TRIANGLE_SIZE = 12;
  /// <summary>The size in bytes of a texture point of an MD2 file</summary>
  MD2_TEXTURE_POINT_SIZE = 4;
  /// <summary>The size in bytes of a vertex of a frame of an MD2 file: x, y, z and the normal</summary>
  MD2_VERTEX_SIZE = 4;
  /// <summary>The size in bytes of the head of a frame of an MD2 file: scale, translate and the name</summary>
  MD2_FRAME_HEAD_SIZE = 40;
  /// <summary>The characters of the name of a frame of an MD2 file</summary>
  MD2_FRAME_NAME_SIZE = 16;

  /// <summary>The first number of a binary model (DMX): the version of the format</summary>
  DMX_MAGIC = 1;
  /// <summary>The size in bytes of a command of a binary model</summary>
  MODEL_COMMAND_SIZE = 24;
  /// <summary>How many frames a model can call from another (the old limit)</summary>
  MODEL_DEFAULT_RECURSION_DEPTH = 20;

  // The commands of a procedural model: the numbers are written in the binary models (DMX)
  MODEL_CMD_BEGIN = 0;
  MODEL_CMD_END = 1;
  MODEL_CMD_TEXCOORD2F = 2;
  MODEL_CMD_VERTEX3F = 3;
  MODEL_CMD_COLOR3F = 4;
  MODEL_CMD_COLOR4F = 5;
  MODEL_CMD_NORMAL3F = 6;
  MODEL_CMD_MATRIXMODE = 7;
  MODEL_CMD_PUSHMATRIX = 8;
  MODEL_CMD_POPMATRIX = 9;
  MODEL_CMD_TRANSLATEF = 10;
  MODEL_CMD_ROTATEF = 11;
  MODEL_CMD_LOADIDENTITY = 12;
  MODEL_CMD_SCALEF = 13;
  MODEL_CMD_SETFRAME = 14;
  MODEL_CMD_CALLFRAME = 15;

resourcestring
  SModelsMd2TooShort = 'The MD2 model is too short (%d bytes)';
  SModelsMd2InvalidMagic = 'Invalid MD2 model magic (%d)!';
  SModelsMd2InvalidCounts = 'The MD2 model has invalid counts (skin %dx%d, vertexes %d, texture points %d, triangles %d, frames %d)';
  SModelsMd2InvalidFrameSize = 'The size of a frame of the MD2 model (%d) is too small for %d vertexes';
  SModelsMd2Truncated = 'The MD2 model is truncated: %s is outside the file (offset %d, size %d)';
  SModelsMd2InvalidIndex = 'The triangle %d of the MD2 model uses the %s %d, that does not exist';
  SModelsMd2NoFrames = 'The MD2 model has no frames';
  SModelsStreamTruncated = 'The binary model is truncated (%d bytes for %d commands)';
  SModelsInvalidCommand = 'The command %d does not exist';
  SModelsInvalidFramePosition = 'The frame at position %d does not exist';
  SModelsInvalidFrame = 'The frame %d does not exist';

type
  /// <summary>A vertex of a model: the same three Single of the OpenGL vertex</summary>
  TModelVertex = record
    X: Single;
    Y: Single;
    Z: Single;
  end;
  PModelVertex = ^TModelVertex;

  /// <summary>A texture point of a model</summary>
  TModelTexCoord = record
    U: Single;
    V: Single;
  end;
  PModelTexCoord = ^TModelTexCoord;

  /// <summary>
  ///   Where and how big a model is drawn: the offset and the scale of each axis, already divided
  ///   by the coefficient of the map (the renderer does that, the library does not know OpenGL)
  /// </summary>
  TModelPlacement = record
    OffsetX: Single;
    OffsetY: Single;
    OffsetZ: Single;
    ScaleX: Single;
    ScaleY: Single;
    ScaleZ: Single;
  end;

  /// <summary>
  ///   A command of a procedural model, as it is in the binary models (DMX): the number of the
  ///   command, four parameters and the frame it belongs to. 24 bytes, little endian.
  /// </summary>
  TModelCommand = packed record
    Command: Integer;
    Params: array[0..3] of Single;
    Frame: Integer;
  end;
  PModelCommand = ^TModelCommand;

  /// <summary>The header of an MD2 file (Quake 2): 17 integers, 68 bytes, little endian</summary>
  TMd2Header = packed record
    Ident: Integer;
    Version: Integer;
    SkinWidth: Integer;
    SkinHeight: Integer;
    FrameSize: Integer;
    SkinCount: Integer;
    VertexCount: Integer;
    TexturePointCount: Integer;
    TriangleCount: Integer;
    GlCommandCount: Integer;
    FrameCount: Integer;
    SkinsOffset: Integer;
    TexturePointsOffset: Integer;
    TrianglesOffset: Integer;
    FramesOffset: Integer;
    GlCommandsOffset: Integer;
    EndOffset: Integer;
  end;

  /// <summary>A triangle of an MD2 file: the vertexes and the texture points, 12 bytes</summary>
  TMd2Triangle = packed record
    VertexIndex: array[0..2] of SmallInt;
    TexturePointIndex: array[0..2] of SmallInt;
  end;

  /// <summary>A texture point of an MD2 file, in pixels of the skin: 4 bytes</summary>
  TMd2TexturePoint = packed record
    S: SmallInt;
    T: SmallInt;
  end;

  /// <summary>The start of a frame of an MD2 file: scale, translation and name, 40 bytes. The vertexes follow</summary>
  TMd2FrameHead = packed record
    Scale: array[0..2] of Single;
    Translate: array[0..2] of Single;
    Name: array[0..MD2_FRAME_NAME_SIZE - 1] of AnsiChar;
  end;

  /// <summary>A mistake in a model (not an MD2, truncated, a number that does not exist)</summary>
  EModelsException = class(Exception);

implementation

end.
