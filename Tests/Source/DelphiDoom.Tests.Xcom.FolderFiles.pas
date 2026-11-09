{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the files in folders         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.FolderFiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomFolderFiles = class(TObject)
  private
    FRoot: string;
    FFirst: string;
    FSecond: string;
    procedure WriteFile(const AFolder, AName: string; const ABytes: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereUnFileDiUnaCartella;
    [Test]
    procedure DovrebbeLeggereUnFileInUnaSottocartellaConLaBarra;
    [Test]
    procedure DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
    [Test]
    procedure DovrebbeCercareNelleCartelleSuccessive;
    [Test]
    procedure DovrebbeDireCheUnFileNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonCe;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomFolderFiles }

procedure TTestXcomFolderFiles.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'ddxcom_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  FFirst := TPath.Combine(FRoot, 'one');
  FSecond := TPath.Combine(FRoot, 'two');
  TDirectory.CreateDirectory(FFirst);
  TDirectory.CreateDirectory(FSecond);
end;

procedure TTestXcomFolderFiles.TearDown;
begin
  if TDirectory.Exists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

procedure TTestXcomFolderFiles.WriteFile(const AFolder, AName: string; const ABytes: TBytes);
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(TPath.Combine(AFolder, AName)));
  TFile.WriteAllBytes(TPath.Combine(AFolder, AName), ABytes);
end;

procedure TTestXcomFolderFiles.DovrebbeLeggereUnFileDiUnaCartella;
begin
  WriteFile(FFirst, 'A.DAT', TXcomTestBuilders.Bytes([1, 2, 3]));
  Assert.AreEqual(3, Integer(Length(TXcomFactory.CreateFolderFiles([FFirst]).ReadAll('A.DAT'))));
end;

procedure TTestXcomFolderFiles.DovrebbeLeggereUnFileInUnaSottocartellaConLaBarra;
begin
  WriteFile(FFirst, 'GEODATA\PALETTES.DAT', TXcomTestBuilders.Bytes([5]));
  Assert.AreEqual(1, Integer(Length(TXcomFactory.CreateFolderFiles([FFirst]).ReadAll('GEODATA/PALETTES.DAT'))));
end;

procedure TTestXcomFolderFiles.DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
var
  LFiles: IXcomDataFiles;
begin
  WriteFile(FFirst, 'A.DAT', TXcomTestBuilders.Bytes([1]));
  WriteFile(FSecond, 'A.DAT', TXcomTestBuilders.Bytes([1, 2]));
  LFiles := TXcomFactory.CreateFolderFiles([FFirst, FSecond]);
  Assert.AreEqual(1, Integer(Length(LFiles.ReadAll('A.DAT'))));
  LFiles := TXcomFactory.CreateFolderFiles([FSecond, FFirst]);
  Assert.AreEqual(2, Integer(Length(LFiles.ReadAll('A.DAT'))));
end;

procedure TTestXcomFolderFiles.DovrebbeCercareNelleCartelleSuccessive;
var
  LFiles: IXcomDataFiles;
begin
  WriteFile(FSecond, 'B.DAT', TXcomTestBuilders.Bytes([9]));
  LFiles := TXcomFactory.CreateFolderFiles([FFirst, FSecond]);
  Assert.IsTrue(LFiles.Exists('B.DAT'));
  Assert.AreEqual(9, Integer(LFiles.ReadAll('B.DAT')[0]));
end;

procedure TTestXcomFolderFiles.DovrebbeDireCheUnFileNonCe;
begin
  Assert.IsFalse(TXcomFactory.CreateFolderFiles([FFirst]).Exists('NO.DAT'));
  Assert.IsFalse(TXcomFactory.CreateFolderFiles([]).Exists('NO.DAT'));
end;

procedure TTestXcomFolderFiles.DovrebbeRifiutareUnFileCheNonCe;
var
  LFiles: IXcomDataFiles;
begin
  LFiles := TXcomFactory.CreateFolderFiles([FFirst]);
  Assert.WillRaise(procedure begin LFiles.ReadAll('NO.DAT'); end, EXcomFileNotFoundException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomFolderFiles);

end.
