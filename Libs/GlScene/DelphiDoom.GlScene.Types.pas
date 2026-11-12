{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the shared types                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Base of the errors of the OpenGL scene library</summary>
  EGlSceneException = class(Exception);

  /// <summary>What a run of the draw list is made of (GLDrawItemType of the old gl_render)</summary>
  TGlSceneItemKind = (
    gskNone,
    gskWall,
    gskFlat,
    gskSprite,
    gskLight
  );

  /// <summary>Consecutive items of the same kind, in the order the BSP walk met them (GLDrawItem)</summary>
  TGlSceneRun = record
    Kind: TGlSceneItemKind;
    /// <summary>How many items of the kind</summary>
    Count: Integer;
    /// <summary>Index of the first one in the block of its kind</summary>
    First: Integer;
    /// <summary>The frame that wrote the run (a counter of one byte: it wraps every 256 frames)</summary>
    Marker: Byte;
  end;
  PGlSceneRun = ^TGlSceneRun;
  TGlSceneRunArray = array[0..$FFFF] of TGlSceneRun;
  PGlSceneRunArray = ^TGlSceneRunArray;

  /// <summary>The size in bytes of the records the engine keeps in the three blocks of a draw list</summary>
  TGlSceneItemSizes = record
    Wall: Integer;
    Flat: Integer;
    Sprite: Integer;
  end;

implementation

end.
