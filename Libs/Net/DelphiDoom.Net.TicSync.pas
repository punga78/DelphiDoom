{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the synchronisation of the commands               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.TicSync;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf, DelphiDoom.GameState.Intf,
  DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>
  ///   The old NetUpdate, GetPackets, HSendPacket, HGetPacket, D_QuitNetGame and the decisions of
  ///   D_RunMultipleTicks, without the globals of the engine: the commands of every player for the
  ///   last BACKUPTICS tics, the tics that every node has sent, the requests to send again, the
  ///   time. The game loop itself (G_Ticker, the display) stays in the engine
  /// </summary>
  /// <remarks>
  ///   Node 0 is this computer: its packets go back to itself (one at a time), so its commands
  ///   enter the store the same way as the others'. The class is created when the game is already
  ///   arbitrated: every node is in the game
  /// </remarks>
  TNetTicSync = class(TInterfacedObject, INetTicSync, INetTicPlanner, INetPacketPort)
  private
    FSettings: TNetSyncSettings;
    FTransport: INetTransport;
    FCodec: INetPacketCodec;
    FClock: IClock;
    FLog: ILog;
    FGame: IGameContext;
    FInput: INetLocalInput;
    FPlayers: INetPlayers;
    FTrace: INetTrace;
    FLocalCmds: array of TBytes;
    FNetCmds: array of array of TBytes;
    FNetTics: array of Integer;
    FNodeInGame: array of Boolean;
    FRemoteResend: array of Boolean;
    FResendTo: array of Integer;
    FResendCount: array of Integer;
    FNodeForPlayer: array of Integer;
    FSkipTics: Integer;
    FMakeTic: Integer;
    FGameTime: Integer;
    FFrameOn: Integer;
    FOldNetTics: Integer;
    FOldEnterTics: Integer;
    FEnterTic: Integer;
    FEnterTime: Integer;
    FFrameSkip: array[0..3] of Boolean;
    FReboundPending: Boolean;
    FReboundStore: TNetPacket;
    FSingleTics: Boolean;
    function ExpandTics(ALow: Integer): Integer;
    function Tracing: Boolean;
    procedure Trace(const AText: string);
    function BytesText(const AData: TBytes): string;
    function SlotOf(ATic: Integer): Integer;
    function CommandAt(const AStore: TBytes): TBytes;
    procedure GetPackets;
    procedure AdaptSpeed;
    function CurrentTicRate: Integer;
  public
    /// <summary>
    ///   ATransport may be nil (a game of one computer); ALog and ATrace may be nil. The nodes of the
    ///   transport are the ones of ASettings
    /// </summary>
    constructor Create(const ASettings: TNetSyncSettings; const ATransport: INetTransport;
      const ACodec: INetPacketCodec; const AClock: IClock; const ALog: ILog;
      const AGame: IGameContext; const AInput: INetLocalInput; const APlayers: INetPlayers;
      const ATrace: INetTrace);
    { INetPacketPort }
    procedure SendPacket(ANode: Integer; var APacket: TNetPacket; AControl: LongWord);
    function TryReceivePacket(out APacket: TNetPacket; out ANode: Integer): Boolean;
    { INetTicSync }
    procedure NetUpdate;
    procedure QuitNetGame;
    function NetCommand(APlayer, ATic: Integer): TBytes;
    procedure SetNetCommand(APlayer, ATic: Integer; const ACommand: TBytes);
    procedure BuildSingleTic;
    procedure EndSingleTic;
    function NetTic(ANode: Integer): Integer;
    function IsNodeInGame(ANode: Integer): Boolean;
    function GetMakeTic: Integer;
    function GetSingleTics: Boolean;
    procedure SetSingleTics(AValue: Boolean);
    { INetTicPlanner }
    function BeginRun: Integer;
    function PlanTics(ARealTics: Integer): Integer;
    function MustYield: Boolean;
    function TicsReady(ACounts: Integer): Boolean;
    procedure VerifyCanRunTic;
    function LowTic: Integer;
    function GetEnterTime: Integer;
  end;

implementation

const
  SBadSettings = 'Net settings are not valid: %d nodes, %d players, console player %d, ticdup %d.';
  STransmitToOther = 'HSendPacket(): Tried to transmit to another node';
  STooManyLocalTics = 'NetUpdate(): netbuffer.numtics > BACKUPTICS';
  SKilled = 'GetPackets(): Killed by network driver';
  SLowTicBehind = 'D_RunMultipleTicks(): lowtic < gametic';
  SGameTicAhead = 'D_RunMultipleTicks(): gametic > lowtic';
  SBadCommandLength = 'A command must be %d bytes, not %d.';
  SBadNode = 'Net node %d does not exist (%d nodes).';
  SBadPlayer = 'Net player %d does not exist (%d players).';
  SIgnoredPlayer = 'Net packet ignored: player %d is not in this game.'#13#10;

{ TNetTicSync }

constructor TNetTicSync.Create(const ASettings: TNetSyncSettings; const ATransport: INetTransport;
  const ACodec: INetPacketCodec; const AClock: IClock; const ALog: ILog; const AGame: IGameContext;
  const AInput: INetLocalInput; const APlayers: INetPlayers; const ATrace: INetTrace);
var
  LIndex: Integer;
begin
  inherited Create;
  if (ASettings.NodeCount < 1) or (ASettings.NodeCount > NET_MAX_NODES) or
    (ASettings.MaxPlayers < 1) or (ASettings.ConsolePlayer < 0) or
    (ASettings.ConsolePlayer >= ASettings.MaxPlayers) or (ASettings.TicDup < 1) or
    (ASettings.TicRate < 1) then
    raise ENetException.CreateFmt(SBadSettings, [ASettings.NodeCount, ASettings.MaxPlayers,
      ASettings.ConsolePlayer, ASettings.TicDup]);
  FSettings := ASettings;
  FTransport := ATransport;
  FCodec := ACodec;
  FClock := AClock;
  FLog := ALog;
  FGame := AGame;
  FInput := AInput;
  FPlayers := APlayers;
  FTrace := ATrace;
  SetLength(FLocalCmds, NET_BACKUPTICS);
  SetLength(FNetCmds, FSettings.MaxPlayers, NET_BACKUPTICS);
  SetLength(FNetTics, FSettings.NodeCount);
  SetLength(FNodeInGame, FSettings.NodeCount);
  SetLength(FRemoteResend, FSettings.NodeCount);
  SetLength(FResendTo, FSettings.NodeCount);
  SetLength(FResendCount, FSettings.NodeCount);
  SetLength(FNodeForPlayer, FSettings.MaxPlayers);
  for LIndex := 0 to FSettings.NodeCount - 1 do
    FNodeInGame[LIndex] := True;
end;

function TNetTicSync.CurrentTicRate: Integer;
begin
  Result := FClock.Steps(FSettings.TicRate);
end;

function TNetTicSync.Tracing: Boolean;
begin
  Result := Assigned(FTrace) and FGame.IsDeveloperMode;
end;

procedure TNetTicSync.Trace(const AText: string);
begin
  if Tracing then
    FTrace.Trace(AText);
end;

function TNetTicSync.BytesText(const AData: TBytes): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AData) do
    Result := Result + IntToStr(AData[LIndex]) + ' ';
end;

function TNetTicSync.SlotOf(ATic: Integer): Integer;
begin
  Result := ((ATic mod NET_BACKUPTICS) + NET_BACKUPTICS) mod NET_BACKUPTICS;
end;

function TNetTicSync.CommandAt(const AStore: TBytes): TBytes;
begin
  if Length(AStore) = FCodec.CommandSize then
    Result := Copy(AStore)
  else
  begin
    // a tic nobody made yet: all zeroes, as the zeroed memory of the old buffers
    SetLength(Result, FCodec.CommandSize);
    FillChar(Result[0], Length(Result), 0);
  end;
end;

function TNetTicSync.ExpandTics(ALow: Integer): Integer;
var
  LDelta: Integer;
begin
  LDelta := ALow - (FMakeTic and $FF);
  if (LDelta >= -64) and (LDelta <= 64) then
    Result := (FMakeTic and not $FF) + ALow
  else if LDelta > 64 then
    Result := (FMakeTic and not $FF) - NET_TIC_WRAP + ALow
  else
    Result := (FMakeTic and not $FF) + NET_TIC_WRAP + ALow;
end;

procedure TNetTicSync.SendPacket(ANode: Integer; var APacket: TNetPacket; AControl: LongWord);
var
  LData: TBytes;
  LRealRetrans: Integer;
begin
  LData := FCodec.Encode(APacket, AControl);
  if ANode = 0 then
  begin
    FReboundStore := APacket;
    FReboundPending := True;
    Exit;
  end;
  if FGame.IsDemoPlayback then
    Exit;
  if not FGame.IsNetGame then
    raise ENetException.Create(STransmitToOther);
  if (ANode < 0) or (ANode >= FSettings.NodeCount) or not Assigned(FTransport) then
    raise ENetException.Create(STransmitToOther);

  if Tracing then
  begin
    if APacket.IsRetransmit then
      LRealRetrans := ExpandTics(APacket.RetransmitFrom)
    else
      LRealRetrans := -1;
    Trace(Format('send (%d(starttic) + %d(numtics), R %d(realretrans)) [%d(datalength)] %s'#13#10,
      [ExpandTics(APacket.StartTic), APacket.NumTics, LRealRetrans, Length(LData), BytesText(LData)]));
  end;
  FTransport.Send(ANode, LData);
end;

function TNetTicSync.TryReceivePacket(out APacket: TNetPacket; out ANode: Integer): Boolean;
var
  LData: TBytes;
  LRealRetrans: Integer;
begin
  Result := False;
  ANode := -1;
  if FReboundPending then
  begin
    APacket := FReboundStore;
    ANode := 0;
    FReboundPending := False;
    Exit(True);
  end;
  if not FGame.IsNetGame then
    Exit;
  if FGame.IsDemoPlayback then
    Exit;
  if not Assigned(FTransport) then
    Exit;
  if not FTransport.Receive(ANode, LData) then
  begin
    ANode := -1;
    Exit;
  end;
  if (ANode < 1) or (ANode >= FSettings.NodeCount) then
  begin
    ANode := -1;
    Exit;
  end;

  case FCodec.Decode(LData, APacket) of
    ndsBadLength:
      begin
        Trace(Format('bad packet length %d'#13#10, [Length(LData)]));
        ANode := -1;
        Exit;
      end;
    ndsBadChecksum:
      begin
        Trace('bad packet checksum'#13#10);
        ANode := -1;
        Exit;
      end;
  end;

  if Tracing then
  begin
    if APacket.IsSetup then
      Trace('setup packet'#13#10)
    else
    begin
      if APacket.IsRetransmit then
        LRealRetrans := ExpandTics(APacket.RetransmitFrom)
      else
        LRealRetrans := -1;
      Trace(Format('get %d = (%d + %d, R %d)[%d] %s'#13#10,
        [ANode, ExpandTics(APacket.StartTic), APacket.NumTics, LRealRetrans, Length(LData),
        BytesText(LData)]));
    end;
  end;
  Result := True;
end;

procedure TNetTicSync.GetPackets;
var
  LPacket: TNetPacket;
  LNetNode: Integer;
  LNetConsole: Integer;
  LRealStart: Integer;
  LRealEnd: Integer;
  LSource: Integer;
  LSize: Integer;
begin
  LSize := FCodec.CommandSize;
  while TryReceivePacket(LPacket, LNetNode) do
  begin
    if LPacket.IsSetup then
      Continue; // extra setup packet

    LNetConsole := LPacket.Player and not NET_PLAYER_DRONE;
    if LNetConsole >= FSettings.MaxPlayers then
    begin
      // the old code indexed its arrays with this byte as it came
      if Assigned(FLog) then
        FLog.DevWarning(Format(SIgnoredPlayer, [LNetConsole]));
      Continue;
    end;

    // to save bytes, only the low byte of tic numbers is sent: figure out what the rest are
    LRealStart := ExpandTics(LPacket.StartTic);
    LRealEnd := LRealStart + LPacket.NumTics;

    // check for exiting the game
    if LPacket.IsExit then
    begin
      if not FNodeInGame[LNetNode] then
        Continue;
      FNodeInGame[LNetNode] := False;
      FPlayers.PlayerLeft(LNetConsole);
      Continue;
    end;

    // check for a remote game kill
    if LPacket.IsKill then
      raise ENetException.Create(SKilled);

    FNodeForPlayer[LNetConsole] := LNetNode;

    // check for retransmit request
    if (FResendCount[LNetNode] <= 0) and LPacket.IsRetransmit then
    begin
      FResendTo[LNetNode] := ExpandTics(LPacket.RetransmitFrom);
      Trace(Format('retransmit from %d'#13#10, [FResendTo[LNetNode]]));
      FResendCount[LNetNode] := NET_RESEND_COUNT;
    end
    else
      FResendCount[LNetNode] := FResendCount[LNetNode] - 1;

    // check for out of order / duplicated packet
    if LRealEnd = FNetTics[LNetNode] then
      Continue;

    if LRealEnd < FNetTics[LNetNode] then
    begin
      Trace(Format('out of order packet (%d + %d)'#13#10, [LRealStart, LPacket.NumTics]));
      Continue;
    end;

    // check for a missed packet
    if LRealStart > FNetTics[LNetNode] then
    begin
      // stop processing until the other system resends the missed tics
      Trace(Format('missed tics from %d (%d - %d)'#13#10, [LNetNode, LRealStart, FNetTics[LNetNode]]));
      FRemoteResend[LNetNode] := True;
      Continue;
    end;

    // update command store from the packet
    FRemoteResend[LNetNode] := False;
    LSource := FNetTics[LNetNode] - LRealStart;
    while FNetTics[LNetNode] < LRealEnd do
    begin
      FNetCmds[LNetConsole][SlotOf(FNetTics[LNetNode])] := Copy(LPacket.Commands, LSource * LSize, LSize);
      FNetTics[LNetNode] := FNetTics[LNetNode] + 1;
      Inc(LSource);
    end;
  end;
end;

procedure TNetTicSync.NetUpdate;
var
  LNowTime: Integer;
  LNewTics: Integer;
  LIndex: Integer;
  LTic: Integer;
  LRealStart: Integer;
  LGameTicDiv: Integer;
  LNode: Integer;
  LPacket: TNetPacket;
  LSize: Integer;
  LCommand: TBytes;
begin
  // check time
  LNowTime := CurrentTicRate div FSettings.TicDup;
  LNewTics := LNowTime - FGameTime;
  FGameTime := LNowTime;

  if LNewTics <= 0 then // nothing new to update
  begin
    GetPackets;
    Exit;
  end;

  if FSkipTics <= LNewTics then
  begin
    LNewTics := LNewTics - FSkipTics;
    FSkipTics := 0;
  end
  else
  begin
    FSkipTics := FSkipTics - LNewTics;
    LNewTics := 0;
  end;

  // build new ticcmds for console player
  LGameTicDiv := FGame.GameTic div FSettings.TicDup;
  for LIndex := 0 to LNewTics - 1 do
  begin
    FInput.PollInput;
    if FInput.IsGameFinished then
      Exit;

    if FMakeTic - LGameTicDiv >= NET_BACKUPTICS div 2 - 1 then
      Break; // can't hold any more

    LCommand := FInput.BuildTicCmd(FMakeTic);
    if Length(LCommand) <> FCodec.CommandSize then
      raise ENetException.CreateFmt(SBadCommandLength, [FCodec.CommandSize, Length(LCommand)]);
    FLocalCmds[SlotOf(FMakeTic)] := LCommand;
    Inc(FMakeTic);
  end;

  if FSingleTics then
    Exit; // singletic update is syncronous

  // send the packet to the other nodes
  LSize := FCodec.CommandSize;
  for LNode := 0 to FSettings.NodeCount - 1 do
    if FNodeInGame[LNode] then
    begin
      LPacket := Default(TNetPacket);
      LPacket.Player := Byte(FSettings.ConsolePlayer);
      LRealStart := FResendTo[LNode];
      LPacket.StartTic := Byte(LRealStart and $FF);
      if (FMakeTic - LRealStart > NET_BACKUPTICS) or (FMakeTic - LRealStart < 0) then
        raise ENetException.Create(STooManyLocalTics);
      LPacket.NumTics := Byte(FMakeTic - LRealStart);

      FResendTo[LNode] := FMakeTic - FSettings.ExtraTics;

      SetLength(LPacket.Commands, LPacket.NumTics * LSize);
      for LTic := 0 to LPacket.NumTics - 1 do
      begin
        LCommand := CommandAt(FLocalCmds[SlotOf(LRealStart + LTic)]);
        Move(LCommand[0], LPacket.Commands[LTic * LSize], LSize);
      end;

      if FRemoteResend[LNode] then
      begin
        LPacket.RetransmitFrom := Byte(FNetTics[LNode] and $FF);
        SendPacket(LNode, LPacket, NCMD_RETRANSMIT);
      end
      else
      begin
        LPacket.RetransmitFrom := 0;
        SendPacket(LNode, LPacket, 0);
      end;
    end;

  // listen for other packets
  GetPackets;
end;

procedure TNetTicSync.QuitNetGame;
var
  LRound: Integer;
  LNode: Integer;
  LPacket: TNetPacket;
begin
  if not FGame.IsNetGame or FGame.IsDemoPlayback then
    Exit;

  // send a bunch of packets for security
  for LRound := 0 to 3 do
  begin
    for LNode := 1 to FSettings.NodeCount - 1 do
      if FNodeInGame[LNode] then
      begin
        LPacket := Default(TNetPacket);
        LPacket.Player := Byte(FSettings.ConsolePlayer);
        LPacket.NumTics := 0;
        SendPacket(LNode, LPacket, NCMD_EXIT);
      end;
    FClock.Wait(1);
  end;
end;

function TNetTicSync.NetCommand(APlayer, ATic: Integer): TBytes;
begin
  if (APlayer < 0) or (APlayer >= FSettings.MaxPlayers) then
    raise ENetException.CreateFmt(SBadPlayer, [APlayer, FSettings.MaxPlayers]);
  Result := CommandAt(FNetCmds[APlayer][SlotOf(ATic)]);
end;

procedure TNetTicSync.SetNetCommand(APlayer, ATic: Integer; const ACommand: TBytes);
begin
  if (APlayer < 0) or (APlayer >= FSettings.MaxPlayers) then
    raise ENetException.CreateFmt(SBadPlayer, [APlayer, FSettings.MaxPlayers]);
  if Length(ACommand) <> FCodec.CommandSize then
    raise ENetException.CreateFmt(SBadCommandLength, [FCodec.CommandSize, Length(ACommand)]);
  FNetCmds[APlayer][SlotOf(ATic)] := Copy(ACommand);
end;

procedure TNetTicSync.BuildSingleTic;
var
  LCommand: TBytes;
begin
  FInput.PollInput;
  LCommand := FInput.BuildTicCmd(FMakeTic);
  SetNetCommand(FSettings.ConsolePlayer, FMakeTic, LCommand);
end;

procedure TNetTicSync.EndSingleTic;
begin
  Inc(FMakeTic);
end;

function TNetTicSync.NetTic(ANode: Integer): Integer;
begin
  if (ANode < 0) or (ANode >= FSettings.NodeCount) then
    raise ENetException.CreateFmt(SBadNode, [ANode, FSettings.NodeCount]);
  Result := FNetTics[ANode];
end;

function TNetTicSync.IsNodeInGame(ANode: Integer): Boolean;
begin
  if (ANode < 0) or (ANode >= FSettings.NodeCount) then
    raise ENetException.CreateFmt(SBadNode, [ANode, FSettings.NodeCount]);
  Result := FNodeInGame[ANode];
end;

function TNetTicSync.GetMakeTic: Integer;
begin
  Result := FMakeTic;
end;

function TNetTicSync.GetSingleTics: Boolean;
begin
  Result := FSingleTics;
end;

procedure TNetTicSync.SetSingleTics(AValue: Boolean);
begin
  FSingleTics := AValue;
end;

function TNetTicSync.BeginRun: Integer;
begin
  FEnterTime := CurrentTicRate;
  FEnterTic := FEnterTime div FSettings.TicDup;
  Result := FEnterTic - FOldEnterTics;
  FOldEnterTics := FEnterTic;
end;

function TNetTicSync.LowTic: Integer;
var
  LNode: Integer;
begin
  Result := MaxInt;
  for LNode := 0 to FSettings.NodeCount - 1 do
    if FNodeInGame[LNode] and (FNetTics[LNode] < Result) then
      Result := FNetTics[LNode];
end;

procedure TNetTicSync.AdaptSpeed;
var
  LFirst: Integer;
  LNode: Integer;
begin
  // ideally nettics[0] should be 1 - 3 tics above lowtic: if we are consistantly slower, speed up time
  LFirst := 0;
  while (LFirst < FSettings.MaxPlayers) and not FPlayers.IsPlayerInGame(LFirst) do
    Inc(LFirst);
  if (LFirst >= FSettings.MaxPlayers) or (FSettings.ConsolePlayer = LFirst) then
    Exit; // the key player does not adapt
  LNode := FNodeForPlayer[LFirst];
  if FNetTics[0] <= FNetTics[LNode] then
    Dec(FGameTime);
  FFrameSkip[FFrameOn and 3] := FOldNetTics > FNetTics[LNode];
  FOldNetTics := FNetTics[0];
  if FFrameSkip[0] and FFrameSkip[1] and FFrameSkip[2] and FFrameSkip[3] then
    FSkipTics := 1;
end;

function TNetTicSync.PlanTics(ARealTics: Integer): Integer;
var
  LAvailable: Integer;
begin
  LAvailable := LowTic - FGame.GameTic div FSettings.TicDup;

  // decide how many tics to run
  if ARealTics < LAvailable - 1 then
    Result := ARealTics + 1
  else if ARealTics < LAvailable then
    Result := ARealTics
  else
    Result := LAvailable;
  if Result < 1 then
    Result := 1;

  Inc(FFrameOn);

  if not FGame.IsDemoPlayback then
    AdaptSpeed;
end;

function TNetTicSync.MustYield: Boolean;
begin
  // we insist while demo playback or recording
  Result := not FGame.IsDemoPlayback and not FGame.IsDemoRecording and
    (CurrentTicRate div FSettings.TicDup - FEnterTic >= NET_YIELD_TICS);
end;

function TNetTicSync.TicsReady(ACounts: Integer): Boolean;
var
  LLowTic: Integer;
begin
  LLowTic := LowTic;
  if LLowTic < FGame.GameTic div FSettings.TicDup then
    raise ENetException.Create(SLowTicBehind);
  Result := LLowTic >= FGame.GameTic div FSettings.TicDup + ACounts;
end;

procedure TNetTicSync.VerifyCanRunTic;
begin
  if FGame.GameTic div FSettings.TicDup > LowTic then
    raise ENetException.Create(SGameTicAhead);
end;

function TNetTicSync.GetEnterTime: Integer;
begin
  Result := FEnterTime;
end;

end.
