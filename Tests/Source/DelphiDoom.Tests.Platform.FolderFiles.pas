{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - files in several folders         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.FolderFiles;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.Windows, DUnitX.TestFramework,
  DelphiDoom.Platform.FolderFiles.Intf;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformFolderFiles = class(TObject)
  private
    FRoot: string;
    FFirst: string;
    FSecond: string;
    procedure WriteFile(const APath: string; const AText: AnsiString);
    function Make: IFolderFiles;
    function TextOf(const ABytes: TBytes): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeTrovareIlFileNellaCartellaCheLoHa;
    [Test]
    procedure DovrebbeVincereLaPrimaCartella;
    [Test]
    procedure DovrebbeDareVuotoSeNessunaCartellaLoHa;
    [Test]
    procedure NonDovrebbeGuardareLeMaiuscoleDelNome;
    [Test]
    procedure DovrebbeAccettareLeDueBarreNeiNomi;
    [Test]
    procedure UnaCartellaNonDovrebbeEssereUnFile;
    [Test]
    procedure DovrebbeLeggereTuttoIlFile;
    [Test]
    procedure DovrebbeLeggereUnFileVuoto;
    [Test]
    procedure DovrebbeAprireUnFlussoDelChiamante;
    [Test]
    procedure DueFlussiDovrebberoLeggereLoStessoFile;
    [Test]
    procedure DovrebbeSollevareSeIlFileManca;
    [Test]
    procedure DovrebbeSollevareSeIlFileNonSiApre;
    [Test]
    procedure SenzaCartelleNonDovrebbeTrovareNiente;
    [Test]
    procedure UnNomeVuotoNonDovrebbeEssereTrovato;
    [Test]
    procedure SoloNomiNonDovrebbeTrovareUnNomeConCartella;
    [Test]
    procedure SoloNomiDovrebbeTrovareUnNomeSemplice;
  end;

implementation

uses
  DelphiDoom.Platform.FolderFiles.Factory;

procedure TTestPlatformFolderFiles.Setup;
begin
  FRoot := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'ddfolderfiles_' +
    IntToStr(GetCurrentProcessId) + '_' + IntToStr(GetCurrentThreadId) + '\';
  FFirst := FRoot + 'first';
  FSecond := FRoot + 'second';
  ForceDirectories(FFirst);
  ForceDirectories(FSecond + '\GEODATA');
  WriteFile(FFirst + '\ONLYFIRST.DAT', 'first');
  WriteFile(FFirst + '\BOTH.DAT', 'from first');
  WriteFile(FSecond + '\BOTH.DAT', 'from second');
  WriteFile(FSecond + '\ONLYSECOND.DAT', 'second');
  WriteFile(FSecond + '\GEODATA\PALETTES.DAT', 'palettes');
  WriteFile(FSecond + '\EMPTY.DAT', '');
end;

procedure TTestPlatformFolderFiles.TearDown;
begin
  if TDirectory.Exists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

procedure TTestPlatformFolderFiles.WriteFile(const APath: string; const AText: AnsiString);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(APath, fmCreate);
  try
    if Length(AText) > 0 then
      LStream.WriteBuffer(AText[1], Length(AText));
  finally
    LStream.Free;
  end;
end;

function TTestPlatformFolderFiles.Make: IFolderFiles;
begin
  Result := TFolderFilesFactory.CreateFolderFiles([FFirst, FSecond]);
end;

function TTestPlatformFolderFiles.TextOf(const ABytes: TBytes): string;
begin
  Result := TEncoding.ASCII.GetString(ABytes);
end;

procedure TTestPlatformFolderFiles.DovrebbeTrovareIlFileNellaCartellaCheLoHa;
var
  LFiles: IFolderFiles;
begin
  LFiles := Make;
  Assert.IsTrue(LFiles.Exists('ONLYFIRST.DAT'));
  Assert.IsTrue(LFiles.Exists('ONLYSECOND.DAT'));
  Assert.AreEqual(FSecond + '\ONLYSECOND.DAT', LFiles.Find('ONLYSECOND.DAT'));
end;

procedure TTestPlatformFolderFiles.DovrebbeVincereLaPrimaCartella;
begin
  Assert.AreEqual('from first', TextOf(Make.ReadAll('BOTH.DAT')));
  Assert.AreEqual('from second',
    TextOf(TFolderFilesFactory.CreateFolderFiles([FSecond, FFirst]).ReadAll('BOTH.DAT')));
end;

procedure TTestPlatformFolderFiles.DovrebbeDareVuotoSeNessunaCartellaLoHa;
var
  LFiles: IFolderFiles;
begin
  LFiles := Make;
  Assert.IsFalse(LFiles.Exists('NOWHERE.DAT'));
  Assert.AreEqual('', LFiles.Find('NOWHERE.DAT'));
end;

procedure TTestPlatformFolderFiles.NonDovrebbeGuardareLeMaiuscoleDelNome;
var
  LFiles: IFolderFiles;
begin
  // OpenXcom asks for its files in any case: on Windows the file system answers the same
  LFiles := Make;
  Assert.IsTrue(LFiles.Exists('onlyfirst.dat'));
  Assert.IsTrue(LFiles.Exists('geodata\Palettes.Dat'));
  Assert.AreEqual('palettes', TextOf(LFiles.ReadAll('GeoData/palettes.DAT')));
end;

procedure TTestPlatformFolderFiles.DovrebbeAccettareLeDueBarreNeiNomi;
var
  LFiles: IFolderFiles;
begin
  LFiles := Make;
  Assert.IsTrue(LFiles.Exists('GEODATA/PALETTES.DAT'));
  Assert.IsTrue(LFiles.Exists('GEODATA\PALETTES.DAT'));
  Assert.AreEqual(FSecond + '\GEODATA\PALETTES.DAT', LFiles.Find('GEODATA/PALETTES.DAT'));
end;

procedure TTestPlatformFolderFiles.UnaCartellaNonDovrebbeEssereUnFile;
begin
  Assert.IsFalse(Make.Exists('GEODATA'));
end;

procedure TTestPlatformFolderFiles.DovrebbeLeggereTuttoIlFile;
begin
  Assert.AreEqual('second', TextOf(Make.ReadAll('ONLYSECOND.DAT')));
end;

procedure TTestPlatformFolderFiles.DovrebbeLeggereUnFileVuoto;
begin
  Assert.AreEqual(0, Integer(Length(Make.ReadAll('EMPTY.DAT'))));
end;

procedure TTestPlatformFolderFiles.DovrebbeAprireUnFlussoDelChiamante;
var
  LStream: TStream;
  LBytes: TBytes;
begin
  LStream := Make.OpenStream('ONLYFIRST.DAT');
  try
    Assert.AreEqual(Int64(5), LStream.Size);
    LStream.Position := 1;
    SetLength(LBytes, 4);
    LStream.ReadBuffer(LBytes[0], 4);
    Assert.AreEqual('irst', TextOf(LBytes));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformFolderFiles.DueFlussiDovrebberoLeggereLoStessoFile;
var
  LFiles: IFolderFiles;
  LOne: TStream;
  LTwo: TStream;
begin
  LFiles := Make;
  LOne := LFiles.OpenStream('BOTH.DAT');
  try
    LTwo := LFiles.OpenStream('BOTH.DAT');
    try
      Assert.AreEqual(LOne.Size, LTwo.Size);
    finally
      LTwo.Free;
    end;
  finally
    LOne.Free;
  end;
end;

procedure TTestPlatformFolderFiles.DovrebbeSollevareSeIlFileManca;
var
  LFiles: IFolderFiles;
begin
  LFiles := Make;
  Assert.WillRaise(
    procedure
    begin
      LFiles.ReadAll('NOWHERE.DAT');
    end, EFolderFileException);
  Assert.WillRaise(
    procedure
    begin
      LFiles.OpenStream('NOWHERE.DAT').Free;
    end, EFolderFileException);
end;

procedure TTestPlatformFolderFiles.DovrebbeSollevareSeIlFileNonSiApre;
var
  LFiles: IFolderFiles;
  LLocked: TFileStream;
begin
  LFiles := Make;
  // somebody else holds the file and lets nobody read it
  LLocked := TFileStream.Create(FFirst + '\ONLYFIRST.DAT', fmOpenReadWrite or fmShareExclusive);
  try
    Assert.IsTrue(LFiles.Exists('ONLYFIRST.DAT'));
    Assert.WillRaise(
      procedure
      begin
        LFiles.ReadAll('ONLYFIRST.DAT');
      end, EFolderFileException);
  finally
    LLocked.Free;
  end;
end;

procedure TTestPlatformFolderFiles.SenzaCartelleNonDovrebbeTrovareNiente;
begin
  Assert.IsFalse(TFolderFilesFactory.CreateFolderFiles([]).Exists('BOTH.DAT'));
end;

procedure TTestPlatformFolderFiles.UnNomeVuotoNonDovrebbeEssereTrovato;
begin
  Assert.IsFalse(Make.Exists(''));
  Assert.IsFalse(TFolderFilesFactory.CreateFileNamesOnly([FFirst]).Exists(''));
end;

procedure TTestPlatformFolderFiles.SoloNomiNonDovrebbeTrovareUnNomeConCartella;
var
  LFiles: IFolderFiles;
begin
  LFiles := TFolderFilesFactory.CreateFileNamesOnly([FFirst, FSecond]);
  Assert.IsFalse(LFiles.Exists('GEODATA\PALETTES.DAT'));
  Assert.IsFalse(LFiles.Exists('GEODATA/PALETTES.DAT'));
  Assert.IsFalse(LFiles.Exists('..\second\BOTH.DAT'));
  Assert.IsFalse(LFiles.Exists(FSecond + '\ONLYSECOND.DAT'), 'un percorso assoluto non e'' un nome');
  // without the rule the same names are found
  Assert.IsTrue(Make.Exists('..\second\ONLYSECOND.DAT'));
end;

procedure TTestPlatformFolderFiles.SoloNomiDovrebbeTrovareUnNomeSemplice;
var
  LFiles: IFolderFiles;
begin
  LFiles := TFolderFilesFactory.CreateFileNamesOnly([FFirst, FSecond]);
  Assert.IsTrue(LFiles.Exists('ONLYSECOND.DAT'));
  Assert.AreEqual('from first', TextOf(LFiles.ReadAll('BOTH.DAT')));
end;

end.
