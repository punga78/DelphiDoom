{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - files in folders                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.FolderFiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedFolderFiles = class(TObject)
  private
    FFirst: string;
    FSecond: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeTrovareUnFileInUnaCartella;
    [Test]
    procedure DovrebbeLeggereTuttiIByteDelFile;
    [Test]
    procedure DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
    [Test]
    procedure DovrebbeCercareNelleCartelleSuccessive;
    [Test]
    procedure DovrebbeNonTrovareUnFileCheNonCe;
    [Test]
    procedure DovrebbeSollevareSeIlFileNonCe;
    [Test]
    procedure DovrebbeRifiutareUnNomeConUnPercorso;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory;

{ TTestGreedFolderFiles }

procedure TTestGreedFolderFiles.Setup;
begin
  FFirst := TPath.Combine(TPath.GetTempPath, 'ddgreed_a_' + TGUID.NewGuid.ToString);
  FSecond := TPath.Combine(TPath.GetTempPath, 'ddgreed_b_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FFirst);
  TDirectory.CreateDirectory(FSecond);
  TFile.WriteAllBytes(TPath.Combine(FFirst, 'A.LAY'), TBytes.Create(1, 2, 3));
  TFile.WriteAllBytes(TPath.Combine(FSecond, 'A.LAY'), TBytes.Create(9));
  TFile.WriteAllBytes(TPath.Combine(FSecond, 'B.LAY'), TBytes.Create(7, 7));
end;

procedure TTestGreedFolderFiles.TearDown;
begin
  TDirectory.Delete(FFirst, True);
  TDirectory.Delete(FSecond, True);
end;

procedure TTestGreedFolderFiles.DovrebbeTrovareUnFileInUnaCartella;
begin
  Assert.IsTrue(TGreedFactory.CreateFolderFiles([FFirst]).Exists('A.LAY'));
  Assert.IsTrue(TGreedFactory.CreateFolderFiles([FFirst]).Exists('a.lay'));
end;

procedure TTestGreedFolderFiles.DovrebbeLeggereTuttiIByteDelFile;
begin
  Assert.AreEqual(3, Length(TGreedFactory.CreateFolderFiles([FFirst]).ReadAll('A.LAY')));
end;

procedure TTestGreedFolderFiles.DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
begin
  Assert.AreEqual(1, Integer(TGreedFactory.CreateFolderFiles([FFirst, FSecond]).ReadAll('A.LAY')[0]));
  Assert.AreEqual(9, Integer(TGreedFactory.CreateFolderFiles([FSecond, FFirst]).ReadAll('A.LAY')[0]));
end;

procedure TTestGreedFolderFiles.DovrebbeCercareNelleCartelleSuccessive;
begin
  Assert.AreEqual(2, Length(TGreedFactory.CreateFolderFiles([FFirst, FSecond]).ReadAll('B.LAY')));
end;

procedure TTestGreedFolderFiles.DovrebbeNonTrovareUnFileCheNonCe;
begin
  Assert.IsFalse(TGreedFactory.CreateFolderFiles([FFirst]).Exists('B.LAY'));
  Assert.IsFalse(TGreedFactory.CreateFolderFiles([]).Exists('A.LAY'));
end;

procedure TTestGreedFolderFiles.DovrebbeSollevareSeIlFileNonCe;
var
  LFiles: IGreedExternalFiles;
begin
  LFiles := TGreedFactory.CreateFolderFiles([FFirst]);
  Assert.WillRaise(procedure begin LFiles.ReadAll('B.LAY'); end, EGreedNotFoundException);
end;

procedure TTestGreedFolderFiles.DovrebbeRifiutareUnNomeConUnPercorso;
begin
  // a lump of the archive must not be able to point out of the folders
  Assert.IsFalse(TGreedFactory.CreateFolderFiles([FFirst]).Exists(TPath.Combine(FFirst, 'A.LAY')));
  Assert.IsFalse(TGreedFactory.CreateFolderFiles([FFirst]).Exists('..\' + ExtractFileName(FFirst) + '\A.LAY'));
end;

procedure TTestGreedFolderFiles.DovrebbeRifiutareUnNomeVuoto;
begin
  Assert.IsFalse(TGreedFactory.CreateFolderFiles([FFirst]).Exists(''));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedFolderFiles);

end.
