{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration library - the collapses of FinishShader }
{  on data built by hand (the branches the golden of the real tr_shader.c      }
{  does not reach: it always reads with LIGHTMAP_NONE)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderCollapse;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Q3Shader.Types;

type
  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderCollapse = class
  strict private
    function LightmappedShader(const ALightmapIndex: Integer): TQ3ShaderData;
  public
    [Test]
    procedure DovrebbeNonCollassareSenzaLEstensioneMultitexture;
    [Test]
    procedure DovrebbeNonCollassareUnAddSenzaLEstensioneAdd;
    [Test]
    procedure DovrebbeUsareIlColoreDeiVerticiSeLoShaderHaUnaLightmap;
    [Test]
    procedure DovrebbeUsareLaLuceDiffusaSenzaLightmap;
    [Test]
    procedure DovrebbeRimettereNessunaLightmapSeMancaLoStageLightmap;
    [Test]
    procedure DovrebbeTenereLaLightmapSeLoStageCe;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Finisher, DelphiDoom.Decl.Q3Shader.MultitextureCollapse,
  DelphiDoom.Decl.Q3Shader.VertexLightCollapse;

{ TTestQ3ShaderCollapse }

/// <summary>A lightmap stage (not blended) and a texture stage that filters it, as the usual wall shader</summary>
function TTestQ3ShaderCollapse.LightmappedShader(const ALightmapIndex: Integer): TQ3ShaderData;
begin
  Result := Default(TQ3ShaderData);
  Result.LightmapIndex := ALightmapIndex;
  Result.Sort := SS_OPAQUE;
  Result.Stages[0].Active := True;
  Result.Stages[0].Bundle.IsLightmap := True;
  Result.Stages[0].Bundle.TcGen := tgLightmap;
  Result.Stages[0].Bundle.ImageNames[0] := '$lightmap';
  Result.Stages[0].RgbGen := cgIdentity;
  Result.Stages[0].StateBits := GLS_DEFAULT;
  Result.Stages[1].Active := True;
  Result.Stages[1].Bundle.TcGen := tgTexture;
  Result.Stages[1].Bundle.ImageNames[0] := 'textures/test/wall.tga';
  Result.Stages[1].RgbGen := cgIdentity;
  Result.Stages[1].StateBits := GLS_DSTBLEND_ZERO or GLS_SRCBLEND_DST_COLOR;
end;

procedure TTestQ3ShaderCollapse.DovrebbeNonCollassareSenzaLEstensioneMultitexture;
var
  LData: TQ3ShaderData;
begin
  LData := LightmappedShader(-1);
  Assert.IsFalse(TQ3ShaderMultitextureCollapse.Apply(LData, TQ3ShaderOptions.Standard));
  Assert.IsTrue(LData.Stages[1].Active);
  Assert.AreEqual<Integer>(Ord(meNone), Ord(LData.MultitextureEnv));
end;

procedure TTestQ3ShaderCollapse.DovrebbeNonCollassareUnAddSenzaLEstensioneAdd;
var
  LData: TQ3ShaderData;
  LOptions: TQ3ShaderOptions;
begin
  LData := LightmappedShader(-1);
  LData.Stages[1].StateBits := GLS_DSTBLEND_ONE or GLS_SRCBLEND_ONE;
  LOptions := TQ3ShaderOptions.Standard;
  LOptions.MultitextureAvailable := True;
  Assert.IsFalse(TQ3ShaderMultitextureCollapse.Apply(LData, LOptions), 'without GL_ADD');
  LOptions.TextureEnvAddAvailable := True;
  Assert.IsTrue(TQ3ShaderMultitextureCollapse.Apply(LData, LOptions), 'with GL_ADD');
  Assert.AreEqual<Integer>(Ord(meAdd), Ord(LData.MultitextureEnv));
  // the lightmap goes to the second bundle
  Assert.IsTrue(LData.Stages[0].Bundle2.IsLightmap);
  Assert.IsFalse(LData.Stages[1].Active);
end;

procedure TTestQ3ShaderCollapse.DovrebbeUsareIlColoreDeiVerticiSeLoShaderHaUnaLightmap;
var
  LData: TQ3ShaderData;
begin
  LData := LightmappedShader(3);
  TQ3ShaderVertexLightCollapse.Apply(LData);
  Assert.AreEqual<Integer>(Ord(cgExactVertex), Ord(LData.Stages[0].RgbGen));
  Assert.AreEqual<Integer>(Ord(agSkip), Ord(LData.Stages[0].AlphaGen));
  // the texture stage ranks better than the lightmap one
  Assert.AreEqual('textures/test/wall.tga', string(LData.Stages[0].Bundle.ImageNames[0]));
  Assert.IsFalse(LData.Stages[1].Active);
end;

procedure TTestQ3ShaderCollapse.DovrebbeUsareLaLuceDiffusaSenzaLightmap;
var
  LData: TQ3ShaderData;
begin
  LData := LightmappedShader(-1);
  TQ3ShaderVertexLightCollapse.Apply(LData);
  Assert.AreEqual<Integer>(Ord(cgLightingDiffuse), Ord(LData.Stages[0].RgbGen));
end;

procedure TTestQ3ShaderCollapse.DovrebbeRimettereNessunaLightmapSeMancaLoStageLightmap;
var
  LContext: TQ3ShaderContext;
begin
  LContext := TQ3ShaderContext.Create('textures/test/nolm', nil, TQ3ShaderOptions.Standard);
  try
    LContext.Data^ := LightmappedShader(4);
    // no lightmap stage: both are textures
    LContext.Data.Stages[0].Bundle.IsLightmap := False;
    LContext.Data.Stages[0].Bundle.ImageNames[0] := 'textures/test/a.tga';
    TQ3ShaderFinisher.FinishShader(LContext);
    Assert.AreEqual(-1, LContext.Data.LightmapIndex);
  finally
    LContext.Free;
  end;
end;

procedure TTestQ3ShaderCollapse.DovrebbeTenereLaLightmapSeLoStageCe;
var
  LContext: TQ3ShaderContext;
begin
  LContext := TQ3ShaderContext.Create('textures/test/lm', nil, TQ3ShaderOptions.Standard);
  try
    LContext.Data^ := LightmappedShader(4);
    TQ3ShaderFinisher.FinishShader(LContext);
    Assert.AreEqual(4, LContext.Data.LightmapIndex);
    Assert.AreEqual(2, LContext.Data.NumUnfoggedPasses);
  finally
    LContext.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ShaderCollapse);

end.
