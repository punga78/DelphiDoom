{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlHudPainter - OpenGL call flow against the      }
{  text of gl_render.pas of before the class                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.HudPainter;

{$I Doom32.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>
  ///   The HUD painter only calls OpenGL (fake functions that log, no context) and, through the shims of the
  ///   texture cache and of the light helpers of gl_render, writes lines in the same log: the calls of the
  ///   four methods are compared with the old gld_DrawNumPatch, gld_DrawBackground, gld_DrawBackgroundFrame
  ///   and gld_DrawWeapon, copied here from the text of before the class, on textures, flags, zooms, view
  ///   windows and players made in memory. The project of each game defines its game, so the statusbar rules
  ///   of DrawBackground are the ones of that game
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlHudPainter = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    procedure UseTexture(const ARandomize: Boolean);
    function Lines: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareELegareLaPatchSenzaDisegnareSeNonCEUnaTexture;
    [Test]
    procedure DovrebbeUsareLaTabellaDiTraduzioneSoloConIlFlagTrans;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLaPatchSuTutteLeCombinazioni;
    [Test]
    procedure DovrebbeInvertireLeCoordinateDiTexturaConIlFlagFlip;
    [Test]
    procedure DovrebbeAllargareELaPatchConLoZoomRestandoCentrata;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLoSfondo;
    [Test]
    procedure DovrebbeNonDisegnareLoSfondoSenzaTexture;
    [Test]
    procedure DovrebbeNonDisegnareLaCorniceDentroLoSchermoIntero;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLaCornice;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLArmaSuTutteLeCombinazioni;
    [Test]
    procedure DovrebbeRimettereBlendEAlphaDopoLArmaTrasparente;
    [Test]
    procedure DovrebbeNonDisegnareLArmaSenzaTexture;
  end;

implementation

uses
  dglOpenGL,
  d_delphi,
  doomdef,
  m_fixed,
  p_mobj_h,
  d_player,
  r_renderstyle,
  r_defs,
  r_main,
  r_draw,
  r_data,
  v_video,
  w_wad,
  gl_defs,
  gl_tex,
  gl_render,
  {$IFDEF DOOM}
  st_stuff,
  {$ENDIF}
  DelphiDoom.Engine.GlHudPainter;

// The text of before the classes (gl_render.pas, commit before ondata2-177-1), only the names changed.

procedure OldDrawNumPatch(x, y: integer; lump: integer; cm: integer; flags: integer;
  const zoomx: float = 1.0; const zoomy: float = 1.0);

  function SCALE_X(const xx: integer): float;
  begin
    if flags and VPT_STRETCH <> 0 then
      result := xx * SCREENWIDTH / 320.0
    else
      result := xx;
  end;

  function SCALE_Y(const yy: integer): float;
  begin
    if flags and VPT_STRETCH <> 0 then
      result := yy * SCREENHEIGHT / 200.0
    else
      result := yy;
  end;

var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  width, height: float;
  xpos, ypos: float;
  dx, dy: float;
begin
  if flags and VPT_TRANS <> 0 then
  begin
    gltexture := gld_RegisterPatch(lump, cm, flags and VPT_NOUNLOAD = 0);
    gld_BindPatch(gltexture, cm);
  end
  else
  begin
    gltexture := gld_RegisterPatch(lump, Ord(CR_DEFAULT), flags and VPT_NOUNLOAD = 0);
    gld_BindPatch(gltexture, Ord(CR_DEFAULT));
  end;
  if gltexture = nil then
    exit;
  fV1 := 0.0;
  fV2 := gltexture.height / gltexture.tex_height;
  if flags and VPT_FLIP <> 0 then
  begin
    fU1 := gltexture.width / gltexture.tex_width;
    fU2 := 0.0;
  end
  else
  begin
    fU1 := 0.0;
    fU2 := gltexture.width / gltexture.tex_width;
  end;
  xpos := SCALE_X(x - gltexture.leftoffset);
  ypos := SCALE_Y(y - gltexture.topoffset);
  width := SCALE_X(gltexture.realtexwidth);
  height := SCALE_Y(gltexture.realtexheight);
  if (zoomx <> 1.0) or (zoomy <> 1.0) then
  begin
    dx := width * zoomx - width;
    dy := height * zoomy - height;
    xpos := xpos - dx / 2;
    ypos := ypos - dy / 2;
    width := width + dx;
    height := height + dy;
  end;

  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(xpos, ypos);
    glTexCoord2f(fU1, fV2);
    glVertex2f(xpos, ypos + height);
    glTexCoord2f(fU2, fV1);
    glVertex2f(xpos + width, ypos);
    glTexCoord2f(fU2, fV2);
    glVertex2f(xpos + width, ypos + height);
  glEnd;
end;

procedure OldDrawBackground(const name: string);
var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  width, height: float;
{$IFDEF DOOM}
  sbar: Integer;
{$ENDIF}
begin
  gltexture := gld_RegisterFlat(TWadRoutines.W_GetNumForName(name), false, -1);
  gld_BindFlat(gltexture, -1);
  if gltexture = nil then
    exit;
  fU1 := 0;
  fV1 := 0;
  fU2 := 320 / gltexture.realtexwidth;
  {$IFDEF DOOM}
  if statusbarstretch then
    sbar := 0
  else
    sbar := ST_HEIGHT;
  {$ENDIF}
  fV2 := (200{$IFDEF DOOM} - sbar{$ENDIF}) / gltexture.realtexheight;
  width := SCREENWIDTH;
  height := SCREENHEIGHT{$IFDEF DOOM} - sbar * SCREENHEIGHT / 200{$ENDIF};

  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(0.0, 0.0);
    glTexCoord2f(fU1, fV2);
    glVertex2f(0.0, height);
    glTexCoord2f(fU2, fV1);
    glVertex2f(width, 0);
    glTexCoord2f(fU2, fV2);
    glVertex2f(width, height);
  glEnd;
end;

procedure OldDrawBackgroundFrame;
var
  x1, x2, y1, y2: integer;
begin
  if (viewwindowx <= 0) and (viewwindowy <= 0) then
    Exit;

  x1 := viewwindowx - 1;
  x2 := x1 + viewwidth + 2;
  y1 := viewwindowy - 1;
  y2 := y1 + viewheight + 2;

  glDisable(GL_TEXTURE_2D);

  glColor4f(0.5, 0.5, 0.5, 1.0);
  glBegin(GL_LINE_STRIP);
    glVertex2i(x1, y1);
    glVertex2i(x2, y1);
    glVertex2i(x2, y2);
    glVertex2i(x1, y2);
    glVertex2i(x1, y1);
  glEnd;

  glEnable(GL_TEXTURE_2D);
end;

procedure OldDrawWeapon(weaponlump: integer; vis: Pvissprite_t; lightlevel: integer);
var
  gltexture: PGLTexture;
  fU1, fU2, fV1, fV2: float;
  x1, y1, x2, y2: integer;
  scale: float;
  light: float;
  restoreblend: boolean;
begin
  gltexture := gld_RegisterPatch(firstspritelump + weaponlump, Ord(CR_DEFAULT));
  if gltexture = nil then
    exit;
  gld_BindPatch(gltexture, Ord(CR_DEFAULT));
  fU1 := 0.0;
  fV1 := 0.0;
  fU2 := gltexture.width / gltexture.tex_width;
  fV2 := gltexture.height / gltexture.tex_height;
  x1 := viewwindowx + vis.x1;
  x2 := viewwindowx + vis.x2;
  scale := vis.scale / FRACUNIT;
  y1 := viewwindowy + centery - round((vis.texturemid / FRACUNIT) * scale);
  y2 := y1 + round(gltexture.realtexheight * scale) + 1;
  light := gld_CalcLightLevel(lightlevel);

// JVAL??  viewplayer.mo.renderstyle = mrs_translucent
  if viewplayer.mo.flags and MF_SHADOW <> 0 then
  begin
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.1);
    glColor4f(0.2, 0.2, 0.2, 0.33);
    restoreblend := true;
  end
  else
  begin
    if (viewplayer.mo.flags_ex and MF_EX_TRANSPARENT <> 0) or
       (viewplayer.mo.renderstyle = mrs_translucent) then
    begin
      gld_StaticLightAlpha(light, tran_filter_pct / 100.0);
      restoreblend := true;
    end
    else
    begin
      gld_StaticLight(light);
      restoreblend := false;
    end;
  end;
  glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fU1, fV1);
    glVertex2f(x1, y1);
    glTexCoord2f(fU1, fV2);
    glVertex2f(x1, y2);
    glTexCoord2f(fU2, fV1);
    glVertex2f(x2, y1);
    glTexCoord2f(fU2, fV2);
    glVertex2f(x2, y2);
  glEnd;
  if restoreblend then
  begin
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GEQUAL, 0.5);
  end;
  glColor3f(1.0, 1.0, 1.0);
end;

var
  GTexture: GLTexture;
  GMobj: mobj_t;
  GPlayer: player_t;

{ TTestOpenGlHudPainter }

procedure TTestOpenGlHudPainter.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  d_delphi.EventLog := TFakeGlLog.Lines;
  SCREENWIDTH := 800;
  SCREENHEIGHT := 600;
  FillChar(GTexture, SizeOf(GTexture), 0);
  FillChar(GMobj, SizeOf(GMobj), 0);
  FillChar(GPlayer, SizeOf(GPlayer), 0);
  GPlayer.mo := @GMobj;
  viewplayer := @GPlayer;
  statusbarstretch := True;
  viewwindowx := 0;
  viewwindowy := 0;
  viewwidth := 0;
  viewheight := 0;
  centery := 0;
  firstspritelump := 1000;
  tran_filter_pct := 66;
  ShimTexture := @GTexture;
  UseTexture(False);
end;

procedure TTestOpenGlHudPainter.TearDown;
begin
  ShimTexture := nil;
  viewplayer := nil;
  d_delphi.EventLog := nil;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
end;

procedure TTestOpenGlHudPainter.UseTexture(const ARandomize: Boolean);
begin
  if ARandomize then
  begin
    GTexture.tex_width := 1 shl (3 + Random(5));
    GTexture.tex_height := 1 shl (3 + Random(5));
    GTexture.width := 1 + Random(GTexture.tex_width);
    GTexture.height := 1 + Random(GTexture.tex_height);
    GTexture.leftoffset := Random(200) - 100;
    GTexture.topoffset := Random(200) - 100;
    GTexture.realtexwidth := GTexture.width + Random(8);
    GTexture.realtexheight := GTexture.height + Random(8);
  end
  else
  begin
    GTexture.tex_width := 64;
    GTexture.tex_height := 128;
    GTexture.width := 50;
    GTexture.height := 100;
    GTexture.leftoffset := 25;
    GTexture.topoffset := 80;
    GTexture.realtexwidth := 64;
    GTexture.realtexheight := 128;
  end;
end;

function TTestOpenGlHudPainter.Lines: string;
begin
  Result := TFakeGlLog.Lines.Text;
end;

procedure TTestOpenGlHudPainter.DovrebbeRegistrareELegareLaPatchSenzaDisegnareSeNonCEUnaTexture;
begin
  ShimTexture := nil;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawNumPatch(10, 20, 77, 3, 0);
  Assert.AreEqual('gld_RegisterPatch 77 ' + IntToStr(Ord(CR_DEFAULT)) + ' True'#13#10 +
    'gld_BindPatch False ' + IntToStr(Ord(CR_DEFAULT)) + #13#10, Lines);
end;

procedure TTestOpenGlHudPainter.DovrebbeUsareLaTabellaDiTraduzioneSoloConIlFlagTrans;
begin
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawNumPatch(10, 20, 77, 3, VPT_TRANS or VPT_NOUNLOAD);
  Assert.StartsWith('gld_RegisterPatch 77 3 False'#13#10'gld_BindPatch True 3'#13#10, Lines);
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawNumPatch(10, 20, 77, 3, 0);
  Assert.StartsWith('gld_RegisterPatch 77 ' + IntToStr(Ord(CR_DEFAULT)) + ' True'#13#10, Lines);
end;

procedure TTestOpenGlHudPainter.DovrebbeDareLeStesseChiamateDelVecchioPerLaPatchSuTutteLeCombinazioni;
var
  LCase, LFlags, LX, LY, LLump, LColorMap: Integer;
  LZoomX, LZoomY: Single;
  LOld, LNew: string;
begin
  RandSeed := 20261117;
  for LCase := 1 to 600 do
  begin
    UseTexture(True);
    SCREENWIDTH := 320 + Random(1700);
    SCREENHEIGHT := 200 + Random(900);
    LFlags := Random(16);
    LX := Random(400) - 40;
    LY := Random(300) - 40;
    LLump := Random(3000);
    LColorMap := Random(24);
    LZoomX := 1.0;
    LZoomY := 1.0;
    if Random(2) = 0 then
    begin
      LZoomX := 0.25 + Random(12) / 4;
      LZoomY := 0.25 + Random(12) / 4;
    end;
    TFakeGlLog.Clear;
    OldDrawNumPatch(LX, LY, LLump, LColorMap, LFlags, LZoomX, LZoomY);
    LOld := Lines;
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawNumPatch(LX, LY, LLump, LColorMap, LFlags, LZoomX, LZoomY);
    LNew := Lines;
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeInvertireLeCoordinateDiTexturaConIlFlagFlip;
var
  LNormal, LFlipped: TStringList;
begin
  LNormal := TStringList.Create;
  LFlipped := TStringList.Create;
  try
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawNumPatch(0, 0, 5, 0, 0);
    LNormal.Assign(TFakeGlLog.Lines);
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawNumPatch(0, 0, 5, 0, VPT_FLIP);
    LFlipped.Assign(TFakeGlLog.Lines);
    // lines: 0 register, 1 bind, 2 begin, 3 texcoord of the first vertex
    Assert.AreNotEqual(LNormal[3], LFlipped[3]);
    Assert.AreEqual(LNormal[3], LFlipped[7], 'il terzo vertice capovolto ha la U del primo normale');
  finally
    LFlipped.Free;
    LNormal.Free;
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeAllargareELaPatchConLoZoomRestandoCentrata;
var
  LPlain, LZoomed: TStringList;
begin
  LPlain := TStringList.Create;
  LZoomed := TStringList.Create;
  try
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawNumPatch(100, 100, 5, 0, 0);
    LPlain.Assign(TFakeGlLog.Lines);
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawNumPatch(100, 100, 5, 0, 0, 2.0, 2.0);
    LZoomed.Assign(TFakeGlLog.Lines);
    Assert.AreEqual(LPlain.Count, LZoomed.Count);
    Assert.AreNotEqual(LPlain[4], LZoomed[4], 'il primo vertice si sposta');
  finally
    LZoomed.Free;
    LPlain.Free;
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeDareLeStesseChiamateDelVecchioPerLoSfondo;
var
  LCase: Integer;
  LOld, LNew: string;
begin
  RandSeed := 20261118;
  for LCase := 1 to 200 do
  begin
    UseTexture(True);
    SCREENWIDTH := 320 + Random(1700);
    SCREENHEIGHT := 200 + Random(900);
    statusbarstretch := Random(2) = 0;
    TFakeGlLog.Clear;
    OldDrawBackground('FLOOR' + IntToStr(LCase mod 7));
    LOld := Lines;
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawBackground('FLOOR' + IntToStr(LCase mod 7));
    LNew := Lines;
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LCase));
    Assert.Contains(LNew, 'glBegin 0005', 'un quadrilatero a strisce');
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeNonDisegnareLoSfondoSenzaTexture;
begin
  ShimTexture := nil;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawBackground('FLOOR4_8');
  Assert.AreEqual('W_GetNumForName FLOOR4_8'#13#10'gld_RegisterFlat 108 False -1'#13#10 +
    'gld_BindFlat False -1'#13#10, Lines);
end;

procedure TTestOpenGlHudPainter.DovrebbeNonDisegnareLaCorniceDentroLoSchermoIntero;
begin
  viewwindowx := 0;
  viewwindowy := 0;
  viewwidth := 800;
  viewheight := 600;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawBackgroundFrame;
  Assert.AreEqual('', Lines);
  viewwindowx := 0;
  viewwindowy := 5;
  TEngineGlHudPainter.DrawBackgroundFrame;
  Assert.AreNotEqual('', Lines, 'basta un solo scostamento positivo');
end;

procedure TTestOpenGlHudPainter.DovrebbeDareLeStesseChiamateDelVecchioPerLaCornice;
var
  LCase: Integer;
  LOld, LNew: string;
begin
  RandSeed := 20261119;
  for LCase := 1 to 200 do
  begin
    viewwindowx := Random(200) - 30;
    viewwindowy := Random(200) - 30;
    viewwidth := Random(800);
    viewheight := Random(600);
    TFakeGlLog.Clear;
    OldDrawBackgroundFrame;
    LOld := Lines;
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawBackgroundFrame;
    LNew := Lines;
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeDareLeStesseChiamateDelVecchioPerLArmaSuTutteLeCombinazioni;
var
  LCase, LWeapon, LLight: Integer;
  LSprite: vissprite_t;
  LOld, LNew: string;
begin
  RandSeed := 20261120;
  for LCase := 1 to 600 do
  begin
    UseTexture(True);
    viewwindowx := Random(100);
    viewwindowy := Random(100);
    centery := Random(300);
    firstspritelump := Random(2000);
    LSprite.x1 := Random(400) - 20;
    LSprite.x2 := LSprite.x1 + Random(300);
    LSprite.scale := Random(4 * FRACUNIT) + 1;
    LSprite.texturemid := Random(400 * FRACUNIT) - 100 * FRACUNIT;
    LWeapon := Random(100);
    LLight := Random(512) - 128;
    tran_filter_pct := Random(101);
    GMobj.flags := 0;
    if Random(4) = 0 then
      GMobj.flags := MF_SHADOW;
    GMobj.flags_ex := Random(2) * MF_EX_TRANSPARENT;
    GMobj.renderstyle := mobjrenderstyle_t(Random(Ord(NUMMOBJRENDERSTYLES)));
    TFakeGlLog.Clear;
    OldDrawWeapon(LWeapon, @LSprite, LLight);
    LOld := Lines;
    TFakeGlLog.Clear;
    TEngineGlHudPainter.DrawWeapon(LWeapon, @LSprite, LLight);
    LNew := Lines;
    Assert.AreEqual(LOld, LNew, 'caso ' + IntToStr(LCase));
  end;
end;

procedure TTestOpenGlHudPainter.DovrebbeRimettereBlendEAlphaDopoLArmaTrasparente;
var
  LSprite: vissprite_t;
begin
  LSprite.x1 := 10;
  LSprite.x2 := 60;
  LSprite.scale := FRACUNIT;
  LSprite.texturemid := 0;
  GMobj.flags := MF_SHADOW;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawWeapon(3, @LSprite, 128);
  Assert.Contains(Lines, 'glBlendFunc 0306 0303');
  Assert.IsTrue(Lines.EndsWith('glBlendFunc 0302 0303'#13#10'glAlphaFunc 0206 3F000000'#13#10 +
    'glColor3f 3F800000 3F800000 3F800000'#13#10), Lines);
  GMobj.flags := 0;
  GMobj.renderstyle := mrs_normal;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawWeapon(3, @LSprite, 128);
  Assert.DoesNotContain(Lines, 'glBlendFunc', 'senza trasparenza non tocca il blend');
end;

procedure TTestOpenGlHudPainter.DovrebbeNonDisegnareLArmaSenzaTexture;
var
  LSprite: vissprite_t;
begin
  ShimTexture := nil;
  LSprite.x1 := 0;
  LSprite.x2 := 10;
  LSprite.scale := FRACUNIT;
  LSprite.texturemid := 0;
  firstspritelump := 500;
  TFakeGlLog.Clear;
  TEngineGlHudPainter.DrawWeapon(7, @LSprite, 100);
  Assert.AreEqual('gld_RegisterPatch 507 ' + IntToStr(Ord(CR_DEFAULT)) + ' True'#13#10, Lines);
end;

end.
