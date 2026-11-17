{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - qagame and cgame of        }
{  OpenArena 0.8.8 together on the server in memory (TQ3Server): the server     }
{  starts the map, a client connects, enters the world, sends commands and      }
{  user commands as packets (TQ3ClientPacketWriter) and gets the snapshots      }
{  through the parser of NetQ3 into the state that cgame reads. The messages    }
{  go from one to the other as they are (the netchan is in NetworkLoop). The    }
{  golden (Tests\Data\Q3Host\reach-loop.golden.txt) has how far it goes.        }
{  Ignored if the OpenArena folder is not there                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.LocalLoop;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostLoop')]
  [Category('OpenArena')]
  TTestQ3LocalLoop = class
  public
    [Test]
    procedure QagameECgameInsiemeDovrebberoArrivareAlPuntoDelGolden;
    [Test]
    procedure UnClientDovrebbeRiceverIlNuovoGamestateDopoUnaNuovaMappa;
    [Test]
    procedure UnClientDovrebbeRestareInGiocoDopoUnMapRestart;
    [Test]
    procedure UnClientDroppatoDovrebbeRiceverIlComandoDisconnect;
    [Test]
    procedure UnClientDovrebbeEntrareNelMondoSoloConIlPrimoComandoDopoIlGamestate;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.TypInfo, DelphiDoom.Qvm.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.ServerSnapshots, DelphiDoom.Tests.Q3Host.LoopRig, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Qvm.Support;

const
  FRAMES = 10;

// the run of the golden: connect, a "say", ten frames
procedure RunLoop(const AFiles: IGameFileSystem; const AGame: string; const ALines: TStrings);
var
  LSession: TQ3LoopSession;
  LResult: string;
  LIndex: Integer;
begin
  LSession := TQ3LoopSession.Create(AFiles, False);
  try
    LResult := 'finished';
    try
      LSession.Connect('oa_dm1');
      // the client is in the world after its first frame: a command before that is ignored by the game
      LSession.Frame;
      LSession.ClientCommand('say "hello"');
      for LIndex := 2 to FRAMES do
        LSession.Frame;
    except
      on E: EQ3UnhandledSyscallException do
        LResult := 'stop=' + E.Message;
      on E: EQ3ModuleErrorException do
        LResult := 'error=' + Trim(E.Message);
      on E: Exception do
        LResult := 'exception=' + E.ClassName + ': ' + Trim(E.Message);
    end;
    ALines.Add(Format('%s/loop %s | server_calls=%d cgame_calls=%d snapshots=%d draws=%d scenes=%d phase=%s chat=%s'
      + ' clients=%d', [AGame, LResult, LSession.ServerSide.GameCalls, LSession.Client.CgameCalls,
      LSession.Client.Parser.SnapshotCount, LSession.Client.Draws, LSession.Client.Scenes,
      GetEnumName(TypeInfo(TQ3ServerClientPhase), Ord(LSession.Server.ClientPhase[LSession.Slot])),
      BoolToStr(LSession.ClientSawCommand('chat'), True), LSession.Server.ConnectedCount]));
  finally
    LSession.Free;
  end;
end;

procedure TTestQ3LocalLoop.QagameECgameInsiemeDovrebberoArrivareAlPuntoDelGolden;
var
  LFolder, LGame, LOut: string;
  LFiles: IGameFileSystem;
  LActual, LGolden: TStringList;
begin
  LFolder := OpenArenaFolder;
  LActual := TStringList.Create;
  try
    for LGame in ['baseoa', 'missionpack'] do
    begin
      LFiles := StartFileSystem(LFolder, LGame);
      RunLoop(LFiles, LGame, LActual);
      LFiles.Shutdown;
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_LOOP_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(StringReplace(Trim(LActual.Text), sLineBreak, ' | ', [rfReplaceAll]));
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach-loop.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach-loop.golden.txt'));
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      finally
        LGolden.Free;
      end;
    end;
  finally
    LActual.Free;
  end;
end;

procedure TTestQ3LocalLoop.UnClientDovrebbeRiceverIlNuovoGamestateDopoUnaNuovaMappa;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
  LOldId, LIndex: Integer;
  LStage: string;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, False);
  try
    try
      LStage := 'connect';
      LSession.Connect('oa_dm1');
      for LIndex := 1 to 3 do
        LSession.Frame;
      Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
      LOldId := LSession.Server.ServerId;
      // SV_Map_f: the bots go, the human client waits for its gamestate
      LStage := 'map';
      Assert.IsTrue(LSession.Server.Map('oa_dm1'));
      Assert.AreNotEqual(LOldId, LSession.Server.ServerId);
      Assert.AreEqual(Ord(TQ3ServerClientPhase.Connected), Ord(LSession.Server.ClientPhase[LSession.Slot]));
      LStage := 'resync';
      LSession.Resync;
      Assert.AreEqual(Ord(TQ3ServerClientPhase.Primed), Ord(LSession.Server.ClientPhase[LSession.Slot]));
      LStage := 'frames';
      for LIndex := 1 to 3 do
        LSession.Frame;
      Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
    except
      on E: EAssertionFailed do
        raise;
      on E: Exception do
        raise Exception.Create(LStage + '/' + LSession.Stage + '/' + LSession.Client.Stage + ': ' + E.ClassName + ' ' + E.Message);
    end;
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

procedure TTestQ3LocalLoop.UnClientDovrebbeRestareInGiocoDopoUnMapRestart;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
  LIndex: Integer;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, False);
  try
    LSession.Connect('oa_dm1');
    for LIndex := 1 to 3 do
      LSession.Frame;
    // SV_MapRestart_f 0: the clients are connected and begun again, and they are told
    LSession.Server.MapRestart(0);
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
    for LIndex := 1 to 3 do
      LSession.Frame;
    Assert.IsTrue(LSession.ClientSawCommand('map_restart'), 'map_restart');
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

procedure TTestQ3LocalLoop.UnClientDroppatoDovrebbeRiceverIlComandoDisconnect;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
  LIndex: Integer;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, False);
  try
    LSession.Connect('oa_dm1');
    for LIndex := 1 to 3 do
      LSession.Frame;
    LSession.Server.DropClient(LSession.Slot, 'Kicked');
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Zombie), Ord(LSession.Server.ClientPhase[LSession.Slot]));
    LSession.Frame;
    Assert.IsTrue(LSession.ClientSawCommand('disconnect'), 'disconnect');
    // a zombie is a free slot again after sv_zombietime (2 seconds) of silence
    for LIndex := 1 to 50 do
      LSession.Server.Frame(50);
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Free), Ord(LSession.Server.ClientPhase[LSession.Slot]));
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

procedure TTestQ3LocalLoop.UnClientDovrebbeEntrareNelMondoSoloConIlPrimoComandoDopoIlGamestate;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, False);
  try
    LSession.Connect('oa_dm1');
    // the gamestate came with the first packet: CS_PRIMED, not in the world
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Primed), Ord(LSession.Server.ClientPhase[LSession.Slot]));
    LSession.Frame;
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3LocalLoop);

end.
