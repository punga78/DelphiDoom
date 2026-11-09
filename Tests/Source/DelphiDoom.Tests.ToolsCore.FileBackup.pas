{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TToolFileBackup                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.FileBackup;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf, DelphiDoom.Tests.ToolsCore.Fakes;

type
  [TestFixture]
  [Category('toolscore')]
  TTestToolsFileBackup = class(TObject)
  strict private
    FFileSystem: TFakeToolFileSystem;
    FFileSystemIntf: IToolFileSystem;
    FBackup: IToolFileBackup;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeCopiareIlFileConIlSuffisso;
    [Test]
    procedure DovrebbeNonFareNullaSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeDareFalsoSeLaCopiaFallisce;
    [Test]
    procedure DovrebbeSostituireUnaCopiaVecchia;
    [Test]
    procedure DovrebbeRifiutareUnSistemaDiFileNil;
  end;

implementation

uses
  DelphiDoom.Tools.Factory;

{ TTestToolsFileBackup }

procedure TTestToolsFileBackup.Setup;
begin
  FFileSystem := TFakeToolFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FBackup := TToolsFactory.CreateFileBackup(FFileSystemIntf);
end;

procedure TTestToolsFileBackup.DovrebbeCopiareIlFileConIlSuffisso;
begin
  FFileSystem.PutText('C:\a.bin', 'dati');
  Assert.IsTrue(FBackup.Backup('C:\a.bin'));
  Assert.AreEqual('dati', FFileSystem.TextOf('C:\a.bin_bak'));
end;

procedure TTestToolsFileBackup.DovrebbeNonFareNullaSeIlFileNonEsiste;
begin
  Assert.IsTrue(FBackup.Backup('C:\manca.bin'));
  Assert.AreEqual(0, FFileSystem.CopyCount);
end;

procedure TTestToolsFileBackup.DovrebbeDareFalsoSeLaCopiaFallisce;
begin
  FFileSystem.PutText('C:\a.bin', 'dati');
  FFileSystem.FailCopy := True;
  Assert.IsFalse(FBackup.Backup('C:\a.bin'));
end;

procedure TTestToolsFileBackup.DovrebbeSostituireUnaCopiaVecchia;
begin
  FFileSystem.PutText('C:\a.bin', 'nuovo');
  FFileSystem.PutText('C:\a.bin_bak', 'vecchio');
  Assert.IsTrue(FBackup.Backup('C:\a.bin'));
  Assert.AreEqual('nuovo', FFileSystem.TextOf('C:\a.bin_bak'));
end;

procedure TTestToolsFileBackup.DovrebbeRifiutareUnSistemaDiFileNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TToolsFactory.CreateFileBackup(nil);
    end, EArgumentNilException);
end;

end.
