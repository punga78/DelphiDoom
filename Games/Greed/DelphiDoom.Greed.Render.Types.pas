{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the types of the renderer                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_public_h.pas, r_refdef.pas}
{  and r_render.pas of the Raven 3D engine (Softdisk Publishing, 1996)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.Types;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

const
  /// <summary>RENDER_VIEW_WIDTH and RENDER_VIEW_HEIGHT: the largest picture the renderer draws</summary>
  GREED_RENDER_MAX_WIDTH = 640;
  GREED_RENDER_MAX_HEIGHT = 400;
  /// <summary>TANANGLES: the angles of a quadrant of the fine tables</summary>
  GREED_TAN_ANGLES = 8192;
  GREED_FINE_SHIFT = 5;
  GREED_FINE_UNIT = 1 shl GREED_FINE_SHIFT;
  /// <summary>MAXVISVERTEXES: the corners of tiles that are transformed in a frame</summary>
  GREED_MAX_VIS_VERTEXES = 16384;
  /// <summary>MAXSPANS: the spans, posts and shapes that wait to be sorted in a frame</summary>
  GREED_MAX_SPANS = 192 * 1024;
  /// <summary>MAXPEND: the posts of transparent walls and steps that wait for the sort</summary>
  GREED_MAX_PENDING = 32768;
  /// <summary>MAXENTRIES: the tiles that wait to be drawn</summary>
  GREED_MAX_ENTRIES = 1024;
  /// <summary>MAXAUTO</summary>
  GREED_MAX_AUTO = 16 * 16;
  /// <summary>MINZ and MAXZ: the nearest and farthest distance of what is drawn (fixed point)</summary>
  GREED_MIN_Z = GREED_FRACUNIT div 2;
  GREED_MAX_Z = (32 shl GREED_FRACTILESHIFT) - 1;
  GREED_MAX_Z_LIGHT = GREED_MAX_Z shr GREED_FRACBITS;
  GREED_TILE_UNIT = 64 * GREED_FRACUNIT;
  GREED_TILE_GLOBAL = 1 shl GREED_FRACTILESHIFT;

  // ---- the flags of a wall (r_refdef.pas) ----

  GREED_WALL_RIGHT = 1 shl 0;
  GREED_WALL_LEFT = 1 shl 1;
  GREED_WALL_UP = 1 shl 2;
  GREED_WALL_DOWN = 1 shl 3;
  GREED_WALL_TRANSPARENT = 1 shl 4;
  GREED_WALL_NO_CLIP = 1 shl 5;
  GREED_WALL_NO_BULLET_CLIP = 1 shl 6;
  /// <summary>F_DAMAGE: in a transparent wall it means that it is drawn as a shadow (an invisible wall)</summary>
  GREED_WALL_DAMAGE = 1 shl 7;

  // ---- the colors of the walls in the map of the player (r_public_h.pas) ----

  GREED_STEP_COLOR = 132;
  GREED_WALL_COLOR = 127;
  GREED_TRANS_COLOR = 79;
  GREED_DOOR_COLOR = 73;

  // ---- what animates a sprite (the bits of its Animation) ----

  GREED_ANIM_LOOP_MASK = 1;
  GREED_ANIM_CG_MASK = 30;
  GREED_ANIM_MG_MASK = 480;
  GREED_ANIM_SELF_DESTRUCT = 32768;
  GREED_ANIM_DELAY_MASK = 32256;

  /// <summary>The kind of the sprite that is a splat of blood (S_BLOODSPLAT)</summary>
  GREED_S_BLOOD_SPLAT = 532;

  // ---- the directions (the circle has 1024 angles) ----

  GREED_WEST = 512;
  GREED_DEGREE45 = 128;
  GREED_DEGREE45_2 = 64;

type
  /// <summary>
  ///   vertex_t: a corner of a tile as it is seen from the view. TX is the distance to the right and TZ the depth,
  ///   PX, FloorY and CeilingY are the pixels (valid if TZ is at least MINZ). The renderer keeps the records in a list
  ///   that does not move, and the walls clip the PX of a record that is shared by four tiles (as the original)
  /// </summary>
  PGreedRenderVertex = ^TGreedRenderVertex;
  TGreedRenderVertex = record
    FloorHeight: Integer;
    CeilingHeight: Integer;
    TX: Integer;
    TZ: Integer;
    PX: Integer;
    FloorY: Integer;
    CeilingY: Integer;
  end;

  /// <summary>entry_t: a tile that waits to be drawn, with the columns of the screen that it can fill</summary>
  PGreedRenderEntry = ^TGreedRenderEntry;
  TGreedRenderEntry = record
    TileX: Integer;
    TileY: Integer;
    XMin: Integer;
    XMax: Integer;
    MapSpot: Integer;
    Counter: Integer;
  end;

  /// <summary>spanobj_t: what a span of the list draws</summary>
  TGreedSpanKind = (
    gskFlat, gskSlope, gskDoor, gskShape, gskMaskedDoor, gskTransparentWall, gskStep, gskSky, gskSlopeSky,
    gskFlatSky, gskInvisibleWall);

  /// <summary>tag_t: the key of a span in the sort (the farthest first), and where it is</summary>
  PGreedSpanTag = ^TGreedSpanTag;
  TGreedSpanTag = record
    Point: Cardinal;
    Span: Cardinal;
  end;

  /// <summary>
  ///   span_t: a row of a floor, a post of a wall or a door, or a sprite. The fields have a different meaning in each
  ///   kind, as in the original (X2 is the last column of a floor span and the index of the post of a wall). Colormap
  ///   is the fixed color table of a floor that has a lighting effect (the original kept the pointer in Shadow)
  /// </summary>
  PGreedSpan = ^TGreedSpan;
  TGreedSpan = record
    Kind: TGreedSpanKind;
    Picture: PByte;
    Colormap: PByte;
    X2: Integer;
    Y: Integer;
    YH: Integer;
    Light: Integer;
    Shadow: Integer;
    /// <summary>The scale of a sprite (scaleobj_t.scale); 0 in the other spans</summary>
    Scale: Integer;
  end;

  /// <summary>clippoint_t: a corner of a polygon that has to be cut at the near plane</summary>
  TGreedClipPoint = record
    TX: Integer;
    TY: Integer;
    TZ: Integer;
    PX: Integer;
    PY: Integer;
  end;

  /// <summary>The time of the game that the renderer needs (timecount and spritemovetime of the original)</summary>
  IGreedRenderClock = interface
    ['{3E6A91C2-7D40-4B58-A2F6-81C05E9D3B74}']
    /// <summary>The tics of the game</summary>
    function GetTimeCount: Integer;
    /// <summary>The tic of the next move of the sprites: it says how far the sprites are between two moves</summary>
    function GetSpriteMoveTime: Integer;
  end;

  /// <summary>
  ///   RF_CheckActionFlag of r_public.pas: the original calls it four times while it draws a view (before
  ///   SetupFrame, before FlowView, before the sprites and after the spans); the game runs a TimeUpdate there and
  ///   the action that the player asked for (the shot)
  /// </summary>
  IGreedRenderActionHook = interface
    ['{6F0C2B91-4E7D-4A35-9B18-D3A5C07E2F64}']
    procedure CheckActionFlag;
  end;

  /// <summary>A wrong request to the renderer</summary>
  EGreedRenderException = class(EGreedException);

resourcestring
  SGreedRenderSize = 'Greed: a picture of %d x %d pixels cannot be drawn (the largest is %d x %d)';
  SGreedRenderPlayer = 'Greed: the renderer needs the player to be inside the map';

implementation

end.

