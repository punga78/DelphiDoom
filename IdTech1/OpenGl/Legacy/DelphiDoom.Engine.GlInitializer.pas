//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the start of the OpenGL renderer (driver, extensions, state, tables)
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlInitializer;

interface

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.GlScene.Types,
  DelphiDoom.Engine.GlVSync;

type
  /// <summary>
  ///   What the OpenGL renderer does once, when the context exists: prints the driver, reads its extensions,
  ///   sets the OpenGL state of the game (blending, alpha test, fog, texture filtering and format), the vertical
  ///   sync, the light table of the GLGAMMA lump and starts the sky, the dynamic lights and shadows, the models,
  ///   the voxels, the lightmap and the ambient (it was gld_Init, gld_InitExtensions and gld_InitLightTable of
  ///   gl_render.pas)
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method, called once. It owns the vertical sync object
  /// </remarks>
  TEngineGlInitializer = class(TObject)
  strict private
    FVSync: TEngineGlVSync;
    FLightTable: PGlSceneLightTable;
    FLightTableInitialized: Boolean;
    procedure InitExtensions(const AExtensions: TDStringList);
    procedure InitLightTable;
  public
    /// <summary>The light table is the one of gl_render (what gld_LightTable returns), filled from GLGAMMA</summary>
    constructor Create(const AVSync: TEngineGlVSync; const ALightTable: PGlSceneLightTable);
    destructor Destroy; override;
    /// <summary>Initializes the renderer for the screen size (it was gld_Init)</summary>
    procedure Initialize(const AWidth, AHeight: Integer; const ADynamicLights: IDynLightRenderCache);
    /// <summary>The vertical sync the initializer started; the scene follows it at every frame</summary>
    property VSync: TEngineGlVSync read FVSync;
  end;

implementation

uses
  dglOpenGL,
  doomstat,
  doomdef,
  d_main,
  v_video,
  i_system,
  w_wad,
  gl_defs,
  gl_tex,
  gl_sky,
  gl_lights,
  gl_shadows,
  gl_models,
  gl_voxels,
  gl_lightmaps,
  gl_automap,
  gl_ambient,
  r_dynlights,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.GlContext.ExtensionList,
  DelphiDoom.Engine.GlLightmap.Types;

{ TEngineGlInitializer }

constructor TEngineGlInitializer.Create(const AVSync: TEngineGlVSync; const ALightTable: PGlSceneLightTable);
begin
  inherited Create;
  if not Assigned(AVSync) then
    raise EArgumentNilException.Create('AVSync');
  if not Assigned(ALightTable) then
    raise EArgumentNilException.Create('ALightTable');
  FVSync := AVSync;
  FLightTable := ALightTable;
end;

destructor TEngineGlInitializer.Destroy;
begin
  FVSync.Free;
  inherited Destroy;
end;

procedure TEngineGlInitializer.InitExtensions(const AExtensions: TDStringList);
begin
  gl_texture_filter_anisotropic := AExtensions.IndexOf('GL_EXT_TEXTURE_FILTER_ANISOTROPIC') > -1;
  if gl_texture_filter_anisotropic then
    printf('enabled anisotropic texture filtering'#13#10);
  if gl_use_paletted_texture <> 0 then
  begin
    gl_paletted_texture := AExtensions.IndexOf('GL_EXT_PALETTED_TEXTURE') > -1;
    gld_ColorTableEXT := lp3DFXFUNC(wglGetProcAddress('glColorTableEXT'));
    if not Assigned(gld_ColorTableEXT) then
      gl_paletted_texture := false
    else
      printf('using GL_EXT_paletted_texture'#13#10);
  end;
  if gl_use_shared_texture_palette <> 0 then
  begin
    gl_shared_texture_palette := AExtensions.IndexOf('GL_EXT_SHARED_TEXTURE_PALETTE') > -1;
    gld_ColorTableEXT := lp3DFXFUNC(wglGetProcAddress('glColorTableEXT'));
    if not Assigned(gld_ColorTableEXT) then
      gl_shared_texture_palette := false
    else
      printf('using GL_EXT_shared_texture_palette'#13#10);
  end;

  canuselightmaps := AExtensions.IndexOf('GL_ARB_MULTITEXTURE') > -1;
  if not canuselightmaps then
  begin
    I_Warning('gld_InitExtensions(): GL_ARB_MULTITEXTURE extension not supported, lightmap will be disabled'#13#10);
    gl_uselightmaps := false;
  end
  else
  begin
    canuselightmaps := AExtensions.IndexOf('GL_EXT_TEXTURE3D') > -1;
    if not canuselightmaps then
    begin
      I_Warning('gld_InitExtensions(): GL_EXT_TEXTURE3D extension not supported, lightmap will be disabled'#13#10);
      gl_uselightmaps := false;
    end;
  end;
  gld_InitAutomap;
end;

procedure TEngineGlInitializer.InitLightTable;
var
  sc: TScriptScanner;
  lump: integer;
  i, j: integer;
begin
  if FLightTableInitialized then
    Exit;

  lump := W_CheckNumForName('GLGAMMA');
  if lump > 0 then
  begin

    sc := TScriptScanner.Create(W_TextLumpNum(lump), TEngineScannerLog.Create);
    for i := 0 to GAMMASIZE - 1 do
      for j := 0 to 255 do
      begin
        sc.MustGetFloat;
        FLightTable^[i, j] := sc.AsFloat;
      end;
    sc.Free;
  end;

  for i := 0 to GAMMASIZE - 1 do
    for j := 0 to 255 do
      FLightTable^[i, j] := Sqrt(FLightTable^[i, j]);

  FLightTableInitialized := true;
end;

procedure TEngineGlInitializer.Initialize(const AWidth, AHeight: Integer; const ADynamicLights: IDynLightRenderCache);
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
  extensions_l := TGlExtensionList.Normalize(extensions);

  ext_lst := TDStringList.Create;
  try
    ext_lst.Text := extensions_l;
    if devparm then
      for i := 0 to ext_lst.count - 1 do
        printf('  %s'#13#10, [ext_lst.strings[i]]);
    InitExtensions(ext_lst);
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

  FVSync.Start;

  InitLightTable;
  gld_CalculateSky(100000.0);
  if ADynamicLights = nil then
    I_Error('R_InitDynamicLights(): the dynamic lights are not configured (ComposeEngine was not called)');
  printf('SC_ParceDynamicLights: Parsing LIGHTDEF lumps.'#13#10);
  if ADynamicLights.Load(gldefs_as_lightdef) then
    lightdeflumppresent := true;
  gld_InitDynamicShadows;
  gld_InitModels;
  gld_InitVoxels;
  gld_InitLightmap;
  gld_InitAmbient;
end;

end.
