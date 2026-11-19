//------------------------------------------------------------------------------
//
//  DelphiHeretic is a source port of the game Heretic and it is
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:  none
//   Implements special effects:
//   Texture animation, height or lighting changes
//    according to adjacent sectors, respective
//    utility functions, etc.
//   Line Tag handling. Line and Sector triggers.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_spec_h;

interface

uses
  m_fixed,
  d_think,
  p_mobj_h,
  r_defs;

//
// End-level timer (-TIMER option)
//

//      Define values for map objects

//==============================================================================
//
// P_FindMinSurroundingLight
//
//==============================================================================

//
// P_LIGHTS
//
type
  fireflicker_t = record
    thinker: thinker_t;
    sector: Psector_t;
    count: integer;
    maxlight: integer;
    minlight: integer;
  end;
  Pfireflicker_t = ^fireflicker_t;

  lightflash_t = record
    thinker: thinker_t;
    sector: Psector_t;
    count: integer;
    maxlight: integer;
    minlight: integer;
    maxtime: integer;
    mintime: integer;
  end;
  Plightflash_t = ^lightflash_t;

  strobe_t = record
    thinker: thinker_t;
    sector: Psector_t;
    count: integer;
    minlight: integer;
    maxlight: integer;
    darktime: integer;
    brighttime: integer;
  end;
  Pstrobe_t = ^strobe_t;

  glow_t = record
    thinker: thinker_t;
    sector: Psector_t;
    minlight: integer;
    maxlight: integer;
    direction: integer;
  end;
  Pglow_t = ^glow_t;

const
  GLOWSPEED = 8;
  STROBEBRIGHT = 5;
  FASTDARK = 15;
  SLOWDARK = 35;

type
  bwhere_e = (
    top,
    middle,
    bottom
  );

  button_t = record
    line: Pline_t;
    where: bwhere_e;
    btexture: integer;
    btimer: integer;
    soundorg: Pmobj_t;
  end;
  Pbutton_t = ^button_t;

const
  MAXSWITCHES = 50; // max # of wall switches in a level
  MAXBUTTONS = 16;  // 4 players, 4 buttons each at once, max.
  BUTTONTIME = 35;  // 1 second, in ticks.

type
//
// P_PLATS
//
  plat_e = (
    up,
    down,
    waiting,
    in_stasis,

    // JVAL: 20220214 - Added UDMF plat status
    PLAT_UP,
    PLAT_DOWN,
    PLAT_WAITING
  );

  plattype_e = (
    perpetualRaise,
    downWaitUpStay,
    raiseAndChange,
    raiseToNearestAndChange,
    blazeDWUS,

    // JVAL: 20220214 - Added UDMF plat types
    PLAT_PERPETUALRAISE,
    PLAT_DOWNWAITUPSTAY,
    PLAT_DOWNBYVALUEWAITUPSTAY,
    PLAT_UPWAITDOWNSTAY,
    PLAT_UPBYVALUEWAITDOWNSTAY,
    // JVAL: 20220227 - Added new plat types
    PLAT_PERPETUALRAISELIP,
    PLAT_DOWNWAITUPSTAYLIP,
    PLAT_UPNEARESTWAITDOWNSTAY
  );

  plat_t = record
    thinker: thinker_t;
    sector: Psector_t;
    speed: fixed_t;
    low: fixed_t;
    high: fixed_t;
    wait: integer;
    count: integer;
    status: plat_e;
    oldstatus: plat_e;
    crush: boolean;
    tag: integer;
    _type: plattype_e;
  end;
  Pplat_t = ^plat_t;

const
  PLATWAIT = 3;
  PLATSPEED = FRACUNIT;
  MAXPLATS = 512;  // JVAL Originally was 30

type
//
// P_DOORS
//
  vldoor_e = (
    normal,
    close30ThenOpen,
    close,
    open,
    raiseIn5Mins,

    // JVAL: 20220214 - Added UDMF door types
    DREV_NORMAL,
    DREV_CLOSE30THENOPEN,
    DREV_CLOSE,
    DREV_OPEN,
    DREV_RAISEIN5MINS,
    // JVAL: 20220227 - Added new door types
    DREV_CLOSEWAITTHENOPEN
  );

  vldoor_t = record
    thinker: thinker_t;
    _type: vldoor_e;
    sector: Psector_t;
    topheight: fixed_t;
    speed: fixed_t;

    // 1 = up, 0 = waiting at top, -1 = down
    direction: integer;

    // tics to wait at the top
    topwait: integer;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
    topcountdown: integer;
  end;
  Pvldoor_t = ^vldoor_t;

const
  VDOORSPEED = FRACUNIT * 2;
  VDOORWAIT = 150;

type
//
// P_CEILNG
//
  ceiling_e = (
    lowerToFloor,
    raiseToHighest,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,

    // JVAL: 20220214 - Added UDMF ceiling types
    CLEV_LOWERTOFLOOR,
    CLEV_RAISETOHIGHEST,
    CLEV_LOWERANDCRUSH,
    CLEV_CRUSHANDRAISE,
    CLEV_LOWERBYVALUE,
    CLEV_RAISEBYVALUE,
    CLEV_CRUSHRAISEANDSTAY,
    CLEV_MOVETOVALUETIMES8,
    // JVAL: 20220227 - Added new ceiling types
    CLEV_LOWERTOMAXFLOOR,
    CLEV_LOWERTOLOWEST,
    CLEV_MOVETOVALUEANDCRUSH,
    CLEV_MOVETOVALUE,
    CLEV_LOWERBYVALUETIMES8,
    CLEV_RAISEBYVALUETIMES8,
    CLEV_RAISETOHIGHESTFLOOR
  );

  ceiling_t = record
    thinker: thinker_t;
    _type: ceiling_e;
    sector: Psector_t;
    bottomheight: fixed_t;
    topheight: fixed_t;
    speed: fixed_t;
    crush: boolean;
    // 1 = up, 0 = waiting, -1 = down
    direction: integer;

    // ID
    tag: integer;
    olddirection: integer;
  end;
  Pceiling_t = ^ceiling_t;

const
  CEILSPEED = FRACUNIT;
  MAXCEILINGS = 128; // JVAL 20210130 - Old value was 30

type
//
// P_FLOOR
//
  floor_e = (
    lowerFloor,         // lower floor to highest surrounding floor
    lowerFloorToLowest, // lower floor to lowest surrounding floor
    turboLower,         // lower floor to highest surrounding floor VERY FAST
    raiseFloor,         // raise floor to lowest surrounding CEILING
    raiseFloorToNearest,// raise floor to next highest surrounding floor
    raiseToTexture,     // raise floor to shortest height texture around it
    lowerAndChange,     // lower floor to lowest surrounding floor and change
                        // floorpic
    raiseFloor24,
    raiseFloor24AndChange,
    raiseFloorCrush,
    donutRaise,
    raiseBuildStep, // One step of a staircase

    // JVAL: 20220214 - Added UDMF floor types
    FLEV_LOWERFLOOR,            // lower floor to highest surrounding floor
    FLEV_LOWERFLOORTOLOWEST,    // lower floor to lowest surrounding floor
    FLEV_LOWERFLOORBYVALUE,
    FLEV_RAISEFLOOR,            // raise floor to lowest surrounding CEILING
    FLEV_RAISEFLOORTONEAREST,   // raise floor to next highest surrounding floor
    FLEV_RAISEFLOORBYVALUE,
    FLEV_RAISEFLOORCRUSH,
    FLEV_RAISEBUILDSTEP,        // One step of a staircase
    FLEV_RAISEBYVALUETIMES8,
    FLEV_LOWERBYVALUETIMES8,
    FLEV_LOWERTIMES8INSTANT,
    FLEV_RAISETIMES8INSTANT,
    FLEV_MOVETOVALUETIMES8,
    FLEV_RAISETOTEXTURE,
    // JVAL: 20220227 - Added new floor types
    FLEV_LOWERFLOORTOHIGHEST,
    FLEV_LOWERFLOORTOLOWESTCEILING,
    FLEV_MOVETOVALUE,
    FLEV_RAISEFLOORCRUSHDOOM,
    FLEV_RAISEFLOORTOCEILING,
    FLEV_RAISETOLOWESTCEILING,
    FLEV_RAISEFLOORBYVALUETIMES8,
    FLEV_RAISETOCEILING,
    FLEV_FLOORTOCEILINGINSTANT
  );

  floormove_t206 = record
    thinker: thinker_t;
    _type: floor_e;
    crush: boolean;
    sector: Psector_t;
    direction: integer;
    newspecial: integer;
    texture: smallint;
    floordestheight: fixed_t;
    speed: fixed_t;
  end;
  Pfloormove_t206 = ^floormove_t206;

  floormove_t = record
    thinker: thinker_t;
    _type: floor_e;
    crush: boolean;
    sector: Psector_t;
    direction: integer;
    newspecial: integer;
    texture: smallint;
    floordestheight: fixed_t;
    speed: fixed_t;
    delayCount: integer;
    delayTotal: integer;
    stairsDelayHeight: fixed_t;
    stairsDelayHeightDelta: fixed_t;
    resetHeight: fixed_t;
    resetDelay: smallint;
    resetDelayCount: smallint;
    textureChange: byte;
  end;
  Pfloormove_t = ^floormove_t;

  pillar_t = record
    thinker: thinker_t;
    sector: Psector_t;
    ceilingSpeed: integer;
    floorSpeed: integer;
    floordest: integer;
    ceilingdest: integer;
    direction: integer;
    crush: boolean;
  end;
  Ppillar_t = ^pillar_t;

  floorWaggle_t = record
    thinker: thinker_t;
    sector: Psector_t;
    originalHeight: fixed_t;
    accumulator: fixed_t;
    accDelta: fixed_t;
    targetScale: fixed_t;
    scale: fixed_t;
    scaleDelta: fixed_t;
    ticker: integer;
    state: integer;
  end;
  PfloorWaggle_t = ^floorWaggle_t;

const
  FLOORSPEED = FRACUNIT;

type
  result_e = (
    ok,
    crushed,
    pastdest,

    // JVAL: 20220214 - Added UDMF Result types
    RES_OK,
    RES_CRUSHED,
    RES_PASTDEST
  );

  stairs_e = (
    STAIRS_NORMAL,
    STAIRS_SYNC,
    STAIRS_PHASED
  );

const
  ORIG_FRICTION = $E800;          // original value
  CROUCH_FRICTION_FACTOR = 1536;  // JVAL: 20211101 - Crouch

implementation

end.
