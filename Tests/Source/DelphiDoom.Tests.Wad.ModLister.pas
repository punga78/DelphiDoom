{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - file system of id Tech 4, list of   }
{  mods (ListMods)                                                             }
{                                                                              }
{  The expected values come from reading idFileSystemLocal::ListMods of        }
{  framework\FileSystem.cpp of Doom 3; the disk is a script of answers, so     }
{  the order of the folders is the one the test decides.                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.ModLister;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Wad.Fs.Types,
  DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.ModList.Intf;

type
  /// <summary>An IGameDisk that answers what the test says: the folders and files of a folder, and text files</summary>
  TScriptedDisk = class(TInterfacedObject, IGameDisk)
  strict private
    FLists: TDictionary<string, TArray<string>>;
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetFolders(const ADirectory: string; const ANames: TArray<string>);
    procedure SetPaks(const ADirectory: string; const ANames: TArray<string>; const AExtension: string = '.pk4');
    procedure SetFile(const APath: string; const ABytes: TBytes);
    function ListFiles(const ADirectory, AExtension: string): TArray<string>;
    function OpenRead(const AFileName: string): TStream;
    function FileTimestamp(const AFileName: string): Int64;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGameModLister = class(TObject)
  strict private
    FDisk: TScriptedDisk;
    FDiskIntf: IGameDisk;
    FSettings: TGameFsSettings;
    function List(AHasExpansion: Boolean = False): TGameModList;
    class function Join(const AValues: TArray<string>): string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareSoloLaBaseSenzaCartelle;
    [Test]
    procedure DovrebbeElencareLeCartelleConUnPak;
    [Test]
    procedure DovrebbeLasciareFuoriLeCartelleSenzaPak;
    [Test]
    procedure DovrebbeOrdinareIgnorandoLeMaiuscole;
    [Test]
    procedure DovrebbeSaltareBaseEPb;
    [Test]
    procedure DovrebbeElencareLEspansioneSoloSeCeIlPak;
    [Test]
    procedure DovrebbeElencareUnaModUnaVoltaSola;
    [Test]
    procedure DovrebbeSaltareIPercorsiNonImpostati;
    [Test]
    procedure DovrebbeConservareIlDifettoDellElencoDeiPak;
    [Test]
    procedure DovrebbeLeggereLaDescrizioneConIlFineRiga;
    [Test]
    procedure DovrebbeLeggereSoloLaPrimaRiga;
    [Test]
    procedure DovrebbeTogliereIlRitornoACapoDiWindows;
    [Test]
    procedure DovrebbeTroncareLaDescrizioneA255Caratteri;
    [Test]
    procedure DovrebbeUsareLaPrimaDescrizioneTrovata;
    [Test]
    procedure DovrebbeUsareIlNomeSeLaDescrizioneManca;
    [Test]
    procedure DovrebbeUsareIlNomeSeLaDescrizioneEVuota;
    [Test]
    procedure DovrebbeProvareIlPercorsoSuccessivoSeLaDescrizioneEVuota;
    [Test]
    procedure DovrebbeCercareIPakConLEstensioneDelleImpostazioni;
    [Test]
    procedure DovrebbeUsareUnaDescrizioneDellaBasePersonalizzata;
    [Test]
    procedure DovrebbeRifiutareUnDiscoNil;
    [Test]
    procedure DovrebbeElencareDalDiscoVero;
  end;

implementation

uses
  System.IOUtils, Winapi.Windows, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Wad.Fs.ModLister;

{ TScriptedDisk }

constructor TScriptedDisk.Create;
begin
  inherited Create;
  FLists := TDictionary<string, TArray<string>>.Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TScriptedDisk.Destroy;
begin
  FFiles.Free;
  FLists.Free;
  inherited Destroy;
end;

procedure TScriptedDisk.SetFolders(const ADirectory: string; const ANames: TArray<string>);
begin
  FLists.AddOrSetValue(LowerCase(ADirectory) + '|/', ANames);
end;

procedure TScriptedDisk.SetPaks(const ADirectory: string; const ANames: TArray<string>; const AExtension: string);
begin
  FLists.AddOrSetValue(LowerCase(ADirectory) + '|' + AExtension, ANames);
end;

procedure TScriptedDisk.SetFile(const APath: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(APath), ABytes);
end;

function TScriptedDisk.ListFiles(const ADirectory, AExtension: string): TArray<string>;
begin
  if not FLists.TryGetValue(LowerCase(ADirectory) + '|' + AExtension, Result) then
    Result := nil;
end;

function TScriptedDisk.OpenRead(const AFileName: string): TStream;
var
  LBytes: TBytes;
begin
  if FFiles.TryGetValue(LowerCase(AFileName), LBytes) then
    Result := TBytesStream.Create(LBytes)
  else
    Result := nil;
end;

function TScriptedDisk.FileTimestamp(const AFileName: string): Int64;
begin
  Result := 0;
end;

{ TTestGameModLister }

procedure TTestGameModLister.Setup;
begin
  FDisk := TScriptedDisk.Create;
  FDiskIntf := FDisk;
  FSettings := Default(TGameFsSettings);
  FSettings.SavePath := 'C:\save';
  FSettings.BasePath := 'C:\d3';
end;

procedure TTestGameModLister.TearDown;
begin
  FDiskIntf := nil;
  FDisk := nil;
end;

function TTestGameModLister.List(AHasExpansion: Boolean): TGameModList;
begin
  Result := TGameFileSystemFactory.CreateModListerWithDisk(FDiskIntf, FSettings, AHasExpansion).ListMods;
end;

class function TTestGameModLister.Join(const AValues: TArray<string>): string;
begin
  Result := string.Join(',', AValues);
end;

procedure TTestGameModLister.DovrebbeDareSoloLaBaseSenzaCartelle;
var
  LMods: TGameModList;
begin
  LMods := List;
  Assert.AreEqual<Integer>(1, Length(LMods.Mods));
  Assert.AreEqual('', LMods.Mods[0]);
  Assert.AreEqual('Doom 3', LMods.Descriptions[0]);
end;

procedure TTestGameModLister.DovrebbeElencareLeCartelleConUnPak;
var
  LMods: TGameModList;
begin
  FDisk.SetFolders('C:\d3', ['base', 'mymod']);
  FDisk.SetPaks('C:\d3\mymod', ['pak000.pk4']);
  LMods := List;
  Assert.AreEqual(',mymod', Join(LMods.Mods));
  Assert.AreEqual<Integer>(2, Length(LMods.Descriptions));
  // no description.txt: the name of the folder
  Assert.AreEqual('mymod', LMods.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeLasciareFuoriLeCartelleSenzaPak;
begin
  FDisk.SetFolders('C:\d3', ['nopak']);
  Assert.AreEqual('', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeOrdinareIgnorandoLeMaiuscole;
begin
  FDisk.SetFolders('C:\d3', ['Zeta', 'alpha', 'Beta']);
  FDisk.SetPaks('C:\d3\Zeta', ['a.pk4']);
  FDisk.SetPaks('C:\d3\alpha', ['a.pk4']);
  FDisk.SetPaks('C:\d3\Beta', ['a.pk4']);
  Assert.AreEqual(',alpha,Beta,Zeta', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeSaltareBaseEPb;
begin
  FDisk.SetFolders('C:\d3', ['base', 'pb', 'mod']);
  FDisk.SetPaks('C:\d3\base', ['a.pk4']);
  FDisk.SetPaks('C:\d3\pb', ['a.pk4']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  Assert.AreEqual(',mod', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeElencareLEspansioneSoloSeCeIlPak;
begin
  FDisk.SetFolders('C:\d3', ['D3XP']);
  FDisk.SetPaks('C:\d3\D3XP', ['a.pk4']);
  Assert.AreEqual('', Join(List(False).Mods));
  Assert.AreEqual(',D3XP', Join(List(True).Mods));
end;

procedure TTestGameModLister.DovrebbeElencareUnaModUnaVoltaSola;
begin
  FSettings.CdPath := 'C:\cd';
  FDisk.SetFolders('C:\save', ['mod']);
  FDisk.SetPaks('C:\save\mod', ['a.pk4']);
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFolders('C:\cd', ['mod']);
  FDisk.SetPaks('C:\cd\mod', ['a.pk4']);
  Assert.AreEqual(',mod', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeSaltareIPercorsiNonImpostati;
begin
  // the dev path and the cd path are empty: nothing is listed for them
  FDisk.SetFolders('', ['ghost']);
  FDisk.SetPaks('ghost', ['a.pk4']);
  Assert.AreEqual('', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeConservareIlDifettoDellElencoDeiPak;
begin
  // the list of paks is cleared once per path, so after the folder with a pak every folder of the path
  // counts as a mod, even the one that has none ("zz" has no pak)
  FDisk.SetFolders('C:\d3', ['aa', 'zz']);
  FDisk.SetPaks('C:\d3\aa', ['a.pk4']);
  Assert.AreEqual(',aa,zz', Join(List.Mods));
  // in the other order the folder without a pak comes first and is left out
  FDisk.SetFolders('C:\d3', ['zz', 'aa']);
  Assert.AreEqual(',aa', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeLeggereLaDescrizioneConIlFineRiga;
var
  LMods: TGameModList;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('My mod' + #10));
  LMods := List;
  // fgets keeps the line feed
  Assert.AreEqual('My mod' + #10, LMods.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeLeggereSoloLaPrimaRiga;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('first' + #10 + 'second'));
  Assert.AreEqual('first' + #10, List.Descriptions[1]);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('only line'));
  Assert.AreEqual('only line', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeTogliereIlRitornoACapoDiWindows;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('one' + #13#10 + 'two'));
  Assert.AreEqual('one' + #10, List.Descriptions[1]);
  // a lone carriage return stays
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('a' + #13 + 'b'));
  Assert.AreEqual('a' + #13 + 'b', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeTroncareLaDescrizioneA255Caratteri;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes(StringOfChar('x', 300)));
  Assert.AreEqual<Integer>(255, Length(List.Descriptions[1]));
end;

procedure TTestGameModLister.DovrebbeUsareLaPrimaDescrizioneTrovata;
begin
  FSettings.DevPath := 'C:\dev';
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  // the order is save, dev, base, cd
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('from base'));
  FDisk.SetFile('C:\dev\mod\description.txt', TEncoding.UTF8.GetBytes('from dev'));
  Assert.AreEqual('from dev', List.Descriptions[1]);
  FDisk.SetFile('C:\save\mod\description.txt', TEncoding.UTF8.GetBytes('from save'));
  Assert.AreEqual('from save', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeUsareIlNomeSeLaDescrizioneManca;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  Assert.AreEqual('mod', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeUsareIlNomeSeLaDescrizioneEVuota;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\d3\mod\description.txt', nil);
  Assert.AreEqual('mod', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeProvareIlPercorsoSuccessivoSeLaDescrizioneEVuota;
begin
  FDisk.SetFolders('C:\d3', ['mod']);
  FDisk.SetPaks('C:\d3\mod', ['a.pk4']);
  FDisk.SetFile('C:\save\mod\description.txt', nil);
  FDisk.SetFile('C:\d3\mod\description.txt', TEncoding.UTF8.GetBytes('base text'));
  Assert.AreEqual('base text', List.Descriptions[1]);
end;

procedure TTestGameModLister.DovrebbeCercareIPakConLEstensioneDelleImpostazioni;
begin
  FSettings.PakExtension := '.pk3';
  FDisk.SetFolders('C:\d3', ['quakemod']);
  FDisk.SetPaks('C:\d3\quakemod', ['a.pk4']);
  Assert.AreEqual('', Join(List.Mods), 'a .pk4 is not a pak of this game');
  FDisk.SetPaks('C:\d3\quakemod', ['a.pk3'], '.pk3');
  Assert.AreEqual(',quakemod', Join(List.Mods));
end;

procedure TTestGameModLister.DovrebbeUsareUnaDescrizioneDellaBasePersonalizzata;
var
  LLister: IGameModLister;
begin
  LLister := TGameModLister.Create(FDiskIntf, FSettings, False, 'Quake');
  Assert.AreEqual('Quake', LLister.ListMods.Descriptions[0]);
end;

procedure TTestGameModLister.DovrebbeRifiutareUnDiscoNil;
begin
  Assert.WillRaise(procedure begin TGameModLister.Create(nil, FSettings); end, EArgumentNilException);
end;

procedure TTestGameModLister.DovrebbeElencareDalDiscoVero;
var
  LFolder: string;
  LSettings: TGameFsSettings;
  LMods: TGameModList;
begin
  LFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'dd_fs_mods_' + IntToStr(GetCurrentProcessId);
  ForceDirectories(LFolder + '\mymod');
  ForceDirectories(LFolder + '\empty');
  try
    TFile.WriteAllBytes(LFolder + '\mymod\pak000.pk4', [1, 2, 3]);
    TFile.WriteAllText(LFolder + '\mymod\description.txt', 'Real mod', TEncoding.ASCII);
    LSettings := Default(TGameFsSettings);
    LSettings.BasePath := LFolder;
    LMods := TGameFileSystemFactory.CreateModListerOnDisk(LSettings).ListMods;
    Assert.AreEqual(',mymod', Join(LMods.Mods));
    Assert.AreEqual('Real mod', LMods.Descriptions[1]);
  finally
    TDirectory.Delete(LFolder, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameModLister);

end.
