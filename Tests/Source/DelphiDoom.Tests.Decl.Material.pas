{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the material declaration (TDeclMaterial and the        }
{  small classes around it)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Material;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Intf, DelphiDoom.Tests.Decl.MaterialSupport;

type
  [TestFixture]
  [Category('Decl')]
  TTestMaterialSurfaceParms = class
  public
    [Test]
    procedure DovrebbeImpostareIFlagDiContenuto;
    [Test]
    procedure DovrebbeImpostareIFlagDiSuperficie;
    [Test]
    procedure DovrebbeTenereUnSoloTipoDiSuperficie;
    [Test]
    procedure DovrebbeTogliereIlSolidoCon;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeElencareLeParole;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestMaterialBlendModes = class
  public
    [Test]
    procedure DovrebbeRiconoscereITipiDiOrigine;
    [Test]
    procedure DovrebbeRiconoscereITipiDiDestinazione;
    [Test]
    procedure DovrebbeRifiutareUnNomeSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiOrigineComeDestinazione;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestMaterialImageNames = class
  public
    [Test]
    procedure DovrebbeTogliereIlTga;
    [Test]
    procedure DovrebbeRiconoscereLImmagineDiDefault;
    [Test]
    procedure DovrebbeRiconoscereLaCopiaDelloSchermo;
    [Test]
    procedure DovrebbeDareIlNomeRisolto;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestMaterialImageProgramNamer = class
  public
    [Test]
    procedure DovrebbeDareIlNomeCanonicoDiUnProgramma;
    [Test]
    procedure DovrebbeLasciareIlLexerDopoIlProgramma;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclMaterial = class
  strict private
    FKit: TMaterialTestKit;
    procedure Start(const AMaterials: string); overload;
    procedure Start(const AMaterials: string; const AOptions: TMaterialOptions); overload;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnMaterialeSemplice;
    [Test]
    procedure DovrebbeNonDisegnareUnMaterialeSenzaStage;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeCEUnErrore;
    [Test]
    procedure DovrebbeSegnalareLaRigaDelLErrore;
    [Test]
    procedure DovrebbeGenerareIlMaterialeImplicito;
    [Test]
    procedure DovrebbeAggiungereGliStageImpliciti;
    [Test]
    procedure DovrebbeOrdinareGliStageDiInterazione;
    [Test]
    procedure DovrebbeSegnalareTroppiStage;
    [Test]
    procedure DovrebbeNonAggiungereStageAlLimite;
    [Test]
    procedure DovrebbeFallireSenzaLettoreDiProgrammi;
    [Test]
    procedure DovrebbeLeggereIFlagEIlSort;
    [Test]
    procedure DovrebbeSommareLArea;
    [Test]
    procedure DovrebbeRifiutareUnoStageFuoriIntervallo;
    [Test]
    procedure DovrebbeConfrontareLaPrioritaDmap;
    [Test]
    procedure DovrebbeIgnorareLaQualitaAltaSeRichiesto;
    [Test]
    procedure DovrebbeDareLaQualitaAltaDiDefault;
    [Test]
    procedure DovrebbeLeggereFragmentProgramsSecondoLeOpzioni;
    [Test]
    procedure DovrebbeNonDareRegistriCostantiDiDefault;
    [Test]
    procedure DovrebbeDareIRegistriCostantiSeRichiesto;
    [Test]
    procedure DovrebbeNonDareRegistriCostantiSeUnaEspressioneLegge;
    [Test]
    procedure DovrebbeNonDareRegistriCostantiSeLOpzioneELaSpenta;
    [Test]
    procedure DovrebbeValutareIRegistri;
    [Test]
    procedure DovrebbeScrivereRegistriEOperazioni;
    [Test]
    procedure DovrebbeDareIlNomeDellImmagineDellEditor;
    [Test]
    procedure DovrebbeDareIlNomeDellImmagineDelloStageZero;
    [Test]
    procedure DovrebbeDareIlTexgenDelPrimoStage;
    [Test]
    procedure DovrebbeNominareLaGuiENonCaricarla;
    [Test]
    procedure DovrebbeDareLaDimensioneEILaDefinizioneDiDefault;
    [Test]
    procedure DovrebbeRileggereDopoUnaModificaDelTesto;
    [Test]
    procedure DovrebbeUsareIlMaterialeNellaSkin;
  end;

implementation

uses
  System.StrUtils, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Skin,
  DelphiDoom.Decl.Material, DelphiDoom.Decl.Material.SurfaceParms, DelphiDoom.Decl.Material.BlendModes,
  DelphiDoom.Decl.Material.ImageNames, DelphiDoom.Decl.Material.ImageNamer;

procedure AssertSingle(const AExpected, AActual: Single; const ATolerance: Double);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), ATolerance);
end;

{ TTestMaterialSurfaceParms }

procedure TTestMaterialSurfaceParms.DovrebbeImpostareIFlagDiContenuto;
var
  LSurface, LContent: Integer;
begin
  LSurface := 0;
  LContent := CONTENTS_SOLID;
  Assert.IsTrue(TMaterialSurfaceParms.Apply('playerclip', LSurface, LContent));
  Assert.AreEqual(CONTENTS_SOLID or CONTENTS_PLAYERCLIP, LContent);
  Assert.AreEqual(0, LSurface);
end;

procedure TTestMaterialSurfaceParms.DovrebbeImpostareIFlagDiSuperficie;
var
  LSurface, LContent: Integer;
begin
  LSurface := 0;
  LContent := 0;
  Assert.IsTrue(TMaterialSurfaceParms.Apply('ladder', LSurface, LContent));
  Assert.IsTrue(TMaterialSurfaceParms.Apply('slick', LSurface, LContent));
  Assert.AreEqual(SURF_LADDER or SURF_SLICK, LSurface);
end;

procedure TTestMaterialSurfaceParms.DovrebbeTenereUnSoloTipoDiSuperficie;
var
  LSurface, LContent: Integer;
begin
  LSurface := SURF_LADDER;
  LContent := 0;
  TMaterialSurfaceParms.Apply('metal', LSurface, LContent);
  TMaterialSurfaceParms.Apply('glass', LSurface, LContent);
  Assert.AreEqual(SURF_LADDER or SURFTYPE_GLASS, LSurface);
end;

procedure TTestMaterialSurfaceParms.DovrebbeTogliereIlSolidoCon;
var
  LSurface, LContent: Integer;
begin
  LSurface := 0;
  LContent := CONTENTS_SOLID;
  TMaterialSurfaceParms.Apply('water', LSurface, LContent);
  Assert.AreEqual(CONTENTS_WATER, LContent);
  LContent := CONTENTS_SOLID;
  TMaterialSurfaceParms.Apply('discrete', LSurface, LContent);
  Assert.AreEqual(0, LContent);
  Assert.AreEqual(SURF_DISCRETE, LSurface);
end;

procedure TTestMaterialSurfaceParms.DovrebbeIgnorareLeMaiuscole;
var
  LSurface, LContent: Integer;
begin
  LSurface := 0;
  LContent := 0;
  Assert.IsTrue(TMaterialSurfaceParms.Apply('NOFRAGMENT', LSurface, LContent));
  Assert.AreEqual(SURF_NOFRAGMENT, LSurface);
end;

procedure TTestMaterialSurfaceParms.DovrebbeRifiutareUnaParolaSconosciuta;
var
  LSurface, LContent: Integer;
begin
  LSurface := 5;
  LContent := 6;
  Assert.IsFalse(TMaterialSurfaceParms.Apply('bogus', LSurface, LContent));
  Assert.AreEqual(5, LSurface);
  Assert.AreEqual(6, LContent);
end;

procedure TTestMaterialSurfaceParms.DovrebbeElencareLeParole;
begin
  Assert.AreEqual(38, TMaterialSurfaceParms.Count);
  Assert.AreEqual('solid', string(TMaterialSurfaceParms.WordAt(0)));
  Assert.AreEqual('surftype15', string(TMaterialSurfaceParms.WordAt(TMaterialSurfaceParms.Count - 1)));
end;

{ TTestMaterialBlendModes }

procedure TTestMaterialBlendModes.DovrebbeRiconoscereITipiDiOrigine;
var
  LBits: Integer;
begin
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('gl_one', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ONE, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_ZERO', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ZERO, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_DST_COLOR', LBits));
  Assert.AreEqual(GLS_SRCBLEND_DST_COLOR, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_ONE_MINUS_DST_COLOR', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ONE_MINUS_DST_COLOR, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_SRC_ALPHA', LBits));
  Assert.AreEqual(GLS_SRCBLEND_SRC_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_ONE_MINUS_SRC_ALPHA', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_DST_ALPHA', LBits));
  Assert.AreEqual(GLS_SRCBLEND_DST_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_ONE_MINUS_DST_ALPHA', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ONE_MINUS_DST_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetSource('GL_SRC_ALPHA_SATURATE', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ALPHA_SATURATE, LBits);
end;

procedure TTestMaterialBlendModes.DovrebbeRiconoscereITipiDiDestinazione;
var
  LBits: Integer;
begin
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_ONE', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ONE, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_ZERO', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ZERO, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_SRC_ALPHA', LBits));
  Assert.AreEqual(GLS_DSTBLEND_SRC_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_ONE_MINUS_SRC_ALPHA', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_DST_ALPHA', LBits));
  Assert.AreEqual(GLS_DSTBLEND_DST_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_ONE_MINUS_DST_ALPHA', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ONE_MINUS_DST_ALPHA, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_SRC_COLOR', LBits));
  Assert.AreEqual(GLS_DSTBLEND_SRC_COLOR, LBits);
  Assert.IsTrue(TMaterialBlendModes.TryGetDestination('GL_ONE_MINUS_SRC_COLOR', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ONE_MINUS_SRC_COLOR, LBits);
end;

procedure TTestMaterialBlendModes.DovrebbeRifiutareUnNomeSconosciuto;
var
  LBits: Integer;
begin
  Assert.IsFalse(TMaterialBlendModes.TryGetSource('GL_BOGUS', LBits));
  Assert.AreEqual(GLS_SRCBLEND_ONE, LBits);
  Assert.IsFalse(TMaterialBlendModes.TryGetDestination('GL_BOGUS', LBits));
  Assert.AreEqual(GLS_DSTBLEND_ONE, LBits);
end;

procedure TTestMaterialBlendModes.DovrebbeRifiutareUnTipoDiOrigineComeDestinazione;
var
  LBits: Integer;
begin
  Assert.IsFalse(TMaterialBlendModes.TryGetDestination('GL_DST_COLOR', LBits));
  Assert.IsFalse(TMaterialBlendModes.TryGetSource('GL_SRC_COLOR', LBits));
end;

{ TTestMaterialImageNames }

procedure TTestMaterialImageNames.DovrebbeTogliereIlTga;
begin
  Assert.AreEqual('textures/a', string(TMaterialImageNames.Canonicalize('textures\a.tga')));
  Assert.AreEqual('addnormals( a, b )', string(TMaterialImageNames.Canonicalize('addnormals( a.tga, b.tga )')));
  // the replacement is case sensitive, as idStr::Replace
  Assert.AreEqual('a.TGA', string(TMaterialImageNames.Canonicalize('a.TGA')));
end;

procedure TTestMaterialImageNames.DovrebbeRiconoscereLImmagineDiDefault;
begin
  Assert.IsTrue(TMaterialImageNames.IsDefault(''));
  Assert.IsTrue(TMaterialImageNames.IsDefault('default'));
  Assert.IsTrue(TMaterialImageNames.IsDefault('_DEFAULT'));
  Assert.IsFalse(TMaterialImageNames.IsDefault('_white'));
end;

procedure TTestMaterialImageNames.DovrebbeRiconoscereLaCopiaDelloSchermo;
begin
  Assert.IsTrue(TMaterialImageNames.IsCurrentRender('_currentRender'));
  Assert.IsTrue(TMaterialImageNames.IsCurrentRender('_CURRENTRENDER.tga'));
  Assert.IsFalse(TMaterialImageNames.IsCurrentRender('currentRender'));
  Assert.IsFalse(TMaterialImageNames.IsCurrentRender(''));
end;

procedure TTestMaterialImageNames.DovrebbeDareIlNomeRisolto;
begin
  Assert.AreEqual('_default', string(TMaterialImageNames.ResolvedName('')));
  Assert.AreEqual('textures/a', string(TMaterialImageNames.ResolvedName('textures\a.tga')));
end;

{ TTestMaterialImageProgramNamer }

procedure TTestMaterialImageProgramNamer.DovrebbeDareIlNomeCanonicoDiUnProgramma;
var
  LNamer: IMaterialImageNamer;
  LLexer: TIdLexer;
begin
  LNamer := TMaterialImageProgramNamer.Create;
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES, nil);
  try
    LLexer.LoadMemory('addnormals(  textures/a_local ,heightmap( textures/a_h, 3 ) )', 'test');
    Assert.AreEqual('addnormals( textures/a_local, heightmap( textures/a_h, 3))',
      string(LNamer.ParsePastImageProgram(LLexer)));
  finally
    LLexer.Free;
  end;
end;

procedure TTestMaterialImageProgramNamer.DovrebbeLasciareIlLexerDopoIlProgramma;
var
  LNamer: IMaterialImageNamer;
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  LNamer := TMaterialImageProgramNamer.Create;
  LLexer := TIdLexer.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES, nil);
  try
    LLexer.LoadMemory('textures/a clamp', 'test');
    Assert.AreEqual('textures/a', string(LNamer.ParsePastImageProgram(LLexer)));
    LToken := TIdToken.Create;
    Assert.IsTrue(LLexer.ReadToken(LToken));
    Assert.AreEqual('clamp', string(LToken.Text));
  finally
    LLexer.Free;
  end;
end;

{ TTestDeclMaterial }

procedure TTestDeclMaterial.Start(const AMaterials: string);
begin
  FreeAndNil(FKit);
  FKit := TMaterialTestKit.Create(AMaterials);
end;

procedure TTestDeclMaterial.Start(const AMaterials: string; const AOptions: TMaterialOptions);
begin
  FreeAndNil(FKit);
  FKit := TMaterialTestKit.Create(AMaterials, AOptions);
end;

procedure TTestDeclMaterial.TearDown;
begin
  FreeAndNil(FKit);
end;

procedure TTestDeclMaterial.DovrebbeLeggereUnMaterialeSemplice;
var
  LMaterial: IDeclMaterial;
  LStage: TMaterialStage;
begin
  Start(StageMaterial(''));
  LMaterial := FKit.Material('m/one');
  Assert.AreEqual(1, LMaterial.GetNumStages);
  Assert.IsTrue(LMaterial.IsDrawn);
  Assert.AreEqual(Ord(TMaterialCoverage.Translucent), Ord(LMaterial.Coverage));
  AssertSingle(SS_MEDIUM, LMaterial.GetSort, 0);
  Assert.IsTrue(LMaterial.TestMaterialFlag(MF_NOSHADOWS));
  LStage := LMaterial.GetStage(0);
  Assert.AreEqual(GLS_SRCBLEND_ONE or GLS_DSTBLEND_ONE or GLS_DEPTHFUNC_LESS or GLS_DEPTHMASK, LStage.DrawStateBits);
  Assert.AreEqual('textures/one', string(LStage.Texture.Image.Name));
  Assert.IsTrue(LStage.Texture.HasImage);
  Assert.AreEqual(Ord(dsParsed), Ord(FKit.Decl('m/one').GetState));
end;

procedure TTestDeclMaterial.DovrebbeNonDisegnareUnMaterialeSenzaStage;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/none'#10'{'#10#9'solid'#10'}'#10);
  LMaterial := FKit.Material('m/none');
  Assert.IsFalse(LMaterial.IsDrawn);
  Assert.IsFalse(LMaterial.ReceivesFog);
  Assert.AreEqual('_scratch', string(LMaterial.ImageName));
  Assert.AreEqual(-1, LMaterial.GetBumpStageIndex);
end;

procedure TTestDeclMaterial.DovrebbeUsareLaDefinizioneDiDefaultSeCEUnErrore;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/bad'#10'{'#10#9'{'#10#9#9'bogus'#10#9'}'#10'}'#10);
  LMaterial := FKit.Material('m/bad');
  Assert.AreEqual(Ord(dsDefaulted), Ord(FKit.Decl('m/bad').GetState));
  Assert.AreEqual(1, LMaterial.GetNumStages);
  Assert.AreEqual('_default', string(LMaterial.ImageName));
  Assert.IsTrue(Pos('unknown token ''bogus'' in material ''m/bad''', FKit.LogText) > 0);
end;

procedure TTestDeclMaterial.DovrebbeSegnalareLaRigaDelLErrore;
begin
  Start('m/bad'#10'{'#10#9'sort'#10'}'#10);
  FKit.Material('m/bad');
  Assert.IsTrue(Pos('file materials/test.mtr, line ', FKit.LogText) > 0);
  Assert.IsTrue(Pos('missing sort parameter', FKit.LogText) > 0);
  // a warning of the material itself has no position
  Start('m/bad2'#10'{'#10#9'blend add'#10'}'#10);
  FKit.Material('m/bad2');
  Assert.IsTrue(Pos('unknown general material parameter ''blend'' in ''m/bad2''', FKit.LogText) > 0);
end;

procedure TTestDeclMaterial.DovrebbeGenerareIlMaterialeImplicito;
var
  LMaterial: IDeclMaterial;
  LStage: TMaterialStage;
begin
  Start('');
  LMaterial := FKit.Material('textures/wall/a');
  Assert.AreEqual(1, LMaterial.GetNumStages);
  LStage := LMaterial.GetStage(0);
  Assert.AreEqual('textures/wall/a', string(LStage.Texture.Image.Name));
  Assert.AreEqual(Ord(TMaterialTextureRepeat.Clamp), Ord(LStage.Texture.Image.RepeatMode));
  // "colored": the color comes from the first four parameters
  Assert.AreEqual(EXP_REG_PARM0, LStage.ColorRegisters[0]);
  Assert.AreEqual(EXP_REG_PARM3, LStage.ColorRegisters[3]);
  Assert.AreEqual(GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA or GLS_DEPTHFUNC_LESS or GLS_DEPTHMASK,
    LStage.DrawStateBits);
  Assert.IsTrue(FKit.Decl('textures/wall/a').IsImplicit);
end;

procedure TTestDeclMaterial.DovrebbeAggiungereGliStageImpliciti;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/diffuse'#10'{'#10#9'diffusemap textures/d'#10'}'#10 +
    'm/bump'#10'{'#10#9'bumpmap textures/n'#10'}'#10 +
    'm/ambient'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map textures/a'#10#9'}'#10'}'#10);
  // only a diffuse: a flat bump map is put first
  LMaterial := FKit.Material('m/diffuse');
  Assert.AreEqual(2, LMaterial.GetNumStages);
  Assert.AreEqual(Ord(TMaterialLighting.Bump), Ord(LMaterial.GetStage(0).Lighting));
  Assert.AreEqual('_flat', string(LMaterial.GetStage(0).Texture.Image.Name));
  Assert.AreEqual(Ord(TMaterialLighting.Diffuse), Ord(LMaterial.GetStage(1).Lighting));
  Assert.AreEqual(0, LMaterial.GetBumpStageIndex);
  // only a bump map: a white diffuse follows
  LMaterial := FKit.Material('m/bump');
  Assert.AreEqual(2, LMaterial.GetNumStages);
  Assert.AreEqual('_white', string(LMaterial.GetStage(1).Texture.Image.Name));
  // no interaction at all: nothing is added
  Assert.AreEqual(1, FKit.Material('m/ambient').GetNumStages);
end;

procedure TTestDeclMaterial.DovrebbeOrdinareGliStageDiInterazione;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/sorted'#10'{'#10 +
    #9'specularmap textures/s'#10#9'diffusemap textures/d'#10#9'bumpmap textures/n'#10'}'#10);
  LMaterial := FKit.Material('m/sorted');
  Assert.AreEqual(3, LMaterial.GetNumStages);
  Assert.AreEqual(Ord(TMaterialLighting.Bump), Ord(LMaterial.GetStage(0).Lighting));
  Assert.AreEqual(Ord(TMaterialLighting.Diffuse), Ord(LMaterial.GetStage(1).Lighting));
  Assert.AreEqual(Ord(TMaterialLighting.Specular), Ord(LMaterial.GetStage(2).Lighting));
  Assert.IsTrue(LMaterial.ReceivesLighting);
  Assert.IsFalse(LMaterial.HasAmbient);
end;

procedure TTestDeclMaterial.DovrebbeSegnalareTroppiStage;
var
  LText: string;
  LIndex: Integer;
begin
  LText := 'm/many'#10'{'#10;
  for LIndex := 1 to MAX_SHADER_STAGES + 1 do
    LText := LText + #9'{'#10#9#9'blend add'#10#9#9'map textures/m'#10#9'}'#10;
  LText := LText + '}'#10;
  Start(LText);
  Assert.AreEqual(Ord(dsDefaulted), Ord(FKit.Decl('m/many').GetState));
  Assert.IsTrue(Pos('material ''m/many'' exceeded 256 stages', FKit.LogText) > 0);
end;

procedure TTestDeclMaterial.DovrebbeNonAggiungereStageAlLimite;
var
  LText: string;
  LIndex: Integer;
begin
  // 256 stages with a diffuse among them: the implicit bump map does not fit and is left out
  LText := 'm/full'#10'{'#10#9'diffusemap textures/d'#10;
  for LIndex := 2 to MAX_SHADER_STAGES do
    LText := LText + #9'{'#10#9#9'blend add'#10#9#9'map textures/m'#10#9'}'#10;
  LText := LText + '}'#10;
  Start(LText);
  Assert.AreEqual(Ord(dsParsed), Ord(FKit.Decl('m/full').GetState));
  Assert.AreEqual(MAX_SHADER_STAGES, FKit.Material('m/full').GetNumStages);
end;

procedure TTestDeclMaterial.DovrebbeFallireSenzaLettoreDiProgrammi;
begin
  Assert.WillRaise(
    procedure
    begin
      TDeclMaterial.Create(nil, TMaterialOptions.Standard);
    end, EDeclMaterialException);
end;

procedure TTestDeclMaterial.DovrebbeLeggereIFlagEIlSort;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/flags'#10'{'#10#9'noSelfShadow'#10#9'forceShadows'#10#9'sort 5'#10#9'{'#10#9#9'blend add'#10#9#9'map x'#10#9'}'#10'}'#10);
  LMaterial := FKit.Material('m/flags');
  Assert.IsTrue(LMaterial.TestMaterialFlag(MF_NOSELFSHADOW));
  Assert.IsTrue(LMaterial.SurfaceCastsShadow);
  Assert.IsTrue(LMaterial.ReceivesLightingOnBackSides);
  AssertSingle(5, LMaterial.GetSort, 0);
  LMaterial.SetSort(8);
  AssertSingle(8, LMaterial.GetSort, 0);
  LMaterial.SetMaterialFlag(MF_EDITOR_VISIBLE);
  Assert.IsTrue(LMaterial.TestMaterialFlag(MF_EDITOR_VISIBLE));
  LMaterial.ClearMaterialFlag(MF_EDITOR_VISIBLE);
  Assert.IsFalse(LMaterial.TestMaterialFlag(MF_EDITOR_VISIBLE));
end;

procedure TTestDeclMaterial.DovrebbeSommareLArea;
var
  LMaterial: IDeclMaterial;
begin
  Start(StageMaterial(''));
  LMaterial := FKit.Material('m/one');
  LMaterial.AddToSurfaceArea(2.5);
  LMaterial.AddToSurfaceArea(1);
  AssertSingle(3.5, LMaterial.GetSurfaceArea, 0);
  // the area survives a new parse (it is for the listSurfaceAreas command)
  FKit.Decl('m/one').Invalidate;
  FKit.Decl('m/one').EnsureNotPurged;
  AssertSingle(3.5, FKit.Material('m/one').GetSurfaceArea, 0);
end;

procedure TTestDeclMaterial.DovrebbeRifiutareUnoStageFuoriIntervallo;
begin
  Start(StageMaterial(''));
  Assert.WillRaise(
    procedure
    begin
      FKit.Material('m/one').GetStage(1);
    end, EDeclMaterialException);
  Assert.WillRaise(
    procedure
    begin
      FKit.Material('m/one').GetStage(-1);
    end, EDeclMaterialException);
end;

procedure TTestDeclMaterial.DovrebbeConfrontareLaPrioritaDmap;
var
  LDrawn, LNone: IDeclMaterial;
begin
  Start(StageMaterial('') + 'm/none'#10'{'#10#9'solid'#10'}'#10);
  LDrawn := FKit.Material('m/one');
  LNone := FKit.Material('m/none');
  Assert.IsTrue(LDrawn.HasHigherDmapPriority(LNone));
  Assert.IsFalse(LNone.HasHigherDmapPriority(LDrawn));
end;

procedure TTestDeclMaterial.DovrebbeIgnorareLaQualitaAltaSeRichiesto;
var
  LOptions: TMaterialOptions;
begin
  LOptions := TMaterialOptions.Standard;
  LOptions.IgnoreHighQuality := True;
  Start(StageMaterial('uncompressed'#10#9#9'highquality'), LOptions);
  Assert.AreEqual(Ord(TMaterialTextureDepth.Default), Ord(FKit.Material('m/one').GetStage(0).Texture.Image.Depth));
end;

procedure TTestDeclMaterial.DovrebbeDareLaQualitaAltaDiDefault;
begin
  Start(StageMaterial('uncompressed'));
  Assert.AreEqual(Ord(TMaterialTextureDepth.HighQuality),
    Ord(FKit.Material('m/one').GetStage(0).Texture.Image.Depth));
end;

procedure TTestDeclMaterial.DovrebbeLeggereFragmentProgramsSecondoLeOpzioni;
var
  LOptions: TMaterialOptions;
  LRegisters: TArray<Single>;
  LStage: TMaterialStage;
begin
  Start(StageMaterial('alpha fragmentPrograms'));
  LStage := FKit.Material('m/one').GetStage(0);
  FKit.Registers('m/one').EvaluateRegisters(LRegisters, Default(TMaterialEvaluationInput));
  AssertSingle(1, LRegisters[LStage.ColorRegisters[3]], 0);

  LOptions := TMaterialOptions.Standard;
  LOptions.FragmentProgramsAvailable := False;
  Start(StageMaterial('alpha fragmentPrograms'), LOptions);
  LStage := FKit.Material('m/one').GetStage(0);
  FKit.Registers('m/one').EvaluateRegisters(LRegisters, Default(TMaterialEvaluationInput));
  AssertSingle(0, LRegisters[LStage.ColorRegisters[3]], 0);
end;

procedure TTestDeclMaterial.DovrebbeNonDareRegistriCostantiDiDefault;
begin
  // the original never makes registersAreConstant true, so its constant registers do not exist
  Start(StageMaterial('alpha 0.5 * 0.5'));
  Assert.AreEqual<Integer>(0, Length(FKit.Registers('m/one').ConstantRegisters));
end;

procedure TTestDeclMaterial.DovrebbeDareIRegistriCostantiSeRichiesto;
var
  LOptions: TMaterialOptions;
  LConstants: TArray<Single>;
  LStage: TMaterialStage;
begin
  LOptions := TMaterialOptions.Standard;
  LOptions.FixConstantRegisters := True;
  Start(StageMaterial('alpha 0.5 * 0.5 + sinTable[ 0.25 ]'), LOptions);
  LConstants := FKit.Registers('m/one').ConstantRegisters;
  Assert.AreEqual<Integer>(FKit.Registers('m/one').GetNumRegisters, Length(LConstants));
  LStage := FKit.Material('m/one').GetStage(0);
  // 0.25 * the first table value at 0.25 of its cycle (1)
  AssertSingle(1.25, LConstants[LStage.ColorRegisters[3]], 0.0001);
end;

procedure TTestDeclMaterial.DovrebbeNonDareRegistriCostantiSeUnaEspressioneLegge;
var
  LOptions: TMaterialOptions;
begin
  LOptions := TMaterialOptions.Standard;
  LOptions.FixConstantRegisters := True;
  Start(StageMaterial('alpha time * 2') + 'm/colored'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map x'#10#9#9'colored'#10#9'}'#10'}'#10, LOptions);
  Assert.AreEqual<Integer>(0, Length(FKit.Registers('m/one').ConstantRegisters));
  Assert.AreEqual<Integer>(0, Length(FKit.Registers('m/colored').ConstantRegisters));
end;

procedure TTestDeclMaterial.DovrebbeNonDareRegistriCostantiSeLOpzioneELaSpenta;
var
  LOptions: TMaterialOptions;
begin
  LOptions := TMaterialOptions.Standard;
  LOptions.FixConstantRegisters := True;
  LOptions.UseConstantMaterials := False;
  Start(StageMaterial('alpha 2'), LOptions);
  Assert.AreEqual<Integer>(0, Length(FKit.Registers('m/one').ConstantRegisters));
end;

procedure TTestDeclMaterial.DovrebbeValutareIRegistri;
var
  LRegisters: TArray<Single>;
  LInput: TMaterialEvaluationInput;
  LStage: TMaterialStage;
begin
  Start(StageMaterial('red time * 2 + parm3' + #10#9#9 + 'green global1 > 1'));
  LStage := FKit.Material('m/one').GetStage(0);
  LInput := Default(TMaterialEvaluationInput);
  LInput.Time := 1.5;
  LInput.Parms[3] := 0.25;
  LInput.GlobalParms[1] := 2;
  FKit.Registers('m/one').EvaluateRegisters(LRegisters, LInput);
  Assert.AreEqual<Integer>(FKit.Registers('m/one').GetNumRegisters, Length(LRegisters));
  AssertSingle(3.25, LRegisters[LStage.ColorRegisters[0]], 0);
  AssertSingle(1, LRegisters[LStage.ColorRegisters[1]], 0);
  AssertSingle(1, LRegisters[LStage.ColorRegisters[2]], 0);
  // the first constant is the 1 of the condition of the stage, then comes the 2 of the product
  AssertSingle(1, FKit.Registers('m/one').GetParsedRegister(EXP_REG_NUM_PREDEFINED), 0);
  AssertSingle(2, FKit.Registers('m/one').GetParsedRegister(EXP_REG_NUM_PREDEFINED + 1), 0);
  Assert.AreEqual(Ord(TMaterialOpType.Multiply), Ord(FKit.Registers('m/one').GetOp(0).OpType));
  Assert.AreEqual(3, FKit.Registers('m/one').GetNumOps);
end;

procedure TTestDeclMaterial.DovrebbeScrivereRegistriEOperazioni;
var
  LDecl: IDecl;
begin
  Start(StageMaterial('alpha sinTable[ time * 0.5 ]'));
  LDecl := FKit.Decl('m/one');
  FKit.Kit.Lines.Clear;
  LDecl.Print;
  Assert.IsTrue(Pos('register 21: 1.000000', FKit.LogText) > 0);
  Assert.IsTrue(Pos('OP_TYPE_MULTIPLY', FKit.LogText) > 0);
  Assert.IsTrue(Pos('sintable[', FKit.LogText) > 0);
end;

procedure TTestDeclMaterial.DovrebbeDareIlNomeDellImmagineDellEditor;
begin
  Start('m/ed'#10'{'#10#9'qer_editorimage textures\ed\x.tga'#10 + #9'diffusemap textures/d'#10'}'#10 +
    'm/diff'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map textures/first'#10#9'}'#10 +
    #9'diffusemap textures/dd'#10'}'#10 +
    'm/first'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map textures/first'#10#9'}'#10'}'#10 +
    'm/none'#10'{'#10#9'solid'#10'}'#10 +
    'm/dyn'#10'{'#10#9'{'#10#9#9'mirrorRenderMap 8 8'#10#9'}'#10'}'#10);
  Assert.AreEqual('textures/ed/x', string(FKit.Material('m/ed').GetEditorImageName));
  Assert.AreEqual('textures/dd', string(FKit.Material('m/diff').GetEditorImageName));
  Assert.AreEqual('textures/first', string(FKit.Material('m/first').GetEditorImageName));
  Assert.AreEqual('_default', string(FKit.Material('m/none').GetEditorImageName));
  Assert.AreEqual('_default', string(FKit.Material('m/dyn').GetEditorImageName));
end;

procedure TTestDeclMaterial.DovrebbeDareIlNomeDellImmagineDelloStageZero;
begin
  Start(StageMaterial('') + 'm/dyn'#10'{'#10#9'{'#10#9#9'mirrorRenderMap 8 8'#10#9'}'#10'}'#10);
  Assert.AreEqual('textures/one', string(FKit.Material('m/one').ImageName));
  Assert.AreEqual('_scratch', string(FKit.Material('m/dyn').ImageName));
end;

procedure TTestDeclMaterial.DovrebbeDareIlTexgenDelPrimoStage;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/gen'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map a'#10#9'}'#10 +
    #9'{'#10#9#9'blend add'#10#9#9'map b'#10#9#9'texGen skybox'#10#9'}'#10'}'#10);
  LMaterial := FKit.Material('m/gen');
  Assert.AreEqual(Ord(TMaterialTexgen.SkyboxCube), Ord(LMaterial.Texgen));
  Assert.AreEqual(Ord(TMaterialTexgen.Explicit), Ord(FKit.Material('textures/plain').Texgen));
end;

procedure TTestDeclMaterial.DovrebbeNominareLaGuiENonCaricarla;
var
  LMaterial: IDeclMaterial;
begin
  Start('m/gui'#10'{'#10#9'guisurf guis/hud.gui'#10'}'#10 + 'm/ent'#10'{'#10#9'guisurf entity2'#10'}'#10);
  LMaterial := FKit.Material('m/gui');
  Assert.IsTrue(LMaterial.HasGui);
  Assert.IsTrue(LMaterial.IsDrawn);
  Assert.AreEqual('guis/hud.gui', string(LMaterial.GetGuiName));
  LMaterial := FKit.Material('m/ent');
  Assert.AreEqual(2, LMaterial.GetEntityGui);
  Assert.AreEqual('', string(LMaterial.GetGuiName));
  Assert.IsTrue(LMaterial.IsDiscrete);
end;

procedure TTestDeclMaterial.DovrebbeDareLaDimensioneEILaDefinizioneDiDefault;
var
  LDecl: IDecl;
begin
  Start(StageMaterial(''));
  LDecl := FKit.Decl('m/one');
  Assert.IsTrue(LDecl.Size > 0);
  Assert.IsTrue(Pos('map'#9#9'_default', string(LDecl.DefaultDefinition)) > 0);
  Assert.IsTrue(StartsText('{', string(LDecl.DefaultDefinition)));
end;

procedure TTestDeclMaterial.DovrebbeRileggereDopoUnaModificaDelTesto;
begin
  Start(StageMaterial(''));
  Assert.AreEqual('textures/one', string(FKit.Material('m/one').ImageName));
  FKit.Decl('m/one').SetText('material m/one { { blend filter map textures/two } }');
  FKit.Decl('m/one').Invalidate;
  FKit.Decl('m/one').EnsureNotPurged;
  Assert.AreEqual('textures/two', string(FKit.Material('m/one').ImageName));
  Assert.AreEqual(GLS_SRCBLEND_DST_COLOR, FKit.Material('m/one').GetStage(0).DrawStateBits and GLS_SRCBLEND_BITS);
end;

procedure TTestDeclMaterial.DovrebbeUsareIlMaterialeNellaSkin;
var
  LSkin: IDeclSkin;
  LNone, LOne: IDecl;
begin
  Start(StageMaterial('') + 'm/none'#10'{'#10#9'solid'#10'}'#10 + 'm/other'#10'{'#10#9'solid'#10'}'#10);
  Supports(FKit.Kit.Manager.FindType(DECL_SKIN, 'sk', False), IDeclSkin, LSkin);
  LNone := FKit.Decl('m/none');
  LOne := FKit.Decl('m/one');
  // a material that draws nothing stays as it is; one that draws is replaced
  Assert.IsTrue(LSkin.RemapShaderBySkin(LNone) = LNone);
  Assert.AreEqual('m/other', string(LSkin.RemapShaderBySkin(LOne).GetName));
  // the shader that is not a material is counted as drawn
  Assert.IsFalse(Assigned(LSkin.RemapShaderBySkin(nil)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMaterialSurfaceParms);
  TDUnitX.RegisterTestFixture(TTestMaterialBlendModes);
  TDUnitX.RegisterTestFixture(TTestMaterialImageNames);
  TDUnitX.RegisterTestFixture(TTestMaterialImageProgramNamer);
  TDUnitX.RegisterTestFixture(TTestDeclMaterial);

end.
