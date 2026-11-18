{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlInitializer - OpenGL call flow, driver         }
{  strings, extensions and light table against the text of gl_render.pas of    }
{  before the class                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Initializer;

{$I Doom32.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlScene.Types,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>One set of inputs of the initializer: what the driver says, the options and the lumps</summary>
  TInitializerCase = record
    Extensions: AnsiString;
    UsePaletted: Integer;
    UseSharedPalette: Integer;
    ColorTableAvailable: Boolean;
    DeveloperMode: Boolean;
    Max3DTextureSize: Integer;
    TextureFormat: string;
    ScreenSync: Boolean;
    GammaLump: Boolean;
    LightsFound: Boolean;
  end;

  /// <summary>
  ///   The initializer calls OpenGL (fake functions that log, no context), reads the strings and the limits
  ///   of the driver, the options and the GLGAMMA lump and calls the initializers of the other parts of the
  ///   renderer (shims that write a line): the lines (calls, printed texts, warnings), the resulting options
  ///   and the light table are compared with the old gld_Init, gld_InitExtensions and gld_InitLightTable,
  ///   copied here from the text of before the class
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlInitializer = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    FLightTable: TGlSceneLightTable;
    FOldLightTable: TGlSceneLightTable;
    procedure Prepare(const ACase: TInitializerCase);
    function Summary: string;
    function RunOld(const ACase: TInitializerCase): string;
    function RunNew(const ACase: TInitializerCase): string;
    function MakeCase(const AExtensions: AnsiString; AMax3D: Integer): TInitializerCase;
    // The old text runs first and the new one second (the order of the arguments of a call is not defined)
    procedure ExpectSameFlow(const ACase: TInitializerCase; const AMessage: string = '');
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeStampareIlDriverEChiedereLeEstensioniPerPrime;
    [Test]
    procedure DovrebbeDareLoStessoFlussoDelVecchioSenzaEstensioni;
    [Test]
    procedure DovrebbeDareLoStessoFlussoDelVecchioConTutteLeEstensioni;
    [Test]
    procedure DovrebbeDareLoStessoFlussoDelVecchioSuCombinazioniCasuali;
    [Test]
    procedure DovrebbeDisabilitareLeLightmapSenzaLeEstensioniOSenzaTexture3DGrandi;
    [Test]
    procedure DovrebbeLeggereLaTabellaDelleLuciDaGlGamma;
    [Test]
    procedure DovrebbeFareLaRadiceQuadrataAncheSenzaLump;
    [Test]
    procedure DovrebbeLeggereLaTabellaDelleLuciUnaSolaVolta;
    [Test]
    procedure DovrebbeDareErroreSenzaLeLuciDinamiche;
    [Test]
    procedure DovrebbeRifiutareParametriNil;
    [Test]
    procedure DovrebbeTenereLaSincronizzazioneVerticaleCheHaAvviato;
  end;

implementation

uses
  dglOpenGL,
  d_delphi,
  d_main,
  doomdef,
  i_system,
  w_wad,
  v_video,
  gl_defs,
  gl_tex,
  gl_lightmaps,
  r_dynlights,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.Engine.GlLightmap.Types,
  DelphiDoom.Engine.GlVSync,
  DelphiDoom.Engine.GlInitializer,
  DelphiDoom.Tests.OpenGl.SceneLightMarker;

var
  GOldLightTable: PGlSceneLightTable;
  GOldLightTableInitialized: Boolean;
  GOldVSyncWarning: Boolean;
  GOldCache: IDynLightRenderCache;

// The text of before the classes (gl_render.pas, commit before ondata2-177-1), only the names of the
// globals that moved: gl_lighttable is the table of the test, gl_dynlights the cache of the test, the
// vsync warning flag a variable of this unit and toupper(char) is UpCase.

procedure OldInitExtensions(ext_list: TDStringList);
begin
  gl_texture_filter_anisotropic := ext_list.IndexOf('GL_EXT_TEXTURE_FILTER_ANISOTROPIC') > -1;
  if gl_texture_filter_anisotropic then
    printf('enabled anisotropic texture filtering'#13#10);
  if gl_use_paletted_texture <> 0 then
  begin
    gl_paletted_texture := ext_list.IndexOf('GL_EXT_PALETTED_TEXTURE') > -1;
    gld_ColorTableEXT := lp3DFXFUNC(wglGetProcAddress('glColorTableEXT'));
    if not Assigned(gld_ColorTableEXT) then
      gl_paletted_texture := false
    else
      printf('using GL_EXT_paletted_texture'#13#10);
  end;
  if gl_use_shared_texture_palette <> 0 then
  begin
    gl_shared_texture_palette := ext_list.IndexOf('GL_EXT_SHARED_TEXTURE_PALETTE') > -1;
    gld_ColorTableEXT := lp3DFXFUNC(wglGetProcAddress('glColorTableEXT'));
    if not Assigned(gld_ColorTableEXT) then
      gl_shared_texture_palette := false
    else
      printf('using GL_EXT_shared_texture_palette'#13#10);
  end;

  canuselightmaps := ext_list.IndexOf('GL_ARB_MULTITEXTURE') > -1;
  if not canuselightmaps then
  begin
    I_Warning('gld_InitExtensions(): GL_ARB_MULTITEXTURE extension not supported, lightmap will be disabled'#13#10);
    gl_uselightmaps := false;
  end
  else
  begin
    canuselightmaps := ext_list.IndexOf('GL_EXT_TEXTURE3D') > -1;
    if not canuselightmaps then
    begin
      I_Warning('gld_InitExtensions(): GL_EXT_TEXTURE3D extension not supported, lightmap will be disabled'#13#10);
      gl_uselightmaps := false;
    end;
  end;
  ShimEvent('gld_InitAutomap');
end;

function OldVSync(vsync: TGlVSyncMode): boolean;
var
  i: Integer;
begin
  if WGL_EXT_swap_control then
  begin
    result := True;
    i := wglGetSwapIntervalEXT;
    case VSync of
      vsmSync    : if i <> 1 then wglSwapIntervalEXT(1);
      vsmNoSync  : if i <> 0 then wglSwapIntervalEXT(0);
    else
      System.Assert(False);
    end;
  end
  else
  begin
    result := False;
    if not GOldVSyncWarning then
    begin
      I_Warning('gld_VSync(): wglSwapIntervalEXT() not assigned'#13#10);
      GOldVSyncWarning := true;
    end;
  end;
end;

procedure OldInitLightTable;
var
  sc: TScriptScanner;
  lump: integer;
  i, j: integer;
begin
  if GOldLightTableInitialized then
    Exit;

  lump := TWadRoutines.W_CheckNumForName('GLGAMMA');
  if lump > 0 then
  begin

    sc := TScriptScanner.Create(TWadRoutines.W_TextLumpNum(lump), TEngineScannerLog.Create);
    for i := 0 to GAMMASIZE - 1 do
      for j := 0 to 255 do
      begin
        sc.MustGetFloat;
        GOldLightTable^[i, j] := sc.AsFloat;
      end;
    sc.Free;
  end;

  for i := 0 to GAMMASIZE - 1 do
    for j := 0 to 255 do
      GOldLightTable^[i, j] := Sqrt(GOldLightTable^[i, j]);

  GOldLightTableInitialized := true;
end;

procedure OldInit(width, height: integer);
var
  params: array[0..3] of TGLfloat;
  BlackFogColor: array[0..3] of TGLfloat;
  ext_lst: TDStringList;
  i, tf_id: integer;
  extensions,
  extensions_l: string;
begin
  params[0] := 0.0;
  params[1] := 0.0;
  params[2] := 1.0;
  params[3] := 0.0;
  BlackFogColor[0] := 0.0;
  BlackFogColor[1] := 0.0;
  BlackFogColor[2] := 0.0;
  BlackFogColor[3] := 0.0;

  printf('GL_VENDOR: %s'#13#10 , [glGetString(GL_VENDOR)]);
  printf('GL_RENDERER: %s'#13#10, [glGetString(GL_RENDERER)]);
  printf('GL_VERSION: %s'#13#10, [glGetString(GL_VERSION)]);

  if devparm then
    printf('GL_EXTENSIONS:'#13#10);

  extensions := StringVal(glGetString(GL_EXTENSIONS));
  extensions_l := '';
  for i := 1 to Length(extensions) do
  begin
    if extensions[i] = ' ' then
      extensions_l := extensions_l + #13#10
    else
      extensions_l := extensions_l + UpCase(extensions[i]);
  end;

  ext_lst := TDStringList.Create;
  try
    ext_lst.Text := extensions_l;
    if devparm then
      for i := 0 to ext_lst.count - 1 do
        printf('  %s'#13#10, [ext_lst.strings[i]]);
    OldInitExtensions(ext_lst);
  finally
    ext_lst.Free;
  end;

  gld_InitPalettedTextures;

  glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);

  {$IFDEF DEBUG}
  glClearColor(0.0, 0.5, 0.5, 1.0);
  glClearDepth(1.0);
  {$ELSE}
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClearDepth(1.0);
  {$ENDIF}

  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @gld_max_texturesize);
  printf('GL_MAX_TEXTURE_SIZE=%d'#13#10, [gld_max_texturesize]);
  glGetIntegerv(GL_MAX_3D_TEXTURE_SIZE, @gld_max_texturesize3d);
  printf('GL_MAX_3D_TEXTURE_SIZE=%d'#13#10, [gld_max_texturesize3d]);

  if canuselightmaps then
    canuselightmaps := (gld_max_texturesize3d >= LIGHTMAPSIZEX) and
                       (gld_max_texturesize3d >= LIGHTMAPSIZEY) and
                       (gld_max_texturesize3d >= LIGHTMAPSIZEZ);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glShadeModel(GL_FLAT);
  glEnable(GL_TEXTURE_2D);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GEQUAL, 0.5);
  glDisable(GL_CULL_FACE);
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  glTexGenfv(GL_Q, GL_EYE_PLANE, @params);
  glTexGenf(GL_S,GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
  glTexGenf(GL_T,GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
  glTexGenf(GL_Q,GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
  glFogi(GL_FOG_MODE, GL_EXP);
  glFogfv(GL_FOG_COLOR, @BlackFogColor);
  glFogf(GL_FOG_DENSITY, fog_density / 1000.0);
  glHint(GL_FOG_HINT, GL_NICEST);
  glFogf(GL_FOG_START, 0.0);
  glFogf(GL_FOG_END, 1.0);

  glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
  glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
  glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

// Texture filtering and mipmaping
  gld_SetCurrTexFiltering(gld_GetCurrTexFiltering);

// Texture format
  gl_tex_format := DEF_TEX_FORMAT;
  gl_tex_format_string := strupper(gl_tex_format_string);
  tf_id := -1;
  for i := 0 to NUM_GL_TEX_FORMATS - 1 do
    if gl_tex_format_string = gl_tex_formats[i].desc then
    begin
      gl_tex_format := gl_tex_formats[i].tex_format;
      tf_id := i;
      break;
    end;

  if tf_id < 0 then
    printf('Using default texture format.'#13#10)
  else
    printf('Using texture format %s.'#13#10, [gl_tex_format_string]);

  if gl_screensync then
    OldVSync(vsmSync)
  else
    OldVSync(vsmNoSync);

  OldInitLightTable;
  ShimEvent('gld_CalculateSky 100000');
  if GOldCache = nil then
    I_Error('R_InitDynamicLights(): the dynamic lights are not configured (ComposeEngine was not called)');
  printf('SC_ParceDynamicLights: Parsing LIGHTDEF lumps.'#13#10);
  if GOldCache.Load(gldefs_as_lightdef) then
    lightdeflumppresent := true;
  ShimEvent('gld_InitDynamicShadows');
  ShimEvent('gld_InitModels');
  ShimEvent('gld_InitVoxels');
  ShimEvent('gld_InitLightmap');
  ShimEvent('gld_InitAmbient');
end;

{ TTestOpenGlInitializer }

procedure TTestOpenGlInitializer.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  d_delphi.EventLog := TFakeGlLog.Lines;
  TFakeGlLog.Vendor := 'Fake Vendor Inc';
  TFakeGlLog.Renderer := 'Fake Renderer 9000';
  TFakeGlLog.Version := '4.5.0 Fake';
  TFakeGlLog.MaxTextureSize := 4096;
  TFakeGlLog.MaxTexture3DSize := 512;
  SCREENWIDTH := 800;
  SCREENHEIGHT := 600;
  fog_density := 150;
  WGL_EXT_swap_control := False;
end;

procedure TTestOpenGlInitializer.TearDown;
begin
  d_delphi.EventLog := nil;
  GOldCache := nil;
  GOldLightTable := nil;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
  devparm := False;
  gld_ColorTableEXT := nil;
  w_wad.ShimGlGammaLump := -1;
end;

function TTestOpenGlInitializer.MakeCase(const AExtensions: AnsiString; AMax3D: Integer): TInitializerCase;
begin
  Result.Extensions := AExtensions;
  Result.UsePaletted := 0;
  Result.UseSharedPalette := 0;
  Result.ColorTableAvailable := True;
  Result.DeveloperMode := False;
  Result.Max3DTextureSize := AMax3D;
  Result.TextureFormat := '';
  Result.ScreenSync := True;
  Result.GammaLump := False;
  Result.LightsFound := True;
end;

procedure TTestOpenGlInitializer.Prepare(const ACase: TInitializerCase);
var
  LGamma: string;
  LIndex: Integer;
begin
  TFakeGlLog.Extensions := ACase.Extensions;
  TFakeGlLog.MaxTexture3DSize := ACase.Max3DTextureSize;
  if ACase.ColorTableAvailable then
    TFakeGlLog.ExtensionProc := @TFakeGlLog.Clear
  else
    TFakeGlLog.ExtensionProc := nil;
  gl_use_paletted_texture := ACase.UsePaletted;
  gl_use_shared_texture_palette := ACase.UseSharedPalette;
  devparm := ACase.DeveloperMode;
  gl_tex_format_string := ACase.TextureFormat;
  gl_screensync := ACase.ScreenSync;
  gl_texture_filter_anisotropic := False;
  gl_paletted_texture := False;
  gl_shared_texture_palette := False;
  gld_ColorTableEXT := nil;
  canuselightmaps := True;
  gl_uselightmaps := True;
  lightdeflumppresent := False;
  gld_max_texturesize := 0;
  gld_max_texturesize3d := 0;
  gl_tex_format := GL_RGBA8;
  ShimTexFilter := FLT_LINEAR_MIPMAP_NEAREST;
  if ACase.GammaLump then
  begin
    LGamma := '';
    for LIndex := 0 to GAMMASIZE * 256 - 1 do
      LGamma := LGamma + Format('%d.%.4d'#13#10, [LIndex div 100, (LIndex * 37) mod 10000], TFormatSettings.Invariant);
    w_wad.ShimGlGammaLump := 12;
    w_wad.ShimGlGammaText := LGamma;
  end
  else
    w_wad.ShimGlGammaLump := -1;
  FillChar(FLightTable, SizeOf(FLightTable), 0);
  TFakeGlLog.Clear;
end;

function TTestOpenGlInitializer.Summary: string;
begin
  Result := Format('aniso=%s pal=%s shared=%s colortable=%s lightmaps=%s/%s max=%d/%d format=%d "%s" lightdef=%s',
    [BoolToStr(gl_texture_filter_anisotropic, True), BoolToStr(gl_paletted_texture, True),
     BoolToStr(gl_shared_texture_palette, True), BoolToStr(Assigned(gld_ColorTableEXT), True),
     BoolToStr(canuselightmaps, True), BoolToStr(gl_uselightmaps, True), gld_max_texturesize,
     gld_max_texturesize3d, gl_tex_format, gl_tex_format_string, BoolToStr(lightdeflumppresent, True)]);
end;

function TTestOpenGlInitializer.RunOld(const ACase: TInitializerCase): string;
begin
  Prepare(ACase);
  FillChar(FOldLightTable, SizeOf(FOldLightTable), 0);
  GOldLightTable := @FOldLightTable;
  GOldLightTableInitialized := False;
  GOldVSyncWarning := False;
  GOldCache := TFakeLightCache.Create;
  TFakeLightCache(GOldCache as TObject).LoadResult := ACase.LightsFound;
  OldInit(SCREENWIDTH, SCREENHEIGHT);
  Result := TFakeGlLog.Lines.Text + Summary;
  GOldCache := nil;
end;

function TTestOpenGlInitializer.RunNew(const ACase: TInitializerCase): string;
var
  LInitializer: TEngineGlInitializer;
  LCache: IDynLightRenderCache;
begin
  Prepare(ACase);
  LCache := TFakeLightCache.Create;
  TFakeLightCache(LCache as TObject).LoadResult := ACase.LightsFound;
  LInitializer := TEngineGlInitializer.Create(TEngineGlVSync.Create, @FLightTable);
  try
    LInitializer.Initialize(SCREENWIDTH, SCREENHEIGHT, LCache);
  finally
    LInitializer.Free;
  end;
  Result := TFakeGlLog.Lines.Text + Summary;
end;

procedure TTestOpenGlInitializer.ExpectSameFlow(const ACase: TInitializerCase; const AMessage: string);
var
  LOld, LNew: string;
begin
  LOld := RunOld(ACase);
  LNew := RunNew(ACase);
  Assert.AreEqual(LOld, LNew, AMessage);
end;

procedure TTestOpenGlInitializer.DovrebbeStampareIlDriverEChiedereLeEstensioniPerPrime;
var
  LLog: string;
begin
  LLog := RunNew(MakeCase('GL_ARB_multitexture', 512));
  Assert.IsTrue(LLog.StartsWith('glGetString 1F00'#13#10'printf GL_VENDOR: Fake Vendor Inc|'#13#10 +
    'glGetString 1F01'#13#10'printf GL_RENDERER: Fake Renderer 9000|'#13#10 +
    'glGetString 1F02'#13#10'printf GL_VERSION: 4.5.0 Fake|'#13#10 + 'glGetString 1F03'#13#10), LLog);
end;

procedure TTestOpenGlInitializer.DovrebbeDareLoStessoFlussoDelVecchioSenzaEstensioni;
var
  LCase: TInitializerCase;
begin
  LCase := MakeCase('', 512);
  ExpectSameFlow(LCase);
  LCase.DeveloperMode := True;
  LCase.Extensions := 'GL_FAKE_one  GL_fake_two';
  ExpectSameFlow(LCase);
end;

procedure TTestOpenGlInitializer.DovrebbeDareLoStessoFlussoDelVecchioConTutteLeEstensioni;
var
  LCase: TInitializerCase;
begin
  LCase := MakeCase('GL_EXT_texture_filter_anisotropic GL_EXT_paletted_texture GL_EXT_shared_texture_palette ' +
    'GL_ARB_multitexture GL_EXT_texture3D', 512);
  LCase.UsePaletted := 1;
  LCase.UseSharedPalette := 1;
  LCase.DeveloperMode := True;
  LCase.TextureFormat := 'gl_rgb5_a1';
  LCase.GammaLump := True;
  ExpectSameFlow(LCase);
  Assert.IsTrue(CompareMem(@FLightTable, @FOldLightTable, SizeOf(FLightTable)), 'tabella delle luci');
  LCase.ColorTableAvailable := False;
  ExpectSameFlow(LCase);
end;

procedure TTestOpenGlInitializer.DovrebbeDareLoStessoFlussoDelVecchioSuCombinazioniCasuali;
const
  Known: array[0..4] of AnsiString = ('GL_EXT_texture_filter_anisotropic', 'GL_EXT_paletted_texture',
    'GL_EXT_shared_texture_palette', 'GL_ARB_multitexture', 'GL_EXT_texture3D');
  Formats: array[0..4] of string = ('', 'GL_RGBA8', 'gl_rgba4', 'GL_RGB5_A1', 'nonsense');
  Sizes: array[0..3] of Integer = (64, 255, 256, 2048);
var
  LCase: TInitializerCase;
  LIndex, LExtension: Integer;
  LText: AnsiString;
  LOld, LNew: string;
begin
  RandSeed := 20261117;
  for LIndex := 1 to 250 do
  begin
    LText := '';
    for LExtension := 0 to High(Known) do
      if Random(3) > 0 then
        LText := LText + Known[LExtension] + ' ';
    LCase := MakeCase(LText, Sizes[Random(4)]);
    LCase.UsePaletted := Random(2);
    LCase.UseSharedPalette := Random(2);
    LCase.ColorTableAvailable := Random(2) = 0;
    LCase.DeveloperMode := Random(2) = 0;
    LCase.TextureFormat := Formats[Random(5)];
    LCase.ScreenSync := Random(2) = 0;
    LCase.GammaLump := Random(4) = 0;
    LCase.LightsFound := Random(2) = 0;
    LOld := RunOld(LCase);
    LNew := RunNew(LCase);
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LIndex) + ' estensioni "' + string(LText) + '"');
    Assert.IsTrue(CompareMem(@FLightTable, @FOldLightTable, SizeOf(FLightTable)), 'tabella, caso ' + IntToStr(LIndex));
  end;
end;

procedure TTestOpenGlInitializer.DovrebbeDisabilitareLeLightmapSenzaLeEstensioniOSenzaTexture3DGrandi;
var
  LLog: string;
begin
  LLog := RunNew(MakeCase('', 512));
  Assert.Contains(LLog, 'I_Warning gld_InitExtensions(): GL_ARB_MULTITEXTURE extension not supported');
  Assert.Contains(LLog, 'lightmaps=False/False');
  LLog := RunNew(MakeCase('GL_ARB_multitexture', 512));
  Assert.Contains(LLog, 'GL_EXT_TEXTURE3D extension not supported');
  LLog := RunNew(MakeCase('GL_ARB_multitexture GL_EXT_texture3D', 128));
  Assert.Contains(LLog, 'lightmaps=False/True', 'texture 3D troppo piccola: resta l''opzione ma non si usano');
  LLog := RunNew(MakeCase('GL_ARB_multitexture GL_EXT_texture3D', 256));
  Assert.Contains(LLog, 'lightmaps=True/True');
end;

procedure TTestOpenGlInitializer.DovrebbeLeggereLaTabellaDelleLuciDaGlGamma;
var
  LCase: TInitializerCase;
begin
  LCase := MakeCase('', 512);
  LCase.GammaLump := True;
  RunNew(LCase);
  // row 0, column 0 is 0.0000 and column 100 is 1.3700 in the text; the table keeps the square root
  Assert.AreEqual(Double(0), Double(FLightTable[0, 0]), 0);
  Assert.AreEqual(Sqrt(1.37), Double(FLightTable[0, 100]), 1E-5);
  Assert.AreEqual(Sqrt(2.74), Double(FLightTable[0, 200]), 1E-5);
end;

procedure TTestOpenGlInitializer.DovrebbeFareLaRadiceQuadrataAncheSenzaLump;
var
  LInitializer: TEngineGlInitializer;
begin
  Prepare(MakeCase('', 512));
  // without the lump the table is the one already in memory, with the square root taken once
  FLightTable[2, 7] := 9;
  FLightTable[0, 0] := 16;
  LInitializer := TEngineGlInitializer.Create(TEngineGlVSync.Create, @FLightTable);
  try
    LInitializer.Initialize(800, 600, TFakeLightCache.Create);
  finally
    LInitializer.Free;
  end;
  Assert.AreEqual(Double(3), Double(FLightTable[2, 7]), 0);
  Assert.AreEqual(Double(4), Double(FLightTable[0, 0]), 0);
end;

procedure TTestOpenGlInitializer.DovrebbeLeggereLaTabellaDelleLuciUnaSolaVolta;
var
  LCase: TInitializerCase;
  LInitializer: TEngineGlInitializer;
  LCache: IDynLightRenderCache;
  LCount, LIndex: Integer;
begin
  LCase := MakeCase('', 512);
  LCase.GammaLump := True;
  Prepare(LCase);
  LCache := TFakeLightCache.Create;
  LInitializer := TEngineGlInitializer.Create(TEngineGlVSync.Create, @FLightTable);
  try
    LInitializer.Initialize(800, 600, LCache);
    LInitializer.Initialize(800, 600, LCache);
  finally
    LInitializer.Free;
  end;
  LCount := 0;
  for LIndex := 0 to TFakeGlLog.Lines.Count - 1 do
    if TFakeGlLog.Lines[LIndex] = 'W_CheckNumForName GLGAMMA' then
      Inc(LCount);
  Assert.AreEqual(1, LCount);
end;

procedure TTestOpenGlInitializer.DovrebbeDareErroreSenzaLeLuciDinamiche;
var
  LInitializer: TEngineGlInitializer;
begin
  Prepare(MakeCase('', 512));
  LInitializer := TEngineGlInitializer.Create(TEngineGlVSync.Create, @FLightTable);
  try
    Assert.WillRaise(
      procedure
      begin
        LInitializer.Initialize(800, 600, nil);
      end, EShimFatalError);
  finally
    LInitializer.Free;
  end;
  Assert.Contains(TFakeGlLog.Lines.Text, 'I_Error R_InitDynamicLights(): the dynamic lights are not configured');
end;

procedure TTestOpenGlInitializer.DovrebbeRifiutareParametriNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineGlInitializer.Create(nil, @FLightTable);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    var
      LVSync: TEngineGlVSync;
    begin
      LVSync := TEngineGlVSync.Create;
      try
        TEngineGlInitializer.Create(LVSync, nil);
      finally
        LVSync.Free;
      end;
    end, EArgumentNilException);
end;

procedure TTestOpenGlInitializer.DovrebbeTenereLaSincronizzazioneVerticaleCheHaAvviato;
var
  LVSync: TEngineGlVSync;
  LInitializer: TEngineGlInitializer;
begin
  LVSync := TEngineGlVSync.Create;
  LInitializer := TEngineGlInitializer.Create(LVSync, @FLightTable);
  try
    Assert.IsTrue(LInitializer.VSync = LVSync);
  finally
    LInitializer.Free;
  end;
end;

end.
