{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the temporary files             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.TempFiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Platform.Intf, DelphiDoom.Platform.Factory,
  DelphiDoom.Tests.Platform.Fakes;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformTempFiles = class(TObject)
  private
    FStore: TMemoryFileStore;
    FStoreIntf: IFileStore;
    FTempFiles: ITempFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlNomeNellaCartellaTemporanea;
    [Test]
    procedure DovrebbeUsareSoloIlNomeDelFile;
    [Test]
    procedure DovrebbeAggiungereIlSeparatoreDiCartella;
    [Test]
    procedure DovrebbeCrearelaCartellaPerOgniFile;
    [Test]
    procedure DovrebbeIgnorareUnaCartellaCheNonSiCrea;
    [Test]
    procedure DovrebbeRicordareIFileDichiarati;
    [Test]
    procedure DovrebbeCancellareTuttoEDimenticare;
    [Test]
    procedure DovrebbeAccettareDueVolteDeleteAll;
    [Test]
    procedure DovrebbeNonCancellareUnFileDopoDeleteAll;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.Platform.TempFiles;

{ TTestPlatformTempFiles }

procedure TTestPlatformTempFiles.Setup;
begin
  FStore := TMemoryFileStore.Create;
  FStoreIntf := FStore;
  FTempFiles := TPlatformFactory.CreateTempFiles(TFakeTempDirectory.Create('DATA\TMP\'), FStoreIntf);
end;

procedure TTestPlatformTempFiles.TearDown;
begin
  FTempFiles := nil;
  FStoreIntf := nil;
end;

procedure TTestPlatformTempFiles.DovrebbeDareIlNomeNellaCartellaTemporanea;
begin
  Assert.AreEqual('DATA\TMP\map.wad', FTempFiles.NewTempFile('map.wad'));
end;

procedure TTestPlatformTempFiles.DovrebbeUsareSoloIlNomeDelFile;
begin
  Assert.AreEqual('DATA\TMP\x.mid', FTempFiles.NewTempFile('C:\altro\posto\x.mid'));
end;

procedure TTestPlatformTempFiles.DovrebbeAggiungereIlSeparatoreDiCartella;
var
  LTempFiles: ITempFiles;
begin
  LTempFiles := TPlatformFactory.CreateTempFiles(TFakeTempDirectory.Create('D:\t'), FStoreIntf);
  Assert.AreEqual('D:\t\a.bin', LTempFiles.NewTempFile('a.bin'));
end;

procedure TTestPlatformTempFiles.DovrebbeCrearelaCartellaPerOgniFile;
begin
  FTempFiles.NewTempFile('a');
  FTempFiles.NewTempFile('b');
  Assert.AreEqual(2, FStore.Directories.Count);
  Assert.AreEqual('DATA\TMP\', FStore.Directories[0]);
end;

procedure TTestPlatformTempFiles.DovrebbeIgnorareUnaCartellaCheNonSiCrea;
begin
  FStore.FailDirectories := True;
  Assert.AreEqual('DATA\TMP\a', FTempFiles.NewTempFile('a'));
  Assert.AreEqual(1, FTempFiles.Count);
end;

procedure TTestPlatformTempFiles.DovrebbeRicordareIFileDichiarati;
begin
  FTempFiles.Declare('X:\fuori.wad');
  FTempFiles.NewTempFile('dentro');
  Assert.AreEqual(2, FTempFiles.Count);
  Assert.AreEqual('X:\fuori.wad', FTempFiles.Names[0]);
  Assert.AreEqual('DATA\TMP\dentro', FTempFiles.Names[1]);
end;

procedure TTestPlatformTempFiles.DovrebbeCancellareTuttoEDimenticare;
var
  LData: Byte;
begin
  LData := 1;
  FStore.Write('X:\fuori.wad', @LData, 1);
  FStore.Write('DATA\TMP\dentro', @LData, 1);
  FTempFiles.Declare('X:\fuori.wad');
  FTempFiles.NewTempFile('dentro');
  FTempFiles.DeleteAll;
  Assert.IsFalse(FStore.Exists('X:\fuori.wad'));
  Assert.IsFalse(FStore.Exists('DATA\TMP\dentro'));
  Assert.AreEqual(0, FTempFiles.Count);
end;

procedure TTestPlatformTempFiles.DovrebbeAccettareDueVolteDeleteAll;
begin
  FTempFiles.NewTempFile('a');
  FTempFiles.DeleteAll;
  FTempFiles.DeleteAll;
  Assert.AreEqual(1, FStore.Deleted.Count);
end;

procedure TTestPlatformTempFiles.DovrebbeNonCancellareUnFileDopoDeleteAll;
var
  LData: Byte;
begin
  LData := 1;
  FTempFiles.NewTempFile('a');
  FTempFiles.DeleteAll;
  FStore.Write('DATA\TMP\a', @LData, 1);
  FTempFiles.DeleteAll;
  Assert.IsTrue(FStore.Exists('DATA\TMP\a'));
end;

procedure TTestPlatformTempFiles.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTempFiles.Create(nil, FStoreIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TTempFiles.Create(TFakeTempDirectory.Create('x\'), nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformTempFiles);

end.
