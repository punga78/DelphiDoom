{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the draw list of a frame            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneDrawList;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.DrawList,
  DelphiDoom.GlScene.Factory,
  DelphiDoom.Tests.OpenGl.OldSceneDrawList;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneDrawList = class(TObject)
  strict private
    FList: TGlSceneDrawList;
    FOld: TOldSceneDrawList;
    FNextId: Integer;
    class function Sizes: TGlSceneItemSizes; static;
    procedure StartFrame;
    procedure AddWall;
    procedure AddFlat;
    procedure AddSprite;
    function Difference: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseListeDelVecchioSu600FotogrammiCasuali;
    [Test]
    procedure DovrebbeEssereVuotaAppenaCreata;
    [Test]
    procedure DovrebbeRifiutareUnaMisuraNonPositiva;
    [Test]
    procedure DovrebbeUnireGliElementiViciniDelloStessoTipoInUnaSerie;
    [Test]
    procedure DovrebbeAprireUnaSerieNuovaQuandoIlTipoCambia;
    [Test]
    procedure DovrebbeDareIlPostoDellElementoNelBloccoDelSuoTipo;
    [Test]
    procedure DovrebbeRipartireDallaPrimaSerieAOgniFotogramma;
    [Test]
    procedure DovrebbeLasciareLaSerieDelFotogrammaPrimaSeIlFotogrammaEVuoto;
    [Test]
    procedure DovrebbeTenereGliElementiOltreIlPrimoBlocco;
    [Test]
    procedure DovrebbeTenereLeSerieOltreIlPrimoBlocco;
    [Test]
    procedure DovrebbeRestareUsabileDopoRelease;
  end;

implementation

{ TTestOpenGlSceneDrawList }

class function TTestOpenGlSceneDrawList.Sizes: TGlSceneItemSizes;
begin
  Result.Wall := SizeOf(GLWall);
  Result.Flat := SizeOf(GLFlat);
  Result.Sprite := SizeOf(GLSprite);
end;

procedure TTestOpenGlSceneDrawList.Setup;
begin
  FList := TGlSceneFactory.CreateDrawList(Sizes);
  old_InitDrawList(FOld);
  FNextId := 1;
end;

procedure TTestOpenGlSceneDrawList.TearDown;
begin
  FreeAndNil(FList);
  old_NewLevel(FOld);
end;

procedure TTestOpenGlSceneDrawList.StartFrame;
begin
  old_StartFrame(FOld);
  FList.BeginFrame(FOld.rendermarker);
end;

procedure TTestOpenGlSceneDrawList.AddWall;
var
  LWall: GLWall;
begin
  FillChar(LWall, SizeOf(LWall), FNextId and $FF);
  LWall.id := FNextId;
  Inc(FNextId);
  old_AddWall(FOld, @LWall);
  PGLWall(FList.AddWall)^ := LWall;
end;

procedure TTestOpenGlSceneDrawList.AddFlat;
var
  LFlat: GLFlat;
begin
  FillChar(LFlat, SizeOf(LFlat), FNextId and $FF);
  LFlat.id := FNextId;
  Inc(FNextId);
  old_AddFlat(FOld, LFlat);
  PGLFlat(FList.AddFlat)^ := LFlat;
end;

procedure TTestOpenGlSceneDrawList.AddSprite;
var
  LSprite: GLSprite;
begin
  FillChar(LSprite, SizeOf(LSprite), FNextId and $FF);
  LSprite.id := FNextId;
  Inc(FNextId);
  old_AddSprite(FOld, LSprite);
  PGLSprite(FList.AddSprite)^ := LSprite;
end;

function TTestOpenGlSceneDrawList.Difference: string;
var
  LIndex: Integer;
  LOld: PGLDrawItem;
  LNew: PGlSceneRun;
begin
  Result := '';
  if FList.WallCount <> FOld.gld_drawinfo.num_walls then
    Exit(Format('walls: %d, old %d', [FList.WallCount, FOld.gld_drawinfo.num_walls]));
  if FList.FlatCount <> FOld.gld_drawinfo.num_flats then
    Exit(Format('flats: %d, old %d', [FList.FlatCount, FOld.gld_drawinfo.num_flats]));
  if FList.SpriteCount <> FOld.gld_drawinfo.num_sprites then
    Exit(Format('sprites: %d, old %d', [FList.SpriteCount, FOld.gld_drawinfo.num_sprites]));
  if (FList.WallCount > 0) and
     not CompareMem(FList.Walls, FOld.gld_drawinfo.walls, FList.WallCount * SizeOf(GLWall)) then
    Exit('the walls are not the same');
  if (FList.FlatCount > 0) and
     not CompareMem(FList.Flats, FOld.gld_drawinfo.flats, FList.FlatCount * SizeOf(GLFlat)) then
    Exit('the flats are not the same');
  if (FList.SpriteCount > 0) and
     not CompareMem(FList.Sprites, FOld.gld_drawinfo.sprites, FList.SpriteCount * SizeOf(GLSprite)) then
    Exit('the sprites are not the same');
  if FList.LastRun <> FOld.gld_drawinfo.num_drawitems then
    Exit(Format('last run: %d, old %d', [FList.LastRun, FOld.gld_drawinfo.num_drawitems]));
  if Assigned(FList.Runs) <> Assigned(FOld.gld_drawinfo.drawitems) then
    Exit('one of the two has no runs');
  if not Assigned(FList.Runs) then
    Exit;
  // the draw loops of the old code read the runs 0..num_drawitems, the one being filled too
  for LIndex := 0 to FList.LastRun do
  begin
    LOld := @FOld.gld_drawinfo.drawitems[LIndex];
    LNew := @FList.Runs[LIndex];
    if (Ord(LNew.Kind) <> Ord(LOld.itemtype)) or (LNew.Count <> LOld.itemcount) or
       (LNew.First <> LOld.firstitemindex) or (LNew.Marker <> LOld.rendermarker) then
      Exit(Format('run %d: kind %d count %d first %d marker %d, old %d %d %d %d', [LIndex, Ord(LNew.Kind),
        LNew.Count, LNew.First, LNew.Marker, Ord(LOld.itemtype), LOld.itemcount, LOld.firstitemindex,
        LOld.rendermarker]));
  end;
end;

procedure TTestOpenGlSceneDrawList.DovrebbeDareLeStesseListeDelVecchioSu600FotogrammiCasuali;
var
  LFrame: Integer;
  LItem: Integer;
  LItems: Integer;
  LKind: Integer;
  LRunLeft: Integer;
  LDifference: string;
begin
  RandSeed := 17709;
  LKind := 0;
  for LFrame := 1 to 600 do
  begin
    // a new level now and then: the old code lost the blocks and started from nothing
    if Random(97) = 0 then
    begin
      old_NewLevel(FOld);
      FList.Release;
    end;
    StartFrame;
    case Random(10) of
      0: LItems := 0;
      1: LItems := 1 + Random(3);
      2: LItems := 900 + Random(600);
    else
      LItems := 20 + Random(300);
    end;
    LRunLeft := 0;
    for LItem := 1 to LItems do
    begin
      if LRunLeft = 0 then
      begin
        LKind := Random(3);
        LRunLeft := 1 + Random(1 + Random(12));
      end;
      Dec(LRunLeft);
      case LKind of
        0: AddWall;
        1: AddFlat;
      else
        AddSprite;
      end;
    end;
    LDifference := Difference;
    if LDifference <> '' then
      Assert.Fail(Format('frame %d: %s', [LFrame, LDifference]));
  end;
  Assert.Pass;
end;

procedure TTestOpenGlSceneDrawList.DovrebbeEssereVuotaAppenaCreata;
begin
  Assert.AreEqual(0, FList.WallCount);
  Assert.AreEqual(0, FList.FlatCount);
  Assert.AreEqual(0, FList.SpriteCount);
  Assert.AreEqual(0, FList.LastRun);
  Assert.IsFalse(Assigned(FList.Runs));
  Assert.IsFalse(Assigned(FList.Walls));
end;

procedure TTestOpenGlSceneDrawList.DovrebbeRifiutareUnaMisuraNonPositiva;
var
  LSizes: TGlSceneItemSizes;
begin
  LSizes := Sizes;
  LSizes.Flat := 0;
  Assert.WillRaise(
    procedure
    begin
      TGlSceneFactory.CreateDrawList(LSizes).Free;
    end,
    EGlSceneException);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeUnireGliElementiViciniDelloStessoTipoInUnaSerie;
begin
  StartFrame;
  AddWall;
  AddWall;
  AddWall;
  Assert.AreEqual(0, FList.LastRun);
  Assert.AreEqual(Ord(gskWall), Ord(FList.Runs[0].Kind));
  Assert.AreEqual(3, FList.Runs[0].Count);
  Assert.AreEqual(0, FList.Runs[0].First);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeAprireUnaSerieNuovaQuandoIlTipoCambia;
begin
  StartFrame;
  AddWall;
  AddWall;
  AddFlat;
  AddWall;
  AddSprite;
  AddSprite;
  Assert.AreEqual(3, FList.LastRun);
  Assert.AreEqual(Ord(gskFlat), Ord(FList.Runs[1].Kind));
  Assert.AreEqual(1, FList.Runs[1].Count);
  Assert.AreEqual(Ord(gskWall), Ord(FList.Runs[2].Kind));
  Assert.AreEqual(2, FList.Runs[2].First, 'the third wall of the frame');
  Assert.AreEqual(Ord(gskSprite), Ord(FList.Runs[3].Kind));
  Assert.AreEqual(2, FList.Runs[3].Count);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeDareIlPostoDellElementoNelBloccoDelSuoTipo;
var
  LFirst: PGLFlat;
  LSecond: PGLFlat;
begin
  StartFrame;
  LFirst := FList.AddFlat;
  LSecond := FList.AddFlat;
  Assert.AreEqual(NativeUInt(FList.Flats), NativeUInt(LFirst));
  Assert.AreEqual<NativeUInt>(NativeUInt(FList.Flats) + SizeOf(GLFlat), NativeUInt(LSecond));
  Assert.AreEqual(2, FList.FlatCount);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeRipartireDallaPrimaSerieAOgniFotogramma;
begin
  StartFrame;
  AddWall;
  AddFlat;
  StartFrame;
  AddSprite;
  Assert.AreEqual(0, FList.LastRun);
  Assert.AreEqual(Ord(gskSprite), Ord(FList.Runs[0].Kind));
  Assert.AreEqual(1, FList.Runs[0].Count);
  Assert.AreEqual(0, FList.WallCount);
  Assert.AreEqual(Integer(FOld.rendermarker), Integer(FList.Runs[0].Marker));
end;

procedure TTestOpenGlSceneDrawList.DovrebbeLasciareLaSerieDelFotogrammaPrimaSeIlFotogrammaEVuoto;
begin
  // as the old code: the draw loops would still meet the first run of the frame before
  StartFrame;
  AddWall;
  AddWall;
  StartFrame;
  Assert.AreEqual(0, FList.LastRun);
  Assert.AreEqual(Ord(gskWall), Ord(FList.Runs[0].Kind));
  Assert.AreEqual(2, FList.Runs[0].Count);
  Assert.AreEqual(0, FList.WallCount);
  Assert.AreEqual('', Difference);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeTenereGliElementiOltreIlPrimoBlocco;
var
  LIndex: Integer;
begin
  StartFrame;
  for LIndex := 1 to 1000 do
    AddSprite;
  Assert.AreEqual(1000, FList.SpriteCount);
  Assert.AreEqual(1000, FList.Runs[0].Count);
  Assert.AreEqual('', Difference);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeTenereLeSerieOltreIlPrimoBlocco;
var
  LIndex: Integer;
begin
  StartFrame;
  for LIndex := 1 to 200 do
  begin
    AddWall;
    AddFlat;
  end;
  Assert.AreEqual(399, FList.LastRun);
  Assert.AreEqual('', Difference);
  // the frame after starts on runs that are already there
  StartFrame;
  for LIndex := 1 to 200 do
  begin
    AddFlat;
    AddSprite;
  end;
  Assert.AreEqual('', Difference);
end;

procedure TTestOpenGlSceneDrawList.DovrebbeRestareUsabileDopoRelease;
begin
  StartFrame;
  AddWall;
  AddFlat;
  FList.Release;
  old_NewLevel(FOld);
  Assert.IsFalse(Assigned(FList.Runs));
  Assert.AreEqual(0, FList.WallCount);
  StartFrame;
  AddSprite;
  AddWall;
  Assert.AreEqual(1, FList.LastRun);
  Assert.AreEqual('', Difference);
end;

end.
