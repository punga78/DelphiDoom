//------------------------------------------------------------------------------
//
//  DelphiStrife is a source port of the game Strife.
//
//  Based on:
//    - Linux Doom by "id Software"
//    - Chocolate Strife by "Simon Howard"
//    - DelphiDoom by "Jim Valavanis"
//
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2005 Simon Howard
//  Copyright (C) 2010 James Haley, Samuel Villarreal
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
//  Implements special effects:
//  Texture animation, height or lighting changes
//   according to adjacent sectors, respective
//   utility functions, etc.
//  Line Tag handling. Line and Sector triggers.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_spec_h;

interface

uses
  doomdef,
  m_fixed,
  d_player,
  d_think,
  p_local,
  p_mobj_h,
  r_defs;

//
// End-level timer (-TIMER option)
//

//      Define values for map objects

// [STRIFE] Teleportation flags - teleflags
// Not to be conflated with telefrags, though they be tangentially related ;)
const
  TF_NOSRCSND = $01;
  TF_NODSTSND = $02;
  TF_NODSTFOG = $10;
  TF_NOSRCFOG = $20;

  TF_NORMAL      = 0;
  TF_DSTSILENCE  = (TF_NODSTSND or TF_NODSTFOG);      // 0x12 (18) (Not used)
  TF_SRCSILENCE  = (TF_NOSRCSND or TF_NOSRCFOG);      // 0x21 (33)
  TF_FULLSILENCE = (TF_SRCSILENCE or TF_DSTSILENCE);  // 0x33 (51)

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
  // 8 players, 4 buttons each at once, max.
  MAXBUTTONS = 32;

  // 1 second, in ticks.
  BUTTONTIME = 35;

type
  change_e = (
    trigChangeOnly,
    numChangeOnly
  );

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
    slowDWUS,           // villsa [STRIFE]
    raiseAndChange,
    raiseToNearestAndChange,
    blazeDWUS,
    upWaitDownStay,     // villsa [STRIFE]
    genLift,      //jff added to support generalized Plat types
    genPerpetual,
    toggleUpDn,   //jff 3/14/98 added to support instant toggle type

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
    vld_normal,
    vld_close30ThenOpen,
    vld_close,
    vld_open,
    vld_raiseIn5Mins,
    vld_blazeRaise,
    vld_blazeOpen,
    vld_blazeClose,
    vld_shopClose,          // villsa [STRIFE]
    vld_splitRaiseNearest,  // villsa [STRIFE]
    vld_splitOpen,          // villsa [STRIFE]

    //jff 02/05/98 add generalize door types
    vld_genRaise,
    vld_genBlazeRaise,
    vld_genOpen,
    vld_genBlazeOpen,
    vld_genClose,
    vld_genBlazeClose,
    vld_genCdO,
    vld_genBlazeCdO,

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
    line: Pline_t;
    topheight: fixed_t;
    speed: fixed_t;

    // 1 = up, 0 = waiting at top, -1 = down
    direction: integer;

    // tics to wait at the top
    topwait: integer;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
    topcountdown: integer;

    // villsa [STRIFE] new field - sound to play when opening
    opensound: integer;

    // villsa [STRIFE] new field - sound to play when closing
    closesound: integer;
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
    lowerToLowest,
    lowerToMaxFloor,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    silentCrushAndRaise,

    //jff 02/04/98 add types for generalized ceiling mover
    genCeiling,
    genCeilingChg,
    genCeilingChg0,
    genCeilingChgT,

    //jff 02/05/98 add types for generalized ceiling mover
    genCrusher,
    genSilentCrusher,

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
    oldspeed: fixed_t; // JVAL BOOM compatibility
    crush: boolean;
    // 1 = up, 0 = waiting, -1 = down
    direction: integer;
  //jff 02/04/98 add these to support ceiling changers
    newspecial: integer;
    oldspecial: smallint; //jff 3/14/98 add to fix bug in change transfers // JVAL SOS mayby integer
    texture: smallint; // JVAL BOOM compatibility
    // ID
    tag: integer;
    olddirection: integer;
  end;
  Pceiling_t = ^ceiling_t;

const
  CEILSPEED = FRACUNIT;
  MAXCEILINGS = 128; // JVAL 20210130 - Old value was 30

type
// villsa [STRIFE] resurrected sliding doors
//
//      Sliding doors...
//
  sd_e = (
    sd_opening,
    sd_waiting,
    sd_closing
  );

  sdt_e = (
    sdt_openOnly,
    sdt_closeOnly,
    sdt_openAndClose
  );

// villsa [STRIFE] Rogue added a second line_t in the struct
// backsector is removed
type
  slidedoor_t = record
    thinker: thinker_t;
    _type: sdt_e;
    line1: Pline_t;
    line2: Pline_t;
    frame: integer;
    whichDoorIndex: integer;
    timer: integer;
    frontsector: Psector_t;
    status: sd_e;
  end;
  Pslidedoor_t = ^slidedoor_t;

// villsa [STRIFE] no front/back frames
type
  slidename_t = record
    frame1: string;
    frame2: string;
    frame3: string;
    frame4: string;
    frame5: string;
    frame6: string;
    frame7: string;
    frame8: string;
  end;

// villsa [STRIFE] no front/back frames
type
  slideframe_t = record
    frames: array [0..7] of integer;
  end;

const
// how many frames of animation
  SNUMFRAMES = 8;       // villsa [STRIFE] changed from 4 to 8

  SDOORWAIT = TICRATE * 3;
  SWAITTICS = 4;

// how many diff. types of anims
  MAXSLIDEDOORS = 8;       // villsa [STRIFE] changed from 5 to 8

type
//
// P_FLOOR
//
  floor_e = (
    // lower floor to highest surrounding floor
    lowerFloor,

    // lower floor to lowest surrounding floor
    lowerFloorToLowest,

    // lower floor to highest surrounding floor VERY FAST
    turboLower,

    // raise floor to lowest surrounding CEILING
    raiseFloor,

    // raise floor to next highest surrounding floor
    raiseFloorToNearest,

    //jff 02/03/98 lower floor to next lowest neighbor
    lowerFloorToNearest,

    //jff 02/03/98 lower floor 24 absolute
    lowerFloor24,

    //jff 02/03/98 lower floor 32 absolute
    lowerFloor32Turbo,

    // raise floor to shortest height texture around it
    raiseToTexture,

    // lower floor to lowest surrounding floor
    //  and change floorpic
    lowerAndChange,

    raiseFloor64,
    raiseFloor24,

    //jff 02/03/98 raise floor 32 absolute
    raiseFloor32Turbo,

    raiseFloor24AndChange,
    raiseFloorCrush,

    // raise to next highest floor, turbo-speed
    raiseFloorTurbo,
    donutRaise,
    raiseFloor512,
    raiseFloor512AndChange,

    //jff 02/04/98  add types for generalized floor mover
    genFloor,
    genFloorChg,
    genFloorChg0,
    genFloorChgT,

    //new types for stair builders
    buildStair,
    genBuildStair,

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

  stair_e = (
    build8, // slowly build by 8
    turbo16, // quickly build by 16
    buildDown16 // haleyjd 09/24/10: [STRIFE] new stair type
  );

  floormove_t206 = record
    thinker: thinker_t;
    _type: floor_e;
    crush: boolean;
    sector: Psector_t;
    direction: integer;
    newspecial: integer;
    oldspecial: smallint;
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
    oldspecial: smallint;
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

  elevator_e = (
    elevateUp,
    elevateDown,
    elevateCurrent
  );

  elevator_t = record
    thinker: thinker_t;
    _type: elevator_e;
    sector: Psector_t;
    direction: integer;
    floordestheight: fixed_t;
    ceilingdestheight: fixed_t;
    speed: fixed_t;
  end;
  Pelevator_t = ^elevator_t;

// phares 3/12/98: added new model of friction for ice/sludge effects

  friction_t = record
    thinker: thinker_t;   // Thinker structure for friction
    friction: integer;    // friction value (E800 = normal)
    movefactor: integer;  // inertia factor when adding to momentum
    affectee: integer;    // Number of affected sector
  end;
  Pfriction_t = ^friction_t;

// phares 3/20/98: added new model of Pushers for push/pull effects

  pushertype_e = (
    p_push,
    p_pull,
    p_wind,
    p_current
  );

  pusher_t = record
    thinker: thinker_t;   // Thinker structure for Pusher
    _type: pushertype_e;
    source: Pmobj_t;      // Point source if point pusher
    x_mag: integer;       // X Strength
    y_mag: integer;       // Y Strength
    magnitude: integer;   // Vector strength for point pusher
    radius: integer;      // Effective radius for point pusher
    x, y: integer;        // X of point source if point pusher
    affectee: integer;    // Number of affected sector
  end;
  Ppusher_t = ^pusher_t;

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
  ELEVATORSPEED = 4 * FRACUNIT;
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

// JVAL: BOOM compatibility
  special_e = (
    floor_special,
    ceiling_special,
    lighting_special
  );

type
  linefunc_t = function (line: Pline_t): integer;

const
  MORE_FRICTION_MOMENTUM = 15000; // mud factor based on momentum
  ORIG_FRICTION = $E800;          // original value
  ORIG_FRICTION_FACTOR = 2048;    // original value
  CROUCH_FRICTION_FACTOR = 1536;  // JVAL: 20211101 - Crouch

var
  levelTimer: boolean;
  levelTimeCount: integer;

implementation

end.
