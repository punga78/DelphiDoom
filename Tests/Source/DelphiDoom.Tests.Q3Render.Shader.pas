{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - the shader }
{  table (the parsing has its own tests and its parity with the C in           }
{  Tests\DelphiDoom.Tests.Decl)                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Shader;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ShaderRegistry = class
  public
    [Test]
    procedure DovrebbeRegistrareUnoShaderDiUnoScriptEIsuoiStage;
    [Test]
    procedure DovrebbeFareUnoShaderImplicitoDaUnaImmagine;
    [Test]
    procedure DovrebbeDareLoStessoNumeroSenzaMaiuscoleEsenzaEstensione;
    [Test]
    procedure DovrebbeDareZeroPerUnoShaderConUnImmagineMancante;
    [Test]
    procedure DovrebbeNonCaricareLeImmaginiCheIlRendererFaDaSe;
    [Test]
    procedure DovrebbeCaricareLeImmaginiDelCielo;
    [Test]
    procedure DovrebbeDareZeroPerUnNomeVuotoOTroppoLungo;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.IOUtils, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Q3Render.Intf, DelphiDoom.Tests.Q3Render.Support;

const
  SCRIPT =
    'textures/test/two' + #10 + '{' + #10 + '  { map textures/a.tga' + #10 + '    blendFunc add }' + #10 +
    '  { map $lightmap }' + #10 + '}' + #10 +
    'textures/test/missing' + #10 + '{' + #10 + '  { map textures/nowhere.tga }' + #10 + '}' + #10 +
    'textures/test/builtin' + #10 + '{' + #10 + '  { map $whiteimage }' + #10 + '  { map $lightmap }' + #10 + '}' + #10 +
    'textures/test/sky' + #10 + '{' + #10 + '  skyparms textures/sky/env 512 -' + #10 + '}' + #10 +
    'textures/test/anim' + #10 + '{' + #10 + '  { animMap 2 textures/a.tga textures/b.tga }' + #10 + '}' + #10;

function Rig(out AFiles: TMemoryFiles; out ASystem: IQ3RenderSystem; out AKeep: IQ3RenderFiles): Boolean;
var
  LImage: TBytes;
begin
  AFiles := TMemoryFiles.Create;
  AKeep := AFiles;
  LImage := TFile.ReadAllBytes(TTestFiles.FindFileUp('Tests\Data\Q3Render\tga\rgba32.tga'));
  AFiles.Add('textures/a.tga', LImage);
  AFiles.Add('textures/b.tga', LImage);
  AFiles.Add('textures/implicit.tga', LImage);
  AFiles.Add('textures/sky/env_rt.tga', LImage);
  ASystem := TTestSupport.BuildSystem(AKeep, [TPair<string, string>.Create('scripts/test.shader', SCRIPT)]);
  Result := True;
end;

procedure TTestQ3ShaderRegistry.DovrebbeRegistrareUnoShaderDiUnoScriptEIsuoiStage;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LHandle: Integer;
  LShader: TQ3ShaderData;
begin
  Rig(LFiles, LSystem, LKeep);
  LHandle := LSystem.Shaders.Register('textures/test/two');
  Assert.AreEqual(1, LHandle);
  Assert.IsTrue(LSystem.Shaders.GetShader(LHandle, LShader));
  Assert.IsTrue(LShader.ExplicitlyDefined);
  Assert.IsTrue(LShader.Stages[0].Active);
  Assert.AreEqual('textures/a.tga', string(LShader.Stages[0].Bundle.ImageNames[0]));
  Assert.IsTrue(LShader.Stages[1].Bundle.IsLightmap);
  Assert.AreEqual(1, LSystem.Shaders.DefinedCount);
  Assert.AreEqual(0, LSystem.Shaders.ImplicitCount);
  Assert.AreEqual(1, LSystem.Images.LoadedCount, 'a.tga is loaded, the lightmap is not an image');
end;

procedure TTestQ3ShaderRegistry.DovrebbeFareUnoShaderImplicitoDaUnaImmagine;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  Rig(LFiles, LSystem, LKeep);
  // no script names it: the renderer makes a shader with the image of the same name
  Assert.AreEqual(1, LSystem.Shaders.Register('textures/implicit'));
  Assert.AreEqual(1, LSystem.Shaders.ImplicitCount);
  Assert.AreEqual(0, LSystem.Shaders.DefinedCount);
  // and without the image it is the default shader
  Assert.AreEqual(0, LSystem.Shaders.Register('textures/not_there'));
  Assert.AreEqual<Integer>(1, Length(LSystem.Shaders.DefectiveNames));
end;

procedure TTestQ3ShaderRegistry.DovrebbeDareLoStessoNumeroSenzaMaiuscoleEsenzaEstensione;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LFirst: Integer;
begin
  Rig(LFiles, LSystem, LKeep);
  LFirst := LSystem.Shaders.Register('textures/test/two');
  Assert.AreEqual(LFirst, LSystem.Shaders.Register('TEXTURES/TEST/TWO'));
  Assert.AreEqual(LFirst, LSystem.Shaders.Register('textures\test\two'));
  Assert.AreEqual(LFirst, LSystem.Shaders.Register('textures/test/two.tga'));
  Assert.AreEqual(1, LSystem.Shaders.RegisteredCount);
  Assert.AreEqual(2, LSystem.Shaders.Register('textures/implicit'));
end;

procedure TTestQ3ShaderRegistry.DovrebbeDareZeroPerUnoShaderConUnImmagineMancante;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  Rig(LFiles, LSystem, LKeep);
  // ParseStage cannot find the image: the shader is the default one, and RE_RegisterShader answers 0
  Assert.AreEqual(0, LSystem.Shaders.Register('textures/test/missing'));
  Assert.AreEqual(0, LSystem.Shaders.Register('textures/test/missing'));
  Assert.AreEqual<Integer>(1, Length(LSystem.Shaders.DefectiveNames));
  Assert.AreEqual<Integer>(1, Length(LSystem.Images.MissingNames));
  Assert.AreEqual(0, LSystem.Shaders.RegisteredCount);
  // the next good one is still the number 1
  Assert.AreEqual(1, LSystem.Shaders.Register('textures/test/two'));
end;

procedure TTestQ3ShaderRegistry.DovrebbeNonCaricareLeImmaginiCheIlRendererFaDaSe;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  Rig(LFiles, LSystem, LKeep);
  Assert.AreEqual(1, LSystem.Shaders.Register('textures/test/builtin'));
  Assert.AreEqual(0, LFiles.Reads.Count, '$whiteimage and $lightmap are not files');
end;

procedure TTestQ3ShaderRegistry.DovrebbeCaricareLeImmaginiDelCielo;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LHandle: Integer;
  LShader: TQ3ShaderData;
begin
  Rig(LFiles, LSystem, LKeep);
  LHandle := LSystem.Shaders.Register('textures/test/sky');
  Assert.IsTrue(LHandle > 0);
  Assert.IsTrue(LSystem.Shaders.GetShader(LHandle, LShader));
  Assert.IsTrue(LShader.IsSky);
  // one of the six sides is there, the others are missing: not an error for a sky (the C uses the default image)
  Assert.IsTrue(LSystem.Images.LoadedCount >= 1);
  Assert.IsTrue(Length(LSystem.Images.MissingNames) >= 1);
  Assert.AreEqual<Integer>(0, Length(LSystem.Shaders.DefectiveNames));
end;

procedure TTestQ3ShaderRegistry.DovrebbeDareZeroPerUnNomeVuotoOTroppoLungo;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  Rig(LFiles, LSystem, LKeep);
  Assert.AreEqual(0, LSystem.Shaders.Register(''));
  Assert.AreEqual(0, LSystem.Shaders.Register(AnsiString(StringOfChar('x', 64))));
  Assert.AreEqual(0, LSystem.Shaders.RegisteredCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ShaderRegistry);

end.
