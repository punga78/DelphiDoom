{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the movement of the actors and       }
{  their clipping to the tiles and to each other                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.ActorMover;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes,
  DelphiDoom.Tests.Keen.GameWorld;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenActorMover = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    function Place(AX, AY: Integer; AShape: Integer = 0): PKeenObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMuovereVerticalmenteLeCoordinate;
    [Test]
    procedure DovrebbeMuovereOrizzontalmenteLeCoordinate;
    [Test]
    procedure DovrebbeFareIlGiroA16BitDellePosizioni;
    [Test]
    procedure DovrebbeMuovereSenzaRettangoloSeNonHaForma;
    [Test]
    procedure DovrebbeCalcolareIlRettangoloDallaForma;
    [Test]
    procedure DovrebbeLimitareIlMovimentoAUnTile;
    [Test]
    procedure DovrebbeFermarsiSulPavimento;
    [Test]
    procedure DovrebbeLasciarsiCadereSeNonCEPavimento;
    [Test]
    procedure DovrebbeFermarsiControUnMuroASinistra;
    [Test]
    procedure DovrebbeFermarsiControUnMuroADestra;
    [Test]
    procedure DovrebbeFermarsiControIlSoffitto;
    [Test]
    procedure DovrebbeFermarsiSuUnaPendenza;
    [Test]
    procedure DovrebbeNonClipparsiSeNonServe;
    [Test]
    procedure DovrebbeClipparsiSempreSeELGiocatore;
    [Test]
    procedure DovrebbeTenereIlContattoConUnaPendenzaDi45Gradi;
    [Test]
    procedure DovrebbeDareLeAltezzeDeiMuri;
    [Test]
    procedure DovrebbeSpingereUnAttoreSopraUnaPiattaforma;
    [Test]
    procedure DovrebbeSpingereUnAttoreDiLato;
    [Test]
    procedure DovrebbeSpingereDalLatoDellaPiattaforma;
    [Test]
    procedure DovrebbeUccidereKeenSchiacciatoControUnMuro;
    [Test]
    procedure DovrebbeNonUccidereSenzaIlParametroDiSchiacciamento;
    [Test]
    procedure DovrebbeRifiutareUnaFormaCheNonEUnoSprite;
    [Test]
    procedure DovrebbeNonVedereMuriFuoriDallaMappa;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.ActorMover, DelphiDoom.Keen.ActionIds;

function Still(ALeft, ARight: Integer; APushToFloor: Boolean = False): TKeenStateDef;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Name := 'still';
  Result.LeftShape := ALeft;
  Result.RightShape := ARight;
  Result.Progress := kpStep;
  Result.TicTime := 4;
  Result.PushToFloor := APushToFloor;
  Result.Think := KEEN_ACTION_NONE;
  Result.NextState := 0;
end;

const
  SPRITE_TILE = KEEN_STARTSPRITES + 1;

{ TTestKeenActorMover }

procedure TTestKeenActorMover.Setup;
begin
  FWorld := TKeenTestWorld.Create(40, 30, [Still(SPRITE_TILE, SPRITE_TILE), Still(SPRITE_TILE, SPRITE_TILE, True),
    Still(KEEN_STARTSPRITES, KEEN_STARTSPRITES)]);
end;

procedure TTestKeenActorMover.TearDown;
begin
  FWorld.Free;
end;

function TTestKeenActorMover.Place(AX, AY: Integer; AShape: Integer): PKeenObject;
begin
  Result := FWorld.AddActor(AShape, 0, 0, 0);
  Result^.X := Word(AX);
  Result^.Y := Word(AY);
  if AShape <> 0 then
    FWorld.Mover.ClipToWalls(Result);
end;

procedure TTestKeenActorMover.DovrebbeMuovereVerticalmenteLeCoordinate;
var
  LObject: PKeenObject;
begin
  LObject := Place(1000, 2000, SPRITE_TILE);
  FWorld.Mover.MoveVertical(LObject, 300);
  Assert.AreEqual(2300, Integer(LObject^.Y));
  Assert.AreEqual(2000 + 300, Integer(LObject^.Top));
  Assert.AreEqual(2000 + 255 + 300, Integer(LObject^.Bottom));
  Assert.AreEqual(2300 shr 8, Integer(LObject^.TileTop));
  Assert.AreEqual((2255 + 300) shr 8, Integer(LObject^.TileBottom));
end;

procedure TTestKeenActorMover.DovrebbeMuovereOrizzontalmenteLeCoordinate;
var
  LObject: PKeenObject;
begin
  LObject := Place(1000, 2000, SPRITE_TILE);
  FWorld.Mover.MoveHorizontal(LObject, -300);
  Assert.AreEqual(700, Integer(LObject^.X));
  Assert.AreEqual(700, Integer(LObject^.Left));
  Assert.AreEqual(700 + 255, Integer(LObject^.Right));
  Assert.AreEqual(700 shr 8, Integer(LObject^.TileLeft));
end;

procedure TTestKeenActorMover.DovrebbeFareIlGiroA16BitDellePosizioni;
var
  LObject: PKeenObject;
begin
  LObject := Place(65530, 3000);
  LObject^.XMove := 10;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(4, Integer(LObject^.X));
  LObject^.XMove := -10;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(65530, Integer(LObject^.X));
end;

procedure TTestKeenActorMover.DovrebbeMuovereSenzaRettangoloSeNonHaForma;
var
  LObject: PKeenObject;
begin
  LObject := Place(1000, 2000);
  LObject^.XMove := 20;
  LObject^.YMove := -30;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(1020, Integer(LObject^.X));
  Assert.AreEqual(1970, Integer(LObject^.Y));
  Assert.IsTrue(LObject^.NeedToReact);
  Assert.AreEqual(0, Integer(LObject^.Right));
end;

procedure TTestKeenActorMover.DovrebbeCalcolareIlRettangoloDallaForma;
var
  LObject: PKeenObject;
begin
  // the sprite 0 has the rectangle (32, 16) to (224, 240)
  LObject := FWorld.AddActor(KEEN_STARTSPRITES, 2, 0, 0);
  LObject^.X := 1000;
  LObject^.Y := 2000;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(1032, Integer(LObject^.Left));
  Assert.AreEqual(1224, Integer(LObject^.Right));
  Assert.AreEqual(2016, Integer(LObject^.Top));
  Assert.AreEqual(2240, Integer(LObject^.Bottom));
  Assert.AreEqual(1128, Integer(LObject^.MidX));
  Assert.AreEqual(1128 shr 8, Integer(LObject^.TileMidX));
end;

procedure TTestKeenActorMover.DovrebbeLimitareIlMovimentoAUnTile;
var
  LObject: PKeenObject;
begin
  LObject := Place(1000, 2000);
  LObject^.XMove := 1000;
  LObject^.YMove := -1000;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(KEEN_MAXMOVE, Integer(LObject^.XMove));
  Assert.AreEqual(-KEEN_MAXMOVE, Integer(LObject^.YMove));
  LObject^.YMove := 1000;
  FWorld.Mover.ClipToWalls(LObject);
  // going down it is 16 more: the push to the floor
  Assert.AreEqual(KEEN_MAXMOVE + 16, Integer(LObject^.YMove));
end;

procedure TTestKeenActorMover.DovrebbeFermarsiSulPavimento;
var
  LObject: PKeenObject;
  LX: Integer;
begin
  for LX := 5 to 15 do
    FWorld.SetTile(LX, 10, WORLD_SOLID);
  LObject := Place(6 * 256, 2300, SPRITE_TILE);
  LObject^.YMove := 100;
  FWorld.Mover.ClipToWalls(LObject);
  // the bottom is the last unit over the floor of the tile row 10 (2560)
  Assert.AreEqual(2559, Integer(LObject^.Bottom));
  Assert.AreEqual(2304, Integer(LObject^.Y));
  Assert.AreEqual(1, Integer(LObject^.HitNorth));
end;

procedure TTestKeenActorMover.DovrebbeLasciarsiCadereSeNonCEPavimento;
var
  LObject: PKeenObject;
begin
  LObject := Place(6 * 256, 2300, SPRITE_TILE);
  LObject^.YMove := 100;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(2400, Integer(LObject^.Y));
  Assert.AreEqual(0, Integer(LObject^.HitNorth));
end;

procedure TTestKeenActorMover.DovrebbeFermarsiControUnMuroASinistra;
var
  LObject: PKeenObject;
begin
  FWorld.SetTile(4, 8, WORLD_SOLID);
  LObject := Place(5 * 256 + 10, 8 * 256, SPRITE_TILE);
  LObject^.XMove := -30;
  FWorld.Mover.ClipToWalls(LObject);
  // the left is at the right side of the tile 4: 5 * 256
  Assert.AreEqual(5 * 256, Integer(LObject^.Left));
  Assert.AreEqual(1, Integer(LObject^.HitEast));
end;

procedure TTestKeenActorMover.DovrebbeFermarsiControUnMuroADestra;
var
  LObject: PKeenObject;
begin
  FWorld.SetTile(8, 8, WORLD_SOLID);
  LObject := Place(6 * 256 + 100, 8 * 256, SPRITE_TILE);
  LObject^.XMove := 200;
  FWorld.Mover.ClipToWalls(LObject);
  // the right is the last unit before the tile 8
  Assert.AreEqual(8 * 256 - 1, Integer(LObject^.Right));
  Assert.AreEqual(1, Integer(LObject^.HitWest));
end;

procedure TTestKeenActorMover.DovrebbeFermarsiControIlSoffitto;
var
  LObject: PKeenObject;
begin
  FWorld.SetTile(6, 7, WORLD_CEILING);
  LObject := Place(6 * 256, 8 * 256, SPRITE_TILE);
  LObject^.YMove := -50;
  FWorld.Mover.ClipToWalls(LObject);
  // the top is at the bottom of the tile row 7
  Assert.AreEqual(8 * 256, Integer(LObject^.Top));
  Assert.AreEqual(1, Integer(LObject^.HitSouth));
end;

procedure TTestKeenActorMover.DovrebbeFermarsiSuUnaPendenza;
var
  LObject: PKeenObject;
begin
  FWorld.SetTile(6, 10, WORLD_SLOPE);
  LObject := Place(6 * 256, 2250, SPRITE_TILE);
  LObject^.YMove := 190;
  FWorld.Mover.ClipToWalls(LObject);
  // the middle of the actor is at the pixel 7 of the tile: the wall of the type 4 is 7 * 16 high there
  Assert.AreEqual(10 * 256 + 112 - 1, Integer(LObject^.Bottom));
  Assert.AreEqual(4, Integer(LObject^.HitNorth));
end;

procedure TTestKeenActorMover.DovrebbeNonClipparsiSeNonServe;
var
  LObject: PKeenObject;
begin
  FWorld.SetTile(8, 8, WORLD_SOLID);
  LObject := Place(7 * 256, 8 * 256, SPRITE_TILE);
  LObject^.NeedToClip := False;
  LObject^.XMove := 200;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(7 * 256 + 200, Integer(LObject^.X));
  Assert.AreEqual(0, Integer(LObject^.HitWest));
end;

procedure TTestKeenActorMover.DovrebbeClipparsiSempreSeELGiocatore;
var
  LPlayer: PKeenObject;
begin
  // the player is clipped at the sides even when it did not move to them (an actor that does not move left
  // is not clipped to the east walls)
  FWorld.SetTile(6, 8, WORLD_SOLID);
  LPlayer := FWorld.Objects.Player;
  LPlayer^.ShapeNum := SPRITE_TILE;
  LPlayer^.State := 0;
  LPlayer^.XDir := 1;
  LPlayer^.NeedToClip := True;
  LPlayer^.X := 6 * 256 + 30;
  LPlayer^.Y := 8 * 256;
  LPlayer^.XMove := 5;
  FWorld.Mover.ClipToWalls(LPlayer);
  Assert.AreEqual(7 * 256, Integer(LPlayer^.Left));
  Assert.AreEqual(1, Integer(LPlayer^.HitEast));
end;

procedure TTestKeenActorMover.DovrebbeTenereIlContattoConUnaPendenzaDi45Gradi;
var
  LObject: PKeenObject;
begin
  // a state that pushes to the floor: the vertical move follows the horizontal one, 16 more
  LObject := FWorld.AddActor(0, 1, 0, 0);
  LObject^.X := 1000;
  LObject^.Y := 1000;
  LObject^.XMove := 20;
  LObject^.YMove := 0;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(36, Integer(LObject^.YMove));
  Assert.AreEqual(1036, Integer(LObject^.Y));
  LObject^.XMove := -20;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(36, Integer(LObject^.YMove));
end;

procedure TTestKeenActorMover.DovrebbeDareLeAltezzeDeiMuri;
begin
  Assert.AreEqual(256, TKeenActorMover.WallClip(0, 5));
  Assert.AreEqual(0, TKeenActorMover.WallClip(1, 5));
  Assert.AreEqual($38, TKeenActorMover.WallClip(2, 7));
  Assert.AreEqual($F8, TKeenActorMover.WallClip(3, 15));
  Assert.AreEqual($70, TKeenActorMover.WallClip(4, 7));
  Assert.AreEqual($78, TKeenActorMover.WallClip(5, 0));
  Assert.AreEqual($80, TKeenActorMover.WallClip(6, 15));
  Assert.AreEqual(0, TKeenActorMover.WallClip(7, 15));
  // only the low 3 bits of the wall number count
  Assert.AreEqual(TKeenActorMover.WallClip(4, 3), TKeenActorMover.WallClip(12, 3));
end;

procedure TTestKeenActorMover.DovrebbeSpingereUnAttoreSopraUnaPiattaforma;
var
  LPlatform: PKeenObject;
  LPush: PKeenObject;
begin
  LPlatform := Place(1000, 3000, SPRITE_TILE);
  LPush := Place(1000, 2850, SPRITE_TILE);
  // the push actor is 105 units into the platform (its bottom 3105 is over the top 3000... 2850 + 255 = 3105)
  LPush^.XMove := 0;
  LPlatform^.XMove := 0;
  FWorld.Mover.ClipToSprite(LPush, LPlatform, False);
  // pushed up by what is inside it less 16: -105 + 16 = -89
  Assert.AreEqual(2850 - 89, Integer(LPush^.Y));
  Assert.AreEqual(25, Integer(LPush^.HitNorth));
end;

procedure TTestKeenActorMover.DovrebbeSpingereUnAttoreDiLato;
var
  LSolid: PKeenObject;
  LPush: PKeenObject;
begin
  LSolid := Place(1000, 3000, SPRITE_TILE);
  LPush := Place(1200, 3000, SPRITE_TILE);
  // the solid actor moves right by 40 and its right side (1255) is 55 units into the push actor
  LSolid^.XMove := 60;
  LPush^.XMove := 0;
  FWorld.Mover.ClipToSpriteSide(LPush, LSolid);
  Assert.AreEqual(1255, Integer(LPush^.Left));
  Assert.AreEqual(1, Integer(LPush^.HitEast));
end;

procedure TTestKeenActorMover.DovrebbeSpingereDalLatoDellaPiattaforma;
var
  LSolid: PKeenObject;
  LPush: PKeenObject;
begin
  LSolid := Place(1000, 3000, SPRITE_TILE);
  LPush := Place(1200, 3000, SPRITE_TILE);
  // the platform moves right: the left side of the push actor is inside it by 55 and it is pushed by 55
  LSolid^.XMove := 60;
  LPush^.XMove := 0;
  FWorld.Mover.ClipToSprite(LPush, LSolid, False);
  Assert.AreEqual(1255, Integer(LPush^.X) + 0);
  Assert.AreEqual(1, Integer(LPush^.HitEast));
  // and from the other side
  LSolid := Place(1500, 3000, SPRITE_TILE);
  LPush := Place(1300, 3000, SPRITE_TILE);
  // the push actor goes 55 into the platform from the left, that moves left by 60
  LSolid^.XMove := -60;
  LPush^.XMove := 0;
  FWorld.Mover.ClipToSprite(LPush, LSolid, False);
  Assert.AreEqual(1300 - 55, Integer(LPush^.X));
  Assert.AreEqual(1, Integer(LPush^.HitWest));
end;

procedure TTestKeenActorMover.DovrebbeUccidereKeenSchiacciatoControUnMuro;
var
  LSolid: PKeenObject;
  LPush: PKeenObject;
begin
  // the platform pushes the actor from the left against a wall that it touches on the right: Keen dies
  FWorld.SetTile(7, 11, WORLD_SOLID);
  LSolid := Place(5 * 256 + 100, 11 * 256, SPRITE_TILE);
  LPush := Place(6 * 256 + 100, 11 * 256, SPRITE_TILE);
  LPush^.XMove := 0;
  LSolid^.XMove := 100;
  FWorld.Mover.ClipToSprite(LPush, LSolid, True);
  Assert.AreEqual(1, FWorld.EventsFake.KillCount);
end;

procedure TTestKeenActorMover.DovrebbeNonUccidereSenzaIlParametroDiSchiacciamento;
var
  LSolid: PKeenObject;
  LPush: PKeenObject;
begin
  FWorld.SetTile(7, 11, WORLD_SOLID);
  LSolid := Place(5 * 256 + 100, 11 * 256, SPRITE_TILE);
  LPush := Place(6 * 256 + 100, 11 * 256, SPRITE_TILE);
  LPush^.XMove := 0;
  LSolid^.XMove := 100;
  FWorld.Mover.ClipToSprite(LPush, LSolid, False);
  Assert.AreEqual(0, FWorld.EventsFake.KillCount);
end;

procedure TTestKeenActorMover.DovrebbeRifiutareUnaFormaCheNonEUnoSprite;
var
  LObject: PKeenObject;
begin
  LObject := Place(1000, 2000);
  LObject^.ShapeNum := 5;
  Assert.WillRaise(
    procedure
    begin
      FWorld.Mover.ClipToWalls(LObject);
    end, EKeenException);
end;

procedure TTestKeenActorMover.DovrebbeNonVedereMuriFuoriDallaMappa;
var
  LObject: PKeenObject;
begin
  // an actor at the top left corner of the map: the tiles before it are not walls (the C reads other memory)
  LObject := Place(10, 10, SPRITE_TILE);
  LObject^.YMove := -5;
  LObject^.XMove := -5;
  FWorld.Mover.ClipToWalls(LObject);
  Assert.AreEqual(0, Integer(LObject^.HitNorth));
  Assert.AreEqual(5, Integer(LObject^.X));
end;

procedure TTestKeenActorMover.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenActorMover.Create(FWorld.Map, nil, FWorld.Sprites, FWorld.States, FWorld.Objects, FWorld.Events);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenActorMover.Create(FWorld.Map, FWorld.TileInfo, FWorld.Sprites, FWorld.States, FWorld.Objects, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenActorMover);

end.
