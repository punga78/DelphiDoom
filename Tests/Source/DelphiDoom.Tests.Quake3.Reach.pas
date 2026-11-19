{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III program - the server in this process     }
{  for 300 frames on oa_dm1 with two bots and a client without a screen, on    }
{  the files of OpenArena 0.8.8 (ignored if they are not there)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Quake3.Reach;

interface

uses
  DUnitX.TestFramework, System.SysUtils;

type
  [TestFixture]
  [Category('Quake3')]
  [Category('OpenArena')]
  TTestQ3Reach = class
  strict private
    FOutput: TStringBuilder;
    function OpenArenaFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlServerDovrebbeFare300FrameSuOaDm1ConDueBotEUnClient;
    [Test]
    procedure SenzaClientIBotDovrebberoGirareDaSoli;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Clock.Intf, DelphiDoom.Clock.ManualClock, DelphiDoom.Quake3.Clock.Adapter,
  DelphiDoom.Quake3.Types, DelphiDoom.Quake3.CommandLine, DelphiDoom.Quake3.Factory,
  DelphiDoom.Quake3.DedicatedServer, DelphiDoom.Quake3.DummyClient, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Skip;

{ TTestQ3Reach }

procedure TTestQ3Reach.Setup;
begin
  FOutput := TStringBuilder.Create;
end;

procedure TTestQ3Reach.TearDown;
begin
  FOutput.Free;
end;

function TTestQ3Reach.OpenArenaFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8');
  if (Result = '') or not TFile.Exists(TPath.Combine(Result, 'baseoa\pak0.pk3')) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)');
end;

procedure TTestQ3Reach.IlServerDovrebbeFare300FrameSuOaDm1ConDueBotEUnClient;
var
  LServer: TQ3DedicatedServer;
  LOptions: TQ3ProgramOptions;
  LError: string;
  LClock: IClock;
  LPlayers, LBots: Integer;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', OpenArenaFolder, '+set', 'g_gametype', '0', '+map', 'oa_dm1',
    '+addbot', 'Sarge', '3', '+addbot', 'Major', '3', '-frames', '300'], LOptions, LError), LError);
  LClock := TManualClock.Create;
  LServer := TQuake3Factory.CreateDedicatedServer(LOptions, TQ3ClockAdapter.Create(LClock),
    procedure(AText: string)
    begin
      FOutput.Append(AText);
    end);
  try
    Assert.AreEqual(Q3_EXIT_OK, LServer.Run, FOutput.ToString);
    Assert.AreEqual(300, LServer.Parts.Loop.Frames);
    Assert.IsTrue(LServer.Parts.Server.IsRunning);
    Assert.AreEqual('oa_dm1', string(LServer.Parts.Server.MapName));
    LServer.Parts.Commands.CountClients(LPlayers, LBots);
    Assert.AreEqual(1, LPlayers, 'il client senza schermo');
    Assert.AreEqual(2, LBots, 'i due bot');
    Assert.AreEqual(Ord(TQ3DummyClientPhase.Playing), Ord(LServer.Parts.Dummy.Phase));
    Assert.IsTrue(LServer.Parts.Dummy.Snapshots > 200, 'snapshot arrivati: ' + IntToStr(LServer.Parts.Dummy.Snapshots));
    Assert.IsTrue(LServer.Parts.Dummy.Frames > 250, 'comandi mandati: ' + IntToStr(LServer.Parts.Dummy.Frames));
    Assert.IsTrue(FOutput.ToString.Contains('AAS initialized.'), 'la botlib ha caricato la mappa');
    Assert.IsTrue(FOutput.ToString.Contains('Major entered the game'), 'i bot entrano in partita');
    Assert.IsTrue(FOutput.ToString.Contains('Dummy entered the game'), 'il client entra in partita');
    Assert.IsFalse(FOutput.ToString.Contains('Com_Error'), FOutput.ToString);
    Assert.IsFalse(FOutput.ToString.Contains('Fatal'), FOutput.ToString);
  finally
    LServer.Free;
  end;
end;

procedure TTestQ3Reach.SenzaClientIBotDovrebberoGirareDaSoli;
var
  LServer: TQ3DedicatedServer;
  LOptions: TQ3ProgramOptions;
  LError: string;
  LClock: IClock;
  LPlayers, LBots: Integer;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', OpenArenaFolder, '+map', 'oa_dm1', '+addbot', 'Sarge', '3',
    '-frames', '60', '-noclient'], LOptions, LError), LError);
  LClock := TManualClock.Create;
  LServer := TQuake3Factory.CreateDedicatedServer(LOptions, TQ3ClockAdapter.Create(LClock),
    procedure(AText: string)
    begin
      FOutput.Append(AText);
    end);
  try
    Assert.AreEqual(Q3_EXIT_OK, LServer.Run, FOutput.ToString);
    Assert.IsFalse(Assigned(LServer.Parts.Dummy), 'nessun client');
    LServer.Parts.Commands.CountClients(LPlayers, LBots);
    Assert.AreEqual(0, LPlayers);
    Assert.AreEqual(1, LBots);
  finally
    LServer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Reach);

end.
