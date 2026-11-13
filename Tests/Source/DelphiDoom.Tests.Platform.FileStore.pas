{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the files on the disk           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.FileStore;

interface

uses
  System.SysUtils, System.IOUtils, Winapi.Windows, DUnitX.TestFramework, DelphiDoom.Platform.Intf,
  DelphiDoom.Platform.Types;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformFileStore = class(TObject)
  private
    FStore: IFileStore;
    FDirectory: string;
    FData: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereERileggere;
    [Test]
    procedure DovrebbeDareFalsoSeScriveZeroByte;
    [Test]
    procedure DovrebbeCreareUnFileVuotoSeScriveZeroByte;
    [Test]
    procedure DovrebbeSovrascrivereUnFileEsistente;
    [Test]
    procedure DovrebbeDareFalsoSeLaCartellaNonEsiste;
    [Test]
    procedure DovrebbeAccodareAlFileEsistente;
    [Test]
    procedure DovrebbeCrearePrimaDiAccodareSeManca;
    [Test]
    procedure DovrebbeDareZeroSeAccodaZeroByte;
    [Test]
    procedure DovrebbeDareZeroSeAccodaInUnaCartellaCheNonEsiste;
    [Test]
    procedure DovrebbeLeggereUnFileVuoto;
    [Test]
    procedure DovrebbeSollevareSeIlFileNonSiLegge;
    [Test]
    procedure DovrebbeCancellareSoloUnFileEsistente;
    [Test]
    procedure DovrebbeCrearePiuCartelleInUnaVolta;
    [Test]
    procedure DovrebbeAccettareUnaCartellaGiaCreata;
    [Test]
    procedure DovrebbeRifiutareUnaCartellaVuota;
  end;

implementation

uses
  DelphiDoom.Platform.Factory;

{ TTestPlatformFileStore }

procedure TTestPlatformFileStore.Setup;
var
  LIndex: Integer;
begin
  FStore := TPlatformFactory.CreateFileStore;
  FDirectory := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'ddplatform_' + IntToStr(GetCurrentThreadId) + '\';
  ForceDirectories(FDirectory);
  SetLength(FData, 300);
  for LIndex := 0 to High(FData) do
    FData[LIndex] := Byte(LIndex * 5 + 1);
end;

procedure TTestPlatformFileStore.TearDown;
begin
  if DirectoryExists(FDirectory) then
    TDirectory.Delete(FDirectory, True);
end;

procedure TTestPlatformFileStore.DovrebbeScrivereERileggere;
var
  LRead: TBytes;
begin
  Assert.IsTrue(FStore.Write(FDirectory + 'a.bin', @FData[0], Length(FData)));
  LRead := FStore.Read(FDirectory + 'a.bin');
  Assert.AreEqual(Length(FData), Length(LRead));
  Assert.IsTrue(CompareMem(@FData[0], @LRead[0], Length(FData)));
end;

procedure TTestPlatformFileStore.DovrebbeDareFalsoSeScriveZeroByte;
begin
  Assert.IsFalse(FStore.Write(FDirectory + 'a.bin', @FData[0], 0));
end;

procedure TTestPlatformFileStore.DovrebbeCreareUnFileVuotoSeScriveZeroByte;
begin
  FStore.Write(FDirectory + 'a.bin', @FData[0], 0);
  Assert.IsTrue(FStore.Exists(FDirectory + 'a.bin'));
  Assert.AreEqual<Integer>(0, Length(FStore.Read(FDirectory + 'a.bin')));
end;

procedure TTestPlatformFileStore.DovrebbeSovrascrivereUnFileEsistente;
begin
  FStore.Write(FDirectory + 'a.bin', @FData[0], 300);
  FStore.Write(FDirectory + 'a.bin', @FData[0], 10);
  Assert.AreEqual<Integer>(10, Length(FStore.Read(FDirectory + 'a.bin')));
end;

procedure TTestPlatformFileStore.DovrebbeDareFalsoSeLaCartellaNonEsiste;
begin
  Assert.IsFalse(FStore.Write(FDirectory + 'manca\a.bin', @FData[0], 10));
end;

procedure TTestPlatformFileStore.DovrebbeAccodareAlFileEsistente;
var
  LRead: TBytes;
begin
  FStore.Write(FDirectory + 'a.bin', @FData[0], 100);
  Assert.AreEqual(50, FStore.Append(FDirectory + 'a.bin', @FData[100], 50));
  LRead := FStore.Read(FDirectory + 'a.bin');
  Assert.AreEqual<Integer>(150, Length(LRead));
  Assert.IsTrue(CompareMem(@FData[0], @LRead[0], 150));
end;

procedure TTestPlatformFileStore.DovrebbeCrearePrimaDiAccodareSeManca;
begin
  Assert.AreEqual(40, FStore.Append(FDirectory + 'nuovo.bin', @FData[0], 40));
  Assert.AreEqual<Integer>(40, Length(FStore.Read(FDirectory + 'nuovo.bin')));
end;

procedure TTestPlatformFileStore.DovrebbeDareZeroSeAccodaZeroByte;
begin
  FStore.Write(FDirectory + 'a.bin', @FData[0], 100);
  Assert.AreEqual(0, FStore.Append(FDirectory + 'a.bin', @FData[0], 0));
  Assert.AreEqual<Integer>(100, Length(FStore.Read(FDirectory + 'a.bin')));
end;

procedure TTestPlatformFileStore.DovrebbeDareZeroSeAccodaInUnaCartellaCheNonEsiste;
begin
  Assert.AreEqual(0, FStore.Append(FDirectory + 'manca\a.bin', @FData[0], 10));
end;

procedure TTestPlatformFileStore.DovrebbeLeggereUnFileVuoto;
begin
  FStore.Write(FDirectory + 'v.bin', nil, 0);
  Assert.AreEqual<Integer>(0, Length(FStore.Read(FDirectory + 'v.bin')));
end;

procedure TTestPlatformFileStore.DovrebbeSollevareSeIlFileNonSiLegge;
begin
  Assert.WillRaise(
    procedure
    begin
      FStore.Read(FDirectory + 'non_esiste.bin');
    end, EPlatformException);
end;

procedure TTestPlatformFileStore.DovrebbeCancellareSoloUnFileEsistente;
begin
  FStore.Write(FDirectory + 'a.bin', @FData[0], 10);
  Assert.IsTrue(FStore.Delete(FDirectory + 'a.bin'));
  Assert.IsFalse(FStore.Exists(FDirectory + 'a.bin'));
  Assert.IsFalse(FStore.Delete(FDirectory + 'a.bin'));
end;

procedure TTestPlatformFileStore.DovrebbeCrearePiuCartelleInUnaVolta;
begin
  Assert.IsTrue(FStore.EnsureDirectory(FDirectory + 'a\b\c\'));
  Assert.IsTrue(DirectoryExists(FDirectory + 'a\b\c'));
end;

procedure TTestPlatformFileStore.DovrebbeAccettareUnaCartellaGiaCreata;
begin
  Assert.IsTrue(FStore.EnsureDirectory(FDirectory));
end;

procedure TTestPlatformFileStore.DovrebbeRifiutareUnaCartellaVuota;
begin
  Assert.IsFalse(FStore.EnsureDirectory(''));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformFileStore);

end.
