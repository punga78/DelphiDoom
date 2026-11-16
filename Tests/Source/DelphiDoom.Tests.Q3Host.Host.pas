{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the dispatcher and the     }
{  system calls all modules share, on a real machine                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Host;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Intf;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3SyscallHost = class
  strict private
    FConsole: IQ3HostConsole;
    FHost: IQ3SyscallHost;
    FText: Integer;
    FMachine: IQvmMachine;
    FTime: IQ3HostTime;
    function Call(ANumber, AFirst, ASecond, AThird: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure UnNumeroCheIlModuloNonHaDovrebbeDareLaTrappaDelC;
    [Test]
    procedure UnaChiamataSenzaGestoreDovrebbeDireIlNome;
    [Test]
    procedure IlSostitutoDovrebbeRispondereALeChiamateSenzaGestore;
    [Test]
    procedure UnGestoreRegistratoDueVolteDovrebbeUsareLUltimo;
    [Test]
    procedure LaStampaDovrebbeDareIlTestoDelModulo;
    [Test]
    procedure LErroreDovrebbeEssereUnaEccezioneConIlTesto;
    [Test]
    procedure IMillisecondiDovrebberoVenireDallOrologio;
    [Test]
    procedure MemsetEMemcpyDovrebberoScrivereNellaMemoriaDelProgramma;
    [Test]
    procedure StrncpyDovrebbeCopiareEPadareConZeri;
    [Test]
    procedure UnIntervalloFuoriDallaMemoriaDovrebbeEssereUnErrore;
    [Test]
    procedure UnaStringaNullaDovrebbeEssereUnErrore;
    [Test]
    procedure LaFabbricaDovrebbeRegistrareLeDodiciChiamateComuniPerModulo;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Factory, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.SyscallHost, DelphiDoom.Tests.Qvm.Programs,
  DelphiDoom.Tests.Qvm.Support, DelphiDoom.Tests.Q3Host.Support;

procedure TTestQ3SyscallHost.Setup;
begin
  FConsole := TQ3RecordingConsole.Create(nil);
  FTime := TQ3FixedTime.Create(1234);
  FHost := TQ3HostFactory.CreateHost(TQ3Module.Game, FConsole, FTime);
  FMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(FText), FHost);
end;

function TTestQ3SyscallHost.Call(ANumber, AFirst, ASecond, AThird: Integer): Integer;
begin
  Result := FMachine.Call(0, [ANumber, AFirst, ASecond, AThird]);
end;

procedure TTestQ3SyscallHost.UnNumeroCheIlModuloNonHaDovrebbeDareLaTrappaDelC;
begin
  try
    Call(9999, 0, 0, 0);
    Assert.Fail('doveva sollevare');
  except
    on E: EQ3UnknownSyscallException do
      Assert.AreEqual('Bad game system trap: 9999', E.Message);
  end;
end;

procedure TTestQ3SyscallHost.UnaChiamataSenzaGestoreDovrebbeDireIlNome;
begin
  try
    Call(G_FS_READ, 0, 0, 0);
    Assert.Fail('doveva sollevare');
  except
    on E: EQ3UnhandledSyscallException do
      Assert.AreEqual('System trap G_FS_READ (' + IntToStr(G_FS_READ) + ') of game has no handler', E.Message);
  end;
end;

procedure TTestQ3SyscallHost.IlSostitutoDovrebbeRispondereALeChiamateSenzaGestore;
begin
  FHost.Fallback := TQvmNullHost.Create;
  Assert.AreEqual(0, Call(G_FS_READ, 0, 0, 0));
  Assert.IsNotNull(FHost.Fallback);
end;

procedure TTestQ3SyscallHost.UnGestoreRegistratoDueVolteDovrebbeUsareLUltimo;
begin
  FHost.Registry.Register(G_ARGC,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := 1;
    end);
  FHost.Registry.Register(G_ARGC,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := 2;
    end);
  Assert.AreEqual(2, Call(G_ARGC, 0, 0, 0));
  Assert.IsTrue(FHost.Registry.IsRegistered(G_ARGC));
  Assert.IsFalse(FHost.Registry.IsRegistered(G_ARGV));
end;

procedure TTestQ3SyscallHost.LaStampaDovrebbeDareIlTestoDelModulo;
begin
  Assert.AreEqual(0, Call(G_PRINT, FText, 0, 0));
  Assert.AreEqual('hello \ world' + #10, (FConsole as TQ3RecordingConsole).Texts[0]);
end;

procedure TTestQ3SyscallHost.LErroreDovrebbeEssereUnaEccezioneConIlTesto;
begin
  try
    Call(G_ERROR, FText, 0, 0);
    Assert.Fail('doveva sollevare');
  except
    on E: EQ3ModuleErrorException do
      Assert.AreEqual('hello \ world' + #10, E.Message);
  end;
  // the machine is usable after the error
  Assert.AreEqual(1234, Call(G_MILLISECONDS, 0, 0, 0));
end;

procedure TTestQ3SyscallHost.IMillisecondiDovrebberoVenireDallOrologio;
begin
  Assert.AreEqual(1234, Call(G_MILLISECONDS, 0, 0, 0));
  (FTime as TQ3FixedTime).Value := -5;
  Assert.AreEqual(-5, Call(G_MILLISECONDS, 0, 0, 0));
end;

procedure TTestQ3SyscallHost.MemsetEMemcpyDovrebberoScrivereNellaMemoriaDelProgramma;
begin
  Assert.AreEqual(0, Call(TRAP_MEMSET, 1000, $1AB, 6));
  Assert.AreEqual($AB, Integer(FMachine.Memory.ReadByte(1000)));
  Assert.AreEqual($AB, Integer(FMachine.Memory.ReadByte(1005)));
  Assert.AreEqual(0, Integer(FMachine.Memory.ReadByte(1006)));
  Assert.AreEqual(0, Call(TRAP_MEMCPY, 2000, 1000, 6));
  Assert.AreEqual($AB, Integer(FMachine.Memory.ReadByte(2005)));
  // a count of 0 does nothing
  Assert.AreEqual(0, Call(TRAP_MEMSET, 1000, 0, 0));
  Assert.AreEqual($AB, Integer(FMachine.Memory.ReadByte(1000)));
end;

procedure TTestQ3SyscallHost.StrncpyDovrebbeCopiareEPadareConZeri;
var
  LIndex: Integer;
begin
  FMachine.Memory.Fill(3000, $55, 20);
  // "hello \ world\n" is 14 bytes: copied with its zero, then zeroes up to the count of 20
  Assert.AreEqual(3000, Call(TRAP_STRNCPY, 3000, FText, 20));
  for LIndex := 0 to 13 do
    Assert.AreEqual(Integer(Ord(('hello \ world' + #10)[LIndex + 1])), Integer(FMachine.Memory.ReadByte(3000 + LIndex)));
  for LIndex := 14 to 19 do
    Assert.AreEqual(0, Integer(FMachine.Memory.ReadByte(3000 + LIndex)));
  // a count shorter than the text: no zero is added
  FMachine.Memory.Fill(3100, $55, 8);
  Call(TRAP_STRNCPY, 3100, FText, 5);
  Assert.AreEqual(Integer(Ord('o')), Integer(FMachine.Memory.ReadByte(3104)));
  Assert.AreEqual($55, Integer(FMachine.Memory.ReadByte(3105)));
end;

procedure TTestQ3SyscallHost.UnIntervalloFuoriDallaMemoriaDovrebbeEssereUnErrore;
begin
  // the C masks the address and then trusts the count: here a range outside the image raises
  Assert.WillRaise(
    procedure
    begin
      Call(TRAP_MEMSET, FMachine.Memory.Size - 4, 1, 100);
    end, EQvmExecutionException);
  Assert.WillRaise(
    procedure
    begin
      Call(TRAP_MEMCPY, 0, 100, -1);
    end, EQvmExecutionException);
end;

procedure TTestQ3SyscallHost.UnaStringaNullaDovrebbeEssereUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      Call(G_PRINT, 0, 0, 0);
    end, EQ3HostException);
end;

procedure TTestQ3SyscallHost.LaFabbricaDovrebbeRegistrareLeDodiciChiamateComuniPerModulo;
var
  LModule: TQ3Module;
  LHost: IQ3SyscallHost;
begin
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    LHost := TQ3HostFactory.CreateHost(LModule, FConsole, FTime);
    Assert.AreEqual(12, LHost.Registry.RegisteredCount);
  end;
end;

end.
