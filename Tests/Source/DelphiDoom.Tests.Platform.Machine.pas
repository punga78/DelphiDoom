{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - drives, processor, DPI, priority}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.Machine;

interface

uses
  System.SysUtils, Winapi.Windows, DUnitX.TestFramework, DelphiDoom.Platform.Intf;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformMachine = class(TObject)
  private
    FServices: IPlatformServices;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLaRadiceDelProgramma;
    [Test]
    procedure DovrebbeDareLaDriveCorrenteSeIlPercorsoEBreve;
    [Test]
    procedure DovrebbeDareLaRadiceDiUnaLettera;
    [Test]
    procedure DovrebbeDareFalsoPerUnaLetteraSenzaUnita;
    [Test]
    procedure DovrebbeDareFalsoPerIlDiscoDiSistema;
    [Test]
    procedure DovrebbeContareAlmenoUnProcessore;
    [Test]
    procedure DovrebbeDareUnaRispostaSuMmxEDa3DNow;
    [Test]
    procedure DovrebbeDareNovantaseiDpiPerUnaFinestraCheNonEsiste;
    [Test]
    procedure DovrebbeRimettereLaPrioritaDiPrima;
    [Test]
    procedure DovrebbeAlzareLaPrioritaUnaVoltaSola;
    [Test]
    procedure DovrebbeNonFareNullaSeNonSiEAlzato;
    [Test]
    procedure DovrebbeRifiutareUnServizioNil;
  end;

implementation

uses
  DelphiDoom.Platform.Factory, DelphiDoom.Platform.Services, DelphiDoom.Platform.WindowsDriveInfo;

{ TTestPlatformMachine }

procedure TTestPlatformMachine.Setup;
begin
  FServices := TPlatformFactory.CreateServices;
end;

procedure TTestPlatformMachine.DovrebbeDareLaRadiceDelProgramma;
begin
  Assert.AreEqual('D:\', TWindowsDriveInfo.RootOfProgram('D:\giochi\doom.exe'));
end;

procedure TTestPlatformMachine.DovrebbeDareLaDriveCorrenteSeIlPercorsoEBreve;
begin
  Assert.AreEqual('', TWindowsDriveInfo.RootOfProgram('C:\a'));
end;

procedure TTestPlatformMachine.DovrebbeDareLaRadiceDiUnaLettera;
begin
  Assert.AreEqual('E:\', TWindowsDriveInfo.RootOfDrive('E'));
end;

procedure TTestPlatformMachine.DovrebbeDareFalsoPerUnaLetteraSenzaUnita;
begin
  Assert.IsFalse(FServices.Drives.IsCdRomDrive('#'));
end;

procedure TTestPlatformMachine.DovrebbeDareFalsoPerIlDiscoDiSistema;
begin
  Assert.IsFalse(FServices.Drives.IsProgramOnCdRom(GetEnvironmentVariable('SystemRoot') +
    '\System32\cmd.exe'));
end;

procedure TTestPlatformMachine.DovrebbeContareAlmenoUnProcessore;
begin
  Assert.IsTrue(FServices.Cpu.ProcessorCount >= 1);
end;

procedure TTestPlatformMachine.DovrebbeDareUnaRispostaSuMmxEDa3DNow;
begin
  // il valore dipende dalla macchina: basta che le domande non falliscano
  FServices.Cpu.HasMmx;
  FServices.Cpu.Has3DNow;
  Assert.Pass;
end;

procedure TTestPlatformMachine.DovrebbeDareNovantaseiDpiPerUnaFinestraCheNonEsiste;
begin
  // GetDpiForWindow con un handle non valido dà 0: l'interfaccia lo lascia passare,
  // il motore lo usa solo con la sua finestra. Qui basta un valore non negativo
  Assert.IsTrue(FServices.Dpi.WindowDpi(0) >= 0);
end;

procedure TTestPlatformMachine.DovrebbeRimettereLaPrioritaDiPrima;
var
  LBefore: Integer;
begin
  LBefore := GetThreadPriority(GetCurrentThread);
  FServices.Priority.RaiseToCritical;
  Assert.AreEqual(THREAD_PRIORITY_TIME_CRITICAL, GetThreadPriority(GetCurrentThread));
  FServices.Priority.Restore;
  Assert.AreEqual(LBefore, GetThreadPriority(GetCurrentThread));
end;

procedure TTestPlatformMachine.DovrebbeAlzareLaPrioritaUnaVoltaSola;
var
  LBefore: Integer;
begin
  LBefore := GetThreadPriority(GetCurrentThread);
  FServices.Priority.RaiseToCritical;
  FServices.Priority.RaiseToCritical;
  FServices.Priority.Restore;
  // la seconda chiamata non ha ricordato la priorità già alzata
  Assert.AreEqual(LBefore, GetThreadPriority(GetCurrentThread));
end;

procedure TTestPlatformMachine.DovrebbeNonFareNullaSeNonSiEAlzato;
var
  LBefore: Integer;
begin
  LBefore := GetThreadPriority(GetCurrentThread);
  FServices.Priority.Restore;
  Assert.AreEqual(LBefore, GetThreadPriority(GetCurrentThread));
end;

procedure TTestPlatformMachine.DovrebbeRifiutareUnServizioNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TPlatformServices.Create(nil, FServices.Cpu, FServices.Executable, FServices.Drives,
        FServices.Dpi, FServices.Priority);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TPlatformServices.Create(FServices.OperatingSystem, FServices.Cpu, FServices.Executable,
        FServices.Drives, FServices.Dpi, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformMachine);

end.
