{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the server and the client  }
{  of OpenArena 0.8.8 in the same process talk through the netchan of NetQ3     }
{  and the transport of NetTransport (a wire in memory: no socket is opened):   }
{  getchallenge and connect out of band, the gamestate in fragments, the        }
{  snapshots, the commands and the user commands of the client encoded with     }
{  the xor of the challenge. The golden                                         }
{  (Tests\Data\Q3Host\reach-net.golden.txt) has how far it goes. Ignored if     }
{  the OpenArena folder is not there                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.NetworkLoop;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostLoop')]
  [Category('OpenArena')]
  TTestQ3NetworkLoop = class
  public
    [Test]
    procedure IlServerEIlClientSuUnaRetePerLoStessoProcessoDovrebberoArrivareAlPuntoDelGolden;
    [Test]
    procedure IlClientDovrebbeConnettersiConChallengeEConnect;
    [Test]
    procedure UnClientConProtocolloSbagliatoDovrebbeEssereRifiutato;
    [Test]
    procedure UnClientDroppatoDovrebbeRiceverIlDisconnectSullaRete;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.TypInfo, DelphiDoom.Qvm.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.ServerSnapshots, DelphiDoom.Q3Host.ClientNetwork,
  DelphiDoom.Tests.Q3Host.LoopRig, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Qvm.Support;

const
  FRAMES = 10;

procedure RunLoop(const AFiles: IGameFileSystem; const AGame: string; const ALines: TStrings);
var
  LSession: TQ3LoopSession;
  LResult: string;
  LIndex: Integer;
begin
  LSession := TQ3LoopSession.Create(AFiles, True);
  try
    LResult := 'finished';
    try
      LSession.Connect('oa_dm1');
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
    ALines.Add(Format('%s/net %s | server_calls=%d cgame_calls=%d snapshots=%d draws=%d scenes=%d phase=%s chat=%s'
      + ' datagrams=%d fragments=%d', [AGame, LResult, LSession.ServerSide.GameCalls, LSession.Client.CgameCalls,
      LSession.Client.Parser.SnapshotCount, LSession.Client.Draws, LSession.Client.Scenes,
      GetEnumName(TypeInfo(TQ3ServerClientPhase), Ord(LSession.Server.ClientPhase[LSession.Slot])),
      BoolToStr(LSession.ClientSawCommand('chat'), True), LSession.DatagramsFromServer,
      LSession.FragmentsFromServer]));
  finally
    LSession.Free;
  end;
end;

procedure TTestQ3NetworkLoop.IlServerEIlClientSuUnaRetePerLoStessoProcessoDovrebberoArrivareAlPuntoDelGolden;
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
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_REACH_NET_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    TQvmScenarioRunner.Report(StringReplace(Trim(LActual.Text), sLineBreak, ' | ', [rfReplaceAll]));
    if TFile.Exists(TTestFiles.DataFile('Q3Host', 'reach-net.golden.txt')) then
    begin
      LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'reach-net.golden.txt'));
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

procedure TTestQ3NetworkLoop.IlClientDovrebbeConnettersiConChallengeEConnect;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, True);
  try
    LSession.Connect('oa_dm1');
    Assert.AreEqual(Ord(TQ3ClientConnection.Connected), Ord(LSession.ClientNetwork.Connection));
    // the challenge is the one the server gave, and the user info on the server is the one the client sent
    Assert.AreNotEqual(0, LSession.ClientNetwork.Challenge);
    Assert.AreEqual(LSession.ClientNetwork.Challenge, LSession.Server.ClientChallenge(LSession.Slot));
    Assert.AreEqual(1234, LSession.Server.ClientQPort(LSession.Slot));
    // the gamestate is longer than a datagram: it came in fragments
    Assert.IsTrue(LSession.FragmentsFromServer >= 2, 'fragmenti: ' + IntToStr(LSession.FragmentsFromServer));
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Primed), Ord(LSession.Server.ClientPhase[LSession.Slot]));
    LSession.Frame;
    Assert.AreEqual(Ord(TQ3ServerClientPhase.Active), Ord(LSession.Server.ClientPhase[LSession.Slot]));
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

procedure TTestQ3NetworkLoop.UnClientConProtocolloSbagliatoDovrebbeEssereRifiutato;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
  LPrints: TArray<AnsiString>;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, True);
  try
    LPrints := LSession.ConnectOnNetwork('oa_dm1', 67);
    Assert.AreEqual<Integer>(1, Length(LPrints));
    Assert.IsTrue(Pos('Server uses protocol version 68', string(LPrints[0])) > 0, string(LPrints[0]));
    Assert.AreEqual(Ord(TQ3ClientConnection.Challenging), Ord(LSession.ClientNetwork.Connection));
    Assert.AreEqual(0, LSession.Server.ConnectedCount);
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

procedure TTestQ3NetworkLoop.UnClientDroppatoDovrebbeRiceverIlDisconnectSullaRete;
var
  LFiles: IGameFileSystem;
  LSession: TQ3LoopSession;
  LIndex: Integer;
begin
  LFiles := StartFileSystem(OpenArenaFolder, 'baseoa');
  LSession := TQ3LoopSession.Create(LFiles, True);
  try
    LSession.Connect('oa_dm1');
    for LIndex := 1 to 3 do
      LSession.Frame;
    LSession.Server.DropClient(LSession.Slot, 'Kicked');
    LSession.Frame;
    Assert.IsTrue(LSession.ClientSawCommand('disconnect'), 'disconnect');
  finally
    LSession.Free;
    LFiles.Shutdown;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3NetworkLoop);

end.
