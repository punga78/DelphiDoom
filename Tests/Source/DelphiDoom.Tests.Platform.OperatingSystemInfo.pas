{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the operating system            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.OperatingSystemInfo;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Platform.Intf, DelphiDoom.Platform.Types,
  DelphiDoom.Tests.Platform.Fakes;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformOperatingSystemInfo = class(TObject)
  private
    function Describe(AFamily: TOperatingSystemFamily; AMajor, AMinor, ABuild: Cardinal;
      const AServicePack: string = ''): TOperatingSystemDescription;
  public
    [Test]
    [TestCase('95', '0,4,0,950,95')]
    [TestCase('98', '0,4,10,1998,98')]
    [TestCase('Me', '0,4,90,3000,Me')]
    [TestCase('NT', '1,4,0,1381,NT')]
    [TestCase('2000', '1,5,0,2195,2000')]
    [TestCase('XP', '1,5,1,2600,XP')]
    [TestCase('Server 2003', '1,5,2,3790,Server 2003')]
    [TestCase('Vista', '1,6,0,6002,Vista')]
    [TestCase('7', '1,6,1,7601,7')]
    [TestCase('8', '1,6,2,9200,8')]
    [TestCase('8.1', '1,6,3,9600,8.1')]
    [TestCase('10', '1,10,0,19045,10')]
    [TestCase('11', '1,10,0,22621,11')]
    procedure DovrebbeDareIlNomeDelSistema(AFamily, AMajor, AMinor, ABuild: Integer;
      const AName: string);
    [Test]
    procedure DovrebbeDareNomeVuotoPerUnaVersioneNonNota;
    [Test]
    procedure DovrebbeDareNomeVuotoPerUnaMinoreNonNotaDi5;
    [Test]
    procedure DovrebbeChiamareSconosciutoUnSistemaCheNonSiConosce;
    [Test]
    procedure DovrebbeDareIlTipoDelSistema;
    [Test]
    procedure DovrebbeDirePiuRecenteDiVistaSoloDaNT6InSu;
    [Test]
    procedure DovrebbeTenereModernoUnSistemaSconosciuto;
    [Test]
    procedure DovrebbeScrivereLaRigaDiAvvio;
    [Test]
    procedure DovrebbeTagliareLaBuildDiWindows9x;
    [Test]
    procedure DovrebbeNonTagliareLaBuildDiNT;
    [Test]
    procedure DovrebbeAggiungereLaRigaDelServicePack;
    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNil;
    [Test]
    procedure DovrebbeDareUnaVersioneAlSistemaVero;
  end;

implementation

uses
  DelphiDoom.Platform.Factory;

{ TTestPlatformOperatingSystemInfo }

function TTestPlatformOperatingSystemInfo.Describe(AFamily: TOperatingSystemFamily; AMajor, AMinor,
  ABuild: Cardinal; const AServicePack: string): TOperatingSystemDescription;
var
  LSource: TFakeVersionSource;
begin
  LSource := TFakeVersionSource.Create;
  LSource.Version.Family := AFamily;
  LSource.Version.MajorVersion := AMajor;
  LSource.Version.MinorVersion := AMinor;
  LSource.Version.BuildNumber := ABuild;
  LSource.Version.ServicePack := AServicePack;
  Result := TPlatformFactory.CreateOperatingSystemInfo(LSource).Describe;
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDareIlNomeDelSistema(AFamily, AMajor, AMinor,
  ABuild: Integer; const AName: string);
begin
  Assert.AreEqual(AName, Describe(TOperatingSystemFamily(AFamily + 1), AMajor, AMinor, ABuild).Name);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDareNomeVuotoPerUnaVersioneNonNota;
begin
  Assert.AreEqual('', Describe(osfWindowsNT, 7, 0, 1).Name);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDareNomeVuotoPerUnaMinoreNonNotaDi5;
begin
  Assert.AreEqual('', Describe(osfWindowsNT, 5, 3, 1).Name);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeChiamareSconosciutoUnSistemaCheNonSiConosce;
begin
  Assert.AreEqual('Unknown OS', Describe(osfUnknown, 1, 1, 1).Name);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDareIlTipoDelSistema;
begin
  Assert.AreEqual(Ord(oskWindows95), Ord(Describe(osfWindows9x, 4, 0, 950).Kind));
  Assert.AreEqual(Ord(oskWindowsNT4), Ord(Describe(osfWindowsNT, 4, 0, 1381).Kind));
  Assert.AreEqual(Ord(oskWindows2000), Ord(Describe(osfWindowsNT, 5, 0, 2195).Kind));
  Assert.AreEqual(Ord(oskWindows2000), Ord(Describe(osfWindowsNT, 10, 0, 19045).Kind));
  Assert.AreEqual(Ord(oskUnknown), Ord(Describe(osfUnknown, 1, 1, 1).Kind));
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDirePiuRecenteDiVistaSoloDaNT6InSu;
begin
  Assert.IsFalse(Describe(osfWindows9x, 4, 90, 1).IsVistaOrNewer);
  Assert.IsFalse(Describe(osfWindowsNT, 5, 1, 2600).IsVistaOrNewer);
  Assert.IsTrue(Describe(osfWindowsNT, 6, 0, 6002).IsVistaOrNewer);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeTenereModernoUnSistemaSconosciuto;
begin
  Assert.IsTrue(Describe(osfUnknown, 1, 1, 1).IsVistaOrNewer);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeScrivereLaRigaDiAvvio;
var
  LDescription: TOperatingSystemDescription;
begin
  LDescription := Describe(osfWindowsNT, 5, 1, 2600);
  Assert.AreEqual<Integer>(1, Length(LDescription.Lines));
  Assert.AreEqual(' OS: Windows XP 5.1 (Build 2600)', LDescription.Lines[0]);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeTagliareLaBuildDiWindows9x;
begin
  Assert.AreEqual(' OS: Windows 98 4.10 (Build 1998)',
    Describe(osfWindows9x, 4, 10, $040A07CE).Lines[0]);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeNonTagliareLaBuildDiNT;
begin
  Assert.AreEqual(' OS: Windows 7 6.1 (Build 4294967295)',
    Describe(osfWindowsNT, 6, 1, $FFFFFFFF).Lines[0]);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeAggiungereLaRigaDelServicePack;
var
  LDescription: TOperatingSystemDescription;
begin
  LDescription := Describe(osfWindowsNT, 5, 1, 2600, 'Service Pack 3');
  Assert.AreEqual<Integer>(2, Length(LDescription.Lines));
  Assert.AreEqual('     Service Pack 3', LDescription.Lines[1]);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeRifiutareUnaSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TPlatformFactory.CreateOperatingSystemInfo(nil);
    end, EArgumentNilException);
end;

procedure TTestPlatformOperatingSystemInfo.DovrebbeDareUnaVersioneAlSistemaVero;
var
  LDescription: TOperatingSystemDescription;
begin
  LDescription := TPlatformFactory.CreateServices.OperatingSystem.Describe;
  Assert.IsTrue(Length(LDescription.Lines) >= 1);
  Assert.IsTrue(LDescription.Lines[0].StartsWith(' OS: Windows '));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformOperatingSystemInfo);

end.
