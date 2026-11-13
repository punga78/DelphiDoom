{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager over the file system of        }
{  id Tech 4 (folders, PK4 and PK3, writing, reload) and the factory           }
{                                                                              }
{  The file system is the real one of Libs\Wad on a disk in memory (and, for   }
{  the factories on the disk of the machine, in a folder that each test makes  }
{  and removes); there is no file of any game.                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.GameFsManager;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Wad.Fs.Types,
  DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Tests.Scanner.IdFakes,
  DelphiDoom.Tests.Wad.MemoryWriteDisk;

type
  [TestFixture]
  [Category('decl')]
  TTestDeclOnFileSystem = class(TObject)
  strict private
    FDisk: TMemoryWriteDisk;
    FDiskRead: IGameDisk;
    FDiskWrite: IGameDiskWriter;
    FSettings: TGameFsSettings;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FSystem: IGameFileSystem;
    FManager: IDeclManager;
    function StartManager(AWithWriter: Boolean = True): IDeclManager;
    function NewManager: IDeclManager;
    function StateOf(const ADecl: IDecl): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeDichiarazioniDaUnaCartella;
    [Test]
    procedure DovrebbeLeggereLeDichiarazioniDaUnPak;
    [Test]
    procedure DovrebbeLeggereLeSottocartelleDiUnPak;
    [Test]
    procedure DovrebbeFarVincereLaCartellaSulPak;
    [Test]
    procedure DovrebbeFarVincereIlPakDopoSulPakPrima;
    [Test]
    procedure DovrebbeLeggereIFileDiPiuCartelleDelGioco;
    [Test]
    procedure DovrebbeLeggereLeCartelleStandard;
    [Test]
    procedure DovrebbeSalvareUnaDichiarazioneNuova;
    [Test]
    procedure DovrebbeSalvareUnaDichiarazioneModificata;
    [Test]
    procedure DovrebbeAvvisareSeNonPuoScrivere;
    [Test]
    procedure DovrebbeRicaricareUnFileCheCambia;
    [Test]
    procedure DovrebbeNonRicaricareUnFileInUnPak;
    [Test]
    procedure DovrebbeLeggereGliShaderDiQuakeIIIDaUnPk3;
    [Test]
    procedure DovrebbeFarVincereLaCartellaSulPk3PerGliShader;
    [Test]
    procedure DovrebbeLeggereGliShaderDelleSottocartelle;
    [Test]
    procedure DovrebbeNonRegistrareITipiDiDoom3PerGliShader;
    [Test]
    procedure DovrebbeCostruireLaSorgenteDallaFabbrica;
    [Test]
    procedure DovrebbeCostruireIlGestoreSuDiscoVero;
    [Test]
    procedure DovrebbeCostruireIlGestoreDegliShaderSuDiscoVero;
  end;

implementation

uses
  System.IOUtils, Winapi.Windows, DelphiDoom.Decl.Types, DelphiDoom.Decl.Factory, DelphiDoom.Decl.Source.Intf,
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Intf, DelphiDoom.Wad.Fs.Factory,
  DelphiDoom.Tests.Wad.MemoryDisk;

const
  DEF_A = 'entityDef monster_a' + #13#10 + '{' + #13#10 + '  "health" "100"' + #13#10 + '}' + #13#10;

function EntityText(const AName, AHealth: string): string;
begin
  Result := 'entityDef ' + AName + #10 + '{' + #10 + '  "health" "' + AHealth + '"' + #10 + '}' + #10;
end;

{ TTestDeclOnFileSystem }

procedure TTestDeclOnFileSystem.Setup;
begin
  FDisk := TMemoryWriteDisk.Create;
  FDiskRead := FDisk;
  FDiskWrite := FDisk;
  FSettings := Default(TGameFsSettings);
  FSettings.BasePath := 'C:\d3';
  FSettings.DevPath := 'C:\dev';
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
end;

procedure TTestDeclOnFileSystem.TearDown;
begin
  FManager := nil;
  FSystem := nil;
  FLog := nil;
  FLogObject := nil;
  FDiskWrite := nil;
  FDiskRead := nil;
  FDisk := nil;
end;

function TTestDeclOnFileSystem.NewManager: IDeclManager;
begin
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  Result := TDeclFactory.CreateStandardManagerOnFileSystem(FSystem,
    TGameFileSystemFactory.CreateWriterWithDisk(FDiskWrite, FSystem, FSettings), FLog);
  Result.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
end;

function TTestDeclOnFileSystem.StartManager(AWithWriter: Boolean): IDeclManager;
begin
  if AWithWriter then
    FManager := NewManager
  else
  begin
    FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
    FSystem.Startup;
    FManager := TDeclFactory.CreateStandardManagerOnFileSystem(FSystem, nil, FLog);
    FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  end;
  Result := FManager;
end;

function TTestDeclOnFileSystem.StateOf(const ADecl: IDecl): Integer;
begin
  Result := Ord(ADecl.GetState);
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereLeDichiarazioniDaUnaCartella;
var
  LDecl: IDecl;
begin
  FDisk.AddText('C:\d3\base\def\a.def', DEF_A);
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  Assert.IsNotNull(LDecl);
  Assert.AreEqual(Ord(dsParsed), StateOf(LDecl));
  Assert.AreEqual('def/a.def', string(LDecl.GetFileName));
  Assert.IsTrue(string(LDecl.GetText).Contains('"health" "100"'));
  Assert.AreEqual(1, FManager.GetNumDecls(DECL_ENTITYDEF));
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereLeDichiarazioniDaUnPak;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['def/p.def'], [EntityText('monster_p', '5')]));
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_p', False);
  Assert.IsNotNull(LDecl);
  Assert.AreEqual(Ord(dsParsed), StateOf(LDecl));
  Assert.IsTrue(string(LDecl.GetText).Contains('"5"'));
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereLeSottocartelleDiUnPak;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['def/sub/deep/b.def', 'def/sub/deep/', 'def/sub/', 'def/'],
    [EntityText('monster_b', '7'), '', '', '']));
  Assert.IsNotNull(StartManager.FindType(DECL_ENTITYDEF, 'monster_b', False));
  Assert.AreEqual('def/sub/deep/b.def', string(FManager.FindType(DECL_ENTITYDEF, 'monster_b', False).GetFileName));
end;

procedure TTestDeclOnFileSystem.DovrebbeFarVincereLaCartellaSulPak;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['def/a.def'], [EntityText('monster_a', 'from pak')]));
  FDisk.AddText('C:\d3\base\def\a.def', EntityText('monster_a', 'loose'));
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  Assert.IsTrue(string(LDecl.GetText).Contains('loose'));
  // the file is listed once: no decl is defined twice
  Assert.AreEqual(1, FManager.GetNumDecls(DECL_ENTITYDEF));
  Assert.IsFalse(FLogObject.Lines.Text.Contains('redefine'), FLogObject.Lines.Text);
end;

procedure TTestDeclOnFileSystem.DovrebbeFarVincereIlPakDopoSulPakPrima;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['def/a.def'], [EntityText('monster_a', 'zero')]));
  FDisk.AddFile('C:\d3\base\pak001.pk4', TMemoryZip.Make(['def/a.def'], [EntityText('monster_a', 'one')]));
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  Assert.IsTrue(string(LDecl.GetText).Contains('"one"'));
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereIFileDiPiuCartelleDelGioco;
begin
  FSettings.Game := 'mod';
  FDisk.AddText('C:\d3\base\def\a.def', EntityText('monster_a', '1'));
  FDisk.AddText('C:\d3\mod\def\b.def', EntityText('monster_b', '2'));
  StartManager;
  Assert.IsNotNull(FManager.FindType(DECL_ENTITYDEF, 'monster_a', False));
  Assert.IsNotNull(FManager.FindType(DECL_ENTITYDEF, 'monster_b', False));
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereLeCartelleStandard;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['skins/a.skin', 'materials/m.mtr'],
    ['skin skin_a { }', 'textures/test/m { diffusemap textures/test/m }']));
  StartManager;
  LDecl := FManager.FindType(DECL_SKIN, 'skin_a', False);
  Assert.IsNotNull(LDecl);
  Assert.AreEqual('skins/a.skin', string(LDecl.GetFileName));
  Assert.IsNotNull(FManager.FindType(DECL_MATERIAL, 'textures/test/m', False));
end;

procedure TTestDeclOnFileSystem.DovrebbeSalvareUnaDichiarazioneNuova;
var
  LDecl: IDecl;
  LOther: IDeclManager;
begin
  StartManager;
  LDecl := FManager.CreateNewDecl(DECL_ENTITYDEF, 'newthing', 'def/new.def');
  Assert.IsTrue(LDecl.ReplaceSourceFileText);
  // the file goes to the dev path, below the game folder
  Assert.IsTrue(FDisk.ReadText('C:\dev\base\def\new.def').Contains('entityDef newthing'));
  // another manager over the same disk reads it back
  LOther := NewManager;
  LDecl := LOther.FindType(DECL_ENTITYDEF, 'newthing', False);
  Assert.IsNotNull(LDecl);
  Assert.AreEqual(Ord(dsParsed), StateOf(LDecl));
  Assert.AreEqual('def/new.def', string(LDecl.GetFileName));
end;

procedure TTestDeclOnFileSystem.DovrebbeSalvareUnaDichiarazioneModificata;
var
  LDecl: IDecl;
  LOther: IDeclManager;
  LBefore: string;
begin
  FDisk.AddText('C:\d3\base\def\two.def', EntityText('monster_one', '1') + EntityText('monster_two', '2'));
  StartManager;
  LDecl := FManager.FindType(DECL_ENTITYDEF, 'monster_one', False);
  LDecl.SetText('entityDef monster_one { "health" "999" }');
  Assert.IsTrue(LDecl.ReplaceSourceFileText);
  // the original file in the base folder is not touched
  LBefore := FDisk.ReadText('C:\d3\base\def\two.def');
  Assert.IsTrue(LBefore.Contains('"1"'));
  LOther := NewManager;
  Assert.IsTrue(string(LOther.FindType(DECL_ENTITYDEF, 'monster_one', False).GetText).Contains('999'));
  Assert.IsTrue(string(LOther.FindType(DECL_ENTITYDEF, 'monster_two', False).GetText).Contains('"2"'));
end;

procedure TTestDeclOnFileSystem.DovrebbeAvvisareSeNonPuoScrivere;
var
  LDecl: IDecl;
begin
  StartManager(False);
  LDecl := FManager.CreateNewDecl(DECL_ENTITYDEF, 'newthing', 'def/new.def');
  Assert.IsFalse(LDecl.ReplaceSourceFileText);
  Assert.IsTrue(FLogObject.Lines.Text.Contains('for writing'), FLogObject.Lines.Text);
  Assert.IsFalse(FDisk.Exists('C:\dev\base\def\new.def'));
  // a disk that cannot be written is the same
  FLogObject.Lines.Clear;
  FManager := NewManager;
  FDisk.Refuse := True;
  LDecl := FManager.CreateNewDecl(DECL_ENTITYDEF, 'other', 'def/other.def');
  Assert.IsFalse(LDecl.ReplaceSourceFileText);
  Assert.IsTrue(FLogObject.Lines.Text.Contains('for writing'), FLogObject.Lines.Text);
end;

procedure TTestDeclOnFileSystem.DovrebbeRicaricareUnFileCheCambia;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\def\a.def', TMemoryZip.Bytes(EntityText('monster_a', 'old')), 100);
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  Assert.IsTrue(string(LDecl.GetText).Contains('old'));
  FDisk.AddFile('C:\d3\base\def\a.def', TMemoryZip.Bytes(EntityText('monster_a', 'new')), 200);
  FManager.Reload(False);
  Assert.IsTrue(string(FManager.FindType(DECL_ENTITYDEF, 'monster_a', False).GetText).Contains('new'));
end;

procedure TTestDeclOnFileSystem.DovrebbeNonRicaricareUnFileInUnPak;
var
  LDecl: IDecl;
begin
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['def/a.def'], [EntityText('monster_a', 'old')]));
  LDecl := StartManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  FManager.Reload(False);
  // the time of a file in a pak is 0, so nothing changed (as in the original)
  Assert.IsTrue(string(FManager.FindType(DECL_ENTITYDEF, 'monster_a', False).GetText).Contains('old'));
  Assert.IsFalse(LDecl.SourceFileChanged);
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereGliShaderDiQuakeIIIDaUnPk3;
var
  LDecl: IDecl;
  LShader: IDeclQ3Shader;
begin
  FSettings.Game := 'baseq3';
  FSettings.PakExtension := '.pk3';
  FDisk.AddFile('C:\d3\baseq3\pak0.pk3', TMemoryZip.Make(['scripts/test.shader'],
    ['textures/test/a' + #13#10 + '{' + #13#10 + '  {' + #13#10 + '    map $lightmap' + #13#10 + '  }' + #13#10 +
     '  {' + #13#10 + '    map textures/test/a.tga' + #13#10 + '    blendFunc filter' + #13#10 + '  }' + #13#10 + '}' + #13#10]));
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  FManager := TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(FSystem, nil, FLog);
  LDecl := FManager.FindType(DECL_Q3SHADER, 'textures/test/a', False);
  Assert.IsNotNull(LDecl);
  Assert.IsTrue(Supports(LDecl, IDeclQ3Shader, LShader));
  Assert.AreEqual(2, LShader.GetStageCount);
  Assert.IsTrue(LShader.IsExplicitlyDefined);
  Assert.AreEqual('scripts/test.shader', string(LDecl.GetFileName));
end;

procedure TTestDeclOnFileSystem.DovrebbeFarVincereLaCartellaSulPk3PerGliShader;
var
  LShader: IDeclQ3Shader;
begin
  FSettings.Game := 'baseq3';
  FSettings.PakExtension := '.pk3';
  FDisk.AddFile('C:\d3\baseq3\pak0.pk3', TMemoryZip.Make(['scripts/test.shader'],
    ['textures/test/a { { map textures/one.tga } }']));
  FDisk.AddText('C:\d3\baseq3\scripts\test.shader', 'textures/test/a { { map textures/one.tga } { map textures/two.tga } }');
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  FManager := TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(FSystem, nil, FLog);
  Assert.IsTrue(Supports(FManager.FindType(DECL_Q3SHADER, 'textures/test/a', False), IDeclQ3Shader, LShader));
  Assert.AreEqual(2, LShader.GetStageCount);
end;

procedure TTestDeclOnFileSystem.DovrebbeLeggereGliShaderDelleSottocartelle;
begin
  FSettings.Game := 'baseq3';
  FSettings.PakExtension := '.pk3';
  FDisk.AddFile('C:\d3\baseq3\pak0.pk3', TMemoryZip.Make(['scripts/sub/more.shader', 'scripts/sub/', 'scripts/top.shader'],
    ['textures/test/deep { { map textures/deep.tga } }', '', 'textures/test/top { { map textures/top.tga } }']));
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  FManager := TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(FSystem, nil, FLog);
  Assert.AreEqual(2, FManager.GetNumDecls(DECL_Q3SHADER));
  Assert.AreEqual('scripts/sub/more.shader', string(FManager.FindType(DECL_Q3SHADER, 'textures/test/deep', False).GetFileName));
end;

procedure TTestDeclOnFileSystem.DovrebbeNonRegistrareITipiDiDoom3PerGliShader;
begin
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  FManager := TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(FSystem, nil, FLog);
  Assert.AreEqual(DECL_Q3SHADER, FManager.GetRegistry.GetDeclTypeFromName('shader'));
  Assert.AreEqual(DECL_MAX_TYPES, FManager.GetRegistry.GetDeclTypeFromName('material'));
  Assert.AreEqual(DECL_MAX_TYPES, FManager.GetRegistry.GetDeclTypeFromName('entityDef'));
end;

procedure TTestDeclOnFileSystem.DovrebbeCostruireLaSorgenteDallaFabbrica;
var
  LSource: IDeclSource;
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FDisk.AddText('C:\d3\base\a.txt', 'hello');
  FSystem := TGameFileSystemFactory.CreateWithDisk(FDiskRead, FSettings);
  FSystem.Startup;
  LSource := TDeclFactory.CreateFileSystemSource(FSystem);
  Assert.IsTrue(LSource.TryReadFile('a.txt', LText, LTimestamp));
  Assert.AreEqual('hello', string(LText));
  // without a writer the source is read only
  Assert.IsFalse(LSource.WriteFile('b.txt', 'x'));
end;

procedure TTestDeclOnFileSystem.DovrebbeCostruireIlGestoreSuDiscoVero;
var
  LFolder: string;
  LSettings: TGameFsSettings;
  LDecl: IDecl;
begin
  LFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'dd_decl_fs_' + IntToStr(GetCurrentProcessId);
  ForceDirectories(LFolder + '\base\def');
  try
    TFile.WriteAllText(LFolder + '\base\def\a.def', EntityText('monster_a', '3'), TEncoding.ASCII);
    LSettings := Default(TGameFsSettings);
    LSettings.BasePath := LFolder;
    LSettings.SavePath := LFolder + '\save';
    FManager := TDeclFactory.CreateStandardManagerOnDisk(LSettings, FLog);
    FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
    LDecl := FManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
    Assert.IsNotNull(LDecl);
    // a new decl is saved below the save path (the dev path is not set)
    LDecl := FManager.CreateNewDecl(DECL_ENTITYDEF, 'saved', 'def/saved.def');
    Assert.IsTrue(LDecl.ReplaceSourceFileText);
    Assert.IsTrue(FileExists(LFolder + '\save\base\def\saved.def'));
    FManager := nil;
  finally
    TDirectory.Delete(LFolder, True);
  end;
end;

procedure TTestDeclOnFileSystem.DovrebbeCostruireIlGestoreDegliShaderSuDiscoVero;
var
  LFolder: string;
  LSettings: TGameFsSettings;
  LShader: IDeclQ3Shader;
begin
  LFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'dd_decl_q3_' + IntToStr(GetCurrentProcessId);
  ForceDirectories(LFolder + '\baseq3\scripts');
  try
    TFile.WriteAllText(LFolder + '\baseq3\scripts\a.shader', 'textures/test/a { { map textures/a.tga } }', TEncoding.ASCII);
    LSettings := Default(TGameFsSettings);
    LSettings.BasePath := LFolder;
    LSettings.Game := 'baseq3';
    LSettings.PakExtension := '.pk3';
    FManager := TDeclFactory.CreateQuake3ShaderManagerOnDisk(LSettings, FLog);
    Assert.IsTrue(Supports(FManager.FindType(DECL_Q3SHADER, 'textures/test/a', False), IDeclQ3Shader, LShader));
    Assert.AreEqual(1, LShader.GetStageCount);
    FManager := nil;
  finally
    TDirectory.Delete(LFolder, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclOnFileSystem);

end.
