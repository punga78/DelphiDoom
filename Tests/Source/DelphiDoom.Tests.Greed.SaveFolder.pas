{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSaveFolder                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SaveFolder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Save.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSaveFolder = class(TObject)
  private
    FFolder: string;
    FSut: IGreedSaveFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereERileggereUnFile;
    [Test]
    procedure DovrebbeSostituireUnFileEsistente;
    [Test]
    procedure DovrebbeDireCheUnFileNonCe;
    [Test]
    procedure DovrebbeSollevareLeggendoUnFileCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnNomeConUnPercorso;
    [Test]
    procedure DovrebbeSollevareSeLaCartellaNonCe;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveFolder;

{ TTestGreedSaveFolder }

procedure TTestGreedSaveFolder.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'greed_save_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
  FSut := TGreedSaveFolder.Create(FFolder);
end;

procedure TTestGreedSaveFolder.TearDown;
begin
  FSut := nil;
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

procedure TTestGreedSaveFolder.DovrebbeScrivereERileggereUnFile;
begin
  FSut.WriteAll('SAVEGAME.1', [1, 2, 3]);
  Assert.IsTrue(FSut.Exists('SAVEGAME.1'));
  Assert.AreEqual<Integer>(3, Length(FSut.ReadAll('SAVEGAME.1')));
  Assert.AreEqual<Integer>(2, FSut.ReadAll('SAVEGAME.1')[1]);
end;

procedure TTestGreedSaveFolder.DovrebbeSostituireUnFileEsistente;
begin
  FSut.WriteAll('SAVEGAME.1', [1, 2, 3]);
  FSut.WriteAll('SAVEGAME.1', [9]);
  Assert.AreEqual<Integer>(1, Length(FSut.ReadAll('SAVEGAME.1')));
end;

procedure TTestGreedSaveFolder.DovrebbeDireCheUnFileNonCe;
begin
  Assert.IsFalse(FSut.Exists('SAVEGAME.5'));
end;

procedure TTestGreedSaveFolder.DovrebbeSollevareLeggendoUnFileCheNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      FSut.ReadAll('SAVEGAME.5');
    end, EGreedNotFoundException);
end;

procedure TTestGreedSaveFolder.DovrebbeRifiutareUnNomeConUnPercorso;
begin
  Assert.WillRaise(
    procedure
    begin
      FSut.WriteAll('..\escape.1', [1]);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FSut.Exists('');
    end, EGreedException);
end;

procedure TTestGreedSaveFolder.DovrebbeSollevareSeLaCartellaNonCe;
var
  LSut: IGreedSaveFiles;
begin
  LSut := TGreedSaveFolder.Create(TPath.Combine(FFolder, 'missing'));
  Assert.WillRaise(
    procedure
    begin
      LSut.WriteAll('SAVEGAME.1', [1]);
    end, EGreedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSaveFolder);

end.
