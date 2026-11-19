{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III program - the executable without the     }
{  process around it, on a folder with no game (nothing of OpenArena needed)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Quake3.Application;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, DelphiDoom.Clock.ManualClock, DelphiDoom.Quake3.Clock.Intf;

type
  [TestFixture]
  [Category('Quake3')]
  TTestQ3Application = class
  strict private
    FFolder: string;
    FOutput: TStringBuilder;
    function Run(const AArguments: array of string): Integer;
    function Text: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaRigaSbagliataDovrebbeDareIlCodiceDiUso;
    [Test]
    procedure HelpDovrebbeStampareLUsoEDareZero;
    [Test]
    procedure UnaCartellaCheNonCEDovrebbeDareIlCodiceDiFallimento;
    [Test]
    procedure IFrameDelLimiteDovrebberoGirareSenzaMappa;
    [Test]
    procedure QuitDovrebbeFermareESenzaMappaDareZero;
    [Test]
    procedure EchoDovrebbeScrivereSullaConsole;
    [Test]
    procedure StatusSenzaMappaDovrebbeDirloEDarZero;
    [Test]
    procedure UnaMappaCheNonCEDovrebbeDareIlCodiceDiFallimento;
    [Test]
    procedure IComandiSetDovrebberoEssereEseguitiPrimaDelServer;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Clock.Intf, DelphiDoom.Quake3.Clock.Adapter, DelphiDoom.Quake3.Application,
  DelphiDoom.Quake3.Types, DelphiDoom.Quake3.Factory, DelphiDoom.Quake3.CommandLine,
  DelphiDoom.Quake3.DedicatedServer, DelphiDoom.Quake3.DummyClient;

{ TTestQ3Application }

procedure TTestQ3Application.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'ddq3app_' + TGUID.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(FFolder);
  FOutput := TStringBuilder.Create;
end;

procedure TTestQ3Application.TearDown;
begin
  FOutput.Free;
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

function TTestQ3Application.Run(const AArguments: array of string): Integer;
var
  LClock: IClock;
begin
  LClock := TManualClock.Create;
  Result := TQ3Application.Run(AArguments, TQ3ClockAdapter.Create(LClock),
    procedure(AText: string)
    begin
      FOutput.Append(AText);
    end);
end;

function TTestQ3Application.Text: string;
begin
  Result := FOutput.ToString;
end;

procedure TTestQ3Application.UnaRigaSbagliataDovrebbeDareIlCodiceDiUso;
begin
  Assert.AreEqual(Q3_EXIT_USAGE, Run(['oa_dm1']));
  Assert.IsTrue(Text.Contains('Unknown argument'), Text);
  Assert.IsTrue(Text.Contains('-frames'), 'anche l''uso');
end;

procedure TTestQ3Application.HelpDovrebbeStampareLUsoEDareZero;
begin
  Assert.AreEqual(Q3_EXIT_OK, Run(['-help']));
  Assert.IsTrue(Text.Contains('Quake3Server'), Text);
end;

procedure TTestQ3Application.UnaCartellaCheNonCEDovrebbeDareIlCodiceDiFallimento;
begin
  Assert.AreEqual(Q3_EXIT_FAILURE, Run(['-fs_basepath', TPath.Combine(FFolder, 'non_c_e'), '-frames', '1']));
  Assert.IsTrue(Text.Contains('does not exist'), Text);
end;

procedure TTestQ3Application.IFrameDelLimiteDovrebberoGirareSenzaMappa;
var
  LServer: TQ3DedicatedServer;
  LOptions: TQ3ProgramOptions;
  LError: string;
  LClock: IClock;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', FFolder, '-frames', '12'], LOptions, LError), LError);
  LClock := TManualClock.Create;
  LServer := TQuake3Factory.CreateDedicatedServer(LOptions, TQ3ClockAdapter.Create(LClock),
    procedure(AText: string)
    begin
      FOutput.Append(AText);
    end);
  try
    Assert.AreEqual(Q3_EXIT_OK, LServer.Run);
    Assert.AreEqual(12, LServer.Parts.Loop.Frames);
    Assert.IsFalse(LServer.Parts.Server.IsRunning, 'nessuna mappa: il server non gira');
    // il client senza schermo aspetta una mappa
    Assert.AreEqual(Ord(TQ3DummyClientPhase.Waiting), Ord(LServer.Parts.Dummy.Phase));
  finally
    LServer.Free;
  end;
end;

procedure TTestQ3Application.QuitDovrebbeFermareESenzaMappaDareZero;
begin
  // senza -frames il ciclo girerebbe per sempre: "quit" lo ferma
  Assert.AreEqual(Q3_EXIT_OK, Run(['-fs_basepath', FFolder, '+quit']));
end;

procedure TTestQ3Application.EchoDovrebbeScrivereSullaConsole;
begin
  Assert.AreEqual(Q3_EXIT_OK, Run(['-fs_basepath', FFolder, '+echo', 'ciao', 'mondo', '-frames', '2']));
  Assert.IsTrue(Text.Contains('ciao mondo'), Text);
end;

procedure TTestQ3Application.StatusSenzaMappaDovrebbeDirloEDarZero;
begin
  Assert.AreEqual(Q3_EXIT_OK, Run(['-fs_basepath', FFolder, '+status', '-frames', '2']));
  Assert.IsTrue(Text.Contains('Server is not running.'), Text);
end;

procedure TTestQ3Application.UnaMappaCheNonCEDovrebbeDareIlCodiceDiFallimento;
begin
  Assert.AreEqual(Q3_EXIT_FAILURE, Run(['-fs_basepath', FFolder, '+map', 'oa_non_c_e', '-frames', '3']));
  Assert.IsTrue(Text.Contains('Can''t find map maps/oa_non_c_e.bsp'), Text);
end;

procedure TTestQ3Application.IComandiSetDovrebberoEssereEseguitiPrimaDelServer;
var
  LServer: TQ3DedicatedServer;
  LOptions: TQ3ProgramOptions;
  LError: string;
  LClock: IClock;
begin
  // g_gametype e sv_maxclients sono LATCH: se il set arrivasse dopo il server resterebbero "in attesa del riavvio"
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', FFolder, '+set', 'g_gametype', '1', '+set', 'sv_maxclients',
    '12', '-frames', '1'], LOptions, LError), LError);
  LClock := TManualClock.Create;
  LServer := TQuake3Factory.CreateDedicatedServer(LOptions, TQ3ClockAdapter.Create(LClock),
    procedure(AText: string)
    begin
      FOutput.Append(AText);
    end);
  try
    Assert.AreEqual(1, LServer.Parts.Console.CVars.VariableIntegerValue('g_gametype'));
    Assert.AreEqual(12, LServer.Parts.Console.CVars.VariableIntegerValue('sv_maxclients'));
    Assert.IsFalse(Text.Contains('will be changed upon restarting'), Text);
  finally
    LServer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Application);

end.
