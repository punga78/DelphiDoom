//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  The extra data of the maps in the UDMF format (the loading is TEngineUdmfMapLoader)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_udmf;

interface

uses
  d_delphi,
  doomdata,
  m_fixed,
  tables,
  DelphiDoom.Udmf.Types;

const
  ML_SCRIPT = Ord(ML_BEHAVIOR) + 1;
  ML_UDMFSTART = Ord(ML_BEHAVIOR) + 2;
  ML_THINGS2 = ML_UDMFSTART + 0;
  ML_SECTORS2 = ML_UDMFSTART + 1;
  ML_VERTEX2 = ML_UDMFSTART + 2;
  ML_LINEDEF2 = ML_UDMFSTART + 3;
  ML_SIDEDEF2 = ML_UDMFSTART + 4;
  ML_NSPACE = ML_UDMFSTART + 5;
  ML_NUMUDMFLUMPS = ML_UDMFSTART + 6;

  MLN_THINGS2 = 'THINGS2';
  MLN_SECTORS2 = 'SECTORS2';
  MLN_VERTEX2 = 'VERTEX2';
  MLN_LINEDEF2 = 'LINEDEF2';
  MLN_SIDEDEF2 = 'SIDEDEF2';
  MLN_NSPACE = 'NSPACE';

const
  UDMF_TF_SKILL1 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL1;
  UDMF_TF_SKILL2 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL2;
  UDMF_TF_SKILL3 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL3;
  UDMF_TF_SKILL4 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL4;
  UDMF_TF_SKILL5 = DelphiDoom.Udmf.Types.UDMF_TF_SKILL5;
  UDMF_TF_SKILL_MASK = DelphiDoom.Udmf.Types.UDMF_TF_SKILL_MASK;
  UDMF_TF_HASZ = DelphiDoom.Udmf.Types.UDMF_TF_HASZ;
  UDMF_TF_HASGRAVITY = DelphiDoom.Udmf.Types.UDMF_TF_HASGRAVITY;
  UDMF_TF_HASHEALTH = DelphiDoom.Udmf.Types.UDMF_TF_HASHEALTH;
  UDMF_TF_SINGLE = DelphiDoom.Udmf.Types.UDMF_TF_SINGLE;
  UDMF_TF_DM = DelphiDoom.Udmf.Types.UDMF_TF_DM;
  UDMF_TF_COOP = DelphiDoom.Udmf.Types.UDMF_TF_COOP;

type
  extrathing_t = record
    extraflags: Integer;
    x, y, z: fixed_t;
    id: Integer;
    gravity: float;
    health: float;
    {$IFNDEF HEXEN}
    special: integer;
    arg1: integer;
    arg2: integer;
    arg3: integer;
    arg4: integer;
    arg5: integer;
    {$ENDIF}
  end;
  Pextrathing_t = ^extrathing_t;
  extrathing_tArray = array[0..$FFFF] of extrathing_t;
  Pextrathing_tArray = ^extrathing_tArray;

type
  moreids_t = set of Byte;
  Pmoreids_t = ^moreids_t;

const
  UDMF_SF_CEILINGPLANE_A = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_A;
  UDMF_SF_CEILINGPLANE_B = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_B;
  UDMF_SF_CEILINGPLANE_C = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_C;
  UDMF_SF_CEILINGPLANE_D = DelphiDoom.Udmf.Types.UDMF_SF_CEILINGPLANE_D;
  UDMF_SF_CEILINGPLANE = UDMF_SF_CEILINGPLANE_A or UDMF_SF_CEILINGPLANE_B or UDMF_SF_CEILINGPLANE_C or UDMF_SF_CEILINGPLANE_D;
  UDMF_SF_FLOORPLANE_A = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_A;
  UDMF_SF_FLOORPLANE_B = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_B;
  UDMF_SF_FLOORPLANE_C = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_C;
  UDMF_SF_FLOORPLANE_D = DelphiDoom.Udmf.Types.UDMF_SF_FLOORPLANE_D;
  UDMF_SF_FLOORPLANE = UDMF_SF_FLOORPLANE_A or UDMF_SF_FLOORPLANE_B or UDMF_SF_FLOORPLANE_C or UDMF_SF_FLOORPLANE_D;
  UDMF_SF_RIPPLECEILING = DelphiDoom.Udmf.Types.UDMF_SF_RIPPLECEILING;
  UDMF_SF_RIPPLEFLOOR = DelphiDoom.Udmf.Types.UDMF_SF_RIPPLEFLOOR;
  UDMF_SF_FOG = DelphiDoom.Udmf.Types.UDMF_SF_FOG;
  UDMF_SF_HIDDEN = DelphiDoom.Udmf.Types.UDMF_SF_HIDDEN;
  UDMF_SF_NOJUMP = DelphiDoom.Udmf.Types.UDMF_SF_NOJUMP;
  UDMF_SF_NOCROUCH = DelphiDoom.Udmf.Types.UDMF_SF_NOCROUCH;

type
  extrasector_t = record
    extraflags: Integer;
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    {$IFDEF DOOM_OR_STRIFE}
    xpanningfloor: fixed_t;   // X texture offset of floor texture, Default = 0.0.
    ypanningfloor: fixed_t;   // Y texture offset of floor texture, Default = 0.0.
    xpanningceiling: fixed_t; // X texture offset of ceiling texture, Default = 0.0.
    ypanningceiling: fixed_t; // Y texture offset of ceiling texture, Default = 0.0.
    {$ENDIF}
    rotationfloor: angle_t;   // Rotation of floor texture (degrees in TEXMAP)
    rotationfloorx: fixed_t;  // x/y rover for rotating floor
    rotationfloory: fixed_t;
    rotationceiling: angle_t; // Rotation of ceiling texture (degrees in TEXMAP)
    rotationceilingx: fixed_t;// x/y rover for rotating ceiling
    rotationceilingy: fixed_t;// x/y rover for rotating ceiling
    gravity: fixed_t;         // Default is 1.0
    ceilingplane_a: float;    // Define the plane equation for the sector's ceiling. Default is a horizontal plane at 'heightceiling'.
    ceilingplane_b: float;    // 'heightceiling' will still be used to calculate texture alignment.
    ceilingplane_c: float;    // The plane equation will only be used if all 4 values are given.
    ceilingplane_d: float;
    floorplane_a: float;      // Define the plane equation for the sector's floor. Default is a horizontal plane at 'heightfloor'.
    floorplane_b: float;      // 'heightfloor' will still be used to calculate texture alignment.
    floorplane_c: float;      // The plane equation will only be used if all 4 values are given.
    floorplane_d: float;
    moreids: moreids_t;
    {$IFNDEF HEXEN}
    sound: integer;
    {$ENDIF}
    windthrust: fixed_t;
    windangle: angle_t;
  end;
  Pextrasector_t = ^extrasector_t;
  extrasector_tArray = array[0..$FFFF] of extrasector_t;
  Pextrasector_tArray = ^extrasector_tArray;

const
  UDMF_VF_ZFLOOR = DelphiDoom.Udmf.Types.UDMF_VF_ZFLOOR;
  UDMF_VF_ZCEILING = DelphiDoom.Udmf.Types.UDMF_VF_ZCEILING;

type
  extravertex_t = record
    extraflags: integer;
    x, y: fixed_t;
    zfloor, zceiling: fixed_t; // Absolute floor & ceiling height
  end;
  Pextravertex_t = ^extravertex_t;
  extravertex_tArray = array[0..$FFFF] of extravertex_t;
  Pextravertex_tArray = ^extravertex_tArray;

const
  ULAC_DEFAULT = DelphiDoom.Udmf.Types.ULAC_DEFAULT;
  ULAC_REPEAT = DelphiDoom.Udmf.Types.ULAC_REPEAT;
  ULAC_CROSS = DelphiDoom.Udmf.Types.ULAC_CROSS;
  ULAC_USE = DelphiDoom.Udmf.Types.ULAC_USE;
  ULAC_MCROSS = DelphiDoom.Udmf.Types.ULAC_MCROSS;
  ULAC_IMPACT = DelphiDoom.Udmf.Types.ULAC_IMPACT;
  ULAC_PUSH = DelphiDoom.Udmf.Types.ULAC_PUSH;
  ULAC_PCROSS = DelphiDoom.Udmf.Types.ULAC_PCROSS;
  {$IFNDEF HEXEN}
  ULAC_MPUSH = DelphiDoom.Udmf.Types.ULAC_MPUSH;
  {$ENDIF}

type
  extraline_t = record
   {$IFNDEF HEXEN}
    arg1: integer;
    arg2: integer;
    arg3: integer;
    arg4: integer;
    arg5: integer;
    activators: integer;  // ULAC_????
    {$ENDIF}
    moreids: moreids_t;
  end;
  Pextraline_t = ^extraline_t;
  extraline_tArray = array[0..$FFFF] of extraline_t;
  Pextraline_tArray = ^extraline_tArray;

type
  extraside_t = record
    textureoffset: fixed_t;
    toptextureoffset: fixed_t;
    bottomtextureoffset: fixed_t;
    midtextureoffset: fixed_t;
    rowoffset: fixed_t;
    toprowoffset: fixed_t;
    bottomrowoffset: fixed_t;
    midrowoffset: fixed_t;
    flags: integer;
  end;
  Pextraside_t = ^extraside_t;
  extraside_tArray = array[0..$FFFF] of extraside_t;
  Pextraside_tArray = ^extraside_tArray;

var
  udmfthings: Pextrathing_tArray;
  numudmfthings: integer;
  udmfsectors: Pextrasector_tArray;
  numudmfsectors: integer;
  udmfvertexes: Pextravertex_tArray;
  numudmfvertexes: integer;
  udmflinedefs: Pextraline_tArray;
  numudmflinedefs: integer;
  udmfsidedefs: Pextraside_tArray;
  numudmfsidedefs: integer;
  hasudmfdata: boolean;
  udmfnamespace: string;
  udmflinetranslate: boolean;

const
{$IFNDEF HEXEN}
  UDMF_SPECIAL_START = 700;
  UDMF_SPECIAL_FINISH = UDMF_SPECIAL_START + 256;
  UDMF_NORMAL_ADD = 300;
{$ELSE}
  UDMF_SPECIAL_START = 0;
  UDMF_NORMAL_ADD = 0;
{$ENDIF}

implementation

end.
