{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loop of the game around Libs\Net                   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Net.Game;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  d_ticcmd,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Logging.Intf,
  DelphiDoom.GameState.Intf,
  DelphiDoom.Net.Intf,
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Net.Services;

type
  /// <summary>
  ///   NetUpdate, D_CheckNetGame, D_RunMultipleTicks, D_RunSingleTick, D_QuitNetGame and the
  ///   consistency of the old d_net.pas: the packets, the nodes, the buffers of the commands and
  ///   the decisions of how many tics to run belong to Libs\Net; this class gives the game its own
  ///   loop around them (the tickers of the menu, the console and the game, the display, the
  ///   interpolation)
  /// </summary>
  TEngineNetGame = class(TInterfacedObject, IEngineNetGame)
  strict private
    FClock: IClock;
    FLog: ILog;
    FGame: IGameContext;
    FConsole: IEngineConsole;
    FEndScreenTick: TProc;
    FServices: TEngineNetServices;
    FServicesReference: IInterface;
    FSync: INetTicSync;
    FPlanner: INetTicPlanner;
    FConsistency: INetConsistency;
    procedure CheckStarted;
    procedure ClearDuplicatedCommand(const APlayer, ABuffer: Integer);
    procedure ArbitrateStart;
    class procedure Fail(const AException: Exception); static;
  public
    /// <param name="AEndScreenTick">
    ///   The tic of the end screen (ENDOOM), run with the tickers of the menu and the console;
    ///   an empty procedure in Hexen, that has no end screen
    /// </param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const AClock: IClock; const ALog: ILog; const AGame: IGameContext;
      const AConsole: IEngineConsole; const AEndScreenTick: TProc);
    procedure Start;
    procedure Shutdown;
    procedure Update;
    procedure Quit;
    procedure RunMultipleTics;
    procedure RunSingleTic;
    function ExpectedConsistency: SmallInt;
    procedure VerifyConsistency(const APlayer: Integer; const AReceived: SmallInt;
      const ALocalValue: Integer);
    procedure GetCommand(const APlayer, ABuffer: Integer; const ACommand: Pticcmd_t);
  end;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  d_net,
  d_net_h,
  m_menu,
  i_startup,
  i_system,
  i_net,
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
  DelphiDoom.Net.Factory;

const
  SClockIsNil = 'TEngineNetGame: the clock is nil';
  SLogIsNil = 'TEngineNetGame: the log is nil';
  SGameIsNil = 'TEngineNetGame: the context of the game is nil';
  SConsoleIsNil = 'TEngineNetGame: the console is nil';
  SEndScreenTickIsNil = 'TEngineNetGame: the tic of the end screen is nil';
  SNotStarted = 'The network is not started (D_CheckNetGame was not called)';
  SArbitrateFailed = 'D_ArbitrateNetStart(): ';

{ TEngineNetGame }

constructor TEngineNetGame.Create(const AClock: IClock; const ALog: ILog;
  const AGame: IGameContext; const AConsole: IEngineConsole; const AEndScreenTick: TProc);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create(SClockIsNil);
  if not Assigned(ALog) then
    raise EArgumentNilException.Create(SLogIsNil);
  if not Assigned(AGame) then
    raise EArgumentNilException.Create(SGameIsNil);
  if not Assigned(AConsole) then
    raise EArgumentNilException.Create(SConsoleIsNil);
  if not Assigned(AEndScreenTick) then
    raise EArgumentNilException.Create(SEndScreenTickIsNil);
  FClock := AClock;
  FLog := ALog;
  FGame := AGame;
  FConsole := AConsole;
  FEndScreenTick := AEndScreenTick;
end;

// The library does not stop the program: its errors end here
class procedure TEngineNetGame.Fail(const AException: Exception);
begin
  if AException is ENetVersionMismatchException then
    I_Error(S_ERR_DIF_NET)
  else
    I_Error('%s', [AException.Message]);
end;

procedure TEngineNetGame.CheckStarted;
begin
  if FSync = nil then
    I_Error(SNotStarted);
end;

procedure TEngineNetGame.Update;
begin
  CheckStarted;
  try
    FSync.SingleTics := singletics;
    FSync.NetUpdate;
  except
    on E: ENetException do
      Fail(E);
  end;
end;

function TEngineNetGame.ExpectedConsistency: SmallInt;
begin
  CheckStarted;
  Result := FConsistency.Expected(consoleplayer, FSync.MakeTic);
end;

procedure TEngineNetGame.VerifyConsistency(const APlayer: Integer; const AReceived: SmallInt;
  const ALocalValue: Integer);
begin
  CheckStarted;
  try
    // g_game.gametic: a method of the class could hide the global of the same name
    FConsistency.Verify(APlayer, g_game.gametic, AReceived, ALocalValue);
  except
    on E: ENetException do
      Fail(E);
  end;
end;

procedure TEngineNetGame.GetCommand(const APlayer, ABuffer: Integer; const ACommand: Pticcmd_t);
var
  LBytes: TBytes;
begin
  CheckStarted;
  try
    LBytes := FSync.NetCommand(APlayer, ABuffer);
  except
    on E: ENetException do
      Fail(E);
  end;
  Move(LBytes[0], ACommand^, SizeOf(ticcmd_t));
end;

// A command that is run again for a duplicated tic does not repeat what must happen only once
procedure TEngineNetGame.ClearDuplicatedCommand(const APlayer, ABuffer: Integer);
var
  LCommand: ticcmd_t;
  LBytes: TBytes;
begin
  GetCommand(APlayer, ABuffer, @LCommand);
  LCommand.chatchar := 0;
  LCommand.commands := 0;
  if LCommand.buttons and BT_SPECIAL <> 0 then
    LCommand.buttons := 0;
  SetLength(LBytes, SizeOf(ticcmd_t));
  Move(LCommand, LBytes[0], SizeOf(ticcmd_t));
  try
    FSync.SetNetCommand(APlayer, ABuffer, LBytes);
  except
    on E: ENetException do
      Fail(E);
  end;
end;

// The key player sends what it has, the others take it
procedure TEngineNetGame.ArbitrateStart;
var
  LInfo: TNetSetupInfo;
begin
  if consoleplayer <> 0 then
    SUC_StartingNetwork('listening for network start info...')
  else
    SUC_StartingNetwork('sending network start info...');

  LInfo := Default(TNetSetupInfo);
  LInfo.EngineVersion := D_EngineVersion;
  LInfo.Skill := Ord(startskill);
  LInfo.Deathmatch := deathmatch;
  LInfo.NoMonsters := nomonsters;
  LInfo.Respawn := respawnparm;
{$IFDEF STRIFE}
  LInfo.MapByte := startmap;
{$ELSE}
  LInfo.MapByte := TNetSetupInfo.PackMap(startepisode, startmap);
{$ENDIF}
  LInfo.Flags := 0;
  if allowplayerjumps then
    LInfo.Flags := LInfo.Flags or 1;
  if spawnrandommonsters then
    LInfo.Flags := LInfo.Flags or 2;
{$IFDEF DOOM_OR_STRIFE}
  if allowterrainsplashes then
    LInfo.Flags := LInfo.Flags or 4;
{$ENDIF}
{$IFDEF DOOM}
  if majorbossdeathendsdoom1level then
    LInfo.Flags := LInfo.Flags or 8;
{$ENDIF}

  LInfo := TNetFactory.CreateStartArbiter(FSync as INetPacketPort, FServices,
    net_numnodes, consoleplayer).Arbitrate(LInfo);

  if consoleplayer <> 0 then
  begin
    startskill := skill_t(LInfo.Skill);
    deathmatch := LInfo.Deathmatch;
    nomonsters := LInfo.NoMonsters;
    respawnparm := LInfo.Respawn;
{$IFDEF STRIFE}
    startmap := LInfo.MapByte;
{$ELSE}
    startmap := TNetSetupInfo.UnpackMap(LInfo.MapByte);
    startepisode := TNetSetupInfo.UnpackEpisode(LInfo.MapByte);
{$ENDIF}
    allowplayerjumps := LInfo.Flags and 1 <> 0;
    spawnrandommonsters := LInfo.Flags and 2 <> 0;
{$IFDEF DOOM_OR_STRIFE}
    allowterrainsplashes := LInfo.Flags and 4 <> 0;
{$ENDIF}
{$IFDEF DOOM}
    majorbossdeathendsdoom1level := LInfo.Flags and 8 <> 0;
{$ENDIF}
  end;

  SUC_FinishedNetwork;
end;

procedure TEngineNetGame.Start;
var
  LIndex: Integer;
  LTransport: INetTransport;
  LSettings: TNetSyncSettings;
begin
  // I_InitNetwork sets netgame and what the command line says
  I_InitNetwork;

  consoleplayer := net_consoleplayer;
  displayplayer := net_consoleplayer;
  ticdup := net_ticdup;

  FServices := TEngineNetServices.Create;
  FServicesReference := FServices;

  try
    LTransport := nil;
    if netgame then
      LTransport := TNetFactory.CreateWinsockTransport(net_port, net_peers);

    LSettings := TNetSyncSettings.Make(net_numnodes, MAXPLAYERS, consoleplayer);
    LSettings.TicDup := ticdup;
    LSettings.ExtraTics := net_extratics;
    LSettings.TicRate := TICRATE;
    FSync := TNetFactory.CreateTicSync(LSettings, LTransport, TNetFactory.CreateCodec(SizeOf(ticcmd_t)),
      FClock, FLog, FGame, FServices, FServices, FServices);
    FPlanner := FSync as INetTicPlanner;
    FConsistency := TNetFactory.CreateConsistencyTracker(MAXPLAYERS, ticdup);

    if netgame then
    begin
      autostart := true;
      ArbitrateStart;
    end;
  except
    on E: ENetVersionMismatchException do
      I_Error(SArbitrateFailed + S_ERR_DIF_NET);
    on E: ENetException do
      Fail(E);
  end;

  printf(' startskill %d  deathmatch: %d  startmap: %d' {$IFNDEF STRIFE} + '  startepisode: %d'{$ENDIF} +#13#10,
    [Ord(startskill), deathmatch, startmap{$IFNDEF STRIFE}, startepisode{$ENDIF}]);

  for LIndex := 0 to net_numnodes - 1 do
    playeringame[LIndex] := true;

  printf(' player %d of %d (%d nodes)'#13#10,
    [consoleplayer + 1, net_numnodes, net_numnodes]);
end;

procedure TEngineNetGame.Shutdown;
begin
  FPlanner := nil;
  FConsistency := nil;
  FSync := nil;
  FServicesReference := nil;
  FServices := nil;
end;

// Called before quitting to leave a net game without hanging the other players
procedure TEngineNetGame.Quit;
begin
  if not netgame or not usergame or (consoleplayer = -1) or demoplayback then
    Exit;

  CheckStarted;
  try
    FSync.QuitNetGame;
  except
    on E: ENetException do
      Fail(E);
  end;
end;

procedure TEngineNetGame.RunMultipleTics;
var
  LDuplicate, LPlayer: Integer;
  LRealTics: Integer;
  LCounts: Integer;
  LBuffer: Integer;
  LEnterTime: Integer;
  LReady: Boolean;
begin
  CheckStarted;
  try
    // get real tics
    LRealTics := FPlanner.BeginRun;
    LEnterTime := FPlanner.EnterTime;

    // get available tics
    Update;

    if I_GameFinished then
      Exit;

    // decide how many tics to run
    LCounts := FPlanner.PlanTics(LRealTics);

    didinterpolations := false;
    storedpolyinterpolations := false;
    firstinterpolation := true;

    // wait for new tics if needed
    repeat
      Update;
      LReady := FPlanner.TicsReady(LCounts);

      // don't stay in here forever -- give the menu a chance to work
      // JVAL 16/2/2011 - We insist while demo playback or recording!
      if FPlanner.MustYield then
      begin
        FEndScreenTick;
        M_Ticker;
        Exit;
      end;

      if (gamestate = GS_LEVEL) and (oldgamestate = Ord(GS_LEVEL)) then
      begin
        if interpolate then
        begin
          if not didinterpolations then
            R_StoreInterpolationData(LEnterTime, LCounts * ticdup);
          if R_Interpolate then
          begin
            didinterpolations := true;
            D_Display;
            firstinterpolation := false;
          end;
        end
        else if interpolateoncapped and firstinterpolation then
        begin
          R_StoreInterpolationData(LEnterTime, LCounts * ticdup);
          if R_Interpolate then
          begin
            didinterpolations := true;
            D_Display;
            firstinterpolation := false;
          end;
        end;
      end;
    until LReady;

    if didinterpolations then
      R_RestoreInterpolationData
    else if storedpolyinterpolations then
      R_RestoreInterpolationPolys;

    ticfrac := 0;

    // run the count * ticdup dics
    while LCounts <> 0 do
    begin
      Dec(LCounts);

      for LDuplicate := 0 to ticdup - 1 do
      begin
        FPlanner.VerifyCanRunTic;
        if advancedemo then
          D_DoAdvanceDemo;
        R_Ticker;
        FEndScreenTick;
        M_Ticker;
        FConsole.Tick;
        interpolationstarttime := I_GetTime * $10000; // I_GetFracTime;
        G_Ticker;
        Inc(g_game.gametic);

        // modify command for duplicated tics
        if LDuplicate <> ticdup - 1 then
        begin
          LBuffer := (g_game.gametic div ticdup) mod BACKUPTICS;
          for LPlayer := 0 to MAXPLAYERS - 1 do
            ClearDuplicatedCommand(LPlayer, LBuffer);
        end;
      end;
      Update;  // check for new console commands
    end;

    // Update display, next frame, with current state.
    if not didinterpolations or (Ord(gamestate) <> wipegamestate) then
    begin
      firstinterpolation := true;
      D_Display;
    end;
  except
    on E: ENetException do
      Fail(E);
  end;
end;

procedure TEngineNetGame.RunSingleTic;
begin
  CheckStarted;
  try
    FSync.BuildSingleTic;
    if advancedemo then
      D_DoAdvanceDemo;
    R_Ticker;
    FEndScreenTick;
    M_Ticker;
    FConsole.Tick;
    G_Ticker;
    Inc(g_game.gametic);
    FSync.EndSingleTic;
    firstinterpolation := true;
    D_Display;
  except
    on E: ENetException do
      Fail(E);
  end;
end;

end.
