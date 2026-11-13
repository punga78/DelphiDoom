{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomFolderShaderCatalog and of the display        }
{  filter list of the video options that shows it                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FolderShaderCatalog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.FolderShaderCatalog,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsVideoState,
  DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomEngine.OptionsScreens;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomFolderShaderCatalog = class
  strict private
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FCatalog: IXcomShaderCatalog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeElencareSoloIFileOpenGlShaderInMinuscolo;
    [Test]
    procedure DovrebbeOrdinarePerCodiceDeiCaratteri;
    [Test]
    procedure DovrebbeDareListaVuotaSeLaCartellaNonCE;
    [Test]
    procedure DovrebbeLeggereDalPercorsoDellOpzioneInOgniCaso;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonCE;
    [Test]
    procedure DovrebbeDareFalsoFuoriDallaCartellaDegliShader;
    [Test]
    procedure DovrebbeRifiutareIlFileSystemNil;
  end;

  /// <summary>The display filter list of TXcomOptionsVideoState with a catalog of two shaders</summary>
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomOptionsVideoShaders = class
  strict private
    FWorld: TTestWorld;
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FNavigator: IXcomOptionsNavigator;
    procedure Open;
    procedure ClickFilterRow(ARow: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LoShaderSceltoVaNeiPendentiConOpenGl;
    [Test]
    procedure DisabledSpegneOpenGl;
    [Test]
    procedure UnFiltroSoftwareSpegneOpenGl;
    [Test]
    procedure LaListaApertaMostraGliShader;
    [Test]
    procedure SenzaCatalogoRestanoLeQuattroVoci;
  end;

implementation

const
  SHADERS = 'data\common\Shaders\';

{ TTestXcomFolderShaderCatalog }

procedure TTestXcomFolderShaderCatalog.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FCatalog := TXcomFolderShaderCatalog.Create('data\common', FFilesRef);
end;

procedure TTestXcomFolderShaderCatalog.TearDown;
begin
  FCatalog := nil;
  FFilesRef := nil;
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeElencareSoloIFileOpenGlShaderInMinuscolo;
var
  LFiles: TArray<string>;
begin
  FFiles.Put(SHADERS + 'Raw.OpenGL.shader', 'language: GLSL');
  FFiles.Put(SHADERS + 'Notes.txt', 'x');
  FFiles.Put(SHADERS + 'other.DirectX.shader', 'x');
  // too short: nothing before the dot of the extension
  FFiles.Put(SHADERS + '.OpenGL.shader', 'x');
  FFiles.Put('data\common\Language\en-US.yml', 'x');
  LFiles := FCatalog.Files;
  Assert.AreEqual<Integer>(1, Length(LFiles));
  Assert.AreEqual('raw.opengl.shader', LFiles[0]);
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeOrdinarePerCodiceDeiCaratteri;
var
  LFiles: TArray<string>;
begin
  // the order of the std::set of the lower case names: the dash comes before the dot
  FFiles.Put(SHADERS + 'CRT.OpenGL.shader', 'x');
  FFiles.Put(SHADERS + 'scanline-3x.OpenGL.shader', 'x');
  FFiles.Put(SHADERS + 'CRT-Lottes.OpenGL.shader', 'x');
  FFiles.Put(SHADERS + 'CRT-Lottes-Warp.OpenGL.shader', 'x');
  FFiles.Put(SHADERS + '5xBR_Rounded.OpenGL.shader', 'x');
  FFiles.Put(SHADERS + 'Raw.OpenGL.shader', 'x');
  LFiles := FCatalog.Files;
  Assert.AreEqual('5xbr_rounded.opengl.shader|crt-lottes-warp.opengl.shader|crt-lottes.opengl.shader|' +
    'crt.opengl.shader|raw.opengl.shader|scanline-3x.opengl.shader', string.Join('|', LFiles));
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeDareListaVuotaSeLaCartellaNonCE;
begin
  Assert.AreEqual<Integer>(0, Length(FCatalog.Files));
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeLeggereDalPercorsoDellOpzioneInOgniCaso;
var
  LBytes: TBytes;
begin
  FFiles.Put(SHADERS + 'Raw.OpenGL.shader', 'language: GLSL');
  // the default of the option and what the list of the video options writes
  Assert.IsTrue(FCatalog.TryRead('Shaders/Raw.OpenGL.shader', LBytes));
  Assert.AreEqual('language: GLSL', TEncoding.UTF8.GetString(LBytes));
  Assert.IsTrue(FCatalog.TryRead('Shaders/raw.opengl.shader', LBytes));
  Assert.AreEqual('language: GLSL', TEncoding.UTF8.GetString(LBytes));
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeDareFalsoSeIlFileNonCE;
var
  LBytes: TBytes;
begin
  Assert.IsFalse(FCatalog.TryRead('Shaders/missing.opengl.shader', LBytes));
  Assert.AreEqual<Integer>(0, Length(LBytes));
  Assert.IsFalse(FCatalog.TryRead('', LBytes));
  Assert.IsFalse(FCatalog.TryRead('Shaders/', LBytes));
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeDareFalsoFuoriDallaCartellaDegliShader;
var
  LBytes: TBytes;
begin
  FFiles.Put('data\common\Language\en-US.yml', 'x');
  FFiles.Put('data\common\secret.txt', 'x');
  Assert.IsFalse(FCatalog.TryRead('Language/en-US.yml', LBytes));
  Assert.IsFalse(FCatalog.TryRead('Shaders/../secret.txt', LBytes));
  Assert.IsFalse(FCatalog.TryRead('Shaders/..\secret.txt', LBytes));
  Assert.IsFalse(FCatalog.TryRead('Shaders/C:secret.txt', LBytes));
end;

procedure TTestXcomFolderShaderCatalog.DovrebbeRifiutareIlFileSystemNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomFolderShaderCatalog.Create('data\common', nil);
    end, EArgumentNilException);
end;

{ TTestXcomOptionsVideoShaders }

procedure TTestXcomOptionsVideoShaders.Setup;
begin
  FWorld := TTestWorld.Create;
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FFiles.Put(SHADERS + 'Raw.OpenGL.shader', 'language: GLSL');
  FFiles.Put(SHADERS + 'CRT-simple.OpenGL.shader', 'language: GLSL');
  FNavigator := TFakeNavigator.Create;
  FWorld.Game.SetLanguageProvider(TFolderProviderForScreens.Create);
  FWorld.Game.SetShaderCatalog(TXcomFolderShaderCatalog.Create('data\common', FFilesRef));
end;

procedure TTestXcomOptionsVideoShaders.TearDown;
begin
  FNavigator := nil;
  FWorld.Free;
  FFilesRef := nil;
end;

procedure TTestXcomOptionsVideoShaders.Open;
begin
  // the game owns the state from here; the popups need time to open
  FWorld.Game.PushState(TXcomOptionsVideoState.Create(FWorld.Game, ooMenu, FNavigator));
  FWorld.Wait(400);
end;

procedure TTestXcomOptionsVideoShaders.ClickFilterRow(ARow: Integer);
var
  LScaleX: Double;
  LScaleY: Double;
begin
  // the combo of the filter is at 206,62; its list opens below it, 9 pixels a row from 81
  LScaleX := FWorld.Game.Screen.XScale;
  LScaleY := FWorld.Game.Screen.YScale;
  FWorld.Click(Round(258 * LScaleX), Round(70 * LScaleY));
  FWorld.Click(Round(258 * LScaleX), Round((85 + 9 * ARow) * LScaleY));
  FWorld.Wait(50);
end;

procedure TTestXcomOptionsVideoShaders.LoShaderSceltoVaNeiPendentiConOpenGl;
begin
  Open;
  // Disabled, Scale, HQx, xBRZ, then "Crt Simple*" and "Raw*"
  ClickFilterRow(5);
  Assert.IsTrue(FWorld.Game.Options.NewOpenGL);
  Assert.AreEqual('Shaders/raw.opengl.shader', FWorld.Game.Options.NewOpenGLShader);
  Assert.IsFalse(FWorld.Game.Options.NewScaleFilter);
  Assert.IsFalse(FWorld.Game.Options.UseOpenGL, 'pending until OK');
  ClickFilterRow(4);
  Assert.AreEqual('Shaders/crt-simple.opengl.shader', FWorld.Game.Options.NewOpenGLShader);
end;

procedure TTestXcomOptionsVideoShaders.DisabledSpegneOpenGl;
begin
  FWorld.Game.Options.UseOpenGL := True;
  FWorld.Game.Options.UseOpenGLShader := 'Shaders/raw.opengl.shader';
  FWorld.Game.Options.NewOpenGL := True;
  FWorld.Game.Options.NewOpenGLShader := 'Shaders/raw.opengl.shader';
  Open;
  ClickFilterRow(0);
  Assert.IsFalse(FWorld.Game.Options.NewOpenGL);
  Assert.IsFalse(FWorld.Game.Options.NewScaleFilter);
end;

procedure TTestXcomOptionsVideoShaders.UnFiltroSoftwareSpegneOpenGl;
begin
  FWorld.Game.Options.NewOpenGL := True;
  Open;
  ClickFilterRow(2);
  Assert.IsFalse(FWorld.Game.Options.NewOpenGL);
  Assert.IsTrue(FWorld.Game.Options.NewHQXFilter);
end;

procedure TTestXcomOptionsVideoShaders.LaListaApertaMostraGliShader;
var
  LClosed: TBytes;
  LScaleX: Double;
  LScaleY: Double;
  LX: Integer;
  LY: Integer;
  LChanged: Integer;
begin
  Open;
  LScaleX := FWorld.Game.Screen.XScale;
  LScaleY := FWorld.Game.Screen.YScale;
  LClosed := Copy(FWorld.Game.Screen.DisplayPixels);
  FWorld.Click(Round(258 * LScaleX), Round(70 * LScaleY));
  FWorld.Wait(50);
  // the rows of the two shaders (the fifth and the sixth) are drawn: with four entries the list ends above them
  LChanged := 0;
  for LY := Round(118 * LScaleY) to Round(134 * LScaleY) do
    for LX := Round(210 * LScaleX) to Round(300 * LScaleX) do
      if FWorld.Game.Screen.DisplayPixels[LY * FWorld.Game.Screen.Width + LX] <>
        LClosed[LY * FWorld.Game.Screen.Width + LX] then
        Inc(LChanged);
  Assert.IsTrue(LChanged > 0, 'the list did not reach the rows of the shaders');
end;

procedure TTestXcomOptionsVideoShaders.SenzaCatalogoRestanoLeQuattroVoci;
begin
  FWorld.Game.SetShaderCatalog(nil);
  Open;
  // where the row of a shader would be there is no list: nothing is chosen
  ClickFilterRow(5);
  Assert.IsFalse(FWorld.Game.Options.NewOpenGL);
  ClickFilterRow(1);
  Assert.IsTrue(FWorld.Game.Options.NewScaleFilter);
end;

end.
