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
//   Networking stuff.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_net;

interface

uses
  d_delphi,
  doomdef,
  d_player,
  d_ticcmd,
  d_net_h,
  m_base,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Logging.Intf,
{$IFNDEF HEXEN}
  DelphiDoom.Engine.Endoom.Intf,
{$ENDIF}
  DelphiDoom.GameState.Intf;

// Network play related stuff.
// The packets, the nodes, the buffers of the commands and the decisions of how many tics
// to run belong to Libs\Net: this unit gives the game its own loop around them.

//==============================================================================
//
// D_ConfigureNet
// The services that the network library uses, given by the composition root
//
//==============================================================================
procedure D_ConfigureNet(const AClock: IClock; const ALog: ILog; const AGame: IGameContext);

{$IFNDEF HEXEN}
//==============================================================================
//
// D_ConfigureNetEndoom
// The end screen, which ticks with the loop of the game; given by the composition root
//
//==============================================================================
procedure D_ConfigureNetEndoom(const AScreen: IEngineEndoomScreen);
{$ENDIF}

{ Create any new ticcmds and broadcast to other players. }

//==============================================================================
//
// NetUpdate
//
//==============================================================================
procedure NetUpdate;

{ Broadcasts special packets to other players }
{  to notify of game exit }

//==============================================================================
//
// D_QuitNetGame
//
//==============================================================================
procedure D_QuitNetGame;

{? how many ticks to run? }

//==============================================================================
//
// D_RunMultipleTicks
//
//==============================================================================
procedure D_RunMultipleTicks;

//==============================================================================
//
// D_RunSingleTick
//
//==============================================================================
procedure D_RunSingleTick;

//==============================================================================
//
// D_CheckNetGame
//
//==============================================================================
procedure D_CheckNetGame;

//==============================================================================
//
// D_ShutDownNetGame
//
//==============================================================================
procedure D_ShutDownNetGame;

//==============================================================================
//
// D_NetExpectedConsistency
// The consistency check that a new command carries: the one that the players agreed for the tic
//
//==============================================================================
function D_NetExpectedConsistency: smallint;

//==============================================================================
//
// D_VerifyNetConsistency
// Compares the consistency of a command that arrived with the one kept for its tic,
// and keeps the new local value
//
//==============================================================================
procedure D_VerifyNetConsistency(const player: integer; const received: smallint; const localvalue: integer);

//==============================================================================
//
// D_GetNetCommand
// The command of a player for a position of the buffer of the network
//
//==============================================================================
procedure D_GetNetCommand(const player, buf: integer; const cmd: Pticcmd_t);

var
  ticdup: integer;

var
  isinterpolateddisplay: boolean;
  firstinterpolation: boolean;

  S_ERR_DIF_NET: string = 'Different ' + APPNAME + ' versions cannot play a net game!';

implementation

uses
  System.SysUtils,
  m_menu,
  c_con,
  i_startup,
  i_system,
  i_net,
  i_io,
  d_main,
  d_event,
  r_intrpl,
  r_main,
  p_mobj_h,
{$IFDEF DOOM_OR_STRIFE}
  p_local,
{$ENDIF}
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  DelphiDoom.Net.Types,
  DelphiDoom.Net.Intf,
  DelphiDoom.Net.Factory,
  DelphiDoom.Engine.Net.Services;

var
  net_clock: IClock;
  net_log: ILog;
  net_game: IGameContext;
  net_services: TEngineNetServices;
  net_servicesref: IInterface;
  net_sync: INetTicSync;
  net_planner: INetTicPlanner;
  net_consistency: INetConsistency;

//==============================================================================
//
// D_ConfigureNet
//
//==============================================================================
procedure D_ConfigureNet(const AClock: IClock; const ALog: ILog; const AGame: IGameContext);
begin
  net_clock := AClock;
  net_log := ALog;
  net_game := AGame;
end;

{$IFNDEF HEXEN}
var
  // given by the composition root (D_ConfigureNetEndoom)
  net_endoom: IEngineEndoomScreen = nil;

//==============================================================================
//
// D_ConfigureNetEndoom
//
//==============================================================================
procedure D_ConfigureNetEndoom(const AScreen: IEngineEndoomScreen);
begin
  net_endoom := AScreen;
end;

//==============================================================================
//
// D_EndoomTicker
//
//==============================================================================
procedure D_EndoomTicker;
begin
  if net_endoom = nil then
    I_Error('D_ConfigureNetEndoom() was not called: the end screen is missing');
  net_endoom.Tick;
end;
{$ENDIF}

// The library does not stop the program: its errors end here
procedure D_NetFailure(const E: Exception);
begin
  if E is ENetVersionMismatchException then
    I_Error(S_ERR_DIF_NET)
  else
    I_Error('%s', [E.Message]);
end;

procedure D_CheckNetStarted;
begin
  if net_sync = nil then
    I_Error('The network is not started (D_CheckNetGame was not called)');
end;

//==============================================================================
//
// NetUpdate
// Builds ticcmds for console player,
// sends out a packet
//
//==============================================================================
procedure NetUpdate;
begin
  D_CheckNetStarted;
  try
    net_sync.SingleTics := singletics;
    net_sync.NetUpdate;
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

//==============================================================================
//
// D_NetExpectedConsistency
//
//==============================================================================
function D_NetExpectedConsistency: smallint;
begin
  D_CheckNetStarted;
  result := net_consistency.Expected(consoleplayer, net_sync.MakeTic);
end;

//==============================================================================
//
// D_VerifyNetConsistency
//
//==============================================================================
procedure D_VerifyNetConsistency(const player: integer; const received: smallint; const localvalue: integer);
begin
  D_CheckNetStarted;
  try
    net_consistency.Verify(player, gametic, received, localvalue);
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

//==============================================================================
//
// D_GetNetCommand
//
//==============================================================================
procedure D_GetNetCommand(const player, buf: integer; const cmd: Pticcmd_t);
var
  bytes: TBytes;
begin
  D_CheckNetStarted;
  try
    bytes := net_sync.NetCommand(player, buf);
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
  Move(bytes[0], cmd^, SizeOf(ticcmd_t));
end;

// A command that is run again for a duplicated tic does not repeat what must happen only once
procedure D_ClearDuplicatedCommand(const player, buf: integer);
var
  cmd: ticcmd_t;
  bytes: TBytes;
begin
  D_GetNetCommand(player, buf, @cmd);
  cmd.chatchar := 0;
  cmd.commands := 0;
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;
  SetLength(bytes, SizeOf(ticcmd_t));
  Move(cmd, bytes[0], SizeOf(ticcmd_t));
  try
    net_sync.SetNetCommand(player, buf, bytes);
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

//==============================================================================
//
// D_CheckNetGame
// Works out player numbers among the net participants
//
//==============================================================================
procedure D_CheckNetGame;
var
  i: integer;
  codec: INetPacketCodec;
  transport: INetTransport;
  settings: TNetSyncSettings;
  info: TNetSetupInfo;
begin
  if net_clock = nil then
    I_Error('D_CheckNetGame(): the network is not configured (ComposeEngine was not called)');

  // I_InitNetwork sets netgame and what the command line says
  I_InitNetwork;

  consoleplayer := net_consoleplayer;
  displayplayer := net_consoleplayer;
  ticdup := net_ticdup;

  net_services := TEngineNetServices.Create;
  net_servicesref := net_services;

  try
    codec := TNetFactory.CreateCodec(SizeOf(ticcmd_t));
    transport := nil;
    if netgame then
      transport := TNetFactory.CreateWinsockTransport(net_port, net_peers);

    settings := TNetSyncSettings.Make(net_numnodes, MAXPLAYERS, consoleplayer);
    settings.TicDup := ticdup;
    settings.ExtraTics := net_extratics;
    settings.TicRate := TICRATE;
    net_sync := TNetFactory.CreateTicSync(settings, transport, codec, net_clock, net_log, net_game,
      net_services, net_services, net_services);
    net_planner := net_sync as INetTicPlanner;
    net_consistency := TNetFactory.CreateConsistencyTracker(MAXPLAYERS, ticdup);

    if netgame then
    begin
      autostart := true;
      if consoleplayer <> 0 then
        SUC_StartingNetwork('listening for network start info...')
      else
        SUC_StartingNetwork('sending network start info...');

      // the key player sends what it has, the others take it
      info := Default(TNetSetupInfo);
      info.EngineVersion := D_EngineVersion;
      info.Skill := Ord(startskill);
      info.Deathmatch := deathmatch;
      info.NoMonsters := nomonsters;
      info.Respawn := respawnparm;
      {$IFDEF STRIFE}
      info.MapByte := startmap;
      {$ELSE}
      info.MapByte := TNetSetupInfo.PackMap(startepisode, startmap);
      {$ENDIF}
      info.Flags := 0;
      if allowplayerjumps then
        info.Flags := info.Flags or 1;
      if spawnrandommonsters then
        info.Flags := info.Flags or 2;
      {$IFDEF DOOM_OR_STRIFE}
      if allowterrainsplashes then
        info.Flags := info.Flags or 4;
      {$ENDIF}
      {$IFDEF DOOM}
      if majorbossdeathendsdoom1level then
        info.Flags := info.Flags or 8;
      {$ENDIF}

      info := TNetFactory.CreateStartArbiter(net_sync as INetPacketPort, net_services,
        net_numnodes, consoleplayer).Arbitrate(info);

      if consoleplayer <> 0 then
      begin
        startskill := skill_t(info.Skill);
        deathmatch := info.Deathmatch;
        nomonsters := info.NoMonsters;
        respawnparm := info.Respawn;
        {$IFDEF STRIFE}
        startmap := info.MapByte;
        {$ELSE}
        startmap := TNetSetupInfo.UnpackMap(info.MapByte);
        startepisode := TNetSetupInfo.UnpackEpisode(info.MapByte);
        {$ENDIF}
        allowplayerjumps := info.Flags and 1 <> 0;
        spawnrandommonsters := info.Flags and 2 <> 0;
        {$IFDEF DOOM_OR_STRIFE}
        allowterrainsplashes := info.Flags and 4 <> 0;
        {$ENDIF}
        {$IFDEF DOOM}
        majorbossdeathendsdoom1level := info.Flags and 8 <> 0;
        {$ENDIF}
      end;

      SUC_FinishedNetwork;
    end;
  except
    on E: ENetVersionMismatchException do
      I_Error('D_ArbitrateNetStart(): ' + S_ERR_DIF_NET);
    on E: ENetException do
      D_NetFailure(E);
  end;

  printf(' startskill %d  deathmatch: %d  startmap: %d' {$IFNDEF STRIFE} + '  startepisode: %d'{$ENDIF} +#13#10,
    [Ord(startskill), deathmatch, startmap{$IFNDEF STRIFE}, startepisode{$ENDIF}]);

  for i := 0 to net_numnodes - 1 do
    playeringame[i] := true;

  printf(' player %d of %d (%d nodes)'#13#10,
    [consoleplayer + 1, net_numnodes, net_numnodes]);
end;

//==============================================================================
//
// D_ShutDownNetGame
// Releases the network: the sockets are closed with the transport
//
//==============================================================================
procedure D_ShutDownNetGame;
begin
  net_planner := nil;
  net_consistency := nil;
  net_sync := nil;
  net_servicesref := nil;
  net_services := nil;
end;

//==============================================================================
//
// D_QuitNetGame
// Called before quitting to leave a net game
// without hanging the other players
//
//==============================================================================
procedure D_QuitNetGame;
begin
  if not netgame or not usergame or (consoleplayer = -1) or demoplayback then
    exit;

  D_CheckNetStarted;
  try
    net_sync.QuitNetGame;
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

//==============================================================================
//
// D_RunMultipleTicks
//
//==============================================================================
procedure D_RunMultipleTicks;
var
  i, j: integer;
  realtics: integer;
  counts: integer;
  buf: integer;
  entertime: integer;
  ready: boolean;
begin
  D_CheckNetStarted;
  try
    // get real tics
    realtics := net_planner.BeginRun;
    entertime := net_planner.EnterTime;

    // get available tics
    NetUpdate;

    if I_GameFinished then
      exit;

    // decide how many tics to run
    counts := net_planner.PlanTics(realtics);

    didinterpolations := false;
    storedpolyinterpolations := false;
    isinterpolateddisplay := true;
    firstinterpolation := true;

    // wait for new tics if needed
    repeat
      NetUpdate;
      ready := net_planner.TicsReady(counts);

      // don't stay in here forever -- give the menu a chance to work
      // JVAL 16/2/2011 - We insist while demo playback or recording!
      if net_planner.MustYield then
      begin
        {$IFNDEF HEXEN}
        D_EndoomTicker;
        {$ENDIF}
        M_Ticker;
        exit;
      end;

      if (gamestate = GS_LEVEL) and (oldgamestate = Ord(GS_LEVEL)) then
      begin
        if interpolate then
        begin
          if not didinterpolations then
          begin
            R_StoreInterpolationData(entertime, counts * ticdup);
          end;
          if R_Interpolate then
          begin
            didinterpolations := true;
            D_Display;
            firstinterpolation := false;
          end;
        end
        else if interpolateoncapped and firstinterpolation then
        begin
          R_StoreInterpolationData(entertime, counts * ticdup);
          if R_Interpolate then
          begin
            didinterpolations := true;
            D_Display;
            firstinterpolation := false;
          end;
        end;
      end;
    until ready;

    if didinterpolations then
      R_RestoreInterpolationData
    else if storedpolyinterpolations then
      R_RestoreInterpolationPolys;

    ticfrac := 0;
    isinterpolateddisplay := false;

    // run the count * ticdup dics
    while counts <> 0 do
    begin
      dec(counts);

      for i := 0 to ticdup - 1 do
      begin
        net_planner.VerifyCanRunTic;
        if advancedemo then
          D_DoAdvanceDemo;
        R_Ticker;
        {$IFNDEF HEXEN}
        D_EndoomTicker;
        {$ENDIF}
        M_Ticker;
        C_Ticker;
        interpolationstarttime := I_GetTime * $10000; // I_GetFracTime;
        G_Ticker;
        inc(gametic);

        // modify command for duplicated tics
        if i <> ticdup - 1 then
        begin
          buf := (gametic div ticdup) mod BACKUPTICS;
          for j := 0 to MAXPLAYERS - 1 do
            D_ClearDuplicatedCommand(j, buf);
        end;
      end;
      NetUpdate;  // check for new console commands
    end;

    // Update display, next frame, with current state.
    if not didinterpolations or (Ord(gamestate) <> wipegamestate) then
    begin
      firstinterpolation := true;
      D_Display;
    end;
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

//==============================================================================
//
// D_RunSingleTick
//
//==============================================================================
procedure D_RunSingleTick;
begin
  D_CheckNetStarted;
  try
    net_sync.BuildSingleTic;
    if advancedemo then
      D_DoAdvanceDemo;
    R_Ticker;
    {$IFNDEF HEXEN}
    D_EndoomTicker;
    {$ENDIF}
    M_Ticker;
    C_Ticker;
    G_Ticker;
    inc(gametic);
    net_sync.EndSingleTic;
    firstinterpolation := true;
    D_Display;
  except
    on E: ENetException do
      D_NetFailure(E);
  end;
end;

end.
