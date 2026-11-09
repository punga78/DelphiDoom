{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the files in memory          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.MemoryFiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.MemoryFiles;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomMemoryFiles = class(TObject)
  private
    FFiles: TXcomMemoryFiles;
    // keeps the object alive (and frees it): FFiles is only used while FOwner is set
    FOwner: IXcomDataFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIByteDiUnFile;
    [Test]
    procedure DovrebbeNonDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTrattareLaBarraEIlRetroBarraComeLoStessoSeparatore;
    [Test]
    procedure DovrebbeSostituireUnFileConLoStessoNome;
    [Test]
    procedure DovrebbeDireCheUnFileNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonCe;
  end;

implementation

uses
  DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomMemoryFiles }

procedure TTestXcomMemoryFiles.Setup;
begin
  FFiles := TXcomMemoryFiles.Create;
  FOwner := FFiles;
end;

procedure TTestXcomMemoryFiles.TearDown;
begin
  FOwner := nil;
  FFiles := nil;
end;

procedure TTestXcomMemoryFiles.DovrebbeDareIByteDiUnFile;
begin
  FFiles.Add('A.DAT', TXcomTestBuilders.Bytes([1, 2, 3]));
  Assert.AreEqual(3, Integer(Length(FFiles.ReadAll('A.DAT'))));
end;

procedure TTestXcomMemoryFiles.DovrebbeNonDistinguereLeMaiuscole;
begin
  FFiles.Add('Geodata.dat', TXcomTestBuilders.Bytes([1]));
  Assert.IsTrue(FFiles.Exists('GEODATA.DAT'));
end;

procedure TTestXcomMemoryFiles.DovrebbeTrattareLaBarraEIlRetroBarraComeLoStessoSeparatore;
begin
  FFiles.Add('GEODATA/PALETTES.DAT', TXcomTestBuilders.Bytes([1]));
  Assert.IsTrue(FFiles.Exists('GEODATA\PALETTES.DAT'));
  Assert.AreEqual(1, Integer(Length(FFiles.ReadAll('geodata\palettes.dat'))));
end;

procedure TTestXcomMemoryFiles.DovrebbeSostituireUnFileConLoStessoNome;
begin
  FFiles.Add('A.DAT', TXcomTestBuilders.Bytes([1]));
  FFiles.Add('a.dat', TXcomTestBuilders.Bytes([1, 2]));
  Assert.AreEqual(2, Integer(Length(FFiles.ReadAll('A.DAT'))));
end;

procedure TTestXcomMemoryFiles.DovrebbeDireCheUnFileNonCe;
begin
  Assert.IsFalse(FFiles.Exists('NO.DAT'));
end;

procedure TTestXcomMemoryFiles.DovrebbeRifiutareUnFileCheNonCe;
begin
  Assert.WillRaise(procedure begin FFiles.ReadAll('NO.DAT'); end, EXcomFileNotFoundException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMemoryFiles);

end.
