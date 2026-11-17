{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the classes one by one,      }
{  on the fake engine                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.Classes;

interface

uses
  DUnitX.TestFramework, DelphiDoom.D3Host.Common, DelphiDoom.Tests.D3Host.World;

type
  [TestFixture]
  [Category('D3Host')]
  TTestD3HostClasses = class
  strict private
    FWorld: TD3FakeWorld;
    FHost: TD3CommonHost;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlTestoDiUnMessaggioDovrebbeEssereTagliatoA4095Caratteri;
    [Test]
    procedure UnMessaggioDovrebbeAndareAllaConsoleConISuoiColoriESenzaColoriAlSistema;
    [Test]
    procedure UnaRedirezioneDiDimensioneZeroNonDovrebbeFareNiente;
    [Test]
    procedure UnaRigaDiComandoConPiuDiTrentaduePiuDovrebbeSollevare;
    [Test]
    procedure IlTempoDelCicloDegliEventiDovrebbeCominciareDaZeroAllInit;
    [Test]
    procedure UnErroreDiTipoDropDovrebbeSollevareEdAzzerareLoStato;
    [Test]
    procedure SenzaRendererUnErroreDovrebbeEssereFatale;
    [Test]
    procedure IlComandoDiRiavvioVideoDovrebbeEssereMessoSoloConLoSchermoIntero;
    [Test]
    procedure UnEventoDiConsoleDovrebbeFinireNelBufferDeiComandiConIlFineRiga;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Factory;

procedure TTestD3HostClasses.Setup;
begin
  FWorld := TD3FakeWorld.Create;
  FHost := TD3HostFactory.CreateCommon(FWorld.Services);
end;

procedure TTestD3HostClasses.TearDown;
begin
  FHost.Free;
  FWorld.Free;
end;

procedure TTestD3HostClasses.IlTestoDiUnMessaggioDovrebbeEssereTagliatoA4095Caratteri;
begin
  Assert.AreEqual(4095, Length(TD3MessageText.Limit(AnsiString(StringOfChar('a', 5000)))));
  Assert.AreEqual(10, Length(TD3MessageText.Limit('0123456789')));
end;

procedure TTestD3HostClasses.UnMessaggioDovrebbeAndareAllaConsoleConISuoiColoriESenzaColoriAlSistema;
begin
  FHost.Printer.Printf('^1red^7 text'#10);
  Assert.AreEqual('CON ^1red^7 text\n', FWorld.Trace[0]);
  Assert.AreEqual('SYS red text\n', FWorld.Trace[1]);
end;

procedure TTestD3HostClasses.UnaRedirezioneDiDimensioneZeroNonDovrebbeFareNiente;
begin
  FHost.Printer.BeginRedirect(0,
    procedure(const AText: AnsiString)
    begin
      Assert.Fail('la redirezione non doveva partire');
    end);
  FHost.Printer.Printf('x');
  Assert.AreEqual('CON x', FWorld.Trace[0]);
end;

procedure TTestD3HostClasses.UnaRigaDiComandoConPiuDiTrentaduePiuDovrebbeSollevare;
var
  LArguments: TArray<AnsiString>;
  LIndex: Integer;
begin
  SetLength(LArguments, 33);
  for LIndex := 0 to 32 do
    LArguments[LIndex] := '+map';
  Assert.WillRaise(
    procedure
    begin
      FHost.CommandLine.ParseCommandLine(LArguments);
    end, ED3HostException);
end;

procedure TTestD3HostClasses.IlTempoDelCicloDegliEventiDovrebbeCominciareDaZeroAllInit;
begin
  FWorld.Time := 1000;
  FHost.EventLoop.Init;
  FWorld.Time := 1750;
  Assert.AreEqual(750, FHost.EventLoop.Milliseconds);
end;

procedure TTestD3HostClasses.UnErroreDiTipoDropDovrebbeSollevareEdAzzerareLoStato;
begin
  FWorld.OpenGLRunning := True;
  Assert.WillRaise(
    procedure
    begin
      FHost.Errors.Error('boom');
    end, ED3HostException);
  Assert.AreEqual(0, FHost.State.ErrorEntered);
  Assert.AreEqual(1, FHost.Diagnostics.ErrorCount);
end;

procedure TTestD3HostClasses.SenzaRendererUnErroreDovrebbeEssereFatale;
begin
  Assert.WillRaise(
    procedure
    begin
      FHost.Errors.Error('boom');
    end, ETestExit);
  Assert.AreEqual(ERP_FATAL, FHost.State.ErrorEntered);
end;

procedure TTestD3HostClasses.IlComandoDiRiavvioVideoDovrebbeEssereMessoSoloConLoSchermoIntero;
begin
  Assert.WillRaise(
    procedure
    begin
      FHost.Errors.FatalError('one');
    end, ETestExit);
  Assert.AreEqual(-1, FWorld.Trace.IndexOf('BUFTEXT now vid_restart partial windowed\n'));
end;

procedure TTestD3HostClasses.UnEventoDiConsoleDovrebbeFinireNelBufferDeiComandiConIlFineRiga;
var
  LEvent: TD3SysEvent;
begin
  LEvent := TD3SysEvent.Make(SE_CONSOLE, 0, 0);
  SetLength(LEvent.EvData, 5);
  Move(AnsiString('quit'#0)[1], LEvent.EvData[0], 5);
  FWorld.SystemQueue.Add(LEvent);
  FHost.EventLoop.RunEventLoop(False);
  Assert.AreEqual(1, FWorld.Trace.IndexOf('BUFTEXT append quit'));
  Assert.AreEqual(2, FWorld.Trace.IndexOf('BUFTEXT append \n'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3HostClasses);

end.
