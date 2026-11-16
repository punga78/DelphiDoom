//------------------------------------------------------------------------------
//
//  DelphiHexen is a source port of the game Hexen and it is
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_spec_h;

interface

uses
  d_delphi,
  m_fixed,
  d_player,
  d_think,
  p_local,
  p_mobj_h,
  p_tick,
  r_defs;

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

  lightflash_t = record
    thinker: thinker_t;
    sector: Psector_t;
    count: integer;
    maxlight: integer;
    minlight: integer;
    maxtime: integer;
    mintime: integer;
  end;

  strobe_t = record
    thinker: thinker_t;
    sector: Psector_t;
    count: integer;
    minlight: integer;
    maxlight: integer;
    darktime: integer;
    brighttime: integer;
  end;

  glow_t = record
    thinker: thinker_t;
    sector: Psector_t;
    minlight: integer;
    maxlight: integer;
    direction: integer;
  end;

type
  bwhere_e = (
    SWTCH_TOP,
    SWTCH_MIDDLE,
    SWTCH_BOTTOM
  );

  button_t = record
    line: Pline_t;
    where: bwhere_e;
    btexture: integer;
    btimer: integer;
    soundorg: Pmobj_t;
  end;

const
  // max # of wall switches in a level
  MAXSWITCHES = 50;

  // 4 players, 4 buttons each at once, max.
  MAXBUTTONS = 16;

  // 1 second, in ticks.
  BUTTONTIME = 35;

type
//
// P_PLATS
//
  plat_e = (
    PLAT_UP,
    PLAT_DOWN,
    PLAT_WAITING
  );

  plattype_e = (
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
  MAXPLATS = 512;  // JVAL Originally was 30

type
//
// P_DOORS
//
  vldoor_e = (
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
    sector: Psector_t;
    _type: vldoor_e;
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

type
//
// P_CEILNG
//
  ceiling_e = (
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
    sector: Psector_t;
    _type: ceiling_e;
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
  MAXCEILINGS = 128; // JVAL 20210130 - Old value was 30

type
//
// P_FLOOR
//
  floor_e = (
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

  floormove_t = record
    thinker: thinker_t;
    sector: Psector_t;
    _type: floor_e;
    crush: boolean;
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
    RES_OK,
    RES_CRUSHED,
    RES_PASTDEST
  );

  stairs_e = (
    STAIRS_NORMAL,
    STAIRS_SYNC,
    STAIRS_PHASED
  );

var
  LavaInflictor: mobj_t;

const
  ORIG_FRICTION = $E800;          // original value
  CROUCH_FRICTION_FACTOR = 1536;  // JVAL: 20211101 - Crouch

implementation

end.
