{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the files in memory                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.MemoryFiles;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.MemoryFiles;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenMemoryFiles = class(TObject)
  private
    FMemory: TKeenMemoryFiles;
    FFiles: IKeenDataFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeTrovareUnFileSenzaGuardareLeMaiuscole;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileCheNonCe;
    [Test]
    procedure DovrebbeLeggereTuttiIByteDiUnFile;
    [Test]
    procedure DovrebbeAprireUnFlussoIndipendenteDalFile;
    [Test]
    procedure DovrebbeSostituireUnFileConLoStessoNome;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileNonCe;
  end;

implementation

{ TTestKeenMemoryFiles }

procedure TTestKeenMemoryFiles.Setup;
begin
  FMemory := TKeenMemoryFiles.Create;
  FFiles := FMemory;
end;

procedure TTestKeenMemoryFiles.TearDown;
begin
  FFiles := nil;
end;

procedure TTestKeenMemoryFiles.DovrebbeTrovareUnFileSenzaGuardareLeMaiuscole;
begin
  FMemory.Add('KDREAMS.EGA', TBytes.Create(1, 2, 3));
  Assert.IsTrue(FFiles.Exists('kdreams.ega'));
  Assert.IsTrue(FFiles.Exists('KDREAMS.EGA'));
end;

procedure TTestKeenMemoryFiles.DovrebbeDareFalsoPerUnFileCheNonCe;
begin
  Assert.IsFalse(FFiles.Exists('KDREAMS.MAP'));
end;

procedure TTestKeenMemoryFiles.DovrebbeLeggereTuttiIByteDiUnFile;
var
  LBytes: TBytes;
begin
  FMemory.Add('A.KDR', TBytes.Create(9, 8, 7));
  LBytes := FFiles.ReadAll('A.KDR');
  Assert.AreEqual<Integer>(3, Length(LBytes));
  Assert.AreEqual(8, Integer(LBytes[1]));
end;

procedure TTestKeenMemoryFiles.DovrebbeAprireUnFlussoIndipendenteDalFile;
var
  LStream: TStream;
  LByte: Byte;
begin
  FMemory.Add('A.KDR', TBytes.Create(9, 8, 7));
  LStream := FFiles.OpenStream('a.kdr');
  try
    Assert.AreEqual(3, Integer(LStream.Size));
    LStream.Position := 2;
    LStream.ReadBuffer(LByte, 1);
    Assert.AreEqual(7, Integer(LByte));
  finally
    LStream.Free;
  end;
  Assert.AreEqual<Integer>(3, Length(FFiles.ReadAll('A.KDR')), 'il file resta com''era');
end;

procedure TTestKeenMemoryFiles.DovrebbeSostituireUnFileConLoStessoNome;
begin
  FMemory.Add('A.KDR', TBytes.Create(1));
  FMemory.Add('a.kdr', TBytes.Create(1, 2));
  Assert.AreEqual<Integer>(2, Length(FFiles.ReadAll('A.KDR')));
end;

procedure TTestKeenMemoryFiles.DovrebbeSollevareUnErroreSeIlFileNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      FFiles.ReadAll('NONE.KDR');
    end, EKeenFileNotFoundException);
  Assert.WillRaise(
    procedure
    begin
      FFiles.OpenStream('NONE.KDR').Free;
    end, EKeenFileNotFoundException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenMemoryFiles);

end.
