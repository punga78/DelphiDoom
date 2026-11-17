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
//  DESCRIPTION:
//    Archiving: SaveGame I/O.
//    Thinker, Ticker.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_tick;

interface

uses
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Engine.World,
  d_think;

//
// THINKERS
// All thinkers should be allocated by Z_Malloc
// so they can be operated on uniformly.
// The actual structures will vary in size,
// but the first element must be thinker_t.
//

type
  /// <summary>
  ///   The state of the tick (issue #245): the head of the thinker list and the tics of the level.
  ///   Class vars with a fixed address, like the globals they replace: no property and no method
  ///   (a call at every read); the class lives here, in the unit that writes them, so that the
  ///   routines of this unit keep reading them as before (see PIANO_TUTTO_A_CLASSI 11.22)
  /// </summary>
  TTickState = class sealed
  public
    /// <summary>Both the head and tail of the thinker list</summary>
    class var ThinkerCap: thinker_t;
    /// <summary>The tics since the level started</summary>
    class var LevelTime: integer;
  end;

//==============================================================================
//
// P_InitThinkers
//
//==============================================================================
procedure P_InitThinkers;

//==============================================================================
//
// P_AddThinker
//
//==============================================================================
procedure P_AddThinker(thinker: Pthinker_t);

//==============================================================================
//
// P_RemoveThinker
//
//==============================================================================
procedure P_RemoveThinker(thinker: Pthinker_t);

//==============================================================================
//
// P_Ticker
//
//==============================================================================
procedure P_Ticker;

//==============================================================================
//
// P_ThinkerIsRemoved
//
//==============================================================================
function P_ThinkerIsRemoved(thinker: Pthinker_t): boolean;

var
{$IFDEF HEXEN}
  TimerGame: integer;
{$ENDIF}
  isgamesuspended: boolean = true;
  isgamefreezed: boolean = false;

//==============================================================================
//
// P_ConfigureTickerConsole
// The console, given by the composition root
//
//==============================================================================
procedure P_ConfigureTickerConsole(const AConsole: IEngineConsole);

//==============================================================================
//
// P_WorldTime
// Where the time of the level is kept, for the world of the composition root
//
//==============================================================================
function P_WorldTime: TEngineWorldTime;

//==============================================================================
//
// P_ConfigureWorld
// The world, given by the composition root; p_tick owns it from here on
//
//==============================================================================
procedure P_ConfigureWorld(const AWorld: TEngineWorld);

//==============================================================================
//
// P_World
// The world of the level, for the classes and the rules of the games that keep
// their state in it (I_Error if P_ConfigureWorld() was not called)
//
//==============================================================================
function P_World: TEngineWorld;

//==============================================================================
//
// P_ThinkerHead
// The head of the list of the thinkers, as the world has it: the saved games
// walk the list from here (thinkercap stays the memory behind it)
//
//==============================================================================
function P_ThinkerHead: Pthinker_t;

implementation

uses
  DelphiDoom.Engine.Parity.Hooks,
  DelphiDoom.Thinkers.List,
  doomdef,
  i_system,
  d_player,
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  m_menu,
{$IFNDEF HEXEN}
  p_animdefs,
{$ENDIF}
  p_user,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  p_mobj,
  p_mobj_h,
  p_mobjlist,
{$IF DEFINED(HERETIC)}
  p_ambient,
{$ELSEIF DEFINED(HEXEN)}
  p_mapinfo,
  p_anim,
{$ENDIF}
  ps_main,  // JVAL: Script Events
  z_zone;

var
  // given by the composition root
  p_tickerconsole_ref: IEngineConsole = nil;
  p_world_ref: TEngineWorld = nil;

//==============================================================================
//
// P_ConfigureTickerConsole
//
//==============================================================================
procedure P_ConfigureTickerConsole(const AConsole: IEngineConsole);
begin
  p_tickerconsole_ref := AConsole;
end;

//==============================================================================
//
// P_TickerConsole
//
//==============================================================================
function P_TickerConsole: IEngineConsole;
begin
  if p_tickerconsole_ref = nil then
    I_Error('P_ConfigureTickerConsole() was not called: the console is missing');
  result := p_tickerconsole_ref;
end;

//==============================================================================
//
// P_WorldTime
//
//==============================================================================
function P_WorldTime: TEngineWorldTime;
begin
  result.LevelTime := @TTickState.LevelTime;
  result.IsFrozen := @isgamefreezed;
  result.IsSuspended := @isgamesuspended;
{$IFDEF HEXEN}
  result.TimerGame := @TimerGame;
{$ELSE}
  result.TimerGame := nil;
{$ENDIF}
end;

//==============================================================================
//
// P_ConfigureWorld
//
//==============================================================================
procedure P_ConfigureWorld(const AWorld: TEngineWorld);
begin
  if p_world_ref <> AWorld then
    p_world_ref.Free;
  p_world_ref := AWorld;
end;

//==============================================================================
//
// P_World
//
//==============================================================================
function P_World: TEngineWorld;
begin
  if p_world_ref = nil then
    I_Error('P_ConfigureWorld() was not called: the world is missing');
  result := p_world_ref;
end;

//==============================================================================
//
// P_ThinkerHead
//
//==============================================================================
function P_ThinkerHead: Pthinker_t;
begin
  result := Pthinker_t(P_World.Thinkers.Head);
end;

//==============================================================================
//
// P_InitThinkers
//
//==============================================================================
procedure P_InitThinkers;
begin
  P_World.Thinkers.Clear;
end;

//==============================================================================
//
// P_AddThinker
// Adds a new thinker at the end of the list.
// No check of the configuration here: P_InitThinkers runs (and checks) before
// the first thinker of a level can be added
//
//==============================================================================
procedure P_AddThinker(thinker: Pthinker_t);
begin
  p_world_ref.Thinkers.Add(PThinkerNode(thinker));
end;

//==============================================================================
//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
//
// JVAL 20191203 - Fixed non working plats & ceilings thanks to slayermbm
//                 https://www.doomworld.com/forum/topic/98789-fpcdoom-1124117-updated-dec-2-2019/?do=findComment&comment=2050845
//
//==============================================================================
procedure P_RemoveThinker(thinker: Pthinker_t);
begin
  p_world_ref.Thinkers.Remove(PThinkerNode(thinker));
end;

//==============================================================================
//
// P_ThinkerIsRemoved
//
//==============================================================================
function P_ThinkerIsRemoved(thinker: Pthinker_t): boolean;
begin
  Result := TThinkerList.IsRemoved(PThinkerNode(thinker));
end;

//==============================================================================
//
// P_Ticker
//
//==============================================================================
procedure P_Ticker;
var
  i: integer;
begin
  isgamesuspended := true;
  // run the tic
  if TGameSession.Paused then
    exit;

  // pause if in menu and at least one tic has been run
  if not TGameSession.NetGame and menuactive and
     not TGameSession.DemoPlayback and (players[TGameSession.ConsolePlayer].viewz <> 1) then
    exit;

  if not TGameSession.DemoPlayback and not TGameSession.DemoRecording and P_TickerConsole.IsActive and not TGameSession.NetGame and (TTickState.LevelTime <> 0) then
    exit;

  isgamesuspended := false;

  // JVAL: Script Events
  if TTickState.LevelTime = 0 then
  begin
    PS_EventMapStart;
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
        PS_EventPlayerEnter(i);
  end;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      P_PlayerThink(@players[i]);

{$IFDEF HEXEN}
  if TimerGame <> 0 then
  begin
    dec(TimerGame);
    if TimerGame = 0 then
      G_Completed(P_TranslateMap(P_GetMapNextMap(TGameSession.GameMap)), 0);
  end;

{$ENDIF}
  if TGameSession.DemoPlayback or TGameSession.DemoRecording then
    isgamefreezed := false;

  P_World.RunThinkers;
  if not isgamefreezed then
  begin
    P_UpdateSpecials;
    P_AnimateSurfaces;
{$IF DEFINED(HERETIC)}
    P_RespawnSpecials;
    P_AmbientSound;
{$ELSEIF DEFINED(HEXEN)}
{$ELSE}
    P_RespawnSpecials;
{$ENDIF}

    // JVAL: Script Events
    PS_EventTick(TTickState.LevelTime);

    if TTickState.LevelTime mod TICRATE = 0 then
    begin
      PS_EventTimerEverySecond(TTickState.LevelTime div TICRATE);
      if TTickState.LevelTime mod (60 * TICRATE) = 0 then
        PS_EventTimerEveryMinute(TTickState.LevelTime div (60 * TICRATE));
    end;
  end;

  // for par times
  inc(TTickState.LevelTime);

  // the parity tools (nothing when they are off)
  Parity_AfterTick;
end;

initialization

finalization
  p_world_ref.Free;
  p_world_ref := nil;

end.
