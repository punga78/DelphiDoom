{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlSceneFrame - OpenGL call flow of the two ends  }
{  of the 3D scene against the text of gl_render.pas of before the class        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneFrame;

{$I Doom32.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>One frame of a run: the vertical sync option it starts with and whether it is finished</summary>
  TFramePlan = record
    ScreenSync: Boolean;
    Finish: Boolean;
  end;

  /// <summary>
  ///   Everything the two ends of the scene read: the options of the view, the camera, the player, the
  ///   colormap of the level (Doom and Strife) and the tints (extra_*)
  /// </summary>
  TFrameState = record
    SharedPalette: Boolean;
    ScreenBlocks: Integer;
    ScreenWidth, ScreenHeight: Integer;
    ViewWindowX, ViewWindowY, ViewWidth, ViewHeight: Integer;
    ViewX, ViewY, ViewZ: Integer;
    ViewAngle: LongWord;
    Aspect: Double;
    NearClip: Integer;
    ZAxisShift: Boolean;
    LookDir16: Integer;
    Wireframe: Boolean;
    FixedColormap: Integer;
    CustomColormap: Boolean;
    ExtraRed, ExtraGreen, ExtraBlue, ExtraAlpha: Single;
  end;

  /// <summary>
  ///   The frame only calls OpenGL (fake functions that log, no context) and its collaborators (shims that
  ///   write a line: the lists, the collectors and the painters of a frame get their BeginFrame): the lines,
  ///   the camera and the tints it leaves are compared with the old gld_StartDrawScene, gld_EndDrawScene and
  ///   infinitePerspective, copied here from the text of before the class, on runs of one to three frames
  ///   with random cameras, views, players and options. The vertical sync is the class TEngineGlVSync in the
  ///   old text too (it has its own test against the old gld_VSync)
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneFrame = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    function RandomState: TFrameState;
    procedure Apply(const AState: TFrameState);
    function Summary: string;
    function RunOld(const AState: TFrameState; const APlan: array of TFramePlan): string;
    function RunNew(const AState: TFrameState; const APlan: array of TFramePlan): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerUnaScenaIntera;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioSuFotogrammiCasuali;
    [Test]
    procedure DovrebbeFarGirareIlMarcatoreDelFotogrammaCome8Bit;
    [Test]
    procedure DovrebbeLimitareLInclinazioneDellaVistaA45Gradi;
    [Test]
    procedure DovrebbeSpegnereLoScissorConLaVistaASchermoPieno;
    [Test]
    procedure DovrebbeColorareLoSchermoConLaColormapFissaDellInvulnerabilita;
    [Test]
    procedure DovrebbeRifiutareOgniCollaboratoreNil;
  end;

implementation

uses
  dglOpenGL,
  d_delphi,
  doomdef,
  d_player,
  g_game,
  m_fixed,
  tables,
  p_mobj_h,
  r_main,
  r_draw,
  r_things,
  r_colormaps,
  r_dynlights,
  gl_defs,
  gl_tex,
  gl_render,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.Engine.GlVSync,
  DelphiDoom.Engine.Gl2dMode,
  DelphiDoom.Engine.GlScene.FlatCollector,
  DelphiDoom.Engine.GlScene.WallCollector,
  DelphiDoom.Engine.GlScene.WallPainter,
  DelphiDoom.Engine.GlScene.SpritePainter,
  DelphiDoom.Engine.GlScene.LightPainter,
  DelphiDoom.Engine.GlScene.Frame;

const
  GL_SCISSOR_TEST_ENABLE = $0C11;

var
  GColormap: customcolormap_t;
  GOldRoll, GOldYaw, GOldInvYaw, GOldPitch: float;
  GOldCameraX, GOldCameraY, GOldCameraZ: float;
  GOldScissorOn: Boolean;
  GOldRenderMarker: Byte;
  GOldDrawList: TGlSceneDrawList;
  GOldFlats: TEngineGlSceneFlatCollector;
  GOldWalls: TEngineGlSceneWallCollector;
  GOldWallPainter: TEngineGlSceneWallPainter;
  GOldSpritePainter: TEngineGlSceneSpritePainter;
  GOldLightPainter: TEngineGlSceneLightPainter;
  GOldVSync: TEngineGlVSync;

// The text of before the classes (gl_render.pas, commit before ondata2-177-1), only the names changed:
// the collectors and painters are the ones of this unit, the vertical sync is TEngineGlVSync, the 2D mode
// is TEngineGl2dMode, the players are the ones of the session.

procedure OldInfinitePerspective(fovy: GLdouble; aspect: GLdouble; znear: GLdouble);
var
  left, right, bottom, top: GLdouble;
  m: array[0..15] of GLdouble;
begin
  top := znear * tan(fovy * __glPi / 360.0);
  bottom := -top;
  left := bottom * aspect;
  right := top * aspect;

  m[ 0] := (2 * znear) / (right - left);
  m[ 4] := 0;
  m[ 8] := (right + left) / (right - left);
  m[12] := 0;

  m[ 1] := 0;
  m[ 5] := (2 * znear) / (top - bottom);
  m[ 9] := (top + bottom) / (top - bottom);
  m[13] := 0;

  m[ 2] := 0;
  m[ 6] := 0;
  m[10] := -1;
  m[14] := -2 * znear;

  m[ 3] := 0;
  m[ 7] := 0;
  m[11] := -1;
  m[15] := 0;

  glMultMatrixd(@m);
end;

procedure OldStartDrawScene;
var
  height: integer;
begin
  if gl_shared_texture_palette then
    glEnable(GL_SHARED_TEXTURE_PALETTE_EXT);
  gld_SetPalette(-1);

  GOldVSync.Update;

  if screenblocks > 10 then
    height := SCREENHEIGHT
  else if screenblocks = 10 then
    height := SCREENHEIGHT
  else
    height := (screenblocks * SCREENHEIGHT div 10) and not 7;

  glViewport(viewwindowx, SCREENHEIGHT - (height + viewwindowy - ((height - viewheight) div 2)), viewwidth, height);
  if screenblocks > 10 then
  begin
    glDisable(GL_SCISSOR_TEST);
    GOldScissorOn := false;
  end
  else
  begin
    glScissor(viewwindowx, SCREENHEIGHT - (viewheight + viewwindowy), viewwidth, viewheight);
    glEnable(GL_SCISSOR_TEST);
    GOldScissorOn := true;
  end;

  // Player coordinates
  GOldCameraX := -viewx / MAP_SCALE;
  GOldCameraY := viewy / MAP_SCALE;
  GOldCameraZ := viewz / MAP_SCALE;

  GOldYaw := 270.0 - (viewangle shr ANGLETOFINESHIFT) * 360.0 / FINEANGLES;
  GOldInvYaw := -90.0 + (viewangle shr ANGLETOFINESHIFT) * 360.0 / FINEANGLES;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

  glShadeModel(GL_SMOOTH);

  glEnable(GL_DEPTH_TEST);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;

  OldInfinitePerspective(64.0, 320.0 / 200.0 * monitor_relative_aspect, gl_nearclip / 100.0);

  if zaxisshift then
    GOldPitch := -TGameSession.Players[displayplayer].lookdir16 / 32 // JVAL Smooth Look Up/Down
  else
    GOldPitch := 0;
  // JVAL: Correct 2d bsp limitation
  if GOldPitch > 45 then
    GOldPitch := 45;

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glRotatef(GOldRoll,  0.0, 0.0, 1.0);
  glRotatef(GOldPitch, 1.0, 0.0, 0.0);
  glRotatef(GOldYaw,   0.0, 1.0, 0.0);
  glTranslatef(-GOldCameraX, -GOldCameraZ, -GOldCameraY);
  camera.rotation[0] := GOldPitch;
  camera.rotation[1] := GOldYaw;
  camera.rotation[2] := GOldRoll;
  camera.position[0] := GOldCameraX;
  camera.position[1] := GOldCameraZ;
  camera.position[2] := GOldCameraY;

  inc(GOldRenderMarker);
  GOldDrawList.BeginFrame(GOldRenderMarker);
  GOldFlats.BeginFrame(GOldRenderMarker);
  GOldWalls.BeginFrame(GOldRenderMarker, GOldYaw, GOldCameraZ);
  GOldWallPainter.BeginFrame(GOldCameraX, GOldCameraY, GOldCameraZ);
  GOldSpritePainter.BeginFrame(GOldInvYaw);
  GOldLightPainter.BeginFrame(GOldInvYaw);
  numdlitems := 0;

  if gl_renderwireframe then
  begin
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearDepth(1.0);
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  end
  else
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
end;

procedure OldEndDrawScene;
var
  player: Pplayer_t;
begin
  player := @TGameSession.Players[displayplayer];

  glDisable(GL_POLYGON_SMOOTH);

  glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);
  TEngineGl2dMode.SetMode;

  TRendererThings.R_DrawPlayer;

  if GOldScissorOn then
    glDisable(GL_SCISSOR_TEST);

  gld_DrawBackgroundFrame;

  if GOldScissorOn then
    glEnable(GL_SCISSOR_TEST);

  if player.fixedcolormap = 32 then
  begin
    glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ZERO);
    glColor4f(1.0, 1.0, 1.0, 1.0);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glDisable(GL_ALPHA_TEST);
    glColor4f(0.3, 0.3, 0.3, 0.3);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;
    glEnable(GL_ALPHA_TEST);
  end;

  if gl_renderwireframe then
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

  {$IFDEF DOOM_OR_STRIFE}
  if customcolormap <> nil then
  begin
    extra_red := extra_red + customcolormap.fog_r;
    if extra_red > 1.0 then
      extra_red := 1.0;
    extra_green := extra_green + customcolormap.fog_g;
    if extra_green > 1.0 then
      extra_green := 1.0;
    extra_blue := extra_blue + customcolormap.fog_b;
    if extra_blue > 1.0 then
      extra_blue := 1.0;
    extra_alpha := extra_alpha + 0.8;
    if extra_alpha > 1.0 then
      extra_alpha := 1.0;
  end;
  {$ENDIF}

  if extra_alpha > 0.0 then
  begin
    glDepthMask(False);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_ALPHA_TEST);
    glBlendFunc(GL_ONE, GL_ONE);

    glColor4f(extra_red * 0.25, extra_green * 0.25, extra_blue * 0.25, extra_alpha);
    glBindTexture(GL_TEXTURE_2D, 0);
    last_gltexture := nil;
    last_cm := -1;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(0.0, 0.0);
      glVertex2f(0.0, SCREENHEIGHT);
      glVertex2f(SCREENWIDTH, 0.0);
      glVertex2f(SCREENWIDTH, SCREENHEIGHT);
    glEnd;

    glDepthMask(True);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_ALPHA_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  end;

  glColor3f(1.0, 1.0, 1.0);
  glDisable(GL_SCISSOR_TEST);
  GOldScissorOn := false;
  if gl_shared_texture_palette then
    glDisable(GL_SHARED_TEXTURE_PALETTE_EXT);
end;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

{ TTestOpenGlSceneFrame }

procedure TTestOpenGlSceneFrame.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  d_delphi.EventLog := TFakeGlLog.Lines;
  WGL_EXT_swap_control := False;
  GColormap.fog_r := 0.3;
  GColormap.fog_g := 0.6;
  GColormap.fog_b := 0.9;
  GColormap.fog_density := 1.0;
  FillChar(TGameSession.Players, SizeOf(TGameSession.Players), 0);
  displayplayer := 1;
end;

procedure TTestOpenGlSceneFrame.TearDown;
begin
  customcolormap := nil;
  d_delphi.EventLog := nil;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
end;

function TTestOpenGlSceneFrame.RandomState: TFrameState;
const
  Fixed: array[0..2] of Integer = (0, 1, 32);
begin
  Result.SharedPalette := Random(2) = 0;
  Result.ScreenBlocks := 3 + Random(11);
  Result.ScreenWidth := 320 + Random(1700);
  Result.ScreenHeight := 200 + Random(900);
  Result.ViewWindowX := Random(100);
  Result.ViewWindowY := Random(100);
  Result.ViewWidth := 100 + Random(900);
  Result.ViewHeight := 100 + Random(600);
  Result.ViewX := (Random(20000) - 10000) * FRACUNIT div 7;
  Result.ViewY := (Random(20000) - 10000) * FRACUNIT div 5;
  Result.ViewZ := Random(300) * FRACUNIT + Random(FRACUNIT);
  Result.ViewAngle := LongWord(Random(MaxInt)) * 2 + LongWord(Random(2));
  Result.Aspect := 0.5 + Random(150) / 100;
  Result.NearClip := 1 + Random(20);
  Result.ZAxisShift := Random(4) > 0;
  Result.LookDir16 := Random(6000) - 3000;
  Result.Wireframe := Random(3) = 0;
  Result.FixedColormap := Fixed[Random(3)];
  Result.CustomColormap := Random(2) = 0;
  Result.ExtraRed := Random(100) / 100;
  Result.ExtraGreen := Random(100) / 100;
  Result.ExtraBlue := Random(100) / 100;
  if Random(2) = 0 then
    Result.ExtraAlpha := 0
  else
    Result.ExtraAlpha := Random(100) / 100;
end;

procedure TTestOpenGlSceneFrame.Apply(const AState: TFrameState);
begin
  gl_shared_texture_palette := AState.SharedPalette;
  screenblocks := AState.ScreenBlocks;
  SCREENWIDTH := AState.ScreenWidth;
  SCREENHEIGHT := AState.ScreenHeight;
  viewwindowx := AState.ViewWindowX;
  viewwindowy := AState.ViewWindowY;
  viewwidth := AState.ViewWidth;
  viewheight := AState.ViewHeight;
  viewx := AState.ViewX;
  viewy := AState.ViewY;
  viewz := AState.ViewZ;
  viewangle := AState.ViewAngle;
  monitor_relative_aspect := AState.Aspect;
  gl_nearclip := AState.NearClip;
  zaxisshift := AState.ZAxisShift;
  TGameSession.Players[displayplayer].lookdir16 := AState.LookDir16;
  TGameSession.Players[displayplayer].fixedcolormap := AState.FixedColormap;
  gl_renderwireframe := AState.Wireframe;
  if AState.CustomColormap then
    customcolormap := @GColormap
  else
    customcolormap := nil;
  extra_red := AState.ExtraRed;
  extra_green := AState.ExtraGreen;
  extra_blue := AState.ExtraBlue;
  extra_alpha := AState.ExtraAlpha;
  last_gltexture := nil;
  last_cm := 7;
  numdlitems := 99;
  camera.position[0] := 0;
  camera.position[1] := 0;
  camera.position[2] := 0;
  camera.rotation[0] := 0;
  camera.rotation[1] := 0;
  camera.rotation[2] := 0;
end;

function TTestOpenGlSceneFrame.Summary: string;
begin
  Result := Format('camera %s %s %s %s %s %s extra %s %s %s %s dl=%d last_cm=%d',
    [FloatBits(camera.position[0]), FloatBits(camera.position[1]), FloatBits(camera.position[2]),
     FloatBits(camera.rotation[0]), FloatBits(camera.rotation[1]), FloatBits(camera.rotation[2]),
     FloatBits(extra_red), FloatBits(extra_green), FloatBits(extra_blue), FloatBits(extra_alpha),
     numdlitems, last_cm]);
end;

function TTestOpenGlSceneFrame.RunOld(const AState: TFrameState; const APlan: array of TFramePlan): string;
var
  LIndex: Integer;
begin
  GOldDrawList := TGlSceneDrawList.Create;
  GOldFlats := TEngineGlSceneFlatCollector.Create;
  GOldWalls := TEngineGlSceneWallCollector.Create;
  GOldWallPainter := TEngineGlSceneWallPainter.Create;
  GOldSpritePainter := TEngineGlSceneSpritePainter.Create;
  GOldLightPainter := TEngineGlSceneLightPainter.Create;
  GOldVSync := TEngineGlVSync.Create;
  try
    Apply(AState);
    TFakeGlLog.Clear;
    GOldRenderMarker := 0;
    GOldScissorOn := False;
    GOldRoll := 0.0;
    for LIndex := 0 to High(APlan) do
    begin
      gl_screensync := APlan[LIndex].ScreenSync;
      OldStartDrawScene;
      if APlan[LIndex].Finish then
        OldEndDrawScene;
    end;
    Result := TFakeGlLog.Lines.Text + Summary + Format(' pitch=%s', [FloatBits(GOldPitch)]);
  finally
    GOldVSync.Free;
    GOldLightPainter.Free;
    GOldSpritePainter.Free;
    GOldWallPainter.Free;
    GOldWalls.Free;
    GOldFlats.Free;
    GOldDrawList.Free;
  end;
end;

function TTestOpenGlSceneFrame.RunNew(const AState: TFrameState; const APlan: array of TFramePlan): string;
var
  LDrawList: TGlSceneDrawList;
  LFlats: TEngineGlSceneFlatCollector;
  LWalls: TEngineGlSceneWallCollector;
  LWallPainter: TEngineGlSceneWallPainter;
  LSpritePainter: TEngineGlSceneSpritePainter;
  LLightPainter: TEngineGlSceneLightPainter;
  LVSync: TEngineGlVSync;
  LFrame: TEngineGlSceneFrame;
  LIndex: Integer;
begin
  LDrawList := TGlSceneDrawList.Create;
  LFlats := TEngineGlSceneFlatCollector.Create;
  LWalls := TEngineGlSceneWallCollector.Create;
  LWallPainter := TEngineGlSceneWallPainter.Create;
  LSpritePainter := TEngineGlSceneSpritePainter.Create;
  LLightPainter := TEngineGlSceneLightPainter.Create;
  LVSync := TEngineGlVSync.Create;
  LFrame := TEngineGlSceneFrame.Create(LDrawList, LFlats, LWalls, LWallPainter, LSpritePainter, LLightPainter,
    LVSync);
  try
    Apply(AState);
    TFakeGlLog.Clear;
    for LIndex := 0 to High(APlan) do
    begin
      gl_screensync := APlan[LIndex].ScreenSync;
      LFrame.Start;
      if APlan[LIndex].Finish then
        LFrame.Finish;
    end;
    Result := TFakeGlLog.Lines.Text + Summary + Format(' pitch=%s', [FloatBits(LFrame.Pitch)]);
  finally
    LFrame.Free;
    LVSync.Free;
    LLightPainter.Free;
    LSpritePainter.Free;
    LWallPainter.Free;
    LWalls.Free;
    LFlats.Free;
    LDrawList.Free;
  end;
end;

procedure TTestOpenGlSceneFrame.DovrebbeDareLeStesseChiamateDelVecchioPerUnaScenaIntera;
var
  LState: TFrameState;
  LPlan: array[0..0] of TFramePlan;
  LOld, LNew: string;
begin
  RandSeed := 1;
  LState := RandomState;
  LState.ScreenBlocks := 9;
  LState.FixedColormap := 0;
  LState.ExtraAlpha := 0.5;
  LPlan[0].ScreenSync := True;
  LPlan[0].Finish := True;
  LOld := RunOld(LState, LPlan);
  LNew := RunNew(LState, LPlan);
  Assert.AreEqual(LOld, LNew);
  Assert.Contains(LNew, 'Walls.BeginFrame 1 ', 'il primo fotogramma ha il marcatore 1');
  Assert.Contains(LNew, 'R_DrawPlayer');
end;

procedure TTestOpenGlSceneFrame.DovrebbeDareLeStesseChiamateDelVecchioSuFotogrammiCasuali;
var
  LCase, LFrames, LIndex: Integer;
  LState: TFrameState;
  LPlan: array of TFramePlan;
  LOld, LNew: string;
begin
  RandSeed := 20261117;
  for LCase := 1 to 400 do
  begin
    LState := RandomState;
    LFrames := 1 + Random(3);
    SetLength(LPlan, LFrames);
    for LIndex := 0 to LFrames - 1 do
    begin
      LPlan[LIndex].ScreenSync := Random(2) = 0;
      LPlan[LIndex].Finish := Random(4) > 0;
    end;
    LOld := RunOld(LState, LPlan);
    LNew := RunNew(LState, LPlan);
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestOpenGlSceneFrame.DovrebbeFarGirareIlMarcatoreDelFotogrammaCome8Bit;
var
  LState: TFrameState;
  LPlan: array of TFramePlan;
  LIndex: Integer;
  LOld, LNew: string;
begin
  RandSeed := 7;
  LState := RandomState;
  SetLength(LPlan, 300);
  for LIndex := 0 to High(LPlan) do
  begin
    LPlan[LIndex].ScreenSync := True;
    LPlan[LIndex].Finish := False;
  end;
  LOld := RunOld(LState, LPlan);
  LNew := RunNew(LState, LPlan);
  Assert.AreEqual(LOld, LNew);
  Assert.Contains(LNew, 'DrawList.BeginFrame 255');
  Assert.Contains(LNew, 'DrawList.BeginFrame 0'#13#10, 'dopo 255 si riparte da 0');
end;

procedure TTestOpenGlSceneFrame.DovrebbeLimitareLInclinazioneDellaVistaA45Gradi;
var
  LState: TFrameState;
  LPlan: array[0..0] of TFramePlan;
  LLog: string;
begin
  RandSeed := 3;
  LState := RandomState;
  LState.ZAxisShift := True;
  LState.LookDir16 := -5000;
  LPlan[0].ScreenSync := True;
  LPlan[0].Finish := False;
  LLog := RunNew(LState, LPlan);
  Assert.Contains(LLog, 'pitch=' + FloatBits(45));
  LState.LookDir16 := 640;
  LLog := RunNew(LState, LPlan);
  Assert.Contains(LLog, 'pitch=' + FloatBits(-20), 'guardare in alto da un angolo negativo');
  LState.ZAxisShift := False;
  LLog := RunNew(LState, LPlan);
  Assert.Contains(LLog, 'pitch=' + FloatBits(0), 'senza lo spostamento lungo Z la vista e piatta');
end;

procedure TTestOpenGlSceneFrame.DovrebbeSpegnereLoScissorConLaVistaASchermoPieno;
var
  LState: TFrameState;
  LPlan: array[0..0] of TFramePlan;
  LLog: string;
begin
  RandSeed := 5;
  LState := RandomState;
  LPlan[0].ScreenSync := True;
  LPlan[0].Finish := False;
  LState.ScreenBlocks := 12;
  LLog := RunNew(LState, LPlan);
  Assert.Contains(LLog, 'glDisable ' + IntToHex(GL_SCISSOR_TEST_ENABLE, 4));
  Assert.DoesNotContain(LLog, 'glScissor');
  LState.ScreenBlocks := 8;
  LLog := RunNew(LState, LPlan);
  Assert.Contains(LLog, 'glScissor ');
  Assert.Contains(LLog, 'glEnable ' + IntToHex(GL_SCISSOR_TEST_ENABLE, 4));
end;

procedure TTestOpenGlSceneFrame.DovrebbeColorareLoSchermoConLaColormapFissaDellInvulnerabilita;
var
  LState: TFrameState;
  LPlan: array[0..0] of TFramePlan;
  LLog: string;
begin
  RandSeed := 9;
  LState := RandomState;
  LState.FixedColormap := 32;
  LState.ExtraAlpha := 0;
  LState.CustomColormap := False;
  LPlan[0].ScreenSync := True;
  LPlan[0].Finish := True;
  LLog := RunNew(LState, LPlan);
  // two full screen quads: the inverse one and the grey one
  Assert.Contains(LLog, 'glBlendFunc 0307 0000');
  Assert.Contains(LLog, 'glColor4f ' + FloatBits(0.3) + ' ' + FloatBits(0.3) + ' ' + FloatBits(0.3) + ' ' +
    FloatBits(0.3));
  LState.FixedColormap := 0;
  LLog := RunNew(LState, LPlan);
  Assert.DoesNotContain(LLog, 'glBlendFunc 0307 0000');
end;

procedure TTestOpenGlSceneFrame.DovrebbeRifiutareOgniCollaboratoreNil;
var
  LDrawList: TGlSceneDrawList;
  LFlats: TEngineGlSceneFlatCollector;
  LWalls: TEngineGlSceneWallCollector;
  LWallPainter: TEngineGlSceneWallPainter;
  LSpritePainter: TEngineGlSceneSpritePainter;
  LLightPainter: TEngineGlSceneLightPainter;
  LVSync: TEngineGlVSync;
begin
  LDrawList := TGlSceneDrawList.Create;
  LFlats := TEngineGlSceneFlatCollector.Create;
  LWalls := TEngineGlSceneWallCollector.Create;
  LWallPainter := TEngineGlSceneWallPainter.Create;
  LSpritePainter := TEngineGlSceneSpritePainter.Create;
  LLightPainter := TEngineGlSceneLightPainter.Create;
  LVSync := TEngineGlVSync.Create;
  try
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(nil, LFlats, LWalls, LWallPainter,
      LSpritePainter, LLightPainter, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, nil, LWalls, LWallPainter,
      LSpritePainter, LLightPainter, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, LFlats, nil, LWallPainter,
      LSpritePainter, LLightPainter, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, LFlats, LWalls, nil,
      LSpritePainter, LLightPainter, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, LFlats, LWalls, LWallPainter,
      nil, LLightPainter, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, LFlats, LWalls, LWallPainter,
      LSpritePainter, nil, LVSync) end, EArgumentNilException);
    Assert.WillRaise(procedure begin TEngineGlSceneFrame.Create(LDrawList, LFlats, LWalls, LWallPainter,
      LSpritePainter, LLightPainter, nil) end, EArgumentNilException);
  finally
    LVSync.Free;
    LLightPainter.Free;
    LSpritePainter.Free;
    LWallPainter.Free;
    LWalls.Free;
    LFlats.Free;
    LDrawList.Free;
  end;
end;

end.
