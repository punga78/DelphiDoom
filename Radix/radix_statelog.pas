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
//  Radix: a log of the state that Radix keeps beside the one of Doom, for the
//  tests at runtime (-radixstate file). The fingerprint of the state of the
//  engine (-statehash) does not see radixplayers: here the first player writes
//  a line whenever one of its numbers changes.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_statelog;

interface

type
  // what a unit of Radix adds to a line: a text of "name=value" words
  radixstatelogsource_t = function: string;

//==============================================================================
//
// RX_StateLogTick
// To call once at every tic of a level, after the thinkers of Radix. Nothing
// without the option -radixstate
//
//==============================================================================
procedure RX_StateLogTick;

//==============================================================================
//
// RX_StateLogAddSource
// Another group of words at the end of every line (the logic of the level)
//
//==============================================================================
procedure RX_StateLogAddSource(const source: radixstatelogsource_t);

implementation

uses
  SysUtils,
  doomdef,
  d_player,
  g_game,
  m_argv,
  m_fixed,
  p_tick,
  radix_playerstate;

const
  STATELOG_OPTION = '-radixstate';
  MAXSOURCES = 4;

var
  statelog_checked: boolean = false;
  statelog_open: boolean = false;
  statelog_file: TextFile;
  statelog_last: string = '';
  statelog_sources: array[0..MAXSOURCES - 1] of radixstatelogsource_t;
  statelog_numsources: integer = 0;

//==============================================================================
//
// RX_StateLogAddSource
//
//==============================================================================
procedure RX_StateLogAddSource(const source: radixstatelogsource_t);
begin
  if statelog_numsources < MAXSOURCES then
  begin
    statelog_sources[statelog_numsources] := source;
    inc(statelog_numsources);
  end;
end;

//==============================================================================
//
// RX_StateLogOpen
//
//==============================================================================
procedure RX_StateLogOpen;
var
  p: integer;
begin
  statelog_checked := true;
  p := M_CheckParm(STATELOG_OPTION);
  if (p <= 0) or (p >= myargc - 1) then
    exit;
  AssignFile(statelog_file, myargv[p + 1]);
  {$I-}
  Rewrite(statelog_file);
  {$I+}
  statelog_open := IOResult = 0;
end;

//==============================================================================
//
// RX_StateLogTick
//
//==============================================================================
procedure RX_StateLogTick;
var
  p: Pplayer_t;
  rp: Pradixplayer_t;
  s: string;
  i: integer;
begin
  if not statelog_checked then
    RX_StateLogOpen;
  if not statelog_open then
    exit;

  p := @players[consoleplayer];
  if p.mo = nil then
    exit;
  rp := RX_PlayerState(p);
  s := Format('map=%d health=%d armor=%d energy=%d reserve=%d bombs=%d burner=%d cannons=%d spreader=%d ' +
    'powers=%d,%d,%d,%d,%d kills=%d',
    [gamemap, p.health, p.armorpoints, rp.energy, rp.energy_reserve, rp.plasmabombs, Ord(rp.afterburner),
     rp.neutroncannonlevel, rp.neutronspreaderlevel,
     // the powers count their tics down: only whether they are on
     Ord(rp.radixpowers[0] > 0), Ord(rp.radixpowers[1] > 0), Ord(rp.radixpowers[2] > 0),
     Ord(rp.radixpowers[3] > 0), Ord(rp.radixpowers[4] > 0),
     p.killcount]);
  for i := 0 to statelog_numsources - 1 do
    s := s + ' ' + statelog_sources[i]();
  if s = statelog_last then
    exit;
  statelog_last := s;
  writeln(statelog_file, Format('tic=%d x=%d y=%d %s', [leveltime, p.mo.x div FRACUNIT, p.mo.y div FRACUNIT, s]));
  // a game that is closed from outside must leave what it wrote so far
  Flush(statelog_file);
end;

initialization

finalization
  if statelog_open then
    CloseFile(statelog_file);

end.
