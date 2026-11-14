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
//  Radix: the debriefing, the screen between two levels (radix_intermission.pas
//  of Rad-X). RADIX.DAT has none of the pictures of the intermission of Doom:
//  WI_ConfigureReplacement (wi_stuff) puts these three procedures in its place.
//  Missing: the table of the ten best pilots (radix_score) and its two lines,
//  the count of the hits against the walls, the music.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_intermission;

interface

uses
  d_player;

//==============================================================================
// RX_Intermission_Start
//
// Setup for an intermission screen.
//
//==============================================================================
procedure RX_Intermission_Start(wbstartstruct: Pwbstartstruct_t);

//==============================================================================
// RX_Intermission_Ticker
//
// Called by main loop
//
//==============================================================================
procedure RX_Intermission_Ticker;

//==============================================================================
// RX_Intermission_Drawer
//
// Called by main loop,
// draws the intermission directly into the screen buffer.
//
//==============================================================================
procedure RX_Intermission_Drawer;

implementation

uses
  d_delphi,
  doomdef,
  d_event,
  g_game,
  mn_font,
  v_data,
  v_video,
  w_wad,
  radix_logic,
  DelphiDoom.Radix.Debriefing;

var
  in_tic: integer;
  in_struct: Pwbstartstruct_t;
  in_input: TRadixDebriefingInput;
  in_score: TRadixDebriefingScore;

//==============================================================================
//
// RX_Intermission_Start
//
//==============================================================================
procedure RX_Intermission_Start(wbstartstruct: Pwbstartstruct_t);
var
  pl: ^wbplayerstruct_t;
begin
  in_struct := wbstartstruct;
  in_tic := 0;
  // the level that the end of this one named (G_DoWorldDone goes to wminfo.next + 1)
  if radixnamedlevel > 0 then
    in_struct.next := radixnamedlevel - 1;
  pl := @in_struct.plyr[consoleplayer];

  in_input.HasSecondaryObjective := levelhassecondaryobjective;
  in_input.SecondaryObjectiveDone := radixlevelplayers[consoleplayer].secondaryobjective;
  in_input.Kills := pl.skills;
  in_input.MaxKills := in_struct.maxkills;
  in_input.Secrets := pl.ssecret;
  in_input.MaxSecrets := in_struct.maxsecret;
  in_input.Tics := pl.stime;
  in_input.ParTics := in_struct.partime;
  in_input.WallHitTics := 0; // the hits against the walls are not counted yet
  in_score := TRadixDebriefing.Score(in_input);
end;

//==============================================================================
//
// RX_CheckForInput
//
//==============================================================================
procedure RX_CheckForInput;
var
  i: integer;
  player: Pplayer_t;
begin
  // check for button presses to skip delays
  for i := 0 to MAXPLAYERS - 1 do
  begin
    player := @players[i];

    if playeringame[i] then
      if (player.cmd.buttons and BT_ATTACK <> 0) or (player.cmd.buttons and BT_USE <> 0) then
        G_WorldDone;
  end;
end;

//==============================================================================
//
// RX_Intermission_Ticker
//
//==============================================================================
procedure RX_Intermission_Ticker;
begin
  inc(in_tic);

  // the key that ended the level is still down in the first tics
  if in_tic > TICRATE div 2 then
    RX_CheckForInput;
end;

//==============================================================================
//
// RX_Intermission_Drawer
//
//==============================================================================
procedure RX_Intermission_Drawer;
var
  backscreen: string;
begin
  if in_struct = nil then
    exit;

  sprintf(backscreen, 'DebriefScreen%d', [gameepisode]);
  if W_CheckNumForName(backscreen) >= 0 then
    V_DrawPatchFullScreenTMP320x200(backscreen);

  M_WriteSmallTextCenter(30, 'MISSION ' + itoa(in_struct.last + 1) + ' COMPLETED', SCN_TMP);

  M_WriteSmallText(121, 71, TRadixDebriefing.PercentText(in_score.Mean), SCN_TMP);
  M_WriteSmallText(157, 81, TRadixDebriefing.SecondaryText(in_input), SCN_TMP);

  M_WriteSmallText(108, 91, TRadixDebriefing.CountText(in_input.Kills), SCN_TMP);
  M_WriteSmallText(130, 91, itoa(in_input.MaxKills), SCN_TMP);

  M_WriteSmallText(144, 101, TRadixDebriefing.PercentText(in_score.ProficientFlying), SCN_TMP);
  M_WriteSmallText(114, 111, TRadixDebriefing.TimeText(in_input.Tics div TICRATE), SCN_TMP);
  M_WriteSmallText(101, 121, TRadixDebriefing.TimeText(in_input.ParTics div TICRATE), SCN_TMP);

  M_WriteSmallTextCenter(131, 'YOU HAVE FOUND ' + itoa(in_input.Secrets) + ' OF ' + itoa(in_input.MaxSecrets) +
    ' SECRET AREAS', SCN_TMP);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

end.
