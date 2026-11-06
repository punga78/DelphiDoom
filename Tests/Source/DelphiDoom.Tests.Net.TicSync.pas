{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the synchronisation of the commands  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.TicSync;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.GameState.Intf, DelphiDoom.Net.Types, DelphiDoom.Net.Intf, DelphiDoom.Tests.Net.Fakes;

type
  /// <summary>One computer of a game, with a fake of everything it depends on</summary>
  TNodeRig = class
  public
    Clock: TFakeClock;
    ClockIntf: IClock;
    Game: TFakeGameContext;
    GameIntf: IGameContext;
    Input: TFakeLocalInput;
    InputIntf: INetLocalInput;
    Players: TFakePlayers;
    PlayersIntf: INetPlayers;
    Trace: TFakeTrace;
    TraceIntf: INetTrace;
    Codec: INetPacketCodec;
    Sync: INetTicSync;
    Planner: INetTicPlanner;
    Port: INetPacketPort;
    /// <summary>On the fake network (ANet nil: a game of one computer without transport)</summary>
    constructor Create(ANet: TFakeNetwork; AMachine: Integer; const APeers: TArray<Integer>;
      AConsolePlayer, ATicDup, AExtraTics: Integer);
    /// <summary>On any transport</summary>
    constructor CreateOn(const ATransport: INetTransport; ANodeCount, AConsolePlayer, ATicDup,
      AExtraTics: Integer);
  end;

  [TestFixture]
  [Category('net')]
  TTestNetTicSync = class(TObject)
  private
    FNet: TFakeNetwork;
    FA: TNodeRig;
    FB: TNodeRig;
    procedure Advance(ATics: Integer);
    procedure Pump;
    procedure Run(ATics: Integer);
    function DecodeSent(AIndex: Integer): TNetPacket;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSinglePlayerBuildsAndKeepsItsOwnCommands;
    [Test]
    procedure TestNewTicsAreLimitedByWhatTheGameHasNotRunYet;
    [Test]
    procedure TestTwoNodesExchangeTheirCommands;
    [Test]
    procedure TestThePacketOnTheWireIsTheOldPacket;
    [Test]
    procedure TestLostPacketIsRetransmitted;
    [Test]
    procedure TestPacketsOutOfOrderAreAbsorbed;
    [Test]
    procedure TestDuplicatedPacketIsIgnored;
    [Test]
    procedure TestOldPacketAfterNewOnesIsOutOfOrder;
    [Test]
    procedure TestCorruptedPacketIsDropped;
    [Test]
    procedure TestPacketOfTheWrongLengthIsDropped;
    [Test]
    procedure TestDatagramFromSomebodyElseIsLost;
    [Test]
    procedure TestPlayerOutOfTheGameIsIgnored;
    [Test]
    procedure TestLeavingNodeIsOutOfTheGame;
    [Test]
    procedure TestExitIsHandledOnce;
    [Test]
    procedure TestQuitSendsFourRoundsOfExit;
    [Test]
    procedure TestQuitDoesNothingInADemoOrOffline;
    [Test]
    procedure TestKillPacketRaises;
    [Test]
    procedure TestSetupPacketsAreIgnoredInTheGame;
    [Test]
    procedure TestSendToAnotherNodeOutsideANetGameRaises;
    [Test]
    procedure TestNothingIsSentDuringDemoPlayback;
    [Test]
    procedure TestExtraTicsRepeatTheLastTic;
    [Test]
    procedure TestTicDupDividesTime;
    [Test]
    procedure TestSingleTicsDoNotSend;
    [Test]
    procedure TestBuildSingleTicStoresTheCommand;
    [Test]
    procedure TestFinishedGameStopsNetUpdate;
    [Test]
    procedure TestNetCommandOfATicNobodyMadeIsZero;
    [Test]
    procedure TestSetNetCommandChecksTheLength;
    [Test]
    procedure TestRequestToResendTooFarBackRaises;
    [Test]
    procedure TestPacketsAreTraced;
    [Test]
    procedure TestSettingsAreValidated;
    [Test]
    procedure TestRetransmitRequestIsMadeWhileTicsAreMissing;
  end;

implementation

uses
  DelphiDoom.Net.Factory;

const
  COMMAND_SIZE = 14;

{ TNodeRig }

constructor TNodeRig.Create(ANet: TFakeNetwork; AMachine: Integer; const APeers: TArray<Integer>;
  AConsolePlayer, ATicDup, AExtraTics: Integer);
var
  LTransport: INetTransport;
begin
  if Assigned(ANet) then
    LTransport := TFakeNetTransport.Create(ANet, AMachine, APeers)
  else
    LTransport := nil;
  CreateOn(LTransport, Length(APeers) + 1, AConsolePlayer, ATicDup, AExtraTics);
end;

constructor TNodeRig.CreateOn(const ATransport: INetTransport; ANodeCount, AConsolePlayer, ATicDup,
  AExtraTics: Integer);
var
  LSettings: TNetSyncSettings;
begin
  inherited Create;
  Clock := TFakeClock.Create;
  ClockIntf := Clock;
  Game := TFakeGameContext.Create;
  GameIntf := Game;
  Input := TFakeLocalInput.Create(COMMAND_SIZE, AConsolePlayer);
  InputIntf := Input;
  Players := TFakePlayers.Create;
  PlayersIntf := Players;
  Trace := TFakeTrace.Create;
  TraceIntf := Trace;
  Codec := TNetFactory.CreateCodec(COMMAND_SIZE);
  LSettings := TNetSyncSettings.Make(ANodeCount, 4, AConsolePlayer);
  LSettings.TicDup := ATicDup;
  LSettings.ExtraTics := AExtraTics;
  Sync := TNetFactory.CreateTicSync(LSettings, ATransport, Codec, ClockIntf, nil, GameIntf, InputIntf,
    PlayersIntf, TraceIntf);
  Planner := Sync as INetTicPlanner;
  Port := Sync as INetPacketPort;
end;

{ TTestNetTicSync }

procedure TTestNetTicSync.Setup;
begin
  FNet := TFakeNetwork.Create;
  FA := TNodeRig.Create(FNet, 0, [1], 0, 1, 0);
  FB := TNodeRig.Create(FNet, 1, [0], 1, 1, 0);
end;

procedure TTestNetTicSync.TearDown;
begin
  FB.Free;
  FA.Free;
  FNet.Free;
end;

procedure TTestNetTicSync.Advance(ATics: Integer);
begin
  FA.Clock.Tics := FA.Clock.Tics + ATics;
  FB.Clock.Tics := FB.Clock.Tics + ATics;
end;

procedure TTestNetTicSync.Pump;
begin
  FA.Sync.NetUpdate;
  FB.Sync.NetUpdate;
  FA.Sync.NetUpdate;
  FB.Sync.NetUpdate;
end;

procedure TTestNetTicSync.Run(ATics: Integer);
var
  LIndex: Integer;
begin
  // the game runs as fast as the net: the window of local tics keeps moving
  for LIndex := 1 to ATics do
  begin
    Advance(1);
    FA.Game.CurrentGameTic := FA.Clock.Tics - 1;
    FB.Game.CurrentGameTic := FB.Clock.Tics - 1;
    Pump;
  end;
end;

function TTestNetTicSync.DecodeSent(AIndex: Integer): TNetPacket;
begin
  Assert.AreEqual(ndsOk, FA.Codec.Decode(FNet.Sent[AIndex].Data, Result), 'pacchetto ' + IntToStr(AIndex));
end;

procedure TTestNetTicSync.TestSinglePlayerBuildsAndKeepsItsOwnCommands;
var
  LRig: TNodeRig;
begin
  LRig := TNodeRig.Create(nil, 0, [], 0, 1, 0);
  try
    LRig.Game.NetGame := False;
    LRig.Clock.Tics := 3;
    LRig.Sync.NetUpdate;
    Assert.AreEqual(3, LRig.Sync.MakeTic);
    Assert.AreEqual(3, LRig.Sync.NetTic(0));
    Assert.AreEqual(3, LRig.Planner.LowTic);
    Assert.AreEqual(Byte(1), LRig.Sync.NetCommand(0, 1)[1], 'il tic 1 e il suo comando');
    Assert.AreEqual(Byte(2), LRig.Sync.NetCommand(0, 2)[1]);
    Assert.AreEqual(3, LRig.Input.BuiltTics.Count);
    Assert.AreEqual(0, LRig.Input.BuiltTics[0]);
    Assert.AreEqual(2, LRig.Input.BuiltTics[2]);
    Assert.AreEqual(3, LRig.Input.PollCalls);
  finally
    LRig.Free;
  end;
end;

procedure TTestNetTicSync.TestNewTicsAreLimitedByWhatTheGameHasNotRunYet;
begin
  FA.Game.CurrentGameTic := 0;
  FA.Clock.Tics := 20;
  FA.Sync.NetUpdate;
  // BACKUPTICS div 2 - 1
  Assert.AreEqual(5, FA.Sync.MakeTic);
  FA.Game.CurrentGameTic := 4;
  FA.Clock.Tics := 30;
  FA.Sync.NetUpdate;
  Assert.AreEqual(9, FA.Sync.MakeTic);
end;

procedure TTestNetTicSync.TestTwoNodesExchangeTheirCommands;
var
  LFromB: TBytes;
  LFromA: TBytes;
  LOnA: TBytes;
  LOnB: TBytes;
begin
  Run(3);
  Assert.AreEqual(3, FA.Sync.MakeTic);
  Assert.AreEqual(3, FA.Sync.NetTic(0), 'i comandi di A, passati dal rimbalzo');
  Assert.AreEqual(3, FA.Sync.NetTic(1), 'i comandi di B');
  Assert.AreEqual(3, FB.Sync.NetTic(0));
  Assert.AreEqual(3, FB.Sync.NetTic(1));
  Assert.AreEqual(3, FA.Planner.LowTic);
  // every computer holds the commands of both players
  LFromB := FA.Sync.NetCommand(1, 2);
  Assert.AreEqual(Byte(1), LFromB[0], 'il comando e del giocatore 1');
  Assert.AreEqual(Byte(2), LFromB[1], 'e del tic 2');
  LFromA := FB.Sync.NetCommand(0, 1);
  Assert.AreEqual(Byte(0), LFromA[0]);
  Assert.AreEqual(Byte(1), LFromA[1]);
  LOnA := FA.Sync.NetCommand(1, 0);
  LOnB := FB.Sync.NetCommand(1, 0);
  Assert.IsTrue(CompareMem(@LOnA[0], @LOnB[0], COMMAND_SIZE), 'lo stesso comando su entrambi');
end;

procedure TTestNetTicSync.TestThePacketOnTheWireIsTheOldPacket;
var
  LPacket: TNetPacket;
begin
  Advance(1);
  FA.Sync.NetUpdate;
  Assert.AreEqual(1, FNet.Sent.Count);
  Assert.AreEqual(0, FNet.Sent[0].FromMachine);
  Assert.AreEqual(1, FNet.Sent[0].ToMachine);
  Assert.AreEqual(12 + 14, Length(FNet.Sent[0].Data));
  LPacket := DecodeSent(0);
  Assert.AreEqual(Byte(0), LPacket.StartTic);
  Assert.AreEqual(Byte(1), LPacket.NumTics);
  Assert.AreEqual(Byte(0), LPacket.Player, 'giocatore di console');
  Assert.AreEqual(Byte(0), LPacket.RetransmitFrom);
  Assert.AreEqual(LongWord(0), LPacket.Checksum and not NCMD_CHECKSUM, 'nessun flag');
  Assert.AreEqual(Byte(0), LPacket.Commands[0]);
  Assert.AreEqual(Byte(0), LPacket.Commands[1]);
end;

procedure TTestNetTicSync.TestLostPacketIsRetransmitted;
var
  LIndex: Integer;
begin
  Run(1);
  Assert.AreEqual(1, FB.Sync.NetTic(1));
  FNet.DropNext(0, 1, 1);
  Run(1); // A's tic 1 is lost
  Assert.AreEqual(1, FB.Sync.NetTic(1), 'B non ha il tic 1');
  for LIndex := 1 to 6 do
    Run(1);
  Assert.AreEqual(FA.Sync.MakeTic, FB.Sync.NetTic(1), 'B ha recuperato tutti i tic di A');
  Assert.AreEqual(Byte(1), FB.Sync.NetCommand(0, 1)[1], 'compreso quello perso');
  Assert.AreEqual(Byte(2), FB.Sync.NetCommand(0, 2)[1]);
end;

procedure TTestNetTicSync.TestPacketsOutOfOrderAreAbsorbed;
var
  LIndex: Integer;
begin
  Run(1);
  FNet.ReorderNext(0, 1);
  Run(1); // A's tic 1 comes after tic 2
  for LIndex := 1 to 6 do
    Run(1);
  Assert.AreEqual(FA.Sync.MakeTic, FB.Sync.NetTic(1));
  for LIndex := 0 to FA.Sync.MakeTic - 1 do
    Assert.AreEqual(Byte(LIndex and $FF), FB.Sync.NetCommand(0, LIndex)[1], 'tic ' + IntToStr(LIndex));
end;

procedure TTestNetTicSync.TestDuplicatedPacketIsIgnored;
begin
  Run(1);
  FNet.DuplicateNext(0, 1);
  Run(1);
  Assert.AreEqual(2, FB.Sync.NetTic(1));
  Assert.AreEqual(Byte(1), FB.Sync.NetCommand(0, 1)[1]);
  Run(1);
  Assert.AreEqual(3, FB.Sync.NetTic(1));
end;

procedure TTestNetTicSync.TestOldPacketAfterNewOnesIsOutOfOrder;
begin
  FB.Game.Developer := True;
  Run(3);
  FNet.Inject(0, 1, FNet.Sent[0].Data);
  FB.Sync.NetUpdate;
  Assert.IsTrue(Pos('out of order packet (0 + 1)', FB.Trace.Text) > 0, FB.Trace.Text);
  Assert.AreEqual(3, FB.Sync.NetTic(1), 'nessun tic perso o ripetuto');
end;

procedure TTestNetTicSync.TestCorruptedPacketIsDropped;
begin
  FB.Game.Developer := True;
  FNet.CorruptNext(0, 1);
  Run(1);
  Assert.AreEqual(0, FB.Sync.NetTic(1));
  Assert.IsTrue(Pos('bad packet checksum', FB.Trace.Text) > 0);
  Run(6);
  Assert.AreEqual(FA.Sync.MakeTic, FB.Sync.NetTic(1), 'recuperato dalla ritrasmissione');
end;

procedure TTestNetTicSync.TestPacketOfTheWrongLengthIsDropped;
var
  LData: TBytes;
begin
  FB.Game.Developer := True;
  SetLength(LData, 20);
  FillChar(LData[0], 20, 0);
  FNet.Inject(0, 1, LData);
  FB.Sync.NetUpdate;
  Assert.IsTrue(Pos('bad packet length 20', FB.Trace.Text) > 0);
  Assert.AreEqual(0, FB.Sync.NetTic(1));
end;

procedure TTestNetTicSync.TestDatagramFromSomebodyElseIsLost;
var
  LPacket: TNetPacket;
  LData: TBytes;
begin
  LPacket := Default(TNetPacket);
  LData := FA.Codec.Encode(LPacket, 0);
  FNet.Inject(7, 1, LData);
  FB.Sync.NetUpdate;
  Assert.AreEqual(0, FB.Sync.NetTic(1));
  Assert.IsTrue(FB.Sync.IsNodeInGame(1));
end;

procedure TTestNetTicSync.TestPlayerOutOfTheGameIsIgnored;
var
  LPacket: TNetPacket;
begin
  LPacket := Default(TNetPacket);
  LPacket.Player := 9; // the old code indexed its arrays with it
  FNet.Inject(0, 1, FB.Codec.Encode(LPacket, 0));
  FB.Sync.NetUpdate;
  Assert.AreEqual(0, FB.Sync.NetTic(1));
  Assert.AreEqual(0, FB.Players.Left.Count);
end;

procedure TTestNetTicSync.TestLeavingNodeIsOutOfTheGame;
begin
  Run(2);
  FB.Sync.QuitNetGame;
  FA.Sync.NetUpdate;
  Assert.IsFalse(FA.Sync.IsNodeInGame(1));
  Assert.IsTrue(FA.Sync.IsNodeInGame(0));
  Assert.AreEqual(1, FA.Players.Left.Count);
  Assert.AreEqual(1, FA.Players.Left[0], 'il giocatore 1 e uscito');
  // the node that left does not hold back the game
  FA.Clock.Tics := FA.Clock.Tics + 1;
  FA.Sync.NetUpdate;
  Assert.AreEqual(FA.Sync.NetTic(0), FA.Planner.LowTic);
end;

procedure TTestNetTicSync.TestExitIsHandledOnce;
begin
  FB.Sync.QuitNetGame;
  FA.Sync.NetUpdate;
  Assert.AreEqual(1, FA.Players.Left.Count, 'quattro pacchetti, un solo avviso');
end;

procedure TTestNetTicSync.TestQuitSendsFourRoundsOfExit;
var
  LIndex: Integer;
  LPacket: TNetPacket;
begin
  FB.Sync.QuitNetGame;
  Assert.AreEqual(4, FNet.Sent.Count);
  Assert.AreEqual(4, FB.Clock.WaitCalls);
  for LIndex := 0 to 3 do
  begin
    LPacket := DecodeSent(LIndex);
    Assert.IsTrue(LPacket.IsExit);
    Assert.AreEqual(Byte(1), LPacket.Player);
    Assert.AreEqual(Byte(0), LPacket.NumTics);
  end;
end;

procedure TTestNetTicSync.TestQuitDoesNothingInADemoOrOffline;
begin
  FB.Game.DemoPlayback := True;
  FB.Sync.QuitNetGame;
  Assert.AreEqual(0, FNet.Sent.Count);
  FB.Game.DemoPlayback := False;
  FB.Game.NetGame := False;
  FB.Sync.QuitNetGame;
  Assert.AreEqual(0, FNet.Sent.Count);
end;

procedure TTestNetTicSync.TestKillPacketRaises;
var
  LPacket: TNetPacket;
begin
  LPacket := Default(TNetPacket);
  FNet.Inject(0, 1, FB.Codec.Encode(LPacket, NCMD_KILL));
  Assert.WillRaise(
    procedure
    begin
      FB.Sync.NetUpdate;
    end, ENetException);
end;

procedure TTestNetTicSync.TestSetupPacketsAreIgnoredInTheGame;
var
  LPacket: TNetPacket;
begin
  LPacket := Default(TNetPacket);
  LPacket.Player := 0;
  FNet.Inject(0, 1, FB.Codec.Encode(LPacket, NCMD_SETUP));
  FB.Sync.NetUpdate;
  Assert.AreEqual(0, FB.Sync.NetTic(1));
  Assert.IsTrue(FB.Sync.IsNodeInGame(1));
end;

procedure TTestNetTicSync.TestSendToAnotherNodeOutsideANetGameRaises;
var
  LPacket: TNetPacket;
begin
  FA.Game.NetGame := False;
  LPacket := Default(TNetPacket);
  Assert.WillRaise(
    procedure
    begin
      FA.Port.SendPacket(1, LPacket, 0);
    end, ENetException);
  // to itself it is fine
  FA.Port.SendPacket(0, LPacket, 0);
end;

procedure TTestNetTicSync.TestNothingIsSentDuringDemoPlayback;
var
  LPacket: TNetPacket;
  LNode: Integer;
begin
  FA.Game.DemoPlayback := True;
  LPacket := Default(TNetPacket);
  FA.Port.SendPacket(1, LPacket, 0);
  Assert.AreEqual(0, FNet.Sent.Count);
  FA.Port.SendPacket(0, LPacket, 0);
  Assert.IsTrue(FA.Port.TryReceivePacket(LPacket, LNode), 'il rimbalzo c''e sempre');
  Assert.AreEqual(0, LNode);
  Assert.IsFalse(FA.Port.TryReceivePacket(LPacket, LNode));
end;

procedure TTestNetTicSync.TestExtraTicsRepeatTheLastTic;
var
  LRig: TNodeRig;
  LNet: TFakeNetwork;
  LPacket: TNetPacket;
begin
  LNet := TFakeNetwork.Create;
  LRig := TNodeRig.Create(LNet, 0, [1], 0, 1, 1);
  try
    LRig.Clock.Tics := 1;
    LRig.Sync.NetUpdate;
    LRig.Clock.Tics := 2;
    LRig.Sync.NetUpdate;
    Assert.AreEqual(2, LNet.Sent.Count);
    Assert.AreEqual(ndsOk, LRig.Codec.Decode(LNet.Sent[1].Data, LPacket));
    Assert.AreEqual(Byte(0), LPacket.StartTic, 'ricomincia un tic prima');
    Assert.AreEqual(Byte(2), LPacket.NumTics);
  finally
    LRig.Free;
    LNet.Free;
  end;
end;

procedure TTestNetTicSync.TestTicDupDividesTime;
var
  LRig: TNodeRig;
begin
  LRig := TNodeRig.Create(nil, 0, [], 0, 2, 0);
  try
    LRig.Game.NetGame := False;
    LRig.Clock.Tics := 4;
    LRig.Sync.NetUpdate;
    Assert.AreEqual(2, LRig.Sync.MakeTic, 'ogni comando vale due tic');
    LRig.Clock.Tics := 5;
    LRig.Sync.NetUpdate;
    Assert.AreEqual(2, LRig.Sync.MakeTic);
    LRig.Clock.Tics := 6;
    LRig.Sync.NetUpdate;
    Assert.AreEqual(3, LRig.Sync.MakeTic);
  finally
    LRig.Free;
  end;
end;

procedure TTestNetTicSync.TestSingleTicsDoNotSend;
begin
  FA.Sync.SingleTics := True;
  Advance(2);
  FA.Sync.NetUpdate;
  Assert.AreEqual(2, FA.Sync.MakeTic, 'i comandi si costruiscono');
  Assert.AreEqual(0, FNet.Sent.Count, 'ma non si spedisce');
  Assert.AreEqual(0, FA.Sync.NetTic(0), 'e non passano dal rimbalzo');
end;

procedure TTestNetTicSync.TestBuildSingleTicStoresTheCommand;
begin
  FA.Sync.BuildSingleTic;
  Assert.AreEqual(0, FA.Sync.MakeTic, 'maketic cambia alla fine del tic');
  Assert.AreEqual(Byte(0), FA.Sync.NetCommand(0, 0)[1]);
  FA.Sync.EndSingleTic;
  Assert.AreEqual(1, FA.Sync.MakeTic);
  FA.Sync.BuildSingleTic;
  Assert.AreEqual(Byte(1), FA.Sync.NetCommand(0, 1)[1]);
  Assert.AreEqual(2, FA.Input.PollCalls);
end;

procedure TTestNetTicSync.TestFinishedGameStopsNetUpdate;
begin
  FA.Input.Finished := True;
  Advance(3);
  FA.Sync.NetUpdate;
  Assert.AreEqual(0, FA.Sync.MakeTic);
  Assert.AreEqual(0, FNet.Sent.Count);
end;

procedure TTestNetTicSync.TestNetCommandOfATicNobodyMadeIsZero;
var
  LCommand: TBytes;
  LIndex: Integer;
begin
  LCommand := FA.Sync.NetCommand(2, 7);
  Assert.AreEqual(COMMAND_SIZE, Length(LCommand));
  for LIndex := 0 to High(LCommand) do
    Assert.AreEqual(Byte(0), LCommand[LIndex]);
  Assert.WillRaise(
    procedure
    begin
      FA.Sync.NetCommand(4, 0);
    end, ENetException);
end;

procedure TTestNetTicSync.TestSetNetCommandChecksTheLength;
var
  LCommand: TBytes;
begin
  SetLength(LCommand, COMMAND_SIZE);
  LCommand[3] := 99;
  FA.Sync.SetNetCommand(2, 13, LCommand);
  Assert.AreEqual(Byte(99), FA.Sync.NetCommand(2, 1)[3], 'il tic 13 e lo slot 1');
  SetLength(LCommand, COMMAND_SIZE + 1);
  Assert.WillRaise(
    procedure
    begin
      FA.Sync.SetNetCommand(2, 0, LCommand);
    end, ENetException);
end;

procedure TTestNetTicSync.TestRequestToResendTooFarBackRaises;
var
  LIndex: Integer;
  LRequest: TNetPacket;
begin
  for LIndex := 1 to 20 do
  begin
    Advance(1);
    FA.Game.CurrentGameTic := LIndex;
    FA.Sync.NetUpdate;
  end;
  Assert.AreEqual(20, FA.Sync.MakeTic);
  LRequest := Default(TNetPacket);
  LRequest.Player := 1;
  LRequest.RetransmitFrom := 0;
  FNet.Inject(1, 0, FA.Codec.Encode(LRequest, NCMD_RETRANSMIT));
  FA.Sync.NetUpdate; // takes the request
  Advance(1);
  Assert.WillRaise(
    procedure
    begin
      FA.Sync.NetUpdate;
    end, ENetException, 'sono piu di BACKUPTICS tic');
end;

procedure TTestNetTicSync.TestPacketsAreTraced;
begin
  FA.Game.Developer := True;
  FB.Game.Developer := True;
  Run(1);
  Assert.IsTrue(Pos('send (0(starttic) + 1(numtics), R -1(realretrans)) [26(datalength)] ', FA.Trace.Text) = 1,
    FA.Trace.Text);
  Assert.IsTrue(Pos('get 1 = (0 + 1, R -1)[26] ', FA.Trace.Text) > 0, FA.Trace.Text);
  Assert.IsTrue(Pos('get 1 = (0 + 1, R -1)[26] ', FB.Trace.Text) > 0, 'anche B riceve dal suo nodo 1');
end;

procedure TTestNetTicSync.TestSettingsAreValidated;
var
  LSettings: TNetSyncSettings;
begin
  LSettings := TNetSyncSettings.Make(2, 4, 4);
  Assert.WillRaise(
    procedure
    begin
      TNetFactory.CreateTicSync(LSettings, nil, FA.Codec, FA.ClockIntf, nil, FA.GameIntf, FA.InputIntf,
        FA.PlayersIntf, nil);
    end, ENetException, 'giocatore di console fuori dai giocatori');
  LSettings := TNetSyncSettings.Make(9, 4, 0);
  Assert.WillRaise(
    procedure
    begin
      TNetFactory.CreateTicSync(LSettings, nil, FA.Codec, FA.ClockIntf, nil, FA.GameIntf, FA.InputIntf,
        FA.PlayersIntf, nil);
    end, ENetException, 'troppi nodi');
  LSettings := TNetSyncSettings.Make(2, 4, 0);
  LSettings.TicDup := 0;
  Assert.WillRaise(
    procedure
    begin
      TNetFactory.CreateTicSync(LSettings, nil, FA.Codec, FA.ClockIntf, nil, FA.GameIntf, FA.InputIntf,
        FA.PlayersIntf, nil);
    end, ENetException, 'ticdup zero');
end;

procedure TTestNetTicSync.TestRetransmitRequestIsMadeWhileTicsAreMissing;
var
  LPacket: TNetPacket;
begin
  Run(1);
  FNet.DropNext(0, 1, 1);
  Run(1); // lost
  Run(1); // B sees tic 2 but misses tic 1
  // the next packet of B asks A to send again from tic 1
  FB.Clock.Tics := FB.Clock.Tics + 1;
  FB.Sync.NetUpdate;
  LPacket := DecodeSent(FNet.Sent.Count - 1);
  Assert.AreEqual(1, FNet.Sent[FNet.Sent.Count - 1].FromMachine);
  Assert.IsTrue(LPacket.IsRetransmit, 'B chiede la ritrasmissione');
  Assert.AreEqual(Byte(1), LPacket.RetransmitFrom, 'a partire dal tic 1');
end;

end.
