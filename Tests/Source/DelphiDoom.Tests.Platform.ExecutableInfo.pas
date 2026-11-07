{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - facts about an executable       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.ExecutableInfo;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Platform.Intf;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformExecutableInfo = class(TObject)
  private
    FInfo: IExecutableInfo;
    FKernel: string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLaDimensioneDellImmagineDelProgramma;
    [Test]
    procedure DovrebbeDareZeroPerUnFileCheNonEUnEseguibile;
    [Test]
    procedure DovrebbeDareZeroPerUnFileCheNonEsiste;
    [Test]
    procedure DovrebbeLeggereLaVersioneDiUnaDllDiSistema;
    [Test]
    procedure DovrebbeLeggereLaVersioneAncheConUnaLinguaDiversaDa040904E4;
    [Test]
    procedure DovrebbeDareVuotoPerUnFileSenzaVersione;
    [Test]
    procedure DovrebbeDareVuotoPerUnFileCheNonEsiste;
  end;

implementation

uses
  DelphiDoom.Platform.Factory;

{ TTestPlatformExecutableInfo }

procedure TTestPlatformExecutableInfo.Setup;
begin
  FInfo := TPlatformFactory.CreateServices.Executable;
  FKernel := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot')) +
    'System32\kernel32.dll';
end;

procedure TTestPlatformExecutableInfo.DovrebbeDareLaDimensioneDellImmagineDelProgramma;
begin
  Assert.IsTrue(FInfo.ImageSize(ParamStr(0)) > 0);
end;

procedure TTestPlatformExecutableInfo.DovrebbeDareZeroPerUnFileCheNonEUnEseguibile;
begin
  // questo sorgente non e un eseguibile
  Assert.AreEqual(0, Integer(FInfo.ImageSize(ParamStr(0) + '.noexe')));
  Assert.AreEqual(0, Integer(FInfo.ImageSize(GetEnvironmentVariable('SystemRoot') +
    '\System32\drivers\etc\hosts')));
end;

procedure TTestPlatformExecutableInfo.DovrebbeDareZeroPerUnFileCheNonEsiste;
begin
  Assert.AreEqual(0, Integer(FInfo.ImageSize('C:\non\esiste\mai.exe')));
end;

procedure TTestPlatformExecutableInfo.DovrebbeLeggereLaVersioneDiUnaDllDiSistema;
begin
  if not FileExists(FKernel) then
    Assert.Pass('kernel32.dll non c''e');
  Assert.IsTrue(Pos('.', FInfo.FileVersion(FKernel)) > 0);
end;

procedure TTestPlatformExecutableInfo.DovrebbeLeggereLaVersioneAncheConUnaLinguaDiversaDa040904E4;
begin
  // regressione: il vecchio codice cercava solo la lingua 040904E4 e per kernel32.dll
  // (040904B0) dava sempre una stringa vuota
  if not FileExists(FKernel) then
    Assert.Pass('kernel32.dll non c''e');
  Assert.AreNotEqual('', FInfo.FileVersion(FKernel));
end;

procedure TTestPlatformExecutableInfo.DovrebbeDareVuotoPerUnFileSenzaVersione;
begin
  Assert.AreEqual('', FInfo.FileVersion(GetEnvironmentVariable('SystemRoot') +
    '\System32\drivers\etc\hosts'));
end;

procedure TTestPlatformExecutableInfo.DovrebbeDareVuotoPerUnFileCheNonEsiste;
begin
  Assert.AreEqual('', FInfo.FileVersion('C:\non\esiste\mai.exe'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformExecutableInfo);

end.
