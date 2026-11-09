{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer of the greed library (DUnitX)              }
{                                                                              }
{  The parity tests compare the pictures with the CRC that the ORIGINAL renderer }
{  of xGreed gave on the same scenarios (Tools\Verifica\175-render); the other   }
{  tests use a room of a few tiles and assets made in memory                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Render;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types,
  DelphiDoom.Greed.Render.Assets.Intf, DelphiDoom.Greed.Render.Tables, DelphiDoom.Greed.Render.State,
  DelphiDoom.Greed.Render.SpanSorter, DelphiDoom.Greed.Render.FrameRenderer, DelphiDoom.Tests.Greed.RenderRunner;

type
  /// <summary>Assets of a few bytes: two walls, two flats, one sprite and the tables that the renderer needs</summary>
  TRenderTestAssets = class(TInterfacedObject, IGreedRenderAssets)
  strict private
    FWalls: array[0..3] of TBytes;
    FFlats: array[0..3] of TBytes;
    FSprite: TBytes;
    FColorMaps: TBytes;
    FTransparency: TBytes;
    FBackdrop: TBytes;
  public
    const
      WALL_COLOR = 100;
      DOOR_COLOR = 120;
      FLOOR_COLOR = 50;
      CEILING_COLOR = 70;
      SPRITE_COLOR = 200;
    constructor Create;
    function GetWallCount: Integer;
    function GetFlatCount: Integer;
    function WallLump(AIndex: Integer): TBytes;
    function FlatLump(AIndex: Integer): TBytes;
    function SpriteLump(ALump: Integer): TBytes;
    function ColorMaps: TBytes;
    function Transparency: TBytes;
    function Backdrop: TBytes;
  end;

  TRenderTestClock = class(TInterfacedObject, IGreedRenderClock)
  public
    Time: Integer;
    function GetTimeCount: Integer;
    function GetSpriteMoveTime: Integer;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedRenderer = class(TObject)
  private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FClock: TRenderTestClock;
    FClockIntf: IGreedRenderClock;
    FRenderer: TGreedFrameRenderer;
    FRendererIntf: IGreedFrameRenderer;
    FPlayer: TGreedPlayerRecord;
    FFrameForNil: TGreedFrame;
    function Draw(AWidth, AHeight: Integer): TGreedFrame;
    function PixelAt(const AFrame: TGreedFrame; AX, AY: Integer): Byte;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareIlMuroAlCentro;
    [Test]
    procedure DovrebbeDisegnarePavimentoESoffitto;
    [Test]
    procedure DovrebbeDisegnareLoStessoAlCentroInBassaRisoluzione;
    [Test]
    procedure DovrebbeSegnareIMuriNellaMappaDelGiocatore;
    [Test]
    procedure DovrebbeDisegnareUnoSpriteDavantiAlMuro;
    [Test]
    procedure DovrebbeNascondereUnoSpriteDietroIlMuro;
    [Test]
    procedure DovrebbeDisegnareUnaPortaChiusa;
    [Test]
    procedure DovrebbeLasciareApertaLaPortaAperta;
    [Test]
    procedure DovrebbeFarAvanzareLAnimazioneDiUnoSprite;
    [Test]
    procedure DovrebbeTogliereUnoSpriteCheSiAutodistrugge;
    [Test]
    procedure DovrebbeSpostareLaVistaConLoScroll;
    [Test]
    procedure DovrebbeSollevareConUnQuadroTroppoPiccolo;
    [Test]
    procedure DovrebbeSollevareConUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeDareLoStessoQuadroPerLaStessaVista;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNil;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedRenderSupport = class(TObject)
  private
    procedure CreateTooWide;
    procedure CreateTooLow;
  public
    [Test]
    procedure DovrebbeDareLaTabellaDeiNumeriCasuali;
    [Test]
    procedure DovrebbeOrdinareLeSpanDalPiuLontanoAlPiuVicino;
    [Test]
    procedure DovrebbeLasciareInPaceUnaListaCorta;
    [Test]
    procedure DovrebbeCalcolareLeTabelleDiUnaVista;
    [Test]
    procedure DovrebbeRifiutareUnaVistaTroppoGrande;
    [Test]
    procedure DovrebbeCalcolareLeTabelleFini;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedRenderParity = class(TObject)
  private
    procedure CheckGolden(const AFolder, AGoldenName: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiQuadriDelloOriginaleNellaDemo20;
    [Test]
    procedure DovrebbeDareGliStessiQuadriDelloOriginaleNelGiocoCompleto;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.World, DelphiDoom.Greed.Factory, DelphiDoom.Greed.Intf,
  DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Greed.RenderScenarios;

{ TRenderTestAssets }

constructor TRenderTestAssets.Create;
var
  LIndex, LColumn, LColor: Integer;
  LLump: TBytes;
begin
  inherited Create;
  // a wall: 16 * 4 = 64 rows in each of the 64 columns, after the header of 65 words
  for LIndex := 1 to 2 do
  begin
    SetLength(LLump, 130 + 64 * 64 + 512);
    LLump[0] := 16;
    if LIndex = 1 then
      LColor := WALL_COLOR
    else
      LColor := DOOR_COLOR;
    for LColumn := 130 to 130 + 64 * 64 - 1 do
      LLump[LColumn] := LColor;
    FWalls[LIndex] := LLump;
  end;
  for LIndex := 1 to 2 do
  begin
    SetLength(LLump, 4096 + 512);
    if LIndex = 1 then
      LColor := FLOOR_COLOR
    else
      LColor := CEILING_COLOR;
    for LColumn := 0 to 4095 do
      LLump[LColumn] := LColor;
    FFlats[LIndex] := LLump;
  end;
  // a sprite 8 columns wide and 32 high: the left offset 4, then the offset of each column, then the columns
  SetLength(FSprite, 4 + 16 + 8 * 34 + 512);
  FSprite[0] := 4;
  FSprite[2] := 8;
  for LColumn := 0 to 7 do
  begin
    LIndex := 4 + 16 + LColumn * 34;
    FSprite[4 + LColumn * 2] := LIndex and 255;
    FSprite[5 + LColumn * 2] := LIndex shr 8;
    FSprite[LIndex] := 32; // top
    FSprite[LIndex + 1] := 0; // bottom
    for LColor := 0 to 31 do
      FSprite[LIndex + 2 + LColor] := SPRITE_COLOR;
  end;
  // four color tables that leave the colors as they are
  SetLength(FColorMaps, 4 * 256 + 512);
  for LIndex := 0 to 3 do
    for LColumn := 0 to 255 do
      FColorMaps[LIndex * 256 + LColumn] := LColumn;
  SetLength(FTransparency, 65536 + 512);
  SetLength(FBackdrop, 65536 + 512);
end;

function TRenderTestAssets.GetWallCount: Integer;
begin
  Result := 3;
end;

function TRenderTestAssets.GetFlatCount: Integer;
begin
  Result := 3;
end;

function TRenderTestAssets.WallLump(AIndex: Integer): TBytes;
begin
  if (AIndex >= 1) and (AIndex <= 2) then
    Result := FWalls[AIndex]
  else
    Result := nil;
end;

function TRenderTestAssets.FlatLump(AIndex: Integer): TBytes;
begin
  if (AIndex >= 1) and (AIndex <= 2) then
    Result := FFlats[AIndex]
  else
    Result := nil;
end;

function TRenderTestAssets.SpriteLump(ALump: Integer): TBytes;
begin
  if ALump = 7 then
    Result := FSprite
  else
    Result := nil;
end;

function TRenderTestAssets.ColorMaps: TBytes;
begin
  Result := FColorMaps;
end;

function TRenderTestAssets.Transparency: TBytes;
begin
  Result := FTransparency;
end;

function TRenderTestAssets.Backdrop: TBytes;
begin
  Result := FBackdrop;
end;

{ TRenderTestClock }

function TRenderTestClock.GetTimeCount: Integer;
begin
  Result := Time;
end;

function TRenderTestClock.GetSpriteMoveTime: Integer;
begin
  Result := Time;
end;

{ TTestGreedRenderer }

procedure TTestGreedRenderer.Setup;
var
  LX, LY, LSpot: Integer;
begin
  FWorld := TGreedWorld.Create;
  // a room of 16 x 16 tiles from the tile (8, 8) to (23, 23): floor 0, ceiling 64, a wall all around
  for LY := 8 to 23 do
    for LX := 8 to 23 do
    begin
      LSpot := LY * 64 + LX;
      FWorld.SetValue(gpFloorPic, LSpot, 1);
      FWorld.SetValue(gpCeilingPic, LSpot, 2);
      FWorld.SetValue(gpCeilingHeight, LSpot, 64);
      FWorld.SetValue(gpFloorDef, LSpot, 56);
      FWorld.SetValue(gpCeilingDef, LSpot, 56);
    end;
  for LX := 8 to 23 do
  begin
    FWorld.SetValue(gpNorthWall, 8 * 64 + LX, 1);
    FWorld.SetValue(gpNorthWall, 24 * 64 + LX, 1);
    FWorld.SetValue(gpWestWall, (LX) * 64 + 8, 1);
    FWorld.SetValue(gpWestWall, (LX) * 64 + 24, 1);
  end;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
  FClock := TRenderTestClock.Create;
  FClockIntf := FClock;
  FRenderer := TGreedFrameRenderer.Create(TRenderTestAssets.Create, FSprites, FClockIntf, TGreedRandomTable.Create);
  FRendererIntf := FRenderer;
  FFrameForNil := TGreedFrame.Make(320, 200);
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  // the middle of the tile (16, 16), at the height of the eyes, looking north (towards the smaller y)
  FPlayer.X := (16 * 64 + 32) * GREED_FRACUNIT;
  FPlayer.Y := (16 * 64 + 32) * GREED_FRACUNIT;
  FPlayer.Z := 41 * GREED_FRACUNIT;
  FPlayer.Angle := 256;
end;

procedure TTestGreedRenderer.TearDown;
begin
  FRendererIntf := nil;
  FreeAndNil(FSprites);
end;

function TTestGreedRenderer.Draw(AWidth, AHeight: Integer): TGreedFrame;
begin
  Result := TGreedFrame.Make(AWidth, AHeight);
  FRendererIntf.Render(FWorld, FPlayer, Result);
end;

function TTestGreedRenderer.PixelAt(const AFrame: TGreedFrame; AX, AY: Integer): Byte;
begin
  Result := AFrame.Pixels[AY * AFrame.Width + AX];
end;

procedure TTestGreedRenderer.DovrebbeDisegnareIlMuroAlCentro;
var
  LFrame: TGreedFrame;
begin
  LFrame := Draw(640, 400);
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 320, 200)));
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 100, 200)));
end;

procedure TTestGreedRenderer.DovrebbeDisegnarePavimentoESoffitto;
var
  LFrame: TGreedFrame;
begin
  LFrame := Draw(640, 400);
  Assert.AreEqual(Integer(TRenderTestAssets.FLOOR_COLOR), Integer(PixelAt(LFrame, 320, 399)));
  Assert.AreEqual(Integer(TRenderTestAssets.FLOOR_COLOR), Integer(PixelAt(LFrame, 50, 390)));
  Assert.AreEqual(Integer(TRenderTestAssets.CEILING_COLOR), Integer(PixelAt(LFrame, 320, 0)));
end;

procedure TTestGreedRenderer.DovrebbeDisegnareLoStessoAlCentroInBassaRisoluzione;
var
  LFrame: TGreedFrame;
begin
  LFrame := Draw(320, 200);
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 160, 100)));
  Assert.AreEqual(Integer(TRenderTestAssets.FLOOR_COLOR), Integer(PixelAt(LFrame, 160, 199)));
  Assert.AreEqual(Integer(TRenderTestAssets.CEILING_COLOR), Integer(PixelAt(LFrame, 160, 0)));
end;

procedure TTestGreedRenderer.DovrebbeSegnareIMuriNellaMappaDelGiocatore;
begin
  Draw(640, 400);
  // the wall of the north is the north map of its tile; the tiles that are not walls are not marked
  Assert.AreEqual(Integer(GREED_WALL_COLOR), Integer(FPlayer.NorthMap[8 * 64 + 16]));
  Assert.AreEqual(0, Integer(FPlayer.NorthMap[12 * 64 + 16]));
end;

procedure TTestGreedRenderer.DovrebbeDisegnareUnoSpriteDavantiAlMuro;
var
  LFrame: TGreedFrame;
  LIndex: Integer;
begin
  LIndex := FSprites.Add;
  FSprites.Item(LIndex)^.BasePic := 7;
  FSprites.Item(LIndex)^.X := FPlayer.X;
  FSprites.Item(LIndex)^.Y := FPlayer.Y - 100 * GREED_FRACUNIT;
  FSprites.Item(LIndex)^.Z := 0;
  FSprites.Item(LIndex)^.NewX := FPlayer.X;
  FSprites.Item(LIndex)^.NewY := FSprites.Item(LIndex)^.Y;
  LFrame := Draw(640, 400);
  // 100 units away, its feet 41 units below the eyes: about 3.2 pixels a unit, from row 229 to 331
  Assert.AreEqual(Integer(TRenderTestAssets.SPRITE_COLOR), Integer(PixelAt(LFrame, 320, 280)));
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 320, 200)));
end;

procedure TTestGreedRenderer.DovrebbeNascondereUnoSpriteDietroIlMuro;
var
  LFrame: TGreedFrame;
  LIndex: Integer;
begin
  LIndex := FSprites.Add;
  FSprites.Item(LIndex)^.BasePic := 7;
  FSprites.Item(LIndex)^.X := FPlayer.X;
  // the wall is 544 units away: the sprite is 600 units away, behind it
  FSprites.Item(LIndex)^.Y := FPlayer.Y - 600 * GREED_FRACUNIT;
  FSprites.Item(LIndex)^.Z := 0;
  FSprites.Item(LIndex)^.NewY := FSprites.Item(LIndex)^.Y;
  LFrame := Draw(640, 400);
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 320, 210)));
end;

procedure TTestGreedRenderer.DovrebbeDisegnareUnaPortaChiusa;
var
  LDoor: TGreedDoor;
  LFrame: TGreedFrame;
begin
  LDoor := Default(TGreedDoor);
  LDoor.TileX := 16;
  LDoor.TileY := 12;
  LDoor.Orientation := gdoHorizontal;
  LDoor.Pic := 2;
  LDoor.Position := 64 * GREED_FRACUNIT;
  FWorld.SetDoor(FWorld.AddDoor(16, 12), LDoor);
  LFrame := Draw(640, 400);
  Assert.AreEqual(Integer(TRenderTestAssets.DOOR_COLOR), Integer(PixelAt(LFrame, 320, 200)));
  Assert.AreEqual(Integer(GREED_DOOR_COLOR), Integer(FPlayer.NorthMap[12 * 64 + 16]));
end;

procedure TTestGreedRenderer.DovrebbeLasciareApertaLaPortaAperta;
var
  LDoor: TGreedDoor;
  LFrame: TGreedFrame;
begin
  LDoor := Default(TGreedDoor);
  LDoor.TileX := 16;
  LDoor.TileY := 12;
  LDoor.Orientation := gdoHorizontal;
  LDoor.Pic := 2;
  LDoor.Position := 0;
  FWorld.SetDoor(FWorld.AddDoor(16, 12), LDoor);
  LFrame := Draw(640, 400);
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 320, 200)));
end;

procedure TTestGreedRenderer.DovrebbeFarAvanzareLAnimazioneDiUnoSprite;
var
  LIndex: Integer;
begin
  LIndex := FSprites.Add;
  FSprites.Item(LIndex)^.BasePic := 7;
  FSprites.Item(LIndex)^.X := FPlayer.X;
  FSprites.Item(LIndex)^.Y := FPlayer.Y - 100 * GREED_FRACUNIT;
  // looping, frame 0 of 3, a delay of 2 tics, due now
  FSprites.Item(LIndex)^.Animation := GREED_ANIM_LOOP_MASK + (0 * 2) + (3 * 32) + (2 shl 9);
  FSprites.Item(LIndex)^.AnimationTime := 0;
  FClock.Time := 10;
  Draw(640, 400);
  Assert.AreEqual(1, (FSprites.Item(LIndex)^.Animation and GREED_ANIM_CG_MASK) div 2);
  Assert.AreEqual(12, FSprites.Item(LIndex)^.AnimationTime);
end;

procedure TTestGreedRenderer.DovrebbeTogliereUnoSpriteCheSiAutodistrugge;
var
  LIndex: Integer;
begin
  LIndex := FSprites.Add;
  FSprites.Item(LIndex)^.BasePic := 7;
  FSprites.Item(LIndex)^.X := FPlayer.X;
  FSprites.Item(LIndex)^.Y := FPlayer.Y - 100 * GREED_FRACUNIT;
  // the last frame of 2, without loop, and it destroys itself
  FSprites.Item(LIndex)^.Animation := (1 * 2) + (2 * 32) + GREED_ANIM_SELF_DESTRUCT;
  FSprites.Item(LIndex)^.AnimationTime := 0;
  Draw(640, 400);
  Assert.AreEqual(0, FSprites.Count);
end;

procedure TTestGreedRenderer.DovrebbeSpostareLaVistaConLoScroll;
var
  LFrame: TGreedFrame;
begin
  FPlayer.ScrollMin := 30;
  LFrame := Draw(640, 400);
  // the horizon moves up by the scroll: the wall still fills the middle, and there is more floor
  Assert.AreEqual(Integer(TRenderTestAssets.WALL_COLOR), Integer(PixelAt(LFrame, 320, 200 - 30)));
  Assert.AreEqual(Integer(TRenderTestAssets.FLOOR_COLOR), Integer(PixelAt(LFrame, 320, 399)));
end;

procedure TTestGreedRenderer.DovrebbeSollevareConUnQuadroTroppoPiccolo;
var
  LFrame: TGreedFrame;
begin
  LFrame := TGreedFrame.Make(640, 400);
  SetLength(LFrame.Pixels, 100);
  Assert.WillRaise(
    procedure
    begin
      FRendererIntf.Render(FWorld, FPlayer, LFrame);
    end, EGreedRenderException);
end;

procedure TTestGreedRenderer.DovrebbeSollevareConUnaDimensioneNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      Draw(641, 400);
    end, EGreedRenderException);
end;

procedure TTestGreedRenderer.DovrebbeDareLoStessoQuadroPerLaStessaVista;
var
  LFirst, LSecond: TGreedFrame;
begin
  LFirst := Draw(640, 400);
  FillChar(FPlayer.NorthMap, SizeOf(FPlayer.NorthMap), 0);
  LSecond := Draw(640, 400);
  Assert.AreEqual(RenderCrc32(LFirst.Pixels[0], 640 * 400), RenderCrc32(LSecond.Pixels[0], 640 * 400));
end;

procedure TTestGreedRenderer.DovrebbeSollevareConDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedFrameRenderer.Create(nil, FSprites, FClockIntf, TGreedRandomTable.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedFrameRenderer.Create(TRenderTestAssets.Create, FSprites, nil, TGreedRandomTable.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FRendererIntf.Render(nil, FPlayer, FFrameForNil);
    end, EArgumentNilException);
end;

{ TTestGreedRenderSupport }

procedure TTestGreedRenderSupport.CreateTooWide;
begin
  TGreedViewTables.Create(641, 400).Free;
end;

procedure TTestGreedRenderSupport.CreateTooLow;
begin
  TGreedViewTables.Create(640, 1).Free;
end;

procedure TTestGreedRenderSupport.DovrebbeDareLaTabellaDeiNumeriCasuali;
var
  LRandom: TGreedRandomTable;
  LIndex: Integer;
begin
  LRandom := TGreedRandomTable.Create;
  try
    // the first numbers of rndtable of d_misc.pas
    Assert.AreEqual(0, Integer(LRandom.Next));
    Assert.AreEqual(8, Integer(LRandom.Next));
    Assert.AreEqual(109, Integer(LRandom.Next));
    Assert.AreEqual(220, Integer(LRandom.Next));
    for LIndex := 5 to 512 do
      LRandom.Next;
    // after 512 numbers the table starts again
    Assert.AreEqual(0, Integer(LRandom.Next));
    Assert.AreEqual(513, LRandom.Offset);
  finally
    LRandom.Free;
  end;
end;

procedure TTestGreedRenderSupport.DovrebbeOrdinareLeSpanDalPiuLontanoAlPiuVicino;
var
  LTags: TArray<TGreedSpanTag>;
  LIndex: Integer;
  LRandom: TRenderRandom;
begin
  LRandom := TRenderRandom.Create(99);
  try
    SetLength(LTags, 500);
    for LIndex := 0 to 499 do
    begin
      LTags[LIndex].Point := LRandom.Below(100000);
      LTags[LIndex].Span := LIndex;
    end;
    TGreedSpanSorter.Sort(LTags, 500);
    for LIndex := 1 to 499 do
      Assert.IsTrue(LTags[LIndex - 1].Point >= LTags[LIndex].Point, 'order at ' + IntToStr(LIndex));
  finally
    LRandom.Free;
  end;
end;

procedure TTestGreedRenderSupport.DovrebbeLasciareInPaceUnaListaCorta;
var
  LTags: TArray<TGreedSpanTag>;
begin
  SetLength(LTags, 3);
  LTags[0].Point := 5;
  LTags[1].Point := 9;
  LTags[2].Point := 7;
  TGreedSpanSorter.Sort(LTags, 1);
  Assert.AreEqual(Cardinal(5), LTags[0].Point);
  TGreedSpanSorter.Sort(LTags, 3);
  Assert.AreEqual(Cardinal(9), LTags[0].Point);
  Assert.AreEqual(Cardinal(7), LTags[1].Point);
  Assert.AreEqual(Cardinal(5), LTags[2].Point);
end;

procedure TTestGreedRenderSupport.DovrebbeCalcolareLeTabelleDiUnaVista;
var
  LTables: TGreedViewTables;
begin
  LTables := TGreedViewTables.Create(640, 400);
  try
    Assert.AreEqual(320, LTables.CenterX);
    Assert.AreEqual(200, LTables.CenterY);
    Assert.AreEqual(120, LTables.MaxScroll);
    Assert.AreEqual(320 * GREED_FRACUNIT, LTables.Scale);
    Assert.AreEqual(GREED_FRACUNIT div 320, LTables.InverseScale);
    // the first column looks to the left, the last to the right
    Assert.IsTrue(LTables.PixelAngle[0] > 0);
    Assert.IsTrue(LTables.PixelAngle[639] < 0);
    Assert.AreEqual(641, Length(LTables.XSlope));
    Assert.AreEqual(400 + 240, Length(LTables.YSlope));
  finally
    LTables.Free;
  end;
  LTables := TGreedViewTables.Create(320, 200);
  try
    Assert.AreEqual(60, LTables.MaxScroll);
  finally
    LTables.Free;
  end;
end;

procedure TTestGreedRenderSupport.DovrebbeRifiutareUnaVistaTroppoGrande;
begin
  Assert.WillRaise(CreateTooWide, EGreedRenderException);
  Assert.WillRaise(CreateTooLow, EGreedRenderException);
end;

procedure TTestGreedRenderSupport.DovrebbeCalcolareLeTabelleFini;
begin
  // the cosine is the sine a quarter of the circle later, and the tangents are odd around the quadrant
  Assert.AreEqual(TGreedFineTables.Sines^[GREED_TAN_ANGLES], TGreedFineTables.Cosines^[0]);
  Assert.AreEqual(TGreedFineTables.Tangents^[GREED_TAN_ANGLES + 3], -TGreedFineTables.Tangents^[GREED_TAN_ANGLES - 4]);
  Assert.IsTrue(TGreedFineTables.Tangents^[GREED_TAN_ANGLES - 1] > 0);
  Assert.IsTrue(TGreedFineTables.Tangents^[GREED_TAN_ANGLES] < 0);
  Assert.IsTrue(TGreedFineTables.Sines^[0] > 0);
  Assert.IsTrue(TGreedFineTables.Sines^[GREED_TAN_ANGLES * 2] < 0);
end;

{ TTestGreedRenderParity }

procedure TTestGreedRenderParity.CheckGolden(const AFolder, AGoldenName: string);
var
  LLines: TStringList;
  LRunner: TRenderRunner;
  LArchive: IGreedArchive;
  LParts: TArray<string>;
  LLine: string;
  LMap, LView, LLastMap, LSkipRandom: Integer;
  LFrame: TGreedFrame;
  LActual: string;
  LChecked: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    LArchive := TGreedRealData.OpenArchive(AFolder);
    LRunner := TRenderRunner.Create(LArchive, TGreedFactory.CreateFolderFiles([AFolder]));
    try
      LLastMap := -1;
      LChecked := 0;
      for LLine in LLines do
      begin
        LParts := LLine.Split([' ']);
        LMap := StrToInt(LParts[1]);
        LView := StrToInt(LParts[3]);
        if LMap <> LLastMap then
        begin
          // the maps are made as the harness made them: the seed, 12 views and 40 sprites of its arguments
          if AGoldenName = 'render.demo20.golden.txt' then
            LRunner.LoadMap(LMap, 20260109 + Cardinal(LMap), 12, 40)
          else
            LRunner.LoadMap(LMap, 20260110 + Cardinal(LMap), 10, 40);
          LLastMap := LMap;
        end;
        LFrame := LRunner.RenderView(LView);
        if LParts[4] = 'skipped' then
        begin
          // the original stopped on a mistake of its own: sprites and random numbers start again as in the harness
          LSkipRandom := StrToInt(LParts[5]);
          LRunner.ResetSprites;
          LRunner.Random.Offset := LSkipRandom;
          Continue;
        end;
        LActual := Format('%s %s %s %d %s', [IntToHex(RenderCrc32(LFrame.Pixels[0], LFrame.Width * LFrame.Height), 8),
          IntToHex(RenderCrc32(LRunner.Player.NorthMap, SizeOf(LRunner.Player.NorthMap)), 8),
          IntToHex(RenderCrc32(LRunner.Player.WestMap, SizeOf(LRunner.Player.WestMap)), 8), LRunner.Random.Offset,
          IntToHex(RenderSpritesHash(LRunner.Sprites), 8)]);
        Assert.AreEqual(Format('%s %s %s %s %s', [LParts[5], LParts[6], LParts[7], LParts[8], LParts[9]]), LActual,
          'map ' + IntToStr(LMap) + ' view ' + IntToStr(LView));
        Inc(LChecked);
      end;
      Assert.IsTrue(LChecked > 20, 'pictures compared');
    finally
      LRunner.Free;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGreedRenderParity.DovrebbeDareGliStessiQuadriDelloOriginaleNellaDemo20;
begin
  if TGreedRealData.Demo20Folder = '' then
  begin
    Assert.Pass('the demo 2.0 is not here');
    Exit;
  end;
  CheckGolden(TGreedRealData.Demo20Folder, 'render.demo20.golden.txt');
end;

procedure TTestGreedRenderParity.DovrebbeDareGliStessiQuadriDelloOriginaleNelGiocoCompleto;
begin
  if TGreedRealData.FullFolder = '' then
  begin
    Assert.Pass('the full game is not here');
    Exit;
  end;
  CheckGolden(TGreedRealData.FullFolder, 'render.full.golden.txt');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedRenderer);
  TDUnitX.RegisterTestFixture(TTestGreedRenderSupport);
  TDUnitX.RegisterTestFixture(TTestGreedRenderParity);

end.
