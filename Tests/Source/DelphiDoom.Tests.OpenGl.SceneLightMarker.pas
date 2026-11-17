{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlSceneLightMarker - the buffer of the lights    }
{  against the text of gl_render.pas of before the class                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneLightMarker;

{$I Doom32.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  d_delphi,
  p_mobj_h,
  DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.Engine.GlScene.Types,
  DelphiDoom.Engine.GlScene.LightMarker;

type
  /// <summary>
  ///   A cache of lights that gives one fixed record for each light number and writes down every request
  ///   (index and level time), so the test sees which lights the marker asked for and in which order
  /// </summary>
  TFakeLightCache = class(TInterfacedObject, IDynLightRenderCache)
  strict private
    FLights: array[0..15] of TDynLightRender;
  public
    Requests: TStringList;
    constructor Create;
    destructor Destroy; override;
    function Load(AGldefsAsLightDef: Boolean): Boolean;
    procedure Clear;
    function Count: Integer;
    function GetLight(AIndex, ALevelTime: Integer): PDynLightRender;
  end;

  /// <summary>
  ///   The marker only fills the buffer of the lights (dlbuffer) from the camera, the lights of the cache and
  ///   the mobj of the sprite: the items are compared, bit for bit, with the ones of the old gld_MarkDLights
  ///   and gld_MarkDShadow, copied here from the text of before the class, on sprites made in memory
  ///   (mobjs with the fields the marker reads: type, radius and floor)
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneLightMarker = class(TObject)
  strict private
    FCache: TFakeLightCache;
    FCacheIntf: IDynLightRenderCache;
    FMarker: TEngineGlSceneLightMarker;
    FInfos: array[0..3] of mobjinfo_t;
    procedure ResetBuffer;
    function Snapshot: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonMarcareNienteSeLoSpriteNonHaLuci;
    [Test]
    procedure DovrebbeMarcareSoloLeLuciDelTipoDellaCosa;
    [Test]
    procedure DovrebbeCalcolareDistanzaEPosizioneDiUnaLuce;
    [Test]
    procedure DovrebbeChiedereLeLuciAllaCacheConIlTicDelLivello;
    [Test]
    procedure DovrebbeMarcareLOmbraConIlRaggioDellaCosa;
    [Test]
    procedure DovrebbeDareGliStessiElementiDelVecchioSuSpriteCasuali;
    [Test]
    procedure DovrebbeFarCrescereIlBufferDi32ElementiComeIlVecchio;
{$IFDEF STRIFE}
    [Test]
    procedure DovrebbeMarcareLeLuciEOmbreDelleCoseDiStrife;
{$ENDIF}
    [Test]
    procedure DovrebbeRifiutareUnaCacheNil;
  end;

implementation

uses
  dglOpenGL,
  m_fixed,
  p_tick,
  gl_defs,
  gl_shadows,
  r_dynlights;

{ TFakeLightCache }

constructor TFakeLightCache.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  Requests := TStringList.Create;
  for LIndex := 0 to High(FLights) do
  begin
    FLights[LIndex].R := LIndex / 16;
    FLights[LIndex].G := 1 - LIndex / 16;
    FLights[LIndex].B := 0.5;
    FLights[LIndex].Radius := 10 + LIndex;
    FLights[LIndex].X := LIndex * 0.25 - 1.5;
    FLights[LIndex].Y := LIndex * 0.125 + 0.0625;
    FLights[LIndex].Z := 2 - LIndex * 0.5;
    FLights[LIndex].Shadow := False;
  end;
end;

destructor TFakeLightCache.Destroy;
begin
  Requests.Free;
  inherited;
end;

function TFakeLightCache.Load(AGldefsAsLightDef: Boolean): Boolean;
begin
  Result := True;
end;

procedure TFakeLightCache.Clear;
begin
end;

function TFakeLightCache.Count: Integer;
begin
  Result := Length(FLights);
end;

function TFakeLightCache.GetLight(AIndex, ALevelTime: Integer): PDynLightRender;
begin
  Requests.Add(IntToStr(AIndex) + '@' + IntToStr(ALevelTime));
  Result := @FLights[AIndex];
end;

// The text of before the classes (gl_render.pas, commit before 97ec6a43e), only the names of the cache and
// of the level time changed.

var
  GOldCache: IDynLightRenderCache;

procedure OldMarkDShadow(sprite: PGLSprite);
var
  olddlitems: integer;
  dx, dy, dz: single;
  xdist, ydist, zdist: single;
  psl: Pdlsortitem_t;
begin
  xdist := camera.position[0] - sprite.x;
  ydist := camera.position[1] - sprite.y;
  zdist := camera.position[2] - sprite.z;

  if numdlitems >= realdlitems then
  begin
    olddlitems := realdlitems;
    realdlitems := numdlitems + 32;
    realloc(pointer(dlbuffer), olddlitems * SizeOf(dlsortitem_t), realdlitems * SizeOf(dlsortitem_t));
  end;

  psl := @dlbuffer[numdlitems];
  psl.l := gld_GetDynamicShadow(sprite.mo.info.radius div FRACUNIT);
  dx := xdist;
  dy := ydist;
  dz := zdist;
  psl.squaredist := dx * dx + dy * dy + dz * dz;
  psl.x := sprite.x;
  psl.y := sprite.mo.floorz / MAP_SCALE;
  psl.z := sprite.z;
  inc(numdlitems);
end;

procedure OldMarkDLights(sprite: PGLSprite);
var
  olddlitems: integer;
  l: PGLDRenderLight;
  i: integer;
  dx, dy, dz: single;
  xdist, ydist, zdist: single;
  psl: Pdlsortitem_t;
begin
  if sprite.dlights = nil then
    exit;

  xdist := camera.position[0] - sprite.x;
  ydist := camera.position[1] - sprite.y;
  zdist := camera.position[2] - sprite.z;

  for i := 0 to sprite.dlights.Count - 1 do
    if sprite.dlights[i].num1 = sprite.mo._type then
    begin
      l := GOldCache.GetLight(sprite.dlights[i].num2, TTickState.LevelTime);
      if numdlitems >= realdlitems then
      begin
        olddlitems := realdlitems;
        realdlitems := numdlitems + 32;
        realloc(pointer(dlbuffer), olddlitems * SizeOf(dlsortitem_t), realdlitems * SizeOf(dlsortitem_t));
      end;

      psl := @dlbuffer[numdlitems];
      psl.l := l;
      dx := xdist - l.x;
      dy := ydist - l.y;
      dz := zdist - l.z;
      psl.squaredist := dx * dx + dy * dy + dz * dz;
      psl.x := sprite.x + l.x;
      psl.y := sprite.y + l.y;
      psl.z := sprite.z + l.z;
      inc(numdlitems);
    end;
end;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

{ TTestOpenGlSceneLightMarker }

procedure TTestOpenGlSceneLightMarker.Setup;
begin
  FCache := TFakeLightCache.Create;
  FCacheIntf := FCache;
  GOldCache := FCacheIntf;
  FMarker := TEngineGlSceneLightMarker.Create(FCacheIntf);
  camera.position[0] := 1.25;
  camera.position[1] := -3.5;
  camera.position[2] := 7.0;
  TTickState.LevelTime := 123;
  FInfos[0].Radius := 20 * FRACUNIT;
  FInfos[1].Radius := 31 * FRACUNIT;
  FInfos[2].Radius := 45 * FRACUNIT;
  FInfos[3].Radius := 8 * FRACUNIT + 12345;
  ResetBuffer;
end;

procedure TTestOpenGlSceneLightMarker.TearDown;
begin
  ResetBuffer;
  FreeAndNil(FMarker);
  GOldCache := nil;
  FCacheIntf := nil;
  FCache := nil;
end;

procedure TTestOpenGlSceneLightMarker.ResetBuffer;
begin
  if dlbuffer <> nil then
    FreeMem(dlbuffer);
  dlbuffer := nil;
  numdlitems := 0;
  realdlitems := 0;
  if Assigned(FCache) then
    FCache.Requests.Clear;
end;

function TTestOpenGlSceneLightMarker.Snapshot: TStringList;
var
  LIndex: Integer;
begin
  Result := TStringList.Create;
  Result.Add('num=' + IntToStr(numdlitems) + ' real=' + IntToStr(realdlitems));
  for LIndex := 0 to numdlitems - 1 do
    Result.Add(Format('%p %s %s %s %s', [Pointer(dlbuffer[LIndex].l), FloatBits(dlbuffer[LIndex].squaredist),
      FloatBits(dlbuffer[LIndex].x), FloatBits(dlbuffer[LIndex].y), FloatBits(dlbuffer[LIndex].z)]));
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeRifiutareUnaCacheNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineGlSceneLightMarker.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeNonMarcareNienteSeLoSpriteNonHaLuci;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
begin
  FillChar(LSprite, SizeOf(LSprite), 0);
  LMobj._type := 5;
  LSprite.mo := @LMobj;
  FMarker.MarkLights(@LSprite);
  Assert.AreEqual(0, numdlitems);
  Assert.AreEqual(0, FCache.Requests.Count);
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeMarcareSoloLeLuciDelTipoDellaCosa;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LLights: T2DNumberList;
begin
  LLights := T2DNumberList.Create;
  try
    LLights.Add(4, 1);
    LLights.Add(9, 2);
    LLights.Add(4, 3);
    LLights.Add(7, 4);
    FillChar(LSprite, SizeOf(LSprite), 0);
    LMobj._type := 4;
    LSprite.mo := @LMobj;
    LSprite.dlights := LLights;
    FMarker.MarkLights(@LSprite);
    Assert.AreEqual(2, numdlitems);
    Assert.AreEqual('1@123|3@123', FCache.Requests[0] + '|' + FCache.Requests[1]);
    LMobj._type := 100;
    FMarker.MarkLights(@LSprite);
    Assert.AreEqual(2, numdlitems);
  finally
    LLights.Free;
  end;
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeCalcolareDistanzaEPosizioneDiUnaLuce;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LLights: T2DNumberList;
  LLight: PDynLightRender;
  LDx, LDy, LDz, LExpected: Single;
begin
  LLights := T2DNumberList.Create;
  try
    LLights.Add(4, 6);
    FillChar(LSprite, SizeOf(LSprite), 0);
    LMobj._type := 4;
    LSprite.mo := @LMobj;
    LSprite.dlights := LLights;
    LSprite.x := 2.0;
    LSprite.y := 0.5;
    LSprite.z := -1.0;
    FMarker.MarkLights(@LSprite);
    LLight := FCache.GetLight(6, 123);
    Assert.AreEqual(1, numdlitems);
    Assert.IsTrue(dlbuffer[0].l = LLight, 'la luce e quella della cache');
    LDx := (camera.position[0] - LSprite.x) - LLight.X;
    LDy := (camera.position[1] - LSprite.y) - LLight.Y;
    LDz := (camera.position[2] - LSprite.z) - LLight.Z;
    LExpected := LDx * LDx + LDy * LDy + LDz * LDz;
    Assert.AreEqual(FloatBits(LExpected), FloatBits(dlbuffer[0].squaredist));
    Assert.AreEqual(FloatBits(LSprite.x + LLight.X), FloatBits(dlbuffer[0].x));
    Assert.AreEqual(FloatBits(LSprite.y + LLight.Y), FloatBits(dlbuffer[0].y));
    Assert.AreEqual(FloatBits(LSprite.z + LLight.Z), FloatBits(dlbuffer[0].z));
  finally
    LLights.Free;
  end;
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeChiedereLeLuciAllaCacheConIlTicDelLivello;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LLights: T2DNumberList;
begin
  LLights := T2DNumberList.Create;
  try
    LLights.Add(1, 5);
    FillChar(LSprite, SizeOf(LSprite), 0);
    LMobj._type := 1;
    LSprite.mo := @LMobj;
    LSprite.dlights := LLights;
    TTickState.LevelTime := 4000;
    FMarker.MarkLights(@LSprite);
    TTickState.LevelTime := 4001;
    FMarker.MarkLights(@LSprite);
    Assert.AreEqual('5@4000|5@4001', FCache.Requests[0] + '|' + FCache.Requests[1]);
  finally
    LLights.Free;
  end;
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeMarcareLOmbraConIlRaggioDellaCosa;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LInfo: mobjinfo_t;
begin
  FillChar(LSprite, SizeOf(LSprite), 0);
  LInfo.radius := 31 * FRACUNIT + 5;
  LMobj.info := @LInfo;
  LMobj.floorz := 10 * FRACUNIT;
  LSprite.mo := @LMobj;
  LSprite.x := 3.0;
  LSprite.z := 2.0;
  FMarker.MarkShadow(@LSprite);
  Assert.AreEqual(1, numdlitems);
  Assert.IsTrue(dlbuffer[0].l = gld_GetDynamicShadow(31), 'ombra del raggio 31');
  Assert.AreEqual(FloatBits(3.0), FloatBits(dlbuffer[0].x));
  Assert.AreEqual(FloatBits(2.0), FloatBits(dlbuffer[0].z));
  Assert.AreEqual(FloatBits(10 * FRACUNIT / MAP_SCALE), FloatBits(dlbuffer[0].y));
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeDareGliStessiElementiDelVecchioSuSpriteCasuali;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LLists: array[0..2] of T2DNumberList;
  LCase, LKind, LIndex: Integer;
  LOld, LNew: TStringList;
  LOldRequests: string;
begin
  RandSeed := 20261117;
  for LKind := 0 to 2 do
    LLists[LKind] := T2DNumberList.Create;
  try
    for LIndex := 0 to 5 do
    begin
      LLists[1].Add(Random(4), Random(16));
      LLists[2].Add(Random(3), Random(16));
    end;
    LLists[2].Add(1, 15);
    for LCase := 1 to 400 do
    begin
      FillChar(LSprite, SizeOf(LSprite), 0);
      LMobj._type := Random(4);
      LMobj.floorz := (Random(2000) - 500) * FRACUNIT div 4;
      LMobj.info := @FInfos[Random(4)];
      LSprite.mo := @LMobj;
      LSprite.x := (Random(4000) - 2000) / 16.0;
      LSprite.y := (Random(4000) - 2000) / 16.0 + 0.1;
      LSprite.z := (Random(4000) - 2000) / 16.0 - 0.3;
      LKind := Random(3);
      if LKind > 0 then
        LSprite.dlights := LLists[LKind];
      camera.position[0] := (Random(4000) - 2000) / 8.0;
      camera.position[1] := (Random(4000) - 2000) / 8.0;
      camera.position[2] := (Random(4000) - 2000) / 8.0;
      TTickState.LevelTime := Random(100000);

      ResetBuffer;
      OldMarkDLights(@LSprite);
      OldMarkDShadow(@LSprite);
      OldMarkDLights(@LSprite);
      LOld := Snapshot;
      LOldRequests := FCache.Requests.Text;
      try
        ResetBuffer;
        FMarker.MarkLights(@LSprite);
        FMarker.MarkShadow(@LSprite);
        FMarker.MarkLights(@LSprite);
        LNew := Snapshot;
        try
          Assert.AreEqual(LOld.Text, LNew.Text, 'caso ' + IntToStr(LCase));
          Assert.AreEqual(LOldRequests, FCache.Requests.Text, 'richieste del caso ' + IntToStr(LCase));
        finally
          LNew.Free;
        end;
      finally
        LOld.Free;
      end;
    end;
  finally
    for LKind := 0 to 2 do
      LLists[LKind].Free;
  end;
end;

procedure TTestOpenGlSceneLightMarker.DovrebbeFarCrescereIlBufferDi32ElementiComeIlVecchio;
var
  LSprite: GLSprite;
  LMobj: mobj_t;
  LCount: Integer;
  LOld, LNew: TStringList;
begin
  FillChar(LSprite, SizeOf(LSprite), 0);
  LMobj.info := @FInfos[1];
  LMobj.floorz := 3 * FRACUNIT;
  LSprite.mo := @LMobj;
  LSprite.x := 1.0;
  ResetBuffer;
  for LCount := 1 to 70 do
    OldMarkDShadow(@LSprite);
  LOld := Snapshot;
  try
    ResetBuffer;
    for LCount := 1 to 70 do
      FMarker.MarkShadow(@LSprite);
    LNew := Snapshot;
    try
      Assert.AreEqual(LOld.Text, LNew.Text);
      Assert.AreEqual('num=70 real=96', LNew[0], 'cresce di 32 alla volta: 32, 64, 96');
    finally
      LNew.Free;
    end;
  finally
    LOld.Free;
  end;
end;

{$IFDEF STRIFE}
procedure TTestOpenGlSceneLightMarker.DovrebbeMarcareLeLuciEOmbreDelleCoseDiStrife;
const
  // Radius (map units) of the thing classes of Strife that have light: the player, the acolytes and the
  // Programmer, plus a thing with a radius that is not a whole number of units
  Radii: array[0..3] of Integer = (20, 31, 45, 8);
var
  LSprite: GLSprite;
  LMobjs: array[0..3] of mobj_t;
  LLights: T2DNumberList;
  LThing: Integer;
  LOld, LNew: TStringList;
begin
  LLights := T2DNumberList.Create;
  try
    for LThing := 0 to 3 do
    begin
      LMobjs[LThing]._type := 100 + LThing;
      LMobjs[LThing].info := @FInfos[LThing];
      LMobjs[LThing].floorz := (LThing - 1) * 24 * FRACUNIT;
      LLights.Add(100 + LThing, 3 * LThing + 1);
    end;
    LLights.Add(101, 2);
    FillChar(LSprite, SizeOf(LSprite), 0);
    LSprite.dlights := LLights;
    ResetBuffer;
    for LThing := 0 to 3 do
    begin
      LSprite.mo := @LMobjs[LThing];
      LSprite.x := 10.5 * LThing;
      LSprite.y := -2.25;
      LSprite.z := 4.0 + LThing;
      OldMarkDLights(@LSprite);
      OldMarkDShadow(@LSprite);
    end;
    LOld := Snapshot;
    try
      ResetBuffer;
      for LThing := 0 to 3 do
      begin
        LSprite.mo := @LMobjs[LThing];
        LSprite.x := 10.5 * LThing;
        LSprite.y := -2.25;
        LSprite.z := 4.0 + LThing;
        FMarker.MarkLights(@LSprite);
        FMarker.MarkShadow(@LSprite);
      end;
      LNew := Snapshot;
      try
        Assert.AreEqual(LOld.Text, LNew.Text);
        // 5 lights (one per thing, two for the second one) and 4 shadows
        Assert.AreEqual('num=9 real=32', LNew[0]);
        Assert.AreEqual(Radii[1], FInfos[1].Radius div FRACUNIT);
      finally
        LNew.Free;
      end;
    finally
      LOld.Free;
    end;
  finally
    LLights.Free;
  end;
end;
{$ENDIF}

end.
