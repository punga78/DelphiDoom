{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRecentFiles and TToolPathText                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.RecentFiles;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   The MRU and SHORT lines of Tests\Data\ToolsCore\old.golden.txt were written by TFileMenuHistory
  ///   and MkShortName of ENDEDIT (ee_filemenuhistory, ee_utils). The old list kept 9 files, so the
  ///   parity runs with a limit of 9
  /// </summary>
  [TestFixture]
  [Category('toolscore')]
  TTestToolsRecentFiles = class(TObject)
  strict private
    FFiles: IRecentFiles;
    function Join(const AFiles: IRecentFiles): string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeMettereInCimaIUltimiFile;
    [Test]
    procedure DovrebbeSpostareInCimaUnFileGiaPresente;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNelConfrontoDeiPercorsi;
    [Test]
    procedure DovrebbeIgnorareIPercorsiVuoti;
    [Test]
    procedure DovrebbeTenereSoloIlNumeroDiFileDelLimite;
    [Test]
    procedure DovrebbeTogliereUnFile;
    [Test]
    procedure DovrebbeSvuotareLaLista;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDalLimite;
    [Test]
    procedure DovrebbeRifiutareUnLimiteZero;
    [Test]
    procedure DovrebbeScrivereLaDidascaliaDelMenu;
    [Test]
    procedure DovrebbeSalvareERileggereLaListaDalleImpostazioni;
    [Test]
    procedure DovrebbeLeggereUnaListaConDeiBuchi;
    [Test]
    procedure DovrebbeDareLeStesseListeDelVecchioCodice;
    [Test]
    procedure DovrebbeAccorciareICamminiCometteIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.RecentFiles, DelphiDoom.Tools.PathText, DelphiDoom.Tools.Types,
  DelphiDoom.Tests.ToolsCore.Fakes;

{ TTestToolsRecentFiles }

procedure TTestToolsRecentFiles.Setup;
begin
  FFiles := TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT);
end;

function TTestToolsRecentFiles.Join(const AFiles: IRecentFiles): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AFiles.Count - 1 do
    Result := Result + '|' + AFiles[LIndex];
end;

procedure TTestToolsRecentFiles.DovrebbeMettereInCimaIUltimiFile;
begin
  FFiles.Add('a');
  FFiles.Add('b');
  Assert.AreEqual('|b|a', Join(FFiles));
end;

procedure TTestToolsRecentFiles.DovrebbeSpostareInCimaUnFileGiaPresente;
begin
  FFiles.Add('a');
  FFiles.Add('b');
  FFiles.Add('a');
  Assert.AreEqual('|a|b', Join(FFiles));
end;

procedure TTestToolsRecentFiles.DovrebbeIgnorareLeMaiuscoleNelConfrontoDeiPercorsi;
begin
  FFiles.Add('C:\A.BIN');
  FFiles.Add('c:\a.bin');
  Assert.AreEqual(1, FFiles.Count);
  Assert.AreEqual('c:\a.bin', FFiles[0]);
end;

procedure TTestToolsRecentFiles.DovrebbeIgnorareIPercorsiVuoti;
begin
  FFiles.Add('');
  FFiles.Add('   ');
  FFiles.Add('  x  ');
  Assert.AreEqual('|x', Join(FFiles));
end;

procedure TTestToolsRecentFiles.DovrebbeTenereSoloIlNumeroDiFileDelLimite;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 12 do
    FFiles.Add(IntToStr(LIndex));
  Assert.AreEqual(TOOLS_RECENT_FILES_LIMIT, FFiles.Count);
  Assert.AreEqual('12', FFiles[0]);
  Assert.AreEqual('3', FFiles[TOOLS_RECENT_FILES_LIMIT - 1]);
end;

procedure TTestToolsRecentFiles.DovrebbeTogliereUnFile;
begin
  FFiles.Add('a');
  FFiles.Add('b');
  FFiles.Remove(' A ');
  FFiles.Remove('zzz');
  Assert.AreEqual('|b', Join(FFiles));
end;

procedure TTestToolsRecentFiles.DovrebbeSvuotareLaLista;
begin
  FFiles.Add('a');
  FFiles.Clear;
  Assert.AreEqual(0, FFiles.Count);
end;

procedure TTestToolsRecentFiles.DovrebbeRifiutareUnIndiceFuoriDalLimite;
begin
  FFiles.Add('a');
  Assert.WillRaise(
    procedure
    begin
      FFiles[1];
    end, EToolsException);
  Assert.WillRaise(
    procedure
    begin
      FFiles[-1];
    end, EToolsException);
end;

procedure TTestToolsRecentFiles.DovrebbeRifiutareUnLimiteZero;
begin
  Assert.WillRaise(
    procedure
    begin
      TRecentFiles.Create(0).Free;
    end, EToolsException);
end;

procedure TTestToolsRecentFiles.DovrebbeScrivereLaDidascaliaDelMenu;
begin
  FFiles.Add('C:\corto.bin');
  FFiles.Add('C:\una cartella molto lunga\con altre cartelle\e un file.bin');
  Assert.AreEqual('&1. C:\...re cartelle\e un file.bin', FFiles.MenuCaption(0));
  Assert.AreEqual('&2. C:\corto.bin', FFiles.MenuCaption(1));
end;

procedure TTestToolsRecentFiles.DovrebbeSalvareERileggereLaListaDalleImpostazioni;
var
  LSettings: ISettingsStore;
  LOther: IRecentFiles;
  LFileSystem: TFakeToolFileSystem;
begin
  LFileSystem := TFakeToolFileSystem.Create;
  LSettings := TToolsFactory.CreateSettings(LFileSystem, 'x.ini');
  FFiles.Add('a');
  FFiles.Add('b');
  FFiles.Add('c');
  FFiles.SaveTo(LSettings, 'File Menu History');
  Assert.AreEqual('c', LSettings.ReadString('File Menu History', 'FILEMENUHISTORY0', ''));
  Assert.AreEqual('', LSettings.ReadString('File Menu History', 'FILEMENUHISTORY3', 'x'));
  LOther := TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT);
  LOther.LoadFrom(LSettings, 'File Menu History');
  Assert.AreEqual('|c|b|a', Join(LOther));
end;

procedure TTestToolsRecentFiles.DovrebbeLeggereUnaListaConDeiBuchi;
var
  LSettings: ISettingsStore;
begin
  LSettings := TToolsFactory.CreateSettings(TFakeToolFileSystem.Create, 'x.ini');
  LSettings.WriteString('H', 'FILEMENUHISTORY0', 'uno');
  LSettings.WriteString('H', 'FILEMENUHISTORY4', 'due');
  FFiles.Add('prima');
  FFiles.LoadFrom(LSettings, 'H');
  Assert.AreEqual('|uno|due', Join(FFiles));
end;

procedure TTestToolsRecentFiles.DovrebbeDareLeStesseListeDelVecchioCodice;
const
  PATHS: array[0..15] of string = (
    'C:\a.bin', 'C:\b.bin', 'c:\A.BIN', 'D:\x\y\z.bin', '  ', '', ' C:\b.bin ', 'E:\1', 'E:\2', 'E:\3',
    'E:\4', 'E:\5', 'E:\6', 'E:\7', 'E:\8', 'E:\9');
  SCRIPTS: array[0..4] of string = (
    '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15',
    '0 1 0 1 2 2 3 4 5 6 7 8 9 10 11 12 13 14 15 3 0',
    '4 5 6 4 4 4 15 14 13 12 11 10 9 8 7 6 5 0',
    '0 2 0 2 0 6 1 6 1 7',
    '15 14 13 12 11 10 9 8 7 3 4 5 6');
var
  LGolden: TArray<string>;
  LFiles: IRecentFiles;
  LOperations: TStringList;
  LScript: Integer;
  LStep: Integer;
  LCount: Integer;
  LLine: string;
  LIndex: Integer;
begin
  LGolden := TToolsGolden.Lines('ToolsCore\old.golden.txt', 'MRU');
  LOperations := TStringList.Create;
  try
    LOperations.Delimiter := ' ';
    LCount := 0;
    for LScript := 0 to High(SCRIPTS) do
    begin
      LFiles := TToolsFactory.CreateRecentFiles(9);
      LOperations.DelimitedText := SCRIPTS[LScript];
      for LStep := 0 to LOperations.Count - 1 do
      begin
        LFiles.Add(PATHS[StrToInt(LOperations[LStep])]);
        LLine := Format('%d.%d', [LScript, LStep]);
        for LIndex := 0 to 9 do
          if LIndex < LFiles.Count then
            LLine := LLine + '|' + LFiles[LIndex]
          else
            LLine := LLine + '|';
        Assert.AreEqual(LGolden[LCount], LLine);
        Inc(LCount);
      end;
    end;
    Assert.AreEqual(Length(LGolden), LCount);
  finally
    LOperations.Free;
  end;
end;

procedure TTestToolsRecentFiles.DovrebbeAccorciareICamminiCometteIlVecchioCodice;
var
  LGolden: TArray<string>;
  LName: string;
  LLength: Integer;
begin
  LGolden := TToolsGolden.Lines('ToolsCore\old.golden.txt', 'SHORT');
  LName := '';
  for LLength := 0 to 60 do
  begin
    Assert.AreEqual(LGolden[LLength],
      Format('%d [%s]', [LLength, TToolPathText.Shorten(LName, TOOLS_SHORT_NAME_LIMIT)]));
    LName := LName + Chr(Ord('a') + (LLength mod 26));
  end;
end;

end.
