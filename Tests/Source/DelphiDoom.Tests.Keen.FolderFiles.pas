{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the files in folders                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.FolderFiles;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenFolderFiles = class(TObject)
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
    procedure DovrebbeTrovareUnFileInUnaCartella;
    [Test]
    procedure DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
    [Test]
    procedure DovrebbeCercareNelleCartelleSuccessive;
    [Test]
    procedure DovrebbeLeggereTuttiIByte;
    [Test]
    procedure DovrebbeAprireUnFlussoInLettura;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileNonCe;
    [Test]
    procedure DovrebbeDareFalsoSenzaCartelle;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.Factory;

{ TTestKeenFolderFiles }

procedure TTestKeenFolderFiles.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'keen-test-' + TGUID.NewGuid.ToString.Substring(1, 8));
  FFirst := TPath.Combine(FRoot, 'one');
  FSecond := TPath.Combine(FRoot, 'two');
  TDirectory.CreateDirectory(FFirst);
  TDirectory.CreateDirectory(FSecond);
end;

procedure TTestKeenFolderFiles.TearDown;
begin
  TDirectory.Delete(FRoot, True);
end;

procedure TTestKeenFolderFiles.WriteFile(const AFolder, AName: string; const ABytes: TBytes);
begin
  TFile.WriteAllBytes(TPath.Combine(AFolder, AName), ABytes);
end;

procedure TTestKeenFolderFiles.DovrebbeTrovareUnFileInUnaCartella;
begin
  WriteFile(FFirst, 'KDREAMS.EGA', TBytes.Create(1, 2, 3));
  Assert.IsTrue(TKeenFactory.CreateFolderFiles([FFirst]).Exists('KDREAMS.EGA'));
  Assert.IsTrue(TKeenFactory.CreateFolderFiles([FFirst]).Exists('kdreams.ega'), 'Windows non guarda le maiuscole');
end;

procedure TTestKeenFolderFiles.DovrebbePrendereIlFileDallaPrimaCartellaCheLoHa;
begin
  WriteFile(FFirst, 'MAPHEAD.KDR', TBytes.Create(1));
  WriteFile(FSecond, 'MAPHEAD.KDR', TBytes.Create(1, 2));
  Assert.AreEqual(1, Length(TKeenFactory.CreateFolderFiles([FFirst, FSecond]).ReadAll('MAPHEAD.KDR')));
  Assert.AreEqual(2, Length(TKeenFactory.CreateFolderFiles([FSecond, FFirst]).ReadAll('MAPHEAD.KDR')));
end;

procedure TTestKeenFolderFiles.DovrebbeCercareNelleCartelleSuccessive;
begin
  WriteFile(FSecond, 'EGAHEAD.KDR', TBytes.Create(5, 6));
  Assert.AreEqual(2, Length(TKeenFactory.CreateFolderFiles([FFirst, FSecond]).ReadAll('EGAHEAD.KDR')));
end;

procedure TTestKeenFolderFiles.DovrebbeLeggereTuttiIByte;
var
  LBytes: TBytes;
begin
  WriteFile(FFirst, 'A.KDR', TBytes.Create(9, 8, 7, 6));
  LBytes := TKeenFactory.CreateFolderFiles([FFirst]).ReadAll('A.KDR');
  Assert.AreEqual(4, Length(LBytes));
  Assert.AreEqual(6, Integer(LBytes[3]));
end;

procedure TTestKeenFolderFiles.DovrebbeAprireUnFlussoInLettura;
var
  LStream: TStream;
begin
  WriteFile(FFirst, 'A.KDR', TBytes.Create(9, 8, 7, 6));
  LStream := TKeenFactory.CreateFolderFiles([FFirst]).OpenStream('A.KDR');
  try
    Assert.AreEqual(4, Integer(LStream.Size));
  finally
    LStream.Free;
  end;
end;

procedure TTestKeenFolderFiles.DovrebbeSollevareUnErroreSeIlFileNonCe;
var
  LFiles: IKeenDataFiles;
begin
  LFiles := TKeenFactory.CreateFolderFiles([FFirst]);
  Assert.WillRaise(
    procedure
    begin
      LFiles.ReadAll('NONE.KDR');
    end, EKeenFileNotFoundException);
end;

procedure TTestKeenFolderFiles.DovrebbeDareFalsoSenzaCartelle;
begin
  Assert.IsFalse(TKeenFactory.CreateFolderFiles([]).Exists('KDREAMS.EGA'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenFolderFiles);

end.
