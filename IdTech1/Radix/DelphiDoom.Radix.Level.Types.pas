{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the records of a level                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{  Copyright (C) 1995 by Epic MegaGames, Inc. (Radix - beyond the void)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the types and constants of radix_level.pas and of the Doom map      }
{  records the old translator wrote. All the records are packed and have no    }
{  pointers; the sizes are the ones of the files (a test covers them)          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Types;

interface

uses
  System.SysUtils;

const
  RADIX_MAP_MAGIC = Cardinal($FFFFFEE7);
  RADIX_SECTOR_NAME_SIZE = 26;
  RADIX_PLAYER_STARTS = 8;
  RADIX_GRID_SIZE = 40960;
  RADIX_GRID_CELL_SIZE = 64;
  RADIX_MAX_ACTION_PARAMS = 64;
  RADIX_MAX_TRIGGER_ACTIONS = 150;
  RADIX_ACTION_HEADER_SIZE = 40;
  RADIX_TRIGGER_HEADER_SIZE = 34;
  RADIX_MAX_LIGHT_LEVEL = 64;

  // sector flags
  RSF_DARKNESS = 1;
  RSF_FOG = 2;
  RSF_FLOORSLOPE = 4;
  RSF_CEILINGSLOPE = 8;
  RSF_CEILINGSKY = 16;
  RSF_HIDDEN = 32;
  RSF_FLOORSKY = 64;
  RSF_RADIXSECTOR = $20000000;

  // wall flags
  RWF_SINGLESIDED = 1;
  RWF_FLOORWALL = 2;
  RWF_CEILINGWALL = 4;
  RWF_TWOSIDEDCOMPLETE = 512;
  RWF_RADIXWALL = $20000000;
  RWF_STUBWALL = $40000000;

  // the coordinates of Radix become the ones of Doom
  E3M2_SPLIT_X = 48000;
  RADIX_MAP_X_MULT = 1;
  RADIX_MAP_X_ADD = -32767;
  RADIX_MAP_X_ADD2 = -65536;
  RADIX_MAP_Y_MULT = -1;
  RADIX_MAP_Y_ADD = 0;
  RADIX_MAP_Y_ADD2 = -4096;

  // flags of the lines and of the things of the Doom map
  ML_BLOCKING = 1;
  ML_BLOCKMONSTERS = 2;
  ML_TWOSIDED = 4;
  ML_DONTDRAW = 128;
  ML_AUTOMAPIGNOGE = 2048;
  ML_SLIDELINE = 4096;
  MTF_EASY = 1;
  MTF_NORMAL = 2;
  MTF_HARD = 4;
  MTF_NOTSINGLE = 16;
  MTF_INACTIVE = 1024;

  // the numbers of the things that the translation names
  RADIX_THING_OFFSET = 1000;
  MT_DEFENCEDRONE_STUB1 = 1031;
  MT_DEFENCEDRONE_STUB2 = 1032;
  MT_DEFENCEDRONE_STUB3 = 1042;
  MT_PLAYERFLOORSLIDE64 = 1204;

  SRadixLevelTruncated = 'The level "%s" is shorter than its header says';
  SRadixLevelBadAction = 'The level "%s" has an action with %d bytes of parameters';

type
  TRadixLevelHeader = packed record
    Id: Cardinal;
    NumTriggers: Integer;
    NumActions: Integer;
    Unknown1: packed array[0..16] of Byte;
    NumWalls: Integer;
    NumSectors: Integer;
    Unknown2: packed array[0..3] of Byte;
    NumThings: Integer;
    Unknown3: packed array[0..19] of Byte;
    OrthogonalMap: SmallInt;
    Unknown4: packed array[0..1] of Byte;
    PlayerStartOffsets: Integer;
  end;

  TRadixLevelPlayerStart = packed record
    X: Integer;
    Y: Integer;
    Z: Integer;
    Angle: Byte;
  end;

  /// <summary>A sector of Radix (142 bytes)</summary>
  TRadixLevelSector = packed record
    Unknown1: packed array[0..1] of Byte;
    NameId: packed array[0..RADIX_SECTOR_NAME_SIZE - 1] of AnsiChar;
    FloorTexture: SmallInt;
    CeilingTexture: SmallInt;
    FloorHeight: SmallInt;
    CeilingHeight: SmallInt;
    LightLevel: Byte;
    Flags: Byte;
    FloorA: Integer;
    FloorB: Integer;
    FloorC: Integer;
    FloorD: Integer;
    CeilingA: Integer;
    CeilingB: Integer;
    CeilingC: Integer;
    CeilingD: Integer;
    FloorAngle: Cardinal;
    CeilingAngle: Cardinal;
    HeightNodesX: packed array[0..2] of Integer;
    FloorAngleX: Integer;
    HeightNodesY: packed array[0..2] of Integer;
    FloorAngleY: Integer;
    FloorHeights: packed array[0..2] of Integer;
    CeilingAngleX: Integer;
    CeilingHeights: packed array[0..2] of Integer;
    CeilingAngleY: Integer;
  end;

  /// <summary>A wall of Radix (86 bytes)</summary>
  TRadixLevelWall = packed record
    Unknown1: packed array[0..9] of Byte;
    V1X: Integer;
    V1Y: Integer;
    V2X: Integer;
    V2Y: Integer;
    FrontSector: SmallInt;
    BackSector: SmallInt;
    Unknown2: packed array[0..41] of Byte;
    Flags: Cardinal;
    BitmapOffset: SmallInt;
    FloorTexture: SmallInt;
    CeilingTexture: SmallInt;
    HitPoints: SmallInt;
    Trigger: SmallInt;
  end;

  /// <summary>A thing of Radix (34 bytes)</summary>
  TRadixLevelThing = packed record
    Skill: Byte;
    Unknown1: SmallInt;
    Unknown2: SmallInt;
    X: Integer;
    Y: Integer;
    Angle: Byte;
    Ground: SmallInt;
    Unknown7: SmallInt;
    Unknown8: Integer;
    RadixType: Integer;
    Speed: SmallInt;
    ThingKey: SmallInt;
    HeightSpeed: SmallInt;
    Unknown12: SmallInt;
  end;

  /// <summary>An action ("sprite") of Radix (168 bytes); the parameters follow the first 40 bytes</summary>
  TRadixLevelAction = packed record
    Unknown1: Byte;
    Enabled: Byte;
    NameId: packed array[0..25] of AnsiChar;
    ExtraData: SmallInt;
    DataOffset: SmallInt;
    ActionType: SmallInt;
    Suspend: Integer;
    Unknown2: Word;
    Params: packed array[0..RADIX_MAX_ACTION_PARAMS - 1] of SmallInt;
  end;

  TRadixLevelTriggerAction = packed record // 12 bytes
    DataOffset: SmallInt;
    ActionId: SmallInt;
    Trigger: SmallInt;
    ActivationFlags: SmallInt;
    Unknown2: packed array[0..1] of SmallInt;
  end;

  /// <summary>A trigger of Radix (1834 bytes); the actions follow the first 34 bytes</summary>
  TRadixLevelTrigger = packed record
    Unknown1: Byte;
    Suspended: Byte;
    NameId: packed array[0..25] of AnsiChar;
    NumActions: Integer;
    Unknown2: Word;
    Actions: packed array[0..RADIX_MAX_TRIGGER_ACTIONS - 1] of TRadixLevelTriggerAction;
  end;

  /// <summary>The lump RGRID: the trigger grid and its size</summary>
  TRadixLevelGrid = packed record
    X: Integer;
    Y: Integer;
    Cells: packed array[0..RADIX_GRID_SIZE - 1] of SmallInt;
  end;

  TRadixLevelMapPoint = packed record
    X: SmallInt;
    Y: SmallInt;
  end;

  /// <summary>The lump RMAPGRID: the Doom position of every cell of the grid</summary>
  TRadixLevelMapPoints = packed array[0..RADIX_GRID_SIZE - 1] of TRadixLevelMapPoint;

  /// <summary>An 8 character name (a lump name or a texture name), padded with zeros</summary>
  TRadixName8 = packed record
    Chars: packed array[0..7] of AnsiChar;
    class function Make(const AName: string): TRadixName8; static;
    class operator Equal(const ALeft, ARight: TRadixName8): Boolean;
  end;

  TRadixDoomThing = packed record
    X: SmallInt;
    Y: SmallInt;
    Angle: SmallInt;
    ThingType: Word;
    Options: SmallInt;
  end;

  /// <summary>The lump RTHINGS has one of these for each thing</summary>
  TRadixDoomThingExtra = packed record
    Z: SmallInt;
    Speed: SmallInt;
    HeightSpeed: SmallInt;
    RadixSkill: SmallInt;
    RadixId: SmallInt;
  end;

  TRadixDoomLineDef = packed record
    V1: SmallInt;
    V2: SmallInt;
    Flags: SmallInt;
    Special: SmallInt;
    Tag: SmallInt;
    SideNum: packed array[0..1] of SmallInt;
  end;

  TRadixDoomSideDef = packed record
    TextureOffset: SmallInt;
    RowOffset: SmallInt;
    TopTexture: TRadixName8;
    BottomTexture: TRadixName8;
    MidTexture: TRadixName8;
    Sector: SmallInt;
  end;

  TRadixDoomVertex = packed record
    X: SmallInt;
    Y: SmallInt;
  end;

  TRadixDoomSector = packed record
    FloorHeight: SmallInt;
    CeilingHeight: SmallInt;
    FloorPic: TRadixName8;
    CeilingPic: TRadixName8;
    LightLevel: SmallInt;
    Special: SmallInt;
    Tag: SmallInt;
  end;

  /// <summary>The position of a sector: Doom x = XMul * x + XAdd, y = YMul * y + YAdd (script of RMAP)</summary>
  TRadixSectorPosition = record
    XMul: Integer;
    XAdd: Integer;
    YMul: Integer;
    YAdd: Integer;
  end;

implementation

{ TRadixName8 }

class function TRadixName8.Make(const AName: string): TRadixName8;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 1 to Length(AName) do
    if LIndex <= 8 then
      Result.Chars[LIndex - 1] := AnsiChar(Ord(AName[LIndex]) and $FF);
end;

class operator TRadixName8.Equal(const ALeft, ARight: TRadixName8): Boolean;
begin
  Result := CompareMem(@ALeft, @ARight, SizeOf(TRadixName8));
end;

end.
