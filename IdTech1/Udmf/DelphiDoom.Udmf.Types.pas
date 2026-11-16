{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the shared types                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Types;

interface

uses
  System.SysUtils;

const
  FRACUNIT = 65536;
  /// <summary>One degree as an angle of the engine (ANG90 div 90)</summary>
  ANG1 = $40000000 div 90;

  /// <summary>Flags of a thing in the extra lump THINGS2</summary>
  UDMF_TF_SKILL1 = 1;
  UDMF_TF_SKILL2 = 2;
  UDMF_TF_SKILL3 = 4;
  UDMF_TF_SKILL4 = 8;
  UDMF_TF_SKILL5 = $10;
  UDMF_TF_SKILL_MASK = $1F;
  UDMF_TF_HASZ = $20;
  UDMF_TF_HASGRAVITY = $40;
  UDMF_TF_HASHEALTH = $80;
  UDMF_TF_SINGLE = $100;
  UDMF_TF_DM = $200;
  UDMF_TF_COOP = $400;

  /// <summary>Flags of a sector in the extra lump SECTORS2</summary>
  UDMF_SF_CEILINGPLANE_A = $1;
  UDMF_SF_CEILINGPLANE_B = $2;
  UDMF_SF_CEILINGPLANE_C = $4;
  UDMF_SF_CEILINGPLANE_D = $8;
  UDMF_SF_FLOORPLANE_A = $10;
  UDMF_SF_FLOORPLANE_B = $20;
  UDMF_SF_FLOORPLANE_C = $40;
  UDMF_SF_FLOORPLANE_D = $80;
  UDMF_SF_RIPPLECEILING = $100;
  UDMF_SF_RIPPLEFLOOR = $200;
  UDMF_SF_FOG = $400;
  UDMF_SF_HIDDEN = $800;
  UDMF_SF_NOJUMP = $1000;
  UDMF_SF_NOCROUCH = $2000;

  /// <summary>Flags of a vertex in the extra lump VERTEX2</summary>
  UDMF_VF_ZFLOOR = 1;
  UDMF_VF_ZCEILING = 2;

  /// <summary>What activates a line (the activators of the extra lump LINEDEF2)</summary>
  ULAC_DEFAULT = 1;
  ULAC_REPEAT = 2;
  ULAC_CROSS = 4;
  ULAC_USE = 8;
  ULAC_MCROSS = 16;
  ULAC_IMPACT = 32;
  ULAC_PUSH = 64;
  ULAC_PCROSS = 128;
  ULAC_MPUSH = 256;

  /// <summary>Flag of a side in the extra lump SIDEDEF2</summary>
  SDF_NOFAKECONTRAST = 1;

  /// <summary>What activates a line of Hexen, in its flags</summary>
  SPAC_CROSS = 0;
  SPAC_USE = 1;
  SPAC_MCROSS = 2;
  SPAC_IMPACT = 3;
  SPAC_PUSH = 4;
  SPAC_PCROSS = 5;

  /// <summary>Names of the lumps of a map, after the ones of a vanilla map</summary>
  MLN_THINGS2 = 'THINGS2';
  MLN_SECTORS2 = 'SECTORS2';
  MLN_VERTEX2 = 'VERTEX2';
  MLN_LINEDEF2 = 'LINEDEF2';
  MLN_SIDEDEF2 = 'SIDEDEF2';
  MLN_NSPACE = 'NSPACE';

type
  /// <summary>The ids of a sector or a line beyond the first: 0..255</summary>
  TUdmfMoreIds = set of Byte;

  /// <summary>A name of a lump: 8 characters, zero padded</summary>
  TUdmfName8 = array[0..7] of AnsiChar;

  /// <summary>
  ///   A thing as it is read. The fields are those of the record of the map and of the record
  ///   of the extra lump of all the games together; the format of the game writes the ones it has
  /// </summary>
  TUdmfThing = record
    // the record of the map
    Tid: Integer;
    X: Integer;
    Y: Integer;
    Height: Integer;
    Angle: Integer;
    ThingType: Integer;
    Options: Integer;
    Special: Integer;
    Args: array[0..4] of Integer;
    // the extra record
    ExtraFlags: Integer;
    ExtraX: Integer;
    ExtraY: Integer;
    ExtraZ: Integer;
    ExtraId: Integer;
    Gravity: Single;
    Health: Single;
    ExtraSpecial: Integer;
    ExtraArgs: array[0..4] of Integer;
  end;

  TUdmfLine = record
    // the record of the map
    V1: Integer;
    V2: Integer;
    Flags: Integer;
    Special: Integer;
    Tag: Integer;
    Args: array[0..4] of Integer;
    SideFront: Integer;
    SideBack: Integer;
    // the extra record
    ExtraArgs: array[0..4] of Integer;
    Activators: Integer;
    MoreIds: TUdmfMoreIds;
  end;

  TUdmfSide = record
    // the record of the map
    TextureOffset: Integer;
    RowOffset: Integer;
    TopTexture: TUdmfName8;
    BottomTexture: TUdmfName8;
    MidTexture: TUdmfName8;
    Sector: Integer;
    // the extra record
    ExtraTextureOffset: Integer;
    ExtraTopTextureOffset: Integer;
    ExtraBottomTextureOffset: Integer;
    ExtraMidTextureOffset: Integer;
    ExtraRowOffset: Integer;
    ExtraTopRowOffset: Integer;
    ExtraBottomRowOffset: Integer;
    ExtraMidRowOffset: Integer;
    ExtraFlags: Integer;
  end;

  TUdmfVertex = record
    // the record of the map
    X: Integer;
    Y: Integer;
    // the extra record
    ExtraFlags: Integer;
    ExtraX: Integer;
    ExtraY: Integer;
    ZFloor: Integer;
    ZCeiling: Integer;
  end;

  TUdmfSector = record
    // the record of the map
    FloorHeight: Integer;
    CeilingHeight: Integer;
    FloorPic: TUdmfName8;
    CeilingPic: TUdmfName8;
    LightLevel: Integer;
    Special: Integer;
    Tag: Integer;
    // the extra record
    ExtraFlags: Integer;
    ExtraFloorHeight: Integer;
    ExtraCeilingHeight: Integer;
    XPanningFloor: Integer;
    YPanningFloor: Integer;
    XPanningCeiling: Integer;
    YPanningCeiling: Integer;
    RotationFloor: Cardinal;
    RotationFloorX: Integer;
    RotationFloorY: Integer;
    RotationCeiling: Cardinal;
    RotationCeilingX: Integer;
    RotationCeilingY: Integer;
    Gravity: Integer;
    CeilingPlane: array[0..3] of Single;
    FloorPlane: array[0..3] of Single;
    MoreIds: TUdmfMoreIds;
    Sound: Integer;
    WindThrust: Integer;
    WindAngle: Cardinal;
  end;

  /// <summary>
  ///   The bits of the flags of a thing that are the same in all the games of the engine except
  ///   for the value: 3D floors, script events and the friend of DelphiDoom
  /// </summary>
  TUdmfCommonThingFlags = record
    OnMidSector: Integer;
    DoNotTriggerScripts: Integer;
    Friend: Integer;
  end;

  /// <summary>The bits that Hexen has for its things; it has no skill bits but the common ones</summary>
  TUdmfHexenThingFlags = record
    GameSingle: Integer;
    GameCoop: Integer;
    GameDeathmatch: Integer;
    Dormant: Integer;
    Fighter: Integer;
    Cleric: Integer;
    Mage: Integer;
  end;

  /// <summary>
  ///   How the special of a thing is moved when the namespace is not the one of the game: the
  ///   specials of the game start at SpecialStart and the ones of the format that was
  ///   translated at NormalAdd
  /// </summary>
  TUdmfSpecialTranslation = record
    SpecialStart: Integer;
    NormalAdd: Integer;
  end;

  /// <summary>
  ///   The flags of a line of a game. A flag with value 0 does not exist in that game and the key
  ///   of the map that would set it is not known
  /// </summary>
  TUdmfLineFlags = record
    Blocking: Integer;
    BlockMonsters: Integer;
    TwoSided: Integer;
    DontPegTop: Integer;
    DontPegBottom: Integer;
    Secret: Integer;
    SoundBlock: Integer;
    DontDraw: Integer;
    TriggerScripts: Integer;
    NoClip: Integer;
    BlockLandMonsters: Integer;
    BlockPlayers: Integer;
    PassUse: Integer;
    Transparent1: Integer;
    Transparent2: Integer;
    JumpOver: Integer;
    BlockFloaters: Integer;
  end;

  /// <summary>What the extra record of a sector has, that changes from a game to another</summary>
  TUdmfSectorLayout = record
    HasPanning: Boolean;
    HasSound: Boolean;
  end;

  /// <summary>A lump of the map that was made</summary>
  TUdmfLump = record
    Name: string;
    Data: TBytes;
  end;

implementation

end.